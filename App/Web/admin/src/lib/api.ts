export type User = {
  id: number;
  email: string;
  name: string;
  has_password: boolean;
  avatar_url: string | null;
};
export type Dataset = {
  id: string;
  filename: string;
  columns: string[];
  row_count: number;
  uploaded_at: string;
};
export type ImportJob = {
  id: string;
  filename: string;
  status: "queued" | "running" | "succeeded" | "failed";
  row_count: number;
  error: string | null;
};
export type DatasetResponse = { dataset: Dataset | null; latest_import: ImportJob | null };
export type DataRow = { row_number: number; values: string[] };
export type RowsResponse = {
  dataset_id: string;
  rows: DataRow[];
  page: number;
  page_size: number;
  page_count: number;
  row_count: number;
};
export class ApiError extends Error {
  constructor(
    public code: string,
    message: string,
    public status: number,
  ) {
    super(message);
  }
}
let csrfToken = "";
export function setCsrf(token: string) {
  csrfToken = token;
}
export async function api<T>(path: string, options: RequestInit = {}): Promise<T> {
  const headers = new Headers(options.headers);
  const method = options.method || "GET";
  if (method !== "GET") {
    if (!csrfToken) {
      const response = await api<{ csrf_token: string }>("/auth/csrf");
      csrfToken = response.csrf_token;
    }
    headers.set("X-CSRF-Token", csrfToken);
    if (!(options.body instanceof FormData)) headers.set("Content-Type", "application/json");
  }
  let response: Response;
  try {
    response = await fetch(`/api/v1${path}`, {
      ...options,
      headers,
      credentials: "same-origin",
      cache: "no-store",
    });
  } catch {
    throw new ApiError(
      "network_error",
      "Tidak dapat terhubung ke layanan. Periksa koneksi lalu coba lagi.",
      0,
    );
  }
  const data = await response.json().catch(() => null);
  if (!response.ok) {
    if (
      response.status === 401 &&
      typeof window !== "undefined" &&
      window.location.pathname !== "/login"
    )
      window.location.assign("/login");
    throw new ApiError(
      data?.error?.code || "request_error",
      data?.error?.message || "Layanan tidak merespons. Coba lagi.",
      response.status,
    );
  }
  return data as T;
}
export function messageOf(error: unknown) {
  return error instanceof Error ? error.message : "Terjadi kesalahan. Coba lagi.";
}
export const number = new Intl.NumberFormat("id-ID");

export type AccountKind = "admin" | "mobile";
export type ManagedUser = {
  id: number;
  kind: AccountKind;
  name: string;
  email: string;
  active: boolean;
  has_password: boolean;
};
export type UsersResponse = {
  kind: AccountKind;
  items: ManagedUser[];
  page: number;
  page_size: number;
  row_count: number;
  page_count: number;
};

export type ReportStageStatus = "submitted" | "review" | "completed" | "rejected";
export type PredictionReport = {
  id: number;
  url: string;
  report_type: "False Positive" | "False Negative";
  reported_category: string;
  status: ReportStageStatus;
  notes: string | null;
  admin_notes: string | null;
  reporter_email: string | null;
  dataset_id: string | null;
  dataset_synced: boolean;
  created_at: string;
  updated_at: string;
};
export type ReportsSummary = {
  total: number;
  submitted: number;
  review: number;
  completed: number;
  synced: number;
};
export type ReportsResponse = {
  items: PredictionReport[];
  page: number;
  page_size: number;
  page_count: number;
  row_count: number;
  summary: ReportsSummary;
};
