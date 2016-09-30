#Ksql
Ksql è un progetto svolto presso l'università degli studi di Verona basato su K-Framework.

Il programma prende in input uno script SQL ne verifica la corretta sintassi e crea un database virtuale con le relative tabelle e tuple al fine di verificarne la sua correttezza.

Ecco la sintassi delle funzioni implementate:

// ------ comandi principali SQL ------ //
syntax Stmt ::=

"CREATE DATABASE" Id ";"

"CREATE TABLE" Id "(" Attributes ")" ";"

"ALTER TABLE" Id AlterCommands ";"

"DROP TABLE" Tables ";"

"INSERT INTO" Id "(" Columns ")" "VALUES" "(" Values ")" ";"

"UPDATE" Id "SET" Substitutions ";"

"UPDATE" Id "SET" Substitutions "WHERE" Conditions ";"

"SELECT" "*" "FROM" Id ";"


// ------ tipi SQL ------ //

VARCHAR

SMALLINT

// ------ Attributi SQL ------ //	

PRIMARY KEY

// ------ Valori SQL ------ //

int

String

null

// ------ Funzioni SQL ------ //
ADD

ADD COLUMN

DROP

DROP COLUMN

DROP IF EXISTS 

DROP COLUMN IF EXISTS

RENAME COLUMN Id TO Id

RENAME TO Id

// ------ Booleani SQL ------ //

AND

OR 


