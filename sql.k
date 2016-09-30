// Core di SQL in K

//sintassi
module SQL-SYNTAX 
	
// ------ comandi SQL ------ //
syntax Stmt ::=	"CREATE DATABASE" Id ";"
			|	"CREATE TABLE" Id "(" Attributes ")" ";"
			|	"ALTER TABLE" Id AlterCommands ";"
			|	"DROP TABLE" Tables ";"
			|	"INSERT INTO" Id "(" Columns ")" "VALUES" "(" Values ")" ";"
			|	"UPDATE" Id "SET" Substitutions ";"
			|	"UPDATE" Id "SET" Substitutions "WHERE" Conditions ";"
			|	"SELECT" "*" "FROM" Id ";"


syntax Stmts ::= 	Stmt
				|	Stmt Stmts

// ------ tipi SQL ------ //
syntax Type ::=	"VARCHAR"
			|	"VARCHAR" "(" Int ")"
			|	"SMALLINT"

// ------ comandi e tipi di supporto utilizzati solo da K ------ //
syntax Command ::=	"ADD SCHEMA" Id "(" Attributes ")" ";"
				|	"SAVE KEY" Id "(" Columns ")" "VALUES" "(" Values ")" ";"

syntax Attribute ::= 	Id Type	
					|	Id Type	"PRIMARY KEY"

syntax Attributes ::= 	List{Attribute,","}
	
syntax Columns ::= 	List{Id,","}

syntax Value ::=	Int
				|	"'" String "'"
				|	"null"

syntax Values ::=	List{Value,","}

syntax Add ::=	"ADD"	
			|	"ADD COLUMN"

syntax AddAttribute ::=	Add Attribute

syntax AddAttributes ::=	List{AddAttribute,","}

syntax Drop ::=	"DROP"	
			|	"DROP COLUMN"
			|	"DROP IF EXISTS" 
			|	"DROP COLUMN IF EXISTS"

syntax DropAttribute ::=	Drop Id

syntax DropAttributes ::= 	List{DropAttribute,","}

syntax RenameColumnAttribute ::= "RENAME COLUMN" Id "TO" Id

syntax RenameColumnAttributes ::= List{RenameColumnAttribute,","}

syntax Tables ::= 	List{Id,","}

syntax RenameTable ::=	"RENAME TO" Id

syntax Ktype ::=	Int | String

syntax Exp ::=	Bool | Ktype | Id
               	| "(" Exp ")"             [bracket]
               	| "-" Exp                 [strict]
               	> left:
                  Exp "*" Exp             [strict, left]
               	| Exp "/" Exp             [strict, left]
               	> left:
                  Exp "+" Exp             [strict, left]
               	| Exp "-" Exp             [strict, left]
               	> left:
                  Exp "AND" Exp            [strict(1), left]
               	| Exp "OR" Exp            [strict(1), left]

syntax Exps ::= List{Exp,","}          [strict]

//sostituzioni dell'update
syntax Substitution ::=	Id "=" "null"
					|	Id "=" "'" String "'"
					|	Id "=" "'" Int "'"

syntax Substitutions ::=	List{Substitution,","}

//condini per l'update
syntax Condition ::=	Id "=" "null"
					|	Id "=" "'" String "'"
					|	Id "=" "'" Int "'"

syntax Conditions ::=	Condition
					|	Conditions AndOr Conditions

syntax AndOr ::=	"AND"
				|	"OR" 

//L'idea è di avere un comando tipo: ALTER TABLE Id AlterCommands
syntax AlterCommand ::=	AddAttribute
					|	DropAttribute
					|	RenameColumnAttribute
					|	RenameTable

syntax AlterCommands ::=	List{AlterCommand,","}


endmodule

