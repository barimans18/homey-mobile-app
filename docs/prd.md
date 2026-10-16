# Product Requirements Document (PRD): Homey App

## 1. Visi Produk
Homey adalah aplikasi manajemen rumah tangga yang dirancang khusus untuk pasangan (suami-istri) agar dapat berkolaborasi mengatur keuangan, jadwal, dan tugas harian secara transparan dan *real-time*.

## 2. Target Pengguna
Pasangan suami-istri atau keluarga modern yang membutuhkan alat sinkronisasi harian.

## 3. Fitur Utama (Minimum Viable Product)
1. **Authentication & Family Pairing:**
   - Login/Register.
   - Menggabungkan akun suami dan istri menggunakan "Kode Keluarga" unik.
2. **Dashboard (Beranda):**
   - Sapaan personal (berdasarkan role Suami/Istri).
   - Ringkasan sisa budget bulan ini.
   - Highlight 2-3 tugas/agenda terpenting hari ini.
3. **Joint Ledger (Keuangan Bersama):**
   - Input pemasukan & pengeluaran yang sinkron *real-time*.
   - Kategori pengeluaran (Dapur, Tagihan, Anak, dll).
   - Visualisasi limit budget per kategori (Progress bar).
4. **Shared Agenda & To-Do List:**
   - Checklist tugas yang bisa ditugaskan ke (Assignee): Suami, Istri, atau Keduanya.
   - Kalender mingguan.
5. **Meal Planner:**
   - Perencanaan menu makan (Sarapan, Siang, Malam).
   - Checklist bahan makanan yang terintegrasi (bisa dikirim ke daftar belanja).

## 4. Persyaratan Teknis & Non-Fungsional
- **Real-time Sync:** Setiap input dari istri harus langsung muncul di HP suami (dan sebaliknya) kurang dari 2 detik menggunakan Supabase Realtime.
- **Offline-First:** Pengguna harus bisa menginput pengeluaran (misal di basement supermarket) saat offline. Data disimpan ke lokal (Isar/sqflite) dan otomatis disinkronkan saat online.