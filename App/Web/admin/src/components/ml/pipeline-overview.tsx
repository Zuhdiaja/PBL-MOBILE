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
import { Badge } from "@/components/ui/badge";

const stages = [
  {
    id: "dataset",
    title: "Dataset",
    description: "Data mentah dari CSV aktif, termasuk jumlah baris dan kolom.",
    Icon: Database,
  },
  {
    id: "distribution",
    title: "Distribusi",
    description: "Jumlah dan proporsi setiap kelas sebelum preprocessing.",
    Icon: BarChart3,
  },
  {
    id: "preprocessing",
    title: "Preprocessing",
    description: "Pembersihan input dan normalisasi URL untuk split domain.",
    Icon: Filter,
  },
  {
    id: "tfidf",
    title: "TF-IDF",
    description: "N-gram karakter 3–5 dengan maksimal 75.000 fitur.",
    Icon: Layers,
  },
  {
    id: "split",
    title: "Split",
    description: "Train 70%, validation 15%, dan test 15%.",
    Icon: CheckCircle2,
  },
  {
    id: "training",
    title: "Training",
    description: "LinearSVC dilatih pada matriks TF-IDF data training.",
    Icon: Cpu,
  },
  {
    id: "validation",
    title: "Validation",
    description: "Perbandingan metrik pada validation dan test set.",
    Icon: BrainCircuit,
  },
  {
    id: "evaluation",
    title: "Evaluasi",
    description: "Report per kelas dan confusion matrix hasil akhir.",
    Icon: ScanSearch,
  },
];

export function PipelineOverview() {
  return (
    <section className="data-section scroll-mt-24" aria-label="Alur pipeline machine learning">
      <div className="table-toolbar">
        <div>
          <h2>Alur Pipeline ML</h2>
          <p>
            Delapan tahap dari dataset mentah sampai hasil evaluasi. Klik tahap untuk menuju detail.
          </p>
        </div>
        <Badge variant="outline">8 tahap</Badge>
      </div>
      <div className="pipeline-track p-4" aria-label="Tahapan pipeline">
        {stages.map((stage, index) => (
          <a key={stage.id} className="pipeline-step" href={`#${stage.id}`}>
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
