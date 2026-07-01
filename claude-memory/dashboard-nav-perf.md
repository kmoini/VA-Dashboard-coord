---
name: dashboard-nav-perf
description: Dashboard slow page-switching has two causes — no Inertia prefetch + no persistent layout (all 50 Pages inline-wrap AuthenticatedLayout so the whole shell remounts each nav). Fix
metadata: 
  node_type: memory
  type: project
  originSessionId: 514e31f4-648d-4687-a162-a6478c27ee33
---

2026-07-01: Amin reported the dashboard "top bar loading takes too long" on every page switch. Two independent root causes (neither is the page's own data):

1. **No link prefetching.** Inertia v2 is installed (client `@inertiajs/react ^2.0` + server `inertiajs/inertia-laravel ^2.0`) but sidebar `<Link>`s did cold server round-trips; the top progress bar (250ms delay) is the symptom. FIX #1 (DONE locally, UNCOMMITTED): added `prefetch cacheFor="30s"` to the nav / Billing / Settings / logo links in `resources/js/Layouts/Components/Sidebar.jsx`. Hover preloads + caches → click is instant, bar barely shows. `npm run build` passed.

2. **Shell remounts on every navigation.** All 50 `resources/js/Pages/**` inline-wrap `<AuthenticatedLayout>` inside the page component instead of Inertia's persistent-layout pattern, so the whole top bar + Sidebar + NotificationsBell + AiAssistantChat unmount/remount each nav (NotificationsBell re-fires `GET /notifications/recent` every switch — see NotificationsBell.jsx mount effect). FIX #2 (PLANNED, not started): convert each page to `Page.layout = (page) => <AuthenticatedLayout>{page}</AuthenticatedLayout>`. 47 pages are the identical clean `export default function NAME(){ return <AuthenticatedLayout>...</AuthenticatedLayout> }` pattern; only Dashboard, Profile/Edit, Storage/Index pass a `header` prop and need individual handling.

Also note the shared-prop closures in `HandleInertiaRequests::share` (clients switcher withCount, currentClient, integrations, billing) run on every navigation. Holding Fix #1 for Amin to test before committing/deploying (see [[wait-for-user-test-before-deploy]], [[dashboard-build-status]]).