//semantica
module SQL
	imports SQL-SYNTAX

	configuration 	<T color="yellow">
						<k color="green"> $PGM:Stmts </k>

						<outputs color="red"> 

							<output multiplicity="*" color="cyan"> .Map </output>

						</outputs>

						<database color="orange">
							<database-name color="blue"> .Set </database-name>

							<tables color="LightSkyBlue">
								<table multiplicity="*" color="red"> 
									<table-name color="blue"> .Set </table-name>
									<schema color="Orchid"> .Map </schema>
									<key color="purple"> .Set </key>
									<keyvalues> .Set </keyvalues>
									<numvalues color="LightSkyBlue"> #counter </numvalues>

									<values multiplicity="*" color="gray">
										<value color="yellow"> 
											<numvalue color="cyan"> #counter </numvalue>
											<val color="purple"> .Map </val> 
										</value>
									</values>

								</table>
							</tables> 

						</database>

						<count> #counter </count>
				  	</T>

//valuta il primo comando poi il secondo gruppo di comandi
rule S1:Stmt S2:Stmts => S1 ~> S2

// ------ CREATE DATABASE  ------- //
//crea il database
rule <k> CREATE DATABASE N:Id ; => .K ... </k>
	<database-name> .Set => SetItem(N) </database-name>
	<count> J:Int => 0 </count>

// ------ CREATE TABLE  ------- //
//crea la tabella senza attributi
rule <k> CREATE TABLE N:Id (A:Attributes) ; => ADD SCHEMA N ( A ) ; ... </k>
       ( . => <table>...
               	<table-name> SetItem(N) </table-name>
               	<schema> .Map </schema>
               	<key> .Set </key>
               	<numvalues> 0 </numvalues>
               	<values>
					.Bag
				 </values>
         ... </table> )

//comando di supporto: aggiunge gli attributi alla tabella
rule <k> ADD SCHEMA N:Id ( X:Id T:Type , A:Attributes => A) ; ... </k>
	<table-name> SetItem(N) </table-name>
	<schema> M:Map => M[X <- T] </schema>

rule <k> ADD SCHEMA N:Id ( X:Id T:Type PRIMARY KEY , A:Attributes => A) ; ... </k>
	<table-name> SetItem(N) </table-name>
	<schema> M:Map => M[X <- T] </schema>
	<key> .Set => SetItem(X) </key>

//se gli attributi sono finiti consuma il comando( lo rimpiazza con .K cioè il comando vuoto di tipo K )
rule <k> ADD SCHEMA N:Id ( .Attributes ) ; => .K ... </k>

// ------ ALTER TABLE ADD o ADD COLUMN  ------- //
//aggiunge gli attributi alla tabella
rule <k> ALTER TABLE N:Id ( Add X:Id T:Type , A:AddAttributes => A ); ... </k>
	<table-name> SetItem(N) </table-name>
	<schema> M:Map => M[X <- T] </schema>

//se l'attributo è uno solo consuma il comando e aggiunge l'attributo
rule <k> ( ALTER TABLE N:Id Add X:Id T:Type ; ) => .K ... </k>
	<table-name> SetItem(N) </table-name>
	<schema> M:Map => M[X <- T] </schema>

rule <k> ALTER TABLE  N:Id .AddAttributes ; => .K ... </k>

// ------ ALTER TABLE DROP o DROP COLUMN o DROP IF EXISTS o DROP COLUMN IF EXISTS ------- //
//elimina la colonna o le colonne in questione
rule <k> ALTER TABLE N:Id Drop X:Id , D:DropAttributes => D ; ... </k>
	<table-name> SetItem(N) </table-name>
	<schema> M:Map X |-> _ => M </schema>

rule <k> ( ALTER TABLE N:Id Drop X:Id ; ) => .K ... </k>
	<table-name> SetItem(N) </table-name>
	<schema> M:Map X |-> _ => M </schema>

rule <k> ALTER TABLE  N:Id .DropAttributes ; => .K ... </k>

// ------ ALTER TABLE RENAME COLUMN ------- //
//rinomina la colonna in questione
rule <k> ALTER TABLE N:Id RENAME COLUMN X:Id TO B:Id ; => .K ... </k>
	<table-name> SetItem(N) </table-name>
	<schema> M:Map X |-> T:Type => M[B <- T] </schema>

