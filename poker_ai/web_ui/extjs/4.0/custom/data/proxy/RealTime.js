// Real-time proxy that automatically resends a request on an interval
Ext.define("Sms.data.proxy.RealTime", {
	extend: "Ext.data.proxy.Ajax",
	alias:  "proxy.realtime",

	stopRefresh: false,  // Set true to stop auto-refresh
	timeoutId:   null,   // Holds the return value of Ext.defer
	
	filterParam: undefined,
	groupParam:  undefined,
	limitParam:  undefined,
	pageParam:   undefined,
	sortParam:   undefined,
	startParam:  undefined,

	// Only used for read actions
	create: function(){return null;},
	update: function(){return null;},
	destroy: function(){return null;},

	createRequestCallback: function(request, operation, callback, scope) {
        var me = this;

        return function(options, success, response) {
            me.processResponse(success, operation, request, response, callback, scope);
			if(!me.stopRefresh && me.refreshRate){
				me.timeoutId = Ext.defer(scope.load, me.refreshRate, scope);
			}
        };
    },

	stop: function(){
		this.callParent();
		this.stopRefresh = true;
		clearTimeout(this.timeoutId);
	}
});
