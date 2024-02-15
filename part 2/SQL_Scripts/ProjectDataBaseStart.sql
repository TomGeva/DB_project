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
	Email			Varchar(40)						NULL, -- emphasizing that there could be a search not made by a user
	Search_text		Varchar(80)						NOT NULL,

	CONSTRAINT	Pk_searches		PRIMARY KEY	(SearchDT, IP_address),
	CONSTRAINT	Fk_user_srch	FOREIGN KEY	(Email)
									REFERENCES	dbo.USERS		(Email),
	CONSTRAINT	Ck_IP_address	CHECK		(IP_address LIKE '') -- needed to be implemented
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
	Sun_amount		Varchar(30),

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
	Company			Varchar(40),
	Phone#			Varchar(30)						NOT NULL,

	CONSTRAINT	Pk_details		PRIMARY KEY	(Name, Address),
	CONSTRAINT	Ck_Phone#		CHECK		(Phone# LIKE '') -- needed to be implmented
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
	Shipping_method	Varchar(100),
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

-- || CONSTRAINTS ADDITION SECTION ||



-- || DROPING OF TABLES SECTION ||

DROP TABLE dbo.INCLUSIONS		-- creating dbo.INCLUSIONS table

DROP TABLE dbo.ORDERS			-- droping dbo.ORDERS table

DROP TABLE dbo.DETAILS_OF		-- droping dbo.DETAILS_OF table

DROP TABLE dbo.DETAILS			-- droping dbo.DETAILS table

DROP TABLE dbo.CHOSENS			-- droping dbo.CHOSENS table

DROP TABLE dbo.GARDENS			-- droping dbo.GARDENS table

DROP TABLE dbo.SEED_TYPES		-- droping dbo.SEED_TYPES table

DROP TABLE dbo.SEEDS			-- droping dbo.SEEDS table

DROP TABLE dbo.RESULTS			-- droping dbo.RESULTS table

DROP TABLE dbo.SEARCHES			-- droping dbo.SEARCHES table

DROP TABLE dbo.USERS			-- droping dbo.USERS table

DROP TABLE dbo.RELATIONS		-- droping dbo.RELATIONS table

DROP TABLE dbo.PRODUCTS			-- droping dbo.PRODUCTS table