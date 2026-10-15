import type { NextConfig } from "next";
const nextConfig: NextConfig = {
  output: "standalone",
  experimental: { proxyClientMaxBodySize: `${Number(process.env.MAX_UPLOAD_MB || 512) + 1}mb` },
  async rewrites() {
    return [
      {
        source: "/api/v1/:path*",
        destination: `${process.env.API_URL || "http://127.0.0.1:5001"}/api/v1/:path*`,
      },
    ];
  },
};
export default nextConfig;
