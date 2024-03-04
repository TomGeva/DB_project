-- || TABLE CREATION SECTION ||

CREATE TABLE dbo.PRODUCTS (		-- creating dbo.PRODUCTS table
	Name			Varchar(80)			NOT NULL,
	Price			Smallmoney			NOT NULL,
	Discount		Smallmoney			NOT NULL		DEFAULT 0,

	CONSTRAINT	Pk_product		PRIMARY KEY		(Name)
)

CREATE TABLE dbo.RELATIONS (	-- creating dbo.RELATIONS table
	Product1		Varchar(80)			NOT NULL,
	Product2		Varchar(80)			NOT NULL,

	CONSTRAINT	Pk_relation		PRIMARY KEY		(Product1, Product2),
	CONSTRAINT	Fk_Product1		FOREIGN KEY		(Product1)
									REFERENCES	dbo.PRODUCTS	(Name),
	CONSTRAINT	Fk_Product2		FOREIGN KEY		(Product2)
									REFERENCES	dbo.PRODUCTS	(Name)
)

CREATE TABLE dbo.USERS (		-- creating dbo.USERS table
	Email			Varchar(40)			NOT NULL,
	Password		Varchar(30)			NOT NULL,

	CONSTRAINT	Pk_user			PRIMARY KEY		(Email)
)

CREATE TABLE dbo.SEARCHES (		-- creating dbo.SEARCHES table
	SearchDT		Datetime			NOT NULL,
	IP_address		Varchar(15)			NOT NULL,
	Email			Varchar(40)			NULL,
	Search_text		Varchar(80)			NOT NULL,

	CONSTRAINT	Pk_search		PRIMARY KEY		(SearchDT, IP_address),
	CONSTRAINT	Fk_user_srch	FOREIGN KEY		(Email)
									REFERENCES	dbo.USERS		(Email)
)

CREATE TABLE dbo.RESULTS (		-- creating dbo.RESULTS table
	Name			Varchar(80)			NOT NULL,
	SearchDT		Datetime			NOT NULL,
	IP_address		Varchar(15)			NOT NULL,

	CONSTRAINT	Pk_result		PRIMARY KEY		(Name, SearchDT, IP_address),
	CONSTRAINT	Fk_product		FOREIGN KEY		(Name)
									REFERENCES	dbo.PRODUCTS	(Name),
	CONSTRAINT	Fk_search		FOREIGN KEY		(SearchDT, IP_address)
									REFERENCES	dbo.SEARCHES	(SearchDT, IP_address)
)

CREATE TABLE dbo.SEEDS (		-- creating dbo.SEEDS table
	Name			Varchar(80)			NOT NULL,
	Size			Char(5)				NOT NULL,
	Season			Varchar(6)			NOT NULL,
	Sun_amount		Varchar(30)			NOT NULL,

	CONSTRAINT	Pk_seed			PRIMARY KEY		(Name),
	CONSTRAINT	Fk_Name_seed	FOREIGN KEY		(Name)
									REFERENCES	dbo.PRODUCTS	(Name)
)

CREATE TABLE dbo.SEED_TYPES (	-- creating dbo.SEED_TYPES table
	Name			Varchar(80)						NOT NULL,
	Type			Varchar(20)						NOT NULL,

	CONSTRAINT	Pk_seed_type	PRIMARY KEY	(Name, Type),
	CONSTRAINT	Fk_seed			FOREIGN KEY	(Name)
									REFERENCES	dbo.SEEDS		(Name)
)

CREATE TABLE dbo.GARDENS (		-- creating dbo.GARDENS table
	Name			Varchar(80)			NOT NULL,
	Small_count		Tinyint				NOT NULL,
	Large_count		Tinyint				NOT NULL,

	CONSTRAINT	Pk_garden		PRIMARY KEY		(Name),
	CONSTRAINT	Fk_Name_Grdn	FOREIGN KEY		(Name)
									REFERENCES	dbo.PRODUCTS	(Name)
)

