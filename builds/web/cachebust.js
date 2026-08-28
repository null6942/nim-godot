/* Force a fresh 3D pack. Old index.pck (78 KB 2D) was sticky in browser HTTP cache. */
(function () {
	var VERSION = '3d-20260828-2';

	function bump(u) {
		if (typeof u !== 'string') {
			return u;
		}
		if (/\.(pck|wasm|js)(\?|$)/.test(u) && u.indexOf('v=') === -1) {
			return u + (u.indexOf('?') >= 0 ? '&' : '?') + 'v=' + VERSION;
		}
		return u;
	}

	var origFetch = window.fetch;
	window.fetch = function (input, init) {
		var url = typeof input === 'string' ? input : (input && input.url);
		var bumped = bump(url);
		if (typeof input === 'string') {
			input = bumped;
		} else if (input instanceof Request && bumped !== url) {
			input = new Request(bumped, input);
		}
		var opts = init ? Object.assign({}, init) : {};
		if (typeof bumped === 'string' && /\.(pck|wasm)(\?|$)/.test(bumped)) {
			opts.cache = 'reload';
		}
		return origFetch.call(this, input, Object.keys(opts).length ? opts : init);
	};

	if ('serviceWorker' in navigator) {
		navigator.serviceWorker.getRegistrations().then(function (regs) {
			regs.forEach(function (r) { r.unregister(); });
		});
	}
	if (window.caches && caches.keys) {
		caches.keys().then(function (keys) {
			keys.forEach(function (k) { caches.delete(k); });
		});
	}
})();
