# CoC Marketplace — Architecture

## Product decisions
- Default display currency: INR; creators can list in INR or USD. The UI can display a selected currency, but does not convert or silently alter the seller's stored amount.
- Seller pricing: fixed or negotiable. Each permitted listing stores its own amount, ISO currency, and pricing mode.
- Player profiles are public informational showcases, not account sale or transfer listings.
- Clan pages support recruitment only.
- Coaching is guidance-only; no credential sharing, boosting, bots, or automated gameplay.
- Base-layout listings must be original creator work or accompanied by rights to distribute.
- Gem information points only to official Supercell purchase options.
- Marketplace contact/support Telegram: @ronin837.

## System architecture
- Next.js App Router + TypeScript + Tailwind CSS.
- Supabase Auth with cookie-based SSR sessions using `@supabase/ssr`.
- PostgreSQL with RLS on every exposed table.
- Supabase Storage for listing images and profile evidence; upload policies scoped by owner.
- Server-side validation with Zod; server components/actions perform privileged operations only after verifying the user.
- Vercel connected to GitHub repository `Bivanjit/coc-market`; pushes to main trigger deployments.

## Main domains
1. Identity: profiles, roles, account settings.
2. Player discovery: player_profiles and progression sub-records.
3. Clans: clans and clan_recruitment.
4. Coaching: coaches, coaching_services, coaching_bookings.
5. Creator marketplace: base_layouts and reviews.
6. Trust & safety: favourites, reports, notifications, moderation_logs.
7. Catalogue: versioned game_catalogue for evolving game data.

## Price model
Every purchasable permitted listing uses:
- `price_amount numeric(12,2)`
- `currency char(3)` constrained to INR or USD initially
- `price_type` fixed or negotiable
- A null amount is allowed only for explicitly free listings.
Amounts are stored in the seller's selected currency. No exchange conversion is performed at write time.

## Security model
- Public visitors can read only published, non-removed content.
- Authenticated owners can create and update only their own records.
- Admin role membership is stored in a non-exposed schema; users cannot grant themselves admin.
- Service-role secrets never enter browser bundles.
- Reviews and reports are tied to authenticated users; moderation actions are audited.
- Account selling, account credential exchange, unauthorized currency transfer and gameplay automation are out of scope.

## Delivery phases
1. Foundation and responsive landing page (committed).
2. Supabase project, SQL migration, auth and storage policies.
3. Player profiles and search/filtering.
4. Clan recruitment.
5. Coaching services and booking requests.
6. Base layout listings and seller-controlled pricing.
7. User dashboard, favourites, reviews and notifications.
8. Admin moderation and audit trail.
9. Security review, tests, and production deployment.
