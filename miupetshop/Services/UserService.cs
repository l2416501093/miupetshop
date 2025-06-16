using Microsoft.Extensions.Options;
using miupetshop.Data;
using miupetshop.Models;
using MongoDB.Driver;

namespace miupetshop.Services
{
    public class UserService
    {
        private readonly IMongoCollection<User> _usersCollection;

        public UserService(IOptions<MongoDBSettings> settings)
        {
            var client = new MongoClient(settings.Value.ConnectionString);
            var database = client.GetDatabase(settings.Value.DatabaseName);
            _usersCollection = database.GetCollection<User>("users");
        }

        public async Task CreateUserAsync(User user)
        {
            await _usersCollection.InsertOneAsync(user);
        }

        public async Task<List<User>> GetAllUsersAsync()
        {
            return await _usersCollection.Find(_ => true).ToListAsync();
        }

        public async Task<User?> LoginAsync(string username, string password)
        {
            var user = await _usersCollection
                .Find(u => u.Username == username && u.Password == password)
                .FirstOrDefaultAsync();
            return user;
        }
    }

}
