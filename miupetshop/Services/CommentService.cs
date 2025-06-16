using Microsoft.Extensions.Options;
using miupetshop.Data;
using MongoDB.Driver;

namespace miupetshop.Services
{
    public class CommentService
    {
        private readonly IMongoCollection<Comment> _commentsCollection;

        public CommentService(IOptions<MongoDBSettings> settings)
        {
            var client = new MongoClient(settings.Value.ConnectionString);
            var database = client.GetDatabase(settings.Value.DatabaseName);
            _commentsCollection = database.GetCollection<Comment>("comments");
        }

        public async Task<List<Comment>> GetAllCommentsAsync()
        {
            return await _commentsCollection.Find(_ => true).ToListAsync();
        }

        public async Task<List<Comment>> GetCommentsByMovieIdAsync(string movieId)
        {
            return await _commentsCollection
                .Find(comment => comment.MovieId == movieId)
                .ToListAsync();
        }
    }
}
