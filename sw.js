const CACHE_NAME = 'el-assima-pwa-v2';
const urlsToCache = [
  '/',
  '/ELASSIMA_HUB.html',
  '/index.html',
  '/manifest.json'
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => {
        return cache.addAll(urlsToCache);
      })
  );
});

self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(response => {
        // Cache hit - return response
        if (response) {
          return response;
        }
        return fetch(event.request).catch(() => console.log('Fetch failed, user might be offline.'));
      })
  );
});
