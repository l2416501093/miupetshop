using Microsoft.AspNetCore.Mvc;
using miupetshop.Models;
using miupetshop.Services;

namespace miupetshop.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class OrdersController : ControllerBase
    {
        private readonly OrderService _orderService;

        public OrdersController(OrderService orderService)
        {
            _orderService = orderService;
        }

        [HttpPost]
        public async Task<IActionResult> CreateOrder([FromBody] Order order)
        {
            try
            {
                // Gerekli alanların kontrolü
                if (order.Customer == null)
                {
                    return BadRequest(new { message = "Müşteri bilgileri gereklidir!" });
                }

                if (string.IsNullOrEmpty(order.Customer.UserId))
                {
                    return BadRequest(new { message = "Kullanıcı ID gereklidir!" });
                }

                if (order.Items == null || !order.Items.Any())
                {
                    return BadRequest(new { message = "Sipariş öğeleri gereklidir!" });
                }

                if (order.Addresses == null || order.Addresses.Delivery == null)
                {
                    return BadRequest(new { message = "Teslimat adresi gereklidir!" });
                }

                if (order.Pricing == null)
                {
                    return BadRequest(new { message = "Fiyat bilgileri gereklidir!" });
                }

                if (order.Payment == null)
                {
                    return BadRequest(new { message = "Ödeme bilgileri gereklidir!" });
                }

                // Sipariş öğelerinin kontrolü
                foreach (var item in order.Items)
                {
                    if (string.IsNullOrEmpty(item.ProductId))
                    {
                        return BadRequest(new { message = "Ürün ID gereklidir!" });
                    }

                    if (item.Quantity <= 0)
                    {
                        return BadRequest(new { message = "Ürün miktarı sıfırdan büyük olmalıdır!" });
                    }

                    if (item.UnitPrice <= 0)
                    {
                        return BadRequest(new { message = "Ürün fiyatı sıfırdan büyük olmalıdır!" });
                    }

                    // Calculate total price for item
                    item.TotalPrice = item.Quantity * item.UnitPrice;
                }

                // Fiyat hesaplamalarının kontrolü
                var calculatedSubtotal = order.Items.Sum(i => i.TotalPrice);
                if (Math.Abs(order.Pricing.Subtotal - calculatedSubtotal) > 0.01m)
                {
                    return BadRequest(new { message = "Ara toplam hesaplaması hatalı!" });
                }

                var calculatedTotal = order.Pricing.Subtotal + order.Pricing.Tax + order.Pricing.Shipping - order.Pricing.Discount;
                if (Math.Abs(order.Pricing.Total - calculatedTotal) > 0.01m)
                {
                    return BadRequest(new { message = "Toplam fiyat hesaplaması hatalı!" });
                }

                // Set default values
                if (string.IsNullOrEmpty(order.Pricing.Currency))
                {
                    order.Pricing.Currency = "TRY";
                }

                if (order.Payment.Status == null)
                {
                    order.Payment.Status = "pending";
                }

                if (order.Notes == null)
                {
                    order.Notes = new Notes();
                }

                // Create order
                var createdOrder = await _orderService.CreateOrderAsync(order);

                return Ok(new 
                { 
                    message = "Sipariş başarıyla oluşturuldu!",
                    orderNumber = createdOrder.OrderNumber,
                    orderId = createdOrder.Id,
                    order = createdOrder
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Sipariş oluşturulurken bir hata oluştu!", error = ex.Message });
            }
        }

        [HttpGet]
        public async Task<IActionResult> GetAllOrders()
        {
            try
            {
                var orders = await _orderService.GetAllOrdersAsync();
                return Ok(orders);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Siparişler yüklenirken bir hata oluştu!", error = ex.Message });
            }
        }

        [HttpGet("user/{userId}")]
        public async Task<IActionResult> GetOrdersByUserId(string userId)
        {
            try
            {
                if (string.IsNullOrEmpty(userId))
                {
                    return BadRequest(new { message = "Kullanıcı ID gereklidir!" });
                }

                var orders = await _orderService.GetOrdersByUserIdAsync(userId);
                return Ok(orders);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Kullanıcı siparişleri yüklenirken bir hata oluştu!", error = ex.Message });
            }
        }

        [HttpGet("{orderId}")]
        public async Task<IActionResult> GetOrderById(string orderId)
        {
            try
            {
                if (string.IsNullOrEmpty(orderId))
                {
                    return BadRequest(new { message = "Sipariş ID gereklidir!" });
                }

                var order = await _orderService.GetOrderByIdAsync(orderId);
                
                if (order == null)
                {
                    return NotFound(new { message = "Sipariş bulunamadı!" });
                }

                return Ok(order);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Sipariş yüklenirken bir hata oluştu!", error = ex.Message });
            }
        }

        [HttpGet("number/{orderNumber}")]
        public async Task<IActionResult> GetOrderByOrderNumber(string orderNumber)
        {
            try
            {
                if (string.IsNullOrEmpty(orderNumber))
                {
                    return BadRequest(new { message = "Sipariş numarası gereklidir!" });
                }

                var order = await _orderService.GetOrderByOrderNumberAsync(orderNumber);
                
                if (order == null)
                {
                    return NotFound(new { message = "Sipariş bulunamadı!" });
                }

                return Ok(order);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Sipariş yüklenirken bir hata oluştu!", error = ex.Message });
            }
        }

        [HttpPut("{orderId}/status")]
        public async Task<IActionResult> UpdateOrderStatus(string orderId, [FromBody] UpdateOrderStatusRequest request)
        {
            try
            {
                if (string.IsNullOrEmpty(orderId))
                {
                    return BadRequest(new { message = "Sipariş ID gereklidir!" });
                }

                if (string.IsNullOrEmpty(request.Status))
                {
                    return BadRequest(new { message = "Yeni durum gereklidir!" });
                }

                // Valid status kontrolü
                var validStatuses = new[] { "pending", "confirmed", "processing", "shipped", "delivered", "cancelled" };
                if (!validStatuses.Contains(request.Status.ToLower()))
                {
                    return BadRequest(new { message = "Geçersiz sipariş durumu!" });
                }

                var updated = await _orderService.UpdateOrderStatusAsync(orderId, request.Status, request.Note);
                
                if (!updated)
                {
                    return NotFound(new { message = "Sipariş bulunamadı veya güncellenemedi!" });
                }

                return Ok(new { message = "Sipariş durumu başarıyla güncellendi!" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Sipariş durumu güncellenirken bir hata oluştu!", error = ex.Message });
            }
        }
    }

    public class UpdateOrderStatusRequest
    {
        public string Status { get; set; }
        public string? Note { get; set; }
    }
} 