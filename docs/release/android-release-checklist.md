# Android Release Checklist

> **Trạng thái:** Tạm hoãn (defer) — chưa tới giai đoạn submit Play Store. Khi nào sẵn sàng phát hành production, làm tuần tự checklist dưới.
>
> **Bối cảnh:** Audit security session phát hiện [`android/app/build.gradle.kts`](../../mobile/android/app/build.gradle.kts) hiện tại
> dùng debug signing key cho release build (line 51) và **không có ProGuard/R8**. Block Play Store publish + APK
> reverse-engineer trivial. Xem chi tiết ở Critical S6.1 trong audit security.

---

## Tóm tắt rủi ro hiện tại

| Vấn đề | Hậu quả | Block prod? |
|--------|---------|-------------|
| `signingConfig = signingConfigs.getByName("debug")` cho release | APK release ký bằng debug key — Play Store reject | ✅ YES |
| Không có `minifyEnabled = true` | APK ship unobfuscated, Java/Kotlin code reverse-engineer trivial bằng `apktool` + `jadx` | ⚠️ Recommended |
| Không có `shrinkResources = true` | APK lớn 1.5-2× cần thiết | ⚠️ Recommended |
| Không có `proguard-rules.pro` | (N/A vì minify chưa bật) | ⚠️ Khi bật minify cần |
| Không có upload keystore | Không thể tạo App Bundle (`.aab`) cho Play Store | ✅ YES |

---

## Checklist trước Production Release

### Bước 1 — Generate upload keystore (one-time)

```bash
# Chạy trên máy dev/release engineer (KHÔNG commit file .jks)
keytool -genkey -v \
  -keystore ~/upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

Khi `keytool` hỏi:
- **Keystore password:** đặt password mạnh ≥16 ký tự, lưu password manager
- **Key password:** có thể giống keystore password (Play Store khuyến nghị)
- **Common Name (CN):** `HTTM XăngDầu Production`
- **Organizational Unit (OU):** `Engineering`
- **Organization (O):** Tên công ty
- **Locality / State / Country code:** `Hanoi / HN / VN`

**Validity 10000 ngày (~27 năm):** đủ vòng đời app. Nếu key rotation cần thiết sau này, Google Play App Signing có flow upload key replacement.

### Bước 2 — Lưu credentials vào password manager

**KHÔNG commit:**
- File `*.jks` keystore
- Password keystore
- Password key alias
- Path đến keystore trên máy build

**Lưu trong company password manager (1Password / Bitwarden / Vaultwarden):**
- `HTTM XăngDầu Android Upload Keystore`
  - File: attach `upload-keystore.jks`
  - Field: `Keystore password`
  - Field: `Key alias` (= `upload`)
  - Field: `Key password`
  - Note: SHA-256 fingerprint (chạy `keytool -list -v -keystore ~/upload-keystore.jks` ghi lại)

**Backup keystore:**
- Encrypted backup ở 2 location vật lý khác nhau (vd USB key safe + encrypted cloud)
- Mất keystore = không thể update app trên Play Store nữa (phải Google Play App Signing recovery flow, mất ~1-2 tuần)

### Bước 3 — Configure gradle credentials (per-machine)

**Option A — Local dev `~/.gradle/gradle.properties`** (gitignored mặc định):

```properties
# ~/.gradle/gradle.properties (NEVER commit, never push to repo)
HTTM_RELEASE_STORE_FILE=/Users/<your-name>/upload-keystore.jks
HTTM_RELEASE_STORE_PASSWORD=<from password manager>
HTTM_RELEASE_KEY_ALIAS=upload
HTTM_RELEASE_KEY_PASSWORD=<from password manager>
```

**Option B — CI environment variables** (preferred cho CI/CD):

GitHub Actions / GitLab CI / Bitrise secrets:
- `HTTM_RELEASE_STORE_FILE` — path tới `upload-keystore.jks` được restore từ secret base64 lúc build
- `HTTM_RELEASE_STORE_PASSWORD`
- `HTTM_RELEASE_KEY_ALIAS`
- `HTTM_RELEASE_KEY_PASSWORD`

CI pipeline restore keystore từ base64 secret:

```yaml
# Github Actions sample
- name: Restore release keystore
  run: |
    echo "$RELEASE_KEYSTORE_BASE64" | base64 -d > $RUNNER_TEMP/upload-keystore.jks
    echo "HTTM_RELEASE_STORE_FILE=$RUNNER_TEMP/upload-keystore.jks" >> $GITHUB_ENV
  env:
    RELEASE_KEYSTORE_BASE64: ${{ secrets.HTTM_RELEASE_KEYSTORE_BASE64 }}
