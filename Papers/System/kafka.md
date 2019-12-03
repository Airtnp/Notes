# Kafka: a Distributed Messaging System for Log Processing  

**Jay Kreps, Neha Narkhede, Jun Rao**

---



## Introduction

* Kafka: distributed message system
  * collecting & delivering high volumes of log data with low latency
  * incorporate ideas from existing log aggregators, message systems
  * suitable for both offline/online message consumption
* logs
  * user activity events
  * operational metrics
* activity data
  * search relevance
  * recommendation
  * ad targeting & reporting
  * security applications
  * newsfeed features
* Traditional messaging systems
  * mismatch in features: rich delivery guarantees / overkill for collecting log data
  * don't focus as strongly on throughput as primary design constraints
  * weak in distributed support
  * assume near immediate consumption of messages
* Kafka: distributed, scalable, high throughput
  * API similar to messaging system
  * allow applications to consume log events in real time



## Kafka Architecture & Design Principles

* topic: stream of messages of a particular type

* brokers: a set of servers, store published messages

* producer: publish messages to a topic

* consumer: subscribe to 1+ topics from brokers, consume subscribed messages by pulling data from brokers

* ```java
  // producer
  producer = new Producer(…);
  message = new Message(“test message str”.getBytes());
  set = new MessageSet(message);
  producer.send(“topic1”, set);
  
  // consumer
  streams[] = Consumer.createMessageStreams(“topic1”, 1)
  for (message : streams[0]) {
      bytes = message.payload();
      // do something with the bytes
  }
  ```

* ![image-20191026225658186](D:\OneDrive\Pictures\Typora\image-20191026225658186.png)

* Single Partition Efficiency

  * Simple storage layout: a log as a set of segment files of approximately the same size [[R: extent, stream, block design in Azure]], exposed after flush
    * message addressed by logical offset in the log
    * no need for id, seek-intensive random-access index
    * consumer asynchronous pull requests to brokers
      * offset of message + # of bytes acceptable
      * receive data
      * compute offset of next message
    * broker maintain sorted list of offsets + first message offset
      * have buffer, send data, searching offsets
    * ![image-20191026230605086](D:\OneDrive\Pictures\Typora\image-20191026230605086.png)
  * Efficient transfer
    * batch push/pull
    * avoid explicitly caching messages in memory at the Kafka layer
      * rely on underlying file system page cache
      * avoid double buffering
      * retaining warm cache even when a broker process is restarted
      * little overhead in GC, VM-based language feasible
      * sequential, lagged reading, normal OS caching heuristics are effective (write-through, read-ahead)
  * network access
    * multi-subscriber, single message consumed multiple times by different consumer applications
    * sending bytes from a local file to a remote socket
      * read data from the storage media to the page cache in an OS
      * copy data in the page cache to an application buffer
      * copy application buffer to another kernel buffer
      * send kernel buffer to the socket
      * 4 copy, 2 syscall
      * use sendfile instead, 2 copy + 1 syscall
  * stateless broker
    * consumer maintains how much info consumed, not broker
    * how to delete a message? time-based SLA for the retention policy
      * automatically delete if retained in the broker longer than a certain period
      * consumer can deliberately rewind back to an old offset & re-consume data

