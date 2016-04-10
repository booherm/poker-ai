Ext.define("Sms.form.Panel", {
	extend: "Ext.form.Panel",
	alias: 'widget.smsform',
	
	constructor: function(config) {
		
		var me = this;
		
		var smsFieldDefaults = {
			labelAlign: "right",
			msgTarget:  "side",
			labelWidth: 150,
			labelStyle: "font-weight:bold;"
		};
		if(config.fieldDefaults)
			Ext.applyIf(config.fieldDefaults, smsFieldDefaults);
		else
			config.fieldDefaults = smsFieldDefaults;
		
		if(!config.bodyStyle)
		{
			config.bodyStyle = {
				padding: "10px 5px 0",
				border:  0
			};
		}
		
		//apply basic attributes if they aren't specified
		Ext.applyIf(config, {
			autoScroll: true
		});
		
		me.callParent(arguments);
	}
});