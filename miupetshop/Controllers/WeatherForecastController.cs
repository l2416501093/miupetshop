using Microsoft.AspNetCore.Mvc;
using MongoDB.Driver;
using MongoDB.Bson;
using miupetshop.Services;

namespace miupetshop.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class WeatherForecastController : ControllerBase
    {
        private readonly CommentService _commentService;

        private readonly ILogger<WeatherForecastController> _logger;

        public WeatherForecastController(ILogger<WeatherForecastController> logger, CommentService commentService)
        {
            _logger = logger;
            _commentService = commentService;
        }

        [HttpGet(Name = "GetWeatherForecast")]
        public async Task<IActionResult> Get()
        {
            var comments = await _commentService.GetAllCommentsAsync();
            return Ok(comments);
        }
    }
}
