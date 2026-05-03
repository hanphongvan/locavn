namespace Httm.XangDau.Api.Shared.Persistence.Migrations;

/// <summary>Deletes a store inventory voucher header (detail rows cascade).</summary>
internal static class StoreAdminInventoryTransactionDeleteProcedureSql
{
    internal const string DeleteByHeaderId =
        """
        CREATE OR ALTER PROCEDURE dbo.sp_StoreAdmin_StationInventoryTransactionHeaders_DeleteById
            @HeaderId INT,
            @RetailCapDonViId INT
        AS
        BEGIN
            SET NOCOUNT ON;

            IF @HeaderId < 1
            BEGIN
                RAISERROR(N'HeaderId is invalid.', 16, 1);
                RETURN;
            END;

            IF NOT EXISTS (
                SELECT 1
                FROM dbo.StationInventoryTransactionHeaders AS h
                INNER JOIN dbo.DM_DonVi AS dv ON dv.Id = h.DonViId AND dv.CapDonViId = @RetailCapDonViId
                WHERE h.Id = @HeaderId)
            BEGIN
                RAISERROR(N'Header not found or not a retail store for this cap.', 16, 1);
                RETURN;
            END;

            DELETE FROM dbo.StationInventoryTransactionHeaders WHERE Id = @HeaderId;
        END;
        """;
}
