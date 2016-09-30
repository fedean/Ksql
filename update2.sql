//update2.sql

CREATE DATABASE Spy; 

CREATE TABLE Prova (Try SMALLINT , Pry VARCHAR(10), Cry VARCHAR);
INSERT INTO Prova (Try) VALUES (5);
INSERT INTO Prova (Try,Pry) VALUES (7,'"ciao"');

UPDATE Prova SET Try = '20' , Pry = '"miao"';

UPDATE Prova SET Try = '10' WHERE Pry = null OR Try = '20';