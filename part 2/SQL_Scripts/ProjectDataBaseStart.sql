-- || TABLE CREATION SECTION ||

CREATE TABLE dbo.PRODUCTS (		-- creating dbo.PRODUCTS table
	Name			Varchar(40)		PRIMARY KEY		NOT NULL,
	Price			Smallmoney						NOT NULL,
	Discount		Smallmoney						NOT NULL	DEFAULT 0,

	CONSTRAINT	Ck_Price		CHECK		(Price > 0),
	CONSTRAINT	Ck_Discount		CHECK		(Discount < Price)
)

CREATE TABLE dbo.RELATIONS (	-- creating dbo.RELATIONS table
	Product1		Varchar(40)						NOT NULL,
	Product2		Varchar(40)						NOT NULL,

	CONSTRAINT	Pk_relation		PRIMARY KEY	(Product1, Product2),
	CONSTRAINT	Fk_Product1		FOREIGN KEY	(Product1)
									REFERENCES	dbo.PRODUCTS	(Name),
	CONSTRAINT	Fk_Product2		FOREIGN KEY	(Product2)
									REFERENCES	dbo.PRODUCTS	(Name)
)

CREATE TABLE dbo.USERS (		-- creating dbo.USERS table
	Email			Varchar(40)		PRIMARY KEY		NOT NULL,
	Password		Varchar(30)						NOT NULL,

	CONSTRAINT	Ck_Email		CHECK		(Email LIKE '%@%.%')
)

CREATE TABLE dbo.SEARCHES (		-- creating dbo.SEARCHES table
	SearchDT		Datetime						NOT NULL,
	IP_address		Varchar(15)						NOT NULL,
	Email			Varchar(40)						NULL,
	Search_text		Varchar(80)						NOT NULL,

	CONSTRAINT	Pk_searches		PRIMARY KEY	(SearchDT, IP_address),
	CONSTRAINT	Fk_user_srch	FOREIGN KEY	(Email)
									REFERENCES	dbo.USERS		(Email),
	CONSTRAINT	Ck_IP_address	CHECK		((ParseName(IP_address, 4) BETWEEN 0 AND 255) -- constraint that makes sure that in any part of the ip address it is between 0 and 255
											AND(ParseName(IP_address, 3) BETWEEN 0 AND 255)
											AND(ParseName(IP_address, 2) BETWEEN 0 AND 255)
											AND(ParseName(IP_address, 1) BETWEEN 0 AND 255))
)

CREATE TABLE dbo.RESULTS (		-- creating dbo.RESULTS table
	Name			Varchar(40)						NOT NULL,
	SearchDT		Datetime						NOT NULL,
	IP_address		Varchar(15)						NOT NULL,

	CONSTRAINT	Pk_results		PRIMARY KEY (Name, SearchDT, IP_address),
	CONSTRAINT	Fk_product		FOREIGN KEY	(Name)
									REFERENCES	dbo.PRODUCTS	(Name),
	CONSTRAINT	Fk_search		FOREIGN KEY	(SearchDT, IP_address)
									REFERENCES	dbo.SEARCHES	(SearchDT, IP_address)
)

CREATE TABLE dbo.SEEDS (		-- creating dbo.SEEDS table
	Name			Varchar(40)		PRIMARY KEY		NOT NULL,
	Size			Char(5)							NOT NULL,
	Season			Varchar(6)						NOT NULL,
	Sun_amount		Varchar(30)						NOT NULL,

	CONSTRAINT	Fk_Name_seed	FOREIGN KEY	(Name)
									REFERENCES	dbo.PRODUCTS	(Name),
	CONSTRAINT	Ck_Size			CHECK		(Size IN ('Small', 'Large')),
	CONSTRAINT	Ck_Season		CHECK		(Season IN ('Summer', 'Spring', 'Winter', 'Fall'))
)

