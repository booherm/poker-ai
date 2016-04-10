/**
 * Basic component wrapper for a Highcharts chart.
 */
Ext.define("Sms.highcharts.Chart", {
	extend: "Ext.Component",
	alias:  "widget.highcharts",

	requires: [
		"Sms.ColorMap"
	],

	mixins: {
		processor: "Sms.highcharts.Processor"
	},
	
	/**
	 * @cfg {Object} chartConfig (required)
	 * A Highcharts configuration object.
	 */
	chartConfig: null,
	
	/**
	 * @cfg {Boolean} useProcessor
	 * Set `true` to process the {@link #chartConfig} before creating the chart.
	 * See {@link Sms.highcharts.Processor} for more information.
	 */
	useProcessor: false,

	/**
	 * @inheritdoc
	 */
	initComponent: function(){
		var me = this;
		if(!me.chartConfig){
			Ext.Error.raise("A chartConfig object must be specified.");
		}
		me.callParent();
	},

	/**
	 * @inheritdoc
	 */
	afterRender: function(){
		var me = this;
		me.callParent(arguments);
		me.chart = me.createChart(me.chartConfig);
	},

	/**
	 * @inheritdoc
	 */
	afterComponentLayout: function(){
		var me = this;
		me.callParent(arguments);
		me.resizeChart();
	},

	/**
	 * Creates and returns a Highcharts chart for embedding in the component.
	 *
	 * @param {Object} config a Highcharts chart config object
	 * @return {Highcharts.Chart} the Highcharts chart specified by the config
	 */
	createChart: function(config){
		var me   = this;
		var size = me.getChartTargetSize();

		if(me.useProcessor){
			me.processChartConfig(config);
		}

		var outputConfig = Highcharts.merge(config, {
			chart: {
				width:    size.width || null,
				height:   size.height || null,
				renderTo: me.getEl().dom
			}
		});

		return new Highcharts.Chart(outputConfig, me.getChartLoadCallback());
	},

	/**
	 * Returns the Highcharts chart.
	 *
	 * @return {Highcharts.Chart}
	 */
	getChart: function(){
		return this.chart;
	},

	/**
	 * Uses the chart's renderer to create a text element that looks like a link.
	 *
	 * IMPORTANT: This method only creates the link. It does not apply click event
	 * handlers, it does not align the element, and it does not add the element
	 * to the chart. This must be done manually.
	 *
	 * @param {String} text  the text to display
	 * @param {Number} [x]  the x-coordinate to position the link
	 * @param {Number} [y]  the y-coordinate to position the link
	 * @param {Boolean} [useHtml=false]  `true` to render as HTML instead of SVG
	 * @return {Highcharts.Element}  the text element in a Highcharts wrapper
	 */
	createTextLink: function(text, x, y, useHtml){
		var me      = this;
		var BLUE    = "#1F497D";
		var ORANGE  = "#F79646";

		if(!me.rendered){
			return null;
		}

		var linkObj = me.chart.renderer
			.text(text, x, y, useHtml)
			.css({
				cursor:         "pointer",
				fill:           BLUE,
				fontFamily:     "Helvetica, Arial, 'sans-serif'",
				fontSize:       "12px",
				fontWeight:     "bold",
				textDecoration: "underline"
			});

		linkObj
			.on("mouseover", function(){
				linkObj.css({fill: ORANGE});
			})
			.on("mouseout", function(){
				linkObj.css({fill: BLUE});
			});

		return linkObj;
	},

	/**
	 * Resizes the embedded chart based on the component's size.
	 * @private
	 */
	resizeChart: function(){
		var me        = this;
		var innerSize = me.getChartTargetSize();

		me.chart.setSize(innerSize.width, innerSize.height, false);
	},

	/**
	 * Returns the available size of the chart.
	 * @private
	 *
	 * @return {Object} the size available for the chart
	 * @return {Number} return.height the available height
	 * @return {Number} return.width the available width
	 */
	getChartTargetSize: function(){
		return this.getEl().getSize(true);
	},

	/**
	 * Returns the function to provide to the Highcharts constructor when creating the
	 * chart. Returned function should be scoped to the Highcharts chart.
	 * @template
	 */
	getChartLoadCallback: function(){
		return Ext.emptyFn;
	},

	/**
	 * @inheritdoc
	 */
	onDestroy: function(){
		var me = this;

		if(me.chart){
			me.chart.destroy();
			me.chart = null;
		}

		me.callParent();
	}
});
