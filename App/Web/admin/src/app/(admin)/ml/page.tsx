/* oxlint-disable react/set-state-in-effect -- Synchronize the dashboard with async API data. */
/* oxlint-disable jsx-a11y/no-noninteractive-tabindex -- Scrollable tables must be keyboard reachable. */
"use client";
import { useCallback, useEffect, useState, type FormEvent } from "react";
import {
  ArrowRight,
  CheckCircle2,
  Cpu,
  Database,
  Gauge,
  Info,
  Layers,
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
import { DatasetVisualization } from "@/components/ml/dataset-visualization";
import { PipelineOverview } from "@/components/ml/pipeline-overview";
import { PreprocessingVisualization } from "@/components/ml/preprocessing-visualization";
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
  type RowsResponse,
} from "@/lib/api";
import { demoDatasetSummary, demoPreview, demoRows, demoRun } from "@/lib/ml-demo";

const trainingParameters = [
  ["C", "C"],
  ["class_weight", "class_weight"],
  ["dual", "dual"],
  ["loss", "loss"],
  ["penalty", "penalty"],
  ["multi_class", "multi_class"],
  ["tol", "tol"],
  ["max_iter", "max_iter"],
  ["random_state", "random_state"],
  ["seed", "seed"],
];

const trainingFlow = [
  {
    label: "Dataset Training",
    hint: "URL yang sudah dibersihkan",
    Icon: Database,
  },
  { label: "TF-IDF Features", hint: "N-gram karakter 3–5", Icon: Layers },
  { label: "LinearSVC Training", hint: "Optimasi hyperplane", Icon: Cpu },
  { label: "Trained Model", hint: "Model siap dievaluasi", Icon: CheckCircle2 },
];