// ------ ALTER TABLE RENAME TABLE ------- //
rule <k> ALTER TABLE N:Id RENAME TO X:Id ; => .K ... </k>
	<table-name> SetItem(N) => SetItem(X) </table-name>

// ------ DROP TABLE ------- // 
//elimina la tabella o le tabelle in questione
rule <k> DROP TABLE N:Id , T:Tables => T ; ... </k>
	( <table>...
               <table-name> SetItem(N) </table-name>
         ... </table> => . )

rule <k> DROP TABLE N:Id ; => .K ... </k>
	( <table>...
               <table-name> SetItem(N) </table-name>
         ... </table> => . )
//(lista vuota)
rule <k> DROP TABLE .Tables ; => .K ... </k>

// ------ INSERT INTO ------- // 
rule <k> INSERT INTO N:Id ( C:Columns ) VALUES ( V:Values ) ; => SAVE KEY N:Id ( C:Columns ) VALUES ( V:Values ) ; ... </k>	
		<table-name> SetItem(N) </table-name>
		<schema> M:Map </schema>
		<key> Z:Set </key>
		<keyvalues> S:Set </keyvalues>
		<numvalues> L:Int => L +Int 1 </numvalues>
			<values> ...

				( . => <value> ...
							<numvalue> inc(L) </numvalue>
							<val> insertValues( C , V , M ) </val>
						... </value> )
				
			... </values>
		when (size(C) ==Int size(V) andBool charControl(M,C,V) andBool checkKey(C,Z,V,S))

//salva i valori della primary key in un set
rule <k> SAVE KEY N:Id ( C:Id , G:Columns ) VALUES ( V:Value , W:Values ) ; => SAVE KEY N ( G ) VALUES ( W ) ; ... </k>	
		<table-name> SetItem(N) </table-name>
		<key> Z:Set </key>
		<keyvalues> S:Set => S SetItem(V) </keyvalues>
		//solo quando C è chiave
		when ( C in Z )

//se non è una primary key va avanti a controllare senza fare nulla
rule <k> SAVE KEY N:Id ( C:Id , G:Columns ) VALUES ( V:Value , W:Values ) ; => SAVE KEY N ( G ) VALUES ( W ) ; ... </k>	
		<table-name> SetItem(N) </table-name>
		<key> Z:Set </key>
		//solo quando C non è chiave
		when notBool( C in Z )

rule <k> SAVE KEY N:Id ( .Columns ) VALUES ( .Values ) ; => .K ... </k>	

// ------ UPDATE ------- //
//update semplice per interi
rule <k> UPDATE N:Id SET ( I:Id = ' S:Int ' , Z:Substitutions ) ; => UPDATE N SET ( I = ' S ' , Z ) ; ... </k>		
		<table-name> SetItem(N) </table-name>
		<schema> O:Map </schema>
		<numvalues> X:Int </numvalues>
		<values> ...

			<value> 
				<numvalue> L:Int </numvalue>
				//recupera il valore data la chiave e lo aggiorna
				<val> M:Map => updateMap( M , I |-> S ) </val>
			</value>

		... </values>
		<count> J:Int => J +Int 1 </count>
		//solo quando ci sono ancora value e il tipo inserito è corretto
		when ( inc(J) ==Int L andBool J <=Int X andBool typeChecker( O , I , SMALLINT , "null" ) )

//update semplice per stringhe
rule <k> UPDATE N:Id SET ( I:Id = ' S:String ' , Z:Substitutions ) ; => UPDATE N SET ( I = ' S ' , Z ) ; ... </k>		
		<table-name> SetItem(N) </table-name>
		<schema> O:Map </schema>
		<numvalues> X:Int </numvalues>
		<values> ...

			<value> 
				<numvalue> L:Int </numvalue>
				//recupera il valore data la chiave e lo aggiorna
				<val> M:Map => updateMap( M , I |-> ' S ' ) </val>	
			</value>

		... </values>
		<count> J:Int => J +Int 1 </count>
		//solo quando ci sono ancora value, il tipo inserito è corretto e la stringa è accettabile
		when ( inc(J) ==Int L andBool J <=Int X andBool typeChecker( O , I , VARCHAR(100) , S ) )

