# AI Developer Skills & Guidelines

Saat mengenerate kode Flutter untuk proyek ini, Anda WAJIB mematuhi aturan berikut:

## 1. Arsitektur (Clean Architecture + Feature First)
Strukturkan folder berdasarkan fitur. Setiap fitur harus memiliki 3 layer:
- `presentation/` (Pages, Widgets, Cubit/BLoC)
- `domain/` (Entities, Repositories interfaces, Usecases)
- `data/` (Models, Data Sources, Repositories implementation)

## 2. State Management (Cubit)
- Gunakan `Cubit` (bukan BLoC dengan event class) untuk mengurangi *boilerplate*, kecuali untuk stream real-time yang kompleks.
- Pisahkan state menjadi kelas-kelas yang merepresentasikan kondisi: `Initial`, `Loading`, `Loaded` (membawa data), dan `Error` (membawa pesan).
- Gunakan package `freezed` atau `equatable` untuk membuat kelas State.

## 3. Interaksi Backend (Supabase)
- Selalu gunakan `Supabase.instance.client`.
- Untuk fitur yang butuh real-time (seperti to-do list atau list pengeluaran), gunakan `.stream(primaryKey: ['id'])` dari Supabase SDK.
- Mapping response dari Supabase (JSON) ke Model/Entity di layer `data` menggunakan fungsi `fromJson`.

## 4. UI Code Rules (Clean UI)
- Ekstrak widget yang sering dipakai ke folder `core/presentation/widgets/`.
- JANGAN menulis fungsi logika *business/API* di dalam file UI (`.dart`). UI hanya boleh memanggil fungsi dari Cubit (misal: `context.read<FinanceCubit>().addExpense(...)`).
- Gunakan `BlocBuilder` untuk me-rebuild UI sesuai state, dan `BlocListener` untuk menampilkan Snackbar/Dialog.

## 5. Offline Support Strategy
- Data yang diambil dari Supabase simpan salinannya di local storage.
- Jika tidak ada koneksi internet, tampilkan data dari local storage.