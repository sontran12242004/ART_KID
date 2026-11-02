namespace ArtKids.DAL.Entities;

public sealed class VnpayPayment : Entity
{
    public string OrderId { get; set; } = "";
    public long AmountVnd { get; set; }
    public string Status { get; set; } = "pending";
    public DateTime ExpiresAt { get; set; }
    public string? TransactionNo { get; set; }
    public string? ResponseCode { get; set; }
    public DateTime? PaidAt { get; set; }
}
