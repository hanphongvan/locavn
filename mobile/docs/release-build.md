# Release build — APK / AAB / IPA

Quy trình build bản phát hành cho mobile (Android + iOS). Đọc trước khi upload Google Play Console / TestFlight.

> Lý do có file này: `--dart-define-from-file=secrets/dev.json` cấu hình ở Android Studio **chỉ áp dụng cho Run** (debug). Khi build release qua menu hoặc lệnh `flutter build`, args đó **không tự động truyền** → `API_BASE_URL` trống → release build throw `StateError("API_BASE_URL is required for release builds")` → app crash khi mở.

---

## 0. Trước khi build (kiểm 1 lần đầu)

### 0.1 Secrets

Hai file (gitignored, chỉ có local) cần điền đủ các key:

- `mobile/secrets/dev.json` — dùng cho Run debug + build test sideload.
- `mobile/secrets/prod.json` — dùng cho build release upload Google Play / App Store.

Tối thiểu phải có các key dưới đây. Đặc biệt **`GOOGLE_SERVER_CLIENT_ID`** — nếu thiếu, app vẫn vào được nhưng nút "Đăng nhập Google" sẽ throw `GoogleSignInException`:

```json
{
  "MAP_PROVIDER": "goong",
  "API_BASE_URL": "https://xdapi.dms.gov.vn",
  "GOOGLE_SERVER_CLIENT_ID": "618004758900-57tttuq5sq8rep6k28ban6pa0ss3ecje.apps.googleusercontent.com",
  "GOONG_MAPTILES_KEY": "<key>",
  "GOONG_API_KEY": "<key>"
}
```

> ⚠️ `API_BASE_URL` không được có space leading/trailing. Code đã `trim()` nhưng để cho gọn, edit lại nếu thấy `" https://..."`.

> ⚠️ Web Client ID là loại `Web application` trên Google Cloud Console, **không phải** Android Client ID.

### 0.2 Bump version pubspec

Mỗi lần upload Play Console / TestFlight phải bump build number (số sau `+`). Trùng build number cũ → reject.

File: [`mobile/pubspec.yaml`](../pubspec.yaml), dòng `version:`.

Pattern:
- Bug fix / patch không thay đổi tính năng: bump build number `1.0.6+8` → `1.0.6+9`.
- Tính năng mới hoặc UI/UX thay đổi đáng kể: bump patch `1.0.6+8` → `1.0.7+1`.

Sau đó cần admin PUT `version-policy.latestVersion=1.0.7` (Vietnam time) để user version cũ thấy dialog soft-update.

---

## 1. Android — Build APK (sideload / test cho team)

```powershell
cd D:\projects\httm-xangdau\mobile

flutter build apk --release `
  --dart-define-from-file=secrets/prod.json `
  --dart-define=MAP_PROVIDER=goong
```

Output: `mobile/build/app/outputs/flutter-apk/app-release.apk` (~30–50 MB)

Cài vào điện thoại Android cắm cáp:
```powershell
adb install -r mobile\build\app\outputs\flutter-apk\app-release.apk
```

Hoặc gửi `.apk` qua Telegram / Drive / USB cho tester.

---

## 2. Android — Build AAB upload Google Play Console

```powershell
cd D:\projects\httm-xangdau\mobile

flutter build appbundle --release `
  --dart-define-from-file=secrets/prod.json `
  --dart-define=MAP_PROVIDER=goong
```

Output: `mobile/build/app/outputs/bundle/release/app-release.aab` (~50–70 MB)

### Upload Play Console

1. Đăng nhập <https://play.google.com/console>.
2. Chọn app `LocaVN`.
3. **Release → Production** (hoặc Internal/Closed testing tuỳ scope).
4. **Create new release** → drag `app-release.aab` vào.
5. Điền "What's new in this release" tiếng Việt (ngắn, gạch đầu dòng).
6. **Save → Review → Submit for review**.

---

## 3. iOS — Build IPA upload TestFlight (chạy trên Mac)

```bash
cd ~/path/to/locavn
git pull origin main
cd mobile
flutter pub get
cd ios && pod install && cd ..

flutter build ipa --release \
  --dart-define-from-file=secrets/prod.json \
  --dart-define=MAP_PROVIDER=goong
```

Output: `mobile/build/ios/ipa/*.ipa`

Upload bằng:
- Transporter app (kéo `.ipa` vào)
- Hoặc Xcode → Organizer → Distribute App

---