//update semplice per i valori nulli
rule <k> UPDATE N:Id SET ( I:Id = null , Z:Substitutions ) ; => UPDATE N SET ( I = null , Z ) ; ... </k>		
		<table-name> SetItem(N) </table-name>
		<schema> O:Map </schema>
		<numvalues> X:Int </numvalues>
		<values> ...

			<value> 
				<numvalue> L:Int </numvalue>
				//recupera il valore data la chiave e lo aggiorna
				<val> M:Map => updateMap( M , I |-> null ) </val>
			</value>

		... </values>
		<count> J:Int => J +Int 1 </count>
		//solo quando ci sono ancora value
		when ( inc(J) ==Int L andBool J <=Int X )

//se ha finito l'update della prima sostituzione passa alle successive
rule <k> UPDATE N:Id SET ( _ , Z:Substitutions ) ; => UPDATE N:Id SET ( Z ) ; ... </k>	
		<table-name> SetItem(N) </table-name>
		<numvalues> L:Int </numvalues>
		//azzera il contatore
		<count> J:Int => 0 </count>
		//solo quando non ci sono piu value
		when ( inc(J) >Int L )

rule <k> UPDATE N:Id SET .Substitutions ; => .K ... </k>	
		<count> J:Int => 0 </count>	//azzera il contatore

//update complessa per interi
rule <k> UPDATE N:Id SET ( I:Id = ' S:Int ' , Z:Substitutions ) WHERE ( C:Conditions ) ; => UPDATE N:Id SET ( I = ' S ' , Z ) WHERE ( C ) ; ... </k>		
		<table-name> SetItem(N) </table-name>
		<schema> O:Map </schema>
		<numvalues> X:Int </numvalues>
		<values> ...

			<value> 
				<numvalue> L:Int </numvalue>
				//recupera il valore data la chiave e lo aggiorna
				<val> M:Map => updateMapConditioned( M , I |-> S , C ) </val>
			</value>

		... </values>
		<count> J:Int => J +Int 1 </count>
		//solo quando ci sono ancora value e il tipo inserito è corretto e le condizioni sono verificate
		when ( inc(J) ==Int L andBool J <=Int X andBool typeChecker( O , I , SMALLINT , "null" ) )

//update complessa per stringhe
rule <k> UPDATE N:Id SET ( I:Id = ' S:String ' , Z:Substitutions ) WHERE ( C:Conditions ) ; => UPDATE N:Id SET ( I = ' S ' , Z ) WHERE ( C ) ; ... </k>		
		<table-name> SetItem(N) </table-name>
		<schema> O:Map </schema>
		<numvalues> X:Int </numvalues>
		<values> ...

			<value> 
				<numvalue> L:Int </numvalue>
				//recupera il valore data la chiave e lo aggiorna
				<val> M:Map => updateMapConditioned( M , I |-> ' S ' , C ) </val>
			</value>

		... </values>
		<count> J:Int => J +Int 1 </count>
		//solo quando ci sono ancora value e il tipo inserito è corretto e le condizioni sono verificate
		when ( inc(J) ==Int L andBool J <=Int X andBool typeChecker( O , I , VARCHAR(100) , S ) )

//update complessa per i valori nulli
rule <k> UPDATE N:Id SET ( I:Id = null , Z:Substitutions ) WHERE ( C:Conditions ) ; => UPDATE N:Id SET ( I = null , Z ) WHERE ( C ) ; ... </k>		
		<table-name> SetItem(N) </table-name>
		<numvalues> X:Int </numvalues>
		<values> ...

			<value> 
				<numvalue> L:Int </numvalue>
				//recupera il valore data la chiave e lo aggiorna
				<val> M:Map => updateMapConditioned( M , I |-> null , C ) </val>
			</value>

		... </values>
		<count> J:Int => J +Int 1 </count>
		//solo quando ci sono ancora value e il tipo inserito è corretto e le condizioni sono verificate
		when ( inc(J) ==Int L andBool J <=Int X )

