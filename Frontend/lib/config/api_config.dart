class ApiConfig {
  // Development URL (IP adres)
  static const String _developmentIPUrl = 'http://192.168.1.17:8080';

  // Production URL
  static const String _productionBaseUrl = 'https://miupetshop-grach4b0eeb3drbq.canadacentral-01.azurewebsites.net';
  
  // Development modunu kontrol eden boolean
  static const bool _isProduction = false; // true yaparak production'a geçebilirsiniz
  
  // Base URL getter - Sade boolean kontrolü
  static String get baseUrl {
    return _isProduction ? _productionBaseUrl : _developmentIPUrl;
  }
  
  // Manuel URL override (test amaçlı)
  static String? _manualBaseUrl;
  static void setManualBaseUrl(String? url) {
    _manualBaseUrl = url;
  }
  
  static String get effectiveBaseUrl => _manualBaseUrl ?? baseUrl;
  
  // API endpoints
  static String get usersEndpoint => '${effectiveBaseUrl}/api/Users';
  static String get productsEndpoint => '${effectiveBaseUrl}/api/Products';
  static String get ordersEndpoint => '${effectiveBaseUrl}/api/Orders';
  
  // Auth endpoints
  static String get loginEndpoint => '${effectiveBaseUrl}/api/Users/login';
  static String get registerEndpoint => '${effectiveBaseUrl}/api/Users/createuser'; // Swagger'dan alınan register endpoint
  static String get authEndpoint => '${effectiveBaseUrl}/api/Auth';
  
  // User detail endpoint (kullanıcı ID'si ile detay almak için)
  static String getUserDetailEndpoint(String userId) => '${effectiveBaseUrl}/api/Users/$userId';
  
  // API versiyonu
  static const String apiVersion = 'v1';
  
  // Timeout ayarları
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);
} 