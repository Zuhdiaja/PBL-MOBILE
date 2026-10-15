/* oxlint-disable react/set-state-in-effect -- Effect fetches server session state asynchronously. */
"use client";
import { Suspense, useEffect, useState } from "react";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { ArrowRight, LockKeyhole } from "lucide-react";
import { Brand } from "@/components/admin-shell";
import { Card, CardHeader, CardContent, CardFooter } from "@/components/ui/card";
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
        <div className="login-brand">
          <Brand />
        </div>
        <Card className="login-form">
          <CardHeader className="login-card-header">
            <h1>Masuk ke LinkGuard</h1>
            <p className="intro">Masuk untuk mengelola data dan akses LinkGuard.</p>
          </CardHeader>
          <CardContent className="login-card-content">
            {error && <ErrorNotice message={error} retry={() => void load()} />}
            <form
              aria-busy={busy}
              onSubmit={async (event) => {
                event.preventDefault();
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
                  placeholder="admin@example.com"
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
              <Button className="full-width" disabled={busy || !ready} type="submit">
                {busy ? "Memeriksa…" : "Masuk"}
                <ArrowRight />
              </Button>
            </form>
          </CardContent>
          <CardFooter className="access-note">
            <LockKeyhole size={15} aria-hidden="true" />
            <p>
              Hanya untuk admin yang telah diberi akses. Hubungi pengelola jika Anda membutuhkan
              akun.
            </p>
          </CardFooter>
        </Card>
        <footer className="login-footer">LinkGuard · Ruang kerja admin</footer>
      </div>
      <aside className="login-aside" aria-label="LinkGuard, ruang kerja admin">
        <div className="login-aside-content">
          <Image
            className="login-illustration"
            src="/illustrations/url-security.webp"
            sizes="(min-width: 1024px) 440px, 1px"
            width={1280}
            height={1280}
            alt=""
            decoding="async"
          />
          <h2>LinkGuard</h2>
          <p>Administrasi data dan akses.</p>
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
