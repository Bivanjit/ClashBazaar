# CoC Marketplace

A premium, community-first Clash of Clans discovery and creator marketplace.

## Stack
- Next.js 15 + React 19 + TypeScript
- Tailwind CSS 4
- Supabase (Postgres, Auth, Storage, RLS)
- Vercel deployment

## Product boundaries
- Player profiles are informational showcases, never account-transfer listings.
- Clan listings are for recruitment, not clan sales.
- Coaching is guidance-only; no account credential sharing, boosting or automated play.
- Gem information links to official Supercell purchase routes only.
- Creators may set their own prices for permitted services and original base-layout products. Prices support INR and USD, with fixed or negotiable terms.

## Local development
1. Install Node.js 20+.
2. Run `npm install`.
3. Copy `.env.example` to `.env.local` and fill in Supabase project values.
4. Run `npm run dev`.

## Environment
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`

Never put a Supabase service-role or secret key in a `NEXT_PUBLIC_*` variable.

## Status
The first commit establishes the design system and responsive landing page. Marketplace data, authentication, owner dashboards, moderation and database migrations are staged for subsequent implementation. Cards currently marked Demo are illustrative only.
