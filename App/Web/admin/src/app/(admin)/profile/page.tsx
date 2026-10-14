"use client";
import Image from "next/image";
import { useState } from "react";
import { Camera, CheckCircle2 } from "lucide-react";
import { useAuth } from "@/components/admin-shell";
import { Card, CardContent, CardHeader, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { ErrorNotice } from "@/components/feedback";
import { api, messageOf, type User } from "@/lib/api";
export default function Page() {
  const { user, setUser } = useAuth();
  const [name, setName] = useState(user.name);
  const [oldPassword, setOldPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [busy, setBusy] = useState("");
  const [error, setError] = useState("");
  const [feedback, setFeedback] = useState("");
  async function save(action: string, work: () => Promise<void>, message: string) {
    setBusy(action);
    setError("");
    setFeedback("");
    try {
      await work();
      setFeedback(message);
    } catch (e) {
      setError(messageOf(e));
    } finally {
      setBusy("");
    }
  }
  return (
    <>
      <div className="page-heading">
        <div>
          <h1>Profil</h1>
          <p>Kelola identitas dan keamanan akun Anda.</p>
        </div>
      </div>
      <div className="profile-content">
        {error && <ErrorNotice message={error} />}
        {feedback && (
          <div className="success-notice" aria-live="polite">
            <CheckCircle2 size={18} />
            <p>{feedback}</p>
          </div>
        )}
        <Card className="profile-section">
          <CardHeader>
            <h2>Foto profil</h2>
            <CardDescription>Foto membantu mengenali akun Anda.</CardDescription>
          </CardHeader>
          <CardContent className="avatar-editor">
            <div className="avatar large">
              {user.avatar_url ? (
                <Image
                  unoptimized
                  width={80}
                  height={80}
                  src={user.avatar_url}
                  alt={`Foto profil ${user.name}`}
                />
              ) : (
                user.name.slice(0, 1).toUpperCase()
              )}
            </div>
            <div>
              <Label htmlFor="avatar-file" className="photo-label">
                <Camera size={16} />
                Pilih foto
              </Label>
              <input
                id="avatar-file"
                aria-describedby="avatar-file-help"
                type="file"
                accept="image/jpeg,image/png,image/webp"
                disabled={!!busy}
                onChange={(e) => {
                  const file = e.target.files?.[0];
                  e.target.value = "";
                  if (!file) return;
                  if (file.size > 2 * 1024 * 1024) {
                    setError("Foto maksimal 2 MB.");
                    return;
                  }
                  void save(
                    "avatar",
                    async () => {
                      const form = new FormData();
                      form.append("file", file);
                      const data = await api<{ user: User }>("/profile/avatar", {
                        method: "PUT",
                        body: form,
                      });
                      setUser(data.user);
                    },
                    "Foto profil disimpan.",
                  );
                }}
              />
              <p className="help-text" id="avatar-file-help">
                {busy === "avatar" ? "Mengunggah foto…" : "JPEG, PNG, atau WebP. Maksimal 2 MB."}
              </p>
            </div>
          </CardContent>
        </Card>
        <Card className="profile-section">
          <CardHeader>
            <h2>Informasi akun</h2>
            <CardDescription>Nama ditampilkan di ruang kerja admin.</CardDescription>
          </CardHeader>
          <form
            aria-busy={busy === "profile"}
            className="profile-form"
            onSubmit={(e) => {
              e.preventDefault();
              void save(
                "profile",
                async () => {
                  const data = await api<{ user: User }>("/profile", {
                    method: "PATCH",
                    body: JSON.stringify({ name }),
                  });
                  setUser(data.user);
                  setName(data.user.name);
                },
                "Profil disimpan.",
              );
            }}
          >
            <div className="field">
              <Label htmlFor="profile-name">Nama</Label>
              <Input
                id="profile-name"
                value={name}
                onChange={(e) => setName(e.target.value)}
                autoComplete="name"
                required
                minLength={1}
                maxLength={120}
              />
            </div>
            <div className="field">
              <Label htmlFor="profile-email">Email</Label>
              <Input id="profile-email" value={user.email} readOnly autoComplete="email" />
              <p className="help-text">Email dikelola oleh pengelola dan tidak dapat diubah.</p>
            </div>
            <Button type="submit" disabled={!!busy || name.trim() === user.name}>
              {busy === "profile" ? "Menyimpan…" : "Simpan profil"}
            </Button>
          </form>
        </Card>
        {user.has_password ? (
          <Card className="profile-section">
            <CardHeader>
              <h2>Ganti password</h2>
              <CardDescription>Gunakan password minimal 12 karakter.</CardDescription>
            </CardHeader>
            <form
              aria-busy={busy === "password"}
              className="profile-form"
              onSubmit={(e) => {
                e.preventDefault();
                if (newPassword !== confirmPassword) {
                  setError("Konfirmasi password tidak sesuai.");
                  return;
                }
                void save(
                  "password",
                  async () => {
                    await api("/profile/password", {
                      method: "POST",
                      body: JSON.stringify({
                        old_password: oldPassword,
                        new_password: newPassword,
                      }),
                    });
                    setOldPassword("");
                    setNewPassword("");
                    setConfirmPassword("");
                  },
                  "Password diubah. Sesi perangkat lain telah diakhiri.",
                );
              }}
            >
              <div className="field">
                <Label htmlFor="old-password">Password lama</Label>
                <Input
                  id="old-password"
                  type="password"
                  autoComplete="current-password"
                  required
                  maxLength={256}
                  value={oldPassword}
                  onChange={(e) => setOldPassword(e.target.value)}
                />
              </div>
              <div className="field">
                <Label htmlFor="new-password">Password baru</Label>
                <Input
                  id="new-password"
                  type="password"
                  autoComplete="new-password"
                  required
                  minLength={12}
                  maxLength={256}
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                />
              </div>
              <div className="field">
                <Label htmlFor="confirm-password">Konfirmasi password baru</Label>
                <Input
                  id="confirm-password"
                  type="password"
                  autoComplete="new-password"
                  required
                  minLength={12}
                  maxLength={256}
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                />
              </div>
              <Button type="submit" disabled={!!busy}>
                {busy === "password" ? "Menyimpan…" : "Ubah password"}
              </Button>
            </form>
          </Card>
        ) : (
          <Card className="profile-section">
            <CardHeader>
              <h2>Metode masuk</h2>
              <CardDescription>Password akun belum diatur.</CardDescription>
            </CardHeader>
            <p className="help-text">Hubungi admin lain untuk mengatur password akun ini.</p>
          </Card>
        )}
      </div>
    </>
  );
}
