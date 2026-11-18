import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import { Brand } from "@/components/admin-shell";
import { buttonVariants } from "@/components/ui/button";

export default function NotFound() {
  return (
    <main className="mx-auto flex min-h-svh max-w-lg flex-col justify-center gap-8 px-6 py-12">
      <Brand />
      <div className="grid gap-3">
        <h1 className="text-2xl font-semibold tracking-tight">Halaman tidak ditemukan</h1>
        <p className="text-muted-foreground">
          Periksa kembali alamat halaman atau buka dashboard LinkGuard.
        </p>
      </div>
      <Link href="/datasets" className={buttonVariants({ className: "min-h-11 w-fit" })}>
        <ArrowLeft aria-hidden="true" />
        Buka dashboard
      </Link>
    </main>
  );
}
