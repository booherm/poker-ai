/**
 * MrRunContainer-specific extension to the Highcharts chart wrapper.
 */
Ext.define("Sms.mr.Highcharts", {
	extend: "Sms.highcharts.Chart",
	
	requires: [
		"Sms.mr.HighchartsData"
	],

	hideMode: "offsets",
	margin:   4,

	useProcessor: true,

	constructor: function(config){
		var me = this;
		if(MrRunContainer.isPdfMode){
			config.margin = 0;
		}
		me.callParent([config]);
	},

	initComponent: function(){
		var me = this;

		me.renderTo = "mri_" + me.itemIndex;

		me.initBaseEl();

		me.initData(me.rawData, me.deferred);
		delete me.rawData;
		delete me.deferred;

		me.chartConfig.sms = Ext.apply(me.chartConfig.sms || {}, {
			itemIndex: me.itemIndex
		});

		me.callParent();
	},

	initBaseEl: function(){
		var me          = this;
		var chartConfig = me.chartConfig;
		var domId       = me.renderTo;
		var renderEl    = Ext.get(domId);
		var sizeAdjust  = (me.margin * 2);
		var exporting   = Ext.applyIf(chartConfig.exporting || {}, {
			width:  me.defaultPdfWidth,
			height: me.defaultPdfHeight
		});

		function getContentHeightOfOuterEl(el){
			var dom = el.dom;

			while(!dom.clientHeight && dom.parentNode){
				dom = dom.parentNode;
			}

			return Ext.fly(dom).getHeight(true);
		}

		function getContentWidthOfOuterEl(el){
			var dom = el.dom;

			// Get the first parent element that has a width
			while(!dom.clientWidth && dom.parentNode){
				dom = dom.parentNode;
			}

			return Ext.fly(dom).getWidth(true);
		}

		chartConfig.exporting = exporting;

		if(!renderEl){
			Ext.Error.raise("Could not find element '" + domId + "'");
		}

		if(!renderEl.isVisible()){
			renderEl.setStyle("display", "block");
			me.hide();
		}

		if(MrRunContainer.isPdfMode){
			me.width  = exporting.width;
			me.height = exporting.height;
		}

		Ext.batchLayouts(function(){
			if(!renderEl.isVisible()){
				renderEl.setStyle("display", "block");
				me.hide();
			}
			
			me.setWidth((me.width || getContentWidthOfOuterEl(renderEl)) - sizeAdjust);
			me.setHeight((me.height || getContentHeightOfOuterEl(renderEl)) - sizeAdjust);
		});
	},

	initData: function(rawData, deferred){
		var me = this;
		var data = me.data = new Sms.mr.HighchartsData();

		if(me.isHidden()){
			data.pause();
		}

		data.itemIndex = me.itemIndex;
		data.addRawData(rawData);
		data.initDeferred(deferred || []);
		data.initRealTime(rawData.realTime || {});
	},

	afterRender: function(){
		var me = this;
		me.callParent(arguments);

		if(!me.isRealTime()){
			me.getEl().mask("Loading...");
		}

		me.onDataChanged();

		me.data.on("datachanged", me.onDataChanged, me);
	},

	getChartLoadCallback: function(){
		var me = this;
		return function(){
			var chart = this;
			chart.reportItem = me;
			if(!me.chart){
				me.chart = chart;
				if(MrRunContainer.isDebugMode){
					me.addDebugLink();
				}
			}
		};
	},

	addDebugLink: function(){
		var me = this;

		var reportNumber   = MrRunContainer.reportNumber;
		var instanceNumber = MrRunContainer.instanceNumber;
		var itemIndex      = me.itemIndex;
		var isDrillDown    = MrRunContainer.isDrillDown;
		var isRealTime     = !!me.isRealTime();

		me.debugLink = me.createTextLink("Debug Info")
			.on("click", function(){
				MrRunContainer.openDebugInfo(
					reportNumber,
					instanceNumber,
					itemIndex,
					false,
					null,
					isDrillDown,
					isRealTime
				);
			})
			.align({
				verticalAlign: "bottom",
				x: 10,
				y: -10
			})
			.add();
	},

	isRealTime: function(){
		return this.data.isRealTime;
	},

	reloadSeriesData: function(){
		var me = this;

		me.chart.xAxis[0].setCategories(me.data.getCategories(), false);
		Ext.Array.each(me.chart.series, function(series){
			series.setData(me.data.getSeriesData(series.options.dataIndex), false);
		});
	},

	onDataChanged: function(){
		var me = this;

		if(me.fireEvent("beforerefresh", me) !== false){
			me.reloadSeriesData();
			me.chart.redraw();

			me.fireEvent("refresh", me);
		}
		if(me.data.records.length > 0){
			me.getEl().unmask();
		}
	},

	onDestroy: function(){
		var me = this;

		me.data.destroy();
		me.data = null;

		if(me.chart){
			if(me.debugLink){
				me.debugLink.destroy();
				me.debugLink = null;
			}
			me.chart.reportItem = null;
		}

		me.callParent(arguments);
	}
});
