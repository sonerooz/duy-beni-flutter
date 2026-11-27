# Duy Beni

Tahmin eden oyuncu kulaklığını takıp müziğin sesini açar. Anlatıcı ekrandaki kelimeyi yüksek sesle söyler; arkadaşı onu duymadan, dudaklarını okuyarak kelimeyi bulmaya çalışır. Bilirse **DOĞRU**'ya, bilemezse **PAS**'a bas. Süre bitmeden en çok puanı topla.

Flutter ile yazılmış, Android ve iOS için tek kod tabanı. Paket adı: `com.soneroz.duybeni`. Önceki Godot sürümü: [sonerooz/duy-beni](https://github.com/sonerooz/duy-beni).

- 12 kelime paketi (Türkçe, English, Français ve konu paketleri), arayüz paketin diline göre TR/EN/FR
- 1–4 takım, 30/60/90/120 sn tur, kolay/orta/zor
- Son 10 saniyede kırmızı sayaç, son 5 saniyede flaş, sallanan kelime, tizleşen bip ve titreşim
- Sözlük ve oyun içi anlam penceresi
- Veri toplamaz, internet izni yok

## Çalıştırma

```
flutter pub get
flutter run
```

### Mac / iOS

Xcode ve CocoaPods gerekir.

```
flutter pub get
cd ios && pod install && cd ..
open ios/Runner.xcworkspace
```

Xcode'da *Runner → Signing & Capabilities* altından kendi Team'ini seç (bundle id `com.soneroz.duybeni`; başkasına aitse değiştir), sonra `flutter run` ya da Xcode'dan çalıştır. iOS tarafı henüz bir cihazda denenmedi.

iOS'ta `vibration` paketi süreyi dikkate almaz (sabit kısa titreşim verir), kalan her şey Android'le aynıdır.

### Android yayın imzası

Anahtar dosyası ve şifre depoda tutulmaz, ortam değişkenleriyle verilir:

```
DUYBENI_KEYSTORE_PATH, DUYBENI_KEYSTORE_USER, DUYBENI_KEYSTORE_PASSWORD
flutter build appbundle
```

Windows'ta pub önbelleği başka diskteyse `android/gradle.properties` içindeki `kotlin.incremental=false` ayarı gerekir.

## Yapı

| Yol | İçerik |
|---|---|
| `lib/data.dart` | Kelime paketleri, sözlük yükleme (büyük dosya ayrı iş parçacığında), tekrarsız kelime destesi |
| `lib/game_state.dart` | Ayarlar, maç akışı, kazanan hesabı, kayıtlı geçmiş |
| `lib/l10n.dart` | Metinler (TR/EN/FR) |
| `lib/sfx.dart` | Ses ve titreşim |
| `lib/ui/` | Ekranlar |
| `tool/make_sounds.py` | `assets/audio` içindeki sinüs seslerini üretir |

## Test

```
flutter test
```

`test/data_test.dart` veri ve mantığı, `test/screens_test.dart` tüm ekran akışını (süre bitişi dahil) sınar ve `--dart-define=OUT=<klasör>` verilirse ekran görüntülerini yazar (`--dart-define=LANG=0|1|2` ile dil seçilir).

## Lisans notu

Yazı tipi Open Sans (SIL OFL 1.1, `assets/fonts/OFL.txt`). Kelime ve anlam verilerinin kaynağı için yayın öncesi lisans kontrolü gerekir.
