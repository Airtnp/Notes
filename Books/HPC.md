# HPC

## Processor
* Scalar vs Vector
* Parallel stream
* Independent processor
* Semi-independent cores
* + each core runs a group of threads
* + threads all run on same thing
* + when branch only one run
* + typical GPU
* Scale
* + processor: n x m element vector processor
* + programmer sees n element vector processor
* + processor starts m element at once
* + same branch => continue
* + different branch => pause & resume later

## Memory
* reg => L1 => L2 => L3 => Main
* working set in fast memory
* cache
* + cache line
* + hash table
* + hopscotch hash algorithm
* + - try to insert
* + - if full, scan up to 32 elements for spare slot, insert if possible
* + - if not, see if any of 32 elements can be moved to a secondary location, insert in their free slot
* + - if not, resize the table and entry.
* coherency
* + MESI
* NUMA
* + Modern x86 chips
* + SGI Altix
* + - pointer: 36bit node offet, 11bit node ID
* + Cell
* + - nocache, 256KB local memory, explicitly managed
* + Stream processor
* + - Most DSPs, GPUs

## Concurrency
* shared memory
* + UMA (uniform memory architecture)
* + SMP (symmetric multiprocessor)
* + - memory controller can handle one memory request at a time
* + - CPU needs to wait
* + - Memory starvation
* + - Cache conherency
* + Duplicate the processors
* private memory
+ + ccNUMA
* + - each processor has private memory
* + - access to other CPU's memory indirect and explicit
* Emulate UMA with NUMA
* + done by most cluster OS and supercomputer
* + single global address space
* + remote memory fetched and cached
* + problem
* + - different time to access
* + - programmer can't see / reasoning hard
* CPU - CPU
* + HyperTransport / QuickPath Interconnect
* + Infiniband
* + Gigabit Ethernet
* + The Internet
* + Carrier Pigeons (RFC1149)
* + INMOS Transputer

## Thread
* overhead
* + creating stack
* + thread_local variables
* + context switching if # of thread > # of cores
* + synchronisation costs (implicit cache coherency cost)

## Erlang
* message-passing concurrency
* Very Prolog-like:
* + Variables start with upper case.
* + Atoms start with lower case.
* + Commas(,) separate sequential statements
* + Semicolons(;) separates ‘choice’ statements
* + Full stop as a terminator(.)
* + Functions defined with arrow (->)
* + Function-like syntax use for all control structures (if, case, etc)
* + Last line is the return value (no explicit return)
* Single Assignment
* Pattern Matching
```erlang
-module ( calc ).
-export ([ evaluate /3]).
evaluate (add ,A,B) ->
    A + B
;
evaluate ( subtract ,A,B) ->
    A - B.
```
* Small Processes
```erlang
Pid = spawn (Node , Module , Function , Args ).
```
* Message Passing
* + `Pid ! Message.`
* + Asynchronous
* + Can send anything, even process IDs
```erlang
receive
    {ping , {Sender , Sent }} ->
        Sender ! {ack , {Sent , now ()}}
    ;
    Error ->
        io: format (" Invalid Message received
            ~w~n", [ Error ])
end.

Responder ! {ping , { self () ,now ()}},
    receive
        {ack , {Sent , Received } ->
            logRoundTrip (Sent , Received }
    end
```
* Data Structures
* + Tuple
* + - `A = {1, 2, { elephant , B}, 12.5 , " aardvark .", Pid }.`
* + - Fixed number
* + - Contain anything
* + List
* + - Dynamic
* + - good for recursion
* + - string: List Char
* Bit Syntax
* + `A = <<1,2,3,4,5,6>>.`
* + `<<B:16/big, C:32/little >> = A.`
```erlang
-module (qs).
-export ([qs /1]).

qs([]) -> []
;
qs([X]) -> [X]
;
qs( List ) ->
    [Pivot | Sublist] = List,
    {Less, Greater} =
        partition (Sublist, Pivot, [], []),
    qs( Less ) ++ [ Pivot ] ++ qs( Greater ).

partition ([],_,Less , Greater ) -> {Less , Greater }
;
partition ([X| List ],Pivot , Less , Greater ) ->
    if
        X > Pivot ->
            partition (List , Pivot , Less , [X|
                Greater ])
        ;
        true ->
            partition (List , Pivot , [X| Less ],
                Greater )
    end 

✞
pqs ([],Parent , Tag ) -> Parent ! {Tag ,[]}
;
pqs ([X],Parent , Tag ) -> Parent ! {Tag ,[X]}
;
pqs (List , Parent , Tag ) ->
    [ Pivot | Sublist ] = List ,
    {Less , Greater } = partition ( Sublist , Pivot ,[]
        ,[]),
    spawn (pqs ,pqs ,[Less , self () , less ]),
    spawn (pqs ,pqs ,[ Greater , self () , greater ]),
    receive {less , LessSorted } -> true end ,
    receive { greater , GreaterSorted } -> true end ,
    Parent ! {Tag , LessSorted ++ [ Pivot ] ++
        GreaterSorted }.
```

