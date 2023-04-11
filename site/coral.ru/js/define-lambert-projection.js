export function defineLambertProjection() {

    ymaps.modules.define('projection.LambertConformalConic', [
        'util.defineClass',
        'util.math.cycleRestrict',
        'coordSystem.geo',
        'meta'
    ], function (provide, defineClass, cycleRestrict, CoordSystemGeo, meta) {
        /**
         * @fileOverview
         * Равноугольная коническая проекция Ламберта.
         */

        var latLongOrder = meta.coordinatesOrder != 'longlat';

        /**
         * Создает равноугольную коническую проекцию Ламберта.
         *
         * @name projection.LambertConformalConic
         * @class Равноугольная коническая проекция Ламберта.
         * Учитывает параметр coordorder, заданный при подключении API.
         * @augments IProjection
         */
        function LambertConformalConic() {
            if (ymaps.meta.debug) {
                if (!center[0] || !center[1]) {
                    throw new Error("projection.LambertConformalConic: Некорректные значения параметра center.");
                }
            }

            this._degToRad = function (point) {
                return point * Math.PI / 180;
            };
            this._radToDeg = function (rad) {
                return rad / (Math.PI / 180);
            };

            // Широта и долгота точки, которая служит началом координат в декартовой системе проекции.
            this._fi0 = this._degToRad(0);
            this._l0 = this._degToRad(-10);

            // Стандартные параллели.
            this._fi1 = this._degToRad(70);
            this._fi2 = this._degToRad(40);
            // this._fi1 = this._degToRad(80);
            // this._fi2 = this._degToRad(20);
        }

        defineClass(LambertConformalConic, {
            toGlobalPixels: function (point, zoom) {
                if (ymaps.meta.debug) {
                    if (!point) {
                        throw new Error("LambertConformalConic.toGlobalPixels: не передан параметр point");
                    }
                    if (typeof zoom == "undefined") {
                        throw new Error("LambertConformalConic.toGlobalPixels: не передан параметр zoom");
                    }
                }

                // Широта и долгота точки на поверхности Земли.
                var fi = this._degToRad(point[latLongOrder ? 0 : 1]);
                var l = this._degToRad(point[latLongOrder ? 1 : 0]);

                var n = (Math.log(Math.cos(this._fi1) / Math.cos(this._fi2))) / (Math.log(Math.tan(0.25 * Math.PI + 0.5 * this._fi2) / Math.tan(0.25 * Math.PI + 0.5 * this._fi1)));
                var F = (Math.cos(this._fi1) * Math.pow(Math.tan(0.25 * Math.PI + 0.5 * this._fi1), n)) / (n);
                var p = F * Math.pow(1 / Math.tan(0.25 * Math.PI + 0.5 * fi), n);
                var p0 = F * Math.pow(1 / Math.tan(0.25 * Math.PI + 0.5 * this._fi0), n);

                // Декартовы координаты той же точки на проекции.
                var x = p0 - p * Math.cos(n * (l - this._l0));
                var y = p * Math.sin(n * (l - this._l0));

                x = x * 128 * Math.pow(2, zoom);
                y = y * 128 * Math.pow(2, zoom);

                return [x, y];
            },
            // Если вам нужно переводить глобальные пиксельные координаты в широту и долготу, необходимо реализовать
            // метод fromGlobalPixels. Это может понадобиться, например, если вы захотите воспользоваться линейкой.
            fromGlobalPixels: function (point, zoom) {
                // if (ymaps.meta.debug) {
                //     console.log('projection.LambertConformalConic#fromGlobalPixels не имплементировано');
                // }
                // return [0, 0];
                var y = point[0], x = point[1];
                x /= 128 * Math.pow(2, zoom);
                y /= 128 * Math.pow(2, zoom);

                var n = (Math.log(Math.cos(this._fi1) / Math.cos(this._fi2))) / (Math.log(Math.tan(0.25 * Math.PI + 0.5 * this._fi2) / Math.tan(0.25 * Math.PI + 0.5 * this._fi1)));
                var F = (Math.cos(this._fi1) * Math.pow(Math.tan(0.25 * Math.PI + 0.5 * this._fi1), n)) / (n);
                var p0 = F * Math.pow(1 / Math.tan(0.25 * Math.PI + 0.5 * this._fi0), n);

                var p = Math.sign(n) * Math.sqrt(x * x + (p0 - y) * (p0 - y));
                var th = Math.atan(x / (p0 - y));

                var fi = 2 * Math.atan(Math.pow(F / p, 1 / n)) - (Math.PI / 2);
                var l = this._l0 + th / n;

                return latLongOrder ? [this._radToDeg(fi), this._radToDeg(l)] : [this._radToDeg(l), this._radToDeg(fi)];

            },

            isCycled: function () {
                return [false, false];
            },

            getCoordSystem: function () {
                return CoordSystemGeo;
            }
        });

        provide(LambertConformalConic);
    });

    return new Promise((resolve, reject) => {
        ymaps.modules.require('projection.LambertConformalConic', function (module) {
            resolve(module);
        }, function (ex) {
            reject(ex);
        });
    });

}
