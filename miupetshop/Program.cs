using miupetshop.Data;
using miupetshop.Services;

namespace miupetshop
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            // Add services to the container.
            builder.Services.AddControllers();
            
            // CORS policy ekleme - tüm çağrılar için serbest
            builder.Services.AddCors(options =>
            {
                options.AddPolicy("AllowAll", policy =>
                {
                    policy.AllowAnyOrigin()
                          .AllowAnyMethod()
                          .AllowAnyHeader();
                });
            });

            // Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
            builder.Services.AddEndpointsApiExplorer();
            builder.Services.AddSwaggerGen();
            builder.Services.Configure<MongoDBSettings>(
            builder.Configuration.GetSection("MongoDBSettings"));
            builder.Services.AddSingleton<UserService>();
            builder.Services.AddSingleton<CommentService>();
            builder.Services.AddSingleton<ProductService>();

            // HTTP hosting için URL konfigürasyonu - Network erişimi için
            builder.WebHost.UseUrls("http://0.0.0.0:8080", "https://0.0.0.0:5001");

            var app = builder.Build();

            // Configure the HTTP request pipeline.
            //if (app.Environment.IsDevelopment())
            {
                app.UseSwagger();
                app.UseSwaggerUI();
            }

            // CORS middleware'i ekle
            app.UseCors("AllowAll");

            // HTTPS yönlendirmesini kaldır (HTTP için)
            // app.UseHttpsRedirection();

            app.UseAuthorization();

            app.MapControllers();

            app.Run();
        }
    }
}
