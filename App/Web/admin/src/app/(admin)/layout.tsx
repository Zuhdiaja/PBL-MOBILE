import { Suspense } from "react";
import { AdminShell } from "@/components/admin-shell";
import { Loading } from "@/components/feedback";
export default function Layout({ children }: { children: React.ReactNode }) {
  return (
    <Suspense fallback={<Loading />}>
      <AdminShell>{children}</AdminShell>
    </Suspense>
  );
}
