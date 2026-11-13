/* oxlint-disable jsx-a11y/no-noninteractive-tabindex -- Scrollable preprocessing tables must be keyboard reachable. */
"use client";
import { useState, type FormEvent } from "react";
import {
  AlertTriangle,
  Binary,
  Braces,
  Eraser,
  FileText,
  Globe2,
  Play,
  Table2,
} from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { ErrorNotice } from "@/components/feedback";
import type { DataRow, Dataset, MLPreviewResponse } from "@/lib/api";
import { number } from "@/lib/api";
import { demoPreview, demoRows, exampleNgrams } from "@/lib/ml-demo";

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

const stages = [
  {
    id: "raw",
    title: "Data URL mentah",
    summary: "CSV dibaca sebagai string",
    Icon: FileText,
  },
  {
    id: "clean",
    title: "Pembersihan input",
    summary: "Trim URL dan normalisasi label",
    Icon: Eraser,
  },
  {
    id: "normalize",
    title: "Normalisasi URL",
    summary: "Dipakai untuk split domain",
    Icon: Globe2,
  },
  {
    id: "tfidf",
    title: "Ekstraksi TF-IDF",
    summary: "N-gram karakter 3–5",
    Icon: Binary,
  },
  {
    id: "ngram",
    title: "N-gram karakter",
    summary: "Contoh token fitur",
    Icon: Braces,
  },
  {
    id: "result",
    title: "Hasil preprocessing",
    summary: "Pratinjau data siap pakai",
    Icon: Table2,
  },
] as const;

type StageId = (typeof stages)[number]["id"];

