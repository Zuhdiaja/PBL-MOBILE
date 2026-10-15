import { AlertCircle, RotateCw } from "lucide-react";
import { Button } from "@/components/ui/button";
export function ErrorNotice({ message, retry }: { message: string; retry?: () => void }) {
  return (
    <div className="error-notice" role="alert">
      <AlertCircle size={18} aria-hidden="true" />
      <p>{message}</p>
      {retry && (
        <Button variant="outline" onClick={retry}>
          <RotateCw />
          Coba lagi
        </Button>
      )}
    </div>
  );
}
export function Loading({ text = "Memuat data…" }: { text?: string }) {
  return (
    <div className="loading-state" aria-live="polite">
      <p>{text}</p>
      <div className="skeleton" />
      <div className="skeleton" />
      <div className="skeleton short" />
    </div>
  );
}
