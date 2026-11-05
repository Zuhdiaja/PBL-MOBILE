/* oxlint-disable react/set-state-in-effect -- Synchronize the dashboard with async API data. */
/* oxlint-disable jsx-a11y/no-noninteractive-tabindex -- Scrollable tables must be keyboard reachable. */
"use client";
import { useCallback, useEffect, useState, type FormEvent } from "react";
import {
  AlertTriangle,
  BrainCircuit,
  CheckCircle2,
  Database,
  FileJson,
  Gauge,
  Layers,
  Play,
  ScanSearch,
  Upload,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogTitle,
} from "@/components/ui/dialog";
import { ErrorNotice, Loading } from "@/components/feedback";
import {
  ApiError,
  api,
  messageOf,
  number,
  percent,
  type MLDatasetSummary,
  type MLMetrics,
  type MLPreviewResponse,
  type MLReport,
  type MLRunDetail,
  type MLRunSummary,
  type MLRunsResponse,
} from "@/lib/api";

const stepLabels: Record<string, string> = {
  trim: "Trim spasi/kontrol",
  lowercase_scheme: "Scheme huruf kecil",
  lowercase_host: "Host huruf kecil",
  percent_decode: "Percent-decode",
  strip_root_dot: "Hapus titik akhir",
  idna: "IDNA/punycode",
  ip_literal: "Deteksi IP",
};

const tfidfParameters = [
  ["analyzer", "char"],
  ["ngram_range", "(3, 5)"],
  ["lowercase", "false"],
  ["min_df", "2"],
  ["max_features", "75.000"],
  ["sublinear_tf", "true"],
  ["norm", "l2"],
];

const trainingParameters = [
  ["C", "C"],
  ["class_weight", "class_weight"],
  ["dual", "dual"],
  ["tol", "tol"],
  ["max_iter", "max_iter"],
  ["random_state", "random_state"],
  ["seed", "seed"],
];

function MetricGroup({ title, metrics }: { title: string; metrics: MLMetrics }) {
  const values = [
    ["Accuracy", metrics.accuracy],
    ["Balanced accuracy", metrics.balanced_accuracy],
    ["Macro F1", metrics.macro_f1],
    ["Weighted F1", metrics.weighted_f1],
  ] as const;
  return (
    <div className="rounded-xl border bg-card p-4 shadow-xs">
      <p className="text-xs font-medium text-muted-foreground">{title}</p>
      <div className="mt-3 grid grid-cols-2 gap-3">
        {values.map(([label, value]) => (
          <div key={label}>
            <p className="text-[11px] text-muted-foreground">{label}</p>
            <p className="text-lg font-semibold tabular-nums">{percent.format(value)}</p>
          </div>
        ))}
      </div>
    </div>
  );
}

