// RDB Process

// set rdb port
\p 5668

// load schema
\l schema.q

// open IPC handle to TP
h_tp: hopen 5666

//  update table with new data
upd:{[tab;data] tab upsert  data}



/ THIS PART DOES NOT NEED CHANGED FROM GIT HUB- NOTE THE `:db file handle in .Q.hdpf

// get the ticker plant and hdb port
.u.x:.z.x,(count .z.x)_(":5001";":5015");


// end of day: save, clear, hdb reload


// Function to send Quotes to TP
sendQuoteToTP:{neg[h_tp](".u.upd"; `quote; quoteData[])};

// Function to send Trades to TP
sendTradeToTP:{neg[h_tp](".u.upd"; `trade; tradeData[])};


// Defining .u.end function - this will be called by.u.endofday[]
.u.end:{  t: tables `.;                           // get all in-memory tables

  	t@: where `g = attr each t@\:`sym;     // only keep grouped tables on `sym -> makes use of apply @ operator

  	.Q.hdpf[`$":" , .u.x 1; `:db; x; `sym]; // HDB write - saves all in memory tables to disk and clears them from memory
  
  	@[; `sym; `g#] each t;                 // clear sym column from memory (keeps structure)
	
  	};

// Subscribe to `trade` and `quote` tables from the TP process (all cols)
h_tp ".u.sub[`;`]"












