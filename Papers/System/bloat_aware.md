# A Bloat-Aware Design for Big Data Applications

  

**Yingyi Bu, Vinayak Borkar, Guoqing Xu, Michael J. Carey**

---



## Introduction

* OOP like java: inefficiency in managed runtime, impact of huge amount of data
* bloat-aware design paradigm
* ![image-20191107111850980](D:\OneDrive\Pictures\Typora\image-20191107111850980.png)
* What is the space overhead if all data items are represented by Java objects?
* What is the memory management (GC) costs in a typical Big Data application?
* ![image-20191107112043710](D:\OneDrive\Pictures\Typora\image-20191107112043710.png)
* ![image-20191107112053845](D:\OneDrive\Pictures\Typora\image-20191107112053845.png)
* ![image-20191107112111100](D:\OneDrive\Pictures\Typora\image-20191107112111100.png)
* It is the data path that needs a non-convential design & an extremely careful implementation
* The # of data objects in the system has to be bounded & cannot grow proportionally with the size of the data to be processed
* bloat-aware design paradigm
  * merge small objects in the storage
  * access the merged objects using data processors
  * page-based record management
* ![image-20191107112519454](D:\OneDrive\Pictures\Typora\image-20191107112519454.png)
* ![image-20191107112534165](D:\OneDrive\Pictures\Typora\image-20191107112534165.png)



## Memory Analysis of Big Data Application

* Low Packing Factor
  * header space
  * ![image-20191107113032718](D:\OneDrive\Pictures\Typora\image-20191107113032718.png)
  * ![image-20191107113146606](D:\OneDrive\Pictures\Typora\image-20191107113146606.png)
  * ![image-20191107113153436](D:\OneDrive\Pictures\Typora\image-20191107113153436.png)
  * ![image-20191107113203333](D:\OneDrive\Pictures\Typora\image-20191107113203333.png)
  * ![image-20191107113215413](D:\OneDrive\Pictures\Typora\image-20191107113215413.png)
  * ![image-20191107140554205](D:\OneDrive\Pictures\Typora\image-20191107140554205.png)
* Large volumes of objects & references
  * ![image-20191107140513147](D:\OneDrive\Pictures\Typora\image-20191107140513147.png)
  * ![image-20191107140540014](D:\OneDrive\Pictures\Typora\image-20191107140540014.png)



## The Bloat-Aware Design Paradigm

* ![image-20191107140820117](D:\OneDrive\Pictures\Typora\image-20191107140820117.png)
* ![image-20191107140828478](D:\OneDrive\Pictures\Typora\image-20191107140828478.png)
* Merging & organizing related small data record objects into few large objects (byte buffers) instead of representing them explicitly as one-object-per-record
* Manipulating data by directly accessing buffers (at byte chunk level as opposed to the object level)
* Data Storage Design: Merging Small Objects
  * ![image-20191107141005644](D:\OneDrive\Pictures\Typora\image-20191107141005644.png)
  * ![image-20191107141028013](D:\OneDrive\Pictures\Typora\image-20191107141028013.png)
  * [[R: It's very similar to database page/tuple layout]]
* Data Processor Design: Access Buffers
  * ![image-20191107142108244](D:\OneDrive\Pictures\Typora\image-20191107142108244.png)
  * ![image-20191107142120269](D:\OneDrive\Pictures\Typora\image-20191107142120269.png)
  * ![image-20191107142133157](D:\OneDrive\Pictures\Typora\image-20191107142133157.png)
  * ![image-20191107142144285](D:\OneDrive\Pictures\Typora\image-20191107142144285.png)
  * ![image-20191107142150804](D:\OneDrive\Pictures\Typora\image-20191107142150804.png)



## Programming Experience

* separate logical data access & physical data storage
* ![image-20191107143352509](D:\OneDrive\Pictures\Typora\image-20191107143352509.png)
* ![image-20191107143817125](D:\OneDrive\Pictures\Typora\image-20191107143817125.png)
* ![image-20191107143843068](D:\OneDrive\Pictures\Typora\image-20191107143843068.png)
* ![image-20191107143848740](D:\OneDrive\Pictures\Typora\image-20191107143848740.png)























## Motivation

* Data intensive frameworks often use object-oriented managed programming language such as Java, Scala. The Java Virtual Machine (JVM) often becomes the bottleneck of data intensive frameworks since it requires extra header space for objects and creates a large number of references which makes garbage collection a heavy work. Since the frameworks often separates the data path and control path, It's unnecessary to force developers to switch back to an unmanaged languages.

## Summary

* In this paper, the authors present a bloat-aware design paradigm in order to solve the inefficiency of using memory in JVM. The authors analyze the current problems in Java runtime: low packing factor memory due to object headers and GC overhead by large volumes of objects and references. The bloat-aware paradigm asks developers to merge and organize related small data record objects into few large objects (e.g. byte buffers) instead of one-object-per-record, and manipulate data by directly accessing buffers. The operations and data storage are transformed manually to accessor classes. The number of accessor objects is always bounded at compile time and doesn't grow proportional with the cardinaity of the dataset.

## Strength

* The bloat-aware paradigm solves the memory usage challenges in managed object-oriented language without re-implementing framework in unmanaged languages.

## Limitation & Solution

* The paradigm needs programmers to manually rewrite their programs.
  * [FACADE](http://web.cs.ucla.edu/~wangkai/papers/asplos15.pdf) might be the following work of this paper, by automatically transforming programs into the bloat-aware paradigm.

