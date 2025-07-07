import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import '../widgets/custom_app_bar.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../config/api_config.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  TextEditingController _searchController = TextEditingController();
  String _username = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // API'den yüklenecek ürünler
  List<Product> allProducts = [];
  bool _isLoadingProducts = true;
  String? _productsError;
  List<Product> filteredProducts = [];
  
  // UI State
  bool _isGridView = true;
  String _selectedCategory = 'Tümü';
  final List<String> _categories = ['Tümü', 'Köpek', 'Kedi', 'Kuş', 'Balık', 'Diğer'];
  
  // Admin kontrolü
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _loadUsernameFromHive();
    _loadUsername();
    _loadProducts();
    _checkAdminStatus();
    _animationController.forward();
  }

  // Sayfa geri döndüğünde sepet badge'ini güncellemek için
  void _refreshCartBadge() {
    setState(() {
      // Sadece UI'ı yenile
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // API'den ürünleri yükle
  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
      _productsError = null;
    });

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.productsEndpoint),
        headers: await AuthService.getAuthHeaders(),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> productsJson = jsonDecode(response.body);
        
        final products = productsJson.map((json) {
          return Product.fromJson(json);
        }).toList();
        
        setState(() {
          allProducts = products;
          filteredProducts = List.from(allProducts);
          _isLoadingProducts = false;
        });
        
        print('API\'den ${products.length} ürün yüklendi');
      } else {
        setState(() {
          _productsError = 'Ürünler yüklenemedi (${response.statusCode})';
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      setState(() {
        _productsError = 'Bağlantı hatası: ${e.toString()}';
        _isLoadingProducts = false;
      });
    }
  }

  // Default olarak Hive'dan kullanıcı adı yükle
  Future<void> _loadUsernameFromHive() async {
    try {
      final usersBox = Hive.box<UserModel>('users');
      if (usersBox.isNotEmpty) {
        final lastUser = usersBox.values.last;
        setState(() {
          _username = lastUser.fullName;
        });
      } else {
        setState(() {
          _username = 'Kullanıcı';
        });
      }
    } catch (e) {
      setState(() {
        _username = 'Kullanıcı';
      });
    }
  }

  // AuthService'den kullanıcı adını güncelle
  Future<void> _loadUsername() async {
    final userData = await AuthService.getUserData();
    if (userData != null && userData['Username'] != null) {
      setState(() {
        _username = userData['Username'];
      });
    }
  }

  // Admin durumunu kontrol et
  Future<void> _checkAdminStatus() async {
    final isAdmin = await AuthService.isAdmin();
    setState(() {
      _isAdmin = isAdmin;
    });
    print('🔑 Admin durumu: $_isAdmin');
  }

  void _searchProducts() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      filteredProducts = allProducts.where((product) {
        final matchesSearch = query.isEmpty || 
            product.name.toLowerCase().contains(query) ||
            product.description.toLowerCase().contains(query);
        
        final matchesCategory = _selectedCategory == 'Tümü' ||
            _doesProductMatchCategory(product, _selectedCategory);
            
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  // Daha akıllı kategori eşleştirme
  bool _doesProductMatchCategory(Product product, String category) {
    final productName = product.name.toLowerCase();
    final productDesc = product.description.toLowerCase();
    
    switch (category.toLowerCase()) {
      case 'köpek':
        return productName.contains('köpek') || 
               productName.contains('dog') ||
               productDesc.contains('köpek') ||
               productDesc.contains('dog');
               
      case 'kedi':
        return (productName.contains('kedi') || 
                productName.contains('cat')) &&
               !productName.contains('köpek') && // Köpek değil
               !productName.contains('dog');
               
      case 'kuş':
        return productName.contains('kuş') || 
               productName.contains('bird') ||
               productName.contains('muhabbet') ||
               productName.contains('kanarya');
               
      case 'balık':
        return (productName.contains('balık') || 
                productName.contains('fish') ||
                productName.contains('akvaryum')) &&
               !productName.contains('kedi') && // Kedi maması değil
               !productName.contains('köpek') && // Köpek maması değil
               !productDesc.contains('kedi maması') &&
               !productDesc.contains('köpek maması');
               
      case 'diğer':
        return !_doesProductMatchCategory(product, 'köpek') &&
               !_doesProductMatchCategory(product, 'kedi') &&
               !_doesProductMatchCategory(product, 'kuş') &&
               !_doesProductMatchCategory(product, 'balık');
               
      default:
        return false;
    }
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _searchProducts();
  }

  // Modern arama barı
  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Ürün ara...',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(Icons.search, color: Colors.deepPurple),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _searchProducts();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        onChanged: (value) {
          _searchProducts();
        },
      ),
    );
  }

  // Kategori seçici
  Widget _buildCategorySelector() {
    return Container(
      height: 50,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          
          return GestureDetector(
            onTap: () => _filterByCategory(category),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              margin: EdgeInsets.only(right: 12),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.deepPurple : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ] : [],
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Header bölümü
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.deepPurple, Colors.deepPurple.shade300],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tek satır - Hoşgeldin mesajı ve aksiyon butonları
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Sol taraf - Drawer butonu ve hoşgeldin mesajı
              Row(
                children: [
                  Builder(
                    builder: (BuildContext context) {
                      return IconButton(
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                        icon: Icon(Icons.menu, color: Colors.white, size: 24),
                        tooltip: 'Menü',
                        padding: EdgeInsets.all(8),
                        constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                      );
                    },
                  ),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Merhaba,',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _username.isNotEmpty ? _username : 'Kullanıcı',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Sağ taraf - Aksiyon butonları
              Row(
                children: [
                  // Admin ürün ekleme butonu (sadece admin kullanıcılar için)
                  if (_isAdmin) ...[
                    IconButton(
                      onPressed: () async {
                        final result = await Navigator.pushNamed(context, '/add_product');
                        if (result == true) {
                          await _loadProducts();
                        }
                      },
                      icon: Icon(Icons.add_circle_outline, color: Colors.white, size: 22),
                      tooltip: 'Ürün Ekle',
                      padding: EdgeInsets.all(8),
                      constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                  ],
                  // Sepet butonu
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CartScreen(),
                            ),
                          );
                          _refreshCartBadge();
                        },
                        icon: Icon(Icons.shopping_cart, color: Colors.white, size: 22),
                        padding: EdgeInsets.all(8),
                        constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
                      // Sepet badge (ürün sayısı)
                      if (MyApp.cart.isNotEmpty)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            constraints: BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${MyApp.cart.length}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isGridView = !_isGridView;
                      });
                    },
                    icon: Icon(
                      _isGridView ? Icons.view_list : Icons.grid_view,
                      color: Colors.white,
                      size: 22,
                    ),
                    padding: EdgeInsets.all(8),
                    constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                  IconButton(
                    onPressed: _loadProducts,
                    icon: Icon(Icons.refresh, color: Colors.white, size: 22),
                    padding: EdgeInsets.all(8),
                    constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ],
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // Açıklama metni
          Text(
            'Evcil dostlarınız için en iyi ürünleri keşfedin',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Grid view için ürün kartı
     Widget _buildProductGridCard(Product product) {
     return GestureDetector(
       onTap: () async {
         final result = await Navigator.push(
           context,
           MaterialPageRoute(
             builder: (context) => ProductDetailScreen(product: product),
           ),
         );
         // Ürün detay sayfasından döndükten sonra sepet badge'ini güncelle ve eğer ürün güncellendiyse listeyi yenile
         _refreshCartBadge();
         if (result == true) {
           await _loadProducts();
         }
       },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  color: Colors.grey.shade100,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.pets, size: 40, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Görsel Yok', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.deepPurple,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(8), // Padding'i azalt
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Column'un minimum boyut almasını sağla
                  children: [
                    // Ürün adı
                    Text(
                      product.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13, // Font boyutunu küçült
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    
                    // Fiyat gösterimi (indirimli/normal)
                    if (product.hasDiscount) ...[
                      // İndirimli fiyat ve orijinal fiyat aynı satırda
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // İndirimli fiyat
                          Flexible(
                            child: Text(
                              '₺${product.discountedPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Orijinal fiyat (üstü çizili)
                          Text(
                            '₺${product.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 10,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      // İndirim yüzdesi - daha küçük
                      if (product.discount > 0)
                        Container(
                          margin: EdgeInsets.only(top: 2),
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '%${product.discount.toInt()}',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ] else ...[
                      // Normal fiyat
                      Text(
                        '₺${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    
                    SizedBox(height: 2), // Spacing'i azalt
                    
                    // Açıklama - Flexible kullan
                    Flexible(
                      child: Text(
                        product.description.isNotEmpty 
                            ? product.description 
                            : 'Açıklama yok',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11, // Font boyutunu küçült
                        ),
                        maxLines: 2, // Max line sayısını artır
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // List view için ürün kartı
     Widget _buildProductListCard(Product product) {
     return GestureDetector(
       onTap: () async {
         final result = await Navigator.push(
           context,
           MaterialPageRoute(
             builder: (context) => ProductDetailScreen(product: product),
           ),
         );
         // Ürün detay sayfasından döndükten sonra sepet badge'ini güncelle ve eğer ürün güncellendiyse listeyi yenile
         _refreshCartBadge();
         if (result == true) {
           await _loadProducts();
         }
       },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  product.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade200,
                      child: Icon(Icons.pets, color: Colors.grey, size: 30),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade200,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.deepPurple,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                                         Text(
                       product.name,
                       style: TextStyle(
                         fontWeight: FontWeight.bold,
                         fontSize: 16,
                       ),
                       maxLines: 2,
                       overflow: TextOverflow.ellipsis,
                     ),
                     SizedBox(height: 4),
                     // Fiyat gösterimi (indirimli/normal)
                     if (product.hasDiscount) ...[
                       Row(
                         children: [
                           // İndirimli fiyat
                           Text(
                             '₺${product.discountedPrice.toStringAsFixed(2)}',
                             style: TextStyle(
                               color: Colors.red.shade600,
                               fontSize: 16,
                               fontWeight: FontWeight.bold,
                             ),
                           ),
                           SizedBox(width: 8),
                           // Orijinal fiyat (üstü çizili)
                           Text(
                             '₺${product.price.toStringAsFixed(2)}',
                             style: TextStyle(
                               color: Colors.grey.shade500,
                               fontSize: 13,
                               decoration: TextDecoration.lineThrough,
                               decorationColor: Colors.grey.shade500,
                             ),
                           ),
                           SizedBox(width: 8),
                           // İndirim yüzdesi - aynı satırda
                           Container(
                             padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                             decoration: BoxDecoration(
                               color: Colors.red.shade600,
                               borderRadius: BorderRadius.circular(6),
                             ),
                             child: Text(
                               '%${product.discount.toInt()}',
                               style: TextStyle(
                                 color: Colors.white,
                                 fontSize: 10,
                                 fontWeight: FontWeight.bold,
                               ),
                             ),
                           ),
                         ],
                       ),
                     ] else ...[
                       // Normal fiyat
                       Text(
                         '₺${product.price.toStringAsFixed(2)}',
                         style: TextStyle(
                           color: Colors.deepPurple,
                           fontSize: 16,
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                     ],
                     SizedBox(height: 8),
                     Text(
                       product.description.isNotEmpty 
                           ? product.description 
                           : 'Açıklama yok',
                       style: TextStyle(
                         color: Colors.grey.shade600,
                         fontSize: 14,
                       ),
                       maxLines: 1,
                       overflow: TextOverflow.ellipsis,
                     ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Ürün listesini oluştur
  Widget _buildProductsList() {
    if (_isLoadingProducts) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.deepPurple),
            SizedBox(height: 16),
            Text('Ürünler yükleniyor...', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    if (_productsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              _productsError!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.red),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProducts,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Ürün bulunamadı',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            if (allProducts.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                'Arama kriterlerinizi değiştirip tekrar deneyin',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ],
        ),
      );
    }

    if (_isGridView) {
      return RefreshIndicator(
        onRefresh: _loadProducts,
        child: GridView.builder(
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
                              childAspectRatio: 0.65, // Daha uzun kartlar - overflow'u önlemek için
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            return _buildProductGridCard(filteredProducts[index]);
          },
        ),
      );
    } else {
      return RefreshIndicator(
        onRefresh: _loadProducts,
        child: ListView.builder(
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            return _buildProductListCard(filteredProducts[index]);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      drawer: _buildDrawer(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildCategorySelector(),
            Expanded(
              child: _buildProductsList(),
            ),
          ],
        ),
      ),
    );
  }

  // Drawer menü oluştur
  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade700,
              Colors.deepPurple.shade500,
              Colors.deepPurple.shade300,
            ],
            stops: [0.0, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Drawer Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.deepPurple,
                      ),
                    ),
                    SizedBox(height: 16),
                    // Username
                    Text(
                      _username.isNotEmpty ? _username : 'Kullanıcı',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    // Admin Badge
                    if (_isAdmin)
                      Container(
                        margin: EdgeInsets.only(top: 8),
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Admin',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Menu Items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildDrawerItem(
                      icon: Icons.home,
                      title: 'Ana Sayfa',
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),

                    _buildDrawerItem(
                      icon: Icons.person,
                      title: 'Profil',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/profile');
                      },
                    ),

                    _buildDrawerItem(
                      icon: Icons.shopping_cart,
                      title: 'Sepetim',
                      trailing: MyApp.cart.isNotEmpty
                          ? Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Text(
                                MyApp.cart.length.toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/cart').then((_) => _refreshCartBadge());
                      },
                    ),

                    if (_isAdmin) ...[
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        height: 1,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Text(
                          'Admin Paneli',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      _buildDrawerItem(
                        icon: Icons.add_box,
                        title: 'Ürün Ekle',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/add_product').then((_) => _loadProducts());
                        },
                      ),
                    ],

                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      height: 1,
                      color: Colors.white.withOpacity(0.3),
                    ),

                    _buildDrawerItem(
                      icon: Icons.settings,
                      title: 'Ayarlar',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/settings');
                      },
                    ),

                    _buildDrawerItem(
                      icon: Icons.help,
                      title: 'Yardım',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/help');
                      },
                    ),

                    SizedBox(height: 20),

                    _buildLogoutItem(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Özel logout item
  Widget _buildLogoutItem() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.red.withOpacity(0.1),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.red.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.logout,
            color: Colors.white,
            size: 22,
          ),
        ),
        title: Text(
          'Çıkış Yap',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () async {
          Navigator.pop(context);
          
          final shouldLogout = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Çıkış Yap'),
              content: Text('Hesabınızdan çıkmak istediğinizden emin misiniz?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Çıkış Yap'),
                ),
              ],
            ),
          );

          if (shouldLogout == true) {
            await AuthService.logout();
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            }
          }
        },
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        hoverColor: Colors.red.withOpacity(0.1),
        splashColor: Colors.red.withOpacity(0.2),
      ),
    );
  }

  // Drawer item builder
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
    Color? textColor,
    Color? iconColor,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: iconColor ?? textColor ?? Colors.white,
            size: 22,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        trailing: trailing,
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        hoverColor: Colors.white.withOpacity(0.1),
        splashColor: Colors.white.withOpacity(0.2),
      ),
    );
  }
}
