'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "c826c87621221e689946cd81c6c97560",
"version.json": "46fd3fdf2257931d1ba3fee49eb584de",
"index.html": "a9abdfb20886e9dd66c39d634b691487",
"/": "a9abdfb20886e9dd66c39d634b691487",
"main.dart.js": "95e9b7ba9b8239351c9a391aa524ad28",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"manifest.json": "a3c04a76600a32dc5aa121b1aa3fe8fa",
"assets/NOTICES": "0d0bc2b30a616dee1001778b05411f36",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin.json": "15c337f8d7deb69fe5db8399e6cf3ab4",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"assets/AssetManifest.bin": "107d2c3946071dd9afa921badeb4a419",
"assets/fonts/MaterialIcons-Regular.otf": "85bb4a636773705c5a1b27b1489fd386",
"assets/assets/images/caltrops.png": "b19cd191db28d4bf40775326a69bb498",
"assets/assets/images/undead_bat.png": "427da697b6cce1e683927628da93bf80",
"assets/assets/images/survival_mode_estate_screen_layout.png": "9aa145ea779868f9b460fa89bae39767",
"assets/assets/images/card_background.png": "9bb932af0fee165e2c6b733065519d31",
"assets/assets/images/Carl_Spitzweg_-_Der_Maler_im_Garten.jpg": "87828e3c97ee6c1cbbfa3e8e04b4aa67",
"assets/assets/images/battlefield_layoutv2.png": "7a9b7343694ade34c1a65499f860a1f3",
"assets/assets/images/survey_estate_rolle.jpeg": "ad6831438780207b950fdf3a42560e63",
"assets/assets/images/Abomination_icon.jpg": "fb72b41146401167177d8a82ee89e301",
"assets/assets/images/Basementlayout.png": "0dd79adb6a062207638bd01103f6883c",
"assets/assets/images/flesh_golem.png": "23b7c301b4d921bf39936df5c39fffae",
"assets/assets/images/undead_rat.png": "f075b41826c1016be2a6eaafa3ba3936",
"assets/assets/images/survey_estate_rolle.png": "3f354bc99f32458780b8c48f0d38d2c5",
"assets/assets/images/hamlet.jpg": "14288e2af41b5a8ba9535fbe8ea77932",
"assets/assets/images/rolle_area.jpg": "09c9199bb73b50fd324ede8628e66949",
"assets/assets/images/battlefield_layout.png": "24f579ca0a74343fe5c5493cec5a9039",
"assets/assets/images/survival/BtoFallow.png": "5365eca34dd2cbad370e8e3d57208b9c",
"assets/assets/images/survival/FtoMill.png": "12eb5c6a547313929c080865a218161f",
"assets/assets/images/survival/FtoMine.png": "40519e9ec7ff268a3daca35f2508ff14",
"assets/assets/images/survival/Mdamage.png": "525077781de635ca5bbcc4b65720a1bf",
"assets/assets/images/survival/GtoFarm.png": "b2d0fbc7c9ff1831c853d61e2796141b",
"assets/assets/images/survival/GtoFallow.png": "84032b8e405177929746afba5587b704",
"assets/assets/images/survival/AtoGarage.png": "476426668ede01a69b6abd8b6172edc7",
"assets/assets/images/survival/BtoGarage.png": "22288a5eb890fdf982520201b8cddbeb",
"assets/assets/images/survival/DtoFallow.png": "2bcfb121f61162f8415270996020af52",
"assets/assets/images/survival/EWdamage.png": "1c6c556b8d8f5b5050a2a4942edbd5f6",
"assets/assets/images/survival/EtoMine5.png": "838ded258787bce6b81b988417c76458",
"assets/assets/images/survival/GtoMill.png": "aa45f69f3ba8e5b45072bca0ea3f9fbe",
"assets/assets/images/survival/CtoFarm2.png": "4d236d5aec2da7e97ada29671b9ecc8f",
"assets/assets/images/survival/GtoMine.png": "72516691ae85b72489ff686446ee99bc",
"assets/assets/images/survival/CtoFarm6.png": "2cd485401c0c8f7c0d4f2d6beca89f5b",
"assets/assets/images/survival/MWdamage.png": "3d4831a81f61002c95d910a50c741e31",
"assets/assets/images/survival/FtoFarm.png": "c1d9e8c3a508c8fa72b22a8022d14432",
"assets/assets/images/survival/AtoArsenal.png": "5434a232c437dd1578c9ad07a8275f67",
"assets/assets/images/survival/CtoFarm4.png": "3e6b85cb431b572a525e6d732c68807f",
"assets/assets/images/survival/AtoFallow.png": "7fc958f326a4f6a4e4c30033336b0f82",
"assets/assets/images/survival/FtoFallow.png": "d19fecc9b2e83f83897d28011825fdbb",
"assets/assets/images/survival/AtoMunitions.png": "e9b8456bd2e69d71971ab7778b00f606",
"assets/assets/images/survival/DtoMine.png": "4d5348b8cd8e96008528a76e4aed25b2",
"assets/assets/images/survival/DtoMill.png": "01fa445b19f2958e86303c06f02f5226",
"assets/assets/images/survival/EtoFarm.png": "62e5bc3432cac74bfc2d72ea3b7154dc",
"assets/assets/images/survival/FtoMine5.png": "279d851d802a1a1047aef05ebc1ae865",
"assets/assets/images/survival/EMWdamage.png": "10cb11e6380008cde360c728249e2dbf",
"assets/assets/images/survival/Wdamage.png": "9c818fe45d33d97421d800249b8932ee",
"assets/assets/images/survival/BtoArsenal.png": "d1f2d67edcf826b394a5f4361de54cbe",
"assets/assets/images/survival/CtoFallow.png": "3d61b5f8e9ef65c3ec712a7f8d9984cf",
"assets/assets/images/survival/Edamage.png": "38c3f5523ab509b9216b65972ea92390",
"assets/assets/images/survival/EtoMine.png": "9da67c51ceed89c527e98efee19bd7d4",
"assets/assets/images/survival/Estate.png": "c941c6cf805c6fb91fc4c80dbba5f7c4",
"assets/assets/images/survival/EMdamage.png": "6ecca1604c0c1a78f634f2531680c013",
"assets/assets/images/survival/BtoMunitions.png": "2f2f303c40b5738a2dabac321f6d0669",
"assets/assets/images/survival/EtoMill.png": "9473e288fcd7950deb05e0a286707c71",
"assets/assets/images/survival/DtoFarm.png": "2df643e4f718afdd468311b4958f03dd",
"assets/assets/images/survival/VillagetoFallow.png": "11cad19aa022cbfa9b2a4c487f541666",
"assets/assets/images/survival/DtoMine5.png": "167efa479732288a0a5450318c80c35c",
"assets/assets/images/survival/EtoFallow.png": "a3565376bf7a524ede7eb68a731db7fe",
"assets/assets/audio/sfx_combat_death.wav": "c2c3342084c19cc7073521731e884a18",
"assets/assets/audio/cloop.wav": "37c7a468d238c99a05839b2e11fc7173",
"assets/assets/audio/vivaldi_winter.m4a": "6735970b7211759599b9b55f4e0cc6ed",
"assets/assets/audio/sfx_combat_caltrops.wav": "32d4c855d9f99f4619df135fcdb9b66d",
"assets/assets/audio/sfx_footsteps.wav": "023947b95da099163c4a6b8ced4fc77b",
"assets/assets/audio/sfx_writing.wav": "47d48982fe6835d91d99cbb6f4003095",
"assets/assets/audio/sfx_meal.wav": "303ddc5248d03424c9932ca59cf7e7e1",
"assets/assets/audio/sfx_pleased.wav": "eea427805ac43849cdc61ec33e4e55ea",
"assets/assets/audio/sfx_experiment.wav": "3899ebd098cf9a9fc427537f8890eb86",
"assets/assets/audio/sfx_displeased.wav": "44845dd132e1c931ae8eae6693fdae91",
"assets/assets/audio/aloop.wav": "25c98c00da66fb5acb4b1d87289a676b",
"assets/assets/audio/buttonpress2.wav": "1fc77e613ff0fabc450612311cc38b59",
"assets/assets/audio/buttonpress1.wav": "342c1830015a8725870f98e0bcc91aab",
"assets/assets/audio/sfx_achievement.wav": "f4376c7b19c0d79554b150d7570c1c70",
"assets/assets/audio/pleased1.wav": "91c62f79fca4bef2371bd473338487e0",
"assets/assets/audio/sfx_cooking.wav": "d1f553ebdacfc48000d44666fcbc404d",
"assets/assets/audio/a.wav": "183bf4f4597624cddeeff1b2280873c5",
"assets/assets/audio/vivaldi_spring_mvt1.m4a": "815b1c29f93beb824c401d2e8253260a",
"assets/assets/audio/pleased2.wav": "12d509d55a176fb8a275a59885f82bde",
"assets/assets/audio/sfx_tap.wav": "5ef9e050c0903b5a4b9b584cf05b4007",
"assets/assets/audio/dloop.wav": "9a387ee542ae2140a5a605b40bf51c7b",
"assets/assets/audio/sfx_giles_shuffle.wav": "15b9c15917d8899e35f1baa23a127534",
"assets/assets/audio/displeased2.wav": "40f555f6bd619a2237911b815bf98c06",
"assets/assets/audio/eloop.wav": "e71231211478c0bd69a99ab4480cf549",
"assets/assets/audio/g.wav": "9a0b631b431f17ad22e0f862b940c9ff",
"assets/assets/audio/sfx_cleaning.wav": "5f09762754e249d14b7622fa9bc8e9ae",
"assets/assets/audio/displeased1.wav": "51a49fd9f90eb93079a671606f7b16c7",
"assets/assets/audio/e.wav": "22ca3580a9371a60be714f41c18e227e",
"assets/assets/audio/d.wav": "9211167a04c3a12afbbac438969ec434",
"assets/assets/audio/sfx_washing.wav": "a9604b5419610bfa116bb36c8a1ddf37",
"assets/assets/audio/soundtrack.mp3": "8eec510e57f5f732fd2cce73df7b73ef",
"assets/assets/audio/sfx_construction.wav": "84ac52a0dc6887a87cdf5a0abe764fb8",
"assets/assets/audio/gloop.wav": "63aa9700f8abb36b492ef99a2f60f304",
"assets/assets/audio/sfx_combat_summon.wav": "c1bbf74436554a02841db13564bd04c7",
"assets/assets/audio/sfx_eggs.wav": "4bff1f658f264949327cad3adc6bb9ce",
"assets/assets/audio/handwash.wav": "8dc291ac22909776517f26b187f0473b",
"assets/assets/audio/sfx_fieldwork.wav": "f9b68be9fa8ff36fd39525d80fea7102",
"assets/assets/audio/sfx_butcher.wav": "8a2c27fd9bfacbde08c14d7773910d67",
"assets/assets/audio/sfx_combat_attack.wav": "f1728ac077bf921fe08693d5a32b805d",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01"};
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
