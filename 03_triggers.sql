/* ==========================================================================
   03. TRIGGERS
   Veritabanı: AdventureWorks
   ========================================================================== */

-- ---------------------------------------------------------------------
-- a) Person.Person tablosunda her türlü değişikliği engelleyen trigger
-- ---------------------------------------------------------------------
IF OBJECT_ID('Person.trg_Person_BlockModifications', 'TR') IS NOT NULL
    DROP TRIGGER Person.trg_Person_BlockModifications;
GO

CREATE TRIGGER trg_Person_BlockModifications
ON Person.Person
INSTEAD OF INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    RAISERROR ('Insert, Update, and Delete are not allowed in this table.', 16, 1);
END;
GO

-- ---------------------------------------------------------------------
-- b) Person.Person tablosunda isim değişikliği olduğunda ilgili kişiye
--    e-posta gönderen trigger.
--    Not: Bir önceki (a) trigger'ı INSTEAD OF olduğu için gerçek UPDATE
--    işlemini engeller; bu iki trigger normalde aynı tabloda birlikte
--    kullanılmaz. Burada bağımsız bir senaryo olarak, (a) trigger'ı
--    devre dışıyken çalışacağı varsayılarak yazılmıştır.
-- ---------------------------------------------------------------------
IF OBJECT_ID('Person.trg_Person_NotifyOnUpdate', 'TR') IS NOT NULL
    DROP TRIGGER Person.trg_Person_NotifyOnUpdate;
GO

CREATE TRIGGER trg_Person_NotifyOnUpdate
ON Person.Person
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT (UPDATE(FirstName) OR UPDATE(LastName))
        RETURN;

    -- Birden fazla satır aynı anda güncellenebileceği için cursor kullanılır.
    DECLARE @BusinessEntityID INT, @FirstName NVARCHAR(50), @LastName NVARCHAR(50), @EmailAddress NVARCHAR(100);

    DECLARE person_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT i.BusinessEntityID, i.FirstName, i.LastName, ea.EmailAddress
        FROM inserted AS i
        JOIN Person.EmailAddress AS ea ON ea.BusinessEntityID = i.BusinessEntityID;

    OPEN person_cursor;
    FETCH NEXT FROM person_cursor INTO @BusinessEntityID, @FirstName, @LastName, @EmailAddress;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @EmailAddress IS NOT NULL
        BEGIN
            EXEC msdb.dbo.sp_send_dbmail
                @profile_name = 'Mail',
                @recipients   = @EmailAddress,
                @subject      = 'Updated Information',
                @body         = 'Dear ' + @FirstName + ' ' + @LastName + ', your information has been successfully updated.';
        END

        FETCH NEXT FROM person_cursor INTO @BusinessEntityID, @FirstName, @LastName, @EmailAddress;
    END

    CLOSE person_cursor;
    DEALLOCATE person_cursor;
END;
GO
