# [The UNIX Time-Sharing System](http://web.eecs.umich.edu/~barisk/teaching/eecs582/unix.pdf)

###### Dennis M. Ritchie, Ken Thompson, Bell Laboratories

---

### What is the Problem? [Good papers generally solve *a single* problem]



### Summary [Up to 3 sentences]



### Key Insights [Up to 2 insights]



### Notable Design Details/Strengths [Up to 2 details/strengths]

* everything is a file
* pipes (IPC)
* do one thing at a time once do it well
* generality
* virtual memory
* + process isolation
* + flexibility
* + access to larger memory user space
* simple interface of syscall
* + `syscall(num, ...)`
* + Windows: wrappers of Wow, Nt, Hal, Sys, Zw...

### Limitations/Weaknesses [up to 2 weaknesses]

* slow syscall
* hide power
* user space pages readable + writable
* bloated monolithic
* hard to modify
* `fork` is wasteful?
* + COW
* + setup, sharing resources

### Summary of Key Results [Up to 3 results]



### Open Questions [Where to go from here?]

* JIT


### Self-Keypoints [Delete this when uploading!!]

* PDP-11/45 
* + 16 bit word (8-bit byte) computer with 144K bytes of core memory.
* + large number of device drivers and a generous allotment of space for I/O buffers and system tables
* + 1M byte fixed-head disk
* + 4 moving-head disk drives which provide 2.5M bytes on removable disk cartridges
* + 1 moving-head disk drive which uses removable 40M byte disk packs
* + high-speed paper tape reader-punch, 9-track magnetic tape, D-tape
* + 14 variable-speed communication interfaces attached to 100-series datasets and a 201 dataset interface
* File System
* + ordinary files
* + directory
* + - root `/`, `.`, `..`
* + - 14 or fewer characters filename
* + - linking
* + special files
* + - I/O device /dev
* + - file and device I/O are as similar as possible
* + removable file system
* + - mount system request
* + - - name of an existing ordinary file
* + - - name of a direct-access special file whose associated storage volume should have the structure of an independent file system containing its own directory hierarchy
* + - - make a reference and replaces a leaf -> subtree
* + - exception of files on different devices: no link may exist between 1 file system hierarchy and another
* + protection
* + - uid, 777, 6-bits
* + - uid, eid, gid (run/effective/saved)
* + I/O Calls
* + - file descriptor
* + - syscall: create/read/write/seek
* Implementation
* + inode => 482P4
* + - owner
* + - protection bits
* + - physical disk or tape addresses for the file content
* + - size
* + - time of last modification
* + - # of links to the file (# of times it appears in a directory)
* + - a bit indicating whether the file is a directory
* + - a bit indicating whether the file is a special file
* + - a bit indicating whether the file is "large" or "small"
* Processes and Images
* + image: computer execution environment
* + - core image, general register values, status of open files, current directory, like
* + process: execution of a image
* + - fork, split into 2 independently executing process, have independent copies of the original core image, share open files
* + pipes: IPC
* + - interprocess channel `pipe`
* + - a write using a pipe file is blocked until another write
* + execution of programs
* + - `execute`
* + process synchronization
* + - `wait`, suspend execution until 1 of its children has completed execution
* + termination
* + - `exit`, terminate the process, destroy its image, close its open files, generally obliterates it. notify `wait`
* + text segment (RYWN), data segment, stack segment
* Shell
* + `command args...`
* + I/O, `>`, `<`
* + filter, `|`
* + - tee
* + command separators, `&`
* + shell as a command
* + implementation
* + - read - fork - execute
* Traps
* + terminates the process and writes the user's image on file core (core_handler)
* + interrupt
* + quit
* + interrupt masking
* Design
* + usability
* + fairly severe size constraints
* + maintain itself