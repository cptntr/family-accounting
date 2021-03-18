USE FamilyAccounting;
GO

DROP PROCEDURE IF EXISTS
	-- Create
	PR_Persons_Create,
	PR_Wallets_Create,
	PR_Cards_Create,
	PR_Categories_Create,
	PR_Actions_Create,
	-- Read
	PR_Persons_Read,
	PR_Wallets_Read,
	PR_Cards_Read,
	PR_Categories_Read,
	PR_Actions_Read
	;
GO

/*
CREATE PROCEDURE PR_
	@_id INT
AS
	SET @_id_created = NULL
	BEGIN TRY
	    --BEGIN TRANSACTION



	SET @_id_created = CASE WHEN @@ROWCOUNT = 1 THEN SCOPE_IDENTITY() ELSE NULL END

		--COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		EXEC PR_LogError;
	END CATCH
-- EXEC PR_
GO
*/

-- Create
CREATE PROCEDURE PR_Persons_Create
	@_name			VARCHAR(50),
	@_surname		VARCHAR(50),
	@_email			VARCHAR(50),
	@_phone			VARCHAR(50),
	@_id_created	INT OUT		-- id of the created record, or NULL if nothing was created
AS
	SET @_id_created = NULL
	BEGIN TRY
	    --BEGIN TRANSACTION
		IF EXISTS(SELECT * FROM Persons WHERE UPPER(name) = UPPER(@_name) AND UPPER(surname) = UPPER(@_surname))
			RAISERROR(N'Person with such a combination of name and surname already exists', 11, 1);

		INSERT INTO Persons
			(name, surname, email, phone)
			VALUES
			(@_name, @_surname, @_email, @_phone)

		SET @_id_created = CASE WHEN @@ROWCOUNT = 1 THEN SCOPE_IDENTITY() ELSE NULL END;

		--COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		EXEC PR_LogError;
	END CATCH
-- EXEC PR_Persons_Create 'newusername', 'newusersurname', 'newuser.mail@mail.com', '0999900099'
GO
CREATE PROCEDURE PR_Wallets_Create
	@id_person		INT,
	@_description	VARCHAR(50) = NULL,
	@_id_created	INT OUT
AS
	SET @_id_created = NULL
	BEGIN TRY
	    --BEGIN TRANSACTION

		INSERT INTO Wallets
			(id_person, description)
			VALUES
			(@id_person, @_description)

		SET @_id_created = CASE WHEN @@ROWCOUNT = 1 THEN SCOPE_IDENTITY() ELSE NULL END

		--COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		EXEC PR_LogError;
	END CATCH
-- EXEC PR_Wallets_Create 99, 'failtest', NULL
GO
CREATE PROCEDURE PR_Cards_Create
	@_id_wallet		INT,
	@_card_number	VARCHAR(16),
	@_description	VARCHAR(50) = NULL,
	@_id_created	INT OUT
AS
	SET @_id_created = NULL
	BEGIN TRY
	    --BEGIN TRANSACTION

		IF dbo.fnIs16digitValidCard(@_card_number) = 0
			RAISERROR(N'Invalid credit card number', 11, 1)

		INSERT INTO Cards
			(id_wallet, card_number, description)
			VALUES
			(@_id_wallet, @_card_number, @_description)

		SET @_id_created = CASE WHEN @@ROWCOUNT = 1 THEN SCOPE_IDENTITY() ELSE NULL END

		--COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		EXEC PR_LogError;
		DECLARE @Message varchar(MAX) = ERROR_MESSAGE(),
		@Severity int = ERROR_SEVERITY(),
		@State smallint = ERROR_STATE()
		RAISERROR (@Message, @Severity, @State)
	END CATCH
-- EXEC PR_Cards_Create 1, '9999999999999999', 'new card', NULL
GO
--CREATE PROCEDURE PR_Categories_Create
--	@_description	VARCHAR(50),
--	@_id_created		INT OUT
--AS
--	SET @_id_created = NULL
--	BEGIN TRY
--	    --BEGIN TRANSACTION

--		INSERT INTO Categories
--			(description)
--			VALUES
--			(@_description)

--  SET @_id_created = CASE WHEN @@ROWCOUNT = 1 THEN SCOPE_IDENTITY() ELSE NULL END

--		--COMMIT TRANSACTION
--	END TRY
--	BEGIN CATCH
--		EXEC PR_LogError;
--	END CATCH
---- EXEC PR_Categories_Create 'new category', NULL
--GO

