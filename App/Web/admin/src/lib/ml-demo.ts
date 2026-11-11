import type { DataRow, Dataset, MLDatasetSummary, MLPreviewResponse, MLRunDetail } from "@/lib/api";

const demoNormalizedText = "http://paypal-login.example/verify?user=1";
const demoModelInput = "paypal-login.example/verify?user=1";

function buildNgrams(text: string, sizes: Array<3 | 4 | 5>, limit = 20) {
  const result: MLPreviewResponse["ngrams"] = {
    "3": [],
    "4": [],
    "5": [],
    total_tokens: 0,
  };
  for (const size of sizes) {
    const counts = new Map<string, number>();
    for (let index = 0; index <= text.length - size; index += 1) {
      const token = text.slice(index, index + size);
      counts.set(token, (counts.get(token) ?? 0) + 1);
    }
    result[String(size) as "3" | "4" | "5"] = [...counts.entries()]
      .sort((left, right) => right[1] - left[1])
      .slice(0, limit)
      .map(([token, count]) => ({ token, count }));
    result.total_tokens += [...counts.values()].reduce((sum, count) => sum + count, 0);
  }
  return result;
}

/**
 * Data contoh untuk mode simulasi. Semua nilai di file ini hanya dipakai jika
 * dashboard belum menerima dataset atau artefak dari API.
 */
export const demoDataset: Dataset = {
  id: "demo-murl-2026",
  filename: "Malicious URL Detection.csv",
  columns: ["url", "type"],
  row_count: 783705,
  uploaded_at: "2026-11-05T00:00:00+00:00",
};

export const demoClassCounts = [
  { label: "benign", count: 318000 },
  { label: "defacement", count: 73000 },
  { label: "exploit", count: 1200 },
  { label: "legitimate", count: 8500 },
  { label: "malware", count: 21000 },
  { label: "phishing", count: 301000 },
  { label: "spam", count: 61005 },
];

export const demoDatasetSummary: MLDatasetSummary = {
  dataset: demoDataset,
  label_column: "type",
  class_counts: demoClassCounts,
};

export const demoRows: DataRow[] = [
  {
    row_number: 1,
    values: ["  https://www.google.com  ", "Benign"],
  },
  {
    row_number: 2,
    values: ["HTTP://PayPal-Login.Example./verify?user=1", "Phishing"],
  },
  {
    row_number: 3,
    values: ["http://192.168.10.5/login.php", "Malware"],
  },
  {
    row_number: 4,
    values: ["https://bbc.co.uk/news", "Benign"],
  },
  {
    row_number: 5,
    values: ["http://defacement-sample.test/index.html", "Defacement"],
  },
  {
    row_number: 6,
    values: ["http://exploit-sample.test/shell.php", "Exploit"],
  },
  {
    row_number: 7,
    values: ["https://legitimate-sample.test/", "Legitimate"],
  },
  {
    row_number: 8,
    values: ["http://spam-sample.test/win", "Spam"],
  },
];

export const demoPreview: MLPreviewResponse = {
  model_input: demoModelInput,
  normalized: {
    raw: "  HTTP://PayPal-Login.Example./verify?user=1  ",
    scheme: "http",
    host: "PayPal-Login.Example.",
    canonical_host: "paypal-login.example",
    site: "paypal-login.example",
    is_ip: false,
    path: "/verify",
    query: "user=1",
    fragment: "",
    parse_failed: false,
    steps: ["trim", "lowercase_scheme", "lowercase_host", "strip_root_dot"],
    text: demoNormalizedText,
  },
  steps: ["trim", "lowercase_scheme", "lowercase_host", "strip_root_dot"],
  ngrams: buildNgrams(demoModelInput, [3, 4, 5]),
};

export const exampleNgrams: MLPreviewResponse["ngrams"] = {
  "3": [
    { token: "log", count: 1 },
    { token: "ogi", count: 1 },
    { token: "gin", count: 1 },
  ],
  "4": [
    { token: "logi", count: 1 },
    { token: "ogin", count: 1 },
  ],
  "5": [{ token: "login", count: 1 }],
  total_tokens: 6,
};

