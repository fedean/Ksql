//select.sql

CREATE DATABASE Spy; 

CREATE TABLE Prova (Try SMALLINT , Pry VARCHAR(10), Cry VARCHAR);
INSERT INTO Prova (Try) VALUES (5);
INSERT INTO Prova (Try,Pry) VALUES (7,'"ciao"');

UPDATE Prova SET Try = null WHERE Cry = null AND Try = '7';

SELECT * FROM Prova;

UPDATE Prova SET Try = '20' , Pry = '"miao"';