//se ha finito l'update complessa della prima sostituzione passa alle successive
rule <k> UPDATE N:Id SET ( _ , Z:Substitutions ) WHERE ( C:Conditions ) ; => UPDATE N:Id SET ( Z ) WHERE ( C ) ; ... </k>	
		<table-name> SetItem(N) </table-name>
		<numvalues> L:Int </numvalues>
		//azzera il contatore
		<count> J:Int => 0 </count>
		//solo quando non ci sono piu value
		when ( inc(J) >Int L )

rule <k> UPDATE N:Id SET .Substitutions WHERE _; => .K ... </k>	
		//azzera il contatore
		<count> J:Int => 0 </count>

// ------ SELECT ------- //
//selct all
rule <k> SELECT * FROM N:Id ; => SELECT * FROM N ; ... </k>
		<table-name> SetItem(N) </table-name>
		<numvalues> X:Int </numvalues>
		<values> ...

			<value> 
				<numvalue> L:Int </numvalue>
				//recupera la mappa
				<val> M:Map </val>
			</value>

		... </values>
		<count> J:Int => J +Int 1 </count>

		<outputs> ...
			//aggiungo la mappa all'output
			( . => <output>
				M
			</output> )
		... </outputs>

		//solo quando ci sono ancora value
		when ( inc(J) ==Int L andBool J <=Int X )

//quando ha finito di aggiungere le mappe
rule <k> SELECT * FROM _ ; => .K ... </k>	
		<table-name> SetItem(N) </table-name>
		<numvalues> L:Int </numvalues>
		//azzera il contatore
		<count> J:Int => 0 </count>
		//solo quando non ci sono piu value
		when ( inc(J) >Int L )

// ------ FUNZIONI ------ //
//inserisce i valori nella tupla (null se non viene specificato il valore per qualche attributo)
syntax Map ::= "insertValues" "(" Columns "," Values "," Map ")"    [function]
rule insertValues ( C:Id , S:Columns , V:Value , W:Values , M:Map) => C |-> V insertValues( S , W , M -Map (C |-> (M[C])))
rule insertValues( .Columns , .Values , (X:Id |-> T:Type) M:Map) => X |-> null insertValues( .Columns , .Values , M )
rule insertValues( .Columns , .Values , .Map) => .Map

//controlla che il tipo sia quello giusto nello schema della tabella
syntax Bool ::= "typeChecker" "(" Map "," Id "," Type "," String ")"	[function]
rule typeChecker( (X:Id |-> T:Type) M:Map , I:Id , SMALLINT , _ ) => #if ( (X ==K I) andBool (T ==K SMALLINT) ) #then true #else typeChecker( M , I , SMALLINT , "null") #fi
rule typeChecker( (X:Id |-> T:Type) M:Map , I:Id , VARCHAR(_) , Z:String ) => #if ((X ==K I) andBool ((VARCHAR(charNumber( Z , T )) ==K T) orBool VARCHAR ==K T)) #then true #else typeChecker( M , I , VARCHAR(100) , Z ) #fi
rule typeChecker( .Map , _ , _ , _) => false

//ritorna l'intero del campo del VARCHAR in questione se la stringa passata è entro tale intero
syntax Int ::= "charNumber" "(" String "," Type ")"	[function]
rule charNumber( S:String , VARCHAR( I:Int )) => I
		when ( I >=Int lengthString(S) )

//aggiorna la mappa solo se sono soddisfatte le condizioni, altrimenti la lascia invariata
syntax Map ::= "updateMapConditioned" "(" Map "," Map "," Conditions ")"	[function]
rule updateMapConditioned( M:Map , O:Map , C:Conditions ) => #if (conditionChecker( M , C ) ==K true) #then updateMap( M , O ) #else M #fi

