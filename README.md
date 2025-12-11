# kdbT

This is a vanilla kdb tick architecture with annotated tickplant code.


STEPS TO RUN:

(1): Initialise Tickerplant -> q tick.q schema . -p 5666 (Tick mode)

the Tickerplant (tick.q script) can also be run in batch mode, to initialise in batch mode (every second): -> q tick.q schema . -p 5666 -t 1000

(2): Initialise Feedhandler -> q feedSim.q

(3): Initialise RDB -> q rdb.q

To save data to disk, and perform end of day functionality, run .u.endofday[] on the tickerplant - this will create 'db' directory containing partitions

(4): Initialise RTE -> q rte.q

(5): Initialise HDB -> q hdb.q (ensure .u.endofday[] has first been called so can load database)


-------------------------------

Some internal functionality like .u.end has been defined on the rdb.q script, however r.q has been made for proper deployment of further functionality 






