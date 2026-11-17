/* oxlint-disable react/set-state-in-effect -- Synchronize the scan table with URL query params. */
/* oxlint-disable jsx-a11y/no-noninteractive-tabindex -- Scrollable table must be keyboard reachable. */
"use client";
import { useCallback, useEffect, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import {
  ScanLine,
  ShieldCheck,
  ShieldAlert,
  UsersRound,
  Search,
  ChevronLeft,
  ChevronRight,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { ErrorNotice, Loading } from "@/components/feedback";
import {
  api,
  messageOf,
  number,
  type MobileScan,
  type ScansResponse,
  type ScansSummary,
} from "@/lib/api";

/** Class names stay as the dataset spells them; only the wording is Indonesian. */
const categories = [
  "benign",
  "legitimate",
  "phishing",
  "malware",
  "spam",
  "defacement",
  "exploit",
];

function categoryTone(category: string) {
  const value = category.toLowerCase();
  if (value === "benign" || value === "legitimate") {
    return "bg-emerald-500/10 text-emerald-700 dark:text-emerald-400";
  }
  if (value === "spam" || value === "defacement") {
    return "bg-amber-500/10 text-amber-700 dark:text-amber-400";
  }
  return "bg-red-500/10 text-red-700 dark:text-red-400";
}

function formatTime(value: string | null) {
  if (!value) return "-";
  return new Date(value).toLocaleString("id-ID", {
    day: "numeric",
    month: "short",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export default function ScansPage() {
  const router = useRouter();
  const searchParams = useSearchParams();

  const currentCategory = searchParams.get("category") || "all";
  const currentPage = parseInt(searchParams.get("page") || "1", 10) || 1;
  const currentSearch = searchParams.get("search") || "";
  const rawSize = Number(searchParams.get("page_size") || 25);
  const currentPageSize = [25, 50, 100].includes(rawSize) ? rawSize : 25;

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [scans, setScans] = useState<MobileScan[]>([]);
  const [summary, setSummary] = useState<ScansSummary>({
    total: 0,
    safe: 0,
    unsafe: 0,
    users: 0,
    by_category: {},
  });
  const [pageCount, setPageCount] = useState(1);
  const [rowCount, setRowCount] = useState(0);
  const [searchInput, setSearchInput] = useState(currentSearch);

  const fetchScans = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const params = new URLSearchParams();
      if (currentCategory !== "all") params.set("category", currentCategory);
      if (currentPage > 1) params.set("page", String(currentPage));
      if (currentPageSize !== 25) params.set("page_size", String(currentPageSize));
      if (currentSearch) params.set("search", currentSearch);

      const [page, counts] = await Promise.all([
        api<ScansResponse>(`/scans?${params.toString()}`),
        api<ScansSummary>("/scans/summary"),
      ]);
      setScans(page.items);
      setPageCount(page.page_count);
      setRowCount(page.row_count);
      setSummary(counts);
    } catch (e) {
      setError(messageOf(e));
    } finally {
      setLoading(false);
    }
  }, [currentCategory, currentPage, currentPageSize, currentSearch]);

  useEffect(() => {
    void fetchScans();
  }, [fetchScans]);

  function updateQuery(
    nextCategory?: string,
    nextPage?: number,
    nextSearch?: string,
    nextSize?: number,
  ) {
    const params = new URLSearchParams(searchParams);
    if (nextCategory !== undefined) {
      if (nextCategory === "all") params.delete("category");
      else params.set("category", nextCategory);
      params.delete("page");
    }
    if (nextSize !== undefined) {
      if (nextSize === 25) params.delete("page_size");
      else params.set("page_size", String(nextSize));
      params.delete("page");
    }
    if (nextPage !== undefined) {
      if (nextPage <= 1) params.delete("page");
      else params.set("page", String(nextPage));
    }
    if (nextSearch !== undefined) {
      if (!nextSearch) params.delete("search");
      else params.set("search", nextSearch);
      params.delete("page");
    }
    router.replace(`/scans?${params.toString()}`);
  }

  const countOf = (category: string) => summary.by_category[category] ?? 0;

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Pemindaian URL</h1>
          <p className="text-sm text-muted-foreground">
            Riwayat pemeriksaan tautan yang dijalankan pengguna dari aplikasi mobile.
          </p>
        </div>
      </div>

      {error && <ErrorNotice message={error} retry={() => void fetchScans()} />}

      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        <div className="rounded-xl border bg-card p-4 shadow-xs">
          <div className="flex items-center justify-between text-muted-foreground">
            <span className="text-xs font-medium">Total Pemindaian</span>
            <ScanLine className="size-4 text-primary" />
          </div>
          <div className="mt-2 text-2xl font-bold">{number.format(summary.total)}</div>
        </div>

        <div className="rounded-xl border bg-card p-4 shadow-xs">
          <div className="flex items-center justify-between text-muted-foreground">
            <span className="text-xs font-medium">Tidak Berbahaya</span>
            <ShieldCheck className="size-4 text-emerald-500" />
          </div>
          <div className="mt-2 text-2xl font-bold">{number.format(summary.safe)}</div>
          <p className="mt-1 text-xs text-muted-foreground">Benign + Legitimate</p>
        </div>

        <div className="rounded-xl border bg-card p-4 shadow-xs">
          <div className="flex items-center justify-between text-muted-foreground">
            <span className="text-xs font-medium">Perlu Perhatian</span>
            <ShieldAlert className="size-4 text-red-500" />
          </div>
          <div className="mt-2 text-2xl font-bold">{number.format(summary.unsafe)}</div>
        </div>

        <div className="rounded-xl border bg-card p-4 shadow-xs">
          <div className="flex items-center justify-between text-muted-foreground">
            <span className="text-xs font-medium">Pengguna Memindai</span>
            <UsersRound className="size-4 text-blue-500" />
          </div>
          <div className="mt-2 text-2xl font-bold">{number.format(summary.users)}</div>
        </div>
      </div>

      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div className="flex flex-wrap gap-1.5">
          <Button
            size="sm"
            variant={currentCategory === "all" ? "default" : "outline"}
            onClick={() => updateQuery("all", 1)}
          >
            Semua
          </Button>
          {categories.map((value) => (
            <Button
              key={value}
              size="sm"
              variant={currentCategory === value ? "default" : "outline"}
              onClick={() => updateQuery(value, 1)}
            >
              {value}
              <span className="ml-1.5 text-xs opacity-70">{countOf(value)}</span>
            </Button>
          ))}
        </div>

        <form
          className="flex w-full items-center gap-2 sm:w-72"
          onSubmit={(e) => {
            e.preventDefault();
            updateQuery(undefined, 1, searchInput);
          }}
        >
          <div className="relative w-full">
            <Search className="absolute left-2.5 top-2.5 size-4 text-muted-foreground" />
            <Input
              type="search"
              placeholder="Cari URL atau pengguna…"
              className="pl-8"
              value={searchInput}
              onChange={(e) => setSearchInput(e.target.value)}
            />
          </div>
          <Button type="submit" variant="secondary" size="sm">
            Cari
          </Button>
        </form>
      </div>

      <div className="rounded-xl border bg-card shadow-xs">
        {loading ? (
          <div className="p-8">
            <Loading text="Memuat pemindaian…" />
          </div>
        ) : scans.length === 0 ? (
          <div className="flex flex-col items-center justify-center p-12 text-center text-muted-foreground">
            <ScanLine className="mb-3 size-10 stroke-[1.5]" />
            <p className="text-base font-medium">Belum ada pemindaian</p>
            <p className="text-xs">
              {currentSearch || currentCategory !== "all"
                ? "Coba ubah filter atau kata kunci pencarian Anda."
                : "Pengguna mobile belum memeriksa tautan apa pun."}
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto" tabIndex={0}>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="w-12">No</TableHead>
                  <TableHead>URL Diperiksa</TableHead>
                  <TableHead>Kategori</TableHead>
                  <TableHead>Skor Margin</TableHead>
                  <TableHead>Pengguna</TableHead>
                  <TableHead>Model</TableHead>
                  <TableHead>Waktu</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {scans.map((scan, idx) => (
                  <TableRow key={scan.scan_id}>
                    <TableCell className="font-mono text-xs text-muted-foreground">
                      {(currentPage - 1) * currentPageSize + idx + 1}
                    </TableCell>
                    <TableCell className="max-w-xs truncate font-mono text-xs font-medium">
                      {scan.url}
                    </TableCell>
                    <TableCell>
                      <span
                        className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${categoryTone(scan.category)}`}
                      >
                        {scan.category}
                      </span>
                    </TableCell>
                    <TableCell className="font-mono text-xs">
                      {scan.score_kind === "margin" ? scan.score.toFixed(4) : scan.score}
                    </TableCell>
                    <TableCell className="text-xs">
                      <div className="font-medium">{scan.user.name}</div>
                      <div className="text-muted-foreground">{scan.user.email}</div>
                    </TableCell>
                    <TableCell className="font-mono text-xs text-muted-foreground">
                      {scan.model_run_id ? scan.model_run_id.slice(0, 8) : "-"}
                    </TableCell>
                    <TableCell className="text-xs text-muted-foreground">
                      {formatTime(scan.created_at)}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}

        {scans.length > 0 && (
          <div className="flex flex-wrap items-center justify-between gap-3 border-t p-4 text-xs text-muted-foreground">
            <div>
              Menampilkan {(currentPage - 1) * currentPageSize + 1}–
              {Math.min(currentPage * currentPageSize, rowCount)} dari {number.format(rowCount)}{" "}
              pemindaian
            </div>
            <div className="flex items-center gap-2">
              <Label htmlFor="scan-page-size" className="text-xs">
                Baris per halaman
              </Label>
              <select
                id="scan-page-size"
                className="h-8 rounded-md border bg-background px-2 text-xs"
                value={currentPageSize}
                disabled={loading}
                onChange={(e) => updateQuery(undefined, 1, undefined, Number(e.target.value))}
              >
                {[25, 50, 100].map((n) => (
                  <option key={n} value={n}>
                    {n}
                  </option>
                ))}
              </select>
              {pageCount > 1 && (
                <>
                  <Button
                    variant="outline"
                    size="icon"
                    className="size-8"
                    aria-label="Halaman sebelumnya"
                    disabled={currentPage <= 1}
                    onClick={() => updateQuery(undefined, currentPage - 1)}
                  >
                    <ChevronLeft className="size-4" />
                  </Button>
                  <span className="px-2 font-medium">
                    {currentPage} / {pageCount}
                  </span>
                  <Button
                    variant="outline"
                    size="icon"
                    className="size-8"
                    aria-label="Halaman berikutnya"
                    disabled={currentPage >= pageCount}
                    onClick={() => updateQuery(undefined, currentPage + 1)}
                  >
                    <ChevronRight className="size-4" />
                  </Button>
                </>
              )}
            </div>
          </div>
        )}
      </div>

      <p className="text-xs text-muted-foreground">
        Skor margin adalah nilai <code>decision_function</code> LinearSVC untuk kelas terpilih, bukan
        probabilitas. Nilainya bisa negatif dan tidak dibatasi 0–1.
      </p>
    </div>
  );
}
