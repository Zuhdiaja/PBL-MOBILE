/* oxlint-disable react/set-state-in-effect -- Effect fetches server session state asynchronously. */
"use client";
import { Suspense, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { ArrowRight, LockKeyhole, ShieldCheck } from "lucide-react";
import { Brand } from "@/components/admin-shell";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { ErrorNotice, Loading } from "@/components/feedback";
import { api, setCsrf, messageOf } from "@/lib/api";
function Login() {
  const router = useRouter();
  const [ready, setReady] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  async function load() {
    try {
      const data = await api<{ csrf_token: string }>("/auth/csrf");
      setCsrf(data.csrf_token);
      setReady(true);
      setError("");
    } catch (e) {
      setError(messageOf(e));
    }
  }
  useEffect(() => {
    void load();
  }, []);
  return (
    <main className="login-page">
      <div className="login-main">
        <header className="login-brand">
          <Brand />
        </header>
        <section className="login-content" aria-labelledby="login-title">
          <div className="login-heading">
            <h1 id="login-title">Masuk ke dashboard</h1>
            <p>Gunakan email dan password akun admin Anda.</p>
          </div>
          <div>
            {error && <ErrorNotice message={error} retry={() => void load()} />}
            <form
              className="login-form"
              aria-busy={busy}
              onSubmit={async (event) => {
                event.preventDefault();
                if (busy || !ready) return;
                setBusy(true);
                setError("");
                try {
                  const data = await api<{ csrf_token: string }>("/auth/login", {
                    method: "POST",
                    body: JSON.stringify({ email, password }),
                  });
                  setCsrf(data.csrf_token);
                  router.replace("/datasets");
                } catch (e) {
                  setError(messageOf(e));
                } finally {
                  setBusy(false);
                }
              }}
            >
              <div className="field">
                <Label htmlFor="email">Email</Label>
                <Input
                  id="email"
                  type="email"
                  autoComplete="username"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                  maxLength={254}
                />
              </div>
              <div className="field">
                <Label htmlFor="password">Password</Label>
                <Input
                  id="password"
                  type="password"
                  autoComplete="current-password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  maxLength={256}
                />
              </div>
              <Button className="login-submit" disabled={busy || !ready} type="submit">
                {busy ? "Memeriksa…" : "Masuk"}
                <ArrowRight aria-hidden="true" />
              </Button>
            </form>
          </div>
          <div className="login-access-note">
            <LockKeyhole size={16} aria-hidden="true" />
            <p>Hubungi pengelola LinkGuard jika Anda membutuhkan akses admin.</p>
          </div>
        </section>
      </div>
      <aside className="login-aside" aria-label="Ruang kerja LinkGuard">
        <div className="login-signal" aria-hidden="true">
          <span className="login-signal-mark">
            <ShieldCheck size={48} strokeWidth={1.35} />
          </span>
        </div>
        <div className="login-aside-copy">
          <h2>Kelola keamanan tautan.</h2>
          <p>Dataset URL, laporan pengguna, dan model deteksi LinkGuard.</p>
        </div>
      </aside>
    </main>
  );
}
export default function Page() {
  return (
    <Suspense fallback={<Loading />}>
      <Login />
    </Suspense>
  );
}
