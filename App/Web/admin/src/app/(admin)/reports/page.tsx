/* oxlint-disable react/set-state-in-effect -- Synchronize reports with URL query params and async server mutations. */
/* oxlint-disable jsx-a11y/no-noninteractive-tabindex -- Scrollable table must be keyboard reachable. */
"use client";
import { useCallback, useEffect, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import {
  Flag,
  Database,
  CheckCircle2,
  AlertCircle,
  Clock,
  Search,
  ChevronLeft,
  ChevronRight,
  Pencil,
  Trash2,
  Layers,
  ArrowRightCircle,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Dialog,
  DialogContent,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from "@/components/ui/dialog";
import { ErrorNotice, Loading } from "@/components/feedback";
import {
  api,
  messageOf,
  number,
  type PredictionReport,
  type ReportsResponse,
  type ReportsSummary,
  type ReportStageStatus,
} from "@/lib/api";

const statusLabels: Record<ReportStageStatus, string> = {
  submitted: "Diproses",
  review: "Ditinjau",
  completed: "Selesai",
  rejected: "Ditolak",
};

const categories = ["Benign", "Phishing", "Malware", "Spam", "Defacement", "Exploit"];

export default function ReportsPage() {
  const router = useRouter();
  const searchParams = useSearchParams();

  const currentTab = searchParams.get("status") || "all";
  const currentPage = parseInt(searchParams.get("page") || "1", 10) || 1;
  const currentSearch = searchParams.get("search") || "";
  const rawSize = Number(searchParams.get("page_size") || 25);
  const currentPageSize = [25, 50, 100].includes(rawSize) ? rawSize : 25;

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [reports, setReports] = useState<PredictionReport[]>([]);
  const [summary, setSummary] = useState<ReportsSummary>({
    total: 0,
    submitted: 0,
    review: 0,
    completed: 0,
    rejected: 0,
    synced: 0,
  });
  const [pageCount, setPageCount] = useState(1);
  const [rowCount, setRowCount] = useState(0);

  // Dialog State
  const [selectedReport, setSelectedReport] = useState<PredictionReport | null>(null);
  const [dialogMode, setDialogMode] = useState<"review" | "sync" | "delete" | null>(null);
  const [actionBusy, setActionBusy] = useState(false);

  // Form State in Review Dialog
  const [editStatus, setEditStatus] = useState<ReportStageStatus>("submitted");
  const [editCategory, setEditCategory] = useState("");
  const [editAdminNotes, setEditAdminNotes] = useState("");

  // Search input state
  const [searchInput, setSearchInput] = useState(currentSearch);

  const fetchReports = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const params = new URLSearchParams();
      if (currentTab !== "all") params.set("status", currentTab);
      if (currentPage > 1) params.set("page", String(currentPage));
      if (currentPageSize !== 25) params.set("page_size", String(currentPageSize));
      if (currentSearch) params.set("search", currentSearch);

      const res = await api<ReportsResponse>(`/reports?${params.toString()}`);
      setReports(res.items);
      setSummary(res.summary);
      setPageCount(res.page_count);
      setRowCount(res.row_count);
    } catch (e) {
      setError(messageOf(e));
    } finally {
      setLoading(false);
    }
  }, [currentTab, currentPage, currentPageSize, currentSearch]);

  useEffect(() => {
    void fetchReports();
  }, [fetchReports]);

  function updateQuery(
    nextStatus?: string,
    nextPage?: number,
    nextSearch?: string,
    nextSize?: number,
  ) {
    const params = new URLSearchParams(searchParams);
    if (nextStatus !== undefined) {
      if (nextStatus === "all") params.delete("status");
      else params.set("status", nextStatus);
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
    router.replace(`/reports?${params.toString()}`);
  }

  function openReviewDialog(report: PredictionReport) {
    setSelectedReport(report);
    setEditStatus(report.status);
    setEditCategory(report.reported_category);
    setEditAdminNotes(report.admin_notes || "");
    setDialogMode("review");
  }

  function openSyncDialog(report: PredictionReport) {
    setSelectedReport(report);
    setDialogMode("sync");
  }

  function openDeleteDialog(report: PredictionReport) {
    setSelectedReport(report);
    setDialogMode("delete");
  }

  async function handleSaveReview() {
    if (!selectedReport) return;
    setActionBusy(true);
    setError("");
    try {
      const res = await api<{ report: PredictionReport; message: string }>(
        `/reports/${selectedReport.id}`,
        {
          method: "PATCH",
          body: JSON.stringify({
            status: editStatus,
            reported_category: editCategory,
            admin_notes: editAdminNotes,
          }),
        },
      );
      setSuccess(res.message);
      setDialogMode(null);
      void fetchReports();
    } catch (e) {
      setError(messageOf(e));
    } finally {
      setActionBusy(false);
    }
  }

  async function handleSyncDataset() {
    if (!selectedReport) return;
    setActionBusy(true);
    setError("");
    try {
      const res = await api<{ report: PredictionReport; message: string }>(
        `/reports/${selectedReport.id}/sync-dataset`,
        { method: "POST" },
      );
      setSuccess(res.message);
      setDialogMode(null);
      void fetchReports();
    } catch (e) {
      setError(messageOf(e));
    } finally {
      setActionBusy(false);
    }
  }

  async function handleDeleteReport() {
    if (!selectedReport) return;
    setActionBusy(true);
    setError("");
    try {
      const res = await api<{ message: string }>(`/reports/${selectedReport.id}`, {
        method: "DELETE",
      });
      setSuccess(res.message);
      setDialogMode(null);
      void fetchReports();
    } catch (e) {
      setError(messageOf(e));
    } finally {
      setActionBusy(false);
    }
  }

  return (
    <div className="space-y-6">
      {/* Header and KPI Summary */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Manajemen Laporan</h1>
          <p className="text-sm text-muted-foreground">
            Kelola laporan koreksi URL dari pengguna dan integrasikan ke dataset pelatihan.
          </p>
        </div>
      </div>

      {success && (
        <div className="flex items-center gap-2 rounded-lg border border-emerald-500/20 bg-emerald-500/10 p-4 text-sm text-emerald-700 dark:text-emerald-400">
          <CheckCircle2 className="size-4 shrink-0" />
          <span>{success}</span>
          <Button
            variant="ghost"
            size="sm"
            className="ml-auto h-auto p-0 hover:bg-transparent"
            onClick={() => setSuccess("")}
          >
            Tutup
          </Button>
        </div>
      )}

      {error && <ErrorNotice message={error} retry={() => void fetchReports()} />}

      {/* KPI Cards */}
      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        <div className="rounded-xl border bg-card p-4 shadow-xs">
          <div className="flex items-center justify-between text-muted-foreground">
            <span className="text-xs font-medium">Total Laporan</span>
            <Flag className="size-4 text-primary" />
          </div>
          <div className="mt-2 text-2xl font-bold">{number.format(summary.total)}</div>
        </div>

        <div className="rounded-xl border bg-card p-4 shadow-xs">
          <div className="flex items-center justify-between text-muted-foreground">
            <span className="text-xs font-medium">Perlu Ditinjau</span>
            <Clock className="size-4 text-amber-500" />
          </div>
          <div className="mt-2 text-2xl font-bold">
            {number.format(summary.submitted + summary.review)}
          </div>
        </div>

        <div className="rounded-xl border bg-card p-4 shadow-xs">
          <div className="flex items-center justify-between text-muted-foreground">
            <span className="text-xs font-medium">Laporan Selesai</span>
            <CheckCircle2 className="size-4 text-emerald-500" />
          </div>
          <div className="mt-2 text-2xl font-bold">{number.format(summary.completed)}</div>
        </div>

        <div className="rounded-xl border bg-card p-4 shadow-xs">
          <div className="flex items-center justify-between text-muted-foreground">
            <span className="text-xs font-medium">Tersinkron Dataset</span>
            <Database className="size-4 text-blue-500" />
          </div>
          <div className="mt-2 text-2xl font-bold">{number.format(summary.synced)}</div>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <Tabs
          value={currentTab}
          onValueChange={(val) => updateQuery(val, 1)}
          className="w-full sm:w-auto"
        >
          <TabsList className="grid grid-cols-5 w-full text-xs sm:w-auto sm:text-sm">
            <TabsTrigger value="all">
              Semua<span className="hidden sm:inline"> ({summary.total})</span>
            </TabsTrigger>
            <TabsTrigger value="submitted">
              Diproses<span className="hidden sm:inline"> ({summary.submitted})</span>
            </TabsTrigger>
            <TabsTrigger value="review">
              Ditinjau<span className="hidden sm:inline"> ({summary.review})</span>
            </TabsTrigger>
            <TabsTrigger value="completed">
              Selesai<span className="hidden sm:inline"> ({summary.completed})</span>
            </TabsTrigger>
            <TabsTrigger value="rejected">
              Ditolak<span className="hidden sm:inline"> ({summary.rejected})</span>
            </TabsTrigger>
          </TabsList>
        </Tabs>

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
              placeholder="Cari URL atau catatan…"
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

      {/* Reports Table */}
      <div className="rounded-xl border bg-card shadow-xs">
        {loading ? (
          <div className="p-8">
            <Loading text="Memuat laporan…" />
          </div>
        ) : reports.length === 0 ? (
          <div className="flex flex-col items-center justify-center p-12 text-center text-muted-foreground">
            <Flag className="mb-3 size-10 stroke-[1.5]" />
            <p className="text-base font-medium">Tidak ada laporan ditemukan</p>
            <p className="text-xs">
              {currentSearch
                ? "Coba ubah kata kunci pencarian Anda."
                : "Belum ada laporan dari pengguna mobile."}
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto" tabIndex={0}>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="w-12">No</TableHead>
                  <TableHead>URL Tautan</TableHead>
                  <TableHead>Jenis Koreksi</TableHead>
                  <TableHead>Kategori Dilaporkan</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Integrasi Dataset</TableHead>
                  <TableHead>Tanggal</TableHead>
                  <TableHead className="text-right">Aksi</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {reports.map((report, idx) => (
                  <TableRow key={report.id}>
                    <TableCell className="font-mono text-xs text-muted-foreground">
                      {(currentPage - 1) * currentPageSize + idx + 1}
                    </TableCell>
                    <TableCell className="max-w-xs truncate font-mono text-xs font-medium">
                      {report.url}
                    </TableCell>
                    <TableCell>
                      <Badge
                        variant={report.report_type === "False Positive" ? "secondary" : "outline"}
                        className={
                          report.report_type === "False Negative"
                            ? "border-red-500/40 text-red-600 dark:text-red-400"
                            : "border-amber-500/40 text-amber-600 dark:text-amber-400"
                        }
                      >
                        {report.report_type === "False Positive"
                          ? "Positif Palsu"
                          : "Negatif Palsu"}
                      </Badge>
                    </TableCell>
                    <TableCell>
                      <Badge variant="outline" className="font-normal">
                        {report.reported_category}
                      </Badge>
                    </TableCell>
                    <TableCell>
                      <span
                        className={`inline-flex items-center gap-1.5 rounded-full px-2 py-0.5 text-xs font-medium ${
                          report.status === "completed"
                            ? "bg-emerald-500/10 text-emerald-700 dark:text-emerald-400"
                            : report.status === "review"
                              ? "bg-blue-500/10 text-blue-700 dark:text-blue-400"
                              : report.status === "rejected"
                                ? "bg-muted text-muted-foreground"
                                : "bg-amber-500/10 text-amber-700 dark:text-amber-400"
                        }`}
                      >
                        {statusLabels[report.status]}
                      </span>
                    </TableCell>
                    <TableCell>
                      {report.dataset_synced ? (
                        <span className="inline-flex items-center gap-1 text-xs font-medium text-emerald-600 dark:text-emerald-400">
                          <CheckCircle2 className="size-3.5" />
                          Tersinkron
                        </span>
                      ) : (
                        <span className="text-xs text-muted-foreground">Belum</span>
                      )}
                    </TableCell>
                    <TableCell className="text-xs text-muted-foreground">
                      {report.created_at
                        ? new Date(report.created_at).toLocaleDateString("id-ID", {
                            day: "numeric",
                            month: "short",
                            year: "numeric",
                          })
                        : "-"}
                    </TableCell>
                    <TableCell className="text-right">
                      <div className="flex items-center justify-end gap-1">
                        {!report.dataset_synced && (
                          <Button
                            variant="ghost"
                            size="icon"
                            className="size-8 text-blue-600 hover:text-blue-700 hover:bg-blue-50 dark:hover:bg-blue-950/50"
                            title="Sinkronkan ke Dataset"
                            onClick={() => openSyncDialog(report)}
                          >
                            <ArrowRightCircle className="size-4" />
                          </Button>
                        )}
                        <Button
                          variant="ghost"
                          size="icon"
                          className="size-8"
                          title="Tinjau & Edit Laporan"
                          onClick={() => openReviewDialog(report)}
                        >
                          <Pencil className="size-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          className="size-8 text-muted-foreground hover:text-destructive"
                          title="Hapus Laporan"
                          onClick={() => openDeleteDialog(report)}
                        >
                          <Trash2 className="size-4" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}

        {/* Pagination Footer */}
        {reports.length > 0 && (
          <div className="flex flex-wrap items-center justify-between gap-3 border-t p-4 text-xs text-muted-foreground">
            <div>
              Menampilkan {(currentPage - 1) * currentPageSize + 1}–
              {Math.min(currentPage * currentPageSize, rowCount)} dari {number.format(rowCount)}{" "}
              laporan
            </div>
            <div className="flex items-center gap-2">
              <Label htmlFor="page-size" className="text-xs">
                Baris per halaman
              </Label>
              <select
                id="page-size"
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

      {/* Dialog Review & Tindak Lanjut */}
      <Dialog open={dialogMode === "review"} onOpenChange={(open) => !open && setDialogMode(null)}>
        <DialogContent className="max-w-lg">
          <DialogTitle>Tinjau Laporan Prediksi</DialogTitle>
          <DialogDescription>
            Periksa detail klaim dari pengguna dan perbarui status peninjauan.
          </DialogDescription>

          {selectedReport && (
            <div className="space-y-4 pt-2 text-sm">
              <div className="rounded-lg border bg-muted/30 p-3 space-y-1.5">
                <div className="text-xs text-muted-foreground">URL Tautan:</div>
                <div className="font-mono text-xs font-semibold break-all text-primary">
                  {selectedReport.url}
                </div>
                <div className="grid grid-cols-2 gap-2 pt-2 text-xs">
                  <div>
                    <span className="text-muted-foreground">Jenis Koreksi: </span>
                    <span className="font-medium">
                      {selectedReport.report_type === "False Positive"
                        ? "Positif Palsu (Klaim Aman)"
                        : "Negatif Palsu (Klaim Bahaya)"}
                    </span>
                  </div>
                  <div>
                    <span className="text-muted-foreground">Pelapor: </span>
                    <span className="font-medium">
                      {selectedReport.reporter_email || "Pengguna Anonim"}
                    </span>
                  </div>
                </div>
                {selectedReport.notes && (
                  <div className="pt-2 text-xs">
                    <span className="text-muted-foreground">Catatan Pengguna: </span>
                    <span className="italic">“{selectedReport.notes}”</span>
                  </div>
                )}
              </div>

              <div className="space-y-2">
                <Label htmlFor="status">Status Peninjauan</Label>
                <select
                  id="status"
                  className="w-full rounded-md border bg-background px-3 py-2 text-sm"
                  value={editStatus}
                  onChange={(e) => setEditStatus(e.target.value as ReportStageStatus)}
                >
                  <option value="submitted">Diproses</option>
                  <option value="review">Ditinjau</option>
                  <option value="completed">Selesai</option>
                  <option value="rejected">Ditolak</option>
                </select>
              </div>

              <div className="space-y-2">
                <Label htmlFor="category">Kategori Verifikasi</Label>
                <select
                  id="category"
                  className="w-full rounded-md border bg-background px-3 py-2 text-sm"
                  value={editCategory}
                  onChange={(e) => setEditCategory(e.target.value)}
                >
                  {editCategory && !categories.includes(editCategory) && (
                    <option value={editCategory}>{editCategory} (belum baku)</option>
                  )}
                  {categories.map((value) => (
                    <option key={value} value={value}>
                      {value}
                    </option>
                  ))}
                </select>
                <p className="text-xs text-muted-foreground">
                  Hanya kategori baku yang dapat disinkronkan ke dataset.
                </p>
              </div>

              <div className="space-y-2">
                <Label htmlFor="admin-notes">Catatan Administrator</Label>
                <textarea
                  id="admin-notes"
                  rows={3}
                  className="w-full rounded-md border bg-background px-3 py-2 text-sm"
                  placeholder="Tambahkan catatan verifikasi atau alasan status peninjauan…"
                  value={editAdminNotes}
                  onChange={(e) => setEditAdminNotes(e.target.value)}
                />
              </div>
            </div>
          )}

          <DialogFooter className="mt-4 gap-2">
            <Button variant="outline" disabled={actionBusy} onClick={() => setDialogMode(null)}>
              Batal
            </Button>
            <Button disabled={actionBusy} onClick={() => void handleSaveReview()}>
              {actionBusy ? "Menyimpan…" : "Simpan Perubahan"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Dialog Konfirmasi Sinkronisasi Dataset */}
      <Dialog open={dialogMode === "sync"} onOpenChange={(open) => !open && setDialogMode(null)}>
        <DialogContent className="max-w-md">
          <DialogTitle className="flex items-center gap-2 text-blue-600 dark:text-blue-400">
            <Layers className="size-5" />
            Integrasikan ke Dataset Aktif
          </DialogTitle>
          <DialogDescription>
            Tindakan ini akan menyetujui laporan dan menambahkan URL ini sebagai baris data baru ke
            dataset aktif untuk bahan pelatihan model SVM.
          </DialogDescription>

          {selectedReport && (
            <div className="rounded-lg border bg-muted/40 p-3 text-xs space-y-1">
              <div>
                <span className="text-muted-foreground">URL: </span>
                <span className="font-mono font-medium">{selectedReport.url}</span>
              </div>
              <div>
                <span className="text-muted-foreground">Kategori Target: </span>
                <span className="font-medium text-primary">{selectedReport.reported_category}</span>
              </div>
            </div>
          )}

          <DialogFooter className="mt-4 gap-2">
            <Button variant="outline" disabled={actionBusy} onClick={() => setDialogMode(null)}>
              Batal
            </Button>
            <Button
              className="bg-blue-600 hover:bg-blue-700 text-white"
              disabled={actionBusy}
              onClick={() => void handleSyncDataset()}
            >
              {actionBusy ? "Menyinkronkan…" : "Setujui & Sinkronkan"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Dialog Konfirmasi Hapus */}
      <Dialog open={dialogMode === "delete"} onOpenChange={(open) => !open && setDialogMode(null)}>
        <DialogContent className="max-w-sm">
          <DialogTitle className="text-destructive flex items-center gap-2">
            <AlertCircle className="size-5" />
            Hapus Laporan?
          </DialogTitle>
          <DialogDescription>
            Laporan untuk URL ini akan dihapus permanen dari sistem.
          </DialogDescription>

          <DialogFooter className="mt-4 gap-2">
            <Button variant="outline" disabled={actionBusy} onClick={() => setDialogMode(null)}>
              Batal
            </Button>
            <Button
              variant="destructive"
              disabled={actionBusy}
              onClick={() => void handleDeleteReport()}
            >
              {actionBusy ? "Menghapus…" : "Hapus"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
