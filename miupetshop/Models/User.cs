using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;
namespace miupetshop.Models
{
    public class User
    {
        [BsonId]
        [BsonRepresentation(BsonType.ObjectId)]
        public string? Id { get; set; }

        [BsonElement("username")]
        public string Username { get; set; }

        [BsonElement("password")]
        public string Password { get; set; }

        [BsonElement("address")]
        public string Address { get; set; }

        [BsonElement("email")]
        public string Email { get; set; }

        [BsonElement("tcno")]
        public string Tcno { get; set; }
    }

}
