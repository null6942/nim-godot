/* Kill-switch: an older Godot PWA worker can keep serving the 2D pack after origin updates. */
self.addEventListener('install', function (event) {
	self.skipWaiting();
});

self.addEventListener('activate', function (event) {
	event.waitUntil((async function () {
		var keys = await caches.keys();
		await Promise.all(keys.map(function (k) { return caches.delete(k); }));
		await self.registration.unregister();
		var windows = await self.clients.matchAll({ type: 'window' });
		windows.forEach(function (client) { client.navigate(client.url); });
	})());
});
