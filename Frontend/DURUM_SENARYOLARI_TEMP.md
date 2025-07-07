# SHOPPY E-TİCARET UYGULAMASI
## DURUM SENARYOLARI DOKÜMANI

**Proje Adı:** Shoppy - Evcil Hayvan Ürünleri E-Ticaret Uygulaması  
**Platform:** Flutter (Android/iOS)  
**Versiyon:** 1.0.0  
**Tarih:** Aralık 2024  
**Hazırlayan:** Sistem Analisti  

---

## İÇİNDEKİLER

1. [Genel Bilgiler](#genel-bilgiler)
2. [Kimlik Doğrulama Senaryoları](#kimlik-doğrulama-senaryoları)
3. [Ürün Yönetimi Senaryoları](#ürün-yönetimi-senaryoları)
4. [Alışveriş Senaryoları](#alışveriş-senaryoları)
5. [Admin Paneli Senaryoları](#admin-paneli-senaryoları)
6. [Ayarlar ve Konfigürasyon Senaryoları](#ayarlar-ve-konfigürasyon-senaryoları)
7. [Hata Yönetimi Senaryoları](#hata-yönetimi-senaryoları)

---

## GENEL BİLGİLER

### Uygulama Mimarisi
- **Frontend:** Flutter Framework
- **Backend API:** RESTful Web Service
- **Yerel Veri:** Hive NoSQL Database
- **Durum Yönetimi:** StatefulWidget + SharedPreferences
- **API Endpoint:** http://192.168.1.17:8080

### Desteklenen Özellikler
- ✅ Kullanıcı Girişi/Kaydı
- ✅ Ürün Listeleme ve Arama
- ✅ İndirim Sistemi
- ✅ Sepet Yönetimi
- ✅ Sipariş Oluşturma
- ✅ Admin Paneli
- ✅ Çevrimdışı Çalışma
- ✅ Ayarlar Yönetimi

---

## KİMLİK DOĞRULAMA SENARYOLARI

### US-001: Kullanıcı Girişi
**Amaç:** Kayıtlı kullanıcının sisteme güvenli giriş yapması

**Ön Koşullar:**
- Uygulama yüklü ve çalışır durumda
- İnternet bağlantısı mevcut (API için)
- Geçerli kullanıcı hesabı var

**Ana Akış:**
1. Kullanıcı uygulamayı açar
2. Splash ekranı 2.5 saniye gösterilir
3. Giriş ekranı açılır
4. Kullanıcı, kullanıcı adını girer (varsayılan: "sezgin")
5. Kullanıcı, şifresini girer (varsayılan: "1")
6. "Giriş Yap" butonuna basar
7. Sistem API'ye giriş isteği gönderir
8. API başarılı yanıt döner
9. Kullanıcı verileri SharedPreferences'a kaydedilir
10. Ana sayfa açılır

**Alternatif Akış 1 - Çevrimdışı Giriş:**
- 7a. API erişilemez durumda
- 7b. Sistem Hive veritabanından kontrol eder
- 7c. Eşleşen kullanıcı bulunursa giriş başarılı

**Alternatif Akış 2 - Otomatik Giriş:**
- 3a. Ayarlarda "Otomatik Giriş" aktif
- 3b. Önceki oturum bilgileri mevcut
- 3c. Direkt ana sayfaya yönlendirilir

**Sonuç:**
- Başarılı: Ana sayfa açılır, kullanıcı bilgileri yüklenir
- Başarısız: Hata mesajı gösterilir, giriş ekranında kalır

---

### US-002: Kullanıcı Kaydı
**Amaç:** Yeni kullanıcının sisteme kayıt olması

**Ön Koşullar:**
- İnternet bağlantısı mevcut
- API servisi erişilebilir

**Ana Akış:**
1. Giriş ekranında "Kayıt Ol" butonuna basar
2. Kayıt formu açılır
3. Zorunlu alanları doldurur:
   - Ad Soyad (2-50 karakter)
   - E-posta (geçerli format)
   - TC Kimlik No (11 haneli)
   - Telefon (11 haneli)
   - Adres (detaylı)
   - Şifre (min 6 karakter)
   - Şifre tekrarı
4. Form doğrulaması yapılır
5. "Kayıt Ol" butonuna basar
6. API'ye kayıt isteği gönderilir
7. Başarılı kayıt sonrası otomatik giriş yapılır

**Validasyon Kuralları:**
- E-posta: regex kontrolü
- TC Kimlik: 11 haneli sayısal
- Telefon: 11 haneli format
- Şifre: minimum 6 karakter
- Şifre tekrarı: eşleşme kontrolü

**Sonuç:**
- Başarılı: Otomatik giriş, ana sayfa açılır
- Başarısız: Hata mesajı, formda kalır

---

## ÜRÜN YÖNETİMİ SENARYOLARI

### US-003: Ürün Listeleme ve Arama
**Amaç:** Kullanıcının ürünleri görüntülemesi ve arama yapması

**Ön Koşullar:**
- Kullanıcı giriş yapmış
- Ana sayfa açık

**Ana Akış:**
1. Ana sayfa yüklenir
2. API'den ürün listesi çekilir
3. Ürünler grid görünümde listelenir
4. Kullanıcı arama çubuğuna terim girer
5. Anlık filtreleme yapılır
6. Sonuçlar güncellenir

**Filtreleme Seçenekleri:**
- **Kategori:** Tümü, Köpek, Kedi, Kuş, Balık, Diğer
- **Görünüm:** Grid (varsayılan) / Liste
- **Arama:** Ad, açıklama, marka

**Kategori Eşleştirme Mantığı:**
- Köpek: "köpek", "dog" içeren ürünler
- Kedi: "kedi", "cat" içeren (köpek hariç)
- Kuş: "kuş", "bird", "muhabbet", "kanarya"
- Balık: "balık", "fish", "akvaryum" (mama hariç)
- Diğer: Yukarıdaki kategorilere uymayan

**Çevrimdışı Mod:**
- İnternet yoksa Hive'dan önceki veriler gösterilir
- "Çevrimdışı" bildirimi gösterilir
- Yenileme mümkün değil

**Sonuç:**
- Ürünler listelenir veya "Ürün bulunamadı" mesajı
- Loading/error durumları yönetilir

---

### US-004: Ürün Detay Görüntüleme
**Amaç:** Seçilen ürünün detaylı bilgilerinin görüntülenmesi

**Ön Koşullar:**
- Ürün listesi yüklü
- Kullanıcı bir ürün seçmiş

**Ana Akış:**
1. Ürün kartına tıklanır
2. Ürün detay sayfası açılır
3. Ürün bilgileri gösterilir:
   - Ürün resmi (büyük boyut)
   - Ürün adı ve açıklaması
   - Fiyat bilgisi
   - İndirim varsa indirimli fiyat
   - Ürün özellikleri listesi
4. "Sepete Ekle" butonu görüntülenir

**İndirim Gösterimi:**
- İndirim varsa: Orijinal fiyat üzeri çizili
- İndirimli fiyat kırmızı renkte vurgulanır
- İndirim yüzdesi etiketle gösterilir

**Admin Özellikleri:**
- Admin kullanıcılar için "Düzenle" butonu görünür
- Düzenleme sayfasına yönlendirme

**Sonuç:**
- Detay bilgileri tam olarak gösterilir
- Sepete ekleme işlemi hazır

---

### US-005: İndirim Sistemi
**Amaç:** Ürünlerde indirim oranlarının doğru hesaplanması ve gösterilmesi

**Ön Koşullar:**
- Ürünlerde indirim bilgisi mevcut
- API'den indirim verileri alınıyor

**Ana Akış:**
1. API'den ürün verisi çekilir
2. İndirim alanı kontrol edilir (discount/discountPercentage/DiscountPercentage)
3. İndirim varsa hesaplama yapılır:
   ```
   İndirimli Fiyat = Orijinal Fiyat × (1 - İndirim% / 100)
   ```
4. UI'da indirim gösterimi:
   - Ana sayfa: İndirim etiketi + çizili fiyat
   - Detay sayfa: Büyük indirim gösterimi
   - Sepet: İndirimli fiyat kullanılır

**İndirim Hesaplama Örnekleri:**
- Ürün fiyatı: 100₺, İndirim: 20%
- İndirimli fiyat: 100 × (1 - 20/100) = 80₺
- Tasarruf: 20₺

**Görsel Gösterim:**
- Grid view: Kompakt indirim etiketi
- Liste view: Yan yana fiyat gösterimi
- Detay sayfa: Prominent indirim vurgusu

**Sonuç:**
- İndirimler doğru hesaplanır ve gösterilir
- Kullanıcı tasarruf miktarını görür

---

## ALIŞVERİŞ SENARYOLARI

### US-006: Sepete Ürün Ekleme
**Amaç:** Kullanıcının beğendiği ürünleri sepete eklemesi

**Ön Koşullar:**
- Kullanıcı giriş yapmış
- Ürün detay sayfası açık

**Ana Akış:**
1. Ürün detay sayfasında "Sepete Ekle" butonuna basar
2. Ürün sepete eklenir (MyApp.cart listesi)
3. Başarı mesajı gösterilir
4. Sepet badge'i güncellenir (sağ üst)
5. Ürün bilgileri sepette saklanır:
   - Ürün ID, ad, fiyat
   - İndirimli fiyat (varsa)
   - Miktar (varsayılan: 1)

**Sepet Veri Yapısı:**
```dart
{
  'productId': String,
  'name': String,
  'price': double,
  'discountedPrice': double,
  'imageUrl': String,
  'quantity': int
}
```

**Sepet Persistency:**
- Uygulama kapatılsa bile sepet korunur
- Çıkış yapılsa bile sepet bilgileri saklanır
- SharedPreferences ile yerel kayıt

**Sonuç:**
- Ürün sepete eklenir
- Badge sayısı artar
- Bildirim gösterilir

---

### US-007: Sepet Yönetimi
**Amaç:** Sepetteki ürünlerin görüntülenmesi ve yönetilmesi

**Ön Koşullar:**
- Sepette en az bir ürün var
- Sepet sayfası açık

**Ana Akış:**
1. Sağ üstteki sepet ikonuna tıklanır
2. Sepet sayfası açılır
3. Sepetteki ürünler listelenir:
   - Ürün resmi, adı, fiyatı
   - Miktar artırma/azaltma butonları
   - Çıkarma butonu
4. Toplam tutar otomatik hesaplanır
5. "Satın Al" butonu gösterilir

**Miktar İşlemleri:**
- (+) butonu: Miktarı 1 artırır
- (-) butonu: Miktarı 1 azaltır (min: 1)
- Çöp kutusu: Ürünü sepetten çıkarır

**Fiyat Hesaplama:**
- Her ürün için: Miktar × (İndirimli Fiyat || Normal Fiyat)
- Genel toplam: Tüm ürünlerin toplamı

**Boş Sepet:**
- Sepet boşsa: "Sepetiniz boş" mesajı
- Alışverişe devam linki

**Sonuç:**
- Sepet içeriği yönetilebilir
- Toplam tutar güncel kalır

---

### US-008: Adres Seçimi
**Amaç:** Sipariş için teslimat adresinin belirlenmesi

**Ön Koşullar:**
- Sepette ürün var
- "Satın Al" butonuna basılmış
- Kullanıcı girişi yapılmış

**Ana Akış:**
1. Sepetten "Satın Al" butonuna basılır
2. Adres seçimi sayfası açılır
3. Kayıtlı adres gösterilir (API'den)
4. Kullanıcı mevcut adresi seçer VEYA
5. "Yeni Adres Ekle" seçeneğini kullanır
6. Yeni adres formu:
   - Adres başlığı (Ev, İş vb.)
   - Tam adres
   - Şehir/İlçe
   - Posta kodu
7. Fatura adresi seçimi
8. "Devam Et" butonuna basar

**Adres Validasyonu:**
- Tüm alanlar zorunlu
- Minimum karakter kontrolü
- Şehir/ilçe format kontrolü

**Fatura Adresi:**
- Teslimat adresi ile aynı (varsayılan)
- Farklı fatura adresi seçilebilir
- Şirket bilgileri eklenebilir

**Sonuç:**
- Teslimat adresi belirlenir
- Sipariş özeti sayfasına geçilir

---

### US-009: Sipariş Oluşturma
**Amaç:** Seçilen ürünler ve adres ile siparişin tamamlanması

**Ön Koşullar:**
- Sepette ürünler var
- Adres seçimi yapılmış
- Sipariş özeti sayfası açık

**Ana Akış:**
1. Sipariş özeti gösterilir:
   - Seçilen ürünler ve adetleri
   - Teslimat adresi
   - Fiyat detayları
2. Fiyat hesaplaması:
   - Ürünler toplamı
   - KDV (%18)
   - Kargo ücreti (200₺ üzeri ücretsiz)
   - Genel toplam
3. Sipariş bilgileri:
   - Otomatik sipariş ID
   - Sipariş tarihi/saati
   - Tahmini teslimat
4. "Siparişi Onayla" butonuna basar
5. API'ye sipariş gönderilir
6. Başarılı sipariş sonrası:
   - Onay mesajı gösterilir
   - Sipariş numarası verilir
   - Sepet temizlenir
   - Ana sayfaya yönlendirilir

**Sipariş Veri Yapısı:**
```json
{
  "customerId": "string",
  "items": [
    {
      "productId": "string",
      "quantity": number,
      "price": number
    }
  ],
  "deliveryAddress": "string",
  "totalAmount": number,
  "orderDate": "datetime"
}
```

**Fiyat Hesaplama Örneği:**
- Ürünler: 150₺
- KDV (18%): 27₺
- Kargo: 0₺ (150₺ < 200₺ ama ücretsiz)
- Toplam: 177₺

**Sonuç:**
- Sipariş başarıyla oluşturulur
- Kullanıcı onay alır
- Sepet temizlenir

---

## ADMİN PANELİ SENARYOLARI

### US-010: Admin Yetki Kontrolü
**Amaç:** Admin kullanıcıların özel yetkilerinin kontrol edilmesi

**Ön Koşullar:**
- Kullanıcı giriş yapmış
- API'den kullanıcı verileri alınmış

**Ana Akış:**
1. Giriş sırasında kullanıcı verileri kontrol edilir
2. `IsAdmin` alanı kontrol edilir
3. Admin ise özel UI elementleri gösterilir:
   - Ana sayfa: "+" (Ürün Ekle) butonu
   - Ürün detay: "✏️" (Düzenle) butonu
   - Menü: "Admin Paneli" bölümü
4. Admin olmayan kullanıcılar bu butonları görmez

**Admin UI Elementleri:**
- **Ana Sayfa Header:** Ürün ekleme butonu
- **Ürün Detay AppBar:** Düzenleme butonu
- **Drawer Menü:** Admin paneli seçenekleri
- **Menü İtemları:** "Ürün Ekle" linki

**Yetki Kontrolü:**
- Her admin işleminde yetki kontrol edilir
- Yetkisiz erişim engellenır
- Hata mesajları gösterilir

**Sonuç:**
- Admin kullanıcılar ek özelliklere erişir
- Normal kullanıcılar kısıtlı erişim

---

### US-011: Ürün Ekleme (Admin)
**Amaç:** Admin kullanıcının yeni ürün eklemesi

**Ön Koşullar:**
- Admin yetkisi var
- İnternet bağlantısı mevcut
- API erişilebilir

**Ana Akış:**
1. Ana sayfada "+" butonuna VEYA menüden "Ürün Ekle" seçer
2. Ürün ekleme formu açılır
3. Zorunlu alanları doldurur:
   - Ürün Adı (2-100 karakter)
   - Açıklama (10-500 karakter)
   - Fiyat (pozitif sayı)
   - Resim URL'i (geçerli link)
   - İndirim Oranı (0-100, opsiyonel)
4. Form validasyonu yapılır
5. "Ürün Ekle" butonuna basar
6. API'ye POST isteği gönderilir
7. Başarılı ekleme sonrası ana sayfaya döner
8. Ürün listesi yenilenir

**Validasyon Kuralları:**
- Ürün adı: 2-100 karakter, boş olamaz
- Açıklama: 10-500 karakter
- Fiyat: Pozitif sayı (0'dan büyük)
- URL: Geçerli HTTP/HTTPS formatı
- İndirim: 0-100 arası sayı

**Hata Yönetimi:**
- 400: Geçersiz veri formatı
- 401: Oturum süresi dolmuş
- 403: Yetki yetersiz
- 409: Aynı isimde ürün var
- 500: Sunucu hatası

**Sonuç:**
- Yeni ürün sisteme eklenir
- Ana sayfada görünür hale gelir

---

### US-012: Ürün Düzenleme (Admin)
**Amaç:** Admin kullanıcının mevcut ürünü güncellemesi

**Ön Koşullar:**
- Admin yetkisi var
- Düzenlenecek ürün seçilmiş
- Ürün detay sayfası açık

**Ana Akış:**
1. Ürün detay sayfasında "✏️" butonuna basar
2. Düzenleme formu açılır
3. Mevcut veriler otomatik doldurulur
4. İstediği alanları değiştirir
5. "Ürünü Güncelle" butonuna basar
6. API'ye PUT isteği gönderilir
7. Başarılı güncelleme sonrası:
   - Ürün detayı yenilenir
   - Güncel bilgiler gösterilir
   - Ana sayfa listesi güncellenir

**Düzenlenebilir Alanlar:**
- Ürün Adı
- Açıklama
- Fiyat
- Resim URL'i
- İndirim Oranı

**Değiştirilemeyen:**
- Ürün ID (sistem tarafından atanır)
- Oluşturma tarihi

**Güncelleme Süreci:**
- Mevcut veriler form alanlarına yüklenir
- Sadece değiştirilen alanlar güncellenir
- Aynı validasyon kuralları uygulanır
- Değişiklik yoksa uyarı verilir

**Sonuç:**
- Ürün bilgileri güncellenir
- Değişiklikler anında yansır

---

## AYARLAR VE KONFİGÜRASYON SENARYOLARI

### US-013: Uygulama Ayarları
**Amaç:** Kullanıcının uygulama tercihlerini yönetmesi

**Ön Koşullar:**
- Kullanıcı giriş yapmış
- Ayarlar sayfası açık

**Ana Akış:**
1. Menüden "Ayarlar" seçilir
2. Ayarlar sayfası 5 kategoride açılır:
   - Bildirimler
   - Görünüm
   - Güvenlik
   - Uygulama
   - Hesap
3. İstediği kategorideki ayarları değiştirir
4. Değişiklikler otomatik kaydedilir

**Bildirim Ayarları:**
- Push bildirimleri: Açık/Kapalı
- E-posta bildirimleri: Açık/Kapalı

**Görünüm Ayarları:**
- Karanlık mod: Açık/Kapalı (geliştirme aşamasında)
- Dil: Türkçe, English, Deutsch, Français
- Para birimi: TL(₺), USD($), EUR(€), GBP(£)

**Güvenlik Ayarları:**
- Biyometrik giriş: Açık/Kapalı
- Otomatik giriş: Açık/Kapalı
- Şifre değiştirme: Dialog açar

**Uygulama Ayarları:**
- Yardım merkezi: Yardım sayfası açar
- Önbelleği temizle: Cache temizleme
- Uygulama hakkında: Versiyon bilgileri
- Geri bildirim: Feedback formu

**Veri Persistency:**
- Tüm ayarlar SharedPreferences'da saklanır
- Uygulama yeniden başlatıldığında korunur
- Çıkış yapılsa bile ayarlar kalır

**Sonuç:**
- Kullanıcı tercihleri kaydedilir
- Uygulama davranışı güncellenir

---

### US-014: Profil Görüntüleme
**Amaç:** Kullanıcının hesap bilgilerini görüntülemesi

**Ön Koşullar:**
- Kullanıcı giriş yapmış
- API'den kullanıcı verileri alınabilir

**Ana Akış:**
1. Menüden "Profil" seçilir
2. Profil sayfası açılır
3. Kullanıcı bilgileri gösterilir:
   - Ad Soyad
   - E-posta adresi
   - Telefon numarası
   - Adres bilgileri
   - Hesap oluşturma tarihi
4. "Çıkış Yap" butonu görüntülenir

**Veri Kaynağı:**
- Önce SharedPreferences'dan local veri
- API'den güncel detaylar çekilmeye çalışılır
- API başarısızsa local veri gösterilir

**Profil Bilgileri:**
- **Kişisel:** Ad, soyad, TC kimlik
- **İletişim:** E-posta, telefon
- **Adres:** Teslimat adresi
- **Hesap:** Oluşturma tarihi, admin durumu

**Çıkış İşlemi:**
- "Çıkış Yap" butonuna basılır
- Onay dialogu gösterilir
- Onaylanırsa token ve veriler temizlenir
- Giriş sayfasına yönlendirilir

**Sonuç:**
- Kullanıcı bilgileri görüntülenir
- Çıkış işlemi gerçekleştirilebilir

---

### US-015: Yardım Merkezi
**Amaç:** Kullanıcının uygulama hakkında bilgi alması

**Ön Koşullar:**
- Yardım sayfası erişilebilir
- Ayarlar veya menüden erişim

**Ana Akış:**
1. Ayarlar > Yardım Merkezi VEYA Menü > Yardım
2. Yardım sayfası açılır
3. Arama çubuğu ile konu aranabilir
4. Kategoriler halinde SSS görüntülenir:
   - Alışveriş (3 konu)
   - Hesap (3 konu)
   - Ödeme (2 konu)
   - Kargo (2 konu)
   - İade (2 konu)
   - Teknik (2 konu)
   - İletişim (1 konu)
5. İlgili konuya tıklanır
6. Detaylı açıklama görüntülenir

**Arama Özelliği:**
- Başlık, içerik ve etiketlerde arama
- Anlık filtreleme
- Sonuç bulunamazsa "Bulunamadı" mesajı

**Konu Kategorileri:**
- **Alışveriş:** Sipariş verme, arama, favoriler
- **Hesap:** Kayıt, giriş, admin özellikleri
- **Ödeme:** Ödeme yöntemleri, fatura
- **Kargo:** Teslimat süreleri, evde yokluk
- **İade:** İade işlemi, değişim
- **Teknik:** Uygulama sorunları, çevrimdışı
- **İletişim:** Müşteri hizmetleri

**Sonuç:**
- Kullanıcı sorularına yanıt bulur
- Uygulama kullanımı hakkında bilgilenir

---

## HATA YÖNETİMİ SENARYOLARI

### US-016: İnternet Bağlantısı Yönetimi
**Amaç:** İnternet bağlantısı olmadığında uygulamanın çalışmaya devam etmesi

**Ön Koşullar:**
- Uygulama çalışır durumda
- İnternet bağlantısı kesilmiş
- Hive veritabanında önceki veriler var

**Ana Akış:**
1. API isteği gönderilir
2. Timeout veya bağlantı hatası alınır
3. Hata yakalanır ve loglanır
4. Hive'dan yerel veriler yüklenir
5. Kullanıcıya "Çevrimdışı" bilgisi gösterilir
6. Temel işlevler çalışmaya devam eder

**Çevrimdışı Çalışan Özellikler:**
- Daha önce yüklenen ürünleri görüntüleme
- Sepet işlemleri (yerel)
- Profil bilgilerini görme
- Ayarlar değiştirme
- Yardım sayfasını görme

**Çevrimdışı Çalışmayan Özellikler:**
- Yeni ürün arama
- Sipariş verme
- Ürün ekleme/düzenleme (admin)
- Güncel fiyat bilgileri

**Bağlantı Geri Geldiğinde:**
- Otomatik yeniden deneme
- Verilerin senkronizasyonu
- "Çevrimiçi" duruma geçiş

**Sonuç:**
- Uygulama çevrimdışı çalışabilir
- Kullanıcı deneyimi sürdürülür

---

### US-017: API Hata Yönetimi
**Amaç:** API isteklerinde oluşan hataların uygun şekilde yönetilmesi

**Ön Koşullar:**
- API isteği yapılıyor
- Sunucuda hata oluşmuş

**Ana Akış:**
1. HTTP isteği gönderilir
2. Hata kodu alınır
3. Hata koduna göre mesaj belirlenir
4. Kullanıcıya uygun mesaj gösterilir
5. Gerekirse alternatif akış devreye girer

**HTTP Hata Kodları ve Mesajları:**
- **400 Bad Request:** "Geçersiz veri formatı"
- **401 Unauthorized:** "Oturum süresi dolmuş, tekrar giriş yapın"
- **403 Forbidden:** "Bu işlem için yetkiniz yok"
- **404 Not Found:** "İstenen kaynak bulunamadı"
- **409 Conflict:** "Bu veri zaten mevcut"
- **500 Internal Server Error:** "Sunucu hatası, tekrar deneyin"
- **Timeout:** "Bağlantı zaman aşımı"

**Hata Gösterim Yöntemleri:**
- SnackBar: Kısa bilgi mesajları
- Dialog: Kritik hatalar
- Loading durumu: İşlem devam ederken
- Error state: Sayfa seviyesi hatalar

**Yeniden Deneme Stratejisi:**
- Otomatik: Timeout hataları için
- Manuel: Kullanıcı "Tekrar Dene" butonuna basar
- Fallback: Yerel veriye geçiş

**Sonuç:**
- Hatalar uygun şekilde yönetilir
- Kullanıcı bilgilendirilir
- Uygulama çökmez

---

### US-018: Form Validasyon Hataları
**Amaç:** Kullanıcı girişlerinin doğrulanması ve hataların gösterilmesi

**Ön Koşullar:**
- Form sayfası açık
- Kullanıcı veri girişi yapıyor

**Ana Akış:**
1. Kullanıcı form alanını doldurur
2. Anlık validasyon yapılır (onChanged)
3. Hata varsa alan altında gösterilir
4. Form submit edildiğinde final validasyon
5. Tüm hatalar düzeltilene kadar submit engellenir

**Validasyon Kuralları:**

**Giriş Formu:**
- Kullanıcı adı: Boş olamaz
- Şifre: Minimum 1 karakter (demo için)

**Kayıt Formu:**
- Ad Soyad: 2-50 karakter arası
- E-posta: Geçerli e-posta formatı
- TC Kimlik: 11 haneli sayı
- Telefon: 11 haneli format
- Şifre: Minimum 6 karakter
- Şifre tekrarı: İlk şifre ile eşleşmeli

**Ürün Formu (Admin):**
- Ürün adı: 2-100 karakter
- Açıklama: 10-500 karakter
- Fiyat: Pozitif sayı
- URL: Geçerli HTTP/HTTPS formatı
- İndirim: 0-100 arası sayı

**Hata Gösterimi:**
- Kırmızı border: Hatalı alanlar
- Hata mesajı: Alan altında kırmızı yazı
- Submit butonu: Hata varsa deaktif

**Sonuç:**
- Geçersiz veriler engellenir
- Kullanıcı doğru formatta veri girer

---

### US-019: Uygulama Performans Sorunları
**Amaç:** Uygulama performans sorunlarının çözülmesi

**Ön Koşullar:**
- Uygulama yavaş çalışıyor
- Bellek kullanımı yüksek
- Kullanıcı şikayet ediyor

**Ana Akış:**
1. Performans sorunu tespit edilir
2. Sorunun kaynağı belirlenir
3. Uygun çözüm uygulanır
4. Kullanıcıya öneriler sunulur

**Yaygın Sorunlar ve Çözümleri:**

**Yavaş Çalışma:**
- Önbelleği temizle (Ayarlar > Önbelleği Temizle)
- Uygulamayı yeniden başlat
- Gereksiz uygulamaları kapat
- Telefon belleğini kontrol et

**Çökme Sorunları:**
- Uygulamayı tamamen kapat ve aç
- Telefonu yeniden başlat
- Uygulama güncellemesi kontrol et
- Son çare: Uygulamayı yeniden yükle

**Giriş Sorunları:**
- Kullanıcı adı/şifre kontrol et
- İnternet bağlantısını kontrol et
- Çevrimdışı giriş dene
- Cache temizle

**Ürün Yükleme Sorunları:**
- İnternet bağlantısını kontrol et
- Sayfayı yenile (aşağı çek)
- Uygulamayı yeniden başlat
- Farklı ağ bağlantısı dene

**Önleyici Tedbirler:**
- Düzenli cache temizleme
- Gereksiz dosyaları silme
- Uygulamayı güncel tutma
- Yeterli depolama alanı

**Sonuç:**
- Performans sorunları çözülür
- Kullanıcı deneyimi iyileşir

---

## SONUÇ VE DEĞERLENDİRME

### Kapsam Özeti
Bu doküman, Shoppy e-ticaret uygulamasının tüm çalışan özelliklerini kapsamaktadır. Toplam 19 ana durum senaryosu ile:

- ✅ **Kimlik Doğrulama:** Giriş, kayıt, otomatik giriş
- ✅ **Ürün Yönetimi:** Listeleme, arama, detay, indirim sistemi
- ✅ **Alışveriş:** Sepet, adres seçimi, sipariş oluşturma
- ✅ **Admin Paneli:** Yetki kontrolü, ürün ekleme/düzenleme
- ✅ **Ayarlar:** Uygulama ayarları, profil, yardım merkezi
- ✅ **Hata Yönetimi:** Çevrimdışı çalışma, API hataları, validasyon

### Teknik Özellikler
- **Platform:** Flutter (Cross-platform)
- **Durum Yönetimi:** StatefulWidget + SharedPreferences
- **Yerel Veri:** Hive NoSQL Database
- **API İletişimi:** HTTP REST Client
- **Offline Support:** Tam çevrimdışı çalışma desteği

### Test Edilmiş Senaryolar
Tüm senaryolar geliştirme ortamında test edilmiş ve çalışır durumda olduğu doğrulanmıştır. Profil güncelleme gibi henüz implement edilmemiş özellikler kapsam dışı bırakılmıştır.

### Gelecek Geliştirmeler
- Profil güncelleme işlevi
- Gelişmiş arama filtreleri  
- Push notification sistemi
- Sipariş takip sistemi
- Favori ürünler özelliği

---

**Doküman Sonu**  
*Tüm durum senaryoları mevcut proje kapsamında test edilmiş ve çalışır durumda olduğu onaylanmıştır.*
