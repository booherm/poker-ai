Ext.define("Sms.mr.Label", {
	dataUrl: "mrd_get_data.jsp",

	constructor: function(config){
		var me = this;

		me.itemIndex = config.item_index;
		me.isRealTime = config.is_real_time;
		me.refreshRate = config.refresh_rate;
		me.afterRtCutoff = config.after_rt_cutoff;
		me.data = config.data;

		me.initComponent();
	},

	initComponent: function(){
		var me = this,
			el = Ext.get("mri_" + me.itemIndex),
			rc = MrRunContainer;

		if(!el){
			Ext.Error.raise("Run Container: Could not find layout element for item " + me.itemIndex);
			return;
		}

		if(me.isRealTime && !me.afterRtCutoff){
			rc.maskItem(me.itemIndex, "Live label items ran prior to 11/15/2011 are no longer supported.", false, true);
			return;
		}

		me.layoutEl = el;

		if(me.isRealTime){
			me.timerOn = true;
			me.timer = null;

			me.realTimeParams = {
				report_number:     rc.reportNumber,
				instance_number:   rc.instanceNumber,
				item_index:        me.itemIndex,
				is_drill_down:     rc.isDrillDown,
				prompt_values_set: rc.promptValuesSet,
				is_real_time:      true,
				is_debug_mode:     rc.isDebugMode,
				context:           "LABEL"
			};

			me.refresh();
		}
		else{
			me.loadData(me.data);
		}
	},

	loadData: function(data){
		var me = this,
			first = me.layoutEl.first();

		if(first){
			Ext.DomHelper.insertBefore(first, data);
			first.remove();
		}
		else{
			if(MrRunContainer.isDebugMode){
				data += "<br/>" + me.getDebugLink();
			}
			me.layoutEl.setHTML(data);
		}
	},

	getDebugLink: function(){
		var me = this;
		if(!me.debugLink){
			me.debugLink = [
				"<span",
				" onclick='MrRunContainer.openDebugInfo(",
					MrRunContainer.reportNumber, ", ",
					MrRunContainer.instanceNumber, ", ",
					me.itemIndex, ", false, null, ",
					me.isRealTime, ");'",
				" onmouseover=\"this.style.color='#F79646';\"",
				" onmouseout=\"this.style.color='#1F497D';\"",
				" style=\"color:#1F497D;text-decoration:underline;cursor:pointer;font-weight:bold;\">",
				"Debug Info</span>"
			].join("");
		}
		return me.debugLink;
	},

	refresh: function(){
		var me = this;

		Sms.Ajax.request({
			url:      me.dataUrl,
			type:     "POST",
			dataType: "text",
			data:     me.realTimeParams,
			success:  function(data){
				if(me.timerOn){
					try{
						var responseObject = json_parse(data);
						me.realTimeParams.dd_record_number = responseObject.dd_record_number;
						me.loadData(responseObject.label_html);
					}
					catch(err){
						//don't want to stop the refresh
					}
				}
			},
			complete: function(){
				if(me.timerOn){
					me.timer = Ext.defer(me.refresh, me.refreshRate, me);
				}
			},
			disableTimeoutRetry: me.isRealTime,
			stopErrorReporting: true
		});
	},

	destroy: function(){
		try{
			this.timerOn = false;
			if(this.timer){
				clearTimeout(this.timer);
				this.timer = null;
			}
			Ext.destroy(this.layoutEl);
			this.layoutEl = null;
		}
		catch(err){
			// Nothing...
		}
	}
});
