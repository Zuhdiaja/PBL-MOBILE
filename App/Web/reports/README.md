# Manajemen Laporan Prediksi

Dokumen ini menjelaskan alur laporan koreksi prediksi: dari pengguna mobile, melalui API, ditinjau admin di dashboard, lalu masuk ke dataset pelatihan.

## Alur

```text
Pengguna mobile                API                     Admin dashboard
     |                          |                            |
     |-- POST /reports/submit ->|                            |
     |                    status=submitted                  |
     |                          |<-- GET /reports -----------|
     |                          |<-- PATCH /reports/{id} ----|
     |                          |    status=review           |
     |                          |<-- POST .../sync-dataset --|
     |                    baris baru di dataset_rows         |
     |                    status=completed                   |
```

Laporan masuk dengan status `submitted`. Admin meninjau, boleh mengubah status, kategori, dan catatan. Tindakan **Setujui & Sinkronkan** menulis satu baris baru ke dataset aktif dan menandai laporan `completed`.

## Status

| Status | Arti |
| --- | --- |
| `submitted` | Baru dikirim, belum ditinjau |
| `review` | Sedang ditinjau |
| `completed` | Sudah disetujui dan disinkronkan ke dataset |
| `rejected` | Ditolak, tidak masuk dataset |

`dataset_synced` adalah penanda terpisah dari `status`. Nilainya `true` hanya setelah sync berhasil, dan dipakai untuk mencegah sync ganda.

## Endpoint

Semua endpoint berada di bawah `/api/v1`.

| Method | Path | Akses | Keterangan |
| --- | --- | --- | --- |
| `POST` | `/reports/submit` | Publik | Kirim laporan; rate limit 30/menit |
| `GET` | `/reports` | Admin | Daftar dengan filter dan paginasi |
| `GET` | `/reports/{id}` | Admin | Detail satu laporan |
| `PATCH` | `/reports/{id}` | Admin | Ubah status, kategori, catatan admin |
| `POST` | `/reports/{id}/sync-dataset` | Admin | Setujui dan tulis ke dataset aktif |
| `DELETE` | `/reports/{id}` | Admin | Hapus laporan yang belum tersinkron |

### Submit (publik)

`/reports/submit` tidak memerlukan sesi maupun `X-CSRF-Token`, karena dipanggil aplikasi mobile. Endpoint ini tetap dibatasi rate limit.

```powershell
Invoke-RestMethod -Uri 'http://localhost:3200/api/v1/reports/submit' -Method Post `
  -ContentType 'application/json' `
  -Body '{"url":"contoh.test","type":"False Negative","category":"Phishing","notes":"Meniru halaman login."}'
```

```sh
curl -X POST http://localhost:3200/api/v1/reports/submit \
  -H 'Content-Type: application/json' \
  -d '{"url":"contoh.test","type":"False Negative","category":"Phishing"}'
```

Field:

