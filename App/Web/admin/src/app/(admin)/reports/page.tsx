/* oxlint-disable react/set-state-in-effect -- Synchronize reports with URL query params and async server mutations. */
/* oxlint-disable jsx-a11y/no-noninteractive-tabindex -- Scrollable table must be keyboard reachable. */
"use client";
import { useCallback, useEffect, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import {
  Flag,
  CheckCircle2,
  AlertCircle,
  Search,
  ChevronLeft,
  ChevronRight,
  Pencil,
  Trash2,
  Layers,
  ArrowRightCircle,
  MoreHorizontal,
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
  DialogHeader,
} from "@/components/ui/dialog";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuGroup,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
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

function canSync(report: PredictionReport) {
  return !report.dataset_synced && report.status !== "rejected";
}

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
  const [actionError, setActionError] = useState("");
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
    setActionError("");
    setSelectedReport(report);
    setEditStatus(report.status);
    setEditCategory(report.reported_category);
    setEditAdminNotes(report.admin_notes || "");
    setDialogMode("review");
  }

  function openSyncDialog(report: PredictionReport) {
    setActionError("");
    setSelectedReport(report);
    setDialogMode("sync");
  }

  function openDeleteDialog(report: PredictionReport) {
    setActionError("");
    setSelectedReport(report);
    setDialogMode("delete");
  }

  async function runReportAction(path: string, method: string, body?: string) {
    setActionBusy(true);
    setActionError("");
    try {
      const result = await api<{ message: string }>(path, { method, body });
      setSuccess(result.message);
      setDialogMode(null);
      void fetchReports();
    } catch (cause) {
      setActionError(messageOf(cause));
    } finally {
      setActionBusy(false);
    }
  }

  function handleSaveReview() {
    if (!selectedReport) return;
    return runReportAction(
      `/reports/${selectedReport.id}`,
      "PATCH",
      JSON.stringify({
        status: editStatus,
        reported_category: editCategory,
        admin_notes: editAdminNotes,
      }),
    );
  }

  function handleSyncDataset() {
    if (!selectedReport) return;
    return runReportAction(`/reports/${selectedReport.id}/sync-dataset`, "POST");
  }

  function handleDeleteReport() {
    if (!selectedReport) return;
    return runReportAction(`/reports/${selectedReport.id}`, "DELETE");
  }

  return (
    <div className="space-y-6">
      <div className="page-heading">
        <div>
          <h1>Manajemen Laporan</h1>
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

      <dl className="grid grid-cols-2 gap-px overflow-hidden rounded-xl border bg-border md:grid-cols-4">
        {[
          ["Total laporan", summary.total],
          ["Perlu ditinjau", summary.submitted + summary.review],
          ["Selesai", summary.completed],
          ["Tersinkron", summary.synced],
        ].map(([label, count]) => (
          <div key={label} className="grid gap-1 bg-card px-4 py-3">
            <dt className="text-xs text-muted-foreground">{label}</dt>
            <dd className="text-xl font-semibold tabular-nums">{number.format(Number(count))}</dd>
          </div>
        ))}
      </dl>

      {/* Filter and Search Bar */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <Tabs
          value={currentTab}
          onValueChange={(val) => updateQuery(val, 1)}
          className="w-full sm:w-auto"
        >
          <TabsList
            aria-label="Status laporan"
            className="grid h-auto! min-h-11 w-full grid-cols-3 gap-1 min-[380px]:grid-cols-5 sm:w-auto [&>button]:min-h-11 [&>button]:text-xs sm:[&>button]:text-sm"
          >
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
              aria-label="Cari URL atau catatan laporan"
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
          <div className="overflow-x-auto">
            <Table className="max-xl:table-fixed">
              <caption className="sr-only">Daftar laporan prediksi</caption>
              <TableHeader>
                <TableRow>
                  <TableHead className="hidden w-12 xl:table-cell">No</TableHead>
                  <TableHead>URL Tautan</TableHead>
                  <TableHead className="hidden xl:table-cell">Jenis Koreksi</TableHead>
                  <TableHead className="hidden xl:table-cell">Kategori Dilaporkan</TableHead>
                  <TableHead className="hidden xl:table-cell">Status</TableHead>
                  <TableHead className="hidden xl:table-cell">Integrasi Dataset</TableHead>
                  <TableHead className="hidden xl:table-cell">Tanggal</TableHead>
                  <TableHead className="w-16 text-right xl:w-auto">Aksi</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {reports.map((report, idx) => {
                  const kind =
                    report.report_type === "False Positive" ? "Positif Palsu" : "Negatif Palsu";
                  const status = (
                    <Badge
                      variant="secondary"
                      className={
                        report.status === "submitted"
                          ? "bg-warning-surface text-warning"
                          : report.status === "review"
                            ? "bg-primary/10 text-primary"
                            : undefined
                      }
                    >
                      {statusLabels[report.status]}
                    </Badge>
                  );
                  const date = report.created_at
                    ? new Date(report.created_at).toLocaleDateString("id-ID", {
                        day: "numeric",
                        month: "short",
                        year: "numeric",
                      })
                    : "—";
                  return (
                    <TableRow key={report.id}>
                      <TableCell className="hidden font-mono text-xs text-muted-foreground xl:table-cell">
                        {(currentPage - 1) * currentPageSize + idx + 1}
                      </TableCell>
                      <TableCell className="max-w-xs align-top whitespace-normal xl:whitespace-nowrap">
                        <p className="truncate font-mono text-xs font-medium" title={report.url}>
                          {report.url}
                        </p>
                        <div className="mt-2 grid gap-1 xl:hidden">
                          <div className="flex flex-wrap items-center gap-1.5">
                            {status}
                            <span className="text-xs text-muted-foreground">
                              {report.reported_category} · {kind}
                            </span>
                          </div>
                          <p className="text-xs text-muted-foreground">
                            {date} · {report.dataset_synced ? "Tersinkron" : "Belum tersinkron"}
                          </p>
                        </div>
                      </TableCell>
                      <TableCell className="hidden xl:table-cell">
                        <Badge
                          variant="secondary"
                          className={
                            report.report_type === "False Positive"
                              ? "bg-warning-surface text-warning"
                              : "text-destructive"
                          }
                        >
                          {kind}
                        </Badge>
                      </TableCell>
                      <TableCell className="hidden xl:table-cell">
                        <Badge variant="outline" className="font-normal">
                          {report.reported_category}
                        </Badge>
                      </TableCell>
                      <TableCell className="hidden xl:table-cell">{status}</TableCell>
                      <TableCell className="hidden text-xs text-muted-foreground xl:table-cell">
                        {report.dataset_synced ? "Tersinkron" : "Belum"}
                      </TableCell>
                      <TableCell className="hidden text-xs text-muted-foreground xl:table-cell">
                        {date}
                      </TableCell>
                      <TableCell className="text-right align-top xl:align-middle">
                        <div className="xl:hidden">
                          <DropdownMenu>
                            <DropdownMenuTrigger
                              render={
                                <Button
                                  variant="outline"
                                  size="icon"
                                  className="size-11"
                                  aria-label={`Aksi laporan untuk ${report.url}`}
                                />
                              }
                            >
                              <MoreHorizontal aria-hidden="true" />
                            </DropdownMenuTrigger>
                            <DropdownMenuContent align="end">
                              <DropdownMenuGroup>
                                <DropdownMenuItem onClick={() => openReviewDialog(report)}>
                                  <Pencil aria-hidden="true" /> Tinjau laporan
                                </DropdownMenuItem>
                                {canSync(report) && (
                                  <DropdownMenuItem onClick={() => openSyncDialog(report)}>
                                    <ArrowRightCircle aria-hidden="true" /> Sinkronkan ke Dataset
                                  </DropdownMenuItem>
                                )}
                                <DropdownMenuItem
                                  variant="destructive"
                                  onClick={() => openDeleteDialog(report)}
                                >
                                  <Trash2 aria-hidden="true" /> Hapus laporan
                                </DropdownMenuItem>
                              </DropdownMenuGroup>
                            </DropdownMenuContent>
                          </DropdownMenu>
                        </div>
                        <div className="hidden items-center justify-end gap-1 xl:flex">
                          {canSync(report) && (
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
                  );
                })}
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
      <Dialog
        open={dialogMode === "review"}
        onOpenChange={(open) => !open && !actionBusy && setDialogMode(null)}
      >
        <DialogContent
          className="max-w-lg grid-rows-[auto_minmax(0,1fr)_auto] overflow-hidden"
          aria-busy={actionBusy}
          showCloseButton={!actionBusy}
        >
          <DialogHeader className="pr-10">
            <DialogTitle>Tinjau Laporan Prediksi</DialogTitle>
            <DialogDescription>Periksa klaim pengguna dan perbarui statusnya.</DialogDescription>
          </DialogHeader>

          {selectedReport && (
            <section
              className="min-h-0 space-y-4 overflow-y-auto overscroll-contain p-1 text-sm"
              aria-label="Detail dan formulir peninjauan"
              tabIndex={0}
            >
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
                    <span className="font-medium break-all">
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
                {selectedReport.status === "rejected" && !selectedReport.dataset_synced && (
                  <p id="report-review-required" className="text-xs text-muted-foreground">
                    Ubah status menjadi Ditinjau dan simpan sebelum menyinkronkan laporan ini.
                  </p>
                )}
                <select
                  id="status"
                  aria-describedby={
                    selectedReport.status === "rejected" && !selectedReport.dataset_synced
                      ? "report-review-required"
                      : undefined
                  }
                  className="w-full rounded-md border bg-background px-3 py-2 text-sm"
                  value={editStatus}
                  disabled={selectedReport.dataset_synced}
                  onChange={(e) => setEditStatus(e.target.value as ReportStageStatus)}
                >
                  <option value="submitted">Diproses</option>
                  <option value="review">Ditinjau</option>
                  {selectedReport.status === "completed" && (
                    <option value="completed">Selesai</option>
                  )}
                  <option value="rejected">Ditolak</option>
                </select>
              </div>

              <div className="space-y-2">
                <Label htmlFor="category">Kategori Verifikasi</Label>
                <select
                  id="category"
                  className="w-full rounded-md border bg-background px-3 py-2 text-sm"
                  value={editCategory}
                  disabled={selectedReport.dataset_synced}
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
            </section>
          )}

          <DialogFooter className="flex-col!">
            {actionError && <ErrorNotice message={actionError} />}
            <div className="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
              <Button variant="outline" disabled={actionBusy} onClick={() => setDialogMode(null)}>
                Batal
              </Button>
              <Button disabled={actionBusy} onClick={() => void handleSaveReview()}>
                {actionBusy ? "Menyimpan…" : "Simpan Perubahan"}
              </Button>
            </div>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Dialog Konfirmasi Sinkronisasi Dataset */}
      <Dialog
        open={dialogMode === "sync"}
        onOpenChange={(open) => !open && !actionBusy && setDialogMode(null)}
      >
        <DialogContent className="max-w-md" aria-busy={actionBusy} showCloseButton={!actionBusy}>
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
                <span className="font-mono font-medium break-all">{selectedReport.url}</span>
              </div>
              <div>
                <span className="text-muted-foreground">Kategori Target: </span>
                <span className="font-medium text-primary">{selectedReport.reported_category}</span>
              </div>
            </div>
          )}

          {actionError && <ErrorNotice message={actionError} />}
          <DialogFooter className="mt-4 gap-2">
            <Button variant="outline" disabled={actionBusy} onClick={() => setDialogMode(null)}>
              Batal
            </Button>
            <Button disabled={actionBusy} onClick={() => void handleSyncDataset()}>
              {actionBusy ? "Menyinkronkan…" : "Setujui & Sinkronkan"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Dialog Konfirmasi Hapus */}
      <Dialog
        open={dialogMode === "delete"}
        onOpenChange={(open) => !open && !actionBusy && setDialogMode(null)}
      >
        <DialogContent className="max-w-sm" aria-busy={actionBusy} showCloseButton={!actionBusy}>
          <DialogTitle className="text-destructive flex items-center gap-2">
            <AlertCircle className="size-5" />
            Hapus Laporan?
          </DialogTitle>
          <DialogDescription>
            Laporan untuk URL ini akan dihapus permanen dari sistem.
          </DialogDescription>

          {actionError && <ErrorNotice message={actionError} />}
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
