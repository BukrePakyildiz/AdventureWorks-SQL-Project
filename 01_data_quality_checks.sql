/* ==========================================================================
   01. DATA QUALITY CHECKS
   Amaç: Kritik kolonlarda NULL değer olup olmadığını kontrol etmek ve
   varsa etkilenen kayıtların ID'lerini listelemek.
   Veritabanı: AdventureWorks
   ========================================================================== */

-- ---------------------------------------------------------------------
-- 1) Person.Person.EmailPromotion
-- ---------------------------------------------------------------------
DECLARE @count1 AS INTEGER;
SET @count1 = (SELECT COUNT(*) FROM Person.Person WHERE EmailPromotion IS NULL);

IF @count1 <> 0
BEGIN
    SELECT BusinessEntityID
    FROM Person.Person
    WHERE EmailPromotion IS NULL;

    PRINT CAST(@count1 AS VARCHAR(10)) + ' rows have NULL value at EmailPromotion';
END
ELSE
    PRINT 'There are no fields with value null in the field EmailPromotion';

-- ---------------------------------------------------------------------
-- 2) HumanResources.JobCandidate.BusinessEntityID
-- ---------------------------------------------------------------------
DECLARE @count2 AS INTEGER;
SET @count2 = (SELECT COUNT(*) FROM HumanResources.JobCandidate WHERE BusinessEntityID IS NULL);

IF @count2 <> 0
BEGIN
    SELECT JobCandidateID
    FROM HumanResources.JobCandidate
    WHERE BusinessEntityID IS NULL;

    PRINT CAST(@count2 AS VARCHAR(10)) + ' rows have NULL value at BusinessEntityID';
END
ELSE
    PRINT 'There are no fields with value null in the field BusinessEntityID';

-- ---------------------------------------------------------------------
-- 3) Person.Address.City
-- ---------------------------------------------------------------------
DECLARE @count3 AS INTEGER;
SET @count3 = (SELECT COUNT(*) FROM Person.Address WHERE City IS NULL);

IF @count3 <> 0
BEGIN
    SELECT AddressID
    FROM Person.Address
    WHERE City IS NULL;

    PRINT CAST(@count3 AS VARCHAR(10)) + ' rows have NULL value at City';
END
ELSE
    PRINT 'There are no fields with value null in the field City';

-- ---------------------------------------------------------------------
-- 4) Production.ProductListPriceHistory.EndDate
--    (Not: "ProductHistory" adında bir tablo AdventureWorks'te bulunmaz;
--     kastedilen tablo ProductListPriceHistory'dir.)
-- ---------------------------------------------------------------------
DECLARE @count4 AS INTEGER;
SET @count4 = (SELECT COUNT(*) FROM Production.ProductListPriceHistory WHERE EndDate IS NULL);

IF @count4 <> 0
BEGIN
    SELECT ProductID
    FROM Production.ProductListPriceHistory
    WHERE EndDate IS NULL;

    PRINT CAST(@count4 AS VARCHAR(10)) + ' rows have NULL value at EndDate';
END
ELSE
    PRINT 'There are no fields with value null in the field EndDate';
