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
            await _productsCollection.InsertOneAsync(product);
        }

        public async Task<Product?> GetProductByIdAsync(string id)
        {
            return await _productsCollection.Find(p => p.Id == id).FirstOrDefaultAsync();
        }
    }
} 