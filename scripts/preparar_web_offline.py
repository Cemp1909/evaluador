#!/usr/bin/env python3
"""Genera una caché versionada de los archivos públicos de Flutter; nunca de API."""
import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1] / 'build' / 'web'
# La publicación solo incluye configuración pública, incluso en builds manuales.
for env_file in (root / 'assets' / '.env', root / 'assets' / '.env.public-demo'):
    if env_file.exists():
        env_file.write_text('\n'.join(line for line in env_file.read_text().splitlines()
                                      if line.split('=', 1)[0].strip() in
                                      {'SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY'}) + '\n')
files = sorted(p for p in root.rglob('*') if p.is_file()
               and p.name not in {'offline_service_worker.js', 'flutter_service_worker.js'}
               and p.suffix != '.map')
version = hashlib.sha256()
for path in files:
    version.update(str(path.relative_to(root)).encode())
    version.update(path.read_bytes())
manifest = [str(p.relative_to(root)) for p in files]
worker = """'use strict';
const CACHE = 'academico-shell-__VERSION__';
const FILES = __FILES__;
const urls = FILES.map(path => new URL(path, self.registration.scope).href);
self.addEventListener('install', event => {
  event.waitUntil(caches.open(CACHE).then(cache => cache.addAll(urls)).then(() => self.skipWaiting()));
});
self.addEventListener('activate', event => {
  event.waitUntil((async () => {
    for (const key of await caches.keys()) {
      if ((key.startsWith('academico-shell-') && key !== CACHE) ||
          ['flutter-app-cache', 'flutter-temp-cache', 'flutter-app-manifest'].includes(key)) {
        await caches.delete(key);
      }
    }
    await self.clients.claim();
  })());
});
self.addEventListener('fetch', event => {
  if (event.request.method !== 'GET') return;
  const url = new URL(event.request.url);
  if (url.origin !== self.location.origin) return;
  const shell = new URL('index.html', self.registration.scope).href;
  const key = event.request.mode === 'navigate' && url.href.startsWith(self.registration.scope)
    ? shell : url.href;
  if (!urls.includes(key)) return;
  event.respondWith(caches.open(CACHE).then(async cache => (await cache.match(key)) || fetch(event.request)));
});
""".replace('__VERSION__', version.hexdigest()[:20]).replace('__FILES__', json.dumps(manifest))
(root / 'offline_service_worker.js').write_text(worker)
print(f'Apertura offline preparada: {len(files)} archivos públicos, {sum(p.stat().st_size for p in files)//1024//1024} MB.')
