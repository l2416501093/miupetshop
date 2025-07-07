import 'package:flutter/material.dart';
import '../main.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final String deliveryAddress;
  final String billingAddress;
  final String orderNumber;
  final double totalAmount;

  const OrderConfirmationScreen({
    Key? key,
    required this.deliveryAddress,
    required this.billingAddress,
    this.orderNumber = '',
    this.totalAmount = 0.0,
  }) : super(key: key);

  @override
  _OrderConfirmationScreenState createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Sipariş numarası - backend'den gelen değer yoksa bir kez generate edilir
  late String _displayOrderNumber;

  @override
  void initState() {
    super.initState();
    
    // Sipariş numarasını ayarla - backend'den gelen değer varsa onu kullan, yoksa sabit bir değer generate et
    _displayOrderNumber = widget.orderNumber.isNotEmpty 
        ? widget.orderNumber 
        : 'SP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    // Start animations
    _fadeController.forward();
    _scaleController.forward();
    
    // Sipariş tamamlandı, sepeti temizle (sadece sipariş numarası varsa, yani API başarılıysa)
    if (widget.orderNumber.isNotEmpty) {
      _clearCart();
    }
  }

  void _clearCart() {
    // Import etmek için main.dart'dan MyApp.cart'a erişim
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Sepeti temizle
      MyApp.cart.clear();
      print('🛒 Sepet temizlendi - Sipariş tamamlandı');
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.deepPurple, Colors.deepPurple.shade300],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/home')),
              icon: Icon(Icons.home, color: Colors.white),
            ),
            Expanded(
              child: Text(
                'Sipariş Onayı',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                '3/3',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 80,
        ),
      ),
    );
  }

  Widget _buildOrderDetails() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text(
                'Sipariş Detayları',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.deepPurple.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.confirmation_number, color: Colors.deepPurple),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sipariş Numarası',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        _displayOrderNumber,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Toplam tutar bilgisi (eğer API'den geliyorsa)
          if (widget.totalAmount > 0) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.monetization_on, color: Colors.green.shade700),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Toplam Tutar',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '₺${widget.totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressInfo() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text(
                'Adres Bilgileri',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Teslimat Adresi
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_shipping, color: Colors.blue.shade700, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Teslimat Adresi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  widget.deliveryAddress,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 12),
          
          // Fatura Adresi
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt, color: Colors.orange.shade700, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Fatura Adresi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  widget.billingAddress,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text(
                'Ödeme Bilgisi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.amber.shade700),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Havale işleminden sonra siparişiniz hazırlanmaya başlanacaktır.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeButton() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.deepPurple.shade300],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.3),
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/home')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              'Ana Sayfaya Dön',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade800,
              Colors.deepPurple.shade600,
              Colors.deepPurple.shade400,
              Colors.purple.shade300,
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 40),
                      
                      // Success Icon
                      _buildSuccessIcon(),
                      
                      SizedBox(height: 24),
                      
                      // Success Message
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Siparişiniz Başarıyla Alındı!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      SizedBox(height: 32),
                      
                      // Order Details
                      _buildOrderDetails(),
                      
                      // Address Info
                      _buildAddressInfo(),
                      
                      // Payment Info
                      _buildPaymentInfo(),
                      
                      SizedBox(height: 100), // Bottom button için yer
                    ],
                  ),
                ),
              ),
              
              // Home Button
              _buildHomeButton(),
            ],
          ),
        ),
      ),
    );
  }
}