const metricDefinitions = [
  ["Accuracy", "Proporsi seluruh prediksi yang benar."],
  ["Balanced accuracy", "Rata-rata recall tiap kelas; lebih adil untuk kelas tidak seimbang."],
  ["Macro F1", "Rata-rata F1 semua kelas tanpa mempertimbangkan jumlah support."],
  ["Weighted F1", "Rata-rata F1 yang mempertimbangkan jumlah support setiap kelas."],
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

function MetricComparison({ metrics }: { metrics: MLRunDetail["metrics"] }) {
  const rows = [
    ["Accuracy", metrics.validation.accuracy, metrics.test.accuracy],
    ["Balanced accuracy", metrics.validation.balanced_accuracy, metrics.test.balanced_accuracy],
    ["Macro F1", metrics.validation.macro_f1, metrics.test.macro_f1],
    ["Weighted F1", metrics.validation.weighted_f1, metrics.test.weighted_f1],
  ] as const;
  return (
    <div className="table-scroll rounded-lg border" tabIndex={0}>
      <table>
        <thead>
          <tr>
            <th>Metrik</th>
            <th>Validation</th>
            <th>Test</th>
            <th>Selisih test − validation</th>
          </tr>
        </thead>
        <tbody>
          {rows.map(([label, validation, test]) => {
            const difference = test - validation;
            return (
              <tr key={label}>
                <td className="font-medium">{label}</td>
                <td className="tabular-nums">{percent.format(validation)}</td>
                <td className="tabular-nums">{percent.format(test)}</td>
                <td className="tabular-nums">
                  {difference >= 0 ? "+" : ""}
                  {percent.format(difference)}
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
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

function ReportTable({ report }: { report: MLReport }) {
  const rows = Object.entries(report);
  if (!rows.length) {
    return (
      <p className="text-sm text-muted-foreground">Report untuk partisi ini tidak tersedia.</p>
    );
  }
  return (
    <div className="table-scroll rounded-lg border" tabIndex={0}>
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
      <div className="table-scroll rounded-lg border pb-2" tabIndex={0}>
        <div
          className="grid min-w-160 gap-1 p-2 text-xs"
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

function SourceBadge({ isDemo }: { isDemo: boolean }) {
  return isDemo ? (
    <Badge variant="secondary" className="bg-amber-500/10 text-amber-700">
      Data simulasi
    </Badge>
  ) : (
    <Badge variant="outline">Data API</Badge>
  );
}

function DemoBanner({ runIsDemo, datasetIsDemo }: { runIsDemo: boolean; datasetIsDemo: boolean }) {
  if (!runIsDemo && !datasetIsDemo) return null;
  const parts = [
    runIsDemo ? "metrik, split, dan evaluasi" : null,
    datasetIsDemo ? "dataset, atribut, dan distribusi" : null,
  ]
    .filter(Boolean)
    .join(" serta ");
  return (
    <div className="flex flex-wrap items-start gap-3 rounded-xl border border-amber-500/25 bg-amber-500/10 p-4 text-sm">
      <Info aria-hidden="true" className="mt-0.5 size-4 shrink-0 text-amber-700" />
      <div className="min-w-0 flex-1">
        <p className="font-medium">Mode simulasi aktif</p>
        <p className="mt-1 text-xs leading-5 text-amber-800">
          Bagian {parts} memakai data contoh karena API belum menyediakan data tersebut. Angka
          simulasi hanya untuk memperlihatkan alur; bukan klaim hasil penelitian terbaru.
        </p>
      </div>
      <Badge variant="secondary" className="bg-amber-500/15 text-amber-800">
        Data simulasi
      </Badge>
    </div>
  );
}

export default function PipelineMLPage() {
  const [runs, setRuns] = useState<MLRunSummary[]>([]);
  const [activeId, setActiveId] = useState<string | null>(null);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [detail, setDetail] = useState<MLRunDetail | null>(null);
  const [datasetSummary, setDatasetSummary] = useState<MLDatasetSummary | null>(null);
  const [datasetRows, setDatasetRows] = useState<RowsResponse | null>(null);
  const [datasetRowsLoading, setDatasetRowsLoading] = useState(false);
  const [datasetRowsError, setDatasetRowsError] = useState("");
  const [loading, setLoading] = useState(true);
  const [detailLoading, setDetailLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [importOpen, setImportOpen] = useState(false);
  const [file, setFile] = useState<File | null>(null);
  const [importBusy, setImportBusy] = useState(false);
  const [importError, setImportError] = useState("");
  const [url, setUrl] = useState(demoPreview.normalized.raw.trim());
  const [preview, setPreview] = useState<MLPreviewResponse | null>(null);
  const [previewBusy, setPreviewBusy] = useState(false);
  const [previewError, setPreviewError] = useState("");
  const [matrixMode, setMatrixMode] = useState<"count" | "recall">("count");
  const [reportSplit, setReportSplit] = useState<"validation" | "test">("test");
  const [activeTab, setActiveTab] = useState<"summary" | "flow" | "simulator" | "evaluation">(
    "summary",
  );

  const loadDataset = useCallback(async () => {
    setDatasetRowsLoading(true);
    setDatasetRowsError("");
    setDatasetRows(null);
    try {
      const summary = await api<MLDatasetSummary>("/ml/dataset-summary");
      setDatasetSummary(summary);
      try {
        const rows = await api<RowsResponse>(
          `/dataset/rows?dataset_id=${encodeURIComponent(summary.dataset.id)}&page=1&page_size=25`,
        );
        setDatasetRows(rows);
      } catch (cause) {
        setDatasetRowsError(messageOf(cause));
      }
    } catch (cause) {
      if (cause instanceof ApiError && cause.code === "no_dataset") {
        setDatasetSummary(null);
        return;
      }
      setError(messageOf(cause));
    } finally {
      setDatasetRowsLoading(false);
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
    setDetail(null);
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
  const runView = detail ?? demoRun;
  const runIsDemo = !detail && !detailLoading;
  const datasetView = datasetSummary ?? demoDatasetSummary;
  const datasetIsDemo = !datasetSummary;
  const rows = datasetIsDemo ? demoRows : (datasetRows?.rows ?? []);
  const split = runView.split_counts;
  const report = runView.report[reportSplit];
  const classRows = runView.classes.map((label) => ({
    label,
    ...runView.report.test[label],
  }));
  const weakest =
    classRows.length > 0
      ? classRows.reduce((lowest, row) => (row["f1-score"] < lowest["f1-score"] ? row : lowest))
      : null;
  const exploitSupport = runView.report.test.exploit?.support ?? 0;
  const showDetailLoading = runs.length > 0 && detailLoading && !detail;
  const summaryCards = [
    ["Total dataset", number.format(datasetView.dataset.row_count), Database],
    ["Jumlah kelas", number.format(datasetView.class_counts.length), Layers],
    ["Skor model", percent.format(runView.metrics.test.accuracy), Gauge],
  ] as const;

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
      setReportSplit("test");
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
            Visualisasi alur dataset, preprocessing, TF-IDF, training LinearSVC, dan evaluasi model.
            Halaman ini tidak menjalankan training atau inference.
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
      {error && (
        <ErrorNotice
          message={error}
          retry={() => {
            void loadRuns();
            void loadDataset();
          }}
        />
      )}

      {loading ? (
        <Loading text="Memuat data pipeline." />
      ) : (
        <>
          <div className="rounded-xl border border-blue-200 bg-blue-50 p-4 text-sm text-blue-900">
            <div className="flex flex-wrap items-center justify-between gap-3">
              <div>
                <p className="font-medium">Preview interaktif</p>
                <p className="mt-1 text-xs text-blue-800">
                  Data dashboard diambil dari API saat tersedia; mode demo akan ditandai dengan
                  jelas.
                </p>
              </div>
              <Badge variant="outline" className="border-blue-200 bg-white text-blue-800">
                Linear SVM + Char TF-IDF
              </Badge>
            </div>
          </div>

          <DemoBanner runIsDemo={runIsDemo} datasetIsDemo={datasetIsDemo} />

          {runs.length > 0 ? (
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
                <Badge variant="outline">
                  {selected?.representation?.toUpperCase() ?? "TF-IDF"}
                </Badge>
                <Badge variant="outline">{selected?.status ?? "completed"}</Badge>
                {activeId === selectedId && <Badge>Aktif</Badge>}
              </div>
            </div>
          ) : (
            <div className="flex flex-wrap items-center gap-3 rounded-xl border bg-card p-4 text-sm shadow-xs">
              <Info aria-hidden="true" className="size-4 text-primary" />
              <p className="min-w-0 flex-1 text-muted-foreground">
                Belum ada artefak model di API. Bagian split, training, dan evaluasi memakai contoh
                artefak notebook. Unggah <code>svm_tfidf_metrics.json</code> untuk memakai hasil
                asli.
              </p>
              <SourceBadge isDemo />
            </div>
          )}

          <div className="grid gap-3 sm:grid-cols-3">
            {summaryCards.map(([label, value, Icon]) => (
              <div key={label} className="rounded-xl border bg-card p-5 shadow-xs">
                <div className="flex items-center gap-2 text-[11px] font-medium uppercase tracking-wide text-muted-foreground">
                  <Icon aria-hidden="true" className="size-3.5 text-primary" /> {label}
                </div>
                <p className="mt-5 text-2xl font-semibold tabular-nums">{value}</p>
              </div>
            ))}
          </div>

          <div className="flex flex-wrap gap-2" role="tablist" aria-label="Tampilan pipeline ML">
            {[
              ["summary", "Ringkasan"],
              ["flow", "Alur Pipeline"],
              ["simulator", "Simulator"],
              ["evaluation", "Evaluasi"],
            ].map(([value, label]) => (
              <Button
                key={value}
                type="button"
                size="sm"
                variant={activeTab === value ? "default" : "outline"}
                role="tab"
                aria-selected={activeTab === value}
                onClick={() => setActiveTab(value as typeof activeTab)}
              >
                {label}
              </Button>
            ))}
          </div>

          {activeTab === "flow" && <PipelineOverview />}

          {showDetailLoading ? (
            <Loading text="Memuat detail hasil model." />
          ) : (
            <>
              {activeTab === "summary" && (
                <DatasetVisualization
                  summary={datasetView}
                  rows={rows}
                  isDemo={datasetIsDemo}
                  rowsLoading={datasetRowsLoading}
                  rowsError={datasetRowsError}
                />
              )}

              {activeTab === "flow" && (
                <PreprocessingVisualization
                  dataset={datasetView.dataset}
                  rows={rows}
                  isDemo={datasetIsDemo || runIsDemo}
                  preview={preview}
                  url={url}
                  onUrlChange={setUrl}
                  onPreview={handlePreview}
                  previewBusy={previewBusy}
                  previewError={previewError}
                  preprocessing={runView.preprocessing}
                />
              )}

              {activeTab === "simulator" && (
                <section id="split" className="data-section scroll-mt-24">
                  <div className="table-toolbar">
                    <div>
                      <h2>Pembagian Dataset</h2>
                      <p>
                        Split domain-disjoint 70/15/15 memakai eTLD+1 ICANN; tidak ada domain yang
                        muncul di lebih dari satu partisi.
                      </p>
                    </div>
                    <div className="flex flex-wrap items-center justify-end gap-2">
                      <SourceBadge isDemo={runIsDemo} />
                      <Badge variant="outline">70 / 15 / 15</Badge>
                    </div>
                  </div>
                  <div className="space-y-5 p-5">
                    <SplitBar split={split} />
                    <div className="grid gap-3 sm:grid-cols-3">
                      {[
                        ["Train", split.train, "Melatih LinearSVC"],
                        ["Validation", split.validation, "Membandingkan konfigurasi"],
                        ["Test", split.test, "Evaluasi akhir"],
                      ].map(([label, value, hint]) => (
                        <div key={String(label)} className="rounded-lg border bg-card p-3">
                          <p className="text-[11px] text-muted-foreground">{label}</p>
                          <p className="mt-1 text-lg font-semibold tabular-nums">
                            {number.format(Number(value))}
                          </p>
                          <p className="text-[11px] text-muted-foreground">{hint}</p>
                        </div>
                      ))}
                    </div>
                    <p className="text-xs leading-5 text-muted-foreground">
                      Normalisasi hostname dipakai untuk mengelompokkan domain saat split, sedangkan
                      input model hanya di-
                      <code>strip</code>. Kelas pada dataset dapat berbeda dari kelas artefak.
                    </p>
                  </div>
                </section>
              )}

              {activeTab === "simulator" && (
                <section id="training" className="data-section scroll-mt-24">
                  <div className="table-toolbar">
                    <div>
                      <h2>Training LinearSVC</h2>
                      <p>Informasi model final dan biaya pelatihan dari artefak notebook.</p>
                    </div>
                    <div className="flex flex-wrap items-center justify-end gap-2">
                      <SourceBadge isDemo={runIsDemo} />
                      <Badge variant="outline">LinearSVC</Badge>
                    </div>
                  </div>
                  <div className="space-y-6 p-5">
                    <div className="flex flex-col gap-2 lg:flex-row lg:items-center">
                      {trainingFlow.map((step, index) => (
                        <div key={step.label} className="flex min-w-0 flex-1 items-center gap-2">
                          <div className="w-full rounded-lg border bg-muted/30 p-3">
                            <step.Icon aria-hidden="true" className="size-4 text-primary" />
                            <p className="mt-2 text-sm font-medium">{step.label}</p>
                            <p className="mt-0.5 text-[11px] leading-4 text-muted-foreground">
                              {step.hint}
                            </p>
                          </div>
                          {index < trainingFlow.length - 1 && (
                            <ArrowRight
                              aria-hidden="true"
                              className="hidden size-4 shrink-0 text-muted-foreground lg:block"
                            />
                          )}
                        </div>
                      ))}
                    </div>

                    <div className="grid gap-6 lg:grid-cols-[1.1fr_0.9fr]">
                      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
                        {trainingParameters.map(([label, key]) => (
                          <div key={key} className="rounded-lg border bg-card p-3">
                            <p className="font-mono text-[11px] text-muted-foreground">{label}</p>
                            <p className="mt-1 break-all text-sm font-medium">
                              {runView.params[key] === undefined || runView.params[key] === null
                                ? "—"
                                : String(runView.params[key])}
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
                            {number.format(split.train)}
                          </span>
                        </div>
                        <div className="flex items-center justify-between rounded-lg border bg-card p-3 text-sm">
                          <span className="flex items-center gap-2 text-muted-foreground">
                            <Layers aria-hidden="true" className="size-4" /> Fitur TF-IDF
                          </span>
                          <span className="font-semibold tabular-nums">
                            {runView.input_features ? number.format(runView.input_features) : "—"}
                          </span>
                        </div>
                        <div className="flex items-center justify-between rounded-lg border bg-card p-3 text-sm">
                          <span className="flex items-center gap-2 text-muted-foreground">
                            <Gauge aria-hidden="true" className="size-4" /> Waktu fit
                          </span>
                          <span className="font-semibold tabular-nums">
                            {runView.fit_seconds === null
                              ? "—"
                              : `${runView.fit_seconds.toFixed(1)} dtk`}
                          </span>
                        </div>
                        <p className="text-xs leading-5 text-muted-foreground">
                          Model dilatih pada seluruh train. Validation dan test hanya dipakai untuk
                          evaluasi, bukan untuk menyesuaikan bobot model.
                        </p>
                      </div>
                    </div>
                  </div>
                </section>
              )}

              {activeTab === "evaluation" && (
                <section id="validation" className="data-section scroll-mt-24">
                  <div className="table-toolbar">
                    <div>
                      <h2>Validasi dan Perbandingan Metrik</h2>
                      <p>Perbandingan hasil validation dan test dari artefak model.</p>
                    </div>
                    <SourceBadge isDemo={runIsDemo} />
                  </div>
                  <div className="space-y-5 p-5">
                    <div className="grid gap-4 md:grid-cols-2">
                      <MetricGroup title="Validation" metrics={runView.metrics.validation} />
                      <MetricGroup title="Test" metrics={runView.metrics.test} />
                    </div>
                    <MetricComparison metrics={runView.metrics} />
                    <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
                      {metricDefinitions.map(([label, explanation]) => (
                        <div key={label} className="rounded-lg border bg-muted/30 p-3">
                          <p className="text-xs font-medium">{label}</p>
                          <p className="mt-1 text-[11px] leading-5 text-muted-foreground">
                            {explanation}
                          </p>
                        </div>
                      ))}
                    </div>
                  </div>
                </section>
              )}

              {activeTab === "evaluation" && (
                <section id="evaluation" className="data-section scroll-mt-24">
                  <div className="table-toolbar">
                    <div>
                      <h2>Evaluasi Akhir</h2>
                      <p>Classification report per kelas dan confusion matrix pada test set.</p>
                    </div>
                    <div className="flex flex-wrap items-center justify-end gap-2">
                      <SourceBadge isDemo={runIsDemo} />
                      <Badge variant="outline">
                        {reportSplit === "test" ? "Test set" : "Validation set"}
                      </Badge>
                    </div>
                  </div>
                  <div className="space-y-6 p-5">
                    <div className="flex flex-wrap items-start gap-3 rounded-lg border border-amber-500/25 bg-amber-500/10 p-4 text-sm">
                      <ScanSearch
                        aria-hidden="true"
                        className="mt-0.5 size-4 shrink-0 text-amber-600"
                      />
                      <p>
                        {weakest ? (
                          <>
                            F1 terendah pada test set ada di kelas <strong>{weakest.label}</strong>{" "}
                            ({percent.format(weakest["f1-score"])}).
                          </>
                        ) : (
                          "Report per kelas tidak tersedia."
                        )}{" "}
                        {exploitSupport > 0 && exploitSupport < 100 && (
                          <>
                            Kelas <code>exploit</code> hanya memiliki{" "}
                            {number.format(exploitSupport)} contoh uji, jadi angkanya sensitif dan
                            jangan dibandingkan langsung dengan kelas besar.
                          </>
                        )}
                      </p>
                    </div>

                    <div className="flex flex-wrap items-center justify-between gap-3">
                      <p className="text-xs font-medium text-muted-foreground">
                        Classification report per kelas
                      </p>
                      <div className="flex gap-2">
                        <Button
                          type="button"
                          size="sm"
                          variant={reportSplit === "validation" ? "default" : "outline"}
                          aria-pressed={reportSplit === "validation"}
                          onClick={() => setReportSplit("validation")}
                        >
                          Validation
                        </Button>
                        <Button
                          type="button"
                          size="sm"
                          variant={reportSplit === "test" ? "default" : "outline"}
                          aria-pressed={reportSplit === "test"}
                          onClick={() => setReportSplit("test")}
                        >
                          Test
                        </Button>
                      </div>
                    </div>
                    <ReportTable report={report} />

                    <div>
                      <p className="mb-3 text-xs font-medium text-muted-foreground">
                        Confusion matrix
                      </p>
                      <ConfusionMatrix
                        detail={runView}
                        mode={matrixMode}
                        onModeChange={setMatrixMode}
                      />
                      {runIsDemo && (
                        <p className="mt-3 text-xs leading-5 text-muted-foreground">
                          Confusion matrix contoh artefak direkonstruksi dari recall dan support
                          karena notebook hanya menyimpan matriks asli sebagai gambar.
                        </p>
                      )}
                    </div>
                  </div>
                </section>
              )}
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
