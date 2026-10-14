export type User = {
  id: number;
  email: string;
  name: string;
  has_password: boolean;
  avatar_url: string | null;
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
