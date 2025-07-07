using Microsoft.Extensions.Options;
using miupetshop.Data;
using miupetshop.Models;
using MongoDB.Driver;

namespace miupetshop.Services
{
    public class ProductService
    {
        private readonly IMongoCollection<Product> _productsCollection;

        public ProductService(IOptions<MongoDBSettings> settings)
        {
            var client = new MongoClient(settings.Value.ConnectionString);
            var database = client.GetDatabase(settings.Value.DatabaseName);
            _productsCollection = database.GetCollection<Product>("products");
        }

        public async Task<List<Product>> GetAllProductsAsync()
        {
            return await _productsCollection.Find(_ => true).ToListAsync();
        }

        public async Task CreateProductAsync(Product product)
        {
            // İndirimli fiyatı hesapla
            CalculateDiscountedPrice(product);
            await _productsCollection.InsertOneAsync(product);
        }

        public async Task<Product?> GetProductByIdAsync(string id)
        {
            var filter = Builders<Product>.Filter.Eq("_id", new MongoDB.Bson.ObjectId(id));
            return await _productsCollection.Find(filter).FirstOrDefaultAsync();
        }

        public async Task<bool> UpdateProductAsync(string id, Product product)
        {
            // İndirimli fiyatı hesapla
            CalculateDiscountedPrice(product);

            var filter = Builders<Product>.Filter.Eq("_id", new MongoDB.Bson.ObjectId(id));
            var update = Builders<Product>.Update
                .Set("name", product.Name)
                .Set("description", product.Description)
                .Set("image", product.Image)
                .Set("price", product.Price)
                .Set("discountPercentage", product.DiscountPercentage)
                .Set("discountedPrice", product.DiscountedPrice);

            var result = await _productsCollection.UpdateOneAsync(filter, update);
            return result.ModifiedCount > 0;
        }

        public async Task<bool> DeleteProductAsync(string id)
        {
            var filter = Builders<Product>.Filter.Eq("_id", new MongoDB.Bson.ObjectId(id));
            var result = await _productsCollection.DeleteOneAsync(filter);
            return result.DeletedCount > 0;
        }

        private void CalculateDiscountedPrice(Product product)
        {
            // İndirim yüzdesi 0-100 arasında olmalı
            if (product.DiscountPercentage < 0)
                product.DiscountPercentage = 0;
            else if (product.DiscountPercentage > 100)
                product.DiscountPercentage = 100;

            // İndirimli fiyatı hesapla
            product.DiscountedPrice = product.Price - (product.Price * product.DiscountPercentage / 100);
        }
    }
} 