* Distributed coordination

  * producer: publish message to
    * randomly selected partition
    * a partition semantically determined by a key & function
  * consumer
    * consumer groups: 1+ consumers jointly consume a set of subscribed topics
      * each message delivered to only 1 of consumers within the group
    * different consumer groups each independently consume the full set of subscribed messages, no  inter-group coordination
    * partition within a topic the smallest unit of parallel
      * all messages from one partition are consumed only by a single consumer within each consumer group  
      * over partitioning
    * no central "master" node, consumers coordinate among themselves
      * Zookeeper service
        * detecting addition/removal of brokers/consumers
        * triggering rebalancing process in each consumer when consumer Zookeeper API events happen
        * maintaining the consumption relationship & keeping tracking of the consumed offset of each partition
      * create a path, set value of a path, read the value of a value, delete a path, list the children of a path
      * one can register a watcher on a path & get notified when children of a path or value of a path has changed
      * a path can be created as ephemeral, creating client gone → removed path
      * replicate data to multiple servers
      * broker registry (hostname, port, topics, partitions, ephemeral) → Zookeeper
      * consumer registry (consumer group, topics, ephemeral) → Zookeeper
      * consumer group with 1 ownership (ephemeral) registry + 1 offset (persistent) registry → Zookeeper
        * ownership: 1 path for every subscribed partition, path value is the id of the consumer currently consuming this partition (owns)
        * offset: for each subscribed partition, the offset of the last consumed message in the partition
      * initial startup of consumer / consumer is notified by watcher about broker/consumer change
        * initialize rebalance process to determine new subset of partitions that it should consume from
        * ![image-20191027002243840](D:\OneDrive\Pictures\Typora\image-20191027002243840.png)
        * reading broker/consumer registry from Zookeeper
        * compute the set of partitions available for each subscribed topic
        * compute the set of consumers subscribing to topic
        * range-partition available partitions into |consumer| chunks
        * deterministically picks 1 chunk to own (so each consumer balances without coordination)
        * write itself as the new owner of the partition in the ownership registry
        * begin a thread pull data from each owned partition
        * starting from the offset stored in the offset registry
      * each of consumers within a group will be notified of a broker/consumer change
        * time delta → conflict ownership → release & retry
      * new consumer group created, on offset available
        * consumer will start with either the smallest / largest offset
      * [Kafka Consumer Rebalancing Algorithm](https://stackoverflow.com/questions/28574054/kafka-consumer-rebalancing-algorithm)

* Delivery guarantees: at-least-once delivery

  * exactly-once: 2 phase commit, not necessary [[Q: what about Flink?]]
  * if consumer crashes without a clean shutdown → new consumer may get some duplicate messages after last offset successfully committed to Zookeeper
    * [[Q: if message publication is failed?]]
  * application de-duplication logic
  * Messages from a single partition are delivered to a consumer in order, no order between partitions
  * log corruption → CRC for each message → recovery messages
  * broker failure → lost data → [WIP] built-in replication in Kafka



## Kafka@LinkedIn

* ![image-20191027003836130](D:\OneDrive\Pictures\Typora\image-20191027003836130.png)
* auditing system to verify that there is no data loss along the whole pipeline
  * message carrying timestamp & generator server name
  * instruct each producer that it periodically generates a monitoring event, recording # of message published fro each topic within a fixed time window
    * publish monitoring events to separate topic
  * consumer counts the # of messages received from a given topic & validate counts
* Avro as serialization protocol
  * efficient & schema evoluation
  * lightweight scheme registray service



## Conclusion & Future Works

* pull-based consumption model, allowing application to consume data at its own rate & rewind the consumption whenever needed
* high throughput
* integrated distributed support
* add built-in replication of messages across multiple brokers
  * durability & data availability
  * support asynchronously & synchronous replication model
* add stream processing capability
  * pull filters from following real-time computations











## Motivation

* Sizable internet companies often generate a large amount of log data. This log data includes user activity and operational metrics, which are tended to be used in production data pipeline. Therefore, large internet companies desire to have a real-time log collection / messaging systems. The existing messaging systems are mismatch of the features, having low throughputs, hard to distributed/scale or only suitable to offline data.

## Summary

* In this paper, the authors present Kafka, which is a distributed messaging system with high throughput, low latency and high scalability. Kafka organizes messages by messages, segments, partitions, and topics. The producers publish messages to brokers in charge of corresponding partitions of topics. The consumers pull messages based on offset of messages from corresponding brokers. The consumers are organized into consumer groups for common subscribed topics. The consumers will coordinate when broker/consumer changes to rebalance the workloads. Kafka provides at least once semantics for message processing.

## Strength

* Kafka topics concept is concise to allow a large set of computatons (like Kubernetes labels).
* Kafka stateless broker and offset design makes it highly scalable.

## Limitation & Solution

* Kafka only provides at least once semantics
  * Insert control events into topics and intrusively change consumers behavior like Flink does.
* Kafka doesn't provide fault tolerance under broker failures.
  * Add built-in replication on partitions.

