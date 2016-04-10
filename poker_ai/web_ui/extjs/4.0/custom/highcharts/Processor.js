/**
 * Mixin that performs Highcharts config pre-processing.
 */
Ext.define("Sms.highcharts.Processor", {
	uses: [
		'Sms.ColorMap'
	],

	/**
	 * Finds the contents of JavaScript bracket properties (e.g., obj[foo] => foo)
	 * @private
	 */
	bracketRe: /\[(\w+)\]/gi,

	/**
	 * Main entry point for Highcharts config processing.
	 * @param {Object} config Highcharts config object
	 */
	processChartConfig: function(config){
		try {
			var me = this;
			
			config.chart = config.chart || {};

			me.findSmsRef(config);
			me.searchConfig(config);
			me.rotateOppositeYAxisTitles(config.yAxis);
			me.initSeriesDataIndex(config.series);
			me.configureLegendBySeries(config);
		}
		catch(e){
			var rc = MrRunContainer;
			if(rc.isDebugMode)
				rc.openDebugInfo(rc.reportNumber, rc.instanceNumber, this.itemIndex, true, e.message, null, null);
			else{
				Ext.Error.raise({
						msg:  e.message
				});
			}
		}
	},

	rotateOppositeYAxisTitles: function(yAxis){
		var defaultConfig = {
			rotation: 270
		};

		Ext.Array.each(Ext.Array.from(yAxis), function(y){
			if(y.opposite){
				y.title = Highcharts.merge(defaultConfig, y.title);
			}
		});
	},

	initSeriesDataIndex: function(series){
		Ext.Array.each(Ext.Array.from(series), function(options){
			if(!options.dataIndex){
				options.dataIndex = "y";
			}
			if(Ext.isString(options.dataIndex)){
				options.dataIndex = {
					y: options.dataIndex
				};
			}
		});
	},

	configureLegendBySeries: function(config){
		var hasPieSeries = function(config, series){
			var defaultSeries = config.chart.type || "line";
			var hasPie = Ext.Array.some(series, function(s){
				return ((s.type || defaultSeries) === "pie");
			});
			return hasPie;
		};

		var seriesArray   = Ext.Array.from(config.series);
		var hasPie        = hasPieSeries(config, seriesArray);
		var legendDefault = {};

		if(hasPie){
			legendDefault = {
				align:    "right",
				floating: "true",
				layout:   "vertical"
			};
		}
		else if(seriesArray.length === 1){
			legendDefault = {
				enabled: false
			};
		}

		config.legend = Highcharts.merge(legendDefault, config.legend);
	},

	/**
	 * Performs a depth-first search on an object (or array of objects), calling
	 * the given function on each nested object.
	 *
	 * WARNING: Circular references will break everything!
	 *
	 * @param {Object/Object[]} obj The object or array to search.
	 *
	 * @param {Function} fn The callback function. If the function returns `false`
	 * at any point, searching is stopped on that branch.
	 * @param {Object} fn.obj The current object being searched
	 * @param {Object} fn.parent The parent object to `obj`
	 * @param {String} fn.property The property of `parent` that `obj` is
	 * assigned to (i.e., parent[property] === obj)
	 */
	objectSearch: function(obj, fn, /* private */ parent, /* private */ parentKey){
		var me = this;
		var prop,
			len,
			i;
		if(Ext.isArray(obj)){
			len = obj.length;
			for(i = 0; i < len; i++){
				me.objectSearch(obj[i], fn, obj, i);
			}
		}
		else if(Ext.isObject(obj)){
			if(fn.call(me, obj, parent, parentKey) !== false){
				for(prop in obj){
					if(obj.hasOwnProperty(prop)){
						me.objectSearch(obj[prop], fn, obj, prop);
					}
				}
			}
		}
	},

	findSmsRef: function(config){
		var me = this;
		me.objectSearch(config, function(obj, parent, parentKey){
			if(obj.hasOwnProperty("smsRef")){
				me.resolveSmsRef(parent, parentKey, me);
				return false;
			}
		});
	},

	/**
	 * Search the config object for instances of custom SMS configurations.
	 */
	searchConfig: function(config){
		var me = this;
		me.objectSearch(config, function(obj){
			if(obj.hasOwnProperty("smsColor")){
				if(Ext.isArray(obj.smsColor)){
					obj.colors = Ext.Array.map(obj.smsColor, me.generateGradient, me);
				}
				else{
					obj.color = me.generateGradient(obj.smsColor);
				}
				delete obj.smsColor;
			}
		});
	},

	/**
	 * @param {Object} obj  The parent object holding the SmsRef
	 * @param {String} key  The name of the property holding the SmsRef
	 * @param {Object} root The root object to use as "this" in the path
	 */
	resolveSmsRef: function(obj, key, root){
		var path      = obj[key].smsRef;
		var ref       = this.parseObjectPath(path);
		var len       = ref.length;
		var startIdx  = 0;
		var searchObj = window;
		var prop,
			i;

		// If using 'this' then refernce belongs to root object
		if(ref[0] === "this"){
			startIdx  = 1;
			searchObj = root;
		}

		for(i = startIdx; i < len; i++){
			prop = ref[i];

			if(typeof searchObj[prop] !== "undefined"){
				searchObj = searchObj[prop];
			}
			else{
				Ext.Error.raise({
					msg:  "SmsRef path not found",
					path: path
				});
			}
		}

		obj[key] = searchObj;
	},

	/**
	 * Processes an object path into an array of path components.
	 *
	 * The object path can use either dot or bracket notation to specify object
	 * properties. For example, the path to the string "apple" in the object
	 *
	 *     {foo: {bar: [null, null, "apple"]}}
	 *
	 * can be represented as any of the following:
	 *
	 *     foo.bar[2]
	 *     foo[bar].2
	 *     [foo][bar][2]
	 *     foo.bar.2
	 *
	 * @param {String} path The raw path string to parse
	 * @return {String[]} An array of path components
	 */
	parseObjectPath: function(path){
		var parsed = path.replace(this.bracketRe, ".$1");
		if(parsed.charAt(0) === "."){
			parsed = parsed.substr(1);
		}
		return parsed.split(".");
	},

	/**
	 * Returns a gradient object based on the colors in the input config.
	 * @param {String/Object} config The base color value for the gradient, or
	 * an object with the following properties:
	 * @param {String} config.base Base gradient color
	 * @param {String} [config.alt] Alternate gradient color. Defaults to a
	 * lighter version of the base color.
	 * @param {Number} [config.alpha=1] Opacity of the gradient
	 * @param {String} [config.type=linear] Gradient fill style. Can be either
	 * `linear` or `radial` for gradients, or `plain` for solid colors.
	 * @return {String/Object} The Highcharts gradient object, or an RGBA color
	 * string.
	 */
	generateGradient: function(config){
		if(Ext.isString(config) || Ext.isNumber(config)){
			config = {base: config};
		}
		Ext.applyIf(config, {
			alpha: 1,
			type:  "linear"
		});

		var rawBase = Sms.ColorMap.getColor(config.base) || config.base;
		var rawAlt  = Sms.ColorMap.getColor(config.alt) || config.alt;

		if(!Ext.isDefined(rawBase)){
			Ext.Error.raise("Gradient base color is required");
		}

		var Color     = Highcharts.Color;
		var baseColor = Color(rawBase).setOpacity(config.alpha).get("rgba");
		var altColor  = rawAlt && Color(rawAlt).setOpacity(config.alpha).get("rgba");

		if(config.type === "linear"){
			return {
				linearGradient: {
					x1: 0,
					y1: 1,
					x2: 1,
					y2: 1
				},
				stops: [
					[0,    baseColor],
					[0.33, altColor || Color(baseColor).brighten(0.4).get("rgba")],
					[1,    baseColor]
				]
			};
		}
		else if(config.type === "radial"){
			return {
				radialGradient: {
					cx: 0.3,
					cy: 0.3,
					r:  0.6
				},
				stops: [
					[0, altColor || Color(baseColor).brighten(0.2).get("rgba")],
					[1, baseColor]
				]
			};
		}
		else if(config.type === "plain"){
			return baseColor;
		}
	}
});