## 4. Common errors & fixes

### "App cài xong không vào được" sau khi build APK
**Nguyên nhân**: Quên truyền `--dart-define-from-file=secrets/prod.json` → `API_BASE_URL` trống → release build throw `StateError`.

**Verify bằng logcat**:
```powershell
adb logcat -c
adb logcat | findstr /i "flutter Dart StateError API_BASE_URL"
# Mở app — nếu thấy "StateError: API_BASE_URL is required..." → đúng nguyên nhân
```

**Fix**: Build lại với `--dart-define-from-file=secrets/prod.json`.

---

### "Đăng nhập Google không thành công"
2 nguyên nhân:

1. **`GOOGLE_SERVER_CLIENT_ID` chưa trong `prod.json`** → mobile throw `GoogleSignInException("Chưa cấu hình GOOGLE_SERVER_CLIENT_ID")`. Fix: thêm key vào `prod.json`.

2. **SHA-1 keystore release chưa đăng ký Google Cloud** → `google_sign_in` trả `idToken == null` → mobile throw `GoogleSignInException("Google không trả idToken")`. Fix:
   ```powershell
   keytool -list -v -keystore D:\chplay\upload-keystore.jks -alias upload
   ```
   Copy SHA-1 → <https://console.cloud.google.com/> → APIs & Services → Credentials → Android OAuth Client → Add fingerprint.

---

### "JWT is not yet valid" trên backend log lúc Google sign-in
**Nguyên nhân**: NTP drift > 5 phút giữa server và Google. Backend đã có `IssuedAtClockTolerance = 5 min` ở [GoogleTokenVerifier.cs](../../backend/src/Httm.XangDau.Api/Features/Auth/Google/GoogleTokenVerifier.cs). Nếu drift > 5 min thì cần fix infra:
```powershell
# Windows:
w32tm /query /status
w32tm /resync /force

# Linux:
timedatectl status
sudo systemctl restart systemd-timesyncd
```

---

### "Conflict with existing version code" khi upload Play Console
**Nguyên nhân**: Build number trùng bản đã upload trước đó.

**Fix**: Bump số sau `+` trong `pubspec.yaml` (vd `1.0.6+8` → `1.0.6+9`), rebuild AAB, upload lại.

---

### App release crash với "ClassNotFoundException" / "NoSuchMethodError"
**Nguyên nhân**: R8 strip class của plugin mà ProGuard rules không cover.

**Verify**: Tạm thời tắt minify trong [`mobile/android/app/build.gradle.kts`](../android/app/build.gradle.kts):
```kotlin
buildTypes {
    release {
        isMinifyEnabled = false   // ← tắt tạm
        isShrinkResources = false // ← tắt tạm
        ...
    }
}
```

Rebuild APK. Nếu OK → ProGuard rules thiếu. Bổ sung `-keep class <package>.** { *; }` vào [`mobile/android/app/proguard-rules.pro`](../android/app/proguard-rules.pro). Bật lại minify.

---

## 5. Checklist trước khi submit Play Console / App Store

- [ ] Pull `main` mới nhất (`git pull origin main`).
- [ ] Bump version `pubspec.yaml`.
- [ ] Commit + push version bump (em đã làm cho release `1.0.6+8`).
- [ ] `flutter pub get`.
- [ ] Backend đã deploy phiên bản tương thích (migration EF Core apply OK).
- [ ] Backend `version-policy.latestVersion` đã PUT thành phiên bản mới (cho user cũ thấy soft-update).
- [ ] Build với `--dart-define-from-file=secrets/prod.json`.
- [ ] Test cài file release trên 1 thiết bị thật trước khi upload Store.
- [ ] Login Google / Apple OK.
- [ ] Bản đồ render OK (Goong / MapLibre).
- [ ] Mở 1 cây xăng → marker click → sheet detail OK.

---

## 6. Tham khảo

- [`pubspec.yaml`](../pubspec.yaml) — version, dependencies.
- [`api_config.dart`](../lib/core/network/api_config.dart) — đọc `API_BASE_URL` từ dart-define.
- [`google_sign_in_service.dart`](../lib/core/auth/google/google_sign_in_service.dart) — đọc `GOOGLE_SERVER_CLIENT_ID`.
- [`android/app/build.gradle.kts`](../android/app/build.gradle.kts) — signing config (`HTTM_RELEASE_*`).
- [`secrets/dev.json.example`](../secrets/dev.json.example) — template secrets.