```

### Bước 4 — Enable release signing config trong `build.gradle.kts`

**File:** [`mobile/android/app/build.gradle.kts`](../../mobile/android/app/build.gradle.kts)

Replace block `buildTypes { release { ... } }` hiện tại (line 47-53) với:

```kotlin
android {
    // ... existing namespace, compileSdk, defaultConfig ...

    signingConfigs {
        create("release") {
            val storeFilePath = System.getenv("HTTM_RELEASE_STORE_FILE")
                ?: project.findProperty("HTTM_RELEASE_STORE_FILE") as String?
            if (storeFilePath != null && file(storeFilePath).exists()) {
                this.storeFile = file(storeFilePath)
                this.storePassword = System.getenv("HTTM_RELEASE_STORE_PASSWORD")
                    ?: project.findProperty("HTTM_RELEASE_STORE_PASSWORD") as String?
                this.keyAlias = System.getenv("HTTM_RELEASE_KEY_ALIAS")
                    ?: project.findProperty("HTTM_RELEASE_KEY_ALIAS") as String?
                this.keyPassword = System.getenv("HTTM_RELEASE_KEY_PASSWORD")
                    ?: project.findProperty("HTTM_RELEASE_KEY_PASSWORD") as String?
            }
        }
    }

    buildTypes {
        release {
            // Real signing config when configured; fallback debug for `flutter run --release` perf testing.
            val releaseSigning = signingConfigs.getByName("release")
            signingConfig = if (releaseSigning.storeFile != null) {
                releaseSigning
            } else {
                signingConfigs.getByName("debug")
            }

            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}
```

### Bước 5 — Tạo `android/app/proguard-rules.pro`

**File mới:** `mobile/android/app/proguard-rules.pro`

```proguard
# ---------- Flutter / Dart core ----------
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-dontwarn io.flutter.embedding.**

# ---------- Plugins (kept by reflection) ----------
# flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# app_links (deep link httmxd://)
-keep class com.llfbandit.app_links.** { *; }

# google_maps_flutter
-keep class io.flutter.plugins.googlemaps.** { *; }
-keep class com.google.android.gms.maps.** { *; }
-keep class com.google.android.libraries.maps.** { *; }

# image_picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# url_launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# geolocator
-keep class com.baseflow.geolocator.** { *; }

# dio (relies on okio)
-dontwarn okio.**
-dontwarn okhttp3.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# ---------- App-specific ----------
# Reflection (rare in Flutter — most JSON parsing manual via JsonUtils, không cần keep model classes).
# Nếu release build crash với ClassNotFoundException sau bước 6, thêm -keep tương ứng ở đây.

# Giữ stack trace cho Crashlytics / Sentry
-keepattributes SourceFile,LineNumberTable
# Đổi tên file gốc thành "SourceFile" để khó reverse-engineer hơn
-renamesourcefileattribute SourceFile
```

### Bước 6 — Build & smoke test

```bash
cd mobile

# Verify env / gradle.properties đã set
flutter clean
flutter pub get

# Build APK release với obfuscation
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.your-prod-domain.example \
  --dart-define=ADMIN_API_KEY=<prod-admin-key> \
  --obfuscate \
  --split-debug-info=build/symbols/

# Hoặc build App Bundle (preferred cho Play Store)
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://api.your-prod-domain.example \
  --dart-define=ADMIN_API_KEY=<prod-admin-key> \
  --obfuscate \
  --split-debug-info=build/symbols/
```

**`--obfuscate` + `--split-debug-info`:** obfuscate Dart symbol names. Symbol map lưu ở `build/symbols/` — cần để decode crash stack trace từ Crashlytics. **Backup `build/symbols/` mỗi release** vào company storage (S3 / cloud bucket) — mất = không decode được crash logs.

**Smoke test cuối cùng:**

- [ ] APK install thành công trên 3 device thật khác nhau (Android 8 / 12 / 14)
- [ ] App launch không crash
- [ ] Login với account thật → token persist sau restart app
- [ ] Tab Bản đồ render (Google Maps render với prod API key + iOS GMS_API_KEY config)
- [ ] Tab Báo cáo load data từ prod API
- [ ] Tab Tài khoản → Đổi mật khẩu → submit thành công
- [ ] Tab Nhiên liệu → tạo giao dịch → save thành công
- [ ] Báo cáo vi phạm submit thành công, list refresh
- [ ] Logout → secure storage clear → quay lại login screen
- [ ] Deep link `httmxd://reset-password?token=test` mở app + nav đến reset page
- [ ] APK size ≤ 30 MB (sau minify+shrink, target reasonable cho project size)

**Test crash decode workflow** (one-time setup):

```bash
# Tạo crash thủ công trong app (vd nút TestCrash trong dev build)
# Lấy obfuscated stack trace từ Logcat / Crashlytics
flutter symbolize -i build/symbols/app.android-arm64.symbols < obfuscated_stack.txt
```

### Bước 7 — Verify không leak secrets trong APK

```bash
# Decompile APK để verify
mkdir /tmp/apk-inspect && cd /tmp/apk-inspect
unzip ~/path/to/app-release.apk
cat AndroidManifest.xml | head -50
strings classes.dat | grep -iE '(AIza|api.*key|password|secret|192\.168)' | head -20
# Expected: no matches (key đã được Google Play App Signing extract / obfuscation hide)
```

⚠️ **Lưu ý:** Google Maps API key trong `AndroidManifest.xml` (build-time substitution từ env) sẽ vẫn visible trong decompiled APK. **Đây là expected** — Google Maps key restrict bằng package name + SHA-1 fingerprint của signing cert (cấu hình trên GCP console). Attacker copy key sang APK khác sẽ bị reject vì SHA-1 không khớp.

### Bước 8 — Submit Play Store

1. Google Play Console → Create app → Internal testing track
2. Upload `app-release.aab` (App Bundle, NOT APK)
3. Upload `mapping.txt` (cho deobfuscation Crashlytics) — file nằm ở `build/app/outputs/mapping/release/mapping.txt`
4. Đăng ký Google Play App Signing (recommended) — Google quản lý production signing key, dev chỉ giữ upload key
5. Internal testing track → 5-10 internal testers
6. Sau 1 tuần testing OK → Closed testing track (limited external)
7. Sau 1 tuần Closed OK → Production rollout staged 5% → 25% → 50% → 100%

---

## Liên quan: các audit khác cần đồng thời

Khi vào prod release pha, review các deferred warning từ audit:

| Audit session | Item | File |
|---|---|---|
| Map/location | 🟡 1.3 — `usesCleartextTraffic="true"` thay bằng `network_security_config.xml` chỉ allow LAN dev hosts | [`android/app/src/main/AndroidManifest.xml`](../../mobile/android/app/src/main/AndroidManifest.xml) |
| Map/location | 🟡 1.2 — Dev IP hardcoded `http://192.168.170.125:5112` ở `api_config_host*.dart` — thay bằng `10.0.2.2:5112` (Android emulator → host) hoặc empty + warning | [`mobile/lib/core/network/api_config_host.dart`](../../mobile/lib/core/network/api_config_host.dart) |
| core/network | 🔴 Critical 2.1 — Refresh token flow (cần backend `/api/oauth/refresh` endpoint) | [`mobile/lib/core/network/auth_http_interceptor.dart`](../../mobile/lib/core/network/auth_http_interceptor.dart) |
| core/network | 🔵 5.1 — Cert pinning với prod cert SHA-256 fingerprint | [`mobile/lib/core/network/dio_provider.dart`](../../mobile/lib/core/network/dio_provider.dart) |

---

## Estimated effort

| Bước | Effort | Người làm |
|------|--------|----------|
| 1 — Generate keystore | 5 phút | Release engineer (one-time) |
| 2 — Lưu password manager + backup | 15 phút | Release engineer (one-time) |
| 3 — Configure gradle.properties / CI secrets | 30 phút | DevOps / Release engineer |
| 4 — Update `build.gradle.kts` | 15 phút | Mobile engineer |
| 5 — Tạo `proguard-rules.pro` | 15 phút | Mobile engineer |
| 6 — Build + smoke test (3 devices) | 4-6 giờ | QA + Mobile engineer |
| 7 — Verify decompile không leak | 30 phút | Security review |
| 8 — Play Store submit + staged rollout | 2-4 tuần (gồm waiting period) | Release engineer |

**Total active work:** ~1-2 ngày engineering + 2-4 tuần Play Store rollout.

---

## Đầu mối

- **Audit security session reference:** Critical S6.1 trong session security audit (Claude Code, 2026-04-30+)
- **Owner (TBD):** Mobile lead khi tới giai đoạn release
- **Backup contact:** Release engineer / DevOps lead
