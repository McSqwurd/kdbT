/ q tick.q sym . -p 5001 </dev/null >foo 2>&1 &   / -> call to start up tickerplant

/2014.03.12 remove license check
/2013.09.05 warn on corrupt log
/2013.08.14 allow <endofday> when -u is set
/2012.11.09 use timestamp type rather than time. -19h/"t"/.z.Z -> -16h/"n"/.z.P
/2011.02.10 i->i,j to avoid duplicate data if subscription whilst data in buffer
/2009.07.30 ts day (and "d"$a instead of floor a)
/2008.09.09 .k -> .q, 2.4
/2008.02.03 tick/r.k allow no log
/2007.09.03 check one day flip
/2006.10.18 check type?
/2006.07.24 pub then log
/2006.02.09 fix(2005.11.28) .z.ts end-of-day
/2006.01.05 @[;`sym;`g#] in tick.k load
/2005.12.21 tick/r.k reset `g#sym
/2005.12.11 feed can send .u.endofday
/2005.11.28 zero-end-of-day
/2005.10.28 allow`time on incoming
/2005.10.10 zero latency




"kdb+tick 2.8 2014.03.12"

/q tick.q SRC [DST] [-p 5010] [-o h]
system"l tick/", (src:first .z.x,enlist"sym"),".q"

// 
if[not system"p"; system"p 5010"]

\l tick/u.q   / Loading in u.q script
\d .u   / Going into .u namespace


// Defining the .u.ld function 
// This function is used to create a new TP log file and establish a connection to it, input x=Date (for which we want to create TP LogFile)
ld:{if[not type key L::`$(-10_string L),string x;   / Check for existance, done by constructing file name
    
    .[L;();:;()]];   / Creates an empty TP LogFile
    
    i::j::-11!(-2;L);   / Assign number of valid chunks and number of lines (their sizes) to i and j respectively - if not corrupted, just returns number of valid chunks
    
    if[0<=type i;-2 (string L)," is a corrupt log. Truncate to length ",(string last i)," and restart";exit 1];   / Error trap incase log file is corrupted 
    
    hopen L};   / If log file is not corrupted, establish connection
    
    / Returns the file handle to the TP LogFile for the current day 


// Function validates all tables defined in the schema file, x = name of schema file (string), y = path to dir where TP log / db should be
tick:{init[];   / Sets up .u.t and .u.w

    if[not min(`time`sym~2#key flip value@)each t;'`timesym];   / Ensures all tables have time and sym as their first columns

    @[;`sym;`g#]each t;d::.z.D;   / Grouped attribute is applied to the sym column of each table

    if[l::count y;L::`$":",y,"/",x,10#"."; l::ld d]};   / Execeutes .u.ld to create TP logFile and establish connection if path exists (10 dots appended at end to serve as temporary placeholder for actual date)


// Defining the .u.endofday function
endofday:{end d;   / Executes .u.end[.u.d] -> sends async message to all real time subs, triggering respective end of day functions

    d+:1;   / Increments TPs current date (.u.d) by 1 to account for start of new day 

    if[l;hclose l;   / Closes connection to current TP logFile

    l::0(`.u.ld;d)]};   / Generates new TP logFile for new date and estables connection to newly created file
// NOTE: invoke .u.ld with one of three system handles: 0 -> system handle for cohnsole, 1 -> system handle for stdout, 2 -> system handle for stderr


// Defining the .u.ts function - responsible for verifying weather we have reached the end of the day passed midnight
// x -> date - the current date - .z.D is passed
ts:{if[d<x;   / If current date is less than input date i.e

    if[d<x-1;system"t 0";'"more than one day?"];   / Ensure we have only published data for only 1 day by comparing .u.d to x-1 (date preceeding current).

    endofday[]]};   / If true, call .u.endofday[]



// IMPORTANT NOTE: Tickerplant will behave different depending on the mode (tick or batch) ***********************



// BATCH MODE code for tickerplant
if[system"t";   / Check weather timer interval has been set  - if true (i.e. if in batch mode:)

    // INPUT - timestamp -> .z.ts is invoked with current timestamp
    .z.ts:{pub'[t;value each t];   / Publish all updates that have been batched in memory to real time subscribers, value each .u.t -> list of data, with each item representing a complete content of a specific table, hence -> whole expression forms a pair of lists that include all table names and their respective data

            @[`.;t;@[;`sym;`g#]0#];   / Use ammend-at to clear contents of the tables in memory and applies the grouped attriubute to the sym column of each table

            i::j;ts .z.D};   / Set the global variable .u.j to .u.i, updating the number of messages stored in the TP logFilem the calling .u.ts with the current date to check if midnight has been reached 


    // .u.upd function is triggered by feedhandler whenever it publishes data to the tickerplant
    // .u.upd specific - BATCH MODE
    upd:{[t;x]   / x -> the table name of the data published by the Feedhandler (symbol), y -> the data to be published. This can be in form of a single record or a list of records (data)

        if[not -16=type first first x;   / Verify the data type of the initial element in the incoming data is type timespan - 'first first' ensures first element - as incoming data could be a single row or multiple rows - basically checks if incoming data does not contain a time column

            if[d<"d"$a:.z.P;.z.ts[]];   / Check TPs date is ealier than the current date - if earlier, we trigger .z.ts (publishing data in memory and calling endofday[]), if TPs date is not preceeding current date (i.e. same day) -> convert present date and timespan into a timespan datatype to obtain current timespan (serves as tickerplants time)
            a:"n"$a;   / a: current timespan

            x:$[0>type first x;a,x;(enlist(count first x)#a),x]];   / CASE 1: recieved a single record and the first element is an atom -> prepend current timespan to the single record we recieve, updated and stored in variable x,      CASE 2: recieved multiple records -> need to create list of timespans with same length of number of records revieved.  These modified records are stored in TPs memory

        // From here, the first column of the records that are to be inserted now contain timespan values (i.e. sent by feedhandler or now recorded by the TP

        t insert x;   / insert received records into their respective tables in memeory and store them in the TP logFile (assuming file exists)
    
        if[l;l enlist (`upd;t;x);j+:1];}];   / After verifying handle to TP logFile -> formulate parse tree (function name for when TP logFile is replayed, table name for stored data, data iself).  -> ONLY EXECUTED IF TP logFile exists, -> these records are appended to TP logFile, .u.j is then increased by 1



// TICK MODE code for tickerplant
if[not system"t";system"t 1000";   / Timer to verify every second whether we have reached end of day or not

    .z.ts:{ts .z.D};   / System func to be invoked on each timer interval defined above - as data is published instantly, only purpose of .z.ts is to invoke .u.ts which verifies if we are past midnight or not 

    // lOW LATENCY ACHIEVED - as data is published instantly on TICK MODE

    // .u.upd specific - TICK MODE
    upd:{[t;x]ts"d"$a:.z.P;   / calls .u.ts to verify if we have reached end of day or not (check if end of day actions need performed or not), 

        if[not -16=type first first x;   / Checks if incoming records contain a timespan as first column - if not - prefixes them with current timespan.
            a:"n"$a;
            x:$[0>type first x;a,x;(enlist(count first x)#a),x]];   / Distinguishes between a single record or a bulk record to adapt the data.  (A single record receives a singular atom timespan as a prefix, while a bulk update generates a list of timespans, matching the number of received records, and applies it as a prefix.)

        f:key flip value t;   / Obtains column names of received data by target table to dictionary format (keys=tables column names) - value is required to access the content of the table t, even if its empty
        
        pub[t;$[0>type first x;enlist f!x;flip f!x]];   / Publish data to all real-time subscribers -> first check if single record or bulk update -> SINGLE: create a dictioanry by mapping the column names stored in f to the actual data stored in x (creating column dictionary) then enlist to a single row table, BULK UPDATE: map column names to the list of data records, creating column dictioanry to then be flipped
        
        if[l;l enlist (`upd;t;x);i+:1];}];   / Inserting received data into the TP logFile, provided it exists, and update overall message count .u.i by one

// Exiting namespace
\d .

// Calling .u.tick
.u.tick[src;.z.x 1];   / args= name of file with schema definition and designated path to store TP logFile


\
 globals used
 .u.w - dictionary of tables->(handle;syms)
 .u.i - msg count in log file
 .u.j - total msg count (log file plus those held in buffer)
 .u.t - table names
 .u.L - tp log filename, e.g. `:./sym2008.09.11
 .u.l - handle to tp log file
 .u.d - date


/test
>q tick.q
>q tick/ssl.q

/run
>q tick.q sym  .  -p 5010       /tick    / -> our 'sym' file is schema
>q tick/r.q :5010 -p 5011       /rdb
>q sym            -p 5012       /hdb
>q tick/ssl.q sym :5010         /feed















