/* ==========================================================================
   05. TRANSACTION MANAGEMENT & DEMO SCHEMA
   Bu dosya, AdventureWorks'ten bağımsız, kendi içinde çalışan basit bir
   "Employees" demo şeması kurar ve transaction (COMMIT/ROLLBACK)
   yönetimini, otomatik loglama trigger'larını gösterir.
   ========================================================================== */

-- ---------------------------------------------------------------------
-- Şema kurulumu
-- ---------------------------------------------------------------------
IF OBJECT_ID('dbo.Employees', 'U') IS NOT NULL DROP TABLE dbo.Employees;
IF OBJECT_ID('dbo.EmployeeInsertionsLog', 'U') IS NOT NULL DROP TABLE dbo.EmployeeInsertionsLog;
IF OBJECT_ID('dbo.SalaryChangeLog', 'U') IS NOT NULL DROP TABLE dbo.SalaryChangeLog;
GO

CREATE TABLE dbo.Employees
(
    ID      INT IDENTITY(1,1) PRIMARY KEY,
    Name    NVARCHAR(50),
    Age     INT,
    Address VARCHAR(100),
    Salary  MONEY
);
GO

CREATE TABLE dbo.EmployeeInsertionsLog
(
    LogID      INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    LoggedAt   DATETIME NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE dbo.SalaryChangeLog
(
    LogID      INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    OldSalary  MONEY NOT NULL,
    NewSalary  MONEY NOT NULL,
    ChangeDate DATETIME NOT NULL DEFAULT GETDATE()
);
GO

INSERT INTO dbo.Employees (Name, Age, Address, Salary)
VALUES
    ('Ramesh',   32, 'Ahmedabad', 2000.00),
    ('Khilan',   25, 'Delhi',     1500.00),
    ('Kaushik',  23, 'Kota',      2000.00),
    ('Chaitali', 25, 'Mumbai',    6500.00),
    ('Hardik',   27, 'Bhopal',    8500.00),
    ('Komal',    22, 'MP',        4500.00),
    ('Muffy',    24, 'Indore',   10000.00);
GO

-- ---------------------------------------------------------------------
-- Trigger: yeni bir çalışan eklendiğinde otomatik olarak logla
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_Employees_LogInsert
ON dbo.Employees
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.EmployeeInsertionsLog (EmployeeID)
    SELECT ID FROM inserted;
END;
GO

-- ---------------------------------------------------------------------
-- Trigger: bir çalışanın yaşı 1 arttığında, diğer tüm çalışanların
-- yaşını da 1 artır.
-- (RECURSIVE_TRIGGERS varsayılan olarak kapalı olduğundan, trigger
-- içindeki UPDATE kendini tekrar tetiklemez.)
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_Employees_CascadeAgeIncrease
ON dbo.Employees
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(Age)
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM inserted AS i
            JOIN deleted AS d ON i.ID = d.ID
            WHERE i.Age = d.Age + 1
        )
        BEGIN
            UPDATE e
            SET Age = Age + 1
            FROM dbo.Employees AS e
            WHERE e.ID NOT IN (SELECT ID FROM inserted);
        END
    END
END;
GO

-- ---------------------------------------------------------------------
-- 1) Age <> 25 olan çalışanları sil, sonra bu işlemi geri al (ROLLBACK)
-- ---------------------------------------------------------------------
BEGIN TRANSACTION;
    DELETE FROM dbo.Employees WHERE Age <> 25;
ROLLBACK TRANSACTION;

SELECT * FROM dbo.Employees;   -- Beklenen sonuç: tüm 7 çalışan hâlâ mevcut

-- ---------------------------------------------------------------------
-- 2) Age = 25 olan çalışanları sil, sonra bu işlemi onayla (COMMIT)
-- ---------------------------------------------------------------------
BEGIN TRANSACTION;
    DELETE FROM dbo.Employees WHERE Age = 25;
COMMIT TRANSACTION;

SELECT * FROM dbo.Employees;   -- Beklenen sonuç: Age=25 olanlar kalıcı silinmiş

-- ---------------------------------------------------------------------
-- 3) Maaşı 5000'in altında olan tüm çalışanlara 1000 USD zam yap ve
--    her değişikliği logla.
-- ---------------------------------------------------------------------
IF OBJECT_ID('dbo.usp_ApplySalaryRaise', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_ApplySalaryRaise;
GO

CREATE PROCEDURE dbo.usp_ApplySalaryRaise
AS
BEGIN
    SET NOCOUNT ON;

    -- Önce eski/yeni değerleri logla (UPDATE'ten önce, eski maaş hâlâ geçerliyken)
    INSERT INTO dbo.SalaryChangeLog (EmployeeID, OldSalary, NewSalary)
    SELECT ID, Salary, Salary + 1000
    FROM dbo.Employees
    WHERE Salary < 5000;

    UPDATE dbo.Employees
    SET Salary = Salary + 1000
    WHERE Salary < 5000;
END;
GO

EXEC dbo.usp_ApplySalaryRaise;

SELECT * FROM dbo.Employees;
SELECT * FROM dbo.SalaryChangeLog;

-- ---------------------------------------------------------------------
-- 4) Yeni bir çalışan eklenmesi durumunda otomatik loglamayı test et
--    (trg_Employees_LogInsert tarafından karşılanır)
-- ---------------------------------------------------------------------
INSERT INTO dbo.Employees (Name, Age, Address, Salary)
VALUES ('Deniz', 29, 'Istanbul', 5500.00);

SELECT * FROM dbo.EmployeeInsertionsLog;

-- ---------------------------------------------------------------------
-- 5) Bir çalışanın yaşının 1 artması durumunda diğer tüm çalışanların
--    yaşının da 1 artmasını test et (trg_Employees_CascadeAgeIncrease
--    tarafından karşılanır)
-- ---------------------------------------------------------------------
UPDATE dbo.Employees
SET Age = Age + 1
WHERE Name = 'Deniz';

SELECT * FROM dbo.Employees;
