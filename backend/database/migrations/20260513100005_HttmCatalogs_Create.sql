-- HTTM Phase 1 — §1.1.1: Danh mục hệ thống (type + code unique).

IF OBJECT_ID(N'dbo.HttmCatalogs', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HttmCatalogs (
        Id UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT DF_HttmCatalogs_Id DEFAULT (NEWSEQUENTIALID()),

        Type NVARCHAR(50) NOT NULL,
        Code NVARCHAR(100) NOT NULL,
        Name NVARCHAR(500) NOT NULL,
        NameEn NVARCHAR(500) NULL,
        ParentCode NVARCHAR(100) NULL,
        SortOrder SMALLINT NOT NULL
            CONSTRAINT DF_HttmCatalogs_SortOrder DEFAULT (0),
        IsActive BIT NOT NULL
            CONSTRAINT DF_HttmCatalogs_IsActive DEFAULT (1),
        Metadata NVARCHAR(MAX) NULL
            CONSTRAINT CK_HttmCatalogs_MetadataJson CHECK (
                Metadata IS NULL OR (ISJSON(Metadata) = 1)
            ),

        CONSTRAINT UQ_HttmCatalogs_Type_Code UNIQUE (Type, Code),

        CONSTRAINT PK_HttmCatalogs PRIMARY KEY CLUSTERED (Id)
    );

    CREATE NONCLUSTERED INDEX IX_HttmCatalogs_Type_IsActive_SortOrder
        ON dbo.HttmCatalogs (Type, IsActive, SortOrder);
END;
GO
