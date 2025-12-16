

// Permanantly add a user to authentication table
permAdd:{[userN; pass]   / Takes 2 arguments -> userN: username (string), pass: password (symbol)
    
    newT:("*S"; enlist ",") 0: `:users/users.csv;   / Load CSV into memory as a table

    newT:newT upsert (userN; pass);   / Add new user account to table

    `:users/users.csv 0: "," 0: newT   / Save and overwrite to original csv
    }


// Permanantly remove a user to authentication table
permRemove:{[userN]}









