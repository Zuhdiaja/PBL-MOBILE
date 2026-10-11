import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "LinkGuard Admin",
  description: "Dashboard admin LinkGuard",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="id">
      <body>{children}</body>
    </html>
  );
}
