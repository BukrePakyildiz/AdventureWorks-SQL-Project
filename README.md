# AdventureWorks-SQL-Project


Readme · MD
AdventureWorks SQL Practice Project
T-SQL (Microsoft SQL Server) ile AdventureWorks örnek veritabanı üzerinde geliştirilmiş, veri kalitesi kontrolü, ileri seviye sorgulama, trigger, stored procedure ve transaction yönetimi konularını kapsayan bir uygulama projesi.

Amaç
Bu proje, gerçek bir veritabanı üzerinde uçtan uca T-SQL yeteneklerini göstermek amacıyla hazırlanmıştır:

Veri bütünlüğü/kalite kontrolleri
XML tabanlı dinamik string birleştirme (STUFF + FOR XML PATH)
Trigger'lar ile iş kuralı uygulama ve denetim (audit)
IF/WHILE kontrol yapıları içeren stored procedure'ler
Transaction (COMMIT/ROLLBACK) yönetimi
Ön Koşullar
SQL Server (2016+) veya Azure SQL
AdventureWorks örnek veritabanı yüklü olmalı (dosya 01-04 için)
Dosya 05 kendi şema/tablolarını oluşturduğu için bağımsız çalışır
Dosya Yapısı
Dosya	Açıklama
01_data_quality_checks.sql	Kritik alanlarda (EmailPromotion, BusinessEntityID, City, EndDate) NULL değer kontrolü yapan script'ler
02_advanced_reporting_query.sql	Her ürün fotoğrafı için ilişkili ürün sayısını ve isimlerini tek satırda birleştiren XML tabanlı rapor sorgusu
03_triggers.sql	Person.Person tablosu üzerinde: (a) tüm değişiklikleri engelleyen INSTEAD OF trigger, (b) isim değişikliğinde ilgili kişiye e-posta gönderen AFTER UPDATE trigger
04_stored_procedures.sql	Ürün fiyat güncelleme (tekil, IF kontrollü) ve toplu indirim uygulama (WHILE döngülü, cursor tabanlı) stored procedure'leri, değişiklik log tablosuyla birlikte
05_transaction_and_demo_schema.sql	Bağımsız Employees demo şeması: transaction (COMMIT/ROLLBACK) örnekleri, otomatik ekleme logu, yaş artışını tüm çalışanlara yansıtan trigger, toplu maaş güncelleme prosedürü
Çalıştırma Sırası
Dosyalar numaralandırılmış sırayla, aynı bağlantıda (AdventureWorks veritabanına bağlıyken) çalıştırılmalıdır. Her dosya bağımsız olarak da incelenebilir; gerekli log tabloları kendi dosyaları içinde oluşturulur.

Notlar
Tüm scriptler SQL Server T-SQL sözdizimi kullanır.
Trigger'lardaki e-posta gönderimi için Database Mail'in yapılandırılmış olması gerekir (msdb.dbo.sp_send_dbmail).
05 numaralı dosyadaki Employees şeması eğitim amaçlı, AdventureWorks'ten bağımsız basit bir demodur.

