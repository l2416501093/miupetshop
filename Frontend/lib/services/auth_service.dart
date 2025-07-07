import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';

  // Login API çağrısı
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final loginData = {
        'Username': username, // API'de büyük U ile Username bekleniyor
        'Password': password, // API'de büyük P ile Password bekleniyor
      };

      final response = await http.post(
        Uri.parse(ApiConfig.loginEndpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(loginData),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('🔥 Login API Response: $responseData');
        
        // Kullanıcı bilgilerini kaydet
        if (responseData['user'] != null) {
          print('👤 User data from API: ${responseData['user']}');
          print('📍 Address from API (büyük A): ${responseData['user']['Address']}');
          print('📍 Address from API (küçük a): ${responseData['user']['address']}');
          
          // API'den gelen veriyi normalize et (case sensitivity sorunu için)
          final normalizedUserData = {
            'Username': responseData['user']['username'] ?? responseData['user']['Username'],
            'Id': responseData['user']['id'] ?? responseData['user']['Id'],
            'Email': responseData['user']['email'] ?? responseData['user']['Email'],
            'Address': responseData['user']['address'] ?? responseData['user']['Address'], // küçük a'dan al
            'Tcno': responseData['user']['tcno'] ?? responseData['user']['Tcno'],
            'IsAdmin': responseData['user']['isAdmin'] ?? responseData['user']['IsAdmin'] ?? false, // Admin yetkisi
          };
          
          print('🔧 Normalized user data: $normalizedUserData');
          await _saveUserData(normalizedUserData);
          // Login session'ı için basit bir token oluştur
          await _saveToken('logged_in_${normalizedUserData['Id']}_${DateTime.now().millisecondsSinceEpoch}');
        }

        return {
          'success': true,
          'data': responseData,
          'message': responseData['message'] ?? 'Giriş başarılı!'
        };
      } else if (response.statusCode == 400) {
        // Bad Request - Username/password boş
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Kullanıcı adı ve şifre gerekli!',
          'statusCode': response.statusCode
        };
      } else if (response.statusCode == 401) {
        // Unauthorized - Hatalı kullanıcı adı/şifre
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Geçersiz kullanıcı adı veya şifre!',
          'statusCode': response.statusCode
        };
      } else {
        // Diğer hatalar
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Beklenmeyen bir hata oluştu!',
            'statusCode': response.statusCode
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Sunucu hatası! Status Code: ${response.statusCode}',
            'statusCode': response.statusCode
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bağlantı hatası: ${e.toString()}',
        'error': e.toString()
      };
    }
  }

  // Token kaydetme
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Kullanıcı verisi kaydetme
  static Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, jsonEncode(userData));
  }

  // Manuel kullanıcı verisi kaydetme (public method)
  static Future<void> saveManualUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, jsonEncode(userData));
  }

  // Token alma
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Kullanıcı verisi alma
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return null;
  }

  // Login durumu kontrolü
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userDataKey);
  }

  // Authorization header için token
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    if (token != null) {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    }
    return {
      'Content-Type': 'application/json',
    };
  }

  // Kullanıcı detaylarını API'den al (Address dahil)
  static Future<Map<String, dynamic>?> fetchUserDetails(String userId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getUserDetailEndpoint(userId)),
        headers: await getAuthHeaders(),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        
        // Güncel kullanıcı verisini kaydet
        await _saveUserData(userData);
        
        return userData;
      } else {
        print('❌ Kullanıcı detayları alınamadı: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('🚨 Kullanıcı detayları alma hatası: $e');
      return null;
    }
  }

  // Gelişmiş kullanıcı verisi alma (Address dahil)
  static Future<Map<String, dynamic>?> getUserDataWithDetails() async {
    try {
      // Önce local'dan kullanıcı verisini al
      final localUserData = await getUserData();
      if (localUserData != null && localUserData['Id'] != null) {
        // API'den güncel detayları çek
        final apiUserData = await fetchUserDetails(localUserData['Id'].toString());
        if (apiUserData != null) {
          return apiUserData;
        }
      }
      
      // API başarısız olursa local veriyi döndür
      return localUserData;
    } catch (e) {
      print('🚨 Gelişmiş kullanıcı verisi alma hatası: $e');
      return await getUserData();
    }
  }

  // Admin kontrolü
  static Future<bool> isAdmin() async {
    try {
      final userData = await getUserData();
      return userData?['IsAdmin'] == true;
    } catch (e) {
      print('🚨 Admin kontrolü hatası: $e');
      return false;
    }
  }

  // Kullanıcı adı alma
  static Future<String> getUsername() async {
    try {
      final userData = await getUserData();
      return userData?['Username'] ?? 'Kullanıcı';
    } catch (e) {
      print('🚨 Kullanıcı adı alma hatası: $e');
      return 'Kullanıcı';
    }
  }

  // Admin yetkisi gerektiren işlemler için kontrol
  static Future<bool> checkAdminPermission() async {
    final isAdminUser = await isAdmin();
    if (!isAdminUser) {
      print('⚠️ Admin yetkisi gerekli!');
    }
    return isAdminUser;
  }
} 