CREATE TABLE dbo.CHOSENS (		-- creating dbo.CHOSENS table
	Garden			Varchar(80)			NOT NULL,
	Seed			Varchar(80)			NOT NULL,
	Quantity		Tinyint				NOT NULL		DEFAULT 1,

	CONSTRAINT	Pk_chosen		PRIMARY KEY		(Garden, Seed),
	CONSTRAINT	Fk_Garden		FOREIGN KEY		(Garden)
									REFERENCES	dbo.GARDENS		(Name),
	CONSTRAINT	Fk_Seed_chs		FOREIGN KEY		(Seed)
									REFERENCES	dbo.SEEDS		(Name)
)

CREATE TABLE dbo.DETAILS (		-- creating dbo.DETAILS table
	Name			Varchar(40)			NOT NULL,
	Address			Varchar(150)		NOT NULL,
	Company			Varchar(40)			NULL,
	Phone#			Varchar(30)			NOT NULL,

	CONSTRAINT	Pk_details		PRIMARY KEY		(Name, Address)
)

CREATE TABLE dbo.DETAILS_OF (	-- creating dbo.DETAILS_OF table
	Email			Varchar(40)			NOT NULL,
	Name			Varchar(40)			NOT NULL,
	Address			Varchar(150)		NOT NULL,

	CONSTRAINT	Pk_dtlsOf		PRIMARY KEY		(Email, Name, Address),
	CONSTRAINT	Fk_dtls_usr		FOREIGN KEY		(Email)
									REFERENCES	dbo.USERS		(Email),
	CONSTRAINT	Fk_detOf_usr	FOREIGN KEY		(Name, Address)
									REFERENCES	dbo.DETAILS		(Name, Address)
)

CREATE TABLE dbo.ORDERS (		-- creating dbo.ORDERS table
	OrderID			Int					NOT NULL,
	Email			Varchar(40)			NULL,
	Name			Varchar(40)			NOT NULL,
	Address			Varchar(150)		NOT NULL,
	OrderDate		Date				NOT NULL,
	Shipping_method	Varchar(100)		NULL,
	Payment_type	Varchar(7)			NOT NULL,

	CONSTRAINT	Pk_order		PRIMARY KEY		(OrderID),
	CONSTRAINT	Fk_user_ordr	FOREIGN KEY		(Email)
									REFERENCES	dbo.USERS		(Email),
	CONSTRAINT	Fk_dtls_ordr	FOREIGN KEY		(Name, Address)
									REFERENCES	dbo.DETAILS		(Name, Address)
)

CREATE TABLE dbo.INCLUSIONS (	-- creating dbo.INCLUSIONS table
	OrderID			Int					NOT NULL,
	Name			Varchar(80)			NOT NULL,
	Quantity		Tinyint				NOT NULL		DEFAULT 1,

	CONSTRAINT	Pk_inclusion	PRIMARY KEY		(OrderID, Name),
	CONSTRAINT	Fk_ordr_ncl		FOREIGN KEY		(OrderID)
									REFERENCES	dbo.ORDERS		(OrderID),
	CONSTRAINT	Fk_prdc_ncl		FOREIGN KEY		(Name)
									REFERENCES	dbo.PRODUCTS	(Name)
)

-- || CONSTRAINTS ADDITION SECTION ||

-- contrsaints for inforcing values of price and discount of products

ALTER TABLE dbo.PRODUCTS
	ADD	CONSTRAINT	Ck_Price
			CHECK	(Price > 0),
		CONSTRAINT	Ck_Discount
			CHECK	(Discount < Price)

-- constraint that inforces Email format

ALTER TABLE dbo.USERS
	ADD	CONSTRAINT	Ck_Email
			CHECK	(Email LIKE '%@%.%')

-- constraint that inforces ip format