CREATE TABLE dbo.SEED_TYPES (	-- creating dbo.SEED_TYPES table
	Name			Varchar(40)						NOT NULL,
	Type			Varchar(20)						NOT NULL,

	CONSTRAINT	Pk_seed_type	PRIMARY KEY	(Name, Type),
	CONSTRAINT	Fk_seed			FOREIGN KEY	(Name)
									REFERENCES	dbo.SEEDS		(Name)
)

CREATE TABLE dbo.GARDENS (		-- creating dbo.GARDENS table
	Name			Varchar(40)		PRIMARY KEY		NOT NULL,
	Small_count		Tinyint							NOT NULL,
	Large_count		Tinyint							NOT NULL,

	CONSTRAINT	Fk_Name_Garden	FOREIGN KEY	(Name)
									REFERENCES	dbo.PRODUCTS	(Name),
	CONSTRAINT	Ck_Small_count	CHECK		(Small_count > 1 AND Small_count < 9),
	CONSTRAINT	Ck_Large_count	CHECK		(Large_count > -1 AND Large_count < 3)
)

CREATE TABLE dbo.CHOSENS (		-- creating dbo.CHOSENS table
	Garden			Varchar(40)						NOT NULL,
	Seed			Varchar(40)						NOT NULL,
	Quantity		Tinyint							NOT NULL	DEFAULT 1,

	CONSTRAINT	Pk_chosen		PRIMARY KEY	(Garden, Seed),
	CONSTRAINT	Fk_Garden		FOREIGN KEY	(Garden)
									REFERENCES	dbo.GARDENS		(Name),
	CONSTRAINT	Fk_Seed_chs		FOREIGN KEY	(Seed)
									REFERENCES	dbo.SEEDS		(Name),
	CONSTRAINT	Ck_Quantity_chs	CHECK		(Quantity > 0)
)

CREATE TABLE dbo.DETAILS (		-- creating dbo.DETAILS table
	Name			Varchar(40)						NOT NULL,
	Address			Varchar(150)					NOT NULL,
	Company			Varchar(40)						NULL,
	Phone#			Varchar(30)						NOT NULL,

	CONSTRAINT	Pk_details		PRIMARY KEY	(Name, Address),
	CONSTRAINT	Ck_Phone#		CHECK		(Phone# LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')
)

CREATE TABLE dbo.DETAILS_OF (	-- creating dbo.DETAILS_OF table
	Email			Varchar(40)						NOT NULL,
	Name			Varchar(40)						NOT NULL,
	Address			Varchar(150)					NOT NULL,

	CONSTRAINT	Pk_details_of	PRIMARY KEY	(Email, Name, Address),
	CONSTRAINT	Fk_user_detls	FOREIGN KEY	(Email)
									REFERENCES	dbo.USERS		(Email),
	CONSTRAINT	Fk_details_usr	FOREIGN KEY	(Name, Address)
									REFERENCES	dbo.DETAILS		(Name, Address)
)

CREATE TABLE dbo.ORDERS (		-- creating dbo.ORDERS table
	OrderID			Int				PRIMARY KEY		NOT NULL,
	Email			Varchar(40)						NULL,
	Name			Varchar(40)						NOT NULL,
	Address			Varchar(150)					NOT NULL,
	OrderDate		Date							NOT NULL,
	Shipping_method	Varchar(100)					NULL,
	Payment_type	Varchar(7)						NOT NULL,

	CONSTRAINT	Fk_user_ordr	FOREIGN KEY	(Email)
									REFERENCES	dbo.USERS		(Email),
	CONSTRAINT	Fk_details_ordr	FOREIGN KEY	(Name, Address)
									REFERENCES	dbo.DETAILS		(Name, Address),
	CONSTRAINT	Ck_Payment_type	CHECK		(Payment_type IN ('Klarna', 'ShopPay'))
)

