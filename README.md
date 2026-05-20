# Qualitrack - Mobile App

Aplikasi mobile Qualitrack yang digunakan untuk manajemen kualitas (Audit, Finding, dan CAPA). Dibangun menggunakan Flutter.

## 🚀 Fitur Utama
- **Authentication:** Login dan Registrasi pengguna.
- **Audit Module:** Pembuatan audit plan dan Pengisian checklist audit.
- **Finding Module:** Pelaporan temuan dengan foto bukti.
- **CAPA Module:** Corrective and Preventive Action tracking.

## 📁 Struktur Project (Modular Architecture)
Project ini menggunakan arsitektur berbasis *package/modul* agar rapi dan mudah di-maintain. Jika mencari fitur spesifik, jangan cari di folder `lib/` utama, melainkan di folder `packages/`:

- `lib/` : Hanya berisi *entry point* (`main.dart`) dan konfigurasi *Dependency Injection* (`injector.dart`).
- `packages/auth/` : Modul untuk Login dan Registrasi.
- `packages/audit/` : Modul fitur Audit.
- `packages/finding/` : Modul fitur Temuan (Finding).
- `packages/capa/` : Modul fitur CAPA.
- `packages/core/` & `packages/core_services/` : Berisi komponen UI (*widget*), *helper*, dan konfigurasi API/Network yang dipakai secara global.

## 🛠️ Teknologi yang Digunakan
- **Framework:** [Flutter](https://flutter.dev/) (SDK ^3.7.2)
- **State Management:** BLoC (Business Logic Component)
- **Dependency Injection:** get_it
- **Version Management:** FVM (Flutter Version Management)
- **Monorepo Management:** Melos (opsional/pengembangan)

## 📋 Prasyarat
Sebelum menjalankan project ini, pastikan kamu sudah menginstal:
- Flutter SDK (Sesuai versi di FVM)
- Dart SDK
- Android Studio / VS Code

## 💻 Cara Menjalankan Project (Getting Started)

1. **Clone repositori ini:**
   ```bash
   git clone <url-repo-git-kamu>
   ```

2. **Gunakan versi Flutter yang sesuai (pakai FVM):**
   ```bash
   fvm use
   ```

3. **Install semua dependencies:**
   Karena menggunakan arsitektur *packages*, pastikan melakukan *pub get* di root project:
   ```bash
   fvm flutter pub get
   ```

4. **Konfigurasi URL Backend (API):**
   Pastikan backend ASP.NET sudah berjalan. Cari konfigurasi Base URL API di  `packages/core_services` dan ubah agar mengarah ke endpoint lokal atau *production* milikmu.

5. **Jalankan aplikasi di emulator atau device:**
   ```bash
   fvm flutter run
   ```

## 📦 Cara Build untuk Development (APK)

Untuk men-generate file `.apk` untuk diinstall di device kamu:
```bash
fvm flutter build apk --debug
```   
APK akan terletak di `build/app/outputs/flutter-apk/app-debug.apk`.

## 📦 Cara Build untuk Release (APK)
```bash
fvm flutter build apk --release
```
APK akan terletak di `build/app/outputs/flutter-apk/app-release.apk`.

## 📦 Cara Build untuk Production (Google Play Store)

Untuk men-generate file `.aab` untuk diupload ke Google Play Console:
```bash
fvm flutter build appbundle --release
```
AAB akan terletak di `build/app/outputs/bundle/release/app-release.aab`.