ALTER TABLE dbo.SEARCHES
	ADD	CONSTRAINT	Ck_IP_address
			CHECK	((ParseName(IP_address, 4) BETWEEN 0 AND 255) 
					AND(ParseName(IP_address, 3) BETWEEN 0 AND 255)
					AND(ParseName(IP_address, 2) BETWEEN 0 AND 255)
					AND(ParseName(IP_address, 1) BETWEEN 0 AND 255))

-- constraints that inforces values of Size and Season

ALTER TABLE dbo.SEEDS
	ADD	CONSTRAINT	Ck_Size
			CHECK	(Size IN ('Small', 'Large')),
		CONSTRAINT	Ck_Season
			CHECK	(Season IN ('Summer', 'Spring', 'Winter', 'Fall'))

-- constraints that inforces values of Small_count and Large_count

ALTER TABLE dbo.GARDENS		
	ADD	CONSTRAINT	Ck_counts
			CHECK	((Small_count = 2 AND Large_count = 2)
					OR (Small_count = 5 AND Large_count = 1)
					OR (Small_count = 8 AND Large_count = 0))

-- constraint that inforces value of quantity

ALTER TABLE dbo.CHOSENS
	ADD	CONSTRAINT	Ck_Quantity_chs
			CHECK	(Quantity > 0)

-- add constraint to inforce phone# format

