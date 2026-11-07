/* oxlint-disable jsx-a11y/no-noninteractive-tabindex -- Scrollable preview tables must be keyboard reachable. */
import {
  AlertCircle,
  Database,
  FileSpreadsheet,
  Rows3,
  Tags,
} from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { ErrorNotice } from "@/components/feedback";
import type { DataRow, MLDatasetSummary } from "@/lib/api";
import { number, percent } from "@/lib/api";

function SourceBadge({ isDemo }: { isDemo: boolean }) {
  return isDemo ? (
    <Badge variant="secondary" className="bg-amber-500/10 text-amber-700">
      Data simulasi
    </Badge>
  ) : (
    <Badge variant="outline">Data API</Badge>
  );
}

function SummaryCard({
  label,
  value,
  hint,
  Icon,
}: {
  label: string;
  value: string;
  hint: string;
  Icon: typeof Database;
}) {
  return (
    <div className="rounded-xl border bg-card p-4 shadow-xs">
      <div className="flex items-center justify-between gap-3">
        <p className="text-xs font-medium text-muted-foreground">{label}</p>
        <Icon aria-hidden="true" className="size-4 text-primary" />
      </div>
      <p className="mt-2 text-xl font-semibold tabular-nums">{value}</p>
      <p className="mt-1 text-[11px] leading-4 text-muted-foreground">{hint}</p>
    </div>
  );
}

const chartColors = [
  "#2563eb",
  "#f59e0b",
  "#ef4444",
  "#10b981",
  "#8b5cf6",
  "#ec4899",
  "#6366f1",
];

function DistributionChart({
  items,
  total,
}: {
  items: MLDatasetSummary["class_counts"];
  total: number;
}) {
  const width = 920;
  const height = 350;
  const plot = { top: 28, right: 30, bottom: 72, left: 72 };
  const plotWidth = width - plot.left - plot.right;
  const plotHeight = height - plot.top - plot.bottom;
  const maximum = Math.max(...items.map((item) => item.count), 1);
  const minimum = Math.min(
    ...items.filter((item) => item.count > 0).map((item) => item.count),
    1,
  );
  const logMin = Math.floor(Math.log10(minimum));
  const logMax = Math.ceil(Math.log10(maximum));
  const range = Math.max(logMax - logMin, 1);
  const ticks = Array.from({ length: range + 1 }, (_, index) =>
    Math.pow(10, logMin + index),
  );
  const slot = plotWidth / items.length;
  const barWidth = Math.min(70, slot * 0.62);
  const yFor = (value: number) =>
    plot.top + ((logMax - Math.log10(Math.max(value, 1))) / range) * plotHeight;

  return (
    <div className="overflow-x-auto rounded-xl border bg-muted/20 p-3 sm:p-5">
      <svg
        aria-label={`Grafik batang distribusi ${items.length} kelas, total ${number.format(total)} baris`}
        viewBox={`0 0 ${width} ${height}`}
        className="block min-w-170 w-full"
      >
        <title>Distribusi kelas dataset pada skala logaritmik</title>
        {ticks.map((tick) => {
          const y = yFor(tick);
          return (
            <g key={tick}>
              <line
                x1={plot.left}
                x2={width - plot.right}
                y1={y}
                y2={y}
                stroke="#dbe2ea"
                strokeDasharray="4 4"
              />
              <text
                x={plot.left - 10}
                y={y + 4}
                textAnchor="end"
                fill="#586579"
                fontSize="11"
              >
                {number.format(tick)}
              </text>
            </g>
          );
        })}
        <line
          x1={plot.left}
          x2={plot.left}
          y1={plot.top}
          y2={height - plot.bottom}
          stroke="#9aa7b8"
        />
        <line
          x1={plot.left}
          x2={width - plot.right}
          y1={height - plot.bottom}
          y2={height - plot.bottom}
          stroke="#9aa7b8"
        />
        {items.map((item, index) => {
          const color = chartColors[index % chartColors.length];
          const x = plot.left + slot * index + (slot - barWidth) / 2;
          const y = yFor(item.count);
          const barHeight = Math.max(height - plot.bottom - y, 2);
          const label =
            item.label.length > 13 ? `${item.label.slice(0, 12)}…` : item.label;
          return (
            <g key={item.label} className="group">
              <title>{`${item.label}: ${number.format(item.count)} URL (${percent.format(item.count / total)})`}</title>
              <rect
                x={x}
                y={y}
                width={barWidth}
                height={barHeight}
                rx="5"
                fill={color}
                opacity="0.9"
              />
              <text
                x={x + barWidth / 2}
                y={height - plot.bottom + 20}
                textAnchor="middle"
                fill="#586579"
                fontSize="11"
              >
                {label}
              </text>
              <text
                x={x + barWidth / 2}
                y={Math.max(y - 8, plot.top + 11)}
                textAnchor="middle"
                fill={color}
                fontSize="11"
                fontWeight="600"
              >
                {number.format(item.count)}
              </text>
            </g>
          );
        })}
        <text x={plot.left} y={14} fill="#586579" fontSize="11">
          Jumlah URL · skala logaritmik
        </text>
      </svg>
    </div>
  );
}

