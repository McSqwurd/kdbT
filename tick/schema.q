// Schema File (also known as a sym file in different systems)

// Defining trade schema
trade:([] time:`timespan$();
          sym:`$();
	      price:`float$();
          size:`long$();
          side:`$();
          ex:`$() );


// Definining quote schema
quote:([] time:`timespan$();
          sym:`$();
          ask:`float$();
	      bid:`float$();
          askSize:`long$();
	      bidSize:`long$();
          mode:`long$());















