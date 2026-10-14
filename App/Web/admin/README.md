# LinkGuard Admin

Next.js, TypeScript, Bun, Oxlint/Oxfmt, Tailwind CSS 4, shadcn Base UI Nova, dan TanStack Table dengan pagination server. Halaman `/login`, `/datasets`, `/profile`; tidak ada registrasi publik.

Lihat [panduan web](../README.md) untuk menjalankan seluruh layanan lewat Docker Compose, membuat akun admin, dan pengujian.

```sh
bun install --frozen-lockfile
bun run dev
```

`bun run lint`, `bun run format:check`, `bun run typecheck`, `bun run build`, dan `bun run test:e2e` tersedia. Geist disajikan lokal dari paket `geist`.

Tampilan mengadaptasi blok resmi [dashboard-01](https://ui.shadcn.com/blocks#blocks) dan [login-03](https://ui.shadcn.com/blocks/login), menggunakan varian Base UI Nova. Sidebar dapat diciutkan di desktop, menjadi drawer pada mobile, dan menyimpan aksi keluar pada menu akun. Tabel memakai header sticky dan scroll terpisah; pagination tetap berada di footer tabel.
