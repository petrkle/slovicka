var version = 'v[% cacheversion %]';

self.addEventListener("install", function(event) {
  console.log('WORKER: install event in progress.');
  event.waitUntil(
    caches
      .open(version + 'fundamentals')
      .then(function(cache) {
        return cache.addAll([
          '/[% dir %]/',
[%- FOREACH pismeno IN abeceda %]
          '/[% dir %]/[% pismeno.key %].html',
[%- END %]
          '/[% dir %]/[% cachebuster %]-slovicka.css',
          '/[% dir %]/[% cachebuster %]-slovicka.js',
          '/[% dir %]/[% cachebuster %]-icon.svg'
        ]);
      })
      .then(function() {
        console.log('WORKER: install completed');
      })
  );
});

self.addEventListener("fetch", function(event) {
  console.log('WORKER: fetch event in progress.');

  if (event.request.method !== 'GET') {
    console.log('WORKER: fetch event ignored.', event.request.method, event.request.url);
    return;
  }
  event.respondWith(
    caches
      .match(event.request)
      .then(function(cached) {
        var networked = fetch(event.request)
          .then(fetchedFromNetwork, unableToResolve)
          .catch(unableToResolve);
        console.log('WORKER: fetch event', cached ? '(cached)' : '(network)', event.request.url);
        return cached || networked;

        function fetchedFromNetwork(response) {
          var cacheCopy = response.clone();
          console.log('WORKER: fetch response from network.', event.request.url);
          caches
            .open(version + 'pages')
            .then(function add(cache) {
              cache.put(event.request, cacheCopy);
            })
            .then(function() {
              console.log('WORKER: fetch response stored in cache.', event.request.url);
            });

          return response;
        }
        function unableToResolve () {
          console.log('WORKER: fetch request failed in both cache and network.');
          return new Response('<html><head><meta http-equiv="content-type" content="text/html; charset=utf-8" /><title>Anglická slovíčka</title><meta name="viewport" content="width=device-width"><meta name="theme-color" content="#2196F3"></head><body><style>body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif,"Apple Color Emoji","Segoe UI Emoji","Segoe UI Symbol";font-size:1.2em;line-height:1.7em;color:#000;background:#BBDEFB;margin:0 auto 0 auto;padding:0;}h1{color:#fff;background:#2196F3;background-size:2em 2em;margin:0;padding:0.5em;font-weight:normal;font-size:1em;}</style><h1>Chyba připojení</h1></body></html>', {
            status: 503,
            statusText: 'Service Unavailable',
            headers: new Headers({
              'Content-Type': 'text/html'
            })
          });
        }
      })
  );
});

self.addEventListener("activate", function(event) {
  console.log('WORKER: activate event in progress.');

  event.waitUntil(
    caches
      .keys()
      .then(function (keys) {
        return Promise.all(
          keys
            .filter(function (key) {
              return !key.startsWith(version);
            })
            .map(function (key) {
              return caches.delete(key);
            })
        );
      })
      .then(function() {
        console.log('WORKER: activate completed.');
      })
  );
});
