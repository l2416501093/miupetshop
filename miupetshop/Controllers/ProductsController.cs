using Microsoft.AspNetCore.Mvc;
using miupetshop.Models;
using miupetshop.Services;

namespace miupetshop.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ProductsController : ControllerBase
    {
        private readonly ProductService _productService;

        public ProductsController(ProductService productService)
        {
            _productService = productService;
        }

        [HttpGet]
        public async Task<IActionResult> GetAllProducts()
        {
            try
            {
                var products = await _productService.GetAllProductsAsync();
                return Ok(products);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Ürünler yüklenirken bir hata oluştu!", error = ex.Message });
            }
        }

        [HttpPost]
        public async Task<IActionResult> CreateProduct([FromBody] Product product)
        {
            try
            {
                // Gerekli alanların kontrolü
                if (string.IsNullOrEmpty(product.Name))
                {
                    return BadRequest(new { message = "Ürün adı gereklidir!" });
                }

                if (string.IsNullOrEmpty(product.Description))
                {
                    return BadRequest(new { message = "Ürün açıklaması gereklidir!" });
                }

                if (string.IsNullOrEmpty(product.Image))
                {
                    return BadRequest(new { message = "Ürün resmi gereklidir!" });
                }

                await _productService.CreateProductAsync(product);
                return Ok(new { message = "Ürün başarıyla eklendi!" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Ürün eklenirken bir hata oluştu!", error = ex.Message });
            }
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetProductById(string id)
        {
            try
            {
                var product = await _productService.GetProductByIdAsync(id);
                if (product == null)
                {
                    return NotFound(new { message = "Ürün bulunamadı!" });
                }
                return Ok(product);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Ürün yüklenirken bir hata oluştu!", error = ex.Message });
            }
        }
    }
} 