document.addEventListener("DOMContentLoaded", function () {
	var e = document.querySelector("[data-copy]"),
		t = document.querySelector(".tooltip-btn");
	e.addEventListener("click", function (e) {
		e.preventDefault();
		var t = e.currentTarget,
			c = t.closest("#tooltip").querySelector("#erid");
		navigator.clipboard
			.writeText("".concat(c.textContent))
			.then(function () {
				var e;
				(e = t),
					console.log("Успех"),
					e.classList.add("success"),
					setTimeout(function () {
						e.classList.remove("success");
					}, 1e3);
			})
			.catch(function () {
				var e;
				(e = t), console.log("Не удача"), e.classList.remove("success");
			});
	}),
		t.addEventListener("click", function (e) {
			return e.preventDefault();
		});
});