export const demoRun: MLRunDetail = {
  id: "contoh-artefak-notebook",
  model: "svm",
  representation: "tfidf",
  status: "completed",
  classes: ["benign", "defacement", "exploit", "legitimate", "malware", "phishing", "spam"],
  metrics: {
    validation: {
      accuracy: 0.8634,
      balanced_accuracy: 0.6261,
      macro_f1: 0.652,
      weighted_f1: 0.8648,
    },
    test: {
      accuracy: 0.8358,
      balanced_accuracy: 0.685,
      macro_f1: 0.7064,
      weighted_f1: 0.8393,
    },
  },
  report: {
    validation: {
      benign: { precision: 0.8967, recall: 0.9065, "f1-score": 0.9016, support: 63965 },
      defacement: { precision: 0.9495, recall: 0.7634, "f1-score": 0.8464, support: 14295 },
      exploit: { precision: 0.875, recall: 0.3784, "f1-score": 0.5283, support: 37 },
      legitimate: { precision: 0.2301, recall: 0.4569, "f1-score": 0.306, support: 871 },
      malware: { precision: 0.9095, recall: 0.7944, "f1-score": 0.8481, support: 3541 },
      phishing: { precision: 0.8055, recall: 0.8501, "f1-score": 0.8272, support: 34438 },
      spam: { precision: 0.4465, recall: 0.233, "f1-score": 0.3062, support: 412 },
      "macro avg": { precision: 0.7304, recall: 0.6261, "f1-score": 0.652, support: 117559 },
      "weighted avg": {
        precision: 0.8703,
        recall: 0.8634,
        "f1-score": 0.8648,
        support: 117559,
      },
    },
    test: {
      benign: { precision: 0.8927, recall: 0.8613, "f1-score": 0.8767, support: 63969 },
      defacement: { precision: 0.9574, recall: 0.7931, "f1-score": 0.8675, support: 14294 },
      exploit: { precision: 0.96, recall: 0.6667, "f1-score": 0.7869, support: 36 },
      legitimate: { precision: 0.2072, recall: 0.4243, "f1-score": 0.2784, support: 872 },
      malware: { precision: 0.8219, recall: 0.6684, "f1-score": 0.7372, support: 3534 },
      phishing: { precision: 0.7395, recall: 0.8373, "f1-score": 0.7854, support: 34437 },
      spam: { precision: 0.7022, recall: 0.5437, "f1-score": 0.6129, support: 412 },
      "macro avg": { precision: 0.7544, recall: 0.685, "f1-score": 0.7064, support: 117554 },
      "weighted avg": {
        precision: 0.8479,
        recall: 0.8358,
        "f1-score": 0.8393,
        support: 117554,
      },
    },
  },
  confusion_matrix: [
    [55096, 2367, 6, 144, 585, 5702, 69],
    [1832, 11337, 1, 25, 101, 986, 12],
    [7, 1, 24, 0, 0, 4, 0],
    [275, 61, 0, 370, 15, 148, 3],
    [658, 147, 0, 9, 2362, 354, 4],
    [4312, 964, 2, 59, 238, 28834, 28],
    [103, 23, 0, 1, 6, 55, 224],
  ],
  split_counts: { train: 548592, validation: 117559, test: 117554 },
  params: {
    C: 1.0,
    class_weight: "balanced",
    dual: false,
    fit_intercept: true,
    intercept_scaling: 1,
    loss: "squared_hinge",
    max_iter: 10000,
    multi_class: "ovr",
    penalty: "l2",
    random_state: 42,
    seed: 42,
    tol: 0.0001,
    verbose: 0,
  },
  preprocessing:
    "TfidfVectorizer(analyzer='char', dtype=<class 'numpy.float32'>, lowercase=False, max_features=75000, min_df=2, ngram_range=(3, 5), sublinear_tf=True)",
  row_count: 783705,
  input_features: 75000,
  fit_seconds: 121.5,
  dataset_id: null,
  dataset_sha256: null,
  is_synthetic: true,
  dataset_matches: null,
  completed_at: "2026-11-05T00:00:00+00:00",
  created_at: "2026-11-05T00:00:00+00:00",
  provenance: {
    split_design_version: "icann-domain-disjoint-v3",
    example_notice:
      "Matriks direkonstruksi dari recall dan support karena notebook hanya menyimpan matriks sebagai gambar.",
    is_synthetic: true,
  },
};
