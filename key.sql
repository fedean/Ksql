//prova per primary key

CREATE DATABASE Spy;

CREATE TABLE Chiave (key SMALLINT , notkey VARCHAR(10) PRIMARY KEY);

INSERT INTO Chiave (key,notkey) VALUES (7,'"ciao"');
INSERT INTO Chiave (notkey,key) VALUES ('"aiao"',14);

//INSERT INTO Chiave (key) VALUES (10);

//INSERT INTO Chiave (key) VALUES (78);

INSERT INTO Chiave (notkey) VALUES ('"ciaone"');