CREATE TABLE dbo.INCLUSIONS (	-- creating dbo.INCLUSIONS table
	OrderID			Int								NOT NULL,
	Name			Varchar(40)						NOT NULL,
	Quantity		Tinyint							NOT NULL	DEFAULT 1,

	CONSTRAINT	Pk_inclusion	PRIMARY KEY	(OrderID, Name),
	CONSTRAINT	Fk_order_ncl	FOREIGN KEY	(OrderID)
									REFERENCES	dbo.ORDERS		(OrderID),
	CONSTRAINT	Fk_product_ncl	FOREIGN KEY	(Name)
									REFERENCES	dbo.PRODUCTS	(Name),
	CONSTRAINT	Ck_Quantity_ncl	CHECK		(Quantity > 0)
)

-- || LOOKUP TABLES CREATION ||

CREATE TABLE dbo.SEEDTYPELOOKUP (
	Type			Varchar(20)		PRIMARY KEY		NOT NULL,
)

INSERT INTO dbo.SEEDTYPELOOKUP VALUES
('Greens'), ('Herbs'), ('Fruiting'), ('Flowers'), ('Root Vegetables'), ('Heirloom')

ALTER TABLE dbo.SEED_TYPES
	ADD	CONSTRAINT	Fk_seedtype	FOREIGN KEY (Type)	REFERENCES	dbo.SEEDTYPELOOKUP (Type)

-- || DATA INSERTION SECTION ||

-- insertion to dbo.PRODUCTS

INSERT INTO dbo.PRODUCTS (Name, Price)
VALUES
('Fennel', 12),
('Scallion', 10),
('Tomato: Heirloom Purple', 10),
('Sunflower: Golden', 12),
('Pepper: Large Bell', 9)

INSERT INTO dbo.PRODUCTS (Name, Price, Discount)
VALUES
('Light Salsa Garden', 119.99, 20),
('Root & Vegi Salad Garden', 129.99, 25),
('Custom: SnflwrGldn, PprLB', 159.99, 30),
('Custom: Scln, Fnl, SnflrGldn', 159.99, 10),
('SUPER Fertilizer', 34.99, 3.75),
('Pruning & Harvesting Scissors', 39.99, 10)

-- insertion to dbo.RELATIONS

INSERT INTO dbo.RELATIONS (Product1, Product2)
VALUES
('SUPER Fertilizer', 'Light Salsa Garden'),
('SUPER Fertilizer', 'Root & Vegi Salad Garden'),
('SUPER Fertilizer', 'Sunflower: Golden'),
('Pruning & Harvesting Scissors', 'Light Salsa Garden'),
('Pruning & Harvesting Scissors', 'Root & Vegi Salad Garden'),
('Pruning & Harvesting Scissors', 'Fennel'),
('Pruning & Harvesting Scissors', 'Scallion')

-- insertion to dbo.USERS

INSERT INTO dbo.USERS (Email, Password)
VALUES
('tomge@post.bgu.ac.il', 'Mis63677'),
('sophiada@post.bgu.ac.il', 'Mis99988'),
('juliev@post.bgu.ac.il', 'Mis45774'),
('georgebush@gmail.com', 'g01w09B6'),
('mickeyM@walla.co.il', 'Hoho1235')

-- insertion to dbo.SEARCHES

INSERT INTO dbo.SEARCHES (SearchDT, IP_address, Email, Search_text)
VALUES
('1999-03-16 13:57:22', '10.100.102.13', 'mickeyM@walla.co.il', 'Seed'),
('2006-04-29 10:30:12', '255.30.2.0', NULL, 'Fertilizer'),
('2013-02-01 14:03:54', '99.234.8.8', 'juliev@post.bgu.ac.il', 'Burger'),
('2015-06-02 15:57:51', '82.43.43.74', 'georgebush@gmail.com', 'Pen'),
('2023-12-30 20:26:24', '69.120.55.26', 'sophiada@post.bgu.ac.il', 'Fennel'),
('2024-01-03 23:56:38', '0.74.255.254', 'sophiada@post.bgu.ac.il', 'Google')

-- insertion to dbo.RESULTS

