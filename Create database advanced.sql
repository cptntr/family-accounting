USE FamilyAccounting;
GO

DROP TABLE IF EXISTS
	Shared_Transactions,
	Shared_Wallets
	;
GO

CREATE TABLE Shared_Wallets (
	id				INT PRIMARY KEY IDENTITY,
	id_person		INT NOT NULL FOREIGN KEY REFERENCES Persons,
	id_wallet		INT NOT NULL FOREIGN KEY REFERENCES Wallets,
	day_limit		DEC
)
GO

CREATE TABLE Shared_Transactions (
	id_shared		INT NOT NULL FOREIGN KEY REFERENCES Shared_Wallets,
	id_transaction	INT NOT NULL FOREIGN KEY REFERENCES Transactions
)
GO