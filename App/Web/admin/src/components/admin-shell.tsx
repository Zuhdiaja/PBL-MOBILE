/* oxlint-disable react/set-state-in-effect -- Effect fetches server session state asynchronously. */
"use client";
import { createContext, useContext, useEffect, useState, type ReactNode } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import {
  Database,
  UserRound,
  LogOut,
  ShieldCheck,
  ChevronsUpDown,
  ChevronRight,
} from "lucide-react";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { TooltipProvider } from "@/components/ui/tooltip";
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarHeader,
  SidebarInset,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarProvider,
  SidebarRail,
  SidebarTrigger,
  useSidebar,
} from "@/components/ui/sidebar";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuGroup,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { api, messageOf, setCsrf, type User } from "@/lib/api";
import { ErrorNotice, Loading } from "./feedback";
const AuthContext = createContext<{
  user: User;
  setUser: (user: User) => void;
  maxUpload: number;
} | null>(null);
export function useAuth() {
  const value = useContext(AuthContext);
  if (!value) throw new Error("Auth context unavailable");
  return value;
}
export function Brand() {
  return (
    <div className="brand">
      <span className="brand-mark">
        <ShieldCheck aria-hidden="true" size={21} strokeWidth={2} />
      </span>
      <span className="brand-wordmark">
        LinkGuard<span className="brand-admin">Administrasi</span>
      </span>
    </div>
  );
}
function UserAvatar({ user }: { user: User }) {
  return (
    <Avatar className="size-8 rounded-lg">
      <AvatarImage src={user.avatar_url || undefined} alt="" />
      <AvatarFallback className="rounded-lg bg-primary/10 text-primary text-xs font-medium">
        {user.name
          .split(" ")
          .slice(0, 2)
          .map((part) => part.slice(0, 1))
          .join("")
          .toUpperCase()}
      </AvatarFallback>
    </Avatar>
  );
}
function Navigation({
  user,
  leaving,
  logout,
}: {
  user: User;
  leaving: boolean;
  logout: () => Promise<void>;
}) {
  const path = usePathname();
  const router = useRouter();
  const { isMobile, setOpenMobile } = useSidebar();
  return (
    <Sidebar variant="inset" collapsible="icon">
      <SidebarHeader className="p-3">
        <Link
          className="sidebar-brand"
          href="/datasets"
          onClick={() => setOpenMobile(false)}
          aria-label="LinkGuard, buka dataset"
        >
          <Brand />
        </Link>
      </SidebarHeader>
      <SidebarContent>
        <SidebarGroup>
          <SidebarGroupLabel>Ruang kerja</SidebarGroupLabel>
          <SidebarGroupContent>
            <SidebarMenu>
              {[
                { href: "/datasets", name: "Dataset", Icon: Database },
                { href: "/profile", name: "Profil", Icon: UserRound },
              ].map(({ href, name, Icon }) => (
                <SidebarMenuItem key={href}>
                  <SidebarMenuButton
                    className="navigation-item"
                    render={
                      <Link
                        href={href}
                        aria-current={path === href ? "page" : undefined}
                        onClick={() => setOpenMobile(false)}
                      />
                    }
                    isActive={path === href}
                    tooltip={name}
                  >
                    <Icon aria-hidden="true" />
                    <span>{name}</span>
                  </SidebarMenuButton>
                </SidebarMenuItem>
              ))}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>
      <SidebarFooter className="p-3">
        <SidebarMenu>
          <SidebarMenuItem>
            <DropdownMenu>
              <DropdownMenuTrigger
                render={
                  <SidebarMenuButton className="account-trigger" size="lg" aria-label="Menu akun" />
                }
              >
                <UserAvatar user={user} />
                <div className="account-label">
                  <span>{user.name}</span>
                  <span>{user.email}</span>
                </div>
                <ChevronsUpDown className="ml-auto size-4 text-muted-foreground" />
              </DropdownMenuTrigger>
              <DropdownMenuContent
                className="min-w-64"
                side={isMobile ? "top" : "right"}
                align="end"
                sideOffset={8}
              >
                <DropdownMenuGroup>
                  <DropdownMenuLabel className="account-menu-label">
                    <UserAvatar user={user} />
                    <div className="account-label">
                      <span>{user.name}</span>
                      <span>{user.email}</span>
                    </div>
                  </DropdownMenuLabel>
                  <DropdownMenuSeparator />
                  <DropdownMenuItem
                    className="min-h-10"
                    onClick={() => {
                      setOpenMobile(false);
                      router.push("/profile");
                    }}
                  >
                    <UserRound />
                    Profil
                  </DropdownMenuItem>
                </DropdownMenuGroup>
                <DropdownMenuSeparator />
                <DropdownMenuItem
                  className="min-h-10"
                  variant="destructive"
                  disabled={leaving}
                  onClick={() => void logout()}
                >
                  <LogOut />
                  {leaving ? "Keluar…" : "Keluar"}
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarFooter>
      <SidebarRail />
    </Sidebar>
  );
}
function SiteHeader() {
  const path = usePathname();
  const { isMobile, state } = useSidebar();
  return (
    <header className="site-header">
      <SidebarTrigger
        aria-label={
          isMobile ? "Buka navigasi" : state === "expanded" ? "Ciutkan sidebar" : "Buka sidebar"
        }
        className="size-9"
      />
      <Separator orientation="vertical" className="mx-2 h-4 data-vertical:self-auto" />
      <nav className="breadcrumbs" aria-label="Lokasi halaman">
        <span className="breadcrumb-parent">Ruang kerja</span>
        <ChevronRight aria-hidden="true" size={14} className="breadcrumb-parent" />
        <span aria-current="page">
          {path === "/profile" ? "Profil" : "Dataset"}
        </span>
      </nav>
      <Badge variant="outline" className="ml-auto font-normal text-muted-foreground">
        Administrator
      </Badge>
    </header>
  );
}
export function AdminShell({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [maxUpload, setMaxUpload] = useState(512 * 1024 * 1024);
  const [error, setError] = useState("");
  const [leaving, setLeaving] = useState(false);
  const router = useRouter();
  async function load() {
    try {
      const data = await api<{ user: User; csrf_token: string; max_upload_bytes: number }>(
        "/auth/me",
      );
      setCsrf(data.csrf_token);
      setUser(data.user);
      setMaxUpload(data.max_upload_bytes);
      setError("");
    } catch (e) {
      setError(messageOf(e));
    }
  }
  useEffect(() => {
    void load();
  }, []);
  async function logout() {
    setLeaving(true);
    try {
      await api("/auth/logout", { method: "POST" });
      setCsrf("");
      router.replace("/login");
    } catch (e) {
      setError(messageOf(e));
      setLeaving(false);
    }
  }

  if (!user)
    return (
      <main className="boot-screen">
        <Brand />
        {error ? (
          <ErrorNotice message={error} retry={() => void load()} />
        ) : (
          <Loading text="Memeriksa sesi…" />
        )}
      </main>
    );
  return (
    <AuthContext value={{ user, setUser, maxUpload }}>
      <TooltipProvider>
        <a href="#main-content" className="skip-link">
          Lewati ke konten
        </a>
        <SidebarProvider
          style={
            { "--sidebar-width": "256px", "--sidebar-width-icon": "40px" } as React.CSSProperties
          }
        >
          <Navigation user={user} leaving={leaving} logout={logout} />
          <SidebarInset className="min-w-0" id="main-content" tabIndex={-1}>
            <SiteHeader />
            <div className="main-content">
              {error && <ErrorNotice message={error} retry={() => setError("")} />}
              {children}
            </div>
          </SidebarInset>
        </SidebarProvider>
      </TooltipProvider>
    </AuthContext>
  );
}
