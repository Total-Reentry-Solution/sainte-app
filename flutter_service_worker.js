'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "50f543e8386625611fc5256ca1b278fb",
"version.json": "f259da60387bd5a875231ff9c873b933",
"index.html": "6ce1049d6191d593d03418b30ebdef44",
"/": "6ce1049d6191d593d03418b30ebdef44",
"main.dart.js": "530aeb2c56931280d8c2880de5e95309",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"favicon.png": "dee07b85d3c65065c8bb1b6199c95430",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/sainte-logo.png": "ffbeaaf08564b298aff80fe0103fbffb",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"manifest.json": "b1a54c7f80ffd6e1b7d3ceb945605c28",
"assets/AssetManifest.json": "f5f11d0198d2ba587a3b004b3af0e762",
"assets/NOTICES": "83eac6b4a91c09d401a96dc8a18aa4d3",
"assets/FontManifest.json": "b191d03e534e370b88a15c03ddb8b660",
"assets/AssetManifest.bin.json": "c4be96ae25e2d45976444ed5e719415c",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/iconsax/lib/assets/fonts/iconsax.ttf": "071d77779414a409552e0584dcbfd03d",
"assets/packages/quill_native_bridge_linux/assets/xclip": "d37b0dbbc8341839cde83d351f96279e",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "f5af94d8f1ce5af9733a5c7cdfff69c0",
"assets/fonts/MaterialIcons-Regular.otf": "b309e226ae0d22a34b21c4a499922a35",
"assets/assets/svg/mail_outline.svg": "bf0626f86c564856cdf44b6b1e3a97a4",
"assets/assets/svg/delete_round.svg": "c220885395da047d26296f8c1454d5dd",
"assets/assets/svg/home.svg": "8ae498c0b25fb08ec27191c9861dbbe7",
"assets/assets/svg/thumbs_up.svg": "09afc2ea2987a207d78c98599f1c689c",
"assets/assets/svg/chat_bubble.svg": "d5a34936a078ace73a154c36d3e189fc",
"assets/assets/svg/calender.svg": "d030856e09fa9dfdeb5862570d48aafa",
"assets/assets/svg/pen.svg": "85896d36500b769cfb2c2f56c9651669",
"assets/assets/svg/web/search.svg": "4b18f2a6176d0c9c42edcb7c22b86f18",
"assets/assets/svg/web/citizens.svg": "7c33eaf4f988c3fc59b31497f7395c9f",
"assets/assets/svg/web/logout.svg": "86e507350bac03a8ebbfe1558f95e3ed",
"assets/assets/svg/web/streak.svg": "645d219b239ac01c2cdbade94097ce7b",
"assets/assets/svg/web/peer.svg": "6e7cabf9b8f792acb52b2a9884c0bda3",
"assets/assets/svg/web/settings.svg": "8e66ae8b69aa4a2bc153591c84a7f5c2",
"assets/assets/svg/web/dashboard.svg": "dc36dc4c0be6b991802d68c6886273ff",
"assets/assets/svg/web/email.svg": "426d698304bf188ad9edffd4a59d9108",
"assets/assets/svg/web/parole.svg": "062e2f9af6dca99c9101c7673052876e",
"assets/assets/svg/web/edit_ic.svg": "b0ce4707f36aec3f808733ed8407165b",
"assets/assets/svg/web/notification.svg": "1899562dff5831e9782c2517bcbe6382",
"assets/assets/svg/web/appointments.svg": "603da5f81c1682b3283a2bb95b2638a0",
"assets/assets/svg/web/edit.svg": "cd8e25f76106e93142f6b208f53621f3",
"assets/assets/svg/web/delete.svg": "de23985297b87bb46e58f8ae86d93dcb",
"assets/assets/svg/web/match.svg": "4c4524c4819cb93f9349ab8f337c8adb",
"assets/assets/svg/web/incident.svg": "5a2939e62a2039e754824cbc678c02ea",
"assets/assets/svg/web/calendar.svg": "1a5867cc1fe56186feb05c942b7e7b17",
"assets/assets/svg/web/blog.svg": "edeff49d7f2ef4172a5f78232c0fb75f",
"assets/assets/svg/web/trend.svg": "cad039d946803dc3c6e0cb0d14712029",
"assets/assets/svg/web/upload.svg": "534672a37f705a2e6a6de200ee7474b8",
"assets/assets/svg/web/apple.svg": "27161aef7a11c339c5371083a88c96cb",
"assets/assets/svg/settings.svg": "27368944525c7b721096ab294f28be36",
"assets/assets/svg/goal.svg": "441c198a06127007e66118c2f593580c",
"assets/assets/svg/chevron_left.svg": "f8d8f79394f7be6793bc04a9144ad728",
"assets/assets/svg/addButton.svg": "477fe76984818d217064d463ef3d7910",
"assets/assets/svg/vector0.svg": "7b56e8413fd9e2a76278bbe5de7cb69c",
"assets/assets/svg/vector1.svg": "8ae498c0b25fb08ec27191c9861dbbe7",
"assets/assets/svg/vector3.svg": "1d548135c135d19ae85248c4d4571a11",
"assets/assets/svg/vector2.svg": "d5a34936a078ace73a154c36d3e189fc",
"assets/assets/svg/google.svg": "0ae35b4946ad56292c577f9733d86070",
"assets/assets/svg/eye_hide.svg": "e45e89d0a233033807454a74962efa68",
"assets/assets/svg/settings_checked.svg": "562ff4c00464b811fe64b59236a6bde2",
"assets/assets/svg/resource_checked.svg": "354f2f84744d4e45fa83242205ec9cce",
"assets/assets/svg/appointments.svg": "b1e7e06d16d5e49845ca2a08c7af4ef3",
"assets/assets/svg/vector5.svg": "444e9a1888edb460f6042b25f9da7b3b",
"assets/assets/svg/vector4.svg": "27368944525c7b721096ab294f28be36",
"assets/assets/svg/bin.svg": "5e5ee34f64f2861337deeba63d6a358f",
"assets/assets/svg/stack.svg": "1d548135c135d19ae85248c4d4571a11",
"assets/assets/svg/activity.svg": "441c198a06127007e66118c2f593580c",
"assets/assets/svg/green_check.svg": "4e07d56a34381fc50f29f9fc44870d08",
"assets/assets/svg/timer_late.svg": "cc7089ce36a9b6b683de8ed6d35347a6",
"assets/assets/svg/add_outline.svg": "dcbbdf62f884c8f80aa5800cedbe79b0",
"assets/assets/svg/apple.svg": "8bc4dfb0c3f8ae68be0f3d7fee49a074",
"assets/assets/svg/pulse.svg": "f8247ea9c433347a3da038beaecbd194",
"assets/assets/svg/timer.svg": "f2f471cf50df036a243706cc21779860",
"assets/assets/images/happy.png": "80a0f8ee3b7ba9b646f14e8755be5705",
"assets/assets/images/loved.png": "2725a76b4e23a6f60665a7c6940fb2e4",
"assets/assets/images/sad.png": "10f2a0385919d074b9b2d8372cf50bdf",
"assets/assets/images/calender.png": "53ddf77d091a98325916d9d604bf20ef",
"assets/assets/images/goals.png": "fadd98822549953826e47fcfda4ced46",
"assets/assets/images/daily_action.png": "1c7e9c2a3574a797ef607e88b593f3ca",
"assets/assets/images/anxiety.png": "f9987cd2100ab7d6672c9572f47d8282",
"assets/assets/images/citiImg.png": "a29abf6971b2fc3a80ae5c8a7368ef54",
"assets/assets/images/get_mentor.png": "8be418929fe8389925d6c977fbd5c37e",
"assets/assets/images/angry.png": "be802e8330d05c11cbb8a018f6cf35c0",
"assets/assets/images/fear.png": "85363f3d71deb26100e55e4e6e46dc3f",
"assets/assets/images/growth.png": "d1807ebb1eb43c0e7abf6f6de83f44a7",
"assets/assets/images/confusion.png": "d435243cc27e639df58c0cc6448fadd9",
"assets/assets/images/People.png": "8e4d1de8bf79783f923ccda63773a976",
"assets/assets/images/shame.png": "7dd56ba0e60831b6f8c555e7c3ff6526",
"assets/assets/font/Inter_28pt-Medium.ttf": "4bf75147230e93108702b004fdee55df",
"assets/assets/font/Inter_18pt-Bold.ttf": "7ef6f6d68c7fedc103180f2254985e8c",
"assets/assets/font/Inter_28pt-Regular.ttf": "fc20e0880f7747bb39b85f2a0722b371",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"canvaskit/skwasm.js.symbols": "e72c79950c8a8483d826a7f0560573a1",
"canvaskit/canvaskit.js.symbols": "bdcd3835edf8586b6d6edfce8749fb77",
"canvaskit/skwasm.wasm": "39dd80367a4e71582d234948adc521c0",
"canvaskit/chromium/canvaskit.js.symbols": "b61b5f4673c9698029fa0a746a9ad581",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.wasm": "f504de372e31c8031018a9ec0a9ef5f0",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/canvaskit.wasm": "7a3f4ae7d65fc1de6a6e7ddd3224bc93"};
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