ALTER TABLE dbo.DETAILS
	ADD	CONSTRAINT	Ck_Phone#
			CHECK	(Phone# LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')

-- add constraint to inforce values of quantity

ALTER TABLE dbo.INCLUSIONS
	ADD	CONSTRAINT	Ck_Quantity_ncl
			CHECK	(Quantity > 0)

-- || LOOKUP TABLES CREATION ||

-- add seed type lookup table

CREATE TABLE dbo.SEEDTYPELOOKUP (
	Type			Varchar(20)		PRIMARY KEY		NOT NULL
)

INSERT INTO dbo.SEEDTYPELOOKUP 
VALUES
('Greens'), ('Herbs'), ('Fruiting'), ('Flowers'), ('Root Vegetables'), ('Heirloom')

ALTER TABLE dbo.SEED_TYPES
	ADD	CONSTRAINT	Fk_seedtypeLU	FOREIGN KEY (Type)	
									REFERENCES	dbo.SEEDTYPELOOKUP (Type)

-- add payment type lookup table

CREATE TABLE dbo.PYMNTTYPELOOKUP (
	Type			Varchar(7)		PRIMARY KEY		NOT NULL
)

INSERT INTO dbo.PYMNTTYPELOOKUP
VALUES
('ShopPay'), ('Klarna')

ALTER TABLE dbo.ORDERS
	ADD CONSTRAINT	Fk_Pymnt_type	FOREIGN KEY	(Payment_type)	
										REFERENCES	dbo.PYMNTTYPELOOKUP	(Type)

-- || DATA INSERTION SECTION ||

-- insertion to dbo.PRODUCTS

INSERT INTO dbo.PRODUCTS
VALUES
('Fennel', 12, 0),
('Scallion', 10, 0),
('Tomato: Heirloom Purple', 10, 0),
('Sunflower: Golden', 12, 0),
('Pepper: Large Bell', 9, 0),
('Light Salsa Garden', 119.99, 20),
('Root & Vegi Salad Garden', 129.99, 25),
('Simple Vegi Salad Garden', 129.99, 25),
('Custom: SnflwrGldn2, PprLB2', 159.99, 30),
('Custom: Scln3, Fnl2, SnflrGldn3', 159.99, 10),
('SUPER Fertilizer', 34.99, 3.75),
('Pruning & Harvesting Scissors', 39.99, 10)

-- insertion to dbo.RELATIONS

INSERT INTO dbo.RELATIONS
VALUES
('SUPER Fertilizer', 'Light Salsa Garden'),
('SUPER Fertilizer', 'Root & Vegi Salad Garden'),
('SUPER Fertilizer', 'Sunflower: Golden'),
('Pruning & Harvesting Scissors', 'Light Salsa Garden'),
('Pruning & Harvesting Scissors', 'Root & Vegi Salad Garden'),
('Pruning & Harvesting Scissors', 'Fennel'),
('Pruning & Harvesting Scissors', 'Scallion')

-- insertion to dbo.USERS

INSERT INTO dbo.USERS
VALUES
('tomge@post.bgu.ac.il', 'Mis63677'),
('sophiada@post.bgu.ac.il', 'Mis99988'),
('juliev@post.bgu.ac.il', 'Mis45774'),
('georgebush@gmail.com', 'g01w09B6'),
('mickeyM@walla.co.il', 'Hoho1235')

-- insertion to dbo.SEARCHES

INSERT INTO dbo.SEARCHES
VALUES
('1999-03-16 13:57:22', '10.100.102.13', 'mickeyM@walla.co.il', 'Seed'),
('2006-04-29 10:30:12', '255.30.2.0', NULL, 'Fertilizer'),
('2013-02-01 14:03:54', '99.234.8.8', 'juliev@post.bgu.ac.il', 'Burger'),
('2015-06-02 15:57:51', '82.43.43.74', 'georgebush@gmail.com', 'Pen'),
('2023-12-30 20:26:24', '69.120.55.26', 'sophiada@post.bgu.ac.il', 'Fennel'),
('2024-01-03 23:56:38', '0.74.255.254', 'sophiada@post.bgu.ac.il', 'Google')

-- insertion to dbo.RESULTS

INSERT INTO dbo.RESULTS
VALUES
('Fennel', '1999-03-16 13:57:22', '10.100.102.13'),
('Scallion', '1999-03-16 13:57:22', '10.100.102.13'),
('Tomato: Heirloom Purple', '1999-03-16 13:57:22', '10.100.102.13'),
('Sunflower: Golden', '1999-03-16 13:57:22', '10.100.102.13'),
('Pepper: Large Bell', '1999-03-16 13:57:22', '10.100.102.13'),
('SUPER Fertilizer', '2006-04-29 10:30:12', '255.30.2.0'),
('Fennel', '2023-12-30 20:26:24', '69.120.55.26')

-- insertion to dbo.SEEDS

INSERT INTO dbo.SEEDS
VALUES
('Fennel', 'Small', 'Spring', 'Full Sun / Partial Shade'),
('Scallion', 'Small', 'Winter', 'Partial Shade'),
('Tomato: Heirloom Purple', 'Large', 'Summer', 'Full Sun'),
('Sunflower: Golden', 'Small', 'Spring', 'Prefers Full Sun'),
('Pepper: Large Bell', 'Large', 'Fall', 'Prefers Full Sun')

-- insertion to dbo.SEED_TYPES

INSERT INTO dbo.SEED_TYPES
VALUES
('Fennel', 'Greens'),
('Fennel', 'Fruiting'),
('Fennel', 'Root Vegetables'),
('Scallion', 'Herbs'),
('Tomato: Heirloom Purple', 'Heirloom'),
('Tomato: Heirloom Purple', 'Fruiting'),
('Sunflower: Golden', 'Flowers'),
('Pepper: Large Bell', 'Fruiting')

-- insertion to dbo.GARDENS

INSERT INTO dbo.GARDENS
VALUES
('Light Salsa Garden', 2, 2),
('Root & Vegi Salad Garden', 5, 1),
('Simple Vegi Salad Garden', 2, 2),
('Custom: SnflwrGldn2, PprLB2', 2, 2),
('Custom: Scln3, Fnl2, SnflrGldn3', 8, 0)

-- insertion to dbo.CHOSENS

INSERT INTO dbo.CHOSENS
VALUES
('Light Salsa Garden', 'Pepper: Large Bell', 1),
('Light Salsa Garden', 'Tomato: Heirloom Purple', 1),
('Light Salsa Garden', 'Scallion', 2),
('Root & Vegi Salad Garden', 'Fennel', 2),
('Root & Vegi Salad Garden', 'Tomato: Heirloom Purple', 1),
('Root & Vegi Salad Garden', 'Scallion', 3),
('Simple Vegi Salad Garden', 'Tomato: Heirloom Purple', 1),
('Simple Vegi Salad Garden', 'Pepper: Large Bell', 1),
('Simple Vegi Salad Garden', 'Fennel', 1),
('Simple Vegi Salad Garden', 'Scallion', 1),
('Custom: SnflwrGldn2, PprLB2', 'Sunflower: Golden', 2),
('Custom: SnflwrGldn2, PprLB2', 'Pepper: Large Bell', 2),
('Custom: Scln3, Fnl2, SnflrGldn3', 'Sunflower: Golden', 3),
('Custom: Scln3, Fnl2, SnflrGldn3', 'Fennel', 2),
('Custom: Scln3, Fnl2, SnflrGldn3', 'Scallion', 3)

-- insertion to dbo.DETAILS

INSERT INTO dbo.DETAILS
VALUES
('Mickey H Mouse the 1st', 'United States, California, Disney Land, , , 00000001', 'Disney', '1234598889'),
('Goofy & Pluto', 'United States, California, Disney Land, , , 00000001', 'Disney', '0126549854'),
('Sargent Donald Duck', 'United States, California, Disney Land, , , 00000001', 'Disney', '1235516595'),
('George W. Bush', 'United States, Texas, Alburkurky, Saint st., 3, 23611356', 'The Government', '2222222221'),
('Laura Welch', 'United States, Texas, Alburkurky, Midland st., 8, 23615656', NULL, '2222222222'),
('Sargent Donald Duck', 'United States, Texas, Alburkurky, Saint st., 3, 23611356', 'The Government', '1235516595')

-- insertion to dbo.DETAILS_OF

INSERT INTO dbo.DETAILS_OF
VALUES
('mickeyM@walla.co.il', 'Mickey H Mouse the 1st', 'United States, California, Disney Land, , , 00000001'),
('mickeyM@walla.co.il', 'Goofy & Pluto', 'United States, California, Disney Land, , , 00000001'),
('mickeyM@walla.co.il', 'Sargent Donald Duck', 'United States, California, Disney Land, , , 00000001'),
('georgebush@gmail.com', 'George W. Bush', 'United States, Texas, Alburkurky, Saint st., 3, 23611356'),
('georgebush@gmail.com', 'Sargent Donald Duck', 'United States, Texas, Alburkurky, Saint st., 3, 23611356')

-- insertion to dbo.ORDERS

INSERT INTO dbo.ORDERS
VALUES
(33222, 'mickeyM@walla.co.il', 'Mickey H Mouse the 1st', 'United States, California, Disney Land, , , 00000001', '1999-03-16', 'Pickup from the factory', 'Klarna'),
(33223, NULL, 'Laura Welch', 'United States, Texas, Alburkurky, Midland st., 8, 23615656', '2009-03-16', NULL, 'Klarna'),
(33224, 'georgebush@gmail.com', 'George W. Bush', 'United States, Texas, Alburkurky, Saint st., 3, 23611356', '2015-08-19', NULL, 'ShopPay'),
(33225, 'mickeyM@walla.co.il', 'Sargent Donald Duck', 'United States, California, Disney Land, , , 00000001', '2016-06-06', 'Fedex', 'ShopPay'),
(33226, 'sophiada@post.bgu.ac.il', 'Goofy & Pluto', 'United States, California, Disney Land, , , 00000001', '2023-12-31', 'Fedex', 'ShopPay'),
(33227, 'georgebush@gmail.com', 'George W. Bush', 'United States, Texas, Alburkurky, Saint st., 3, 23611356', '2024-01-05', 'Fedex', 'Klarna'),
(33228, NULL, 'Laura Welch', 'United States, Texas, Alburkurky, Midland st., 8, 23615656', '2024-02-03', 'Private jet delivery', 'ShopPay')

-- insertion to dbo.INCLUSIONS

INSERT INTO dbo.INCLUSIONS
VALUES
(33222, 'Custom: SnflwrGldn2, PprLB2', 3),
(33222, 'Custom: Scln3, Fnl2, SnflrGldn3', 3),
(33223, 'SUPER Fertilizer', 2),
(33224, 'Pruning & Harvesting Scissors', 1),
(33225, 'Light Salsa Garden', 20),
(33226, 'Fennel', 60),
(33227, 'Pruning & Harvesting Scissors', 5),
(33228, 'Sunflower: Golden', 30)

-- || DROPING OF TABLES SECTION ||

-- droping dbo.INCLUSIONS table and its constraints

ALTER TABLE dbo.INCLUSIONS
	DROP CONSTRAINT		Pk_inclusion, Fk_ordr_ncl, Fk_prdc_ncl, Ck_Quantity_ncl

DROP TABLE dbo.INCLUSIONS

-- droping dbo.ORDERS table and its constraints

ALTER TABLE dbo.ORDERS
	DROP CONSTRAINT		Pk_order, Fk_user_ordr, Fk_dtls_ordr, Fk_Pymnt_type

DROP TABLE dbo.ORDERS

-- droping dbo.PYMNTTYPELOOKUP table

DROP TABLE dbo.PYMNTTYPELOOKUP

-- droping dbo.DETAILS_OF table and its constraints

ALTER TABLE dbo.DETAILS_OF
	DROP CONSTRAINT		Pk_dtlsOf, Fk_dtls_usr, Fk_detOf_usr

DROP TABLE dbo.DETAILS_OF

-- droping dbo.DETAILS table and its constraints

ALTER TABLE dbo.DETAILS
	DROP CONSTRAINT		Pk_details, Ck_Phone#

DROP TABLE dbo.DETAILS

-- droping dbo.CHOSENS table and its constraints

ALTER TABLE dbo.CHOSENS
	DROP CONSTRAINT		Pk_chosen, Fk_Garden, Fk_Seed_chs, Ck_Quantity_chs

DROP TABLE dbo.CHOSENS

-- droping dbo.GARDENS table and its constraints

ALTER TABLE dbo.GARDENS
	DROP CONSTRAINT		Pk_garden, Fk_Name_Grdn, Ck_counts

DROP TABLE dbo.GARDENS

-- droping dbo.SEED_TYPES table and its constraints

ALTER TABLE dbo.SEED_TYPES
	DROP CONSTRAINT		Pk_seed_type, Fk_seed, Fk_seedtypeLU

DROP TABLE dbo.SEED_TYPES

-- droping dbo.SEEDTYPELOOKUP table

DROP TABLE dbo.SEEDTYPELOOKUP

-- droping dbo.SEEDS table and its constraints

ALTER TABLE dbo.SEEDS
	DROP CONSTRAINT		Pk_seed, Fk_Name_seed, Ck_Size, Ck_season

DROP TABLE dbo.SEEDS

-- droping dbo.RESULTS table and its constraints

ALTER TABLE dbo.RESULTS
	DROP CONSTRAINT		Pk_result, Fk_product, Fk_search

DROP TABLE dbo.RESULTS

-- droping dbo.SEARCHES table and its constraints

ALTER TABLE dbo.SEARCHES
	DROP CONSTRAINT		Pk_search, Fk_user_srch, Ck_IP_address

DROP TABLE dbo.SEARCHES

-- droping dbo.USERS table and its constraints

ALTER TABLE dbo.USERS
	DROP CONSTRAINT		Pk_user, Ck_Email

DROP TABLE dbo.USERS

-- droping dbo.RELATIONS table and its constraints

ALTER TABLE dbo.RELATIONS
	DROP CONSTRAINT		Pk_relation, Fk_Product1, Fk_Product2

DROP TABLE dbo.RELATIONS

-- droping dbo.PRODUCTS table and its constraints

ALTER TABLE dbo.PRODUCTS
	DROP CONSTRAINT		Pk_product, Ck_Price, Ck_Discount

DROP TABLE dbo.PRODUCTS