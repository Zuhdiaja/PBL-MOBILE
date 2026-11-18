"use client";

import { useId, useState } from "react";
import { ChevronDown } from "lucide-react";
import { number, percent, type MLRunDetail } from "@/lib/api";

const splits = [
  { id: "train", label: "Train", description: "Melatih LinearSVC" },
  { id: "validation", label: "Validation", description: "Evaluasi validasi" },
  { id: "test", label: "Test", description: "Evaluasi akhir" },
] as const;

type Split = (typeof splits)[number];

function distribution(run: MLRunDetail, role: Split["id"]) {
  const rows = [];
  for (const label of run.classes) {
    const count =
      role === "train"
        ? run.provenance.train_class_counts?.[label]
        : run.report[role]?.[label]?.support;
    if (typeof count !== "number" || !Number.isSafeInteger(count) || count < 0) return null;
    rows.push({ label, count });
  }
  return rows.reduce((sum, row) => sum + row.count, 0) === run.split_counts[role] ? rows : null;
}

export function SplitDistribution({ run }: { run: MLRunDetail }) {
  const [selected, setSelected] = useState<Split | null>(null);
  const panelId = useId();
  const total = selected ? run.split_counts[selected.id] : 0;
  const rows = selected ? distribution(run, selected.id) : null;

  return (
    <div className="space-y-4">
      <div className="grid gap-2 sm:grid-cols-3">
        {splits.map((split) => {
          const expanded = selected?.id === split.id;
          return (
            <button
              key={split.id}
              type="button"
              aria-expanded={expanded}
              aria-controls={panelId}
              className="group flex items-start justify-between gap-3 rounded-lg border bg-card p-3 text-left hover:border-primary aria-expanded:border-primary aria-expanded:bg-primary/5"
              onClick={() => setSelected(expanded ? null : split)}
            >
              <span className="grid gap-1">
                <span className="text-xs font-medium text-muted-foreground">{split.label}</span>
                <span className="text-lg font-semibold tabular-nums">
                  {number.format(run.split_counts[split.id])}
                </span>
                <span className="text-xs text-muted-foreground">{split.description}</span>
              </span>
              <ChevronDown
                aria-hidden="true"
                className="size-4 shrink-0 text-muted-foreground group-aria-expanded:rotate-180"
              />
            </button>
          );
        })}
      </div>

      <section
        id={panelId}
        hidden={!selected}
        aria-labelledby={`${panelId}-heading`}
        className="rounded-lg border bg-card p-3 sm:p-4"
      >
        {selected && (
          <>
            <div className="flex flex-wrap items-baseline justify-between gap-1">
              <h3 id={`${panelId}-heading`} className="text-sm font-semibold">
                Distribusi {selected.label}
              </h3>
              <p className="text-xs text-muted-foreground">{number.format(total)} baris</p>
            </div>
            {!rows ? (
              <p className="mt-2 text-sm text-muted-foreground">
                Jumlah per kelas belum tersedia untuk run ini.
              </p>
            ) : total === 0 ? (
              <p className="mt-2 text-sm text-muted-foreground">Split ini tidak berisi baris.</p>
            ) : (
              <table className="mt-3 w-full text-xs sm:text-sm">
                <thead className="border-b text-muted-foreground">
                  <tr>
                    <th scope="col" className="pb-2 text-left font-medium">
                      Kelas
                    </th>
                    <th scope="col" className="px-2 pb-2 text-right font-medium">
                      Jumlah
                    </th>
                    <th scope="col" className="pb-2 text-right font-medium">
                      Persentase
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y">
                  {rows.map(({ label, count }) => (
                    <tr key={label}>
                      <th
                        scope="row"
                        className="py-2 text-left font-medium [overflow-wrap:anywhere]"
                      >
                        {label}
                      </th>
                      <td className="px-2 py-2 text-right tabular-nums">{number.format(count)}</td>
                      <td className="py-2 text-right tabular-nums">
                        {percent.format(count / total)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </>
        )}
      </section>
    </div>
  );
}
