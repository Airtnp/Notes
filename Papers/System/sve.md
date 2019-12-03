# SVE: Distributed Video Processing at Facebook Scale

  

**Qi Huang, Petchean Ang, Peter Knowles et al.**

---



## Introduction

* Uploading & processing videos
  * Low latency to support interactive applications
  * A flexible programming model for application developers
    * simple to program
    * efficient processing
    * reliable
  * robustness to faults & overload
  * video format
  * re-encoding into a variety of bitrates & formats
* initial monolithic encoding script (MES)
* current Streaming Video Engine (SVE)
  * overlap uploading & processing
  * parallelize the processing by chunking
  * parallelize the storing (with replication)
  * DAG programming model
  * stream-of-tracks abstraction
    * video -> tracks of video/audio/metadata
  * fault tolerance
    * mask non-deterministic & machine-specific processing failures -> retry
    * unmask processing failures -> automatic, fine-grained monitoring
    * delay non-latency-sensitive tasks
    * reroute tasks across datacenters
    * time-shift load by store uploaded video on disk



## Background

* full video pipeline: record, upload, process, store, share, stream
* processing: validate, re-encode
* store: BLOB storage system
* pre-sharing pipeline: upload, process, store
* ![image-20191030164506967](D:\OneDrive\Pictures\Typora\image-20191030164506967.png)
* MES: video as opaque file, 1 monolithic encoding script
  * incur high latency (sequential nature)
  * different to add new applications
  * prone to failure & fragile under overload
* Mismatch of existing system
  * Batch processing: high latency due to no sequential data
  * Streaming processing: continuous queries, not events, no video-deferring overload control, DAG for ecah video, specialized scheduling
  * generality is bad, specialized fault tolerance, overload control, scheduling



## Streaming Video Engine

* ![image-20191030170558117](D:\OneDrive\Pictures\Typora\image-20191030170558117.png)
* client breaks the video up into segments consisting of a group of pictures (GOP)
* GOP: separately encoded, decoded without referencing earlier GOPs
* Segments: split based on GOP alignment, smaller standalone videos
  * reduce latency
  * front-end forwards video chunks to a preprocessor instead of into storage
  * replacing MES with the preprocessor + scheduler + workers of  SVE
  * pipeline construction in a DAG interface for developer tunings
* Preprocessor
  * lightweight preprocessing
  * initiate heavyweight processing
  * write-through cache for segments headed to storage
  * validation, fix malformed videos
  * GOP splitting
  * single machine
* Encoding
  * heavyweight
  * pixel-level examination of each frame within a video track
  * spatial image compression & temporal motion compression across a series of frames
  * many workers with DAG
* Scheduler
  * priority-based (annotated by programmers) multi-queue
  * greedy
  * worker pull
  * shard workload by video ids among many schedulers
* Worker
  * receive task from scheduler
  * pull data from cache in preprocessor / intermediate storage
* Intermediate Storage
  * read/write pattern,, data format, access frequency
  * metadata to multi-tier storage system & in-memory cache
  * internal processing context for SVE is written to a storage system (durability)
    * write many times, read once
  * video/audio data to configured version of BLOB storage system
  * automatically free after a few days
    * simple, less error-prone
    * without explicit tracing



## Low Latency Processing

* ![image-20191102125554087](D:\OneDrive\Pictures\Typora\image-20191102125554087.png)
* ![image-20191102130856385](D:\OneDrive\Pictures\Typora\image-20191102130856385.png)
* Pre-sharing latency
  * upload time + storage sync time + encoding time + load time
  * encoding start delay + storage time + encoding time + fetch time
* Overlap Uploading & Encoding
  * time required for a client to upload all segments of a video
    * significant part of pre-sharing latency
  * bottlenecked by bandwidth available
    * can't improve
    * upload less data
    * overlap uploading & encoding
  * should support diverse set of client devices
  * client-side processing if possible, cloud-side as backup
    * [[Q: legal problem? user battery...]]
  * client-side re-encoding
    * raw video is large
    * network is bandwidth constrained
    * appropriate hardware & software support
  * split videos into GOP-aligned segments
    * client-side splitting / preprocessor splitting
* Parallel Processing
  * video size ~ encoding time
  * segment size controls a tradeoff between compression & parallelism
    * 10s for low latency
    * 2min for high quality
  * variable frame rate video? extra sequential pass
  * malformed when artifacts
    * editing tools setting start time to negative value
    * missing frame information
    * repair at preprocessing & track joining stages
