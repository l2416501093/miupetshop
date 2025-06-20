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

        [HttpPost("createuser")]
        public async Task<IActionResult> CreateUser([FromBody] User user)
        {
            // Gerekli alanların boş olup olmadığını kontrol et
            if (string.IsNullOrEmpty(user.Username))
            {
                return BadRequest(new { message = "Kullanıcı adı gereklidir!" });
            }

            if (string.IsNullOrEmpty(user.Password))
            {
                return BadRequest(new { message = "Şifre gereklidir!" });
            }

            if (string.IsNullOrEmpty(user.Email))
            {
                return BadRequest(new { message = "E-posta adresi gereklidir!" });
            }

            if (string.IsNullOrEmpty(user.Tcno))
            {
                return BadRequest(new { message = "TC kimlik numarası gereklidir!" });
            }

            // Kullanıcı adının daha önce kullanılıp kullanılmadığını kontrol et
            var existingUserByUsername = await _userService.GetUserByUsernameAsync(user.Username);
            if (existingUserByUsername != null)
            {
                return Conflict(new { message = "Bu kullanıcı adı zaten kullanılmaktadır!" });
            }

            // E-posta adresinin daha önce kullanılıp kullanılmadığını kontrol et
            var existingUserByEmail = await _userService.GetUserByEmailAsync(user.Email);
            if (existingUserByEmail != null)
            {
                return Conflict(new { message = "Bu e-posta adresi zaten kullanılmaktadır!" });
            }

            // Şifre uzunluğu kontrolü
            if (user.Password.Length < 6)
            {
                return BadRequest(new { message = "Şifre en az 6 karakter olmalıdır!" });
            }

            // TC kimlik numarası format kontrolü
            if (user.Tcno.Length != 11 || !user.Tcno.All(char.IsDigit))
            {
                return BadRequest(new { message = "TC kimlik numarası 11 haneli olmalıdır!" });
            }

            // E-posta format kontrolü (basit)
            if (!user.Email.Contains("@") || !user.Email.Contains("."))
            {
                return BadRequest(new { message = "Geçerli bir e-posta adresi giriniz!" });
            }

            // Yeni kullanıcılar için isAdmin false olarak set et
            user.IsAdmin = false;

            await _userService.CreateUserAsync(user);
            return Ok(new { message = "Kullanıcı başarıyla eklendi!" });
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
                return BadRequest(new { message = "Kullanıcı adı ve şifre gereklidir!" });
            }

            var user = await _userService.LoginAsync(loginRequest.Username, loginRequest.Password);
            
            if (user == null)
            {
                return Unauthorized(new { message = "Kullanıcı adı veya şifre hatalı!" });
            }

            // Return all user info without password for security
            var userResponse = new
            {
                Id = user.Id,
                Username = user.Username,
                Email = user.Email,
                Address = user.Address,
                Tcno = user.Tcno,
                IsAdmin = user.IsAdmin
            };

            return Ok(new { 
                message = "Giriş başarılı!", 
                user = userResponse,
                success = true
            });
        }
    }
}
