CREATE DATABASE CryptoDB
GO

USE CryptoDB
GO


CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Some3xtr4Passw00rd';
GO

-- Creating asymmetric key

CREATE ASYMMETRIC KEY AsymKey1_Sales
WITH ALGORITHM = RSA_1024;

-- Protecting symmetric key with asymmetric key

CREATE SYMMETRIC KEY SymKey1_Sales
WITH ALGORITHM = AES_256
ENCRYPTION BY ASYMMETRIC KEY AsymKey1_Sales;

-- Sample credit card info tables

-- Nonencrypted credit card info
CREATE TABLE CreditCardInfo
(
  SalesOrderID int not null primary key,
  CreditCardNumber nvarchar(50),
  CreditCardExpirationDate datetime,
  TotalCharge money
);

-- Encrypted credit card info
CREATE TABLE EncryptedCreditCardInfo
(
  SalesOrderID int not null primary key,
  CreditCardNumber varbinary(150),
  CreditCardExpirationDate varbinary(150),
  TotalCharge varbinary(150)		
);

-- Generate random credit card info 

WITH Generate4Digits /* Generate 4 random digits */
AS
(
  SELECT SUBSTRING
  (
    CAST
      (
        ABS(CHECKSUM(NEWID())) % 10000 AS NVARCHAR(4)
      ) + N'0000', 1, 4
  ) AS Digits
),
CardNum /* Generate a 16 digit random credit card number */
AS
(
  SELECT N'0999-' + 
  (
    SELECT Digits
    FROM Generate4Digits
  ) + N'-' + 
  (
    SELECT Digits
    FROM Generate4Digits
  ) + N'-' +  
  (
    SELECT Digits
    FROM Generate4Digits
  ) AS CardNumber
),
DaysToExpire /* Get a random amount of days to expiration */
AS
(
  SELECT ABS(CHECKSUM(NEWID()) % 700) AS Days
)
INSERT INTO CreditCardInfo
(
  SalesOrderID,
  CreditCardNumber,
  CreditCardExpirationDate,
  TotalCharge	
)
SELECT 
  SalesOrderID,
  CardNumber,
  DATEADD(DAY, Days, OrderDate),
  TotalDue
FROM AdventureWorksLT2012.SalesLT.SalesOrderHeader
CROSS APPLY CardNum
CROSS APPLY DaysToExpire;

-- Query unencrypted credit card info

SELECT
  SalesOrderID,
  CreditCardNumber,
  CreditCardExpirationDate,
  TotalCharge	
FROM CreditCardInfo;


-- Open symmetric data encrypting key
OPEN SYMMETRIC KEY SymKey1_Sales
DECRYPTION BY ASYMMETRIC KEY AsymKey1_Sales;

-- Encrypt sample random credit card data
INSERT INTO EncryptedCreditCardInfo
(
  SalesOrderID,
  CreditCardNumber,
  CreditCardExpirationDate,
  TotalCharge	
)
SELECT 
  SalesOrderID,
  EncryptByKey(Key_Guid(N'SymKey1_Sales'), CreditCardNumber),
  EncryptByKey(Key_Guid(N'SymKey1_Sales'), CAST 
    (
      CreditCardExpirationDate AS varbinary(10)
    )
  ),
  EncryptByKey(Key_Guid(N'SymKey1_Sales'), CAST
    (
      TotalCharge AS varbinary(10)
    )
  )
FROM CreditCardInfo;

-- Query encrypted credit card info
SELECT
  SalesOrderID,
  CreditCardNumber,
  CreditCardExpirationDate,
  TotalCharge	
FROM EncryptedCreditCardInfo

-- Close data encrypting key
CLOSE SYMMETRIC KEY SymKey1_Sales;


-- Decrypting credit card data

-- Open symmetric data encrypting key
OPEN SYMMETRIC KEY SymKey1_Sales
DECRYPTION BY ASYMMETRIC KEY AsymKey1_Sales;

-- Decrypt previously encrypted credit card data
SELECT 
  SalesOrderID,
  CAST
  (
    DecryptByKey(CreditCardNumber) AS nvarchar(100)
  ) AS CreditCardNumber,
  CAST
  (
    DecryptByKey(CreditCardExpirationDate) AS datetime
  ) AS CreditCardExpirationDate,
  CAST
  (
    DecryptByKey(TotalCharge) AS money
  ) AS TotalDue
FROM EncryptedCreditCardInfo;

-- Close data encrypting key
CLOSE SYMMETRIC KEY SymKey1_Sales;
GO

DROP TABLE CreditCardInfo
GO

DROP TABLE EncryptedCreditCardInfo
GO

DROP SYMMETRIC KEY SymKey1_Sales
GO

DROP ASYMMETRIC KEY AsymKey1_Sales
GO

DROP MASTER KEY
GO