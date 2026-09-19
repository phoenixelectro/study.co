// study.co service worker — caches the app shell only.
// Supabase requests (auth/database) always go to the network;
// this just lets the app itself load instantly and survive
// brief connectivity blips, it does not enable full offline use.
//
// IMPORTANT: bump CACHE_NAME any time you deploy a meaningful update.
// Changing this value is what forces already-installed users to pick
// up the new version instead of being stuck on a stale cached copy.
const CACHE_NAME = 'studyco-shell-v2';

const SHELL_FILES = [
  '/',
  '/index.html',
  '/manifest.json',
  '/icons/icon-192.png',
  '/icons/icon-512.png'
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => cache.addAll(SHELL_FILES)).catch(() => {})
  );
  self.skipWaiting();
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(names =>
      Promise.all(names.filter(n => n !== CACHE_NAME).map(n => caches.delete(n)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);

  // Never cache/interfere with Supabase (or any other) API calls —
  // those must always hit the real network for fresh, correct data.
  if (url.origin !== self.location.origin) return;

  const isHtmlRequest = event.request.mode === 'navigate' ||
    url.pathname === '/' || url.pathname.endsWith('/index.html');

  if (isHtmlRequest) {
    // NETWORK-FIRST for the app's own HTML: always try to get the
    // latest version first, so a deploy shows up immediately. Only
    // fall back to the cached copy if the network request fails
    // (e.g. genuinely offline).
    event.respondWith(
      fetch(event.request).then(response => {
        if (response && response.status === 200) {
          const clone = response.clone();
          caches.open(CACHE_NAME).then(cache => cache.put(event.request, clone));
        }
        return response;
      }).catch(() => caches.match(event.request))
    );
    return;
  }

  // CACHE-FIRST for everything else (icons, manifest) — these rarely
  // change, so serving from cache instantly is fine.
  event.respondWith(
    caches.match(event.request).then(cached => {
      if (cached) return cached;
      return fetch(event.request).then(response => {
        if (response && response.status === 200) {
          const clone = response.clone();
          caches.open(CACHE_NAME).then(cache => cache.put(event.request, clone));
        }
        return response;
      }).catch(() => cached);
    })
  );
});
