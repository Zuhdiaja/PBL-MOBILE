/* oxlint-disable react/set-state-in-effect -- Loading state synchronizes with asynchronous server pagination. */
/* oxlint-disable jsx-a11y/no-noninteractive-tabindex -- Scrollable data region must be keyboard reachable. */
"use client";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import {
  Database,
  Upload,
  FileSpreadsheet,
  ChevronLeft,
  ChevronRight,
  ChevronsLeft,
  ChevronsRight,
  CheckCircle2,
} from "lucide-react";
import { useTable, tableFeatures, rowPaginationFeature, flexRender } from "@tanstack/react-table";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from "@/components/ui/dialog";
import { Badge } from "@/components/ui/badge";
import {
  Table,
  TableHeader,
  TableBody,
  TableRow,
  TableHead,
  TableCell,
} from "@/components/ui/table";
import { Label } from "@/components/ui/label";
import { useAuth } from "@/components/admin-shell";
import { ErrorNotice, Loading } from "@/components/feedback";
import {
  api,
  ApiError,
  messageOf,
  number,
  type DatasetResponse,
  type Dataset,
  type ImportJob,
  type RowsResponse,
  type DataRow,
} from "@/lib/api";
const features = tableFeatures({ rowPaginationFeature });
const emptyRows: DataRow[] = [];
function DatasetTable({
  dataset,
  result,
  page,
  size,
  onPage,
  busy,
}: {
  dataset: Dataset;
  result: RowsResponse;
  page: number;
  size: number;
  onPage: (page: number, size: number) => void;
  busy: boolean;
}) {
  const columns = useMemo(
    () => [
      { id: "number", header: "No.", accessorFn: (row: DataRow) => row.row_number },
      ...dataset.columns.map((name, index) => ({
        id: `column-${index}`,
        header: name || `Kolom ${index + 1}`,
        accessorFn: (row: DataRow) => row.values[index],
      })),
    ],
    [dataset.columns],
  );
  const table = useTable({
    features,
    columns,
    data: result.rows || emptyRows,
    manualPagination: true,
    rowCount: result.row_count,
    state: { pagination: { pageIndex: page - 1, pageSize: size } },
    onPaginationChange: (updater) => {
      const next =
        typeof updater === "function" ? updater({ pageIndex: page - 1, pageSize: size }) : updater;
      onPage(next.pageIndex + 1, next.pageSize);
    },
  });
  return (
    <section className="data-section" aria-label="Data CSV">
      <div className="table-toolbar">
        <div>
          <h2>Data dataset</h2>
          <p>Nilai asli dari file CSV.</p>
        </div>
        <Badge variant="outline">{number.format(dataset.row_count)} baris</Badge>
      </div>
      <section
        className="table-scroll"
        tabIndex={0}
        aria-label="Tabel dataset, gulir untuk melihat semua kolom"
        aria-busy={busy}
      >
        <Table>
          <caption className="sr-only">
            {dataset.filename}, halaman {page} dari {result.page_count}
          </caption>
          <TableHeader>
            {table.getHeaderGroups().map((group) => (
              <TableRow key={group.id}>
                {group.headers.map((header) => (
                  <TableHead scope="col" key={header.id}>
                    {flexRender(header.column.columnDef.header, header.getContext())}
                  </TableHead>
                ))}
              </TableRow>
            ))}
          </TableHeader>
          <TableBody>
            {table.getRowModel().rows.map((row) => (
              <TableRow key={row.id}>
                {row.getAllCells().map((cell) => (
                  <TableCell key={cell.id}>{String(cell.getValue() ?? "")}</TableCell>
                ))}
              </TableRow>
            ))}
          </TableBody>
        </Table>
        {result.rows.length === 0 && (
          <p className="table-empty">CSV ini hanya berisi header; tidak ada baris data.</p>
        )}
      </section>
      <div className="pagination">
        <p>
          {result.row_count
            ? `${number.format((page - 1) * size + 1)}–${number.format(Math.min(page * size, result.row_count))} dari ${number.format(result.row_count)} baris`
            : "0 baris"}
        </p>
        <div className="pagination-controls">
          <Label htmlFor="page-size">Baris per halaman</Label>
          <select
            id="page-size"
            value={size}
            disabled={busy}
            onChange={(e) => onPage(1, Number(e.target.value))}
          >
            {[25, 50, 100].map((n) => (
              <option key={n} value={n}>
                {n}
              </option>
            ))}
          </select>
          <span className="page-indicator">
            {page} / {result.page_count}
          </span>
          <Button
            variant="outline"
            size="icon"
            aria-label="Halaman pertama"
            disabled={busy || !table.getCanPreviousPage()}
            onClick={() => table.firstPage()}
          >
            <ChevronsLeft />
          </Button>
          <Button
            variant="outline"
            size="icon"
            aria-label="Halaman sebelumnya"
            disabled={busy || !table.getCanPreviousPage()}
            onClick={() => table.previousPage()}
          >
            <ChevronLeft />
          </Button>
          <Button
            variant="outline"
            size="icon"
            aria-label="Halaman berikutnya"
            disabled={busy || !table.getCanNextPage()}
            onClick={() => table.nextPage()}
          >
            <ChevronRight />
          </Button>
          <Button
            variant="outline"
            size="icon"
            aria-label="Halaman terakhir"
            disabled={busy || !table.getCanNextPage()}
            onClick={() => table.lastPage()}
          >
            <ChevronsRight />
          </Button>
        </div>
      </div>
    </section>
  );
}
export default function Page() {
  const { maxUpload } = useAuth();
  const params = useSearchParams();
  const router = useRouter();
  const rawPage = Number(params.get("page") || 1);
  const page = Number.isSafeInteger(rawPage) && rawPage > 0 ? rawPage : 1;
  const rawSize = Number(params.get("page_size") || 25);
  const size = [25, 50, 100].includes(rawSize) ? rawSize : 25;
  const [meta, setMeta] = useState<DatasetResponse | null>(null);
  const [result, setResult] = useState<RowsResponse | null>(null);
  const [error, setError] = useState("");
  const [rowError, setRowError] = useState("");
  const [loading, setLoading] = useState(true);
  const [retry, setRetry] = useState(0);
  const [open, setOpen] = useState(false);
  const [file, setFile] = useState<File | null>(null);
  const [uploadError, setUploadError] = useState("");
  const [uploading, setUploading] = useState(false);
  const [notice, setNotice] = useState("");
  const paramsRef = useRef(params);
  useEffect(() => {
    paramsRef.current = params;
  }, [params]);
  const previousId = useRef<string | null>(null);
  const mounted = useRef(true);
  const selectPage = useCallback(
    (next: number, nextSize: number, id?: string) => {
      const query = new URLSearchParams(paramsRef.current.toString());
      query.set("page", String(next));
      query.set("page_size", String(nextSize));
      if (id) query.set("dataset_id", id);
      router.replace(`/datasets?${query}`, { scroll: false });
    },
    [router],
  );
  const loadMeta = useCallback(async () => {
    try {
      const data = await api<DatasetResponse>("/dataset");
      if (!mounted.current) return;
      const id = data.dataset?.id;
      const known = previousId.current || paramsRef.current.get("dataset_id");
      if (id && known && known !== id) {
        setResult(null);
        selectPage(1, Number(paramsRef.current.get("page_size") || 25), id);
        setNotice("Dataset aktif diperbarui. Anda kembali ke halaman pertama.");
      } else if (id && !paramsRef.current.get("dataset_id")) {
        selectPage(
          Number(paramsRef.current.get("page") || 1),
          Number(paramsRef.current.get("page_size") || 25),
          id,
        );
      }
      previousId.current = id || null;
      setMeta((current) =>
        JSON.stringify(current) === JSON.stringify(data)
          ? current
          : {
              ...data,
              dataset:
                current?.dataset?.id === data.dataset?.id ? current?.dataset || null : data.dataset,
            },
      );
      setError("");
    } catch (e) {
      if (mounted.current) setError(messageOf(e));
    }
  }, [selectPage]);
  const job = meta?.latest_import;
  const importing = job?.status === "queued" || job?.status === "running";
  useEffect(() => {
    mounted.current = true;
    void loadMeta();
    const timer = setInterval(() => void loadMeta(), importing ? 1500 : 10000);
    const refresh = () => void loadMeta();
    window.addEventListener("focus", refresh);
    return () => {
      mounted.current = false;
      clearInterval(timer);
      window.removeEventListener("focus", refresh);
    };
  }, [loadMeta, importing]);
  const dataset = meta?.dataset;
  useEffect(() => {
    if (!dataset) return;
    const controller = new AbortController();
    setLoading(true);
    setRowError("");
    void api<RowsResponse>(
      `/dataset/rows?dataset_id=${dataset.id}&page=${page}&page_size=${size}`,
      { signal: controller.signal },
    )
      .then((data) => {
        if (!controller.signal.aborted) setResult(data);
      })
      .catch((e) => {
        if (controller.signal.aborted) return;
        if (e instanceof ApiError && e.code === "dataset_changed") {
          void loadMeta();
        } else if (e instanceof ApiError && e.code === "invalid_pagination" && page > 1)
          selectPage(1, size, dataset.id);
        else setRowError(messageOf(e));
      })
      .finally(() => {
        if (!controller.signal.aborted) setLoading(false);
      });
    return () => controller.abort();
  }, [dataset, page, size, retry, loadMeta, selectPage]);
  function beginUpload() {
    setFile(null);
    setUploadError("");
    setOpen(true);
  }
  async function upload() {
    if (!file) return;
    setUploading(true);
    setUploadError("");
    const form = new FormData();
    form.append("file", file);
    try {
      const data = await api<{ import_job: ImportJob }>("/dataset/imports", {
        method: "POST",
        body: form,
      });
      setMeta((current) => ({ dataset: current?.dataset || null, latest_import: data.import_job }));
      setOpen(false);
      setFile(null);
      setNotice("");
    } catch (e) {
      setUploadError(messageOf(e));
      void loadMeta();
    } finally {
      setUploading(false);
    }
  }
  return (
    <>
      <div className="page-heading">
        <div>
          <h1>Dataset</h1>
          <p>Unggah dan lihat data URL yang digunakan LinkGuard.</p>
        </div>
        <Button onClick={beginUpload} disabled={importing || uploading}>
          <Upload />
          Unggah dataset
        </Button>
      </div>
      {notice && (
        <div className="success-notice" aria-live="polite">
          <CheckCircle2 size={18} />
          <p>{notice}</p>
          <Button variant="ghost" aria-label="Tutup pemberitahuan" onClick={() => setNotice("")}>
            Tutup
          </Button>
        </div>
      )}
      {error && <ErrorNotice message={error} retry={() => void loadMeta()} />}
      {importing && (
        <div className="import-status" aria-live="polite">
          <FileSpreadsheet size={21} />
          <div>
            <strong>{job?.status === "queued" ? "Menunggu worker" : "Mengimpor dataset"}</strong>
            <p>
              {job?.filename} · {number.format(job?.row_count || 0)} baris diproses. Dataset
              sebelumnya tetap tersedia sampai impor selesai.
            </p>
          </div>
          <span className="status-dot" />
        </div>
      )}
      {job?.status === "failed" && (
        <ErrorNotice
          message={`${job.filename}: ${job.error || "Impor gagal. Silakan unggah kembali."}`}
        />
      )}
      {!meta ? (
        !error && <Loading />
      ) : dataset ? (
        <>
          <div className="dataset-meta">
            <div className="file-icon">
              <FileSpreadsheet size={24} />
            </div>
            <div className="dataset-file">
              <h2>{dataset.filename}</h2>
              <Badge className="active-label" variant="secondary">
                <span className="active-dot" />
                Dataset aktif
              </Badge>
            </div>
            <dl>
              <div>
                <dt>Jumlah baris</dt>
                <dd>{number.format(dataset.row_count)}</dd>
              </div>
              <div>
                <dt>Waktu unggah</dt>
                <dd>
                  {new Intl.DateTimeFormat("id-ID", {
                    dateStyle: "medium",
                    timeStyle: "short",
                  }).format(new Date(dataset.uploaded_at))}
                </dd>
              </div>
            </dl>
          </div>
          {rowError ? (
            <ErrorNotice message={rowError} retry={() => setRetry((n) => n + 1)} />
          ) : loading ||
            !result ||
            result.dataset_id !== dataset.id ||
            result.page !== page ||
            result.page_size !== size ? (
            <Loading text="Memuat halaman dataset…" />
          ) : (
            <DatasetTable
              dataset={dataset}
              result={result}
              page={page}
              size={size}
              onPage={(p, s) => selectPage(p, s, dataset.id)}
              busy={loading}
            />
          )}
        </>
      ) : (
        <section className="empty-state">
          <Database size={38} strokeWidth={1.5} />
          <h2>Belum ada dataset</h2>
          <p>
            Mulai dengan mengunggah file CSV UTF-8. Kolom dan nilai akan ditampilkan sesuai isi
            file.
          </p>
          <Button onClick={beginUpload} disabled={importing}>
            <Upload />
            Unggah dataset
          </Button>
          <span>Maksimal {number.format(maxUpload / 1024 / 1024)} MB · CSV UTF-8</span>
        </section>
      )}
      <p className="dataset-footnote">
        Nilai dan duplikat dipertahankan. URL ditampilkan sebagai teks.
      </p>
      <Dialog
        open={open}
        onOpenChange={(value) => {
          if (!uploading) setOpen(value);
        }}
      >
        <DialogContent className="upload-dialog" aria-busy={uploading} showCloseButton={!uploading}>
          <DialogTitle>Unggah dataset</DialogTitle>
          <DialogDescription>
            {dataset ? (
              <>
                Dataset aktif <strong>{dataset.filename}</strong> akan diganti setelah impor baru
                berhasil. Jika impor gagal, dataset aktif tetap tersedia.
              </>
            ) : (
              "Pilih file CSV UTF-8 untuk menjadi dataset aktif."
            )}
          </DialogDescription>
          <div className="field">
            <Label htmlFor="csv-file">File CSV</Label>
            <input
              id="csv-file"
              aria-describedby="csv-file-help"
              type="file"
              accept=".csv,text/csv"
              disabled={uploading}
              onChange={(event) => {
                const next = event.target.files?.[0] || null;
                setUploadError("");
                if (
                  next &&
                  (next.size > maxUpload ||
                    !next.name.toLowerCase().endsWith(".csv") ||
                    next.size === 0)
                ) {
                  setFile(null);
                  setUploadError(
                    `Gunakan file CSV yang tidak kosong, maksimal ${number.format(maxUpload / 1024 / 1024)} MB.`,
                  );
                } else setFile(next);
              }}
            />
            <p className="help-text" id="csv-file-help">
              CSV UTF-8, termasuk BOM. Maksimal {number.format(maxUpload / 1024 / 1024)} MB.
            </p>
          </div>
          {file && (
            <p className="selected-file">
              {file.name} ·{" "}
              {file.size < 1024 * 1024
                ? `${number.format(Math.max(1, Math.ceil(file.size / 1024)))} KB`
                : `${number.format(file.size / 1024 / 1024)} MB`}
            </p>
          )}
          {uploadError && <ErrorNotice message={uploadError} />}
          <DialogFooter>
            <Button variant="outline" disabled={uploading} onClick={() => setOpen(false)}>
              Batal
            </Button>
            <Button disabled={!file || uploading} onClick={() => void upload()}>
              {uploading ? "Mengunggah…" : dataset ? "Unggah dan ganti dataset" : "Mulai impor"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
