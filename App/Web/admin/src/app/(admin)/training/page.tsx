"use client";

import Link from "next/link";
import { useEffect, useState, type FormEvent } from "react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { ErrorNotice, Loading } from "@/components/feedback";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { api, messageOf, number, type MLTrainingSchedule } from "@/lib/api";

const statusLabels = {
  queued: "Training dalam antrean",
  running: "Training berjalan",
  completed: "Selesai",
  failed: "Training gagal",
  skipped: "Dilewati",
  awaiting_review: "Menunggu persetujuan",
  quality_failed: "Evaluasi belum lulus",
};

const dateFormat = new Intl.DateTimeFormat("id-ID", {
  timeZone: "Asia/Jakarta",
  dateStyle: "medium",
  timeStyle: "short",
});

export default function TrainingPage() {
  const [schedule, setSchedule] = useState<MLTrainingSchedule>();
  const [draft, setDraft] = useState<Pick<MLTrainingSchedule, "enabled" | "time">>();
  const [saving, setSaving] = useState(false);
  const [loadError, setLoadError] = useState("");
  const [saveError, setSaveError] = useState("");
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    if (saving) return;
    let cancelled = false;

    async function refresh() {
      try {
        const data = await api<MLTrainingSchedule>("/ml/schedule");
        if (!cancelled) {
          setSchedule(data);
          setLoadError("");
        }
      } catch (error) {
        if (!cancelled) setLoadError(messageOf(error));
      }
    }

    function refreshVisible() {
      if (document.visibilityState === "visible") void refresh();
    }

    refreshVisible();
    const timer = window.setInterval(refreshVisible, 10_000);
    document.addEventListener("visibilitychange", refreshVisible);
    return () => {
      cancelled = true;
      window.clearInterval(timer);
      document.removeEventListener("visibilitychange", refreshVisible);
    };
  }, [saving]);

  async function save(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!draft) return;
    setSaving(true);
    setSaveError("");
    setSaved(false);
    try {
      const data = await api<MLTrainingSchedule>("/ml/schedule", {
        method: "PUT",
        body: JSON.stringify(draft),
      });
      setSchedule(data);
      setDraft(undefined);
      setSaved(true);
    } catch (error) {
      setSaveError(messageOf(error));
    } finally {
      setSaving(false);
    }
  }

  const settings = draft ?? schedule;

  return (
    <div className="space-y-6">
      <div className="page-heading">
        <div>
          <h1>Jadwal Training</h1>
          <p>Latih ulang model secara otomatis setelah dataset CSV baru berhasil diimpor.</p>
        </div>
        <Link
          className="text-sm font-medium text-primary underline-offset-4 hover:underline"
          href="/ml"
        >
          Lihat Pipeline ML
        </Link>
      </div>

      {loadError && <ErrorNotice message={loadError} />}
      {!schedule && !loadError && <Loading text="Memuat jadwal training…" />}
      {schedule && settings && (
        <div className="grid items-start gap-5 lg:grid-cols-[minmax(0,1.15fr)_minmax(0,1fr)]">
          <section className="data-section">
            <div className="table-toolbar">
              <div>
                <h2>Pengaturan jadwal</h2>
                <p>Pemeriksaan dijalankan setiap hari pada jam yang dipilih.</p>
              </div>
            </div>
            <form className="grid gap-5 p-5" onSubmit={save}>
              <label className="flex w-fit items-center gap-2 text-sm font-medium">
                <input
                  type="checkbox"
                  className="size-4 accent-primary"
                  disabled={saving}
                  checked={settings.enabled}
                  onChange={(event) => {
                    setDraft({ enabled: event.target.checked, time: settings.time });
                    setSaved(false);
                  }}
                />
                Aktifkan training terjadwal
              </label>
              <div className="max-w-52 space-y-2">
                <Label htmlFor="training-time">Jam training (WIB)</Label>
                <Input
                  id="training-time"
                  type="time"
                  value={settings.time}
                  required
                  disabled={saving}
                  onChange={(event) => {
                    setDraft({ enabled: settings.enabled, time: event.target.value });
                    setSaved(false);
                  }}
                />
              </div>
              <p className="text-sm leading-6 text-muted-foreground">
                Pemindaian tetap memakai model aktif selama training. Model hasil training mulai
                melayani pemindaian setelah berhasil diverifikasi dan diaktifkan.
              </p>
              {saveError && <ErrorNotice message={saveError} />}
              <div className="flex flex-wrap items-center gap-3">
                <Button type="submit" disabled={!draft || saving}>
                  {saving ? "Menyimpan…" : "Simpan jadwal"}
                </Button>
                <output className="text-sm text-muted-foreground">
                  {saved && "Jadwal tersimpan."}
                </output>
              </div>
            </form>
          </section>

          <section className="data-section">
            <div className="table-toolbar">
              <div>
                <h2>Status training</h2>
                <p>Dataset aktif dan hasil pemeriksaan terakhir.</p>
              </div>
              <Badge variant={schedule.enabled ? "secondary" : "outline"}>
                {schedule.enabled ? "Jadwal aktif" : "Jadwal nonaktif"}
              </Badge>
            </div>
            <dl className="divide-y border-t text-sm" aria-live="polite">
              <div className="space-y-2 p-5">
                <dt className="font-medium">Dataset aktif</dt>
                <dd className="break-all text-foreground">
                  {schedule.dataset?.filename ?? "Belum ada dataset"}
                </dd>
                {schedule.dataset && (
                  <dd className="text-muted-foreground">
                    {number.format(schedule.dataset.row_count)} baris ·{" "}
                    {schedule.pending_dataset ? "Menunggu training" : "Sudah dilatih"}
                  </dd>
                )}
              </div>
              <div className="space-y-2 p-5">
                <dt className="font-medium">Pemeriksaan terakhir</dt>
                <dd>
                  {schedule.last_status
                    ? statusLabels[schedule.last_status]
                    : "Belum ada pemeriksaan"}
                  {schedule.last_started_at && (
                    <span className="text-muted-foreground">
                      {" · "}
                      {dateFormat.format(new Date(schedule.last_started_at))} WIB
                    </span>
                  )}
                </dd>
                {schedule.last_message && (
                  <dd className="leading-6 text-muted-foreground">{schedule.last_message}</dd>
                )}
              </div>
            </dl>
          </section>
        </div>
      )}
    </div>
  );
}
