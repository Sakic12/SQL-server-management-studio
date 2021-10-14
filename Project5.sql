/*
1. Kroz SQL kod, napraviti bazu podataka koja nosi ime va�eg broja dosijea. U postupku kreiranja u
obzir uzeti samo DEFAULT postavke.
*/
CREATE DATABASE BP2_2016_07_16
GO

USE BP2_2016_07_16
GO
/*
Unutar svoje baze podataka kreirati tabelu sa sljede�om strukturom:
a) Proizvodi:
I. ProizvodID, automatski generatpr vrijednosti i primarni klju�
II. Sifra, polje za unos 10 UNICODE karaktera (obavezan unos), jedinstvena vrijednost
III. Naziv, polje za unos 50 UNICODE karaktera (obavezan unos)
IV. Cijena, polje za unos decimalnog broja (obavezan unos)
b) Skladista
I. SkladisteID, automatski generator vrijednosti i primarni klju�
II. Naziv, polje za unos 50 UNICODE karaktera (obavezan unos)
III. Oznaka, polje za unos 10 UNICODE karaktera (obavezan unos), jedinstvena vrijednost
IV. Lokacija, polje za unos 50 UNICODE karaktera (obavezan unos)
c) SkladisteProizvodi
I) Stanje, polje za unos decimalnih brojeva (obavezan unos)
Napomena: Na jednom skladi�tu mo�e biti uskladi�teno vi�e proizvoda, dok isti proizvod mo�e biti
uskladi�ten na vi�e razli�itih skladi�ta. Onemogu�iti da se isti proizvod na skladi�tu mo�e pojaviti vi�e
puta
*/
CREATE TABLE Proizvodi
(
    ProizvodID INT CONSTRAINT PK_Proizvodi PRIMARY KEY IDENTITY(1,1),
    Sifra NVARCHAR(10) CONSTRAINT uq_sifra UNIQUE NOT NULL,
    Naziv NVARCHAR(50) NOT NULL,
    Cijena DECIMAL(8,2) NOT NULL
)

CREATE TABLE Skladista
(
    SkladisteID INT CONSTRAINT PK_Skladista PRIMARY KEY IDENTITY(1,1),
    Naziv NVARCHAR(50) NOT NULL,
    Oznaka NVARCHAR(10) CONSTRAINT uq_oznaka UNIQUE NOT NULL,
    Lokacija NVARCHAR(50) NOT NULL
)

CREATE TABLE SkladisteProizvodi
(
    SkladisteID INT CONSTRAINT FK_SkladisteProizvodi_Skladiste FOREIGN KEY(SkladisteID) REFERENCES Skladista(SkladisteID),
    ProizvodID INT CONSTRAINT FK_SkladistaProizvodi_Proizvodi FOREIGN KEY(ProizvodID) REFERENCES Proizvodi(ProizvodID),
    CONSTRAINT PK_SkladisteProizvodi PRIMARY KEY(SkladisteID,ProizvodID),
    Stanje DECIMAL(8,2) NOT NULL
)

/*
2. Popunjavanje tabela podacima
a) Putem INSERT komande u tabelu Skladista dodati minimalno 3 skladi�ta.
b) Koriste�i bazu podataka AdventureWorks2014, preko INSERT i SELECT komande importovati
10 najprodavanijih bicikala (kategorija proizvoda 'Bikes' i to sljede�e kolone:
I. Broj proizvoda (ProductNumber) - > Sifra,
II. Naziv bicikla (Name) -> Naziv,
III. Cijena po komadu (ListPrice) -> Cijena,
c) Putem INSERT i SELECT komandi u tabelu SkladisteProizvodi za sva dodana skladista
importovati sve proizvode tako da stanje bude 100
*/
--a
SELECT INTO Skladista
VALUES ('Skladiste 1', 'SAK-100-1','Grad 1'),
		('Skladiste 2','SAK-100-2','Grad 2'),
		('Skladiste 3','SAK-100-3','Grad 3')

