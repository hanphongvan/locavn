namespace Httm.XangDau.Api.Features.Leader;

/// <summary>
/// Trạng thái hiển thị marker đầu mối (bản đồ Lãnh đạo): <c>0</c> an toàn, <c>1</c> cảnh báo, <c>2</c> nguy cơ.
/// Logic phải trùng <c>dbo.fn_Leader_Map_DistributorReserveDisplayStatus</c> (migration cùng tên).
/// </summary>
public static class LeaderMapDistributorReserveDisplayStatus
{
    public const byte Safe = 0;

    public const byte Warning = 1;

    public const byte Danger = 2;

    /// <summary>Từ số ngày dự trữ (một nhiên liệu). <see langword="null"/> → cảnh báo (thiếu/ghép dữ liệu).</summary>
    public static byte FromDays(int? days) => days switch
    {
        null => Warning,
        > 10 => Safe,
        >= 5 and <= 10 => Warning,
        _ => Danger,
    };
}
