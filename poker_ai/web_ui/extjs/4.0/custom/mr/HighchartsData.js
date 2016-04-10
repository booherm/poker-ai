/**
 * Stores the data for a {@link Sms.mr.Highcharts HighchartsChart} report item.
 */
Ext.define("Sms.mr.HighchartsData", {
	mixins: {
		observable: "Ext.util.Observable"
	},
	requires: [
		"Ext.util.MixedCollection"
	],

	/**
	 * @property {Boolean} destroying
	 * `true` if the object is in the middle of {@link #method-destroy}ing.
	 * @readonly
	 */
	destroying: false,

	/**
	 * @property {Boolean} isDestroyed
	 * `true` if the object is {@link #method-destroy}ed.
	 * @readonly
	 */
	isDestroyed: false,

	/**
	 * @property {Ext.util.MixedCollection} records
	 * A collection of records indexed by the record's `x` value.
	 * @readonly
	 */
	records: null,

	/**
	 * @property {Object} rawData
	 * A map of raw sub-item data, indexed by sub-item index
	 * @readonly
	 */
	rawData: null,

	/**
	 * @property {Object} requests
	 * A map of currently active Ajax requests for real-time data
	 * @readonly
	 */
	requests: null,

	/**
	 * @property {Object} timeouts
	 * A map of currently active timeout IDs returned from {@link Ext#defer}
	 * @readonly
	 */
	timeouts: null,

	/**
	 * @property {Boolean} isRealTime
	 * `true` if there are any real-time items registered
	 * @readonly
	 */
	isRealTime: false,

	/**
	 * @property {Boolean} paused
	 * `true` if real-time refreshes are paused, `false` otherwise.
	 * @private
	 */
	paused: false,

	/**
	 * Additional prompts to send with the data request.
	 */
	extraPrompts: "",

	/**
	 * @event beforedestroy
	 * Fires before the object is {@link #method-destroy}ed.
	 * @param {Sms.mr.HighchartsData} this
	 * @preventable
	 */

	/**
	 * @event clear
	 * Fires when the data is {@link #method-clear}ed.
	 * @param {Sms.mr.HighchartsData} this
	 */

	/**
	 * @event datachanged
	 * Fires when the stored data changes or updates.
	 * @param {Sms.mr.HighchartsData} this
	 */

	/**
	 * @event destroy
	 * Fires when the object is {@link #method-destroy}ed.
	 * @param {Sms.mr.HighchartsData} this
	 */

	 /**
	  * Creates a new HighchartsData instance.
	  */
	constructor: function(config){
		var me = this;
		me.callParent([config]);

		me.rawData  = {};
		me.requests = {};
		me.timeouts = {};
		me.records  = new Ext.util.MixedCollection(false, me.getKey);

		me.mixins.observable.constructor.call(me);
	},

	/**
	 * Adds an entire raw data object from the server
	 * @param {Object} rawData The raw sub-item data
	 */
	addRawData: function(rawData){
		try{
			var me = this;

			if(rawData.items){
				me.suspendEvents();

				Ext.Array.each(rawData.items, function(subItemIndex){
					me.addSubItem(subItemIndex, rawData[subItemIndex]);
				});

				me.resumeEvents();

				me.fireEvent("datachanged", me);
			}
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

	/**
	 * Merges records into existing data set and
	 * fires the {@link #event-addsubitem} when complete.
	 * @param {Number} subItemIndex The sub-item index of the data to add
	 * @param {Object[]} newRecords An array of data records to add
	 */
	addSubItem: function(subItemIndex, newRecords){
		var me = this;

		me.rawData[subItemIndex] = newRecords;

		Ext.Array.each(newRecords, function addNewRecord(obj){
			var newKey   = me.getKey(obj);
			var existing = me.records.getByKey(newKey);

			if(existing){
				Ext.apply(existing, obj);
			} else{
				me.records.add(newKey, obj);
			}
		});

		me.fireEvent("datachanged", me);
	},

	/**
	 * Returns the record object associated with the passed `x` value, or null
	 * if no record was found.
	 * @param {String} x The value to search for.
	 * @return {Object} The record object associated with the passed value.
	 */
	getByKey: function(x){
		return this.records.getByKey(x) || null;
	},

	/**
	 * Returns the array of records for a given sub-item index, or null if no
	 * data was found.
	 * @param {Number} subItemIndex The sub-item index to find (1-based).
	 * @return {Object[]} The array of record objects.
	 */
	getRawData: function(subItemIndex){
		return this.rawData[subItemIndex] || null;
	},

	/**
	 * Returns an array containing the unique `x` values of all stored records
	 * (excluding records without `x` values).
	 * @return {String[]} The array of `x` values.
	 */
	getCategories: function(){
		return Ext.Array.clean(Ext.Array.pluck(this.records.items, "x"));
	},

	/**
	 * Converts the internal records into a Highcharts series data array.
	 *
	 * @param {Object} dataIndex An object of key-value mappings from the source
	 * records to the output data.
	 *
	 * Example:
	 *
	 *     getSeriesData({
	 *         y: "so_count"
	 *     });
	 *
	 * Each record in the returned data array will have a property "y" with the
	 * value of record["so_count"].
	 *
	 * @return {Object[]} A new array of records for a Highcharts series
	 */
	getSeriesData: function(dataIndex){
		var me     = this;
		var output = [];

		Ext.Array.each(me.records.items, function(record){
			if(!record.hasOwnProperty("x")){
				return;
			}

			var newRecord = Ext.apply({}, record);

			Ext.Object.each(dataIndex, function(outputKey, recordKey){
				var recordValue = record[recordKey];
				newRecord[outputKey] = (typeof recordValue !== "undefined") ? recordValue : null;
			});
			
			newRecord.name = newRecord.x;
			delete newRecord.x;

			output.push(newRecord);
		});

		return output;
	},

	/**
	 * Clears all data.
	 */
	clear: function(){
		var me = this;
		me.rawData = {};
		me.records.clear();

		me.fireEvent("clear", me);
	},

	/**
	 * Makes a single, non-repeating Ajax request to retrieve data for the passed
	 * sub-items.
	 * @param {Number[]} deferred The array of sub-item indexes
	 */
	initDeferred: function(deferred){
		if(deferred.length){
			this.refresh(0, deferred);
		}
	},

	/**
	 * Configures and defers real-time sub-items.
	 * @param {Object[]} realTime The array of real-time items
	 */
	initRealTime: function(realTime){
		var me    = this;
		var boxes = {};

		Ext.Object.each(realTime, function(subItemIndex, refreshRate){
			if(!boxes[refreshRate]){
				boxes[refreshRate] = [];
			}
			boxes[refreshRate].push(subItemIndex);
		});

		me.realTimeBoxes = boxes;
		Ext.Object.each(boxes, me.deferRefresh, me);
	},

	deferRefresh: function(refreshRate, subItemArray){
		var me = this;

		if(refreshRate > 0 && !me.isDestroying()){
			me.isRealTime = true;
			
			me.timeouts[refreshRate] = Ext.defer(
				me.refresh,
				refreshRate * 1000,
				me,
				[refreshRate, subItemArray]
			);
		}
	},

	refresh: function(refreshRate, subItemArray){
		var me = this;
		var currentRequest = me.requests[refreshRate];
		
		delete me.timeouts[refreshRate];

		if(me.isDestroying()){
			return;
		}

		if(currentRequest){
			currentRequest.abort();
		}

		me.requests[refreshRate] = Sms.Ajax.request({
			url:     "mrd_get_data.jsp",
			type:    "POST",
			timeout: 999999,
			disableTimeoutRetry: true,
			stopErrorReporting:  true,
			data:    {
				context:            "HCCHART",
				report_number:      MrRunContainer.reportNumber,
				instance_number:    MrRunContainer.instanceNumber,
				item_index:         me.itemIndex,
				prompt_values_set:  MrRunContainer.promptValuesSet,
				is_drill_down:      MrRunContainer.isDrillDown,
				is_debug_mode:      MrRunContainer.isDebugMode,
				is_real_time:       (refreshRate > 0),
				sub_items:          subItemArray.join(","),
				drill_down_prompts: me.getRequestPrompts()
			},
			success: function(data){
				if(me.isDestroying()) return;
				me.addRawData(data);
			},
			error: function(jqXhr){
				if(me.isDestroying()) return;
				Sms.log("HighchartsData Ajax error: " + jqXhr.statusText);
			},
			complete: function(){
				if(me.isDestroying()) return;
				delete me.requests[refreshRate];
				me.deferRefresh(refreshRate, subItemArray);
			}
		});
	},

	getRequestPrompts: function(){
		var extras = this.extraPrompts || "";
		var output = MrRunContainer.drillDownPrompts || "";

		if(extras){
			if(output){
				output += "|";
			}
			output += extras;
		}

		return output;
	},

	/**
	 * Aborts all active Ajax requests and cancels all refresh timeouts.
	 */
	stopAllRequests: function(){
		var me = this;

		Ext.Object.each(me.timeouts, function(refreshRate, timeoutId){
			clearTimeout(timeoutId);
		});

		Ext.Object.each(me.requests, function(refreshRate, requestObj){
			requestObj.abort();
		});

		me.requests = {};
		me.timeouts = {};
	},

	pause: function(){
		var me = this;
		me.paused = true;
		me.stopAllRequests();
	},

	resume: function(){
		var me = this;
		me.paused = false;
		Ext.Object.each(me.realTimeBoxes, me.refresh, me);
	},

	/**
	 * Returns the pause state of the object.
	 * @return {Boolean} `true` if real-time refreshes are paused
	 */
	isPaused: function(){
		return this.paused;
	},

	/**
	 * Destroys the object by removing all records and clearing event listeners.
	 */
	destroy: function(){
		var me = this;

		if(!me.isDestroying()){
			if(me.fireEvent("beforedestroy", me) !== false){
				me.destroying = true;

				me.stopAllRequests();

				me.records.clear();
				me.records.getKey = Ext.emptyFn;
				me.records = null;

				me.fireEvent("destroy", me);

				me.clearListeners();

				me.destroying  = false;
				me.isDestroyed = true;
			}
		}
	},

	/**
	 * Returns `true` if the object is currently destroying or has already been
	 * destroyed.
	 * @return {Boolean} `true` if the object is destroying.
	 */
	isDestroying: function(){
		var me = this;
		return (me.destroying || me.isDestroyed);
	},

	/**
	 * Used by records collection to get record key.
	 * @param {Object} obj A raw data object
	 * @return {String} The primary key of `obj`
	 * @private
	 */
	getKey: function(obj){
		return obj.x || null;
	}
});
