# Power: A First-Class Architecture Design Constraint

**Trevor Mudge**

---



## Introduction

* written in 2001
* limiting power consumption is critical:
  * portable/mobile platforms
  * server farms
* ![image-20200107020121474](D:\OneDrive\Pictures\Typora\image-20200107020121474.png)
* rapid growth in power consumption is obvious
* chip die's power density also increases linearly



## Power Equations for CMOS Logic

* 3 equations for power-per-performance trade-offs for complementary metal-oxide semiconductor logic circcuits
* power consumption $$P = AVC^2 f + \tau AVI_{\text{short}} f + VI_{\text{leak}}$$
  * `f`: system operation
  * `A`: activity of the gates in the system (some gates do not switch per clock tick)
  * `C`: total capacitance seen by the gates' outputs
  * `V`: supply voltage
  * 1st component: dynamic power consumption caused by charging & discharging the capacitive load on each gate's output
    * most dominate factor
    * suggests that reduce power consumption is the most effective way
    * quadratic dependency
  * 2nd component: power expended as the result of the short-circuit current $I_{\text{short}}$, which momentarily $\tau$, flows between the supply voltage & ground, when CMOS logic gate's output switches
  * 3rd component: power lost from the leakage current regardless of the gate's state
* maximum-operating frequency: $$f_{\text{max}} \propto (V - V_{\text{threshold}})^2 / V$$
  * parallel processing, which involves splitting a computation in 2 and running it as 2 parallel independent tasks, hash to potential to cut the power in half without slowing the computation
* leakage current: $$I_{\text{leak}} \propto \exp (-q V_{\text{threshold}} / kT)$$
  * limited option for countering the effect of reducing `V` (also reduce threshold voltage), making leakage term appreciable
* ![image-20200107110940738](D:\OneDrive\Pictures\Typora\image-20200107110940738.png)



## Other quantities

* Peak power: upper limit of the system
* Dynamic power: sharp changes in power consumption can result in ground bounce / _di/dt_ noise that upsets logic voltage levels, ca using erroneous circuit behavior
* energy/operation raio
* MIPS/W
* energy $\times$ delay



## Reducing Power Consumption



### Logic

* clock tree 30% power

* Clock gating: turn off clock tree branches to latches / flip-flops whenever they are not used
  * poor design, can exacerbate clock skew
  * with more accurate timing analyzers, flexible design tools
* Half-frequency / half-swing clocks: half-frequency clock uses both edges of the clock to synchronize events
  * like Intel some port?
  * half swing clock swings only half of `V`
    * increases the latch design's requirement
    * produces great gain
* Asynchronous logic: don't have a clock
  * needing to generate completion signals
  * additional logic must be used at each register transfer
    * double-rail implementation
  * testing difficulty
  * absence of design tools
  * e.g. Amulet
  * good for globally asynchronous, locally synchronous systems



## Architecture

* exploiting parallelism: reduce power
* using speculation: permit computations to proceed beyond dependent instructions
* Memory systems
  * cache memory can dominate the chip area
  * frequency of memory access $\to$ dynamic power loss
  * leakage current $\to$ power loss
  * filter cache
    *  in front of L1 cache
    * intercept signal intended for the main cache
  * memory banking
    * usually in low-power designs
    * splits the memory into banks, activates only the bank presently in use
    * relies on reference-pattern having lot of spatial locality
    * suitable for instruction-cache organization ([[C: also GPU memory?]])
    * [channel, DIMM, rank, chip, bank, row/column](https://www.archive.ece.cmu.edu/~ece740/f11/lib/exe/fetch.php?media=wiki:lectures:onur-740-fall11-lecture25-mainmemory.pdf)
* Buses
  * significant source of power loss
  * especially interchip buses (often wide)
  * encode the address lines into Gray code
    * address changes (from cache refills) are often sequential
    * counting in Gray code switches the least number of signals
  * transmitting difference between successive address values? similar to Gray code
  * compressing information in address lines
    * integrated into bus controllers for interchip signaling
  * reduce code overlays (DSP techniques)
* Parallel processing & pipelining
  * reduce power consumption in CMOS system
  * signal-processing algorithms often possess a significant degree of parallelism
    * DSP chips



### Operating System

* known comptuation's deadline $\to$ adjust frequency
* allow OS to set the voltage (by writing a regsiter)
* scheduler its voltage needs
  * don't need application modifications
  * detecting best timing for scaling back is difficult



## What can we do with a high MIPS/W device

* omitted



## Future challenge

* leakage current limitation
* submicron dimensions, supply must be reduced to avoid damaging electric fields, in turn reducing threshold voltage
  * $\to$ leakage becomes the dominant source of power consumption
  * $\to$ increase in chip temperature, increase in the thermal voltage, thermal runaway
* solutions
  * 2 types of field-effect transistors (voltage clustering): low threshold voltage devices for high-speed paths + high threshold voltage devices for not critical paths









## Motivation

## Summary

## Strength

## Limitation & Solution