INSERT INTO dbo.RESULTS (Name, SearchDT, IP_address)
VALUES
('Fennel', '1999-03-16 13:57:22', '10.100.102.13'),
('Scallion', '1999-03-16 13:57:22', '10.100.102.13'),
('Tomato: Heirloom Purple', '1999-03-16 13:57:22', '10.100.102.13'),
('Sunflower: Golden', '1999-03-16 13:57:22', '10.100.102.13'),
('Pepper: Large Bell', '1999-03-16 13:57:22', '10.100.102.13'),
('SUPER Fertilizer', '2006-04-29 10:30:12', '255.30.2.0'),
('Fennel', '2023-12-30 20:26:24', '69.120.55.26')

-- insertion to dbo.SEEDS

INSERT INTO dbo.SEEDS (Name, Size, Season, Sun_amount)
VALUES
('Fennel', 'Small', 'Spring', 'Full Sun / Partial Shade'),
('Scallion', 'Small', 'Winter', 'Partial Shade'),
('Tomato: Heirloom Purple', 'Large', 'Summer', 'Full Sun'),
('Sunflower: Golden', 'Small', 'Spring', 'Prefers Full Sun'),
('Pepper: Large Bell', 'Large', 'Fall', 'Prefers Full Sun')

-- insertion to dbo.SEED_TYPES

INSERT INTO dbo.SEED_TYPES (Name, Type)
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

INSERT INTO dbo.GARDENS (Name, Small_count, Large_count)
VALUES
('Light Salsa Garden', 2, 2),
('Root & Vegi Salad Garden', 5, 1),
('Custom: SnflwrGldn, PprLB', 2, 2),
('Custom: Scln, Fnl, SnflrGldn', 8, 0)

-- insertion to dbo.CHOSENS

INSERT INTO dbo.CHOSENS (Garden, Seed, Quantity)
VALUES
('Light Salsa Garden', 'Pepper: Large Bell', 1),
('Light Salsa Garden', 'Tomato: Heirloom Purple', 1),
('Light Salsa Garden', 'Scallion', 2),
('Root & Vegi Salad Garden', 'Fennel', 2),
('Root & Vegi Salad Garden', 'Tomato: Heirloom Purple', 1),
('Root & Vegi Salad Garden', 'Scallion', 3),
('Custom: SnflwrGldn, PprLB', 'Sunflower: Golden', 2),
('Custom: SnflwrGldn, PprLB', 'Pepper: Large Bell', 2),
('Custom: Scln, Fnl, SnflrGldn', 'Sunflower: Golden', 3),
('Custom: Scln, Fnl, SnflrGldn', 'Fennel', 2),
('Custom: Scln, Fnl, SnflrGldn', 'Scallion', 3)

-- insertion to dbo.DETAILS

