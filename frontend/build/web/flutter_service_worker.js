'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"favicon-16x16.png": "fd4413050865d1a6bef1c4be12d4b5f5",
"flutter_bootstrap.js": "451a00b30e9c1b254f95bb589f6f8887",
"version.json": "9f523b3bcea39538fc2a20c0e7068841",
"splash/img/light-2x.png": "0b23f5098aedffc470fb092e6c1b0703",
"splash/img/dark-4x.png": "dbbcbd46f8e5e0a6e408ad71187844b5",
"splash/img/light-3x.png": "72a310504af6bfe67ca972cded1307c9",
"splash/img/dark-3x.png": "72a310504af6bfe67ca972cded1307c9",
"splash/img/light-4x.png": "dbbcbd46f8e5e0a6e408ad71187844b5",
"splash/img/dark-2x.png": "0b23f5098aedffc470fb092e6c1b0703",
"splash/img/dark-1x.png": "09c120998bb412aa24dad825741a62a5",
"splash/img/light-1x.png": "09c120998bb412aa24dad825741a62a5",
"favicon.ico": "76616ceb3246ae6c41a9505c007705c3",
"index.html": "90f0777fb298f4de93891eded2ba2db1",
"/": "90f0777fb298f4de93891eded2ba2db1",
"apple-icon.png": "40c30aca701145b9b1f0ac754008dfa1",
"apple-icon-144x144.png": "dc3ff22dd13b02a65127707d46f1b408",
"android-icon-192x192.png": "6e485df3eb5de35835f1217f2b9f3837",
"apple-icon-precomposed.png": "40c30aca701145b9b1f0ac754008dfa1",
"apple-icon-114x114.png": "41869f30acb50c7e78ac07f1e5cd6833",
"main.dart.js": "65e1b89f46c8dcd1e2f13aa209a7dfc3",
"ms-icon-310x310.png": "2707c8aaecab6062ac692c544cb62194",
"ms-icon-144x144.png": "dc3ff22dd13b02a65127707d46f1b408",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"apple-icon-57x57.png": "4307888f60f6ae28057911d489e6507e",
"apple-icon-152x152.png": "ee75b3f20fd2e0c920d9dbf64e3a4aaa",
"favicon.png": "6e9fd46542b051824c7c3bbf5ec90d1a",
"ms-icon-150x150.png": "9c4c4b4b101dea151f9d22254a736ae3",
"android-icon-72x72.png": "0c721c27724728c2257e71792586d1f3",
"android-icon-96x96.png": "43e43170f2f2f7a88f0ee947c37fe165",
"android-icon-36x36.png": "b72939c71a430f4fa6a3c9348dc90153",
"apple-icon-180x180.png": "39d8d17b654bbb92a285ca664d7fbcb4",
"favicon-96x96.png": "43e43170f2f2f7a88f0ee947c37fe165",
"icons/Icon-192.png": "1e09e1a7bce65e518203fd3ecb8465c7",
"icons/Icon-maskable-192.png": "1e09e1a7bce65e518203fd3ecb8465c7",
"icons/Icon-maskable-512.png": "955d26a9561a8340f6634a0c3b816886",
"icons/Icon-512.png": "955d26a9561a8340f6634a0c3b816886",
"manifest.json": "92f21689569d46d58fafc7ded048a59f",
"android-icon-48x48.png": "5384054bdb36eceb7b7d72123a95afea",
"apple-icon-76x76.png": "953102a4e036dc18164c8c8246bb3dde",
"apple-icon-60x60.png": "9306d0949af73e1add0bcf9503f226cb",
"assets/AssetManifest.json": "07fd7dc02ae5ea49850e8bb39846006c",
"assets/NOTICES": "5ffc08e99be9c4272f225f0b9540ba6f",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin.json": "dd823dc091d2174fc2b2a2c5a0593bec",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "8e891253082a369ac9754240aae4eca4",
"assets/fonts/MaterialIcons-Regular.otf": "8a5dc427edf916406a7b6958600cb839",
"assets/assets/GitHub_Lockup_Black_Clearspace.svg": "39727a5c5b07f0219e92add8eec094c8",
"assets/assets/promptpay.jpeg": "7d3666890c2faf02f4e17e1776136baa",
"assets/assets/header.png": "aa01b8494ad2c0fa36138629f445f3fb",
"assets/assets/jess.png": "7eb368bb362b6e386368e701d786ba18",
"assets/assets/janet.jpg": "506ed6c672902988cd7e46f047934370",
"browserconfig.xml": "653d077300a12f09a69caeea7a8947f8",
"android-icon-144x144.png": "dc3ff22dd13b02a65127707d46f1b408",
"apple-icon-72x72.png": "0c721c27724728c2257e71792586d1f3",
"apple-icon-120x120.png": "d6f94aaff9072563467de8326401417d",
"favicon-32x32.png": "8e1af93c8774bfff82967c135c9c9d6b",
"ms-icon-70x70.png": "3bb6b7375b4d1b690b97f3ef3f0c4b56",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
