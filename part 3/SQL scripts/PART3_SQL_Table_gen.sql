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

CREATE TABLE dbo.PLANTED (		-- creating dbo.PLANTED table
	Garden			Varchar(80)			NOT NULL,
	Seed			Varchar(80)			NOT NULL,
	Quantity		Tinyint				NOT NULL		DEFAULT 1,

	CONSTRAINT	Pk_PLANTED		PRIMARY KEY		(Garden, Seed),
	CONSTRAINT	Fk_Garden		FOREIGN KEY		(Garden)
									REFERENCES	dbo.GARDENS		(Name),
	CONSTRAINT	Fk_SEEDS_PLT		FOREIGN KEY		(Seed)
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

CREATE TABLE dbo.DESIGNS (		-- creating dbo.DESIGNS table
	Name			Varchar(80)			NOT NULL,
	DesignID		INT					NOT NULL,
	OrderID 		INT					NOT NULL,
	Quantity		Tinyint				NOT NULL		DEFAULT 1,

	CONSTRAINT	Pk_DESIGNS		PRIMARY KEY		(Name, DesignID),
	CONSTRAINT	Fk_ORDER_DSG	FOREIGN KEY		(OrderID)
									REFERENCES	dbo.ORDERS		(OrderID)
)

CREATE TABLE dbo.CHOSENS (		-- creating dbo.CHOSENS table
	Garden			Varchar(80)			NOT NULL,
	Design			INT					NOT NULL,
	Seed 			Varchar(80)			NOT NULL,
	Quantity		Tinyint				NOT NULL		DEFAULT 1,

	CONSTRAINT	Pk_CHOSENS		PRIMARY KEY		(Garden, Design, Seed),
	CONSTRAINT	Fk_CHOSENS_DSG		FOREIGN KEY		(Garden, Design)
									REFERENCES	dbo.DESIGNS		(Name, DesignID),
	CONSTRAINT	Fk_CHOSENS_SEED		FOREIGN KEY		(Seed)
									REFERENCES	dbo.SEEDS		(Name)
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

ALTER TABLE dbo.DESIGNS 
	ADD	CONSTRAINT	Ck_Quantity_dsg
			CHECK	(Quantity > 0)

ALTER TABLE dbo.INCLUSIONS
	ADD	CONSTRAINT	Ck_Quantity_ncl
			CHECK	(Quantity > 0)

-- add constraint to inforce phone# format

ALTER TABLE dbo.DETAILS
	ADD	CONSTRAINT	Ck_Phone#
			CHECK	(Phone# LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')

-- add constraint to inforce password restrictions

ALTER TABLE dbo.USERS
	ADD	CONSTRAINT	Ck_Password
			CHECK	(Password LIKE '%[0-9]' 
						AND Password LIKE '%[A-Z]' 
						AND Password LIKE '%[a-z]' 
						AND Password LIKE '%[!@#$%^&*()_-=+`~/\|.,;:"]%' 
						AND LEN([Password]) >= (8))


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

-- droping dbo.DESIGNS table and its constraints

ALTER TABLE dbo.DESIGNS
	DROP CONSTRAINT		Pk_DESIGNS, Fk_ORDER_DSG

DROP TABLE dbo.DESIGNS

-- droping dbo.CHOSENS table and its constraints

ALTER TABLE dbo.CHOSENS
	DROP CONSTRAINT		Pk_chosen, Fk_Garden, Fk_Seed_chs, Ck_Quantity_chs

DROP TABLE dbo.CHOSENS

-- droping dbo.PLANTED table and its constraints

ALTER TABLE dbo.PLANTED
	DROP CONSTRAINT		Pk_PLANTED, Fk_Garden, Fk_SEEDS_PLT

DROP TABLE dbo.PLANTED

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