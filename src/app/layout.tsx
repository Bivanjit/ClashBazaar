import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Clash Market — Your Clash Community",
  description: "Discover players, recruit for clans, find coaching and explore original base layouts.",
  metadataBase: new URL("https://coc-market.vercel.app")
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}