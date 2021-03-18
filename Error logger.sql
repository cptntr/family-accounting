USE FamilyAccounting;
GO

CREATE PROCEDURE PR_LogErrorInfo
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
 
	-- Transaction uncommittable
	IF (XACT_STATE()) = -1
		ROLLBACK TRANSACTION
 
	-- Transaction committable
	IF (XACT_STATE()) = 1
		COMMIT TRANSACTION
GO