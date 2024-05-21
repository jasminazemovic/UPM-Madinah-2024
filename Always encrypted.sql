/*
	1. Kreiranje nove baze podataka
*/


CREATE DATABASE Hotel
GO

USE Hotel
GO

/*
	2. Kreiranje tabela Gosti
*/


CREATE TABLE Gosti
(
	GostID int IDENTITY (1,1) CONSTRAINT PK_GostID PRIMARY KEY,
	Titula nvarchar (10) NULL,
	Prezime nvarchar (50) NOT NULL,
	Ime nvarchar (50) NOT NULL,
	Email nvarchar (100) NOT NULL CONSTRAINT UQ_EMail UNIQUE,
	BrojTelefona nvarchar (20) NULL,
	BrojKreditneKartice nvarchar (50)  NULL,
	KorisnickoIme nvarchar (100) NOT NULL,
	Lozinka nvarchar (12) NOT NULL
)
INSERT INTO Gosti
SELECT 

	P.Title, 
	P.LastName, 
	P.FirstName, 
	EA.EmailAddress, 
	PP.PhoneNumber, 
	CC.CardNumber,
	P.FirstName+'.'+P.LastName,
	SUBSTRING (REVERSE (P.LastName),2,4)+
	SUBSTRING (REVERSE (P.FirstName),2,2)+
	SUBSTRING (CAST (P.rowguid AS nvarchar (100)),10,6)
	
FROM 
	AdventureWorks2014.Person.Person AS P
	INNER JOIN
	AdventureWorks2014.Person.EmailAddress AS EA
		ON P.BusinessEntityID = EA.BusinessEntityID
	INNER JOIN
	AdventureWorks2014.Person.PersonPhone AS PP
		ON P.BusinessEntityID = PP.BusinessEntityID
	LEFT JOIN
	AdventureWorks2014.Sales.PersonCreditCard AS PCC
		ON PP.BusinessEntityID = PCC.BusinessEntityID
	LEFT JOIN
	AdventureWorks2014.Sales.CreditCard AS CC
		ON PCC.CreditCardID = CC.CreditCardID

SELECT * FROM Gosti
-- column encryption setting=enabled