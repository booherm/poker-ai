/**
 * @author  Eric Cook
 * @class   Sms.data.proxy.JQuery
 * @extends Ext.data.proxy.Server
 *
 * Allows Ext JS {@link Ext.data.Store Stores} to use jQuery Ajax requests using
 * their own interface. This cuts down some of the coding overhead of having to
 * manually configure requests and store loading.
 */
Ext.define("Sms.data.proxy.JQuery", {
	extend: "Ext.data.proxy.Server",
	alias:  "proxy.jquery",

	/**
     * @property {Object} actionMethods
     * Mapping of action name to HTTP request method. All actions use "POST" by default.
     */
	actionMethods: {
		create:  "POST",
		read:    "POST",
		update:  "POST",
		destroy: "POST"
	},

	/**
	 * @property {Object} requestConversions
	 * Mapping of Ext JS request configurations to jQuery request configs.
	 */
	requestConversions: {
		params:         "data",
		method:         "type",
		callback:       "complete",
		disableCaching: "cache"
	},

	/**
	 * @property {Object} activeRequest
	 * The jQuery jqXHR object of the actively running request.
	 */
	activeRequest: null,

	/**
	 * @cfg {Number} [realTime=0]
	 * The number of milliseconds to wait before making another request. If this
	 * value equals 0, then the request will only be made once.
	 */
	realTime: 0,

	/**
	 * @property {Boolean} [stopRefresh=false]
	 * Set true to stop real-time refreshing.
	 */
	stopRefresh: false,

	/**
	 * @cfg {Object} requestConfig
	 * Any configurations to directly apply to the request object before
	 * calling {@link Ext.Ajax#request Ext.Ajax.request}.
	 */

	/**
     * In ServerProxy subclasses, the {@link #create}, {@link #read}, {@link #update} and {@link #destroy} methods all
     * pass through to doRequest. Each ServerProxy subclass must implement the doRequest method - see {@link
     * Ext.data.proxy.JsonP} and {@link Ext.data.proxy.Ajax} for examples. This method carries the same signature as
     * each of the methods that delegate to it.
     *
     * @param {Ext.data.Operation} operation The Ext.data.Operation object
     * @param {Function} callback The callback function to call when the Operation has completed
     * @param {Object} scope The scope in which to execute the callback
     */
	doRequest: function(operation, callback, scope){
		var me = this,
			writer = me.getWriter(),
			request = me.buildRequest(operation, callback, scope),
			jqReq;

		if(operation.allowWrite()){
			request = writer.write(request);
		}

		Ext.apply(request, {
			headers:        me.headers,
			timeout:        me.timeout,
			scope:          me,
			callback:       me.createRequestCallback(request, operation, callback, scope),
			method:         me.getMethod(request),
			disableCaching: true,
			dataType:       "text"
		});

		jqReq = me.convertRequest(request);
		if(me.requestConfig){
			Ext.apply(jqReq, me.requestConfig);
		}

		me.activeRequest = Sms.Ajax.request(jqReq);

		return request;
	},

	/**
	 * Returns a jQuery-compatible request object from the request provided.
	 * @param {Ext.data.Request} request The request object
	 * @return {Object} The jQuery request equivalent of the Ext JS request
	 */
	convertRequest: function(request){
		var jqReq = Ext.apply({}, request);
		
		// Convert property names
		Ext.Object.each(this.requestConversions, function(extProp, jqProp){
			jqReq[jqProp] = request[extProp];
			delete jqReq[extProp];
		});

		return jqReq;
	},
	
	getMethod: function(request){
		return this.actionMethods[request.action];
	},

	createRequestCallback: function(request, operation, callback, scope){
		var me = this;
		return function(jqXHR, textStatus){
			me.processResponse(textStatus === "success", operation, request, jqXHR, callback, scope);
			if(!me.stopRefresh && me.realTime){
				me.timeoutId = Ext.defer(scope.load, me.realTime, scope);
			}
		};
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
	afterRequest: function(){
		this.activeRequest = null;
	},

	/**
	 * Stops all execution.
	 */
	stop: function(){
		var me = this;
		
		me.stopRefresh = true;
		clearTimeout(me.timeoutId);
		me.timeoutId = null;

		if(me.activeRequest){
			me.activeRequest.abort();
			me.activeRequest = null;
		}
	}
});
