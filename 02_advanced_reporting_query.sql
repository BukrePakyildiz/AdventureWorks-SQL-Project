/* ==========================================================================
   02. ADVANCED REPORTING QUERY
   Amaç: Her ürün fotoğrafı için, o fotoğrafla ilişkilendirilmiş ürün
   sayısını ve bu ürünlerin isim/ID bilgilerini tek bir satırda
   virgülle ayrılmış şekilde listelemek.
   Teknik: Korelasyonlu alt sorgular + STUFF / FOR XML PATH ile
   string birleştirme (SQL Server'da GROUP_CONCAT muadili).
   Veritabanı: AdventureWorks
   ========================================================================== */

SELECT
    PP.LargePhotoFileName,
    (
        SELECT COUNT(*)
        FROM Production.Product AS P
        JOIN Production.ProductProductPhoto AS PPP ON P.ProductID = PPP.ProductID
        WHERE PPP.ProductPhotoID = PP.ProductPhotoID
    ) AS NumberOfProducts,
    STUFF((
        SELECT CONCAT(', Product Name:', P.Name, ' (Product ID: ', CAST(P.ProductID AS VARCHAR(10)), ')')
        FROM Production.Product AS P
        JOIN Production.ProductProductPhoto AS PPP ON P.ProductID = PPP.ProductID
        WHERE PPP.ProductPhotoID = PP.ProductPhotoID
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS ProductNames
FROM Production.ProductPhoto AS PP;
