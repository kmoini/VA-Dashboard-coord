---
name: dashboard-nav-perf
description: Dashboard slow page-switching had two causes (no Inertia prefetch + no persistent layout so the whole shell remounted each nav). BOTH fixed and pushed to main in commit f27e462 (2026-07-01); prod owes `npm run build` to go live.
metadata:
  node_type: memory
  type: project
  originSessionId: 514e31f4-648d-4687-a162-a6478c27ee33
---

2026-07-01: Amin reported the dashboard "top bar loading takes too long" on every page switch. Two independent root causes (neither is the page's own data). BOTH fixed and pushed to `main` in commit **f27e462** ("perf(dashboard): instant page navigation"). Not yet deployed: prod owes `npm run build` (deploy = git pull + manual build, see [[deploy-process]]).

1. **No link prefetching.** Inertia v2 is installed (client `@inertiajs/react ^2.0` + server `inertiajs/inertia-laravel ^2.0`) but sidebar `<Link>`s did cold server round-trips; the top progress bar (250ms delay) is the symptom. FIX (DONE): added `prefetch cacheFor="30s"` to the nav / Billing / Settings / logo links in `resources/js/Layouts/Components/Sidebar.jsx`. Hover preloads + caches so the click is instant and the bar barely shows.

2. **Shell remounts on every navigation.** All 50 `resources/js/Pages/**` inline-wrapped `<AuthenticatedLayout>` inside the page component instead of Inertia's persistent-layout pattern, so the whole top bar + Sidebar + NotificationsBell + AiAssistantChat unmounted/remounted each nav (NotificationsBell re-fired `GET /notifications/recent` every switch). FIX (DONE): converted all 50 pages to `Page.layout = (page) => <AuthenticatedLayout>{page}</AuthenticatedLayout>` (47 via a codemod on the identical clean pattern; Dashboard, Profile/Edit, Storage/Index done by hand because they pass a static `header` prop, now moved into the `.layout` fn). Shell stays mounted; only content swaps.

Still open (not done): the shared-prop closures in `HandleInertiaRequests::share` (clients-switcher withCount, currentClient, integrations, billing) still run on every navigation and could be cached/deferred if more speed is needed. See [[dashboard-build-status]].