| Field | Wajib | Batas |
| --- | --- | --- |
| `url` | Ya | 1–2048 karakter |
| `type` | Ya | `False Positive` atau `False Negative` |
| `category` | Ya | 1–64 karakter, lihat [Aturan kategori](#aturan-kategori) |
| `notes` | Tidak | Maksimal 2000 karakter |
| `reporter_email` | Tidak | Maksimal 254 karakter |

Respons `201` berisi `report` dan `message`.

### Daftar

```sh
GET /api/v1/reports?status=review&search=phishing&page=1&page_size=25
```

| Parameter | Nilai | Default |
| --- | --- | --- |
| `status` | `all`, `submitted`, `review`, `completed`, `rejected` | `all` |
| `type` | `all`, `False Positive`, `False Negative` | `all` |
| `search` | Teks bebas, maksimal 200 karakter | — |
| `page` | Bilangan bulat ≥ 1 | `1` |
| `page_size` | `25`, `50`, `100` | `25` |

`search` mencocokkan `url`, `notes`, dan `reported_category`. Karakter `%` dan `_` diperlakukan literal, bukan wildcard.

Respons berisi `items`, `page`, `page_size`, `row_count`, `page_count`, dan `summary`:

```json
{
  "summary": {
    "total": 12,
    "submitted": 5,
    "review": 2,
    "completed": 4,
    "rejected": 1,
    "synced": 4
  }
}
```

`page` di luar rentang akan dijepit ke halaman terakhir yang valid, bukan menghasilkan error. Ini disengaja: setelah admin menghapus laporan terakhir di sebuah halaman, URL lama tetap menampilkan data yang benar.

### Ubah laporan

```sh
PATCH /api/v1/reports/42
{"status":"review","reported_category":"Phishing","admin_notes":"Sedang dianalisis."}
```

Semua field opsional. `admin_notes` dibatasi 2000 karakter.

### Sinkronkan ke dataset

```sh
POST /api/v1/reports/42/sync-dataset
```

Tindakan ini:

1. Mengunci baris laporan, lalu baris `dataset_state` secara eksklusif.
2. Menolak jika laporan sudah tersinkron.
3. Memvalidasi kategori terhadap kelas yang benar-benar ada di dataset aktif.
4. Menulis satu baris baru ke `dataset_rows` dengan `row_number` berikutnya.
5. Mengubah status laporan menjadi `completed`.

### Hapus laporan

```sh
DELETE /api/v1/reports/42
```

Laporan yang sudah tersinkron tidak dapat dihapus, agar baris dataset tidak menjadi yatim dan `row_number` tidak berlubang. Hapus atau impor ulang dataset bila baris tersebut memang harus dibuang.

## Aturan kategori

Kategori laporan memakai enam nama baku:

`Benign`, `Phishing`, `Malware`, `Spam`, `Defacement`, `Exploit`

Alias berikut diterima saat submit dan ubah laporan, lalu disimpan sebagai nama baku:

| Dikirim | Disimpan |
| --- | --- |
| `aman`, `Aman / Benign`, `benign` | `Benign` |
| `phishing` | `Phishing` |
| `malware` | `Malware` |
| `spam` | `Spam` |
| `defacement` | `Defacement` |
| `exploit` | `Exploit` |
| `legitimate` | `Benign` |

Kategori di luar daftar tetap disimpan apa adanya (misalnya `Lainnya`), tetapi **tidak dapat disinkronkan** sampai diubah ke kategori baku.

### Ejaan mengikuti dataset

Dataset pelatihan menentukan ejaan akhir. Sync tidak menulis nama baku, melainkan ejaan yang sudah dipakai dataset tersebut, sehingga tidak muncul kelas kembar.

Contoh pada dataset MURL:

| Kategori laporan | Ditulis ke dataset |
| --- | --- |
| `Benign` | `benign` |
| `Phishing` | `phishing` |
| `Malware` | `malware` |
| `Spam` | `spam` |
| `Defacement` | `defacement` |
| `Exploit` | `Exploit` |

Daftar ejaan dibaca sekali per dataset lewat `SELECT DISTINCT` pada kolom label, lalu di-cache di memori. Cache aman dari data basi karena setiap impor membuat dataset dengan ID baru.

### Kelas `legitimate`

Dataset MURL memiliki kelas `legitimate` (0,74% baris, mayoritas berupa domain tanpa path). Kelas ini **dipertahankan apa adanya** dan tidak pernah diubah oleh fitur laporan. Laporan yang menyatakan sebuah URL aman ditulis ke `benign`, karena laporan koreksi hanya membedakan "aman" dan "berbahaya", bukan asal-usul pengumpulan data.

### Konsistensi jenis laporan

| `type` | Kategori yang diizinkan |
| --- | --- |
| `False Positive` (model salah, seharusnya aman) | `Benign` |
| `False Negative` (model melewatkan ancaman) | `Phishing`, `Malware`, `Spam`, `Defacement`, `Exploit` |

Pelanggaran menghasilkan `409 inconsistent_report`. Aturan ini menjaga agar dataset tidak menerima baris yang bertentangan dengan klaim pelapor.

## Kode error

| Kode | Status | Sebab |
| --- | --- | --- |
| `invalid_url` | 400 | URL kosong atau melebihi 2048 karakter |
| `invalid_type` | 400 | Jenis laporan bukan `False Positive`/`False Negative` |
| `invalid_category` | 400 | Kategori kosong atau melebihi 64 karakter |
| `invalid_notes` | 400 | Catatan bukan teks atau melebihi 2000 karakter |
| `invalid_email` | 400 | Email pelapor melebihi 254 karakter |
| `invalid_status` | 400 | Filter atau status tidak dikenal |
| `invalid_pagination` | 400 | `page` atau `page_size` tidak valid |
| `not_found` | 404 | Laporan tidak ada |
| `no_active_dataset` | 400/404 | Belum ada dataset aktif |
| `already_synced` | 409 | Laporan sudah pernah disinkronkan |
| `report_synced` | 409 | Laporan tersinkron tidak boleh dihapus |
| `unsupported_dataset` | 409 | Dataset tanpa kolom URL/kategori, atau tanpa kategori yang diminta |
| `inconsistent_report` | 409 | Jenis laporan tidak cocok dengan kategori |

Format error selalu `{"error":{"code":"...","message":"..."}}`.

## Menguji dengan dataset MURL asli

Panduan ini **hanya membaca** data. Tidak ada `INSERT`, `UPDATE`, atau `DELETE` ke dataset.

### 1. Periksa dataset aktif

```sh
docker compose exec -T postgres psql -U linkguard -d linkguard -tAc \
  "select filename, row_count from datasets;"
```

Dataset MURL yang sudah diimpor berisi 783.705 baris dengan kolom `["url", "type"]`.

### 2. Lihat kelas yang tersedia

```sh
docker compose exec -T postgres psql -U linkguard -d linkguard -c \
  "select values->>1 as label, count(*) from dataset_rows group by 1 order by 2 desc;"
```

### 3. Cek pemetaan ejaan

Jalankan dari container yang memuat kode terbaru:

```sh
docker compose --profile test run --rm --no-deps -T test python -c "
from app import create_app
from app.extensions import db
from app.models import Dataset, DatasetState
from app.routes.reports import dataset_labels
app = create_app()
with app.app_context():
    did = db.session.get(DatasetState, 1).active_id
    columns = [c.lower() for c in db.session.get(Dataset, did).columns]
    idx = next(i for i, c in enumerate(columns) if any(k in c for k in ('label','category','class','type')))
    print(dataset_labels(did, idx))
"
```

### 4. Verifikasi bahwa dataset tidak berubah

```sh
docker compose exec -T postgres psql -U linkguard -d linkguard -tAc \
  "select row_count from datasets; select count(*) from dataset_rows;"
```

Kedua angka harus tetap 783.705.

### 5. Uji alur penuh (mengubah data)

Langkah ini **menambah satu baris** ke dataset aktif. Lakukan hanya bila Anda siap mengembalikannya.

1. Kirim laporan uji lewat `/reports/submit`.
2. Masuk dashboard di `http://localhost:3200`, buka menu **Laporan**.
3. Pilih laporan, tekan tombol sinkron, konfirmasi.
4. Periksa baris terakhir:

```sh
docker compose exec -T postgres psql -U linkguard -d linkguard -tAc \
  "select row_number, values::text from dataset_rows order by row_number desc limit 1;"
```

`row_count` akan menjadi 783.706. Untuk mengembalikan kondisi semula, hapus baris tersebut dan koreksi `datasets.row_count` kembali ke 783.705.

## Hasil verifikasi

| Pemeriksaan | Hasil |
| --- | --- |
| `docker compose --profile test run --build --rm test` | 52 lulus |
| `bun run lint` | lulus |
| `bun run typecheck` | lulus |
| `bun run build` | lulus |
| Pemetaan ejaan pada dataset MURL | 6 kategori baku terpetakan, `legitimate` dipertahankan |
| Dataset asli | tidak diubah (783.705 baris sebelum dan sesudah) |

Cakupan tes API mencakup submit publik, validasi masukan, alur admin, sync ke dataset, idempotensi, penolakan hapus laporan tersinkron, paginasi, filter status, batas panjang catatan, escaping wildcard, normalisasi kategori, konsistensi jenis laporan, dataset tanpa kolom URL, pemetaan ejaan dataset, dan isolasi cache antar-dataset.

## Batasan

- **`created_at`/`updated_at` belum punya `server_default`.** Aman lewat ORM, tetapi insert SQL mentah harus mengisi sendiri.
- **Belum ada index** pada `status`, `created_at`, atau `dataset_synced`. Query daftar masih sequential scan; penambahan index sebaiknya dilakukan setelah data tumbuh.
- **Aplikasi mobile belum memanggil API ini.** Mobile masih memakai sumber data demo di memori, sehingga laporan yang masuk saat ini berasal dari pemanggilan manual.
- **`report_type` tidak ditulis ke kolom dataset.** Nilainya hanya dipakai untuk validasi konsistensi. Jika dataset butuh kolom arah koreksi, itu perubahan terpisah.
- **Label non-baku tidak dapat disinkronkan.** Admin harus memilih kategori baku lewat dialog tinjau sebelum sync.
