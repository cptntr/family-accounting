USE FamilyAccounting;
GO

DROP VIEW IF EXISTS
	VW_Shared_Wallets,
	VW_Shared_Wallets_Total
	;
GO

CREATE VIEW VW_Shared_Wallets AS
	SELECT
		*
	FROM Shared_Wallets
-- SELECT * FROM VW_Shared_Wallets
GO
CREATE VIEW VW_Shared_Wallets_Total AS
	SELECT
		*,
		(SELECT id_person FROM VW_Wallets WHERE VW_Wallets.id = VW_Shared_Wallets.id_wallet) AS id_owner
	FROM VW_Shared_Wallets
-- SELECT * FROM VW_Shared_Wallets_Total
GO
