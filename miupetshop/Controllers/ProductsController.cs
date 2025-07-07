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

                if (product.Price <= 0)
                {
                    return BadRequest(new { message = "Ürün fiyatı sıfırdan büyük olmalıdır!" });
                }

                // İndirim oranı kontrolü
                if (product.DiscountPercentage < 0 || product.DiscountPercentage > 100)
                {
                    return BadRequest(new { message = "İndirim oranı 0-100 arasında olmalıdır!" });
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

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateProduct(string id, [FromBody] Product product)
        {
            try
            {
                if (string.IsNullOrEmpty(id))
                {
                    return BadRequest(new { message = "Ürün ID gereklidir!" });
                }

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

                if (product.Price <= 0)
                {
                    return BadRequest(new { message = "Ürün fiyatı sıfırdan büyük olmalıdır!" });
                }

                // İndirim oranı kontrolü
                if (product.DiscountPercentage < 0 || product.DiscountPercentage > 100)
                {
                    return BadRequest(new { message = "İndirim oranı 0-100 arasında olmalıdır!" });
                }

                // Ürünün mevcut olup olmadığını kontrol et
                var existingProduct = await _productService.GetProductByIdAsync(id);
                if (existingProduct == null)
                {
                    return NotFound(new { message = "Güncellenecek ürün bulunamadı!" });
                }

                var updated = await _productService.UpdateProductAsync(id, product);
                
                if (!updated)
                {
                    return StatusCode(500, new { message = "Ürün güncellenirken bir hata oluştu!" });
                }

                // Güncellenmiş ürünü döndür
                var updatedProduct = await _productService.GetProductByIdAsync(id);
                return Ok(new { 
                    message = "Ürün başarıyla güncellendi!",
                    product = updatedProduct
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Ürün güncellenirken bir hata oluştu!", error = ex.Message });
            }
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteProduct(string id)
        {
            try
            {
                if (string.IsNullOrEmpty(id))
                {
                    return BadRequest(new { message = "Ürün ID gereklidir!" });
                }

                // Ürünün mevcut olup olmadığını kontrol et
                var existingProduct = await _productService.GetProductByIdAsync(id);
                if (existingProduct == null)
                {
                    return NotFound(new { message = "Silinecek ürün bulunamadı!" });
                }

                var deleted = await _productService.DeleteProductAsync(id);
                
                if (!deleted)
                {
                    return StatusCode(500, new { message = "Ürün silinirken bir hata oluştu!" });
                }

                return Ok(new { message = "Ürün başarıyla silindi!" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Ürün silinirken bir hata oluştu!", error = ex.Message });
            }
        }
    }
} 