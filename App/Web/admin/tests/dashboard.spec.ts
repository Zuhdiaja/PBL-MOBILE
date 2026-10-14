import { test, expect, type Page } from "@playwright/test";
import { mkdir } from "node:fs/promises";
const email = process.env.E2E_EMAIL || "e2e@example.com";
const password = process.env.E2E_PASSWORD || "e2e-only-password-2026";
async function navigate(page: Page, name: "Dataset" | "Profil" | "Pengguna") {
  const menu = page.getByRole("button", { name: "Buka navigasi" });
  if (await menu.isVisible()) await menu.click();
  await page.getByRole("link", { name, exact: true }).filter({ visible: true }).click();
}
async function login(page: Page) {
  await page.goto("/login");
  await page.getByLabel("Email", { exact: true }).fill(email);
  await page.getByLabel("Password", { exact: true }).fill(password);
  await page.getByRole("button", { name: "Masuk", exact: true }).click();
  await expect(page.getByRole("heading", { name: "Dataset", exact: true })).toBeVisible();
}
async function logout(page: Page) {
  const menu = page.getByRole("button", { name: "Buka navigasi" });
  if (await menu.isVisible()) await menu.click();
  await page
    .getByRole("button", { name: "Menu akun", exact: true })
    .filter({ visible: true })
    .click();
  await page.getByRole("menuitem", { name: "Keluar", exact: true }).click();
  await expect(page).toHaveURL(/\/login$/);
}
test("login → impor → pagination → profil → logout", async ({ page }, info) => {
  const errors: string[] = [];
  page.on("pageerror", (error) => errors.push(error.message));
  await page.goto("/login");
  await expect(page.getByRole("button", { name: "Masuk dengan Google" })).toHaveCount(0);
  await expect(page.getByRole("link", { name: /daftar|registrasi/i })).toHaveCount(0);
  await mkdir("test-results/screenshots", { recursive: true });
  await expect(page.getByRole("button", { name: "Masuk", exact: true })).toBeEnabled();
  if (info.project.name === "desktop") {
    await expect(page.locator(".login-illustration")).not.toHaveJSProperty("naturalWidth", 0);
  }
  await page.screenshot({
    path: `test-results/screenshots/login-${info.project.name}.png`,
    animations: "disabled",
  });
  await page.getByLabel("Email", { exact: true }).fill(email);
  await page.getByLabel("Password", { exact: true }).fill("wrong-password");
  await page.getByRole("button", { name: "Masuk", exact: true }).click();
  await expect(page.locator(".error-notice[role=alert]")).toContainText(
    "Email atau password tidak sesuai.",
  );
  let sessionUnavailable = true;
  await page.route("**/api/v1/auth/me", async (route) => {
    if (sessionUnavailable) {
      sessionUnavailable = false;
      await route.fulfill({
        status: 503,
        contentType: "application/json",
        body: JSON.stringify({
          error: { code: "unavailable", message: "Pemeriksaan sesi sementara tidak tersedia." },
        }),
      });
    } else await route.continue();
  });
  await page.getByLabel("Password", { exact: true }).fill(password);
  await page.getByRole("button", { name: "Masuk", exact: true }).click();
  await expect(page.getByText("Pemeriksaan sesi sementara tidak tersedia.")).toBeVisible();
  await page.getByRole("button", { name: "Coba lagi" }).click();
  await expect(page.getByRole("heading", { name: "Dataset", exact: true })).toBeVisible();
  await expect(page.getByText("Pemeriksaan sesi sementara tidak tersedia.")).not.toBeVisible();
  await page.unroute("**/api/v1/auth/me");
  if (info.project.name === "desktop") {
    await page.getByRole("button", { name: "Ciutkan sidebar" }).click();
    await expect(page.locator('[data-slot="sidebar"][data-state="collapsed"]')).toBeVisible();
    await page.getByRole("button", { name: "Buka sidebar" }).click();
    await expect(page.locator('[data-slot="sidebar"][data-state="expanded"]')).toBeVisible();
  } else {
    await page.getByRole("button", { name: "Buka navigasi" }).click();
    await expect(page.getByRole("dialog", { name: "Navigasi LinkGuard" })).toBeVisible();
    await page.keyboard.press("Escape");
    await expect(page.getByRole("dialog", { name: "Navigasi LinkGuard" })).not.toBeVisible();
    await expect(page.getByRole("button", { name: "Buka navigasi" })).toBeFocused();
  }
  await page.getByRole("button", { name: "Unggah dataset", exact: true }).first().click();
  const dialog = page.getByRole("dialog");
  await expect(dialog).toBeVisible();
  await page.keyboard.press("Escape");
  await expect(dialog).not.toBeVisible();
  await expect(
    page.getByRole("button", { name: "Unggah dataset", exact: true }).first(),
  ).toBeFocused();
  await page.getByRole("button", { name: "Unggah dataset", exact: true }).first().click();
  const csv =
    "\ufeffurl,label,source\r\n" +
    Array.from(
      { length: 63 },
      (_, i) => `https://example.com/${i}?value=original,${i % 2},fixture`,
    ).join("\r\n");
  await page.getByLabel("File CSV", { exact: true }).setInputFiles({
    name: `fixture-${info.project.name}.csv`,
    mimeType: "text/csv",
    buffer: Buffer.from(csv),
  });
  await dialog.getByRole("button", { name: /Mulai impor|Unggah dan ganti dataset/ }).click();
  await expect(
    page.getByRole("heading", { name: `fixture-${info.project.name}.csv` }),
  ).toBeVisible();
  await expect(page.locator("tbody tr")).toHaveCount(25);
  await expect(page.locator("tbody tr").first()).toContainText(
    "https://example.com/0?value=original",
  );
  await expect(page.locator("tbody a")).toHaveCount(0);
  await page.getByRole("button", { name: "Halaman terakhir" }).click();
  await expect(page).toHaveURL(/page=3/);
  await expect(page.locator("tbody tr")).toHaveCount(13);
  await page.getByLabel("Baris per halaman").selectOption("50");
  await expect(page).toHaveURL(/page=1.*page_size=50/);
  await expect(page.locator("tbody tr")).toHaveCount(50);
  await page.reload();
  await expect(page.locator("tbody tr")).toHaveCount(50);
  await expect(page.getByLabel("Baris per halaman")).toHaveValue("50");
  expect(
    await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth),
  ).toBeTruthy();
  const scroll = page.getByRole("region", { name: /Tabel dataset/ });
  await scroll.focus();
  await expect(scroll).toBeFocused();
  await page.evaluate(() => (document.activeElement as HTMLElement | null)?.blur());
  await mkdir("test-results/screenshots", { recursive: true });
  await page.evaluate(() => window.scrollTo(0, 0));
  await page.screenshot({ path: `test-results/screenshots/${info.project.name}.png` });
  // A replacement from another session resets the current page through metadata polling.
  await page.getByRole("button", { name: "Halaman berikutnya" }).click();
  await expect(page).toHaveURL(/page=2/);
  const csrf = await page.request.get("/api/v1/auth/csrf");
  const { csrf_token } = await csrf.json();
  const replacementName = `replacement-${info.project.name}.csv`;
  const imported = await page.request.post("/api/v1/dataset/imports", {
    headers: { "X-CSRF-Token": csrf_token },
    multipart: { file: { name: replacementName, mimeType: "text/csv", buffer: Buffer.from(csv) } },
  });
  expect(imported.status()).toBe(202);
  await expect(page.getByRole("heading", { name: replacementName })).toBeVisible();
  await expect(page).toHaveURL(/page=1/);
  await expect(page.locator("tbody tr")).toHaveCount(50);
  // An invalid replacement must leave the previous dataset available.
  await page.getByRole("button", { name: "Unggah dataset", exact: true }).first().click();
  await page.getByLabel("File CSV", { exact: true }).setInputFiles({
    name: "broken.csv",
    mimeType: "text/csv",
    buffer: Buffer.from("a,b\nmissing\n"),
  });
  await dialog.getByRole("button", { name: "Unggah dan ganti dataset" }).click();
  await expect(page.locator(".error-notice[role=alert]")).toContainText("jumlah kolom");
  await expect(page.locator(".import-status")).toHaveCount(0);
  await expect(page.getByText("File diterima. Impor sedang diproses.")).toHaveCount(0);
  await expect(page.getByRole("heading", { name: replacementName })).toBeVisible();
  await navigate(page, "Profil");
  await page.getByLabel("Nama", { exact: true }).fill(`Admin ${info.project.name}`);
  await page.getByRole("button", { name: "Simpan profil" }).click();
  await expect(page.getByText("Profil disimpan.", { exact: true })).toBeVisible();
  await expect(page.getByLabel("Email", { exact: true })).toHaveValue(email);
  await expect(page.getByLabel("Email", { exact: true })).toHaveAttribute("readonly", "");
  // Tiny valid PNG, re-encoded by the actual API.
  await page.getByLabel("Pilih foto").setInputFiles({
    name: "avatar.png",
    mimeType: "image/png",
    buffer: Buffer.from(
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aP9sAAAAASUVORK5CYII=",
      "base64",
    ),
  });
  await expect(page.getByText("Foto profil disimpan.", { exact: true })).toBeVisible();
  await page.getByLabel("Password lama", { exact: true }).fill(password);
  await page.getByLabel("Password baru", { exact: true }).fill("temporary-e2e-password");
  await page.getByLabel("Konfirmasi password baru").fill("temporary-e2e-password");
  await page.getByRole("button", { name: "Ubah password" }).click();
  await expect(
    page.getByText("Password diubah. Sesi perangkat lain telah diakhiri.", { exact: true }),
  ).toBeVisible();
  await page.getByLabel("Password lama", { exact: true }).fill("temporary-e2e-password");
  await page.getByLabel("Password baru", { exact: true }).fill(password);
  await page.getByLabel("Konfirmasi password baru").fill(password);
  await page.getByRole("button", { name: "Ubah password" }).click();
  await expect(page.getByLabel("Password lama", { exact: true })).toHaveValue("");
  await page.evaluate(async () => {
    (document.activeElement as HTMLElement | null)?.blur();
    window.scrollTo(0, 0);
    await document.fonts.ready;
    await new Promise<void>((resolve) =>
      requestAnimationFrame(() => requestAnimationFrame(() => resolve())),
    );
  });
  await page.screenshot({
    path: `test-results/screenshots/profile-${info.project.name}.png`,
    fullPage: true,
  });
  await logout(page);
  await page.goto("/datasets");
  await expect(page).toHaveURL(/\/login$/);
  expect(errors).toEqual([]);
});
test("error dapat dicoba lagi dan loading dapat dibaca", async ({ page }) => {
  await page.route("**/api/v1/auth/csrf", (route) =>
    route.fulfill({
      status: 503,
      contentType: "application/json",
      body: JSON.stringify({
        error: { code: "unavailable", message: "Formulir masuk belum tersedia." },
      }),
    }),
  );
  await page.goto("/login");
  await expect(page.getByText("Formulir masuk belum tersedia.")).toBeVisible();
  await page.unroute("**/api/v1/auth/csrf");
  await page.getByRole("button", { name: "Coba lagi" }).click();
  await expect(page.getByText("Formulir masuk belum tersedia.")).not.toBeVisible();
  await expect(page.getByRole("button", { name: "Masuk", exact: true })).toBeEnabled();
  await login(page);
  await page.route("**/api/v1/dataset", (route) =>
    route.fulfill({
      status: 503,
      contentType: "application/json",
      body: JSON.stringify({
        error: { code: "unavailable", message: "Layanan sementara tidak tersedia." },
      }),
    }),
  );
  await page.reload();
  await expect(page.locator(".error-notice[role=alert]")).toContainText(
    "Layanan sementara tidak tersedia.",
  );
  await page.unroute("**/api/v1/dataset");
  await page.getByRole("button", { name: "Coba lagi" }).click();
  await expect(page.getByText("Layanan sementara tidak tersedia.")).not.toBeVisible();
  await page.route("**/api/v1/dataset/rows?**", async (route) => {
    await new Promise((resolve) => setTimeout(resolve, 1000));
    await route.continue();
  });
  await page.reload();
  await expect(page.getByText("Memuat halaman dataset…")).toBeVisible();
  await expect(page.locator("tbody tr").first()).toBeVisible();
  await logout(page);
});

