/*
 * @author Paul Schroeder
 * A much simpler version of the chart container that's easy to use and lightweight in comparison to the one
 * in use on the run container.  See cdb_container.js for example usage.
 */
Ext.ns("Ext.container.Highchart");

Ext.container.chartProcessor = new Sms.highcharts.Processor();

Ext.define("Ext.container.Highchart", {
	extend: "Ext.Container",
	html: "<div class=\"sms_highchart\" style=\"height:100%;\"></div>",
	margin: 5,
 
	initComponent: function(){
		var me = this;
		me.addEvents(
			"dataload"
		);
		//need to defere these events because afterrender is called before reflow, the timeout will break that
		me.on("afterrender", function(){
			setTimeout(function(){
				me.renderChart(me);
			}, 1000);
		});
		me.on("afterlayout", me.layoutChart);
		me.callParent();
	},
	
	renderChart: function(){
		var me = this;
		
		Ext.container.chartProcessor.processChartConfig(me.chartConfig);

		$(me.getEl().dom).find("div.sms_highchart").highcharts(me.chartConfig);

		me.chart = $(me.getEl().dom).find("div.sms_highchart").highcharts();

		if(me.categories)
			me.setCategories(me.categories, false);

		if(me.data)
			me.setData(me.data);
	},
	
	layoutChart: function(component){
		var me = component;
		//this is a fix for the labels being off when a chart is not visible...
		if(me.chart)
			me.chart.reflow();
		//end fix
	},
	
	setCategories: function(categories, refresh){
		var me = this;
		me.categories = categories;
		if(me.chart)
			me.chart.xAxis[0].setCategories(categories, refresh);
	},
	
	setData: function(data, stopRefresh){
		var me = this;
		me.data = data;
		if(me.chart)
		{
			for(var i = 0; i < data.length; i++)
				me.chart.series[i].setData(data[i], false);
			if(!stopRefresh)
				me.chart.redraw();
		}
		me.fireEvent("dataload", me, data);
	},
	
	setTitle: function(title, subtitle, refresh){
		var me = this;
		if(me.chart)
		{
			me.chart.setTitle(title, subtitle, refresh);
		}
		else
		{
			me.chartConfig.title = title;
			if(subtitle)
				me.chartConfig.subtitle = subtitle;
		}
	}
	
});