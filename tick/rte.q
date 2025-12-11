// RTE Process

// assign port
\p 5610

// load schema file
\l schema.q

// open IPC connection to TP
h_tp: hopen 5666

//  Create an empty keyed table using sym as the key and the schema of quote
empTabQuote:`sym xkey quote

//  Create an empty keyed table using sym as the key and the schema of trade
empTabTrade:`sym xkey trade

//if the table is trade or quote, upsert into relevant table
upd:{[tab; data] 
    $[tab~`trade; `empTabTrade upsert data; tab~`quote; `empTabQuote upsert data]};

// Subscribe to `trade and `quote tables from TP process
h_tp ".u.sub[`;`]"