function SplitBar({ split }: { split: { train: number; validation: number; test: number } }) {
  const total = split.train + split.validation + split.test || 1;
  const parts = [
    { label: "Train", value: split.train, className: "bg-blue-500" },
    { label: "Validation", value: split.validation, className: "bg-amber-500" },
    { label: "Test", value: split.test, className: "bg-emerald-500" },
  ];
  return (
    <div>
      <div className="flex h-4 overflow-hidden rounded-full bg-muted" aria-hidden="true">
        {parts.map((part) => (
          <span
            key={part.label}
            className={part.className}
            style={{ width: `${(part.value / total) * 100}%` }}
          />
        ))}
      </div>
      <div className="mt-3 grid grid-cols-1 gap-2 text-xs sm:grid-cols-3">
        {parts.map((part) => (
          <div key={part.label} className="flex items-center gap-2">
            <span className={`size-2.5 rounded-full ${part.className}`} aria-hidden="true" />
            <span className="text-muted-foreground">{part.label}</span>
            <span className="ml-auto font-medium tabular-nums sm:ml-0">
              {number.format(part.value)} ({percent.format(part.value / total)})
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}

function ClassBars({ summary }: { summary: MLDatasetSummary }) {
  const max = Math.max(...summary.class_counts.map((item) => item.count), 1);
  if (!summary.class_counts.length) {
    return (
      <p className="text-sm text-muted-foreground">
        Dataset aktif tidak memiliki kolom label yang dapat dihitung.
      </p>
    );
  }
  return (
    <div className="space-y-3">
      {summary.class_counts.map((item) => (
        <div key={item.label}>
          <div className="mb-1 flex items-center justify-between gap-3 text-xs">
            <span className="font-medium">{item.label}</span>
            <span className="tabular-nums text-muted-foreground">{number.format(item.count)}</span>
          </div>
          <div className="h-2 overflow-hidden rounded-full bg-muted">
            <div
              className="h-full rounded-full bg-primary/75"
              style={{ width: `${Math.max((item.count / max) * 100, item.count ? 2 : 0)}%` }}
            />
          </div>
        </div>
      ))}
    </div>
  );
}

function NgramChips({ preview }: { preview: MLPreviewResponse }) {
  const sizes = ["3", "4", "5"] as const;
  const hasTokens = sizes.some((size) => preview.ngrams[size].length > 0);
  if (!hasTokens) {
    return <p className="text-sm text-muted-foreground">URL terlalu pendek untuk n-gram 3–5.</p>;
  }
  return (
    <div className="space-y-4">
      {sizes.map((size) => (
        <div key={size}>
          <p className="mb-2 text-xs font-medium text-muted-foreground">N-gram {size} karakter</p>
          {preview.ngrams[size].length ? (
            <div className="flex flex-wrap gap-2">
              {preview.ngrams[size].map((item) => (
                <span
                  key={`${size}-${item.token}`}
                  className="rounded-full border bg-muted/60 px-2.5 py-1 font-mono text-xs"
                >
                  {item.token}
                  <span className="ml-1.5 text-muted-foreground">×{item.count}</span>
                </span>
              ))}
            </div>
          ) : (
            <p className="text-xs text-muted-foreground">Tidak ada token.</p>
          )}
        </div>
      ))}
    </div>
  );
}

function ReportTable({ report }: { report: MLReport }) {
  const rows = Object.entries(report);
  return (
    <div className="table-scroll" tabIndex={0}>
      <table>
        <thead>
          <tr>
            <th>Kelas</th>
            <th>Precision</th>
            <th>Recall</th>
            <th>F1</th>
            <th>Support</th>
          </tr>
        </thead>
        <tbody>
          {rows.map(([label, row]) => (
            <tr key={label}>
              <td className="font-medium">{label}</td>
              <td className="tabular-nums">{percent.format(row.precision)}</td>
              <td className="tabular-nums">{percent.format(row.recall)}</td>
              <td className="tabular-nums">{percent.format(row["f1-score"])}</td>
              <td className="tabular-nums">{number.format(row.support)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function ConfusionMatrix({
  detail,
  mode,
  onModeChange,
}: {
  detail: MLRunDetail;
  mode: "count" | "recall";
  onModeChange: (mode: "count" | "recall") => void;
}) {
  const classes = detail.classes;
  const matrix = detail.confusion_matrix;
  const rowTotals = matrix.map((row) => row.reduce((sum, value) => sum + value, 0));
  const max = Math.max(...matrix.flat(), 1);
  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <p className="text-xs text-muted-foreground">
          Baris = kelas aktual, kolom = kelas prediksi.
        </p>
        <div className="flex gap-2">
          <Button
            type="button"
            size="sm"
            variant={mode === "count" ? "default" : "outline"}
            aria-pressed={mode === "count"}
            onClick={() => onModeChange("count")}
          >
            Jumlah
          </Button>
          <Button
            type="button"
            size="sm"
            variant={mode === "recall" ? "default" : "outline"}
            aria-pressed={mode === "recall"}
            onClick={() => onModeChange("recall")}
          >
            Recall per kelas
          </Button>
        </div>
      </div>
      <div className="table-scroll pb-2" tabIndex={0}>
        <div
          className="grid min-w-[640px] gap-1 text-xs"
          style={{
            gridTemplateColumns: `minmax(130px, 1.4fr) repeat(${classes.length}, minmax(58px, 1fr))`,
          }}
        >
          <div />
          {classes.map((label) => (
            <div
              key={`head-${label}`}
              className="truncate px-2 py-1 text-center font-medium text-muted-foreground"
            >
              {label}
            </div>
          ))}
          {matrix.map((row, rowIndex) => (
            <div key={`row-${classes[rowIndex]}`} className="contents">
              <div className="truncate px-2 py-1 font-medium">{classes[rowIndex]}</div>
              {row.map((value, columnIndex) => {
                const ratio = rowTotals[rowIndex] ? value / rowTotals[rowIndex] : 0;
                const intensity = mode === "recall" ? ratio : value / max;
                return (
                  <div
                    key={`cell-${classes[rowIndex]}-${classes[columnIndex]}`}
                    className="rounded-md border px-1 py-2 text-center tabular-nums"
                    style={{
                      backgroundColor:
                        intensity > 0 ? `rgba(37, 99, 235, ${0.08 + intensity * 0.82})` : undefined,
                      color: intensity > 0.55 ? "#fff" : undefined,
                    }}
                    title={`${classes[rowIndex]} → ${classes[columnIndex]}: ${number.format(value)}`}
                  >
                    {mode === "recall" ? percent.format(ratio) : number.format(value)}
                  </div>
                );
              })}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function DatasetSection({ summary }: { summary: MLDatasetSummary | null }) {
  if (!summary) {
    return (
      <section className="data-section">
        <div className="table-toolbar">
          <div>
            <h2>Distribusi dataset</h2>
            <p>Belum ada dataset aktif yang dapat diringkas.</p>
          </div>
          <Badge variant="outline">Dataset</Badge>
        </div>
      </section>
    );
  }
  return (
    <section className="data-section">
      <div className="table-toolbar">
        <div>
          <h2>Distribusi dataset</h2>
          <p>
            {summary.dataset.filename} · {number.format(summary.dataset.row_count)} baris
          </p>
        </div>
        <Badge variant="outline">{summary.label_column ?? "Tanpa kolom label"}</Badge>
      </div>
      <div className="p-5">
        <ClassBars summary={summary} />
      </div>
    </section>
  );
}

export default function PipelineMLPage() {
  const [runs, setRuns] = useState<MLRunSummary[]>([]);
  const [activeId, setActiveId] = useState<string | null>(null);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [detail, setDetail] = useState<MLRunDetail | null>(null);
  const [datasetSummary, setDatasetSummary] = useState<MLDatasetSummary | null>(null);
  const [loading, setLoading] = useState(true);
  const [detailLoading, setDetailLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [importOpen, setImportOpen] = useState(false);
  const [file, setFile] = useState<File | null>(null);
  const [importBusy, setImportBusy] = useState(false);
  const [importError, setImportError] = useState("");
  const [url, setUrl] = useState("https://bank-login.example.test/verify?user=1");
  const [preview, setPreview] = useState<MLPreviewResponse | null>(null);
  const [previewBusy, setPreviewBusy] = useState(false);
  const [previewError, setPreviewError] = useState("");
  const [matrixMode, setMatrixMode] = useState<"count" | "recall">("count");

  const loadDataset = useCallback(async () => {
    try {
      setDatasetSummary(await api<MLDatasetSummary>("/ml/dataset-summary"));
    } catch (cause) {
      if (cause instanceof ApiError && cause.code === "no_dataset") {
        setDatasetSummary(null);
        return;
      }
      setError(messageOf(cause));
    }
  }, []);

  const loadRuns = useCallback(async (selectId?: string) => {
    setError("");
    try {
      const data = await api<MLRunsResponse>("/ml/runs");
      setRuns(data.items);
      setActiveId(data.active_id);
      setSelectedId(selectId ?? data.active_id ?? data.items[0]?.id ?? null);
    } catch (cause) {
      setError(messageOf(cause));
    }
  }, []);

  useEffect(() => {
    void Promise.all([loadRuns(), loadDataset()]).finally(() => setLoading(false));
  }, [loadRuns, loadDataset]);

  useEffect(() => {
    if (!selectedId) {
      setDetail(null);
      return;
    }
    let cancelled = false;
    setDetailLoading(true);
    api<{ run: MLRunDetail }>(`/ml/runs/${selectedId}`)
      .then((data) => {
        if (!cancelled) setDetail(data.run);
      })
      .catch((cause) => {
        if (!cancelled) setError(messageOf(cause));
      })
      .finally(() => {
        if (!cancelled) setDetailLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [selectedId]);

  const selected = runs.find((run) => run.id === selectedId) ?? null;
  const split = detail?.split_counts ?? null;
  const testReport = detail?.report.test ?? null;
  const classRows = detail
    ? detail.classes.map((label) => ({ label, ...detail.report.test[label] }))
    : [];
  const weakest =
    detail && classRows.length
      ? classRows.reduce((lowest, row) => (row["f1-score"] < lowest["f1-score"] ? row : lowest))
      : null;
  const exploitSupport = detail?.report.test.exploit?.support ?? 0;

  async function handleImport() {
    if (!file) return;
    setImportBusy(true);
    setImportError("");
    try {
      const form = new FormData();
      form.append("file", file);
      const data = await api<{ run: MLRunDetail; message: string }>("/ml/runs/import", {
        method: "POST",
        body: form,
      });
      setImportOpen(false);
      setFile(null);
      setSuccess(data.message);
      setDetail(data.run);
      setSelectedId(data.run.id);
      setMatrixMode("count");
      await loadRuns(data.run.id);
      await loadDataset();
    } catch (cause) {
      setImportError(messageOf(cause));
    } finally {
      setImportBusy(false);
    }
  }

  async function handlePreview(event: FormEvent) {
    event.preventDefault();
    if (!url.trim()) return;
    setPreviewBusy(true);
    setPreviewError("");
    try {
      setPreview(
        await api<MLPreviewResponse>("/ml/preview", {
          method: "POST",
          body: JSON.stringify({ url }),
        }),
      );
    } catch (cause) {
      setPreview(null);
      setPreviewError(messageOf(cause));
    } finally {
      setPreviewBusy(false);
    }
  }

  return (
    <div className="space-y-6">
      <div className="page-heading">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Pipeline ML</h1>
          <p>
            Visualisasi pipeline SVM linear + TF-IDF karakter, dari normalisasi URL sampai evaluasi
            model. Halaman ini tidak menjalankan training atau inference.
          </p>
        </div>
        <Button
          onClick={() => {
            setImportError("");
            setImportOpen(true);
          }}
        >
          <Upload aria-hidden="true" />
          Impor hasil
        </Button>
      </div>

      {success && (
        <div className="success-notice">
          <CheckCircle2 aria-hidden="true" className="size-4" />
          <p>{success}</p>
          <Button variant="ghost" size="sm" onClick={() => setSuccess("")}>
            Tutup
          </Button>
        </div>
      )}
      {error && <ErrorNotice message={error} retry={() => void loadRuns()} />}

      {loading ? (
        <Loading text="Memuat hasil model." />
      ) : runs.length === 0 ? (
        <>
          <section className="data-section">
            <div className="empty-state p-8">
              <BrainCircuit aria-hidden="true" className="size-10" />
              <h2>Belum ada hasil model</h2>
              <p>
                Impor <code>svm_tfidf_metrics.json</code> dari folder{" "}
                <code>results/hasil_model/</code> notebook SVM + TF-IDF. Artefak berisi metrik,
                report per kelas, dan confusion matrix; file model <code>.pkl</code> tidak dipakai.
              </p>
              <p className="rounded-lg border bg-muted/50 px-3 py-2 font-mono text-xs">
                flask --app app:create_app ml-import --path svm_tfidf_metrics.json
              </p>
              <Button
                onClick={() => {
                  setImportError("");
                  setImportOpen(true);
                }}
              >
                <FileJson aria-hidden="true" />
                Impor hasil model
              </Button>
            </div>
          </section>
          <DatasetSection summary={datasetSummary} />
        </>
      ) : (
        <>
          <div className="flex flex-col gap-4 rounded-xl border bg-card p-4 shadow-xs sm:flex-row sm:items-end sm:justify-between">
            <div className="w-full sm:max-w-sm">
              <Label
                htmlFor="ml-run"
                className="mb-2 block text-xs font-medium text-muted-foreground"
              >
                Hasil model
              </Label>
              <select
                id="ml-run"
                className="h-9 w-full rounded-md border border-input bg-background px-3 text-sm shadow-xs outline-none focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50"
                value={selectedId ?? ""}
                onChange={(event) => setSelectedId(event.target.value)}
              >
                {runs.map((run) => (
                  <option key={run.id} value={run.id}>
                    {run.id} — {run.model}/{run.representation}
                  </option>
                ))}
              </select>
            </div>
            <div className="flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
              <Badge variant="outline">{selected?.model?.toUpperCase() ?? "SVM"}</Badge>
              <Badge variant="outline">{selected?.representation?.toUpperCase() ?? "TF-IDF"}</Badge>
              <Badge variant="outline">{selected?.status ?? "completed"}</Badge>
              {activeId === selectedId && <Badge>Aktif</Badge>}
            </div>
          </div>

          {detailLoading || !detail || !split ? (
            <Loading text="Memuat detail hasil model." />
          ) : (
            <>
              <section className="data-section">
                <div className="table-toolbar">
                  <div>
                    <h2>A. Normalisasi URL</h2>
                    <p>Aturan deterministik yang dipakai untuk audit dan split domain-disjoint.</p>
                  </div>
                  <Badge variant="outline">Sebelum praproses</Badge>
                </div>
                <div className="space-y-5 p-5">
                  <p className="max-w-3xl text-sm text-muted-foreground">
                    Trim spasi/kontrol, lowercase scheme dan host, hapus titik akhir,
                    percent-decode, IDNA/punycode, deteksi IPv4/IPv6, lalu ambil eTLD+1 memakai
                    snapshot offline.
                  </p>
                  <form
                    className="flex flex-col gap-3 sm:flex-row sm:items-end"
                    onSubmit={handlePreview}
                  >
                    <div className="w-full">
                      <Label htmlFor="ml-url">URL yang ingin diperiksa</Label>
                      <Input
                        id="ml-url"
                        className="mt-2"
                        value={url}
                        maxLength={2048}
                        placeholder="https://contoh.test/login"
                        onChange={(event) => setUrl(event.target.value)}
                      />
                    </div>
                    <Button type="submit" disabled={previewBusy || !url.trim()}>
                      <Play aria-hidden="true" />
                      {previewBusy ? "Memproses." : "Proses"}
                    </Button>
                  </form>
                  {previewError && <ErrorNotice message={previewError} />}
                  {preview ? (
                    <div className="space-y-4">
                      <div className="flex flex-wrap gap-2">
                        {preview.steps.map((step) => (
                          <Badge key={step} variant="secondary">
                            {stepLabels[step] ?? step}
                          </Badge>
                        ))}
                        {preview.normalized.parse_failed && (
                          <Badge variant="destructive">
                            <AlertTriangle aria-hidden="true" />
                            Parse gagal
                          </Badge>
                        )}
                      </div>
                      <div className="overflow-x-auto rounded-lg border">
                        <table className="w-full min-w-[620px] text-sm">
                          <thead className="bg-muted/60 text-left text-xs text-muted-foreground">
                            <tr>
                              <th className="px-3 py-2 font-medium">Field</th>
                              <th className="px-3 py-2 font-medium">Sebelum</th>
                              <th className="px-3 py-2 font-medium">Sesudah</th>
                            </tr>
                          </thead>
                          <tbody>
                            {[
                              ["Raw", preview.normalized.raw, preview.normalized.text],
                              [
                                "Scheme",
                                preview.normalized.scheme || "—",
                                preview.normalized.scheme || "—",
                              ],
                              [
                                "Host",
                                preview.normalized.host || "—",
                                preview.normalized.canonical_host || "—",
                              ],
                              [
                                "eTLD+1",
                                preview.normalized.site || "—",
                                preview.normalized.site || "—",
                              ],
                              [
                                "Path",
                                preview.normalized.path || "—",
                                preview.normalized.path || "—",
                              ],
                              [
                                "Query",
                                preview.normalized.query || "—",
                                preview.normalized.query || "—",
                              ],
                              [
                                "IP",
                                preview.normalized.is_ip ? "Ya" : "Tidak",
                                preview.normalized.is_ip
                                  ? preview.normalized.canonical_host
                                  : "Tidak",
                              ],
                            ].map(([label, before, after]) => (
                              <tr key={label} className="border-t">
                                <td className="px-3 py-2 font-medium">{label}</td>
                                <td className="break-all px-3 py-2 font-mono text-xs">{before}</td>
                                <td className="break-all px-3 py-2 font-mono text-xs">{after}</td>
                              </tr>
                            ))}
                          </tbody>
                        </table>
                      </div>
                    </div>
                  ) : (
                    <p className="text-sm text-muted-foreground">
                      Masukkan URL untuk melihat hasil normalisasi dan langkah yang diterapkan.
                    </p>
                  )}
                </div>
              </section>

              <section className="data-section">
                <div className="table-toolbar">
                  <div>
                    <h2>B. Praproses TF-IDF</h2>
                    <p>Token n-gram karakter dan komposisi data yang dipakai notebook.</p>
                  </div>
                  <Badge variant="outline">TfidfVectorizer</Badge>
                </div>
                <div className="grid gap-6 p-5 lg:grid-cols-2">
                  <div className="space-y-4">
                    <div className="rounded-lg border bg-muted/30 p-4">
                      <p className="mb-3 text-xs font-medium text-muted-foreground">Parameter</p>
                      <dl className="grid grid-cols-2 gap-3 text-sm">
                        {tfidfParameters.map(([name, value]) => (
                          <div key={name}>
                            <dt className="font-mono text-xs text-muted-foreground">{name}</dt>
                            <dd className="font-medium">{value}</dd>
                          </div>
                        ))}
                      </dl>
                      {detail.preprocessing && (
                        <p className="mt-4 break-all rounded-md bg-background/70 p-2 font-mono text-[11px] text-muted-foreground">
                          {detail.preprocessing}
                        </p>
                      )}
                    </div>
                    <div>
                      <p className="mb-2 text-xs font-medium text-muted-foreground">
                        Token n-gram dari preview
                      </p>
                      {preview ? (
                        <NgramChips preview={preview} />
                      ) : (
                        <p className="text-sm text-muted-foreground">
                          Jalankan preview URL di bagian Normalisasi untuk melihat token 3/4/5.
                        </p>
                      )}
                    </div>
                  </div>
                  <div className="space-y-5">
                    <div>
                      <p className="mb-3 text-xs font-medium text-muted-foreground">
                        Split train / validation / test
                      </p>
                      <SplitBar split={split} />
                    </div>
                    <DatasetSection summary={datasetSummary} />
                    <p className="text-xs leading-5 text-muted-foreground">
                      Normalisasi hostname dipakai untuk split domain-disjoint (ICANN eTLD+1),
                      sedangkan input model hanya di-<code>strip</code>. Kelas pada dataset dapat
                      berbeda dari kelas artefak.
                    </p>
                  </div>
                </div>
              </section>

              <section className="data-section">
                <div className="table-toolbar">
                  <div>
                    <h2>C. Training</h2>
                    <p>Ringkasan model final dan biaya pelatihan dari artefak.</p>
                  </div>
                  <Badge variant="outline">LinearSVC</Badge>
                </div>
                <div className="grid gap-6 p-5 lg:grid-cols-[1.1fr_0.9fr]">
                  <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
                    {trainingParameters.map(([label, key]) => (
                      <div key={key} className="rounded-lg border bg-card p-3">
                        <p className="font-mono text-[11px] text-muted-foreground">{label}</p>
                        <p className="mt-1 break-all text-sm font-medium">
                          {detail.params[key] === undefined || detail.params[key] === null
                            ? "—"
                            : String(detail.params[key])}
                        </p>
                      </div>
                    ))}
                  </div>
                  <div className="space-y-3">
                    <div className="flex items-center justify-between rounded-lg border bg-card p-3 text-sm">
                      <span className="flex items-center gap-2 text-muted-foreground">
                        <Database aria-hidden="true" className="size-4" /> Baris training
                      </span>
                      <span className="font-semibold tabular-nums">
                        {number.format(detail.row_count ?? 0)}
                      </span>
                    </div>
                    <div className="flex items-center justify-between rounded-lg border bg-card p-3 text-sm">
                      <span className="flex items-center gap-2 text-muted-foreground">
                        <Layers aria-hidden="true" className="size-4" /> Fitur TF-IDF
                      </span>
                      <span className="font-semibold tabular-nums">
                        {detail.input_features ? number.format(detail.input_features) : "—"}
                      </span>
                    </div>
                    <div className="flex items-center justify-between rounded-lg border bg-card p-3 text-sm">
                      <span className="flex items-center gap-2 text-muted-foreground">
                        <Gauge aria-hidden="true" className="size-4" /> Waktu fit
                      </span>
                      <span className="font-semibold tabular-nums">
                        {detail.fit_seconds === null ? "—" : `${detail.fit_seconds.toFixed(1)} dtk`}
                      </span>
                    </div>
                    <p className="text-xs leading-5 text-muted-foreground">
                      Split domain-disjoint 70/15/15 memakai eTLD+1 ICANN: tidak ada domain yang
                      muncul di lebih dari satu partisi. Model dilatih pada seluruh train;
                      validation dan test hanya untuk evaluasi.
                    </p>
                  </div>
                </div>
              </section>

              <section className="data-section">
                <div className="table-toolbar">
                  <div>
                    <h2>D. Evaluasi</h2>
                    <p>Metrik test, report per kelas, dan confusion matrix dari artefak.</p>
                  </div>
                  <Badge variant="outline">Test set</Badge>
                </div>
                <div className="space-y-6 p-5">
                  <div className="grid gap-4 md:grid-cols-2">
                    <MetricGroup title="Validation" metrics={detail.metrics.validation} />
                    <MetricGroup title="Test" metrics={detail.metrics.test} />
                  </div>

                  <div className="flex flex-wrap items-start gap-3 rounded-lg border border-amber-500/25 bg-amber-500/10 p-4 text-sm">
                    <ScanSearch
                      aria-hidden="true"
                      className="mt-0.5 size-4 shrink-0 text-amber-600"
                    />
                    <p>
                      {weakest ? (
                        <>
                          F1 terendah ada pada kelas <strong>{weakest.label}</strong> (
                          {percent.format(weakest["f1-score"])}).
                        </>
                      ) : (
                        "Report per kelas tidak tersedia."
                      )}{" "}
                      {exploitSupport > 0 && exploitSupport < 100 && (
                        <>
                          Kelas <code>exploit</code> hanya memiliki {number.format(exploitSupport)}{" "}
                          contoh uji, jadi angkanya sensitif dan jangan dibandingkan langsung dengan
                          kelas besar.
                        </>
                      )}
                    </p>
                  </div>

                  {testReport && (
                    <div>
                      <p className="mb-3 text-xs font-medium text-muted-foreground">
                        Report per kelas · test
                      </p>
                      <ReportTable report={testReport} />
                    </div>
                  )}

                  <div>
                    <p className="mb-3 text-xs font-medium text-muted-foreground">
                      Confusion matrix
                    </p>
                    <ConfusionMatrix
                      detail={detail}
                      mode={matrixMode}
                      onModeChange={setMatrixMode}
                    />
                  </div>
                </div>
              </section>
            </>
          )}
        </>
      )}

      <Dialog
        open={importOpen}
        onOpenChange={(open) => {
          if (!importBusy) setImportOpen(open);
        }}
      >
        <DialogContent
          className="upload-dialog"
          aria-busy={importBusy}
          showCloseButton={!importBusy}
        >
          <DialogTitle>Impor hasil model</DialogTitle>
          <DialogDescription>
            Pilih <code>svm_tfidf_metrics.json</code> dari folder <code>results/hasil_model/</code>.
            File divalidasi tanpa menjalankan model. Maksimal 2 MB.
          </DialogDescription>
          <div className="field">
            <Label htmlFor="ml-artifact">File JSON</Label>
            <Input
              id="ml-artifact"
              type="file"
              accept=".json,application/json"
              disabled={importBusy}
              onChange={(event) => setFile(event.target.files?.[0] ?? null)}
            />
            {file && (
              <p className="help-text">
                {file.name} · {(file.size / 1024).toFixed(1)} KB
              </p>
            )}
          </div>
          {importError && <ErrorNotice message={importError} />}
          <DialogFooter>
            <Button variant="outline" disabled={importBusy} onClick={() => setImportOpen(false)}>
              Batal
            </Button>
            <Button disabled={!file || importBusy} onClick={() => void handleImport()}>
              {importBusy ? "Mengimpor." : "Impor hasil"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