export function DatasetVisualization({
  summary,
  rows,
  isDemo,
  rowsLoading = false,
  rowsError = "",
}: {
  summary: MLDatasetSummary;
  rows: DataRow[];
  isDemo: boolean;
  rowsLoading?: boolean;
  rowsError?: string;
}) {
  const columns = summary.dataset.columns;
  const previewRows = rows.slice(0, 25);
  const classTotal = summary.class_counts.reduce(
    (sum, item) => sum + item.count,
    0,
  );
  const maxClass = summary.class_counts.reduce(
    (max, item) => Math.max(max, item.count),
    0,
  );
  const minClass = summary.class_counts.reduce(
    (min, item) => Math.min(min, item.count),
    Number.POSITIVE_INFINITY,
  );
  const ratio = minClass > 0 ? maxClass / minClass : Number.POSITIVE_INFINITY;
  const balance =
    summary.class_counts.length === 0
      ? { label: "Belum ada label", className: "text-muted-foreground" }
      : ratio <= 1.5
        ? { label: "Relatif seimbang", className: "text-emerald-700" }
        : ratio <= 5
          ? { label: "Cukup tidak seimbang", className: "text-amber-700" }
          : { label: "Tidak seimbang", className: "text-red-700" };

  const attributes = columns.map((name, index) => {
    const values = previewRows.map((row) => row.values[index] ?? "");
    return {
      name,
      sample: values.find((value) => value.trim()) ?? "—",
      missing: values.filter((value) => !value.trim()).length,
    };
  });
  const missingTotal = previewRows.reduce(
    (total, row) =>
      total +
      columns.filter((_, index) => !(row.values[index] ?? "").trim()).length,
    0,
  );

  return (
    <div className="space-y-6">
      <section id="dataset" className="data-section scroll-mt-24">
        <div className="table-toolbar">
          <div>
            <h2>Dataset Awal</h2>
            <p>
              Pratinjau data mentah sebelum pembersihan input dan representasi
              TF-IDF.
            </p>
          </div>
          <div className="flex flex-wrap items-center justify-end gap-2">
            <SourceBadge isDemo={isDemo} />
            <Badge variant="outline">{summary.dataset.filename}</Badge>
          </div>
        </div>
        <div className="space-y-5 p-5">
          <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
            <SummaryCard
              label="Jumlah baris"
              value={number.format(summary.dataset.row_count)}
              hint="Seluruh baris pada dataset aktif"
              Icon={Rows3}
            />
            <SummaryCard
              label="Jumlah kolom"
              value={number.format(columns.length)}
              hint="Header CSV dibaca sebagai atribut"
              Icon={FileSpreadsheet}
            />
            <SummaryCard
              label="Kelas label"
              value={number.format(summary.class_counts.length)}
              hint={
                summary.label_column
                  ? `Kolom ${summary.label_column}`
                  : "Kolom label tidak ditemukan"
              }
              Icon={Tags}
            />
            <SummaryCard
              label="Missing values"
              value={number.format(missingTotal)}
              hint={
                previewRows.length
                  ? `Dari ${number.format(previewRows.length)} baris pratinjau`
                  : "Pratinjau belum tersedia"
              }
              Icon={AlertCircle}
            />
          </div>

          {rowsError && <ErrorNotice message={rowsError} />}

          <div>
            <div className="mb-3 flex flex-wrap items-center justify-between gap-2">
              <p className="text-xs font-medium text-muted-foreground">
                Pratinjau data mentah · maksimal 25 baris
              </p>
              <Badge variant="outline">
                {number.format(columns.length)} kolom
              </Badge>
            </div>
            <div className="table-scroll rounded-lg border" tabIndex={0}>
              <table>
                <thead>
                  <tr>
                    <th>No.</th>
                    {columns.map((column, index) => (
                      <th key={`${column}-${index}`}>
                        {column || `Kolom ${index + 1}`}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {previewRows.map((row) => (
                    <tr key={row.row_number}>
                      <td>{number.format(row.row_number)}</td>
                      {columns.map((_, index) => (
                        <td key={`${row.row_number}-${index}`}>
                          {row.values[index] === "" ? (
                            <span className="text-muted-foreground italic">
                              kosong
                            </span>
                          ) : (
                            (row.values[index] ?? "")
                          )}
                        </td>
                      ))}
                    </tr>
                  ))}
                </tbody>
              </table>
              {!rowsLoading && previewRows.length === 0 && (
                <p className="table-empty">
                  Dataset ini belum memiliki baris data.
                </p>
              )}
              {rowsLoading && (
                <p className="table-empty">Memuat pratinjau dataset.</p>
              )}
            </div>
          </div>

          <div>
            <p className="mb-3 text-xs font-medium text-muted-foreground">
              Informasi atribut dan missing values pada pratinjau
            </p>
            <div className="table-scroll rounded-lg border" tabIndex={0}>
              <table>
                <thead>
                  <tr>
                    <th>Atribut</th>
                    <th>Tipe</th>
                    <th>Contoh nilai</th>
                    <th>Missing</th>
                  </tr>
                </thead>
                <tbody>
                  {attributes.map((attribute) => (
                    <tr key={attribute.name}>
                      <td className="font-medium">
                        {attribute.name || "Tanpa nama"}
                      </td>
                      <td>Teks (string)</td>
                      <td className="break-all font-mono text-xs">
                        {attribute.sample}
                      </td>
                      <td className="tabular-nums">
                        {number.format(attribute.missing)} /{" "}
                        {number.format(previewRows.length)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <p className="mt-3 text-xs leading-5 text-muted-foreground">
              API saat ini belum menyediakan total missing values seluruh
              dataset. Angka di atas hanya dihitung dari baris pratinjau yang
              ditampilkan, bukan klaim untuk seluruh data.
            </p>
          </div>
        </div>
      </section>

      <section id="distribution" className="data-section scroll-mt-24">
        <div className="table-toolbar">
          <div>
            <h2>Distribusi Dataset</h2>
            <p>
              Jumlah dan persentase setiap kelas sebelum masuk ke pipeline
              Machine Learning.
            </p>
          </div>
          <div className="flex flex-wrap items-center justify-end gap-2">
            <SourceBadge isDemo={isDemo} />
            <Badge variant="outline" className={balance.className}>
              {balance.label}
            </Badge>
          </div>
        </div>
        <div className="p-5">
          {summary.class_counts.length === 0 ? (
            <p className="text-sm text-muted-foreground">
              Dataset aktif tidak memiliki kolom label yang dapat dihitung.
            </p>
          ) : (
            <div className="space-y-4">
              <div>
                <p className="mb-3 text-xs leading-5 text-muted-foreground">
                  Perbandingan volume antarkelas. Sumbu vertikal memakai skala
                  logaritmik supaya kelas dengan jumlah kecil tetap kebaca.
                </p>
                <DistributionChart
                  items={summary.class_counts}
                  total={classTotal}
                />
              </div>
              {summary.class_counts.map((item) => {
                const percentage = classTotal ? item.count / classTotal : 0;
                return (
                  <div key={item.label}>
                    <div className="mb-1 flex flex-wrap items-center justify-between gap-2 text-xs">
                      <span className="font-medium">{item.label}</span>
                      <span className="tabular-nums text-muted-foreground">
                        {number.format(item.count)} ·{" "}
                        {percent.format(percentage)}
                      </span>
                    </div>
                    <div className="h-2.5 overflow-hidden rounded-full bg-muted">
                      <div
                        className="h-full rounded-full bg-primary/75"
                        style={{
                          width: `${Math.max(percentage * 100, item.count ? 1.5 : 0)}%`,
                        }}
                      />
                    </div>
                  </div>
                );
              })}
              <div className="grid gap-3 border-t pt-4 text-xs text-muted-foreground sm:grid-cols-3">
                <p>
                  Total baris berlabel:{" "}
                  <strong className="text-foreground">
                    {number.format(classTotal)}
                  </strong>
                </p>
                <p>
                  Kelas terbesar:{" "}
                  <strong className="text-foreground">
                    {number.format(maxClass)}
                  </strong>
                </p>
                <p>
                  Rasio kelas terbesar/terkecil:{" "}
                  <strong className="text-foreground">
                    {Number.isFinite(ratio) ? `${ratio.toFixed(1)}×` : "—"}
                  </strong>
                </p>
              </div>
            </div>
          )}
        </div>
      </section>
    </div>
  );
}