--b
SELECT INTO Proizvodi
SELECT TOp 10 P.ProductNumber,P.Name,P.ListPrice
FROM AdventureWORks2014.Production.Product AS P INNER JOIN AdventureWORks2014.Production.ProductSubcategORy AS PS
	 ON P.ProductSubcategORyID = PS.ProductSubcategORyID INNER JOIN AdventureWORks2014.Production.ProductCategORy AS PC
	 ON PS.ProductCategORyID = PC.ProductCategORyID INNER JOIN AdventureWORks2014.Sales.SalesORderDetail AS SOD
	 ON P.ProductID = SOD.ProductID
WHERE PC.Name LIKE '%Bikes%'
GROUP BY P.ProductNumber,P.Name,P.ListPrice
ORDER BY SUM(SOD.ORderQty) DESC

SELECT * FROM Proizvodi

--C
OR INTO SkladisteProizvodi
SELECT (SELECT SkladisteID FROM Skladista WHERE SkladisteID = 3),ProizvodID,100
FROM Proizvodi

SELECT * FROM SkladisteProizvodi
GO
/*3.
Kreirati uskladi�tenu proceduru koja �e vr�iti pove�anje stanja skladi�ta za odre�eni proizvod na
odabranom skladi�tu. Provjeriti ispravnost procedure.
*/
CREATE PROCEDURE proc_SkladisteProizvodi_update
(
    @SkladisteID INT,
    @ProizvodID INT,
    @Stanje DECIMAL(8,2)
)
AS
BEGIN
    UPDATE SkladisteProizvodi
    SET Stanje = Stanje + @Stanje
    WHERE SkladisteID = @SkladisteID AND ProizvodID = @ProizvodID
END

EXEC proc_SkladisteProizvodi_update 1,2,33

SELECT * FROM SkladisteProizvodi


/*4.
 Kreiranje indeksa u bazi podataka nad tabelama
a) Non-clustered indeks nad tabelom Proizvodi. Potrebno je indeksirati Sifru i Naziv. Tako�er,
potrebno je uklju�iti kolonu Cijena
b) Napisati proizvoljni upit nad tabelom Proizvodi koji u potpunosti iskORi�tava indeks iz
prethodnog kORaka
c) Uradite disable indeksa iz kORaka a)
*/
CREATE NONCLUSTERED INDEX IX_Proizvodi_Sifra_Naziv
ON Proizvodi(Sifra, Naziv)
include(Cijena)

SELECT Sifra,Naziv
FROM Proizvodi
WHERE Cijena > 2100

ALTER INDEX IX_Proizvodi_Sifra_Naziv ON Proizvodi
DISABLE
GO
/*
5. Kreirati VIEW sa sljede�om definicijom. Objekat treba da prikazuje sifru, naziv i cijenu proizvoda,
oznaku, naziv i lokaciju skladi�ta, te stanje na skladi�tu.
*/
CREATE VIEW VIEW_Proizvodi_Skladista
AS
SELECT 
    P.Sifra,P.Naziv AS Proizvod,
    P.Cijena,
	S.Oznaka,S.Naziv AS Skladiste,
    S.Lokacija,
	SP.Stanje
FROM Proizvodi AS P 
    INNER JOIN SkladisteProizvodi AS SP ON P.ProizvodID = SP.ProizvodID 
    INNER JOIN Skladista AS S ON SP.SkladisteID = S.SkladisteID

SELECT * FROM VIEW_Proizvodi_Skladista
GO
/*6.
 Kreirati uskladi�tenu proceduru koja �e na osnovu unesene �ifre proizvoda prikazati ukupno stanje
zaliha na svim skladi�tima. U rezultatu prikazati sifru, naziv i cijenu proizvoda te ukupno stanje zaliha.
U proceduri kORistiti prethodno kreirani VIEW. Provjeriti ispravnost kreirane procedure.
*/
CREATE PROCEDURE proc_VIEW_Proizvodi_Skladista_UkupnoStanje
(
    @Sifra NVARCHAR(10)
)
AS
BEGIN
    SELECT 
        Sifra,
        Proizvod,
        Cijena,
        SUM(Stanje) AS [Ukupno stanje]
    FROM VIEW_Proizvodi_Skladista
    WHERE Sifra = @Sifra
    GROUP BY Sifra, Proizvod, Cijena
