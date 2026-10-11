# LinkGuard API

Scaffold Flask dengan application factory. Belum ada route atau fitur.

```sh
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
python -m flask --app app:create_app run --debug --port 5001
```

Server berjalan di `http://localhost:5001`. Semua URL mengembalikan 404 sampai route ditambahkan.

Struktur lengkap ada di [README Web](../README.md).
