/**
 * @author  Eric Cook (el4hcnn)
 * @class   Sms.data.MultiStore
 * @extends Ext.data.Store
 *
 * MultiStore is a custom Store subclass that encapsulates logic for loading
 * data from multiple sources to be used by Ext JS objects that only support
 * one store (like charts).
 *
 * There are two ways the MultiStore can load data. It can either perform a bulk
 * update using all registered proxies, or it can allow each proxy to update on
 * its own interval.
 */
Ext.define("Sms.data.MultiStore", {
	extend: "Ext.data.Store",
	alias:  "store.multistore",

	// The number of stores that are in the process of loading. Counts down to 0.
	loadCount: 0,
	
	constructor: function(config){
		var me = this;
		
		me.addEvents(
			/**
			 * @event storeadded
			 * Fires when a store is added.
			 * @param {Sms.data.MultiStore} this
			 * @param {Ext.data.Store} store The store that was added
			 */
			"storeadded",
			
			/**
			 * @event storeremoved
			 * Fires when a store is removed.
			 * @param {Sms.data.MultiStore} this
			 * @param {Ext.data.Store} store The store that was removed
			 */
			"storeremoved",
			
			/**
			 * @event loadcomplete
			 * Fires when all stores have been loaded.
			 * @param {Sms.data.MultiStore} multistore This object
			 */
			"loadcomplete"
		);

		// The list of stores to load from
		me.storeList = [];

		// Maps primary keys to records for fast lookup
		me.pkMap = {};

		// Private field is a copy of load options for using callbacks later
		me.tempSaveLoadOptions = null;
		
		me.callParent(arguments);

		me.primaryKeys = Ext.Array.from(me.primaryKeys);
	},
	
	getPrimaryKey: function(record){
		return Ext.Array.map(this.primaryKeys, function(key){
			return record.get(key);
		}).join(",");
	},

	// Populates pkMap on add, makes sure primary keys are unique
	add: function(records){
		if(!Ext.isArray(records)){
			records = Ext.Array.slice(arguments);
		} else {
			records = records.slice(0);
		}

		var me = this,
			length = records.length,
			isSorted = me.sorters && me.sorters.items.length,
			pk, i, record;

		if(isSorted && length === 1){
			record = me.createModel(records[0]);
			pk = me.getPrimaryKey(record);

			if(me.pkMap[pk]){
				me.remove([me.pkMap[pk]]);
			}
			me.addSorted(record);
			me.pkMap[pk] = record;
			
			return [record];
		}

		for(i = 0; i < length; i++){
			record = me.createModel(records[i]);
			pk = me.getPrimaryKey(record);

			if(me.pkMap[pk]){
				me.remove([me.pkMap[pk]]);
			}
			me.pkMap[pk] = record;
			records[i] = record;
		}

		if(isSorted){
			me.requireSort = true;
		}

		me.insert(me.data.length, records);
		delete me.requireSort;

		return records;
	},

	remove: function(records){
		var me = this;
		if(!Ext.isArray(records)){
			records = [records];
		}
		Ext.each(records, function(rec){
			me.pkMap[me.getPrimaryKey(rec)] = null;
		});
		me.callParent(arguments);
	},

	clearData: function(){
		this.pkMap = {};
		return this.callParent(arguments);
	},
	
	/**
	 * Triggers the loading of the backend stores.
	 * @param {Object} options (optional) Optional parameters.
	 */
	load: function(options){
		var me = this;
		
		options = options || {};
		
		// Don't try to load if already loading
		if(!me.loading){
			Ext.each(me.storeList, function(store){
				store.load();
			});
		}

		if(!me.loading){
			me.tempSaveLoadOptions = null;
			if(Ext.isFunction(options.callback)){
				Ext.defer(options.callback, 1, options.scope);
			}
		}
		else{
			// Save off load options until loading is complete
			me.tempSaveLoadOptions = Ext.Object.merge({}, options);
		}

		return me;
	},

	/**
	 * @private
	 * Called internally before a store begins loading.
	 */
	onBeforeStoreLoad: function(store) {
		var me = store.multiStore;
		me.loading = true;
		me.loadCount++;

		return true;
	},
	
	/**
	 * @private
	 * Called internally when a Store has completed a load request.
	 */
	onStoreLoad: function(store) {
		var me = store.multiStore;
		me.loadCount--;

		if(me.loadCount <= 0){
			me.loadStoreData();
		}
	},
	
	/**
	 * @private
	 * Called internally when all stores have finished loading.
	 */
	loadStoreData: function() {
		var me = this;

		me.suspendEvents();
		me.removeAll();

		Ext.each(me.storeList, function(store){
			var records = store.getRange();
			if(!me.getCount()){
				me.add(records);
			}
			else{
				me.mergeRecordsFromStore(store);
			}
		});

		me.resumeEvents();
		me.fireEvent("datachanged", me);

		// Trigger callback function initially given to load method
		if(me.tempSaveLoadOptions !== null && Ext.isFunction(me.tempSaveLoadOptions.callback)){
			me.tempSaveLoadOptions.callback.call(me.tempSaveLoadOptions.scope);
		}
		me.tempSaveLoadOptions = null;

		me.loading = false;
	},
	
	/**
	 * Adds a Store to the storeList
	 * @param {Object} options (optional) Additional options to specify
	 */
	addStore: function(store){
		var me = this;

		store.multiStore = me;
		store.on({
			beforeload: me.onBeforeStoreLoad,
			load:       me.onStoreLoad
		});

		me.storeList.push(store);
		me.fireEvent("storeadded", me, store);
	},
	
	/**
	 * Removes a Store from the storeList
	 * @param {Ext.data.Store} store The store to remove
	 */
	removeStore: function(store){
		var me = this,
			len = me.storeList.length,
			i;
		
		for(i = 0; i < len; i++){
			if(me.storeList[i] === store){
				store.multiStore = null;
				store.un("beforeload", me.onBeforeStoreLoad);
				store.un("load", me.onStoreLoad);

				me.storeList.splice(i, 1);
			}
		}
		
		me.fireEvent("storeremoved", me, store);
	},

	/**
	 * Allows records from another store to be merged with the records in a
	 * multistore instead of simply adding those records.
	 */
	mergeRecordsFromStore: function(store){
		if(!store.getCount()){
			return;
		}

		var me = this,
			pKeys = Ext.Array.toMap(me.primaryKeys),  // Faster lookup than indexOf
			toAdd = [],
			fields = [];

		// Generate the array of field names to merge. Excludes primary key fields.
		 Ext.each(store.model.getFields(), function(field){
			if(!pKeys[field.name]){
				fields.push(field.name);
			}
		});

		Ext.each(store.getRange(), function(rec){
			var pk = me.getPrimaryKey(rec),
				existingRecord = me.pkMap[pk];

			if(existingRecord){
				existingRecord.beginEdit();
				Ext.each(fields, function(name){
					existingRecord.set(name, rec.get(name));
				});
				existingRecord.endEdit();
			}
			else{
				toAdd.push(rec);
			}
		});

		if(toAdd.length){
			me.add(toAdd);
		}
	},

	/**
	 * Intended to be a private function, but can be used publicly as long as
	 * keys and fields are both non-empty arrays of strings.
	 */
	performStoreMerge: function(store, keys, fields){
		var me = this,
			mRec, i, fLen, field;

		store.each(function(storeRec){
			var idx = me.findBy(function(multiRec){
				var isMatch = true,
					j, len, key;
				for(j = 0, len = keys.length; j < len; j++){
					key = keys[j];
					isMatch = isMatch && (storeRec.data[key] === multiRec.data[key]);
					if(!isMatch){
						return false;
					}
				}
				return isMatch;
			});

			if(idx === -1){
				return;
			}

			mRec = me.getAt(idx);
			for(i = 0, fLen = fields.length; i < fLen; i++){
				field = fields[i];
				mRec.set(field, storeRec.data[field]);
			}
		});
	}
});