function NgramGroup({ label, ngrams }: { label: string; ngrams: MLPreviewResponse["ngrams"] }) {
  const sizes = ["3", "4", "5"] as const;
  return (
    <div className="space-y-4">
      <p className="text-xs font-medium text-muted-foreground">{label}</p>
      {sizes.map((size) => (
        <div key={size}>
          <p className="mb-2 text-[11px] font-medium text-muted-foreground">
            N-gram {size} karakter
          </p>
          {ngrams[size].length ? (
            <div className="flex flex-wrap gap-2">
              {ngrams[size].map((item) => (
                <span
                  key={`${label}-${size}-${item.token}`}
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

export function PreprocessingVisualization({
  dataset,
  rows,
  isDemo,
  preview,
  url,
  onUrlChange,
  onPreview,
  previewBusy,
  previewError,
  preprocessing,
}: {
  dataset: Dataset;
  rows: DataRow[];
  isDemo: boolean;
  preview: MLPreviewResponse | null;
  url: string;
  onUrlChange: (value: string) => void;
  onPreview: (event: FormEvent) => void;
  previewBusy: boolean;
  previewError: string;
  preprocessing?: string | null;
}) {
  const [activeStage, setActiveStage] = useState<StageId>("raw");
  const urlIndex = Math.max(
    dataset.columns.findIndex((column) => column.toLowerCase().includes("url")),
    0,
  );
  const labelIndex = dataset.columns.findIndex((column) =>
    ["label", "category", "class", "type"].some((key) => column.toLowerCase().includes(key)),
  );
  const activePreview = preview ?? demoPreview;
  const previewIsDemo = !preview;
  const sampleRow = rows[0] ?? (isDemo ? demoRows[0] : null);
  const sampleUrl = sampleRow?.values[urlIndex] ?? "";
  const sampleLabel = labelIndex >= 0 ? (sampleRow?.values[labelIndex] ?? "") : "";
  const cleanedRows = rows.slice(0, 10).map((row) => {
    const rawUrl = row.values[urlIndex] ?? "";
    const rawLabel = labelIndex >= 0 ? (row.values[labelIndex] ?? "") : "";
    const cleanUrl = rawUrl.trim();
    const cleanLabel = rawLabel.trim().toLowerCase();
    return {
      rowNumber: row.row_number,
      rawUrl,
      rawLabel,
      cleanUrl,
      cleanLabel,
      ready: Boolean(cleanUrl) && (labelIndex < 0 || Boolean(cleanLabel)),
    };
  });
  const changedUrls = rows.filter(
    (row) => (row.values[urlIndex] ?? "") !== (row.values[urlIndex] ?? "").trim(),
  ).length;
  const emptyUrls = rows.filter((row) => !(row.values[urlIndex] ?? "").trim()).length;

  return (
    <section id="preprocessing" className="data-section scroll-mt-24">
      <div className="table-toolbar">
        <div>
          <h2>Preprocessing</h2>
          <p>
            Tahapan nyata yang dipakai notebook: pembersihan input, normalisasi split, dan TF-IDF.
          </p>
        </div>
        <div className="flex flex-wrap items-center justify-end gap-2">
          {isDemo ? (
            <Badge variant="secondary" className="bg-amber-500/10 text-amber-700">
              Data simulasi
            </Badge>
          ) : (
            <Badge variant="outline">Data API</Badge>
          )}
          <Badge variant="outline">6 tahap</Badge>
        </div>
      </div>

      <div className="grid gap-0 lg:grid-cols-[280px_minmax(0,1fr)]">
        <div className="border-b p-4 lg:border-r lg:border-b-0">
          <div className="preprocess-timeline" aria-label="Tahapan preprocessing">
            {stages.map((stage, index) => (
              <button
                key={stage.id}
                type="button"
                className="preprocess-stage"
                data-active={activeStage === stage.id}
                aria-pressed={activeStage === stage.id}
                onClick={() => setActiveStage(stage.id)}
              >
                <span className="preprocess-dot">{index + 1}</span>
                <span className="min-w-0">
                  <span className="flex items-center gap-2 text-sm font-medium">
                    <stage.Icon aria-hidden="true" className="size-3.5 shrink-0" />
                    {stage.title}
                  </span>
                  <span className="mt-0.5 block text-[11px] leading-4 text-muted-foreground">
                    {stage.summary}
                  </span>
                </span>
              </button>
            ))}
          </div>
        </div>

        <div className="min-w-0 p-5">
          {activeStage === "raw" && (
            <div className="space-y-5">
              <div>
                <h3 className="font-medium">Data mentah dibaca sebagai string</h3>
                <p className="mt-1 text-sm leading-6 text-muted-foreground">
                  Notebook memakai{" "}
                  <code>pandas.read_csv(..., dtype=str, keep_default_na=False)</code>. Semua nilai
                  dipertahankan sebagai teks; tidak ada konversi tipe atau imputasi.
                </p>
              </div>
              <div className="grid gap-3 sm:grid-cols-3">
                <div className="rounded-lg border bg-muted/30 p-3">
                  <p className="text-[11px] text-muted-foreground">File</p>
                  <p className="mt-1 break-all text-sm font-medium">{dataset.filename}</p>
                </div>
                <div className="rounded-lg border bg-muted/30 p-3">
                  <p className="text-[11px] text-muted-foreground">Baris</p>
                  <p className="mt-1 text-sm font-medium tabular-nums">
                    {number.format(dataset.row_count)}
                  </p>
                </div>
                <div className="rounded-lg border bg-muted/30 p-3">
                  <p className="text-[11px] text-muted-foreground">Kolom</p>
                  <p className="mt-1 text-sm font-medium tabular-nums">{dataset.columns.length}</p>
                </div>
              </div>
              <div>
                <p className="mb-2 text-xs font-medium text-muted-foreground">Header CSV</p>
                <div className="flex flex-wrap gap-2">
                  {dataset.columns.map((column) => (
                    <Badge key={column} variant="secondary">
                      {column}
                    </Badge>
                  ))}
                </div>
              </div>
              <div className="rounded-lg border bg-muted/30 p-4">
                <p className="text-xs font-medium text-muted-foreground">Contoh baris mentah</p>
                <p className="mt-2 break-all font-mono text-xs">
                  {sampleUrl || "—"} <span className="text-muted-foreground">|</span>{" "}
                  {sampleLabel || "—"}
                </p>
              </div>
            </div>
          )}

          {activeStage === "clean" && (
            <div className="space-y-5">
              <div>
                <h3 className="font-medium">Pembersihan input</h3>
                <p className="mt-1 text-sm leading-6 text-muted-foreground">
                  URL di-<code>strip</code> dan label di-<code>strip</code> lalu diubah ke huruf
                  kecil. Tidak ada baris yang dihapus dan duplikat tetap dipertahankan.
                </p>
              </div>
              <div className="table-scroll rounded-lg border" tabIndex={0}>
                <table>
                  <thead>
                    <tr>
                      <th>Field</th>
                      <th>Sebelum</th>
                      <th>Sesudah</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td className="font-medium">URL</td>
                      <td className="break-all font-mono text-xs">{sampleUrl || "—"}</td>
                      <td className="break-all font-mono text-xs">{sampleUrl.trim() || "—"}</td>
                    </tr>
                    <tr>
                      <td className="font-medium">Label</td>
                      <td className="font-mono text-xs">{sampleLabel || "—"}</td>
                      <td className="font-mono text-xs">
                        {sampleLabel.trim().toLowerCase() || "—"}
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <div className="grid gap-3 sm:grid-cols-3">
                <div className="rounded-lg border p-3 text-sm">
                  <p className="text-[11px] text-muted-foreground">Baris dihapus</p>
                  <p className="mt-1 font-semibold">0</p>
                </div>
                <div className="rounded-lg border p-3 text-sm">
                  <p className="text-[11px] text-muted-foreground">Duplikat</p>
                  <p className="mt-1 font-semibold">Dipertahankan</p>
                </div>
                <div className="rounded-lg border p-3 text-sm">
                  <p className="text-[11px] text-muted-foreground">Imputasi missing</p>
                  <p className="mt-1 font-semibold">Tidak diterapkan</p>
                </div>
              </div>
              <p className="rounded-lg border border-amber-500/25 bg-amber-500/10 p-3 text-xs leading-5 text-amber-800">
                Notebook memastikan URL dan label tidak kosong. Karena itu tidak ada tahap
                <span className="font-medium"> handling missing values</span> atau encoding label
                tambahan pada pipeline ini.
              </p>
            </div>
          )}

          {activeStage === "normalize" && (
            <div className="space-y-5">
              <div>
                <h3 className="font-medium">Normalisasi URL untuk split domain-disjoint</h3>
                <p className="mt-1 text-sm leading-6 text-muted-foreground">
                  Normalisasi hostname dipakai untuk mengelompokkan eTLD+1 saat membagi data. Input
                  model tetap URL yang sudah di-<code>strip</code>, bukan hasil normalisasi ini.
                </p>
              </div>
              <form className="flex flex-col gap-3 sm:flex-row sm:items-end" onSubmit={onPreview}>
                <div className="w-full">
                  <Label htmlFor="ml-url">Coba URL lain</Label>
                  <Input
                    id="ml-url"
                    className="mt-2"
                    value={url}
                    maxLength={2048}
                    placeholder="https://contoh.test/login"
                    onChange={(event) => onUrlChange(event.target.value)}
                  />
                </div>
                <Button type="submit" disabled={previewBusy || !url.trim()}>
                  <Play aria-hidden="true" />
                  {previewBusy ? "Memproses." : "Proses"}
                </Button>
              </form>
              {previewError && <ErrorNotice message={previewError} />}
              <div className="flex flex-wrap items-center gap-2">
                {previewIsDemo ? (
                  <Badge variant="secondary" className="bg-amber-500/10 text-amber-700">
                    Contoh normalisasi
                  </Badge>
                ) : (
                  <Badge variant="outline">Hasil API</Badge>
                )}
                {activePreview.steps.map((step) => (
                  <Badge key={step} variant="secondary">
                    {stepLabels[step] ?? step}
                  </Badge>
                ))}
                {activePreview.normalized.parse_failed && (
                  <Badge variant="destructive">
                    <AlertTriangle aria-hidden="true" />
                    Parse gagal
                  </Badge>
                )}
              </div>
              <div className="table-scroll rounded-lg border" tabIndex={0}>
                <table>
                  <thead>
                    <tr>
                      <th>Field</th>
                      <th>Sebelum</th>
                      <th>Sesudah</th>
                    </tr>
                  </thead>
                  <tbody>
                    {[
                      ["Raw", activePreview.normalized.raw, activePreview.normalized.text],
                      [
                        "Input model",
                        activePreview.normalized.raw,
                        activePreview.model_input || "—",
                      ],
                      [
                        "Host",
                        activePreview.normalized.host || "—",
                        activePreview.normalized.canonical_host || "—",
                      ],
                      [
                        "eTLD+1",
                        activePreview.normalized.site || "—",
                        activePreview.normalized.site || "—",
                      ],
                      [
                        "IP",
                        activePreview.normalized.is_ip ? "Ya" : "Tidak",
                        activePreview.normalized.is_ip
                          ? activePreview.normalized.canonical_host
                          : "Tidak",
                      ],
                    ].map(([label, before, after]) => (
                      <tr key={label}>
                        <td className="font-medium">{label}</td>
                        <td className="break-all font-mono text-xs">{before}</td>
                        <td className="break-all font-mono text-xs">{after}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {activeStage === "tfidf" && (
            <div className="space-y-5">
              <div>
                <h3 className="font-medium">Ekstraksi fitur TF-IDF karakter</h3>
                <p className="mt-1 text-sm leading-6 text-muted-foreground">
                  Setiap URL diubah menjadi vektor sparse dari frekuensi n-gram karakter. Matriks
                  penuh tidak dikirim ke frontend; yang ditampilkan hanya parameter dan contoh
                  token.
                </p>
              </div>
              <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
                {tfidfParameters.map(([name, value]) => (
                  <div key={name} className="rounded-lg border bg-muted/30 p-3">
                    <p className="font-mono text-[11px] text-muted-foreground">{name}</p>
                    <p className="mt-1 text-sm font-medium">{value}</p>
                  </div>
                ))}
              </div>
              {preprocessing && (
                <p className="break-all rounded-lg border bg-muted/30 p-3 font-mono text-[11px] leading-5 text-muted-foreground">
                  {preprocessing}
                </p>
              )}
              <p className="rounded-lg border border-amber-500/25 bg-amber-500/10 p-3 text-xs leading-5 text-amber-800">
                Token n-gram adalah contoh representasi fitur, bukan keseluruhan matriks TF-IDF.
                Bobot IDF dan matriks 75.000 fitur tidak ditampilkan di dashboard.
              </p>
            </div>
          )}

          {activeStage === "ngram" && (
            <div className="space-y-6">
              <div>
                <h3 className="font-medium">Contoh n-gram karakter</h3>
                <p className="mt-1 text-sm leading-6 text-muted-foreground">
                  Ukuran 3, 4, dan 5 karakter diambil dari jendela teks yang saling tumpang tindih.
                  Contoh di bawah berasal dari kata <code>login</code> pada notebook.
                </p>
              </div>
              <NgramGroup label="Contoh notebook: login" ngrams={exampleNgrams} />
              <div className="border-t pt-5">
                <NgramGroup
                  label={
                    previewIsDemo
                      ? "Contoh token dari URL simulasi"
                      : "Token dari URL yang baru diproses"
                  }
                  ngrams={activePreview.ngrams}
                />
              </div>
              <p className="text-xs leading-5 text-muted-foreground">
                Jumlah token di sini hanya ilustrasi. Matriks TF-IDF sebenarnya memiliki hingga
                75.000 fitur dan bobot yang dihitung dari seluruh data training.
              </p>
            </div>
          )}

          {activeStage === "result" && (
            <div className="space-y-5">
              <div>
                <h3 className="font-medium">Hasil preprocessing</h3>
                <p className="mt-1 text-sm leading-6 text-muted-foreground">
                  Pratinjau ini menerapkan pembersihan input yang sama dengan notebook pada baris
                  yang tersedia. Tidak ada data yang dikirim balik atau diubah di server.
                </p>
              </div>
              <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
                <div className="rounded-lg border p-3">
                  <p className="text-[11px] text-muted-foreground">Sebelum</p>
                  <p className="mt-1 text-lg font-semibold tabular-nums">
                    {number.format(dataset.row_count)}
                  </p>
                  <p className="text-[11px] text-muted-foreground">baris dataset</p>
                </div>
                <div className="rounded-lg border p-3">
                  <p className="text-[11px] text-muted-foreground">Sesudah</p>
                  <p className="mt-1 text-lg font-semibold tabular-nums">
                    {number.format(dataset.row_count)}
                  </p>
                  <p className="text-[11px] text-muted-foreground">tidak ada penghapusan baris</p>
                </div>
                <div className="rounded-lg border p-3">
                  <p className="text-[11px] text-muted-foreground">URL berubah</p>
                  <p className="mt-1 text-lg font-semibold tabular-nums">
                    {number.format(changedUrls)}
                  </p>
                  <p className="text-[11px] text-muted-foreground">dari pratinjau</p>
                </div>
                <div className="rounded-lg border p-3">
                  <p className="text-[11px] text-muted-foreground">URL kosong</p>
                  <p className="mt-1 text-lg font-semibold tabular-nums">
                    {number.format(emptyUrls)}
                  </p>
                  <p className="text-[11px] text-muted-foreground">dari pratinjau</p>
                </div>
              </div>
              <div className="table-scroll rounded-lg border" tabIndex={0}>
                <table>
                  <thead>
                    <tr>
                      <th>No.</th>
                      <th>URL mentah</th>
                      <th>URL bersih</th>
                      <th>Label mentah</th>
                      <th>Label bersih</th>
                      <th>Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {cleanedRows.map((row) => (
                      <tr key={row.rowNumber}>
                        <td>{number.format(row.rowNumber)}</td>
                        <td className="break-all font-mono text-xs">{row.rawUrl || "—"}</td>
                        <td className="break-all font-mono text-xs">{row.cleanUrl || "—"}</td>
                        <td className="font-mono text-xs">{row.rawLabel || "—"}</td>
                        <td className="font-mono text-xs">{row.cleanLabel || "—"}</td>
                        <td>
                          <Badge variant={row.ready ? "secondary" : "destructive"}>
                            {row.ready ? "Siap" : "Perlu perhatian"}
                          </Badge>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
                {cleanedRows.length === 0 && (
                  <p className="table-empty">Belum ada baris pratinjau yang dapat ditampilkan.</p>
                )}
              </div>
              <p className="text-xs leading-5 text-muted-foreground">
                Perubahan jumlah baris sebelum/sesudah adalah sama karena pipeline tidak melakukan
                drop, sampling, atau deduplikasi. Tabel hanya menampilkan maksimal 10 baris
                pratinjau.
              </p>
            </div>
          )}
        </div>
      </div>

      <div id="tfidf" className="scroll-mt-24 border-t p-5">
        <div className="mb-4 flex flex-wrap items-start justify-between gap-3">
          <div>
            <h3 className="font-medium">Representasi TF-IDF</h3>
            <p className="mt-1 text-sm leading-6 text-muted-foreground">
              Parameter nyata dari <code>TfidfVectorizer</code> yang dipakai notebook. Matriks fitur
              tidak dikirim ke frontend.
            </p>
          </div>
          <Badge variant="outline">N-gram karakter</Badge>
        </div>
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 xl:grid-cols-7">
          {tfidfParameters.map(([name, value]) => (
            <div key={name} className="rounded-lg border bg-muted/30 p-3">
              <p className="font-mono text-[11px] text-muted-foreground">{name}</p>
              <p className="mt-1 break-all text-sm font-medium">{value}</p>
            </div>
          ))}
        </div>
        {preprocessing && (
          <p className="mt-3 break-all rounded-lg border bg-muted/30 p-3 font-mono text-[11px] leading-5 text-muted-foreground">
            {preprocessing}
          </p>
        )}
      </div>
    </section>
  );
}
