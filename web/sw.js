// Service worker do Dev Routine: deixa o app abrir sem internet.
//
// Estratégia "rede primeiro": com internet, sempre pega a versão nova
// (e guarda uma cópia); sem internet, usa a cópia guardada. Só arquivos
// do próprio app: a nuvem (Supabase) e o clima nunca passam pelo cache.
const CACHE = 'dev-routine-v1';

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE).then((c) => c.addAll(['./', 'index.html', 'manifest.json', 'icons/Icon-192.png'])).catch(() => {})
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      for (const key of await caches.keys()) {
        if (key !== CACHE) await caches.delete(key);
      }
      await self.clients.claim();
    })()
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;

  event.respondWith(
    (async () => {
      const cache = await caches.open(CACHE);
      try {
        const res = await fetch(req);
        if (res.ok) cache.put(req, res.clone());
        return res;
      } catch (e) {
        const hit = await cache.match(req, { ignoreSearch: true });
        if (hit) return hit;
        if (req.mode === 'navigate') {
          const shell = await cache.match('index.html');
          if (shell) return shell;
        }
        throw e;
      }
    })()
  );
});
