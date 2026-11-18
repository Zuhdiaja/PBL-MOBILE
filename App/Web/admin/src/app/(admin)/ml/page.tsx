/* oxlint-disable react/set-state-in-effect -- Synchronize the dashboard with async API data. */
/* oxlint-disable jsx-a11y/no-noninteractive-tabindex -- Scrollable tables must be keyboard reachable. */
"use client";
import { useCallback, useEffect, useRef, useState } from "react";
import Link from "next/link";
import {
  ArrowRight,
  CheckCircle2,
  Cpu,
  Database,
  Gauge,
  ChevronLeft,
  ChevronRight,
  Layers,
  ScanSearch,
  Play,
  Upload,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
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
import { SplitDistribution } from "@/components/ml/split-distribution";
import {
  ApiError,
  api,
  messageOf,
  number,
  percent,
  type MLDatasetSummary,
  type MLPreviewResponse,
  type MLReport,
  type MLRunDetail,
  type MLRunSummary,
  type MLRunsResponse,
  type MLStatusResponse,
  type MLTrainingSchedule,
  type RowsResponse,
} from "@/lib/api";
import { demoDatasetSummary, demoRows, demoRun } from "@/lib/ml-demo";

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

function MetricComparison({ metrics }: { metrics: MLRunDetail["metrics"] }) {
  const rows = [
    ["Accuracy", metrics.validation.accuracy, metrics.test.accuracy],
    ["Balanced accuracy", metrics.validation.balanced_accuracy, metrics.test.balanced_accuracy],
    ["Macro F1", metrics.validation.macro_f1, metrics.test.macro_f1],
    ["Weighted F1", metrics.validation.weighted_f1, metrics.test.weighted_f1],
  ] as const;
  return (
    <section
      className="table-scroll rounded-lg border"
      aria-label="Tabel perbandingan metrik"
      tabIndex={0}
    >
      <table className="ml-metrics-table">
        <thead>
          <tr>
            <th>Metrik</th>
            <th>Validation</th>
            <th>Test</th>
            <th>Selisih</th>
          </tr>
        </thead>
        <tbody>
          {rows.map(([label, validation, test]) => {
            const difference = test - validation;
            return (
              <tr key={label}>
                <th scope="row">{label}</th>
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
    </section>
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

function ReportTable({ report, classes }: { report: MLReport; classes: string[] }) {
  const rows = [...classes, "macro avg", "weighted avg"].filter((label) => label in report);
  if (!rows.length) {
    return (
      <p className="text-sm text-muted-foreground">Report untuk partisi ini tidak tersedia.</p>
    );
  }
  return (
    <section
      className="table-scroll rounded-lg border"
      aria-label="Tabel evaluasi per kelas"
      tabIndex={0}
    >
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
          {rows.map((label) => (
            <tr key={label}>
              <th scope="row">{label}</th>
              <td className="tabular-nums">{percent.format(report[label].precision)}</td>
              <td className="tabular-nums">{percent.format(report[label].recall)}</td>
              <td className="tabular-nums">{percent.format(report[label]["f1-score"])}</td>
              <td className="tabular-nums">{number.format(report[label].support)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </section>
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
      <section
        className="overflow-x-auto rounded-lg border p-1"
        aria-label="Gulir confusion matrix"
        tabIndex={0}
      >
        <table className="min-w-full border-separate border-spacing-1 text-xs whitespace-nowrap">
          <caption className="sr-only">Confusion matrix untuk data test</caption>
          <thead>
            <tr>
              <th scope="col" className="min-w-20 p-1 text-left text-muted-foreground">
                Aktual
              </th>
              {classes.map((label) => (
                <th
                  scope="col"
                  key={label}
                  className="min-w-12 px-1 py-2 font-medium text-muted-foreground"
                >
                  {label}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {matrix.map((row, rowIndex) => (
              <tr key={classes[rowIndex]}>
                <th scope="row" className="px-1 py-2 text-left font-medium">
                  {classes[rowIndex]}
                </th>
                {row.map((value, columnIndex) => {
                  const ratio = rowTotals[rowIndex] ? value / rowTotals[rowIndex] : 0;
                  const intensity = mode === "recall" ? ratio : value / max;
                  return (
                    <td
                      key={classes[columnIndex]}
                      className="rounded-md border px-1 py-2 text-center tabular-nums text-foreground"
                      style={{
                        backgroundColor:
                          intensity > 0
                            ? `color-mix(in srgb, var(--primary) ${4 + intensity * 24}%, var(--background))`
                            : undefined,
                      }}
                      title={`${classes[rowIndex]} → ${classes[columnIndex]}: ${number.format(value)}`}
                    >
                      {mode === "recall" ? percent.format(ratio) : number.format(value)}
                    </td>
                  );
                })}
              </tr>
            ))}
          </tbody>
        </table>
      </section>
    </div>
  );
}

function SourceBadge({ isDemo }: { isDemo: boolean }) {
  return isDemo ? (
    <Badge variant="secondary" className="bg-warning-surface text-warning">
      Data simulasi
    </Badge>
  ) : (
    <Badge variant="outline">Data API</Badge>
  );
}

const runDate = new Intl.DateTimeFormat("id-ID", {
  timeZone: "Asia/Jakarta",
  dateStyle: "medium",
  timeStyle: "short",
});

function ModelHistory({
  activeId,
  selectedId,
  onSelect,
  revision,
}: {
  activeId: string | null;
  selectedId: string | null;
  onSelect: (id: string) => void;
  revision: string | null | undefined;
}) {
  const [page, setPage] = useState(1);
  const [data, setData] = useState<MLRunsResponse>();
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);
  const [retry, setRetry] = useState(0);

  useEffect(() => {
    const controller = new AbortController();
    setLoading(true);
    setError("");
    api<MLRunsResponse>(`/ml/runs?page=${page}`, { signal: controller.signal })
      .then((result) => {
        if (!controller.signal.aborted) setData(result);
      })
      .catch((cause) => {
        if (!controller.signal.aborted) setError(messageOf(cause));
      })
      .finally(() => {
        if (!controller.signal.aborted) setLoading(false);
      });
    return () => controller.abort();
  }, [page, retry, revision]);

  return (
    <div id="model-history" className="space-y-3 border-t p-4 sm:px-5">
      {loading ? (
        <output className="text-sm text-muted-foreground">Memuat riwayat model…</output>
      ) : error ? (
        <ErrorNotice message={error} retry={() => setRetry(retry + 1)} />
      ) : data?.items.length ? (
        <>
          <ul className="divide-y rounded-lg border">
            {data.items.map((run) => (
              <li key={run.id}>
                <button
                  type="button"
                  aria-pressed={run.id === selectedId}
                  className="flex min-h-11 w-full flex-wrap items-center justify-between gap-2 px-3 py-2.5 text-left text-sm hover:bg-muted aria-pressed:bg-muted"
                  onClick={() => onSelect(run.id)}
                >
                  <span className="flex flex-wrap items-baseline gap-x-2">
                    {run.completed_at
                      ? runDate.format(new Date(run.completed_at)) + " WIB"
                      : "Waktu selesai belum dicatat"}
                    <span className="font-mono text-xs text-muted-foreground">
                      {run.id.slice(0, 8)}
                    </span>
                  </span>
                  {run.id === activeId && <Badge>Aktif</Badge>}
                </button>
              </li>
            ))}
          </ul>
          {(page > 1 || data.has_next) && (
            <nav aria-label="Halaman riwayat model" className="flex items-center justify-end gap-2">
              <Button
                variant="outline"
                size="icon"
                aria-label="Riwayat sebelumnya"
                disabled={page === 1}
                onClick={() => setPage(page - 1)}
              >
                <ChevronLeft />
              </Button>
              <span className="text-xs text-muted-foreground">Halaman {page}</span>
              <Button
                variant="outline"
                size="icon"
                aria-label="Riwayat berikutnya"
                disabled={!data.has_next}
                onClick={() => setPage(page + 1)}
              >
                <ChevronRight />
              </Button>
            </nav>
          )}
        </>
      ) : (
        <p className="text-sm text-muted-foreground">Belum ada riwayat model.</p>
      )}
    </div>
  );
}

export default function PipelineMLPage() {
  const [preferredRun, setPreferredRun] = useState<MLRunSummary | null>(null);
  const [historyOpen, setHistoryOpen] = useState(false);
  const [historyRevision, setHistoryRevision] = useState(0);
  const [training, setTraining] = useState<MLTrainingSchedule>();
  const [trainingSubmitting, setTrainingSubmitting] = useState(false);
  const [trainingError, setTrainingError] = useState("");
  const runsRequest = useRef(0);
  const historyTrigger = useRef<HTMLButtonElement>(null);
  const [activeId, setActiveId] = useState<string | null>(null);
  const [datasetDigest, setDatasetDigest] = useState<string | null>();
  const [chosenId, setChosenId] = useState<string | null>(null);
  const selectedId = chosenId ?? preferredRun?.id ?? null;
  const [detail, setDetail] = useState<MLRunDetail | null>(null);
  const [datasetStatus, setDatasetStatus] = useState<"loading" | "ready" | "empty" | "failed">(
    "loading",
  );
  const [datasetSummary, setDatasetSummary] = useState<MLDatasetSummary | null>(null);
  const [datasetRows, setDatasetRows] = useState<RowsResponse | null>(null);
  const [datasetRowsLoading, setDatasetRowsLoading] = useState(false);
  const [datasetRowsError, setDatasetRowsError] = useState("");
  const [loading, setLoading] = useState(true);
  const [detailLoading, setDetailLoading] = useState(false);
  const [runsError, setRunsError] = useState("");
  const [datasetError, setDatasetError] = useState("");
  const [detailError, setDetailError] = useState("");
  const [detailRetry, setDetailRetry] = useState(0);
  const error = runsError || datasetError || detailError;
  const [success, setSuccess] = useState("");
  const [importOpen, setImportOpen] = useState(false);
  const [file, setFile] = useState<File | null>(null);
  const [importBusy, setImportBusy] = useState(false);
  const [importError, setImportError] = useState("");
  const [url, setUrl] = useState<string | null>(null);
  const [preview, setPreview] = useState<MLPreviewResponse | null>(null);
  const [previewBusy, setPreviewBusy] = useState(false);
  const [previewError, setPreviewError] = useState("");
  const [matrixMode, setMatrixMode] = useState<"count" | "recall">("count");
  const [reportSplit, setReportSplit] = useState<"validation" | "test">("test");
  const [activeTab, setActiveTab] = useState<"summary" | "flow" | "simulator" | "evaluation">(
    "summary",
  );

  const loadDataset = useCallback(async () => {
    setDatasetStatus("loading");
    setDatasetRowsLoading(true);
    setDatasetRowsError("");
    setDatasetRows(null);
    try {
      const summary = await api<MLDatasetSummary>("/ml/dataset-summary");
      setDatasetSummary(summary);
      setDatasetStatus("ready");
      setDatasetError("");
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
        setDatasetStatus("empty");
        setDatasetError("");
        return;
      }
      setDatasetStatus("failed");
      setDatasetError(messageOf(cause));
    } finally {
      setDatasetRowsLoading(false);
    }
  }, []);

  const loadStatus = useCallback(async () => {
    const requestId = ++runsRequest.current;
    try {
      const data = await api<MLStatusResponse>("/ml/status");
      if (requestId !== runsRequest.current) return;
      setTraining(data.training);
      setRunsError("");
      setPreferredRun(data.run);
      setActiveId(data.active_id);
      setDatasetDigest(data.dataset_sha256);
      setChosenId((current) => (current === data.active_id ? null : current));
    } catch (cause) {
      if (requestId === runsRequest.current) setRunsError(messageOf(cause));
    }
  }, []);

  useEffect(() => {
    function refreshVisible() {
      if (document.visibilityState === "visible") void loadStatus();
    }
    void loadStatus().finally(() => setLoading(false));
    const timer = window.setInterval(refreshVisible, 15_000);
    document.addEventListener("visibilitychange", refreshVisible);
    return () => {
      window.clearInterval(timer);
      document.removeEventListener("visibilitychange", refreshVisible);
    };
  }, [loadStatus]);

  useEffect(() => {
    if (datasetDigest !== undefined) void loadDataset();
  }, [datasetDigest, loadDataset]);

  useEffect(() => {
    setDetailError("");
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
        if (!cancelled) setDetailError(messageOf(cause));
      })
      .finally(() => {
        if (!cancelled) setDetailLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [selectedId, detailRetry]);

  const currentDetail = detail?.id === selectedId ? detail : null;
  const selected = currentDetail ?? (preferredRun?.id === selectedId ? preferredRun : null);
  const datasetMatches =
    selected?.dataset_matches == null || !datasetDigest
      ? null
      : selected.dataset_sha256 === datasetDigest;
  const runView = currentDetail ?? demoRun;
  const runIsDemo = !selectedId && !runsError;
  const datasetView = datasetSummary ?? demoDatasetSummary;
  const datasetIsDemo = datasetStatus === "empty";
  const showDataset = datasetIsDemo || datasetStatus === "ready";
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
  const showDetailLoading = Boolean(selectedId && detailLoading && !currentDetail);
  const scheduledRun = Boolean(currentDetail?.provenance.dataset_filename);
  const detailUnavailable = Boolean(selectedId && !currentDetail && !showDetailLoading);

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
      setChosenId(data.run.id);
      setMatrixMode("count");
      setReportSplit("test");
      setHistoryRevision((value) => value + 1);
      await loadStatus();
    } catch (cause) {
      setImportError(messageOf(cause));
    } finally {
      setImportBusy(false);
    }
  }

  const trainingBusy = training?.last_status === "queued" || training?.last_status === "running";
  const canTrain = Boolean(
    training?.pending_dataset && !trainingBusy && !trainingSubmitting && !runsError,
  );

  async function handleTrain() {
    if (!canTrain || !training?.dataset) return;
    setTrainingSubmitting(true);
    setTrainingError("");
    try {
      const next = await api<MLTrainingSchedule>("/ml/train", {
        method: "POST",
        body: JSON.stringify({ dataset_id: training.dataset.id }),
      });
      setTraining(next);
      setChosenId(null);
    } catch (cause) {
      setTrainingError(messageOf(cause));
    } finally {
      await loadStatus();
      setTrainingSubmitting(false);
    }
  }

  function navigateStage(tab: typeof activeTab, id: string) {
    setActiveTab(tab);
    window.requestAnimationFrame(() => {
      const section = document.getElementById(id);
      if (!section) return;
      section.setAttribute("tabindex", "-1");
      section.focus({ preventScroll: true });
      section.scrollIntoView({ block: "start" });
    });
  }

  async function handlePreview(url: string) {
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
          <p>Kelola training dan evaluasi model LinearSVC + TF-IDF untuk pemindaian URL.</p>
        </div>
        <div className="flex shrink-0 flex-wrap items-center gap-2">
          <Button
            variant="outline"
            className="min-h-9 max-md:min-h-11"
            onClick={() => {
              setImportError("");
              setImportOpen(true);
            }}
          >
            <Upload aria-hidden="true" />
            Impor hasil
          </Button>
          <Button
            className="min-h-9 max-md:min-h-11"
            disabled={!canTrain}
            aria-describedby={loading ? undefined : "training-status"}
            onClick={() => void handleTrain()}
          >
            <Play aria-hidden="true" />
            {trainingSubmitting ? "Mengajukan…" : "Train sekarang"}
          </Button>
        </div>
      </div>

      {trainingError && <ErrorNotice message={trainingError} />}

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
            void loadStatus();
            if (datasetError) void loadDataset();
            if (detailError) setDetailRetry((current) => current + 1);
          }}
        />
      )}

      {loading ? (
        <Loading text="Memuat data pipeline." />
      ) : (
        <>
          <section
            aria-labelledby="model-overview"
            className="overflow-hidden rounded-xl border bg-card"
          >
            <output
              id="training-status"
              className="block border-b px-4 py-3 text-sm leading-5 text-muted-foreground sm:px-5"
            >
              {runsError || !training ? (
                runsError ? (
                  "Status training belum tersedia."
                ) : (
                  "Memeriksa status training…"
                )
              ) : trainingBusy ? (
                <>
                  <strong className="text-foreground">
                    {training.last_status === "queued"
                      ? "Training dalam antrean."
                      : "Training sedang berjalan."}
                  </strong>
                  {activeId && " Pemindaian tetap memakai model aktif."}
                </>
              ) : training.last_status === "failed" ? (
                <>
                  <strong className="text-foreground">Training terakhir gagal.</strong>{" "}
                  {training.last_message}
                </>
              ) : training.dataset && training.pending_dataset ? (
                <>
                  <strong className="break-all text-foreground">{training.dataset.filename}</strong>{" "}
                  siap dilatih.
                </>
              ) : training.dataset ? (
                training.last_status === "completed" ? (
                  training.last_message
                ) : (
                  "Dataset aktif sudah berhasil dilatih."
                )
              ) : (
                <>
                  Unggah CSV di{" "}
                  <Link className="text-primary underline underline-offset-4" href="/datasets">
                    Dataset
                  </Link>{" "}
                  untuk memulai training.
                </>
              )}
            </output>

            <div className="flex flex-wrap items-start justify-between gap-3 p-4 sm:p-5">
              <div className="min-w-0 space-y-2">
                <h2 id="model-overview" className="text-base font-semibold">
                  {selectedId && selectedId === activeId
                    ? "Model aktif"
                    : selectedId
                      ? "Hasil evaluasi"
                      : "Belum ada model aktif"}
                </h2>
                {selectedId ? (
                  <>
                    <div className="flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
                      <span className="font-mono">{selectedId.slice(0, 8)}</span>
                      {selected?.completed_at && (
                        <span>{runDate.format(new Date(selected.completed_at))} WIB</span>
                      )}
                      {selectedId !== activeId && <Badge variant="outline">Riwayat</Badge>}
                      {selected?.is_synthetic && (
                        <Badge variant="secondary" className="bg-warning-surface text-warning">
                          Matriks rekonstruksi
                        </Badge>
                      )}
                      {selected && datasetMatches === null && (
                        <Badge variant="outline">Dataset training belum terverifikasi</Badge>
                      )}
                      {datasetMatches === false && (
                        <Badge variant="outline" className="text-destructive">
                          Dataset berbeda
                        </Badge>
                      )}
                    </div>
                    {currentDetail?.provenance.dataset_filename && (
                      <p className="text-xs leading-5 text-muted-foreground">
                        <strong className="break-all text-foreground">
                          {currentDetail.provenance.dataset_filename}
                        </strong>
                        {" · "}
                        {number.format(currentDetail.provenance.source_row_count ?? 0)} baris sumber
                        {" · "}
                        {number.format(currentDetail.row_count ?? 0)} URL unik setelah preprocessing
                      </p>
                    )}
                    {activeId && selectedId !== activeId && (
                      <Button
                        variant="link"
                        className="h-auto p-0"
                        onClick={() => setChosenId(null)}
                      >
                        Kembali ke model aktif
                      </Button>
                    )}
                  </>
                ) : runIsDemo ? (
                  <p className="text-sm text-muted-foreground">
                    Tab Detail Training dan Evaluasi menampilkan contoh berlabel.
                  </p>
                ) : null}
              </div>
              <div className="flex flex-wrap items-start gap-3">
                {selected?.metrics.test.accuracy !== undefined && (
                  <div className="pr-1">
                    <p className="text-xs text-muted-foreground">
                      Akurasi uji{selected.is_synthetic ? " (simulasi)" : ""}
                    </p>
                    <p className="text-xl font-semibold tabular-nums">
                      {percent.format(selected.metrics.test.accuracy)}
                    </p>
                  </div>
                )}
                {preferredRun && (
                  <Button
                    ref={historyTrigger}
                    variant="outline"
                    aria-expanded={historyOpen}
                    aria-controls={historyOpen ? "model-history" : undefined}
                    onClick={() => setHistoryOpen(!historyOpen)}
                  >
                    Riwayat model
                  </Button>
                )}
              </div>
            </div>
            {historyOpen && (
              <ModelHistory
                activeId={activeId}
                selectedId={selectedId}
                revision={`${activeId ?? ""}:${preferredRun?.id ?? ""}:${historyRevision}`}
                onSelect={(id) => {
                  setChosenId(id === preferredRun?.id ? null : id);
                  setHistoryOpen(false);
                  historyTrigger.current?.focus();
                }}
              />
            )}
          </section>

          <Tabs
            value={activeTab}
            onValueChange={(value) => setActiveTab(value as typeof activeTab)}
            className="min-w-0 gap-4"
          >
            <TabsList
              aria-label="Tampilan pipeline ML"
              className="grid h-auto! w-full grid-cols-2 gap-1 sm:inline-flex sm:w-fit [&>button]:min-h-10 [&>button]:px-3"
            >
              <TabsTrigger value="summary">Ringkasan</TabsTrigger>
              <TabsTrigger value="flow">Alur Pipeline</TabsTrigger>
              <TabsTrigger value="simulator">Detail Training</TabsTrigger>
              <TabsTrigger value="evaluation">Evaluasi</TabsTrigger>
            </TabsList>
            <TabsContent value="summary">
              {datasetStatus === "loading" && <Loading text="Memuat dataset aktif." />}
              {showDataset && (
                <DatasetVisualization
                  summary={datasetView}
                  rows={rows}
                  isDemo={datasetIsDemo}
                  rowsLoading={datasetRowsLoading}
                  rowsError={datasetRowsError}
                />
              )}
            </TabsContent>
            <TabsContent value="flow" className="space-y-4">
              <PipelineOverview onNavigate={navigateStage} />
              {datasetStatus === "loading" && <Loading text="Memuat dataset aktif." />}
              {showDataset && (
                <PreprocessingVisualization
                  key={`${datasetView.dataset.id}:${datasetView.dataset.row_count}`}
                  dataset={datasetView.dataset}
                  rows={rows}
                  isDemo={datasetIsDemo}
                  preview={preview}
                  url={url}
                  onUrlChange={setUrl}
                  onPreview={handlePreview}
                  previewBusy={previewBusy}
                  previewError={previewError}
                  preprocessing={
                    currentDetail?.preprocessing ?? (runIsDemo ? demoRun.preprocessing : null)
                  }
                />
              )}
            </TabsContent>
            <TabsContent value="simulator" className="space-y-4">
              {showDetailLoading ? (
                <Loading text="Memuat detail hasil model." />
              ) : detailUnavailable ? (
                <p className="text-sm text-muted-foreground">Detail hasil model belum tersedia.</p>
              ) : (
                <>
                  <section id="split" className="data-section scroll-mt-24">
                    <div className="table-toolbar">
                      <div>
                        <h2>Pembagian Dataset</h2>
                        <p>
                          {scheduledRun
                            ? "Target 70/15/15 berdasarkan grup domain. Proporsi baris mengikuti ukuran grup."
                            : "Jumlah baris per partisi sesuai catatan evaluasi model."}
                        </p>
                      </div>
                      <div className="flex flex-wrap items-center justify-end gap-2">
                        <SourceBadge isDemo={runIsDemo} />
                        {scheduledRun && <Badge variant="outline">Grup domain</Badge>}
                      </div>
                    </div>
                    <div className="space-y-5 p-5">
                      <SplitBar split={split} />
                      <SplitDistribution key={runView.id} run={runView} />
                      {scheduledRun && (
                        <p className="text-xs leading-5 text-muted-foreground">
                          Untuk training LinkGuard, input URL dipangkas, diubah ke huruf kecil, dan
                          dibersihkan dari skema HTTP(S). URL dengan input model yang sama dihitung
                          sekali sebelum pembagian berdasarkan grup domain.
                        </p>
                      )}
                    </div>
                  </section>

                  <section id="training" className="data-section scroll-mt-24">
                    <div className="table-toolbar">
                      <div>
                        <h2>Training LinearSVC</h2>
                        <p>Konfigurasi model dan durasi pelatihan yang tercatat.</p>
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
                            Model dilatih pada seluruh train. Validation dan test hanya dipakai
                            untuk evaluasi, bukan untuk menyesuaikan bobot model.
                          </p>
                        </div>
                      </div>
                    </div>
                  </section>
                </>
              )}
            </TabsContent>
            <TabsContent value="evaluation" className="space-y-4">
              {showDetailLoading ? (
                <Loading text="Memuat detail hasil model." />
              ) : detailUnavailable ? (
                <p className="text-sm text-muted-foreground">Detail hasil model belum tersedia.</p>
              ) : (
                <>
                  <section id="validation" className="data-section scroll-mt-24">
                    <div className="table-toolbar">
                      <div>
                        <h2>Validasi dan Perbandingan Metrik</h2>
                        <p>Perbandingan hasil validation dan test dari artefak model.</p>
                      </div>
                      <SourceBadge isDemo={runIsDemo} />
                    </div>
                    <div className="space-y-5 p-5">
                      <MetricComparison metrics={runView.metrics} />
                      <details className="rounded-lg border px-3 py-2">
                        <summary className="cursor-pointer text-sm font-medium">
                          Arti metrik
                        </summary>
                        <dl className="mt-3 grid gap-3 sm:grid-cols-2">
                          {metricDefinitions.map(([label, explanation]) => (
                            <div key={label}>
                              <dt className="text-xs font-medium">{label}</dt>
                              <dd className="mt-1 text-xs leading-5 text-muted-foreground">
                                {explanation}
                              </dd>
                            </div>
                          ))}
                        </dl>
                      </details>
                    </div>
                  </section>

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
                              F1 terendah pada test set ada di kelas{" "}
                              <strong>{weakest.label}</strong> (
                              {percent.format(weakest["f1-score"])}).
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
                      <ReportTable report={report} classes={runView.classes} />

                      <div>
                        <p className="mb-3 text-xs font-medium text-muted-foreground">
                          Confusion matrix · Test set
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
                        {selected?.is_synthetic && !runIsDemo && (
                          <p className="mt-3 text-xs leading-5 text-amber-700">
                            Artefak ini bertanda sintetis: matriksnya direkonstruksi, sehingga
                            precision per kelas tidak dapat diturunkan dari matriks dan angka ini
                            tidak boleh dianggap hasil eksperimen asli.
                          </p>
                        )}
                        {datasetMatches === false && (
                          <p className="mt-3 text-xs leading-5 text-red-700">
                            Metrik ini berasal dari versi dataset sebelumnya. Buka{" "}
                            <Link className="underline" href="/training">
                              Jadwal Training
                            </Link>{" "}
                            untuk memeriksa status dataset terbaru.
                          </p>
                        )}
                      </div>
                    </div>
                  </section>
                </>
              )}
            </TabsContent>
          </Tabs>
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
