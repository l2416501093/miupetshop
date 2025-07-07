class Product {
  final String? id;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final double discount; // İndirim oranı (0-100 arası)

  Product({
    this.id,
    required this.name, 
    required this.description,
    required this.imageUrl,
    required this.price,
    this.discount = 0.0, // Varsayılan olarak indirim yok
  });

  // İndirimli fiyatı hesapla
  double get discountedPrice {
    if (discount > 0) {
      return price * (1 - discount / 100);
    }
    return price;
  }

  // İndirim var mı kontrol et
  bool get hasDiscount => discount > 0;

  // API'den gelen JSON'ı Product'a çevir
  factory Product.fromJson(Map<String, dynamic> json) {
    // Farklı field isimlerini dene
    double discountValue = 0.0;
    if (json['discount'] != null) {
      discountValue = (json['discount']).toDouble();
    } else if (json['discountPercentage'] != null) {
      discountValue = (json['discountPercentage']).toDouble();
    } else if (json['DiscountPercentage'] != null) {
      discountValue = (json['DiscountPercentage']).toDouble();
    }
    
    return Product(
      id: json['id']?.toString(), // String'e güvenli çevirme
      name: json['name'] ?? 'İsimsiz Ürün', // Fallback
      description: json['description'] ?? 'Açıklama yok', // Fallback
      imageUrl: json['image'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(), // API'den gelen fiyat
      discount: discountValue, // API'den gelen indirim oranı
    );
  }

  // Product'ı JSON'a çevir (gelecekteki API istekleri için)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': imageUrl,
      'price': price,
      'discount': discount,
    };
  }
} 