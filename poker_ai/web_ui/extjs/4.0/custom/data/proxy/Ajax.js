Ext.define("Sms.data.proxy.Ajax", {
	override: "Ext.data.proxy.Ajax",

	/**
	 * @cfg {Object} requestConfig
	 * Any configurations to directly apply to the request object before
	 * calling {@link Ext.Ajax#request Ext.Ajax.request}.
	 */

	doRequest: function(operation, callback, scope){
		var me = this,
			writer = me.getWriter(),
			request = me.buildRequest(operation, callback, scope);

		if(operation.allowWrite()){
			request = writer.write(request);
		}

		Ext.apply(request, {
			headers:        me.headers,
			timeout:        me.timeout,
			scope:          me,
			callback:       me.createRequestCallback(request, operation, callback, scope),
			method:         me.getMethod(request),
			disableCaching: false
		});

		// Allows setting/overriding settings directly on the request object
		if(me.requestConfig){
			Ext.apply(request, me.requestConfig);
		}

		me.activeRequest = Ext.Ajax.request(request);  // Keep a reference to the current request

		return request;
	},

	/**
	 * Returns the currently running request object, or null.
	 * @return {Ext.data.Request} The request object
	 */
	getActiveRequest: function(){
		return this.activeRequest || null;
	},

	/**
	 * Removes the reference to the last request.
	 * @param {Ext.data.Request} request The request object
	 * @param {Boolean} success True if the request was successful
	 */
	afterRequest: function(request, success){
		this.activeRequest = null;
	},

	/**
	 * Stops all execution.
	 */
	stop: function(){
		if(this.activeRequest){
			Ext.Ajax.abort(this.activeRequest);
			this.activeRequest = null;
		}
	}
});