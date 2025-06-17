using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace miupetshop.Models
{
    public class Product
    {
        [BsonId]
        [BsonRepresentation(BsonType.ObjectId)]
        public string? Id { get; set; }

        [BsonElement("name")]
        public string Name { get; set; }

        [BsonElement("description")]
        public string Description { get; set; }

        [BsonElement("image")]
        public string Image { get; set; }
    }
} 