using Microsoft.AspNetCore.Mvc;
using miupetshop.Models;
using miupetshop.Services;

namespace miupetshop.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UsersController : ControllerBase
    {
        private readonly UserService _userService;

        public UsersController(UserService userService)
        {
            _userService = userService;
        }

        [HttpPost]
        public async Task<IActionResult> CreateUser([FromBody] User user)
        {
            await _userService.CreateUserAsync(user);
            return Ok(new { message = "User inserted successfully!" });
        }

        [HttpGet]
        public async Task<IActionResult> GetAllUsers()
        {
            var users = await _userService.GetAllUsersAsync();
            return Ok(users);
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest loginRequest)
        {
            if (string.IsNullOrEmpty(loginRequest.Username) || string.IsNullOrEmpty(loginRequest.Password))
            {
                return BadRequest(new { message = "Username and password are required!" });
            }

            var user = await _userService.LoginAsync(loginRequest.Username, loginRequest.Password);
            
            if (user == null)
            {
                return Unauthorized(new { message = "Invalid username or password!" });
            }

            // Return user info without password for security
            var userResponse = new
            {
                Id = user.Id,
                Username = user.Username,
                Email = user.Email,
                Address = user.Address,
                Tcno = user.Tcno
            };

            return Ok(new { 
                message = "Login successful!", 
                user = userResponse 
            });
        }
    }
}
