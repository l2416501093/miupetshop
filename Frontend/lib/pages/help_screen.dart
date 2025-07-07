import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatefulWidget {
  @override
  _HelpScreenState createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<HelpItem> _helpItems = [
    // Alışveriş Kategorisi
    HelpItem(
      category: 'Alışveriş',
      icon: Icons.shopping_cart,
      title: 'Nasıl sipariş verebilirim?',
      content: '''
1. Beğendiğiniz ürünü seçin
2. "Sepete Ekle" butonuna tıklayın
3. Sepetinizi kontrol edin
4. "Satın Al" butonuna tıklayın
5. Teslimat adresinizi seçin
6. Ödeme bilgilerinizi girin
7. Siparişinizi onaylayın

Sipariş verdikten sonra e-posta ile onay alacaksınız.
      ''',
      tags: ['sipariş', 'satın al', 'sepet'],
    ),
    HelpItem(
      category: 'Alışveriş',
      icon: Icons.favorite,
      title: 'Ürünleri nasıl favorilere eklerim?',
      content: '''
Ürün detay sayfasında kalp ikonuna tıklayarak ürünü favorilerinize ekleyebilirsiniz.

Favorilerinizi görmek için:
1. Profil menüsünü açın
2. "Favorilerim" seçeneğine tıklayın

Not: Favori özelliği yakında eklenecektir.
      ''',
      tags: ['favori', 'beğeni', 'kalp'],
    ),
    HelpItem(
      category: 'Alışveriş',
      icon: Icons.search,
      title: 'Ürün nasıl ararım?',
      content: '''
Ana sayfada arama çubuğunu kullanarak:
1. Ürün adını yazın
2. Kategori filtrelerini kullanın (Köpek, Kedi, Kuş, Balık, Diğer)
3. Arama sonuçlarında istediğiniz ürünü bulun

Arama ipuçları:
• Ürün markasını yazabilirsiniz
• Genel terimler kullanın (mama, oyuncak, tasma)
• Kategorileri filtreleyerek arama yapın
      ''',
      tags: ['arama', 'bul', 'kategori'],
    ),

    // Hesap Kategorisi
    HelpItem(
      category: 'Hesap',
      icon: Icons.person_add,
      title: 'Nasıl hesap oluştururum?',
      content: '''
Yeni hesap oluşturmak için:
1. "Kayıt Ol" butonuna tıklayın
2. Gerekli bilgileri doldurun:
   • Ad Soyad
   • E-posta adresi
   • TC Kimlik No
   • Telefon numarası
   • Adres bilgileri
   • Güvenli bir şifre
3. "Kayıt Ol" butonuna tıklayın
4. E-posta doğrulamasını tamamlayın

Hesabınız oluşturulduktan sonra hemen alışverişe başlayabilirsiniz.
      ''',
      tags: ['kayıt', 'hesap', 'üyelik'],
    ),
    HelpItem(
      category: 'Hesap',
      icon: Icons.lock_reset,
      title: 'Şifremi unuttum, ne yapmalıyım?',
      content: '''
Şifrenizi sıfırlamak için:
1. Giriş ekranında "Şifremi Unuttum" linkine tıklayın
2. E-posta adresinizi girin
3. E-postanıza gelen linke tıklayın
4. Yeni şifrenizi belirleyin
5. Yeni şifrenizle giriş yapın

Güvenlik için:
• Güçlü bir şifre seçin
• Şifrenizi kimseyle paylaşmayın
• Düzenli olarak şifrenizi değiştirin
      ''',
      tags: ['şifre', 'unuttu', 'sıfırla'],
    ),
    HelpItem(
      category: 'Hesap',
      icon: Icons.edit,
      title: 'Profil bilgilerimi nasıl güncellerim?',
      content: '''
Profil bilgilerinizi güncellemek için:
1. Menüden "Profil" seçeneğine tıklayın
2. Güncellemek istediğiniz bilgileri değiştirin
3. "Kaydet" butonuna tıklayın

Güncelleyebileceğiniz bilgiler:
• Ad Soyad
• E-posta adresi
• Telefon numarası
• Adres bilgileri
• Şifre

Not: TC Kimlik No değiştirilemez.
      ''',
      tags: ['profil', 'güncelle', 'bilgi'],
    ),

    // Ödeme Kategorisi
    HelpItem(
      category: 'Ödeme',
      icon: Icons.payment,
      title: 'Hangi ödeme yöntemlerini kabul ediyorsunuz?',
      content: '''
Kabul ettiğimiz ödeme yöntemleri:

Kredi/Banka Kartları:
• Visa
• Mastercard
• American Express
• Troy

Diğer Ödeme Seçenekleri:
• Kapıda Ödeme (Nakit/Kart)
• Havale/EFT
• Dijital cüzdanlar (gelecekte)

Güvenlik:
• Tüm ödemeler SSL ile şifrelenir
• Kart bilgileriniz saklanmaz
• 3D Secure doğrulama kullanılır
      ''',
      tags: ['ödeme', 'kart', 'güvenlik'],
    ),
    HelpItem(
      category: 'Ödeme',
      icon: Icons.receipt,
      title: 'Fatura nasıl alırım?',
      content: '''
Fatura almak için:
1. Sipariş sırasında "Fatura Bilgileri" bölümünü doldurun
2. Şirket adı ve vergi numaranızı girin
3. Fatura adresini belirtin

E-Fatura:
• Sipariş onaylandıktan sonra e-postanıza gönderilir
• PDF formatında indirebilirsiniz
• Yasal geçerliliği vardır

Kağıt Fatura:
• Talep etmeniz durumunda kargo ile gönderilir
• Ek ücret alınmaz
      ''',
      tags: ['fatura', 'e-fatura', 'vergi'],
    ),

    // Kargo Kategorisi
    HelpItem(
      category: 'Kargo',
      icon: Icons.local_shipping,
      title: 'Kargo süresi ne kadar?',
      content: '''
Kargo süreleri:

Standart Kargo:
• İstanbul içi: 1-2 iş günü
• Türkiye geneli: 2-5 iş günü
• Ücretsiz kargo: 200₺ ve üzeri siparişlerde

Hızlı Kargo:
• Aynı gün teslimat (İstanbul'da seçili bölgeler)
• Ertesi gün teslimat (büyük şehirler)

Kargo Takibi:
• Sipariş onaylandıktan sonra takip numarası gönderilir
• SMS ve e-posta ile bilgilendirme yapılır
• Uygulama üzerinden takip edebilirsiniz
      ''',
      tags: ['kargo', 'teslimat', 'süre'],
    ),
    HelpItem(
      category: 'Kargo',
      icon: Icons.home,
      title: 'Evde yokken kargo gelirse ne olur?',
      content: '''
Evde yokken kargo gelirse:

1. Kargo görevlisi 3 kez deneme yapar
2. Komşularınıza teslim edilebilir (izninizle)
3. Kargo şubesinde bekletilir
4. SMS ile bilgilendirilirsiniz

Alternatif Çözümler:
• Kargo adresini değiştirebilirsiniz
• İş yerinize göndertebilirsiniz
• Kargo şubesinden alabilirsiniz
• Uygun saati belirtebilirsiniz

Saklama Süresi: 5 iş günü
      ''',
      tags: ['evde yok', 'komşu', 'şube'],
    ),

    // İade Kategorisi
    HelpItem(
      category: 'İade',
      icon: Icons.keyboard_return,
      title: 'Ürün iadesi nasıl yapılır?',
      content: '''
İade işlemi için:

İade Koşulları:
• 14 gün içinde iade hakkınız vardır
• Ürün orijinal ambalajında olmalı
• Kullanılmamış ve hasarsız olmalı
• Fatura/fişi bulunmalı

İade Süreci:
1. "Siparişlerim" bölümünden iade talebi oluşturun
2. İade nedenini belirtin
3. Kargo ile ürünü gönderin (ücretsiz)
4. İade onaylandıktan sonra para iadesi yapılır

Para İadesi: 5-10 iş günü içinde
      ''',
      tags: ['iade', 'geri gönder', 'para iadesi'],
    ),
    HelpItem(
      category: 'İade',
      icon: Icons.swap_horiz,
      title: 'Ürün değişimi yapabilir miyim?',
      content: '''
Ürün değişimi:

Değişim Koşulları:
• Aynı kategoriden başka ürünle değişim
• Fiyat farkı varsa ödeme/iade yapılır
• 14 gün içinde değişim hakkı
• Ürün hasarsız ve kullanılmamış olmalı

Değişim Süreci:
1. İade talebi oluşturun
2. "Değişim" seçeneğini işaretleyin
3. Yeni ürünü seçin
4. Kargo ile eski ürünü gönderin
5. Yeni ürün size gönderilir

Not: Mama ve hijyen ürünlerinde değişim yapılamaz.
      ''',
      tags: ['değişim', 'değiştir', 'farklı ürün'],
    ),

    // Teknik Kategorisi
    HelpItem(
      category: 'Teknik',
      icon: Icons.bug_report,
      title: 'Uygulama çökerse ne yapmalıyım?',
      content: '''
Uygulama sorunları için:

Hızlı Çözümler:
1. Uygulamayı tamamen kapatıp açın
2. Telefonunuzu yeniden başlatın
3. Uygulama güncellemesi olup olmadığını kontrol edin
4. İnternet bağlantınızı kontrol edin

Kalıcı Çözümler:
• Uygulamayı silip yeniden yükleyin
• Telefon belleğinizi temizleyin
• İşletim sisteminizi güncelleyin

Hala sorun varsa:
• Ayarlar > Geri Bildirim Gönder
• destek@shoppy.com'a yazın
• Canlı destek hattımızı arayın
      ''',
      tags: ['çökme', 'hata', 'sorun'],
    ),
    HelpItem(
      category: 'Teknik',
      icon: Icons.wifi_off,
      title: 'İnternet bağlantısı olmadan kullanabilir miyim?',
      content: '''
Çevrimdışı Kullanım:

Yapabilecekleriniz:
• Daha önce görüntülenen ürünleri inceleyebilirsiniz
• Sepetinizdeki ürünleri görebilirsiniz
• Profil bilgilerinizi görüntüleyebilirsiniz
• Önceki siparişlerinizi inceleyebilirsiniz

Yapamayacaklarınız:
• Yeni ürün araması
• Sipariş verme
• Fiyat güncellemelerini görme
• Yeni hesap oluşturma

Öneriler:
• WiFi bağlantısı kurun
• Mobil veri kullanın
• Daha sonra tekrar deneyin
      ''',
      tags: ['çevrimdışı', 'internet', 'bağlantı'],
    ),

    // İletişim Kategorisi
    HelpItem(
      category: 'İletişim',
      icon: Icons.phone,
      title: 'Müşteri hizmetleri ile nasıl iletişime geçerim?',
      content: '''
İletişim Kanalları:

Telefon:
• 0850 123 45 67 (Hafta içi 09:00-18:00)
• Ücretsiz arama
• Ortalama bekleme süresi: 2 dakika

E-posta:
• destek@shoppy.com
• 24 saat içinde yanıt
• Dosya eki gönderebilirsiniz

Canlı Destek:
• Uygulama içi chat
• Hafta içi 09:00-22:00
• Anında yanıt

Sosyal Medya:
• @ShoppyTR (Twitter)
• facebook.com/ShoppyTR
• instagram.com/shoppy_tr
      ''',
      tags: ['iletişim', 'destek', 'telefon'],
    ),
  ];

  List<HelpItem> get filteredItems {
    if (_searchQuery.isEmpty) {
      return _helpItems;
    }
    return _helpItems.where((item) {
      return item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();
  }

  Map<String, List<HelpItem>> get groupedItems {
    final Map<String, List<HelpItem>> grouped = {};
    for (final item in filteredItems) {
      if (!grouped.containsKey(item.category)) {
        grouped[item.category] = [];
      }
      grouped[item.category]!.add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade400,
              Colors.deepPurple.shade100,
              Colors.white,
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        'Yardım Merkezi',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48),
                  ],
                ),
              ),

              // Search Bar
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Yardım konularında ara...',
                    prefixIcon: Icon(Icons.search, color: Colors.deepPurple),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Quick Actions
              if (_searchQuery.isEmpty) ...[
                Container(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildQuickAction(
                        icon: Icons.phone,
                        title: 'Bizi Arayın',
                        subtitle: '0850 123 45 67',
                        onTap: () => _makePhoneCall('08501234567'),
                      ),
                      _buildQuickAction(
                        icon: Icons.email,
                        title: 'E-posta',
                        subtitle: 'destek@shoppy.com',
                        onTap: () => _sendEmail('destek@shoppy.com'),
                      ),
                      _buildQuickAction(
                        icon: Icons.chat,
                        title: 'Canlı Destek',
                        subtitle: 'Hemen başlat',
                        onTap: () => _startLiveChat(),
                      ),
                      _buildQuickAction(
                        icon: Icons.feedback,
                        title: 'Geri Bildirim',
                        subtitle: 'Önerinizi iletin',
                        onTap: () => _showFeedbackDialog(),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],

              // Help Content
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  itemCount: groupedItems.keys.length,
                  itemBuilder: (context, index) {
                    final category = groupedItems.keys.elementAt(index);
                    final items = groupedItems[category]!;
                    
                    return _buildCategorySection(category, items);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 140,
      margin: EdgeInsets.only(right: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 3,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.deepPurple,
                    size: 20,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(String category, List<HelpItem> items) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(
                  _getCategoryIcon(category),
                  color: Colors.deepPurple,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ),
          // Category Items
          ...items.map((item) => _buildHelpItem(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildHelpItem(HelpItem item) {
    return ExpansionTile(
      leading: Icon(
        item.icon,
        color: Colors.deepPurple,
        size: 24,
      ),
      title: Text(
        item.title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            item.content.trim(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Alışveriş':
        return Icons.shopping_cart;
      case 'Hesap':
        return Icons.account_circle;
      case 'Ödeme':
        return Icons.payment;
      case 'Kargo':
        return Icons.local_shipping;
      case 'İade':
        return Icons.keyboard_return;
      case 'Teknik':
        return Icons.settings;
      case 'İletişim':
        return Icons.contact_support;
      default:
        return Icons.help;
    }
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Telefon araması yapılamadı: $phoneNumber'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _sendEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Shoppy Destek Talebi',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('E-posta gönderilemedi: $email'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startLiveChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Canlı destek yakında aktif olacak'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showFeedbackDialog() {
    final TextEditingController feedbackController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Geri Bildirim'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Deneyiminizi bizimle paylaşın:'),
            SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Geri bildiriminizi yazın...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Geri bildiriminiz gönderildi. Teşekkürler!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Gönder'),
          ),
        ],
      ),
    );
  }
}

class HelpItem {
  final String category;
  final IconData icon;
  final String title;
  final String content;
  final List<String> tags;

  HelpItem({
    required this.category,
    required this.icon,
    required this.title,
    required this.content,
    required this.tags,
  });
} 