## Lock-Free
* problem
* + Compiler Reorder
* + - reorder => volatile / compiler fence
* + CPU Reorder
* + - single core program order invisible
* + - other thread => memory barrier (__sync_x)
* + - Eg. Xen Time Source
* + - - Hypervisor must provide guest VMs with current time
* + - - Desire to avoid expensive calls from guest to hypervisor
* + - - Lock-free for updating time
* Time in Xen
* + Hypervisor provides coarse-grained time and TSC (time-stamp counter) when accurate
* + Generating current time requires reading several values from memory
```c
struct shared_info {
    int version , nanosecs , seconds , tscs ;
};
// Read
struct shared_info atomic_read (volatile struct shared_info * info ) {
    struct ret ;
    while (( ret -> version = info -> version ) & 1) ;
    ret -> nanosecs = info -> nanosecs ;
    ret -> seconds = info -> seconds ;
    ret -> tscs = info -> seconds ;
    if (ref -> version == info -> version )
        return ret ;
    return atomic_read ( info );
}

// Write
info -> version ++;
__sync_synchronize ();
info -> nanosecs = nanosecs ;
info -> seconds = seconds ;
info -> tscs = seconds ;
__sync_synchronize ();
info -> version ++;
```
* Lockless ring buffer
* + volatile don't assure atomicity, x86 ensures
* + volatile don't assure no reorder(CPU/Compiler) between multi-thread or non-volatile
* + volatile assure no register-based forward. 
* + But we have x86 only SL reorder
* + [better-solution](https://www.codeproject.com/Articles/43510/Lock-Free-Single-Producer-Single-Consumer-Circular)
* + [CAS](https://www.codeproject.com/Articles/153898/Yet-another-implementation-of-a-lock-free-circular)
* + [SPSC-volatile](https://sites.google.com/site/kjellhedstrom2/threadsafecircularqueue)
* + [MPMC-atomic](https://kjellkod.wordpress.com/2012/11/28/c-debt-paid-in-full-wait-free-lock-free-queue/)
```c
// SPSC, MPMC not work
volatile uint32_t producer ;
volatile uint32_t consumer ;
int shift = 8;
// Must be power of two !
const bufferSize = 1<< shift ;
const bufferMask = bufferSize - 1;
void * buffer [ bufferSize ];

void insert ( void *v) {
    while ( producer - consumer > bufferSize );
    buffer [ producer & bufferMask ] = v;
    // at least compiler fence here
    producer ++;
}

void * fetch ( void ) {
    while ( producer == consumer );
    // add sched_yield() to avoid busy waiting
    void *v = buffer [ consumer & bufferMask ];
    // at least compiler fence here
    consumer ++;
    return v;
}
```

## Transaction
* transaction
* + set of operations
* + atomically (large atomic operation, no middle state, fail if same)
* + either success or fail
* ACID
* + Atomicity - groups of commands must execute as a single operation
* + Consistency - the database must never expose partially completed operations
* + Isolation - concurrent operations should not have to worry about each other
* + Durability - the database shouldn’t randomly corrupt data
```c++
BEGIN TRANSACTION ;
    SELECT { stuff };
    UPDATE { more stuff };
    UPDATE { even more stuff };
END TRANSACTION ;
```
* Transactional Memory
* + Load-Linked / Store-Conditional (ARM, PowerPC)
* + - load-linked begins transaction on a world
* + - store-conditional commits it
* + - only modify one word in memory
* + Fully Transactional Memory (Software)
* + - All modification to memory are private
* + - commit applies all
* + - fails if any memory location has been modified
* + - Multiword LL/SC
* + - Keep copy of all memory, Lock all memory for update
* + Hardware Transactional Memory
* + - add instruction for begin/commit
* + - handle all updates via caches/buffers
* + - [Intel Haswell](http://www.informit.com/articles/article.aspx?p=2142912)
* + - - Hardware Lock Elision
* + - - [TSX](https://en.wikipedia.org/wiki/Transactional_Synchronization_Extensions)
* + - - - side-channel attack
* + Hardware-Assisted Transactional Memory: Rock
* + - UltraSPARC from Sun
* + - Cancelled by Oracle
* + - `chkpt/commit`
* + Software Transaction Memory
* + - Emulate HTM
* + - Indirection and Swizzling
* + - - create copy => modify copy => update pointer via CAS => failed if pointer modifed by other copy
* + - Lock must be held for duration of an update
* + - - lock on ranges of memory (one per page)
* + - - acquire in global same order (avoid deadlock)
```c
void atomic_increment ( void ) {
    do {
        begin_transaction();
        int a = atomic_get();
        a++;
        atomic_set(a);
    } while ( end_transaction ());
}

atomic {
    if (i == 0)
    retry;
    next = queue [i];
    i++;
};

/*
atomic keyword defines a transaction
retry restarts transaction, blocks until a memory address that
has been read already is modified by something else
Transaction automatically restarted if it fails
*/
```
* STM and Haskell
* + side effects in Monads
* + Monad handles merging results, retrying failed transactions