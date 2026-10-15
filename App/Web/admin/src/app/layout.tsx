import type { Metadata } from "next";
import { GeistSans } from "geist/font/sans";
import "./globals.css";
export const metadata: Metadata = {
  title: { default: "LinkGuard Admin", template: "%s · LinkGuard" },
  description: "Dashboard admin LinkGuard",
};
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="id" className={GeistSans.variable}>
      <body>{children}</body>
    </html>
  );
}