END

EXEC proc_VIEW_Proizvodi_Skladista_UkupnoStanje 'BK-M68B-42'
GO
/*7.
. Kreirati uskladi�tenu proceduru koja �e vr�iti upis novih proizvoda, te kao stanje zaliha za uneseni
proizvod postaviti na 0 za sva skladi�ta. Provjeriti ispravnost kreirane procedure.
*/
CREATE PROCEDURE proc_Proizvodi_Select
(
    @Sifra NVARCHAR(10),
    @Naziv NVARCHAR(50),
    @Cijena DECIMAL(8,2)
)
AS
BEGIN
    SELECT INTO Proizvodi
    VALUES (@Sifra, @Naziv, @Cijena)

    SELECT INTO SkladisteProizvodi
    SELECT SkladisteID, (SELECT ProizvodID FROM Proizvodi WHERE Sifra = @Sifra), 0
    FROM Skladista
END

EXEC proc_Proizvodi_Select 'Sifra', 'Naziv', 1.00

SELECT * FROM SkladisteProizvodi
GO
/*8.
 Kreirati uskladi�tenu proceduru koja �e za unesenu �ifru proizvoda vr�iti brisanje proizvoda
uklju�uju�i stanje na svim skladi�tima. Provjeriti ispravnost procedure.
*/
CREATE PROCEDURE proc_Proizvodi_Delete
(
    @Sifra NVARCHAR(10)
)
AS
BEGIN
    DELETE FROM SkladisteProizvodi
    WHERE ProizvodID IN 
    (
        SELECT ProizvodID
        FROM Proizvodi
        WHERE Sifra = @Sifra
    )

    DELETE FROM Proizvodi
    WHERE Sifra = @Sifra
END

EXEC proc_Proizvodi_Delete 'AB-CULT'
GO
/*9.
 Kreirati uskladi�tenu proceduru koja �e za unesenu �ifru proizvoda, oznaku skladi�ta ili lokaciju
skladi�ta vr�iti pretragu prethodno kreiranim VIEW-om (zadatak 5). Procedura obavezno treba da
vra�a rezultate bez obrzira da li su vrijednosti parametara postavljene. Testirati ispravnost procedure
u sljede�im situacijama:
a) Nije postavljena vrijednost niti jednom parametru (vra�a sve zapise)
b) Postavljena je vrijednost parametra �ifra proizvoda, a ostala dva parametra nisu
c) Postavljene su vrijednosti parametra �ifra proizvoda i oznaka skladi�ta, a lokacija
nije
d) Postavljene su vrijednosti parametara �ifre proizvoda i lokacije, a oznaka skladi�ta
nije
e) Postavljene su vrijednosti sva tri parametra
*/
CREATE PROCEDURE proc_VIEW_Proizvodi_Skladista_pretraga
(
    @Sifra NVARCHAR(10) = null,
    @Oznaka NVARCHAR(10) = null,
    @Lokacija NVARCHAR(50) = null
)
AS
BEGIN
    SELECT *
    FROM VIEW_Proizvodi_Skladista
    WHERE (Sifra = @Sifra OR @Sifra IS NULL) AND 
          (Oznaka = @Oznaka OR @Oznaka IS NULL) AND 
          (Lokacija = @Lokacija OR @Lokacija IS NULL)
END

EXEC proc_VIEW_Proizvodi_Skladista_pretraga
EXEC proc_VIEW_Proizvodi_Skladista_pretraga 'BK-R50B-52'
EXEC proc_VIEW_Proizvodi_Skladista_pretraga 'BK-R50B-52','SAK-100-2'
EXEC proc_VIEW_Proizvodi_Skladista_pretraga @Sifra = 'BK-R50B-52',@Lokacija = 'Sarajevo'


/*10. Napraviti full i diferencijalni BACKUP baze podataka na default lokaciju servera:*/

BACKUP DATABASE BP2_2016_07_16 TO
DISK = 'BP2_2016_07_16.bak'

BACKUP DATABASE BP2_2016_07_16 TO
DISK = 'BP2_2016_07_16_diff.bak'
WITH DIFFERENTIAL