-- USE IMT577_DW_URVI_CHAUDHARY;

create or replace table Fact_SalesActual
(
    DimProductID            INT CONSTRAINT FK_DimProductID FOREIGN KEY REFERENCES Dim_Product(DimProductID),
    DimStoreID              INT CONSTRAINT FK_DimStoreID FOREIGN KEY REFERENCES Dim_Store(DimStoreID),
    DimResellerID           INT CONSTRAINT FK_DimResellerID FOREIGN KEY REFERENCES Dim_Reseller(DimResellerID),
    DimCustomerID           INT CONSTRAINT FK_DimCustomerID FOREIGN KEY REFERENCES Dim_Customer(DimCustomerID),
    DimChannelID            INT CONSTRAINT FK_DimChannelID FOREIGN KEY REFERENCES Dim_Channel(DimChannelID),
    DimSaleDateID           NUMBER(9,0) CONSTRAINT FK_DimSaleDateID FOREIGN KEY REFERENCES Dim_Date(DATE_PKEY),
    DimLocationID           INT CONSTRAINT FK_DimLocationID FOREIGN KEY REFERENCES Dim_Location(DimLocationID),
    SourceSalesHeaderID     INT NOT NULL,
    SourceSalesDetailID     INT NOT NULL,
    SaleAmount              FLOAT NOT NULL,
    SaleQuantity            INT NOT NULL,
    SaleUnitPrice           FLOAT NOT NULL,
    SaleExtendedCost        FLOAT NOT NULL,
    SaleTotalProfit         FLOAT NOT NULL
);

insert into Fact_SalesActual
(
    DimProductID,
    DimStoreID,
    DimResellerID,
    DimCustomerID,
    DimChannelID,
    DimSaleDateID,
    DimLocationID,
    SourceSalesHeaderID,
    SourceSalesDetailID,
    SaleAmount,
    SaleQuantity,
    SaleUnitPrice,
    SaleExtendedCost,
    SaleTotalProfit
)
select
    nvl(Dim_Product.DimProductID, -1) as DimProductID,
    nvl(Dim_Store.DimStoreID, -1) as DimStoreID,
    nvl(Dim_Reseller.DimResellerID, -1) as DimResellerID,
    nvl(Dim_Customer.DimCustomerID, -1) as DimCustomerID,
    nvl(Dim_Channel.DimChannelID, -1) as DimChannelID,
    cast(replace(replace(cast(STAGE_SALESHEADER.Date as DATE), '00', '20'), '-', '') AS NUMBER(9)) as DimSaleDateID,
    coalesce(Dim_Store.DimLocationID, Dim_Customer.DimLocationID, Dim_Reseller.DimLocationID, -1) AS DimLocationID,
    STAGE_SALESHEADER.SalesHeaderID as SourceSalesHeaderID,
    STAGE_SALESDETAIL.SalesDetailID as SourceSalesDetailID,
    STAGE_SALESDETAIL.SalesAmount as SaleAmount,
    STAGE_SALESDETAIL.SalesQuantity as SaleQuantity,
    Dim_Product.ProductRetailPrice as SaleUnitPrice,
    round(Dim_Product.ProductCost * STAGE_SALESDETAIL.SalesQuantity, 2) as SaleExtendedCost,
    round(STAGE_SALESDETAIL.SalesAmount - SaleExtendedCost, 2) as SaleTotalProfit
from
    STAGE_SALESHEADER
join
    STAGE_SALESDETAIL
on  
    STAGE_SALESHEADER.SalesHeaderID = STAGE_SALESDETAIL.SalesHeaderID
join
    Dim_Product
on
    STAGE_SALESDETAIL.ProductID = Dim_Product.ProductID
left join
    Dim_Channel
on
    STAGE_SALESHEADER.ChannelID = Dim_Channel.ChannelID
left join
    Dim_Store
on
    STAGE_SALESHEADER.StoreID = Dim_Store.StoreID
left join
    Dim_Customer
on
    STAGE_SALESHEADER.CustomerID = Dim_Customer.CustomerID
left join
    Dim_Reseller
on
    STAGE_SALESHEADER.ResellerID = Dim_Reseller.ResellerID;


-- SELECT * FROM Fact_SalesActual;