INSERT INTO dbo.DETAILS (Name, Address, Company, Phone#)
VALUES
('Mickey H Mouse the 1st', 'United States, California, Disney Land, , , 00000001', 'Disney', '1234598889'),
('Goofy & Pluto', 'United States, California, Disney Land, , , 00000001', 'Disney', '0126549854'),
('Sargent Donald Duck', 'United States, California, Disney Land, , , 00000001', 'Disney', '1235516595'),
('George W. Bush', 'United States, Texas, Alburkurky, Saint st., 3, 23611356', 'The Government', '2222222221'),
('Laura Welch', 'United States, Texas, Alburkurky, Midland st., 8, 23615656', NULL, '2222222222'),
('Sargent Donald Duck', 'United States, Texas, Alburkurky, Saint st., 3, 23611356', 'The Government', '1235516595')

-- insertion to dbo.DETAILS_OF

INSERT INTO dbo.DETAILS_OF (Email, Name, Address)
VALUES
('mickeyM@walla.co.il', 'Mickey H Mouse the 1st', 'United States, California, Disney Land, , , 00000001'),
('mickeyM@walla.co.il', 'Goofy & Pluto', 'United States, California, Disney Land, , , 00000001'),
('mickeyM@walla.co.il', 'Sargent Donald Duck', 'United States, California, Disney Land, , , 00000001'),
('georgebush@gmail.com', 'George W. Bush', 'United States, Texas, Alburkurky, Saint st., 3, 23611356'),
('georgebush@gmail.com', 'Sargent Donald Duck', 'United States, Texas, Alburkurky, Saint st., 3, 23611356')

-- insertion to dbo.ORDERS

INSERT INTO dbo.ORDERS (OrderID, Email, Name, Address, OrderDate, Shipping_method, Payment_type)
VALUES
(33222, 'mickeyM@walla.co.il', 'Mickey H Mouse the 1st', 'United States, California, Disney Land, , , 00000001', '1999-03-16', 'Pickup from the factory', 'Klarna'),
(33223, NULL, 'Laura Welch', 'United States, Texas, Alburkurky, Midland st., 8, 23615656', '2009-03-16', NULL, 'Klarna'),
(33224, 'georgebush@gmail.com', 'George W. Bush', 'United States, Texas, Alburkurky, Saint st., 3, 23611356', '2015-08-19', NULL, 'ShopPay'),
(33225, 'mickeyM@walla.co.il', 'Sargent Donald Duck', 'United States, California, Disney Land, , , 00000001', '2016-06-06', 'Fedex', 'ShopPay'),
(33226, 'sophiada@post.bgu.ac.il', 'Goofy & Pluto', 'United States, California, Disney Land, , , 00000001', '2023-12-31', 'Fedex', 'ShopPay'),
(33227, 'georgebush@gmail.com', 'George W. Bush', 'United States, Texas, Alburkurky, Saint st., 3, 23611356', '2024-01-05', 'Fedex', 'Klarna'),
(33228, NULL, 'Laura Welch', 'United States, Texas, Alburkurky, Midland st., 8, 23615656', '2024-02-03', 'Private jet delivery', 'ShopPay')

-- insertion to dbo.INCLUSIONS

INSERT INTO dbo.INCLUSIONS (OrderID, Name, Quantity)
VALUES
(33222, 'Custom: SnflwrGldn, PprLB', 3),
(33222, 'Custom: Scln, Fnl, SnflrGldn', 3),
(33223, 'SUPER Fertilizer', 2),
(33224, 'Pruning & Harvesting Scissors', 1),
(33225, 'Light Salsa Garden', 20),
(33226, 'Fennel', 60),
(33227, 'Pruning & Harvesting Scissors', 5),
(33228, 'Sunflower: Golden', 30)

-- || CONSTRAINTS ADDITION SECTION ||

-- add constraint to inforce that a garden should hve the exact amount it can contain in seeds, is it possible???

-- || DROPING OF TABLES SECTION ||

DROP TABLE dbo.INCLUSIONS		-- creating dbo.INCLUSIONS table

DROP TABLE dbo.ORDERS			-- droping dbo.ORDERS table

DROP TABLE dbo.DETAILS_OF		-- droping dbo.DETAILS_OF table

DROP TABLE dbo.DETAILS			-- droping dbo.DETAILS table

DROP TABLE dbo.CHOSENS			-- droping dbo.CHOSENS table

DROP TABLE dbo.GARDENS			-- droping dbo.GARDENS table

DROP TABLE dbo.SEED_TYPES		-- droping dbo.SEED_TYPES table

DROP TABLE dbo.SEEDTYPELOOKUP	-- droping dbo.SEEDTYPELOOKUP table

DROP TABLE dbo.SEEDS			-- droping dbo.SEEDS table

DROP TABLE dbo.RESULTS			-- droping dbo.RESULTS table

DROP TABLE dbo.SEARCHES			-- droping dbo.SEARCHES table

DROP TABLE dbo.USERS			-- droping dbo.USERS table

DROP TABLE dbo.RELATIONS		-- droping dbo.RELATIONS table

DROP TABLE dbo.PRODUCTS			-- droping dbo.PRODUCTS table