* Rethink the Video Sync
  * overlap processing/storing
    * [[Q: fault tolerance?]]
* SVE Latency Improvements



## DAG Execution System

* ![image-20191102151835929](D:\OneDrive\Pictures\Typora\image-20191102151835929.png)
* ![image-20191102152706667](D:\OneDrive\Pictures\Typora\image-20191102152706667.png)
* streams-of-tracks
  * vertices: sequential processing tasks
  * edges: dataflow
  * track within a video: processing with 1 or all
  * stream of data within a track (GOP-based segments)
    * [[Q: stateful operators?]]
  * split into track/segment, split into encodings, collect segments, join segments, join tracks
* DAG generation
  * dynamically generated
* DAG Execution & Annotations
  * HHVM workers (JIT for SVE tasks)
  * Hack functions deployed continuously from our code repo
  * wrapper: prepare I/O, report
  * annotations
    * task group: group of tasks scheduled together on a single worker
      * fine-grained monitoring, fault identification, fault recovery
    * latency-sensitive: scheduler
* Monitoring & Fault Identification









## Fault Tolerance

* ![image-20191102153400058](D:\OneDrive\Pictures\Typora\image-20191102153400058.png)
* Scale error
  * non-deterministic bugs
  * retry
  * task failure → (user handling → scheduler report → reschedule ) / → cancellation
* Incomplete control
  * loss of connection, network interruption
  * store original segments from videos for grace period
  * purge DAG execution job associated with the upload? schedule again
* Diverse input
  * client devices, types of segments, bugs
  * monitoring



## Overload Control

* overloaded: high demand for processing than the provisioned throughput of the system
* sources of overload
  * organic: diurnal pattern, daily weekly peaks, social events
  * load-testing: load-testing framework Karken, diaster tolerance test
  * bugs: memory leak, ffmpeg version
* mitigating
  * monitor load in CPU-bound workers/memory-bound preprocessors
  * front-end/storage tiers separately manage overload
  * DAG complexity small
  * SVE delay latency-insensitive tasks → scheduler monitor CPU load → check current load against moderate threshold → mitigate task → redirect a portion of new uploads to other region → latency-sensitive tasks pushed back by the scheduler avoiding thrashing workers → regional overload alert → on-call engineer / automatic mechanism → redirect uploads (allow caching) to co-locate
  * processing newly uploaded video entirely



## Production Lessons

* mismatch between livestreaming & SVE
  * overlap of recording with other stages of full video pipeline in livestreaming
    * upload & processing rate paced
    * upload throughput is not bottleneck, parallel processing is unnecessary
  * flexibility afforded through dynamic generation of a DAG for each video is unnecessary
  * SVE recovers from failures & process segments, while livestreaming doesn't need long-lived video
  * separate system
* global inconsistency
  * eventually-consistent geo-replicated data store
  * segment replicate asynchronous with upload redirection
  * retry → vulnerable to spikes in replication lag
  * WIP? strongly-consistent storage
* regional inconsistency
  * regional cache-only option
  * read-after-write consistency data store
* continuous sandboxing
  * Linux namespace
  * unique network namespace for each execution causing spikes
  * re-use pre-created namespace for sandboxing across tasks

















## Motivation

* Videos are an increasing utilized part of the user experience for people using Facebook. The videos must be uploaded and processed (format, bitrates) by they are available for sharing. There are three major requirements for video uploading and processing: low latency, flexible programming model and robustness to faults and overload. The existing Facebook monolithic encoding script (MES) fails to satisfy all three requirements.

## Summary

* In this paper, the authors describe Facebook's Streaming Video Engine (SVE). SVE is a parallel processing framework specializing video uploading, preprocessing, and re-encoding. SVE preprocessors validate the video format and split videos into segments and either cache them in memory or store into persistent layer BLOB. The encoding is done by DAG-like system with scheduler and workers on different tracks, different segments and collect and join segments and tracks. SVE focuses on low latency, fault tolerance and overload control.

## Strength

* SVE is specialized on video processing, which makes it better at reducing latency precisely (uploading time, storage time, encoding time, fetch time).
* SVE decreases latency by overlapping uploading, processing (encoding) and storage sync by parallel processing and splitting video into segments.

## Limitation & Solution

* SVE only serves a very specific domain: video processing.
  * Essentially a batch-at-a-time streaming processing engine.
* SVE fault tolerance is mainly solved by retrying. (the paper doesn't talk much about the system fault tolerance handling).
  * Overlapping computation and communication makes it hard to have fault tolerance.

