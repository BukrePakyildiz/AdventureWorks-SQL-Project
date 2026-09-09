/* ==========================================================================
   04. STORED PROCEDURES
   Veritabanı: AdventureWorks
   Her iki prosedür de en az 1 IF ve 3 ayrı veritabanı erişimi (SELECT/
   UPDATE/INSERT) içerir. İkinci prosedür ayrıca bir WHILE döngüsü
   (cursor ile) kullanır.
   ========================================================================== */

-- ---------------------------------------------------------------------
-- Destek tablosu: fiyat değişikliklerinin loglanması için
-- ---------------------------------------------------------------------
IF OBJECT_ID('dbo.ProductPriceChangeLog', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ProductPriceChangeLog
    (
        LogID       INT IDENTITY(1,1) PRIMARY KEY,
        ProductID   INT NOT NULL,
        OldPrice    DECIMAL(10,2) NOT NULL,
        NewPrice    DECIMAL(10,2) NOT NULL,
        ChangeType  VARCHAR(20) NOT NULL,   -- 'Updated' veya 'Rejected-Decrease'
        ChangeDate  DATETIME NOT NULL DEFAULT GETDATE()
    );
END;
GO

-- ---------------------------------------------------------------------
-- a) Tek bir ürünün fiyatını güncelleyen prosedür.
--    Yeni fiyat mevcut fiyattan düşükse ürünü SİLMEK yerine, değişikliği
--    reddedip loglar (orijinal taslakta ürünü silen hatalı mantık
--    düzeltilmiştir). Yeni fiyat eşit ya da yüksekse günceller ve loglar.
-- ---------------------------------------------------------------------
IF OBJECT_ID('dbo.usp_UpdateProductPrice', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_UpdateProductPrice;
GO

CREATE PROCEDURE dbo.usp_UpdateProductPrice
    @ProductID INT,
    @NewPrice  DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentPrice DECIMAL(10,2);

    -- 1. veritabanı erişimi: mevcut fiyatı oku
    SELECT @CurrentPrice = ListPrice
    FROM Production.Product
    WHERE ProductID = @ProductID;

    IF @CurrentPrice IS NULL
    BEGIN
        RAISERROR('Product %d not found.', 16, 1, @ProductID);
        RETURN;
    END

    IF @NewPrice < @CurrentPrice
    BEGIN
        -- 2. veritabanı erişimi: reddedilen değişikliği logla
        INSERT INTO dbo.ProductPriceChangeLog (ProductID, OldPrice, NewPrice, ChangeType)
        VALUES (@ProductID, @CurrentPrice, @NewPrice, 'Rejected-Decrease');

        PRINT 'New price is lower than the current price. Change rejected and logged.';
    END
    ELSE
    BEGIN
        -- 2. veritabanı erişimi: fiyatı güncelle
        UPDATE Production.Product
        SET ListPrice = @NewPrice
        WHERE ProductID = @ProductID;

        -- 3. veritabanı erişimi: onaylanan değişikliği logla
        INSERT INTO dbo.ProductPriceChangeLog (ProductID, OldPrice, NewPrice, ChangeType)
        VALUES (@ProductID, @CurrentPrice, @NewPrice, 'Updated');
    END
END;
GO

-- ---------------------------------------------------------------------
-- b) Belirli bir alt kategorideki, satışı hâlâ devam eden (SellEndDate
--    IS NULL) tüm ürünlere WHILE döngüsü ile tek tek indirim uygulayan
--    ve her değişikliği loglayan prosedür.
-- ---------------------------------------------------------------------
IF OBJECT_ID('dbo.usp_ApplyDiscountToSubcategory', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_ApplyDiscountToSubcategory;
GO

CREATE PROCEDURE dbo.usp_ApplyDiscountToSubcategory
    @ProductSubcategoryID INT,
    @DiscountPercent      DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ProductID    INT;
    DECLARE @CurrentPrice DECIMAL(10,2);
    DECLARE @NewPrice     DECIMAL(10,2);

    -- 1. veritabanı erişimi: indirim uygulanacak ürünlerin cursor'ı
    DECLARE product_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT ProductID, ListPrice
        FROM Production.Product
        WHERE ProductSubcategoryID = @ProductSubcategoryID
          AND SellEndDate IS NULL;

    OPEN product_cursor;
    FETCH NEXT FROM product_cursor INTO @ProductID, @CurrentPrice;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @CurrentPrice > 0
        BEGIN
            SET @NewPrice = @CurrentPrice - (@CurrentPrice * @DiscountPercent / 100);

            -- 2. veritabanı erişimi: fiyatı güncelle
            UPDATE Production.Product
            SET ListPrice = @NewPrice
            WHERE ProductID = @ProductID;

            -- 3. veritabanı erişimi: değişikliği logla
            INSERT INTO dbo.ProductPriceChangeLog (ProductID, OldPrice, NewPrice, ChangeType)
            VALUES (@ProductID, @CurrentPrice, @NewPrice, 'Updated');
        END

        FETCH NEXT FROM product_cursor INTO @ProductID, @CurrentPrice;
    END

    CLOSE product_cursor;
    DEALLOCATE product_cursor;
END;
GO
