# LinkGuard Web

Scaffold kosong untuk dashboard admin Next.js dan REST API Flask.

Versi stabil diverifikasi pada 11 Oktober 2026 melalui registry npm dan PyPI:

- Next.js **16.4.0**, React **19.3.0**, TypeScript **7.0.2**.
- Bun **1.4.3**, Oxlint **1.87.0**, Oxfmt **0.72.0**.
- Flask **3.1.3**.

## Struktur

```text
App/Web/
├── admin/
│   ├── public/            # Aset statis
│   ├── src/
│   │   ├── app/           # Halaman dan layout App Router
│   │   ├── components/    # Komponen bersama
│   │   ├── features/      # Modul per fitur
│   │   ├── hooks/         # Custom hooks
│   │   ├── lib/           # Helper dan integrasi
│   │   └── types/         # Tipe TypeScript
│   ├── package.json
│   └── bun.lock
└── api/
    ├── app/
    │   ├── __init__.py    # Application factory
    │   ├── routes/        # Endpoint REST API
    │   ├── models/        # Model data
    │   ├── services/      # Logika bisnis
    │   ├── schemas/       # Validasi dan serialisasi
    │   └── utils/         # Helper
    ├── tests/
    └── requirements.txt
```

Folder cadangan sengaja kosong. Belum ada UI dashboard, endpoint, autentikasi, database, atau integrasi antar aplikasi.

## Menjalankan

Gunakan Bun 1.4.3+ dan Python 3.10+. Jika memakai Node.js untuk tooling, gunakan Node.js 24+.

Admin, dari root repository:

```sh
cd App/Web/admin
bun install --frozen-lockfile
bun run dev
```

Buka `http://localhost:3000`; halaman awal kosong. Lint dan format memakai Oxlint dan Oxfmt; pemeriksaan tipe memakai TypeScript. Jalankan `bun run lint`, `bun run format:check`, `bun run typecheck`, dan `bun run build` untuk pengecekan.

API, di terminal lain dari root repository:

```sh
cd App/Web/api
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
python -m flask --app app:create_app run --debug --port 5001
```

API berjalan di `http://localhost:5001` dan mengembalikan 404 karena belum ada route.
