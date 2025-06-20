using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace miupetshop.Models
{
    public class Order
    {
        [BsonId]
        [BsonRepresentation(BsonType.ObjectId)]
        public string? Id { get; set; }

        [BsonElement("orderNumber")]
        public string OrderNumber { get; set; }

        [BsonElement("orderDate")]
        public DateTime OrderDate { get; set; }

        [BsonElement("orderStatus")]
        public string OrderStatus { get; set; } // pending, confirmed, processing, shipped, delivered, cancelled

        [BsonElement("customer")]
        public Customer Customer { get; set; }

        [BsonElement("addresses")]
        public Addresses Addresses { get; set; }

        [BsonElement("items")]
        public List<OrderItem> Items { get; set; }

        [BsonElement("pricing")]
        public Pricing Pricing { get; set; }

        [BsonElement("payment")]
        public Payment Payment { get; set; }

        [BsonElement("shipping")]
        public Shipping Shipping { get; set; }

        [BsonElement("timeline")]
        public List<Timeline> Timeline { get; set; }

        [BsonElement("notes")]
        public Notes Notes { get; set; }

        [BsonElement("createdAt")]
        public DateTime CreatedAt { get; set; }

        [BsonElement("updatedAt")]
        public DateTime UpdatedAt { get; set; }

        [BsonElement("createdBy")]
        [BsonRepresentation(BsonType.ObjectId)]
        public string? CreatedBy { get; set; }

        [BsonElement("isActive")]
        public bool IsActive { get; set; }

        [BsonElement("isDeleted")]
        public bool IsDeleted { get; set; }
    }

    public class Customer
    {
        [BsonElement("userId")]
        [BsonRepresentation(BsonType.ObjectId)]
        public string UserId { get; set; }

        [BsonElement("username")]
        public string Username { get; set; }

        [BsonElement("email")]
        public string Email { get; set; }

        [BsonElement("phone")]
        public string Phone { get; set; }
    }

    public class Addresses
    {
        [BsonElement("delivery")]
        public Address Delivery { get; set; }

        [BsonElement("billing")]
        public Address Billing { get; set; }
    }

    public class Address
    {
        [BsonElement("fullAddress")]
        public string FullAddress { get; set; }

        [BsonElement("city")]
        public string City { get; set; }

        [BsonElement("district")]
        public string District { get; set; }

        [BsonElement("postalCode")]
        public string PostalCode { get; set; }

        [BsonElement("country")]
        public string Country { get; set; }
    }

    public class OrderItem
    {
        [BsonElement("productId")]
        [BsonRepresentation(BsonType.ObjectId)]
        public string ProductId { get; set; }

        [BsonElement("productName")]
        public string ProductName { get; set; }

        [BsonElement("productImage")]
        public string ProductImage { get; set; }

        [BsonElement("quantity")]
        public int Quantity { get; set; }

        [BsonElement("unitPrice")]
        public decimal UnitPrice { get; set; }

        [BsonElement("totalPrice")]
        public decimal TotalPrice { get; set; }

        [BsonElement("category")]
        public string Category { get; set; }
    }

    public class Pricing
    {
        [BsonElement("subtotal")]
        public decimal Subtotal { get; set; }

        [BsonElement("tax")]
        public decimal Tax { get; set; }

        [BsonElement("shipping")]
        public decimal Shipping { get; set; }

        [BsonElement("discount")]
        public decimal Discount { get; set; }

        [BsonElement("total")]
        public decimal Total { get; set; }

        [BsonElement("currency")]
        public string Currency { get; set; }
    }

    public class Payment
    {
        [BsonElement("method")]
        public string Method { get; set; } // bank_transfer, credit_card, cash_on_delivery

        [BsonElement("status")]
        public string Status { get; set; } // pending, completed, failed, refunded

        [BsonElement("transactionId")]
        public string? TransactionId { get; set; }

        [BsonElement("paidAmount")]
        public decimal PaidAmount { get; set; }

        [BsonElement("paymentDate")]
        public DateTime? PaymentDate { get; set; }
    }

    public class Shipping
    {
        [BsonElement("method")]
        public string Method { get; set; } // standard, express, same_day

        [BsonElement("trackingNumber")]
        public string? TrackingNumber { get; set; }

        [BsonElement("estimatedDelivery")]
        public DateTime EstimatedDelivery { get; set; }

        [BsonElement("actualDelivery")]
        public DateTime? ActualDelivery { get; set; }

        [BsonElement("carrier")]
        public string Carrier { get; set; }
    }

    public class Timeline
    {
        [BsonElement("status")]
        public string Status { get; set; }

        [BsonElement("date")]
        public DateTime Date { get; set; }

        [BsonElement("note")]
        public string Note { get; set; }
    }

    public class Notes
    {
        [BsonElement("customerNote")]
        public string? CustomerNote { get; set; }

        [BsonElement("adminNote")]
        public string? AdminNote { get; set; }

        [BsonElement("deliveryNote")]
        public string? DeliveryNote { get; set; }
    }
} 