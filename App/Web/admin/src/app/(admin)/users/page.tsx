/* oxlint-disable react/set-state-in-effect -- Synchronize account list with URL and server mutations. */
/* oxlint-disable jsx-a11y/no-noninteractive-tabindex -- Scrollable account table must be keyboard reachable. */
"use client";
import { useEffect, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import {
  UsersRound,
  UserPlus,
  MoreHorizontal,
  Pencil,
  KeyRound,
  UserCheck,
  UserX,
  ChevronLeft,
  ChevronRight,
  ShieldCheck,
  Smartphone,
  CheckCircle2,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Dialog,
  DialogContent,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from "@/components/ui/dialog";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuGroup,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { ErrorNotice, Loading } from "@/components/feedback";
import { useAuth } from "@/components/admin-shell";
import {
  api,
  messageOf,
  number,
  type AccountKind,
  type ManagedUser,
  type UsersResponse,
} from "@/lib/api";
type Action = "create" | "edit" | "password" | "status";
const kinds = { admin: "Admin dashboard", mobile: "Pengguna mobile" };
export default function Page() {
  const { user, setUser } = useAuth();
  const params = useSearchParams();
  const router = useRouter();
  const kind: AccountKind = params.get("kind") === "mobile" ? "mobile" : "admin";
  const rawPage = Number(params.get("page") || 1);
  const page = Number.isSafeInteger(rawPage) && rawPage > 0 ? rawPage : 1;
  const rawSize = Number(params.get("page_size") || 25);
  const size = [25, 50, 100].includes(rawSize) ? rawSize : 25;
  const [data, setData] = useState<UsersResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [retry, setRetry] = useState(0);
  const [notice, setNotice] = useState("");
  const [action, setAction] = useState<Action | null>(null);
  const [selected, setSelected] = useState<ManagedUser | null>(null);
  const [dialogKind, setDialogKind] = useState<AccountKind>(kind);
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [saving, setSaving] = useState(false);
  const [formError, setFormError] = useState("");
  function changePage(next: number, nextKind = kind, nextSize = size) {
    router.replace(`/users?kind=${nextKind}&page=${next}&page_size=${nextSize}`, { scroll: false });
  }
  useEffect(() => {
    const controller = new AbortController();
    setLoading(true);
    setError("");
    void api<UsersResponse>(`/users?kind=${kind}&page=${page}&page_size=${size}`, {
      signal: controller.signal,
    })
      .then((response) => {
        if (!controller.signal.aborted) setData(response);
      })
      .catch((e) => {
        if (!controller.signal.aborted) setError(messageOf(e));
      })
      .finally(() => {
        if (!controller.signal.aborted) setLoading(false);
      });
    return () => controller.abort();
  }, [kind, page, size, retry]);
  function open(next: Action, account: ManagedUser | null = null) {
    setAction(next);
    setSelected(account);
    setDialogKind(account?.kind || kind);
    setName(account?.name || "");
    setEmail(account?.email || "");
    setPassword("");
    setConfirm("");
    setFormError("");
  }
  function close() {
    if (saving) return;
    setAction(null);
    setPassword("");
    setConfirm("");
  }
  async function submit() {
    if (!action) return;
    if ((action === "password" || (action === "create" && password)) && password !== confirm) {
      setFormError("Konfirmasi password tidak sesuai.");
      return;
    }
    setSaving(true);
    setFormError("");
    try {
      const path =
        action === "create"
          ? `/users/${dialogKind}`
          : `/users/${dialogKind}/${selected!.id}${action === "password" ? "/password" : ""}`;
      const payload =
        action === "create"
          ? { name, email, password }
          : action === "edit"
            ? { name }
            : action === "password"
              ? { password }
              : { active: !selected!.active };
      const result = await api<{ user: ManagedUser; message: string }>(path, {
        method: action === "create" || action === "password" ? "POST" : "PATCH",
        body: JSON.stringify(payload),
      });
      if (dialogKind === "admin" && result.user.id === user.id)
        setUser({ ...user, name: result.user.name });
      setNotice(
        action === "status"
          ? `Akun ${result.user.email} ${result.user.active ? "diaktifkan" : "dinonaktifkan"}.`
          : result.message,
      );
      setAction(null);
      setPassword("");
      setConfirm("");
      setRetry((n) => n + 1);
    } catch (e) {
      setFormError(messageOf(e));
    } finally {
      setSaving(false);
    }
  }
  const current =
    !loading && data?.kind === kind && data.page === page && data.page_size === size ? data : null;
  const title =
    action === "create"
      ? `Tambah ${dialogKind === "admin" ? "admin" : "pengguna mobile"}`
      : action === "password"
        ? "Atur password"
        : action === "status"
          ? `${selected?.active ? "Nonaktifkan" : "Aktifkan"} akun?`
          : "Edit akun";
  return (
    <>
      <div className="page-heading">
        <div>
          <h1>Pengguna</h1>
          <p>Kelola akun admin dashboard dan pengguna aplikasi mobile.</p>
        </div>
        <Button onClick={() => open("create")}>
          <UserPlus />
          Tambah akun
        </Button>
      </div>
      {notice && (
        <div className="success-notice" aria-live="polite">
          <CheckCircle2 size={18} />
          <p>{notice}</p>
          <Button variant="ghost" onClick={() => setNotice("")} aria-label="Tutup pemberitahuan">
            Tutup
          </Button>
        </div>
      )}
      <Tabs
        value={kind}
        onValueChange={(value) => {
          if (value === "admin" || value === "mobile") {
            setNotice("");
            changePage(1, value);
          }
        }}
        className="users-tabs"
      >
        <TabsList aria-label="Jenis akun">
          <TabsTrigger value="admin">
            <ShieldCheck />
            Admin dashboard
          </TabsTrigger>
          <TabsTrigger value="mobile">
            <Smartphone />
            Pengguna mobile
          </TabsTrigger>
        </TabsList>
        <TabsContent value={kind}>
          {error ? (
            <ErrorNotice message={error} retry={() => setRetry((n) => n + 1)} />
          ) : !current ? (
            <Loading text="Memuat daftar pengguna…" />
          ) : current.items.length === 0 ? (
            <section className="empty-state">
              <UsersRound size={38} strokeWidth={1.5} />
              <h2>Belum ada {kind === "admin" ? "admin" : "pengguna mobile"}</h2>
              <p>Tambahkan akun yang ingin dikelola. Akun baru akan muncul di daftar ini.</p>
              <Button onClick={() => open("create")}>
                <UserPlus />
                Tambah akun
              </Button>
            </section>
          ) : (
            <section className="users-table-frame" aria-label={`Daftar ${kinds[kind]}`}>
              <div className="table-toolbar">
                <div>
                  <h2>{kinds[kind]}</h2>
                  <p>
                    {kind === "admin"
                      ? "Akun dengan akses ke ruang kerja LinkGuard."
                      : "Akun aplikasi mobile yang tersimpan di layanan LinkGuard."}
                  </p>
                </div>
                <Badge variant="outline">{number.format(current.row_count)} akun</Badge>
              </div>
              <section
                className="users-table-scroll"
                aria-label="Tabel pengguna, gulir untuk melihat kolom lainnya"
                tabIndex={0}
              >
                <Table>
                  <caption className="sr-only">
                    {kinds[kind]}, halaman {page} dari {current.page_count}
                  </caption>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Nama</TableHead>
                      <TableHead>Email</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead>Metode masuk</TableHead>
                      <TableHead className="account-actions">
                        <span className="sr-only">Aksi</span>
                      </TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {current.items.map((account) => {
                      const self = kind === "admin" && account.id === user.id;
                      return (
                        <TableRow key={account.id}>
                          <TableCell>
                            <div className="managed-name">
                              {account.name}
                              {self && <Badge variant="outline">Anda</Badge>}
                            </div>
                          </TableCell>
                          <TableCell>{account.email}</TableCell>
                          <TableCell>
                            <Badge
                              variant="secondary"
                              className={account.active ? "account-active" : "account-inactive"}
                            >
                              {account.active ? "Aktif" : "Nonaktif"}
                            </Badge>
                          </TableCell>
                          <TableCell>
                            <div className="login-methods">
                              {account.has_password && <Badge variant="outline">Password</Badge>}
                              {!account.has_password && (
                                <Badge variant="outline">Belum diatur</Badge>
                              )}
                            </div>
                          </TableCell>
                          <TableCell className="account-actions">
                            <DropdownMenu>
                              <DropdownMenuTrigger
                                render={
                                  <Button
                                    variant="ghost"
                                    size="icon"
                                    aria-label={`Aksi untuk ${account.email}`}
                                  />
                                }
                              >
                                <MoreHorizontal />
                              </DropdownMenuTrigger>
                              <DropdownMenuContent align="end" className="min-w-48">
                                <DropdownMenuGroup>
                                  {self && <DropdownMenuLabel>Akun Anda</DropdownMenuLabel>}
                                  <DropdownMenuItem onClick={() => open("edit", account)}>
                                    <Pencil />
                                    Edit akun
                                  </DropdownMenuItem>
                                  <DropdownMenuItem
                                    disabled={self}
                                    onClick={() => open("password", account)}
                                  >
                                    <KeyRound />
                                    Atur password
                                  </DropdownMenuItem>
                                  <DropdownMenuItem
                                    disabled={self}
                                    variant={account.active ? "destructive" : "default"}
                                    onClick={() => open("status", account)}
                                  >
                                    {account.active ? <UserX /> : <UserCheck />}
                                    {account.active ? "Nonaktifkan" : "Aktifkan"}
                                  </DropdownMenuItem>
                                </DropdownMenuGroup>
                              </DropdownMenuContent>
                            </DropdownMenu>
                          </TableCell>
                        </TableRow>
                      );
                    })}
                  </TableBody>
                </Table>
              </section>
              <div className="pagination">
                <p>
                  {number.format((page - 1) * size + 1)}–
                  {number.format(Math.min(page * size, current.row_count))} dari{" "}
                  {number.format(current.row_count)} akun
                </p>
                <div className="pagination-controls">
                  <Label htmlFor="users-page-size">Akun per halaman</Label>
                  <select
                    id="users-page-size"
                    value={size}
                    onChange={(e) => changePage(1, kind, Number(e.target.value))}
                  >
                    {[25, 50, 100].map((n) => (
                      <option key={n} value={n}>
                        {n}
                      </option>
                    ))}
                  </select>
                  <span className="page-indicator">
                    {page} / {current.page_count}
                  </span>
                  <Button
                    variant="outline"
                    size="icon"
                    aria-label="Halaman pengguna sebelumnya"
                    disabled={page <= 1}
                    onClick={() => changePage(page - 1)}
                  >
                    <ChevronLeft />
                  </Button>
                  <Button
                    variant="outline"
                    size="icon"
                    aria-label="Halaman pengguna berikutnya"
                    disabled={page >= current.page_count}
                    onClick={() => changePage(page + 1)}
                  >
                    <ChevronRight />
                  </Button>
                </div>
              </div>
            </section>
          )}
        </TabsContent>
      </Tabs>
      <p className="users-footnote">
        {kind === "admin"
          ? "Akun Anda tidak dapat dinonaktifkan dari halaman ini. Ubah password sendiri melalui Profil."
          : "Nonaktifkan akun untuk mengubah statusnya tanpa menghapus data."}
      </p>
      <Dialog
        open={action !== null}
        onOpenChange={(value) => {
          if (!value) close();
        }}
      >
        <DialogContent className="user-dialog" aria-busy={saving} showCloseButton={!saving}>
          <DialogTitle>{title}</DialogTitle>
          <DialogDescription>
            {action === "create" ? (
              `Akun ditambahkan sebagai ${dialogKind === "admin" ? "admin dashboard" : "pengguna mobile"}.`
            ) : action === "status" ? (
              <>
                Status akun <strong>{selected?.email}</strong> akan diubah menjadi{" "}
                {selected?.active ? "nonaktif" : "aktif"}.
                {dialogKind === "admin" &&
                  selected?.active &&
                  " Sesi dashboard akun tersebut akan diakhiri."}
              </>
            ) : action === "password" ? (
              <>
                Tetapkan password baru untuk <strong>{selected?.email}</strong>.
                {dialogKind === "admin" && " Sesi dashboard akun tersebut akan diakhiri."}
              </>
            ) : (
              "Perbarui nama akun."
            )}
          </DialogDescription>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              void submit();
            }}
            aria-busy={saving}
          >
            {formError && <ErrorNotice message={formError} />}
            {(action === "create" || action === "edit") && (
              <>
                <div className="field">
                  <Label htmlFor="account-name">Nama</Label>
                  <Input
                    id="account-name"
                    autoComplete="off"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    maxLength={120}
                    required
                    disabled={saving}
                  />
                </div>
                <div className="field">
                  <Label htmlFor="account-email">Email</Label>
                  <Input
                    id="account-email"
                    type="email"
                    autoComplete="off"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    maxLength={254}
                    required
                    readOnly={action === "edit"}
                    disabled={saving}
                  />
                  {action === "edit" && (
                    <p className="help-text">
                      Email menjadi identitas akun dan tidak dapat diubah.
                    </p>
                  )}
                </div>
              </>
            )}
            {(action === "create" || action === "password") && (
              <>
                <div className="field">
                  <Label htmlFor="account-password">
                    {action === "create" ? "Password awal" : "Password baru"}
                  </Label>
                  <Input
                    id="account-password"
                    type="password"
                    autoComplete="new-password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    minLength={12}
                    maxLength={256}
                    required
                    disabled={saving}
                    aria-describedby="account-password-help"
                  />
                  <p className="help-text" id="account-password-help">
                    12–256 karakter.
                  </p>
                </div>
                {
                  <div className="field">
                    <Label htmlFor="account-confirm">Konfirmasi password</Label>
                    <Input
                      id="account-confirm"
                      type="password"
                      autoComplete="new-password"
                      value={confirm}
                      onChange={(e) => setConfirm(e.target.value)}
                      minLength={12}
                      maxLength={256}
                      required
                      disabled={saving}
                    />
                  </div>
                }
              </>
            )}
            <DialogFooter>
              <Button type="button" variant="outline" disabled={saving} onClick={close}>
                Batal
              </Button>
              <Button
                type="submit"
                variant={action === "status" && selected?.active ? "destructive" : "default"}
                disabled={saving}
              >
                {saving
                  ? "Menyimpan…"
                  : action === "status"
                    ? selected?.active
                      ? "Nonaktifkan akun"
                      : "Aktifkan akun"
                    : action === "create"
                      ? "Tambah akun"
                      : "Simpan perubahan"}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
    </>
  );
}
