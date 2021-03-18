DROP DATABASE IF EXISTS FamilyAccounting
GO
CREATE DATABASE FamilyAccounting
GO
USE FamilyAccounting;
GO

DROP TABLE IF EXISTS
	Wallets,
	Cards,
	Persons,
	Actions,
	Categories;
GO

CREATE TABLE Persons (
	id				INT PRIMARY KEY IDENTITY,
	name			VARCHAR(50) NOT NULL,
	surname			VARCHAR(50) NOT NULL,
	email			VARCHAR(50) NOT NULL,
	phone			VARCHAR(50) NOT NULL,
	inactive		BIT NOT NULL DEFAULT 0,
)
GO
CREATE TABLE Wallets (
	id				INT PRIMARY KEY IDENTITY,
	id_person		INT NOT NULL FOREIGN KEY REFERENCES Persons,
	description		VARCHAR(50) NOT NULL,
	inactive		BIT NOT NULL DEFAULT 0,
)
GO
CREATE TABLE Cards (
	id				INT PRIMARY KEY IDENTITY,
	id_wallet		INT NOT NULL FOREIGN KEY REFERENCES Wallets,
	card_number		VARCHAR(16) NOT NULL CHECK(card_number LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
	description		VARCHAR(50) NOT NULL,
	inactive		BIT NOT NULL DEFAULT 0
)
GO
CREATE TABLE Categories (
	id				INT PRIMARY KEY IDENTITY,
	description		VARCHAR(50) NOT NULL UNIQUE,
)
GO
CREATE TABLE Actions (
	id					INT PRIMARY KEY IDENTITY,
	id_wallet_source	INT FOREIGN KEY REFERENCES Wallets,
	id_wallet_target	INT FOREIGN KEY REFERENCES Wallets,
	id_category			INT FOREIGN KEY REFERENCES Categories,
	amount				DEC NOT NULL,
	timestamp			SMALLDATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	success				BIT NOT NULL,
	description			VARCHAR(50),
)
GO

-- Archive tables
DROP TABLE IF EXISTS
	Archive_Wallets,
	Archive_Persons,
	Archive_Actions
	;
GO

Select Top 0 * into Archive_Wallets from Wallets;
Select Top 0 * into Archive_Persons from Persons;
Select Top 0 * into Archive_Actions from Actions;
GO

-- Table to log errors
DROP TABLE IF EXISTS
	LogErrors;
GO
CREATE TABLE LogErrors (
	id				INT IDENTITY,
	UserName		VARCHAR(100),
	ErrorNumber		INT,
	ErrorState		INT,
	ErrorSeverity	INT,
	ErrorLine		INT,
	ErrorProcedure	VARCHAR(MAX),
	ErrorMessage	VARCHAR(MAX),
	ErrorDateTime	DATETIME
	)
GO
DROP PROCEDURE IF EXISTS PR_LogError;
GO
CREATE PROCEDURE PR_LogError
AS
	INSERT INTO LogErrors
	VALUES (
		SUSER_SNAME(),
		ERROR_NUMBER(),
		ERROR_STATE(),
		ERROR_SEVERITY(),
		ERROR_LINE(),
		ERROR_PROCEDURE(),
		ERROR_MESSAGE(),
		GETDATE()
	);

    DECLARE
		@Message varchar(MAX) = ERROR_MESSAGE(),
        @Severity int = ERROR_SEVERITY(),
        @State smallint = ERROR_STATE()
 
   RAISERROR (@Message, @Severity, @State)

	---- Transaction uncommittable
	--IF (XACT_STATE()) = -1
	--	ROLLBACK TRANSACTION
 
	---- Transaction committable
	--IF (XACT_STATE()) = 1
	--	COMMIT TRANSACTION
GO

-- triggers
DROP TRIGGER TR_Persons_onDelete
GO
CREATE TRIGGER TR_Persons_onDelete
ON Persons
INSTEAD OF DELETE
AS
	IF(SELECT inactive FROM deleted) = 0
		UPDATE Persons
		SET inactive = 1
		WHERE id = (SELECT id FROM deleted)
	ELSE
		DELETE Persons
		WHERE id = (SELECT id FROM deleted)
GO
--DROP TRIGGER TR_Cards_onDelete
--GO
--CREATE TRIGGER TR_Cards_onDelete
--ON Cards
--INSTEAD OF DELETE
--AS
--	UPDATE Cards
--	SET inactive = 1
--	WHERE id = (SELECT id FROM deleted)
--GO
DROP TRIGGER TR_Wallets_onDelete
GO
CREATE TRIGGER TR_Wallets_onDelete
ON Wallets
INSTEAD OF DELETE
AS
	IF(SELECT inactive FROM deleted) = 0
		UPDATE Wallets
		SET inactive = 1
		WHERE id = (SELECT id FROM deleted)
	ELSE
		DELETE Wallets
		WHERE id = (SELECT id FROM deleted)
GO