CREATE PROCEDURE PR_Actions_Create -- !! Add auto transfer to cash wallet if Espense category
	@_id_wallet_source	INT = NULL,
	@_id_wallet_target	INT = NULL,
	@_id_category		INT = NULL,
	@_amount			DEC,
	@_description		VARCHAR(50) = NULL,
	@_id_created		INT OUT,
	@_success			BIT OUT
AS
	SET @_id_created = NULL
	SET @_success = 1
	BEGIN TRY
	    --BEGIN TRANSACTION

		-- pre checks
		IF((@_id_wallet_source IS NULL) AND (@_id_wallet_target IS NULL))
			RAISERROR(N'At least one wallet must be specified', 11, 1)
		IF(@_amount <= 0)
			RAISERROR(N'The amount must be a positive value', 11, 1)

		-- success
		IF(@_id_wallet_source IS NOT NULL)
			IF(SELECT balance FROM VW_Wallets_Total WHERE id = @_id_wallet_source) < @_amount
				SET @_success = 0

		-- на майбутнє зробити Income і Transfer віртуальними
		-- Income
		IF((@_id_wallet_source IS NULL) AND (@_id_wallet_target IS NOT NULL))
			SET @_id_category = (SELECT id FROM Categories WHERE description = 'Income')
		-- Transfer
		IF((@_id_wallet_source IS NOT NULL) AND (@_id_wallet_target IS NOT NULL))
			SET @_id_category = (SELECT id FROM Categories WHERE description = 'Transfer')

		INSERT INTO Actions
			(id_wallet_source, id_wallet_target, id_category, amount, description, success)
			VALUES
			(@_id_wallet_source, @_id_wallet_target, @_id_category, @_amount, @_description, @_success)

		SET @_id_created = CASE WHEN @@ROWCOUNT = 1 THEN SCOPE_IDENTITY() ELSE NULL END

		--COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		EXEC PR_LogError;
	END CATCH
-- EXEC PR_Actions_Create
GO

-- Read
CREATE PROCEDURE PR_Persons_Read
	@_id		INT = NULL,	-- if NULL, it will return all records
	@_records	INT OUT		-- rows affected
AS
	SET @_records = 0
	BEGIN TRY

		SELECT * FROM VW_Persons_Total

		SET @_records = @@Rowcount
	END TRY
	BEGIN CATCH
		EXEC PR_LogError;
	END CATCH
-- EXEC PR_Persons_Read NULL, NULL
GO
CREATE PROCEDURE PR_Wallets_Read
	@_id		INT = NULL,	-- if NULL, it will return all records
	@_records	INT OUT		-- rows affected
AS
	SET @_records = 0
	BEGIN TRY

		SELECT * FROM VW_Wallets_Total

		SET @_records = @@Rowcount
	END TRY
	BEGIN CATCH
		EXEC PR_LogError;
	END CATCH
-- EXEC PR_Wallets_Read NULL, NULL
GO
CREATE PROCEDURE PR_Cards_Read
	@_id		INT = NULL,	-- if NULL, it will return all records
	@_records	INT OUT		-- rows affected
AS
	SET @_records = 0
	BEGIN TRY

		SELECT * FROM VW_Cards

		SET @_records = @@Rowcount
	END TRY
	BEGIN CATCH
		EXEC PR_LogError;
	END CATCH
-- EXEC PR_Cards_Read NULL, NULL
GO
CREATE PROCEDURE PR_Categories_Read
	@_id		INT = NULL,	-- if NULL, it will return all records
	@_records	INT OUT		-- rows affected
AS
	SET @_records = 0
	BEGIN TRY

		SELECT * FROM VW_Categories_Total

		SET @_records = @@Rowcount
	END TRY
	BEGIN CATCH
		EXEC PR_LogError;
	END CATCH
-- EXEC PR_Categories_Read NULL, NULL
GO
CREATE PROCEDURE PR_Actions_Read
	@_id		INT = NULL,	-- if NULL, it will return all records
	@_records	INT OUT		-- rows affected
AS
	SET @_records = 0
	BEGIN TRY

		SELECT * FROM VW_Actions

		SET @_records = @@Rowcount
	END TRY
	BEGIN CATCH
		EXEC PR_LogError;
	END CATCH
-- EXEC PR_Actions_Read NULL, NULL
GO
