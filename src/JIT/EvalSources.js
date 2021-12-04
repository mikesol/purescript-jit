exports.freshModules = function () {
	return {};
};
exports.evalSources_ = function (modules) {
	return function (sources) {
		function dirname(str) {
			var ix = str.lastIndexOf("/");
			return ix < 0 ? "" : str.slice(0, ix);
		}
		function resolvePath(a, b) {
			if (b[0] === "." && b[1] === "/") {
				return dirname(a) + b.slice(1);
			}
			if (b[0] === "." && b[1] === "." && b[2] === "/") {
				return dirname(dirname(a)) + b.slice(2);
			}
			return b;
		}
		return function load(name) {
			return function () {
				if (name !== "<file>" && modules[name]) {
					return { modules: modules, evaluated: modules[name].exports };
				}
				function require(path) {
					return load(resolvePath(name, path))().evaluated;
				}
				var module = (modules[name] = { exports: {} });
				try {
					new Function("module", "exports", "require", sources[name])(
						module,
						module.exports,
						require
					);
				} catch (e) {
					console.error("ERR", e);
					console.error(name);
					console.error(sources[name]);
					throw e;
				}
				return { modules: modules, evaluated: module.exports };
			};
		};
	};
};
