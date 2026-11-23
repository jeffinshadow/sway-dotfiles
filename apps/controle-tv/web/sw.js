// Guarda a "casca" do app pra abrir instantâneo; /api sempre vai pra rede.
const CACHE = "controle-tv-v8";
const SHELL = ["/", "/manifest.webmanifest", "/icon-192.png", "/icon-512.png"];
self.addEventListener("install", (e) => { e.waitUntil(caches.open(CACHE).then((c) => c.addAll(SHELL))); self.skipWaiting(); });
self.addEventListener("activate", (e) => { e.waitUntil(caches.keys().then((ks) =>
  Promise.all(ks.filter((k) => k !== CACHE).map((k) => caches.delete(k))))); self.clients.claim(); });
self.addEventListener("fetch", (e) => {
  const u = new URL(e.request.url);
  if (u.pathname.startsWith("/api") || e.request.method !== "GET") return;
  e.respondWith(fetch(e.request).then((r) => { const c = r.clone(); caches.open(CACHE).then((x) => x.put(e.request, c)); return r; })
    .catch(() => caches.match(e.request).then((r) => r || caches.match("/"))));
});
