using Microsoft.Extensions.Options;
using miupetshop.Data;
using miupetshop.Models;
using MongoDB.Driver;

namespace miupetshop.Services
{
    public class OrderService
    {
        private readonly IMongoCollection<Order> _ordersCollection;
        private readonly Random _random;

        public OrderService(IOptions<MongoDBSettings> settings)
        {
            var client = new MongoClient(settings.Value.ConnectionString);
            var database = client.GetDatabase(settings.Value.DatabaseName);
            _ordersCollection = database.GetCollection<Order>("orders");
            _random = new Random();
        }

        public async Task<Order> CreateOrderAsync(Order order)
        {
            // Generate unique order number
            order.OrderNumber = await GenerateOrderNumberAsync();
            
            // Set system fields
            order.OrderDate = DateTime.UtcNow;
            order.CreatedAt = DateTime.UtcNow;
            order.UpdatedAt = DateTime.UtcNow;
            order.IsActive = true;
            order.IsDeleted = false;
            
            // Set default order status
            if (string.IsNullOrEmpty(order.OrderStatus))
            {
                order.OrderStatus = "pending";
            }

            // Initialize timeline
            if (order.Timeline == null)
            {
                order.Timeline = new List<Timeline>();
            }
            
            // Add initial timeline entry
            order.Timeline.Add(new Timeline
            {
                Status = order.OrderStatus,
                Date = DateTime.UtcNow,
                Note = "Sipariş oluşturuldu"
            });

            await _ordersCollection.InsertOneAsync(order);
            return order;
        }

        public async Task<List<Order>> GetAllOrdersAsync()
        {
            return await _ordersCollection.Find(o => !o.IsDeleted).ToListAsync();
        }

        public async Task<List<Order>> GetOrdersByUserIdAsync(string userId)
        {
            return await _ordersCollection
                .Find(o => o.Customer.UserId == userId && !o.IsDeleted)
                .SortByDescending(o => o.CreatedAt)
                .ToListAsync();
        }

        public async Task<Order?> GetOrderByIdAsync(string orderId)
        {
            return await _ordersCollection
                .Find(o => o.Id == orderId && !o.IsDeleted)
                .FirstOrDefaultAsync();
        }

        public async Task<Order?> GetOrderByOrderNumberAsync(string orderNumber)
        {
            return await _ordersCollection
                .Find(o => o.OrderNumber == orderNumber && !o.IsDeleted)
                .FirstOrDefaultAsync();
        }

        public async Task<bool> UpdateOrderStatusAsync(string orderId, string newStatus, string note = "")
        {
            var filter = Builders<Order>.Filter.And(
                Builders<Order>.Filter.Eq(o => o.Id, orderId),
                Builders<Order>.Filter.Eq(o => o.IsDeleted, false)
            );

            var timelineEntry = new Timeline
            {
                Status = newStatus,
                Date = DateTime.UtcNow,
                Note = string.IsNullOrEmpty(note) ? $"Sipariş durumu {newStatus} olarak güncellendi" : note
            };

            var update = Builders<Order>.Update
                .Set(o => o.OrderStatus, newStatus)
                .Set(o => o.UpdatedAt, DateTime.UtcNow)
                .Push(o => o.Timeline, timelineEntry);

            var result = await _ordersCollection.UpdateOneAsync(filter, update);
            return result.ModifiedCount > 0;
        }

        private async Task<string> GenerateOrderNumberAsync()
        {
            string orderNumber;
            bool exists;
            
            do
            {
                // Generate order number: SP-YYYYMMDD-XXXXXX
                var datePrefix = DateTime.Now.ToString("yyyyMMdd");
                var randomSuffix = _random.Next(100000, 999999);
                orderNumber = $"SP-{datePrefix}-{randomSuffix}";
                
                // Check if order number already exists
                var existingOrder = await _ordersCollection
                    .Find(o => o.OrderNumber == orderNumber)
                    .FirstOrDefaultAsync();
                    
                exists = existingOrder != null;
                
            } while (exists);
            
            return orderNumber;
        }
    }
} 