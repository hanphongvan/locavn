-- HTTM Phase 2 — Bảng tạm lưu đề xuất cập nhật / tạo mới hạ tầng từ public user.
-- Workflow: public submit (status=pending) → cán bộ review → approve (merge vào HttmFacilities) hoặc reject.
-- FacilityId NULL = đề xuất tạo mới; non-NULL = đề xuất cập nhật facility hiện có.

IF OBJECT_ID(N'dbo.HttmFacilitySubmissions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HttmFacilitySubmissions (
        Id              UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_HttmFacilitySubmissions_Id DEFAULT (NEWSEQUENTIALID()),

        FacilityId      UNIQUEIDENTIFIER NULL,
        SubmissionType  VARCHAR(20)      NOT NULL,  -- 'update' | 'create_new'
        Status          VARCHAR(20)      NOT NULL CONSTRAINT DF_HttmFacilitySubmissions_Status DEFAULT ('pending'),

        -- Payload đầy đủ thông tin facility, validate ISJSON.
        PayloadJson     NVARCHAR(MAX)    NOT NULL,

        -- Cột tóm tắt phục vụ filter / search nhanh (không cần parse JSON).
        Name            NVARCHAR(500)    NOT NULL,
        HttmType        VARCHAR(50)      NULL,
        ProvinceCode    VARCHAR(10)      NULL,
        WardCode        VARCHAR(10)      NULL,

        -- Người gửi (bắt buộc tên + phone — theo decision user)
        SubmitterName   NVARCHAR(200)    NOT NULL,
        SubmitterPhone  NVARCHAR(50)     NOT NULL,
        SubmitterEmail  NVARCHAR(200)    NULL,
        SubmitterNotes  NVARCHAR(MAX)    NULL,

        -- Trace cho anti-abuse / audit
        SubmitterIp     VARCHAR(45)      NULL,
        SubmitterUserAgent NVARCHAR(500) NULL,
        SubmittedAt     DATETIMEOFFSET(7) NOT NULL CONSTRAINT DF_HttmFacilitySubmissions_SubmittedAt DEFAULT (SYSDATETIMEOFFSET()),

        -- Review fields
        ReviewedBy      NVARCHAR(128)    NULL,  -- AspNetUsers.Id
        ReviewedAt      DATETIMEOFFSET(7) NULL,
        ReviewNotes     NVARCHAR(MAX)    NULL,
        MergedFacilityId UNIQUEIDENTIFIER NULL,  -- Với type=create_new, Id facility được tạo sau khi approve.

        CONSTRAINT PK_HttmFacilitySubmissions PRIMARY KEY CLUSTERED (Id),
        CONSTRAINT FK_HttmFacilitySubmissions_HttmFacilities FOREIGN KEY (FacilityId)
            REFERENCES dbo.HttmFacilities (Id),
        CONSTRAINT FK_HttmFacilitySubmissions_MergedFacility FOREIGN KEY (MergedFacilityId)
            REFERENCES dbo.HttmFacilities (Id),
        CONSTRAINT CK_HttmFacilitySubmissions_Status
            CHECK (Status IN ('pending', 'approved', 'rejected')),
        CONSTRAINT CK_HttmFacilitySubmissions_Type
            CHECK (SubmissionType IN ('update', 'create_new')),
        CONSTRAINT CK_HttmFacilitySubmissions_PayloadJson CHECK (ISJSON(PayloadJson) = 1)
    );

    CREATE INDEX IX_HttmFacilitySubmissions_Status_Province
        ON dbo.HttmFacilitySubmissions (Status, ProvinceCode);
    CREATE INDEX IX_HttmFacilitySubmissions_FacilityId
        ON dbo.HttmFacilitySubmissions (FacilityId) WHERE FacilityId IS NOT NULL;
    CREATE INDEX IX_HttmFacilitySubmissions_SubmittedAt
        ON dbo.HttmFacilitySubmissions (SubmittedAt DESC);
END
GO