test("kelola admin dashboard dan pengguna mobile", async ({ page }, info) => {
  const errors: string[] = [];
  page.on("pageerror", (error) => errors.push(error.message));
  await login(page);
  await navigate(page, "Pengguna");
  await expect(page.getByRole("heading", { name: "Pengguna", exact: true })).toBeVisible();
  // Your own account keeps the profile password flow and cannot deactivate itself.
  await page.getByRole("button", { name: `Aksi untuk ${email}`, exact: true }).click();
  await expect(page.getByRole("menuitem", { name: "Atur password", exact: true })).toBeDisabled();
  await expect(page.getByRole("menuitem", { name: "Nonaktifkan", exact: true })).toBeDisabled();
  await page.keyboard.press("Escape");
  for (const kind of ["admin", "mobile"]) {
    if (kind === "mobile") await page.getByRole("tab", { name: "Pengguna mobile" }).click();
    const accountEmail = `${kind}-${info.project.name}-${Date.now()}@example.com`;
    await page.getByRole("button", { name: "Tambah akun", exact: true }).first().click();
    const dialog = page.getByRole("dialog");
    await expect(dialog.getByLabel("Izinkan login Google")).toHaveCount(0);
    await dialog.getByLabel("Nama", { exact: true }).fill(`Akun ${kind}`);
    await dialog.getByLabel("Email", { exact: true }).fill(accountEmail);
    await dialog.getByLabel("Password awal", { exact: true }).fill("initial-managed-password");
    await dialog
      .getByLabel("Konfirmasi password", { exact: true })
      .fill("initial-managed-password");
    await dialog.getByRole("button", { name: "Tambah akun", exact: true }).click();
    await expect(dialog).not.toBeVisible();
    // The last page contains freshly appended accounts even after repeated test runs.
    const sizeSelect = page.getByLabel("Akun per halaman");
    await sizeSelect.selectOption("100");
    const row = page.getByRole("row").filter({ hasText: accountEmail });
    while (
      !(await row.count()) &&
      (await page.getByRole("button", { name: "Halaman pengguna berikutnya" }).isEnabled())
    ) {
      await page.getByRole("button", { name: "Halaman pengguna berikutnya" }).click();
      await expect(page.getByText("Memuat daftar pengguna…")).not.toBeVisible();
    }
    await expect(row).toContainText("Aktif");
    async function action(name: string) {
      await row.getByRole("button", { name: `Aksi untuk ${accountEmail}`, exact: true }).click();
      await page.getByRole("menuitem", { name, exact: true }).click();
    }
    await action("Edit akun");
    await expect(dialog.getByLabel("Email", { exact: true })).toHaveAttribute("readonly", "");
    await dialog.getByLabel("Nama", { exact: true }).fill(`Diperbarui ${kind}`);
    await dialog.getByRole("button", { name: "Simpan perubahan" }).click();
    await expect(row).toContainText(`Diperbarui ${kind}`);
    await action("Atur password");
    await dialog.getByLabel("Password baru", { exact: true }).fill("updated-managed-password");
    await dialog
      .getByLabel("Konfirmasi password", { exact: true })
      .fill("updated-managed-password");
    await dialog.getByRole("button", { name: "Simpan perubahan" }).click();
    await expect(dialog).not.toBeVisible();
    await action("Nonaktifkan");
    await dialog.getByRole("button", { name: "Nonaktifkan akun", exact: true }).click();
    await expect(row).toContainText("Nonaktif");
    await action("Aktifkan");
    await dialog.getByRole("button", { name: "Aktifkan akun", exact: true }).click();
    await expect(row).toContainText("Aktif");
    expect(
      await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth),
    ).toBeTruthy();
    await mkdir("test-results/screenshots", { recursive: true });
    await expect(page.locator('[data-slot="dialog-content"]')).toHaveCount(0);
    await page.evaluate(async () => {
      (document.activeElement as HTMLElement | null)?.blur();
      const region = document.querySelector(".users-table-scroll");
      if (region) region.scrollLeft = 0;
      window.scrollTo(0, 0);
      await document.fonts.ready;
    });
    await page.screenshot({
      animations: "disabled",
      path: `test-results/screenshots/users-${kind}-${info.project.name}.png`,
      fullPage: true,
    });
    // Keep local fixture records, disabled, for reproducible review.
    await action("Nonaktifkan");
    await dialog.getByRole("button", { name: "Nonaktifkan akun", exact: true }).click();
    await expect(row).toContainText("Nonaktif");
  }
  await logout(page);
  expect(errors).toEqual([]);
});
