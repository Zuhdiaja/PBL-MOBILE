import {
  BarChart3,
  BrainCircuit,
  CheckCircle2,
  Cpu,
  Database,
  Filter,
  Layers,
  ScanSearch,
} from "lucide-react";

const stages = [
  {
    id: "dataset",
    tab: "summary" as const,
    title: "Dataset",
    description: "Data mentah dari CSV aktif, termasuk jumlah baris dan kolom.",
    Icon: Database,
  },
  {
    id: "distribution",
    tab: "summary" as const,
    title: "Distribusi",
    description: "Jumlah dan proporsi setiap kelas sebelum preprocessing.",
    Icon: BarChart3,
  },
  {
    id: "preprocessing",
    tab: "flow" as const,
    title: "Preprocessing",
    description: "Pembersihan input dan normalisasi URL untuk split domain.",
    Icon: Filter,
  },
  {
    id: "tfidf",
    tab: "flow" as const,
    title: "TF-IDF",
    description: "N-gram karakter 3–5 dengan maksimal 75.000 fitur.",
    Icon: Layers,
  },
  {
    id: "split",
    tab: "simulator" as const,
    title: "Split",
    description: "Pembagian train, validation, dan test.",
    Icon: CheckCircle2,
  },
  {
    id: "training",
    tab: "simulator" as const,
    title: "Training",
    description: "LinearSVC dilatih pada matriks TF-IDF data training.",
    Icon: Cpu,
  },
  {
    id: "validation",
    tab: "evaluation" as const,
    title: "Validation",
    description: "Perbandingan metrik pada validation dan test set.",
    Icon: BrainCircuit,
  },
  {
    id: "evaluation",
    tab: "evaluation" as const,
    title: "Evaluasi",
    description: "Report per kelas dan confusion matrix hasil akhir.",
    Icon: ScanSearch,
  },
];

export function PipelineOverview({
  onNavigate,
}: {
  onNavigate: (tab: (typeof stages)[number]["tab"], id: string) => void;
}) {
  return (
    <section className="data-section scroll-mt-24" aria-label="Alur pipeline machine learning">
      <div className="table-toolbar">
        <div>
          <h2>Alur Pipeline ML</h2>
          <p>Pilih tahap untuk membuka detailnya.</p>
        </div>
      </div>
      <div className="pipeline-track p-4" aria-label="Tahapan pipeline">
        {stages.map((stage, index) => (
          <a
            key={stage.id}
            className="pipeline-step"
            href={`#${stage.id}`}
            onClick={(event) => {
              event.preventDefault();
              onNavigate(stage.tab, stage.id);
            }}
          >
            <span className="pipeline-step-index">{index + 1}</span>
            <stage.Icon aria-hidden="true" className="size-5 text-primary" />
            <span className="text-sm font-medium">{stage.title}</span>
            <span className="text-xs leading-5 text-muted-foreground">{stage.description}</span>
          </a>
        ))}
      </div>
    </section>
  );
}