CREATE OR REPLACE TABLE Fact_SRCSalesTarget
(
	 DimStoreID INT CONSTRAINT FK_DimStoreID FOREIGN KEY REFERENCES Dim_Store(DimStoreID) --Foreign Key
    ,DimResellerID INT CONSTRAINT FK_DimResellerID FOREIGN KEY REFERENCES Dim_Reseller(DimResellerID) --Foreign Key
    ,DimChannelID INT CONSTRAINT FK_DimChannelID FOREIGN KEY REFERENCES Dim_Channel(DimChannelID) --Foreign Key
	,DimTargetDateID number(9) CONSTRAINT FK_DimTargetDateID FOREIGN KEY REFERENCES Dim_Date(Date_PKEY) --Foreign Key
    ,SalesTargetAmount NUMBER(12,2)

);

INSERT INTO Fact_SRCSalesTarget
(
	 DimChannelID
	,DimStoreID 
    ,DimResellerID  
	,DimTargetDateID
    ,SalesTargetAmount

)

SELECT 
		Dim_Channel.DimChannelID
		,NVL(Dim_Store.DimStoreID, -1) AS DimStoreID
		,NVL(Dim_Reseller.DimResellerID, -1) AS DimResellerID
		,Dim_Date.Date_PKEY AS DimTargetDateID
		,ROUND(STAGE_TARGETDATACHANNELRESELLERANDSTORE.TARGETSALESAMOUNT/365,2) AS SalesTargetAmount
FROM STAGE_TARGETDATACHANNELRESELLERANDSTORE
INNER JOIN Dim_Channel ON Dim_Channel.CHANNELNAME = CASE WHEN STAGE_TARGETDATACHANNELRESELLERANDSTORE.CHANNELNAME = 'Online' THEN 'Online Sales' ELSE STAGE_TARGETDATACHANNELRESELLERANDSTORE.CHANNELNAME END
LEFT JOIN Dim_Store ON Dim_Store.STORENUMBER = CASE WHEN STAGE_TARGETDATACHANNELRESELLERANDSTORE.TARGETNAME = 'Store Number 5' THEN 5
													WHEN STAGE_TARGETDATACHANNELRESELLERANDSTORE.TARGETNAME = 'Store Number 8' THEN 8
													WHEN STAGE_TARGETDATACHANNELRESELLERANDSTORE.TARGETNAME = 'Store Number 10' THEN 10
													WHEN STAGE_TARGETDATACHANNELRESELLERANDSTORE.TARGETNAME = 'Store Number 21' THEN 21
													WHEN STAGE_TARGETDATACHANNELRESELLERANDSTORE.TARGETNAME = 'Store Number 34' THEN 34
													WHEN STAGE_TARGETDATACHANNELRESELLERANDSTORE.TARGETNAME = 'Store Number 39' THEN 39 END
LEFT JOIN Dim_Reseller ON Dim_Reseller.RESELLERNAME = STAGE_TARGETDATACHANNELRESELLERANDSTORE.TARGETNAME
LEFT JOIN Dim_Date ON STAGE_TARGETDATACHANNELRESELLERANDSTORE.YEAR = Dim_Date.YEAR


-- SELECT * FROM Fact_SRCSalesTarget;


CREATE OR REPLACE TABLE Fact_ProductSalesTarget
(
	DimProductID INT CONSTRAINT FK_DimProductID FOREIGN KEY REFERENCES Dim_Product(DimProductID) --Foreign Key
    ,DimTargetDateID NUMBER(9) CONSTRAINT FK_DimTargetDateID FOREIGN KEY REFERENCES Dim_Date(DATE_PKEY) --Foreign Key
    ,ProductTargetSalesQuantity FLOAT
);

INSERT INTO Fact_ProductSalesTarget
	(
		DimProductID
        ,DimTargetDateID
		,ProductTargetSalesQuantity
	)
	SELECT  
		   Dim_Product.DimProductID
		  ,Dim_Date.DATE_PKEY
          ,Stage_TARGETDATAPRODUCT.SALESQUANTITYTARGET as ProductTargetSalesQuantity
	FROM Dim_Product
	INNER JOIN Stage_TARGETDATAPRODUCT ON
	Dim_Product.ProductID = Stage_TARGETDATAPRODUCT.ProductID
	INNER JOIN Dim_Date ON
	Dim_Date.YEAR = Stage_TARGETDATAPRODUCT.YEAR     

-- SELECT * FROM Fact_ProductSalesTarget	

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------