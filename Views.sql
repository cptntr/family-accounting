USE FamilyAccounting;
GO

DROP VIEW IF EXISTS
	VW_Persons,
	VW_Wallets,
	VW_Categories,
	VW_Actions,
	VW_Cards,
	VW_Actions_Transfers,
	VW_Actions_Incomes,
	VW_Actions_Expenses,
	VW_Actions_Negatives,
	VW_Actions_Positives,
	VW_Wallets_Total,
	VW_Persons_Total,
	VW_Categories_Total,
	VW_Wallets_Categories_Total
	;
GO

CREATE VIEW VW_Persons AS
SELECT
	id,
	name,
	surname,
	email,
	phone
FROM Persons
-- SELECT * FROM VW_Persons
GO
CREATE VIEW VW_Wallets AS
SELECT
	Wallets.id,
	id_person,
	name,
	surname,
	description,
	Wallets.inactive
FROM Wallets INNER JOIN Persons ON id_person = Persons.id
-- SELECT * FROM VW_Wallets
GO
CREATE VIEW VW_Categories AS
SELECT
	id,
	description
FROM Categories
-- SELECT * FROM VW_Categories
GO
CREATE VIEW VW_Actions AS
SELECT
	id,
	id_wallet_source,
	id_wallet_target,
	id_category,
	amount,
	timestamp,
	success,
	description
FROM Actions
-- SELECT * FROM VW_Actions
GO
CREATE VIEW VW_Cards AS
SELECT
	id,
	id_wallet,
	card_number,
	description,
	inactive
FROM Cards
-- SELECT * FROM VW_Cards
GO

CREATE VIEW VW_Actions_Transfers AS
	SELECT *
	FROM VW_Actions
	WHERE id_wallet_source IS NOT NULL AND id_wallet_target IS NOT NULL;
-- SELECT * FROM VW_Actions_Transfers
GO
CREATE VIEW VW_Actions_Incomes AS
	SELECT *
	FROM VW_Actions
	WHERE id_wallet_source IS NULL AND id_wallet_target IS NOT NULL;
-- SELECT * FROM VW_Actions_Incomes
GO
--CREATE VIEW VW_Actions_Expenses AS
--	SELECT *
--	FROM VW_Actions
--	WHERE id_wallet_source IS NOT NULL AND id_wallet_target IS NULL;
---- SELECT * FROM VW_Actions_Expenses
--GO
CREATE VIEW VW_Actions_Negatives AS
	SELECT *
	FROM VW_Actions
	WHERE id_wallet_source IS NOT NULL;
-- SELECT * FROM VW_Actions_Negatives
GO
CREATE VIEW VW_Actions_Positives AS
	SELECT *
	FROM VW_Actions
	WHERE id_wallet_target IS NOT NULL;
-- SELECT * FROM VW_Actions_Positives
GO

CREATE VIEW VW_Wallets_Total AS
	SELECT
		VW_Wallets.*,
		(IIF(0=(SELECT COUNT(Cards.id) FROM Cards WHERE Cards.id_wallet = VW_Wallets.id AND inactive = 0),1,0)) AS is_cash,
		(SELECT COUNT(Cards.id) FROM Cards WHERE Cards.id_wallet = VW_Wallets.id AND inactive = 0) AS cards_act,
		(SELECT SUM(amount) FROM VW_Actions WHERE id_wallet_target = VW_Wallets.id AND success = 1) AS positive_bal,
		(SELECT SUM(amount) FROM VW_Actions WHERE id_wallet_source = VW_Wallets.id AND success = 1) AS negative_bal,
		((SELECT SUM(amount) FROM VW_Actions WHERE id_wallet_target = VW_Wallets.id AND success = 1)
		-(SELECT SUM(amount) FROM VW_Actions WHERE id_wallet_source = VW_Wallets.id AND success = 1)) AS balance,
		(SELECT COUNT(id) FROM VW_Actions WHERE (id_wallet_target = VW_Wallets.id OR id_wallet_source = VW_Wallets.id) AND success = 1) AS success_act,
		(SELECT COUNT(id) FROM VW_Actions WHERE (id_wallet_target = VW_Wallets.id OR id_wallet_source = VW_Wallets.id) AND success = 0) AS failure_act,
		(SELECT COUNT(id) FROM VW_Actions_Positives WHERE (id_wallet_target = VW_Wallets.id OR id_wallet_source = VW_Wallets.id) AND success = 1) AS positive_act,
		(SELECT COUNT(id) FROM VW_Actions_Negatives WHERE (id_wallet_target = VW_Wallets.id OR id_wallet_source = VW_Wallets.id) AND success = 1) AS negative_act,
		(SELECT COUNT(id) FROM VW_Actions WHERE (id_wallet_target = VW_Wallets.id OR id_wallet_source = VW_Wallets.id) AND success = 1) AS all_actansactions
	FROM VW_Wallets
-- SELECT * FROM VW_Wallets_Total
GO
CREATE VIEW VW_Persons_Total AS
	SELECT
		VW_Persons.*,
		(SELECT COUNT(VW_Wallets.id) FROM VW_Wallets WHERE VW_Wallets.id_person = VW_Persons.id AND VW_Wallets.inactive = 0) AS active_wallets,
		(SELECT COUNT(VW_Wallets.id) FROM VW_Wallets WHERE VW_Wallets.id_person = VW_Persons.id AND VW_Wallets.inactive = 1) AS inactive_wallets,
		(SELECT SUM(balance) FROM VW_Wallets_Total WHERE VW_Wallets_Total.id_person = VW_Persons.id AND VW_Wallets_Total.inactive = 0) AS active_balance,
		(SELECT SUM(balance) FROM VW_Wallets_Total WHERE VW_Wallets_Total.id_person = VW_Persons.id AND VW_Wallets_Total.inactive = 1) AS inactive_balance
	FROM VW_Persons
-- SELECT * FROM VW_Persons_Total
GO
CREATE VIEW VW_Categories_Total AS
	SELECT
		VW_Categories.*,
		(SELECT SUM(amount) FROM VW_Actions_Negatives WHERE VW_Actions_Negatives.id_category = VW_Categories.id) AS spended
	FROM VW_Categories
-- SELECT * FROM VW_Categories_Total
GO
CREATE VIEW VW_Wallets_Categories_Total AS
	SELECT
		VW_Wallets_Total.id AS id_wallet,
		VW_Categories.id AS id_category,
		VW_Categories.description,
		(SELECT SUM(amount) FROM VW_Actions_Negatives WHERE VW_Actions_Negatives.id_wallet_source = VW_Wallets_Total.id AND VW_Actions_Negatives.id_category = VW_Categories.id AND success = 1) AS spended
	FROM VW_Wallets_Total, VW_Categories
-- SELECT * FROM VW_Wallets_Categories_Total
GO