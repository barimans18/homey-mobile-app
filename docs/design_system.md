# Homey Design System

Tema visual aplikasi Homey adalah hangat, ramah, dan rapi (*cozy & homey*). Hindari sudut tajam dan warna gelap yang kaku.

## 1. Palet Warna
- **Background:** `#FDFBF7` (Warm off-white)
- **Text Primary:** `#3D405B` (Soft Navy/Grey, jangan gunakan hitam pekat #000000)
- **Text Muted:** `#9CA3AF` (Gray untuk subtitle)
- **Accent Green (Budget/Success):** `#81B29A` (Sage green)
- **Accent Terracotta (Primary Action/Buttons):** `#E07A5F`
- **Accent Yellow (Warning/Kids/Meals):** `#F2CC8F`

## 2. Tipografi
- **Font Family:** `Nunito` (Terapkan via package `google_fonts`).
- Karakteristik: Membulat, friendly, dan mudah dibaca.
- Gunakan `FontWeight.w800` (ExtraBold) untuk Heading utama.

## 3. Komponen UI (Shape & Shadows)
- **Border Radius:** Gunakan sudut membulat ekstrem. 
  - Cards & Buttons: `BorderRadius.circular(16)` hingga `24`.
  - Bottom Sheet & Container luar: `BorderRadius.circular(32)` atau `40`.
- **Shadows:** Gunakan bayangan yang sangat lembut dan menyebar (Soft drop shadow).
  - Contoh: `BoxShadow(color: Color(0xFF3D405B).withOpacity(0.08), blurRadius: 40, offset: Offset(0, 10))`
- **App Bar:** Hindari AppBar standar bawaan Material. Gunakan custom row dengan padding atas yang lega.
- **Bottom Navigation:** Rounded corners di bagian atas dengan efek shadow lembut, dan Floating Action Button (FAB) menonjol di tengah.