//verifica le condizioni dell'update
syntax Bool ::= "conditionChecker" "(" Map "," Conditions ")"	[function]
rule conditionChecker( M:Map , C:Conditions AND G:Conditions ) => (conditionChecker( M , C) andBool conditionChecker( M , G))
rule conditionChecker( M:Map , C:Conditions OR G:Conditions ) => #if (conditionChecker( M , C) ==K true) #then true #else (conditionChecker( M , G) ==K true) #fi
rule conditionChecker( (X:Id |-> V:Int) M:Map , I:Id = ' S:Int ' ) => #if ( (X ==K I) andBool (V ==Int S) ) #then true #else conditionChecker( M , I = ' S ' ) #fi
rule conditionChecker( (X:Id |-> ' V:String ' ) M:Map , I:Id = ' S:String ' ) => #if ( (X ==K I) andBool (V ==String S) ) #then true #else conditionChecker( M , I = ' S ' ) #fi
rule conditionChecker( (X:Id |-> null) M:Map , I:Id = null ) => #if ( X ==K I ) #then true #else conditionChecker( M , I = null ) #fi
rule conditionChecker( .Map , Conditions ) => false

//controlla che la stringa inserita sia entro la lunghezza definita in CREATE TABLE
syntax Bool ::= "charControl" "(" Map "," Columns "," Values ")"	[function]
rule charControl( M:Map , I:Id , C:Columns , ' S:String ' , V:Values ) => #if ( control( S , M[I]) ) #then ( charControl( M , C , V ) ) #else false #fi
rule charControl( M:Map , I:Id , C:Columns ,  S:Int , V:Values ) => charControl( M , C , V )
rule charControl( _ , .Columns , .Values ) => true

//funzione di supporto alla funzione charControl() che controlla effettivamente se la stringa inserita è accettabile
syntax Bool ::= "control" "(" String "," Type ")"	[function]
rule control( S:String , VARCHAR ( I:Int )) => true
		when ( I >=Int lengthString(S) )
rule control( S:String , VARCHAR ) => true

//controlla che si faccia l'inserimento dell'attributo chiave se esiste una primary key nella tabella
syntax Bool ::=	"checkKey" "(" Columns "," Set "," Values "," Set ")"	[function]
rule checkKey( C:Id , G:Columns , Z:Set , V:Value , W:Values , S:Set ) => #if ( (C in Z) orBool (Z ==K .Set) ) #then ( isNotAlreadyIn( C , V , S ) ) #else ( checkKey( G , Z , W , S ) ) #fi
rule checkKey( C:Columns, .Set , _ , _ , _ ) => true	//se la primary key non esiste nella tabella va bene

//controlla se la chiave inserita esiste gia
syntax Bool ::=	"isNotAlreadyIn" "(" Id "," Value "," Set ")"	[function]
rule isNotAlreadyIn( C:Id , V:Value , S:Set ) => #if ( V in S ) #then ( false ) #else ( true ) #fi

//calcola la dimensione della lista di colonne
syntax Int ::= "size" "(" Columns ")"	[function]
rule size( C:Id , S:Columns ) => 1 +Int size(S)
rule size(.Columns) => 0

//calcola la dimensione della lista di valori
syntax Int ::= "size" "(" Values ")"	[function]
rule size(V:Value , W:Values) => 1 +Int size(W)
rule size(.Values) => 0

//calcola la dimensione del bag
syntax Int ::= "size" "(" Bag ")"   [function]
rule size(BagItem(_) B:Bag) => 1 +Int size(B)
rule size(.Bag) => 0

//verifica se l'elemento K è nel bag
syntax Bool ::= K "in" Bag    [function]
rule K1 in BagItem(K2) B:Bag => (K1 =K K2) orBool (K1 in B)
rule _ in .Bag => false

//incrementa una variabile intera
syntax Int ::= "inc" "(" Int ")"	[function]
rule inc( I:Int ) => I +Int 1

//decrementa una variabile intera
syntax Int ::= "dec" "(" Int ")"	[function]
rule dec( I:Int ) => I +Int 1

endmodule