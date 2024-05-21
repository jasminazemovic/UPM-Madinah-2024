CREATE DATABASE CryptoDB
GO

USE CryptoDB
GO

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Some3xtr4Passw00rd';
GO

SELECT * 
FROM sys.symmetric_keys

-- Create new table for encryption process

CREATE TABLE EncryptedCustomer
(
  CustomerID   int NOT NULL PRIMARY KEY,
  FirstName    nvarchar (200),
  LastName     varbinary(200),
  CreditCard   varbinary(200),
  ExpMonth     varbinary(200),
  ExpYear      varbinary(200),
  EmailAddress nvarchar (200),
  Phone        nvarchar (200)
 );

 

-- Create a certificate
CREATE CERTIFICATE CertForSymKeyCustomer
ENCRYPTION BY PASSWORD = 'pGFD4bb925DGvbd2439587y'
WITH SUBJECT = 'Encryption of Symmetric key', 
EXPIRY_DATE = '20241212';
GO


-- Create a AES 256 symmetric key
CREATE SYMMETRIC KEY CustomerSymKey
WITH ALGORITHM = AES_256,
IDENTITY_VALUE = 'University of Prince Mugrin - Madinah'
ENCRYPTION BY CERTIFICATE CertForSymKeyCustomer;
GO

-- Encrypt data with a symmetric key

-- Open the key that's protected by certificate
OPEN SYMMETRIC KEY CustomerSymKey
DECRYPTION BY CERTIFICATE CertForSymKeyCustomer
WITH PASSWORD = 'pGFD4bb925DGvbd2439587y';
GO

SELECT
  P.BusinessEntityID, P.FirstName, P.LastName, CC.CardNumber, 
	CAST (CC.ExpMonth AS int), CC.ExpYear, EmailAddress, PP.PhoneNumber
FROM AdventureWorks2017.Person.Person AS P
	INNER JOIN AdventureWorks2017.Person.EmailAddress AS EA
ON P.BusinessEntityID = EA.BusinessEntityID
	INNER JOIN AdventureWorks2017.Person.PersonPhone AS PP
ON P.BusinessEntityID = PP.BusinessEntityID
	LEFT JOIN AdventureWorks2017.Sales.PersonCreditCard AS PCC
ON P.BusinessEntityID = PCC.BusinessEntityID
	LEFT JOIN AdventureWorks2017.Sales.CreditCard AS CC
ON PCC.CreditCardID = CC.CreditCardID


-- Encrypt the data
INSERT INTO EncryptedCustomer
(
  CustomerID,
  FirstName,
  LastName,
  CreditCard,
  ExpMonth,
  ExpYear,
  EmailAddress,
  Phone
)
SELECT
  P.BusinessEntityID,
  FirstName,
  EncryptByKey(Key_Guid('CustomerSymKey'), LastName),
  EncryptByKey(Key_Guid('CustomerSymKey'), CC.CardNumber),
  EncryptByKey(Key_Guid('CustomerSymKey'), CAST (CC.ExpMonth AS nvarchar)),
  EncryptByKey(Key_Guid('CustomerSymKey'), CAST (CC.ExpYear AS nvarchar)),
  EA.EmailAddress,
  PP.PhoneNumber
FROM AdventureWorks2017.Person.Person AS P
	INNER JOIN AdventureWorks2017.Person.EmailAddress AS EA
ON P.BusinessEntityID = EA.BusinessEntityID
	INNER JOIN AdventureWorks2017.Person.PersonPhone AS PP
ON P.BusinessEntityID = PP.BusinessEntityID
	LEFT JOIN AdventureWorks2017.Sales.PersonCreditCard AS PCC
ON P.BusinessEntityID = PCC.BusinessEntityID
	LEFT JOIN AdventureWorks2017.Sales.CreditCard AS CC
ON PCC.CreditCardID = CC.CreditCardID

GO

-- Close the key
CLOSE SYMMETRIC KEY CustomerSymKey;
GO 

-- View encrypted binary data

SELECT
  *
FROM EncryptedCustomer;
GO


-- Open the key that's protected by certificate
OPEN SYMMETRIC KEY CustomerSymKey
DECRYPTION BY CERTIFICATE CertForSymKeyCustomer
WITH PASSWORD = 'pGFD4bb925DGvbd2439587y';
GO

-- Decrypt the data
SELECT
  CustomerID,
  CAST(DecryptByKey(LastName) AS nvarchar(100)) AS DecryptedFirstName,
  LastName
FROM EncryptedCustomer;
GO

-- Close the key
CLOSE SYMMETRIC KEY CustomerSymKey;
GO

DROP SYMMETRIC KEY CustomerSymKey
GO

DROP CERTIFICATE CertForSymKeyCustomer
GO

DROP MASTER KEY
GO

USE master
GO

DROP DATABASE CryptoDB
GO