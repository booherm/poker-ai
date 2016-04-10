// Use the same set of dateFormats for both sorting and filtering
// If you find a format that doesn't sort, add it here.
Sms.gridDateFormats = [
	"m/d/Y", "m/Y", "m/d/Y h:i:s", "m/d/Y h:i:s A",
	"Y-m-d", "Y", "m/d/Y h:i A", "m/d/Y h:i",
	"m/d/Y h:i A T", "m/d/Y h:i:s A T"
];

// Custom sorting function to make sure that grid total row (row_type = 'T') is
// always at the bottom of the grid, regardless of sort order or type.
Ext.override(Ext.util.Sorter, {
	createSortFunction: function(sorterFn) {
        var me        = this,
            direction = me.direction || "ASC",
            modifier  = direction.toUpperCase() === "DESC" ? -1 : 1;

		return function(o1, o2) {
			var rowType1 = o1.data["row_type"],
				rowType2 = o2.data["row_type"];

			if(rowType1 !== "T" && rowType2 !== "T"){
				return modifier * sorterFn.call(me, o1, o2);
			}
			if(rowType1 === "T" && rowType2 !== "T"){
				return 1;
			}
			if(rowType1 !== "T" && rowType2 === "T"){
				return -1;
			}
			return 0;
		};
    }
});

// Because there are many different date formats used by reports, and because
// there's no feature in the report editor to specify a format, we have to check
// many possible formats.
Ext.apply(Ext.data.SortTypes, {
	// Remember the last date format that worked, and try it first.
	lastDateFormat: null,

	// Add new date formats here as necessary. Keep in order of most to least likely.
	dateFormats: Sms.gridDateFormats,

	asDate: function(s){
		if(!s){
			return 0;
		}

		var st = Ext.data.SortTypes,
			dateObj = null,
			len = st.dateFormats.length,
			fmt, i;

		s = String(s).replace(st.stripTagsRE, "");

		// Attempt to guess the date format
		// Store the last successful format and use that first
		if(st.lastDateFormat){
			dateObj = Ext.Date.parse(s, st.lastDateFormat);
		}

		// Using the last known date format didn't work, so check each format.
		if(!dateObj){
			st.lastDateFormat = null;
			for(i = 0; i < len; i++){
				fmt = st.dateFormats[i];
				dateObj = Ext.Date.parse(s, fmt);
				if(dateObj){
					st.lastDateFormat = fmt;
					break;
				}
			}
		}

		return dateObj ? dateObj.getTime() : 0;
	},

	// Numeric columns (like service order ID or survey record number) don't get
	// sorted properly if they have tags.
	numericRE: /[^\-\d\.]/g,

	asFloat: (function(){
		var st = Ext.data.SortTypes,
			raw, val;
		return function(s){
			raw = String(s).replace(st.stripTagsRE, "");
			val = parseFloat(raw.replace(st.numericRE, ""));
			return isNaN(val) ? 0 : val;
		};
	}())
});

Ext.override(Ext.ux.grid.filter.DateFilter, {
	dateFormats: Sms.gridDateFormats
});

Ext.override(Ext.ux.tree.filter.DateFilter, {
	dateFormats: Sms.gridDateFormats
});

Ext.override(Ext.data.TreeStore, {
	load: function(options) {
		options = options || {};
        options.params = options.params || {};
		var me = this,
			node = options.node || (me.tree && me.tree.getRootNode());
		if(!me.tree){
			return false;
		}
        if(!node){
			node = me.setRootNode({expanded: true}, true);
        }
		if(me.clearOnLoad && me.clearRemovedOnLoad){
			me.clearRemoved(node);
		}
		me.loading = true;
		// Removed "node.removeAll" function call, moved it
		// to right before loading new records
		Ext.applyIf(options, {node: node});
		options.params[me.nodeParam] = node ? node.getId() : "root";
		if(node){
			node.set("loading", true);
		}
		return me.superclass.load.call(me, options);  // Can't use callParent, need to bypass TreeStore
    },
	onProxyLoad: function(operation){
		var me         = this,
			tree       = me.tree,
            successful = operation.wasSuccessful(),
            records    = operation.getRecords(),
            node       = operation.node;
        me.loading = false;
        node.set("loading", false);
        if(successful && tree){

			/* CUSTOM EVENT, needed to intercept node expand states */
			me.fireEvent("smsbeforenodefill", me, node);

			// Here's where we can remove nodes after loading
			Ext.suspendLayouts();
			if(me.clearOnLoad){
				tree.un("remove", me.onNodeRemove, me);
				node.removeAll(false);
				tree.on("remove", me.onNodeRemove, me);
			}
			else{
				records = me.cleanRecords(node, records);
			}
            records = me.fillNode(node, records);
			Ext.resumeLayouts();
        }
		me.fireEvent("load", me, operation.node, records, successful);
        Ext.callback(operation.callback, operation.scope || me, [records, operation, successful]);
	},
	getCount: function(){
		var me = this,
			root = me.getRootNode(),
			count = 0;
		if(root){
			++count;
			root.cascadeBy(function(){
				++count;
			});
		}
		return count;
	},
	getRootChildrenCount: function(){
		var me = this,
			root = me.getRootNode();
		return root ? root.childNodes.length : 0;
	}
});

// Collects unique values together instead of keeping individual records
// Only loads the menu once, since filtering is disabled for real-time items.
// Drill-down items
Ext.override(Ext.ux.grid.menu.ListMenu, {
	beforeLoad: function(store){
		var me = this,
			records;
		if(!me.loaded || me.items.length <= 1){
			records = me.getStoreRecords(store);
			if(records.length > 0){
				me.onLoad(store, records);
			}
		}
	},

	onLoad: function(store, records){
		var me         = this,
			sortedVals = Ext.Array.sort(me.getUniqueValues(records, me.valueField)),
			uniqueVals = ["(Blanks)"].concat(sortedVals),
			st         = Ext.data.SortTypes,
			gid        = me.single ? Ext.id() : null,
			selected   = Ext.Array.toMap(me.selected),
			listeners = {
				checkchange: me.checkChange,
				scope:       me
			};

		Ext.suspendLayouts();
		me.removeAll(true);
		
		Ext.Array.each(uniqueVals, function(value){
			var itemValue = st.asText(value);  // Strips tags
			me.add(new Ext.menu.CheckItem({
				text:        itemValue,
				group:       gid,
				checked:     !!selected[itemValue],
				hideOnClick: false,
				value:       itemValue,
				listeners:   listeners
			}));
		});

		me.loaded = true;
		Ext.resumeLayouts(true);
		me.fireEvent("load", me, records);
	},

	getUniqueValues: function(records, valueField){
		var values = [], v;
		Ext.each(records, function(rec){
			v = rec.get(valueField);
			if(v){
				values.push(v);
			}
		});
		return Ext.Array.unique(values);
	}
});

Ext.override(Ext.ux.tree.menu.ListMenu, {
	beforeLoad: function(store){
		var me = this,
			records;
		if(!me.loaded || me.items.length <= 1){
			records = me.getStoreRecords(store);
			if(records.length > 0){
				me.onLoad(store, records);
			}
		}
	}
});

Ext.override(Ext.grid.ColumnLayout, {
	completeLayout: function(ownerContext){
		var me = this,
			owner = me.owner,
			state = ownerContext.state,
			needsInvalidate = false,
			calculated = me.sizeModels.calculated,
			configured = me.sizeModels.configured,
			totalFlex = 0, totalWidth = 0, remainingWidth = 0, colWidth = 0,
			childItems, len, i, childContext, item,
			j, sublen, subChild;

		me.callParent(arguments);

		// Get the layout context of the main container
		// Required two passes. First pass calculates total flexes of all items
		// and child items. Second pass uses those flex values to calculate fixed
		// widths for each item, then removes flexing so resizing/hiding works.
		if(!state.flexesCalculated && owner.forceFit && !owner.isHeader){
			childItems = ownerContext.flexedItems = ownerContext.childItems;
			len = childItems.length;
			totalWidth = state.contentWidth;
			if(state.contentWidth < state.boxPlan.availableSpace){
				totalWidth += state.boxPlan.availableSpace - 2;
			}
			remainingWidth = totalWidth;

			// Begin first pass
			ownerContext.flex = 0;
			for(i = 0; i < len; i++){
				childContext = childItems[i];
				item = childContext.target;

				if(item.isRowExpander){
					item.width = item.flex || item.width;
					totalWidth -= item.width;
					remainingWidth -= item.width;
					item.forceFit = false;
					delete item.flex;
					continue;
				}

				if(item.isGroupHeader){
					totalFlex = 0;
					for(j = 0, sublen = childContext.childItems.length; j < sublen; j++){
						subChild = childContext.childItems[j];
						subChild.widthModel = calculated;
						totalFlex += subChild.flex;
					}
					item.flex = childContext.flex = childContext.totalFlex = totalFlex;
					ownerContext.flex += totalFlex;
					needsInvalidate = true;
				}
				else{
					ownerContext.flex += item.flex;
				}
			}

			ownerContext.totalFlex = ownerContext.flex;

			// Begin second pass
			for(i = 0; i < len; i++){
				childContext = childItems[i];
				item = childContext.target;

				if(item.isRowExpander){
					continue;
				}

				item.width = colWidth = Math.min(Math.ceil((totalWidth / ownerContext.totalFlex) * childContext.flex), remainingWidth);
				remainingWidth -= colWidth;
				childContext.sizeModel.width = childContext.widthModel = configured;

				if(item.isGroupHeader){
					for(j = 0, sublen = childContext.childItems.length; j < sublen; j++){
						subChild = childContext.childItems[j];
						subChild.target.width = Math.ceil((item.width / childContext.flex) * subChild.flex);
						subChild.sizeModel.width = subChild.widthModel = configured;
						delete subChild.flex;
						delete subChild.target.flex;
					}
					childContext.sizeModel.width = childContext.widthModel = calculated;
					delete item.width;
					delete item.flex;
				}
				
				item.forceFit = false;
			}

			delete owner.flex;
			owner.forceFit = false;

			if(needsInvalidate){
				ownerContext.invalidate({state: {flexesCalculated: true}});
			}
		}
	}
});

Ext.override(Ext.grid.header.Container, {
	prepareData: function(data, rowIdx, record, view, panel) {
        var obj = {},
            headers = this.gridDataColumns || this.getGridColumns(),
            headersLn = headers.length,
			store = panel.store,
            colIdx, header, headerId, renderer, value, metaData, rowColor;
        for(colIdx = 0; colIdx < headersLn; colIdx++){
            metaData = {tdCls: "", style: ""};
            header = headers[colIdx];
            headerId = header.id;
            renderer = header.renderer;
            value = data[header.dataIndex];
			rowColor = record.data["row_color"];

            // When specifying a renderer as a string, it always resolves
            // to Ext.util.Format
            if (typeof renderer === "string") {
                header.renderer = renderer = Ext.util.Format[renderer];
            }
            if (typeof renderer === "function") {
                value = renderer.call(
                    header.scope || this.ownerCt,
                    value, metaData, record,
                    rowIdx, colIdx, store, view);
            }
            if (metaData.css) {
                obj.cssWarning = true;
                metaData.tdCls = metaData.css;
                delete metaData.css;
            }
			if(rowColor){
				metaData.style += "background-color:" + rowColor + ";";
			}
			obj[headerId+'-modified'] = "";  // Cells will never be editable or dirty
            obj[headerId+'-tdCls'] = metaData.tdCls;
            obj[headerId+'-tdAttr'] = metaData.tdAttr;
            obj[headerId+'-style'] = metaData.style;
            if(Ext.isEmpty(value)) {
                value = '&#160;';
            }
            obj[headerId] = value;
        }
        return obj;
    },
	getVisibleHeaderClosestToIndex: function(index){
		var result = this.getHeaderAtIndex(index);
		if(result && result.hidden){
			result = result.next(":not([hidden])") || result.prev(":not([hidden])");
		}
		return result;
	},
	getHeaderIndex: function(header) {
        if(header.isGroupHeader){
            header = header.down(':not([isGroupHeader])');  // Fixed typo
        }
        return Ext.Array.indexOf(this.getGridColumns(), header);
    },

	// Custom function to return a leaf-level header by id
	getHeaderById: function(id){
		var me = this,
			cols = me.getGridColumns(),
			len = cols.length,
			col, i;
		for(i = 0; i < len; i++){
			col = cols[i];
			if(id === col.getId()){
				return col;
			}
		}
		return null;
	}
});

Ext.override(Ext.view.AbstractView, {
    onRender: function(){
		var me = this,
			mask = me.loadMask,
			cfg = {
				msg:    me.loadingText,
				msgCls: me.loadingCls,
				useMsg: me.loadingUseMsg,
				store:  me.store
			};
		me.callParent(arguments);
		if(!me.up("[collapsed],[hidden]")){
			// The render event isn't fired until Ext.util.Renderable#finishRender.
			// Wait until the render event before allowing a refresh (EXTJSIV-6554)
			me.on("render", function(){me.doFirstRefresh(me.store);}, me, {single: true});
		}
		if(mask){
			if(Ext.isObject(mask)){
				cfg = Ext.apply(cfg, mask);
			}
			me.loadMask = new Ext.LoadMask(me, cfg);
			me.loadMask.on({
				beforeshow: me.onMaskBeforeShow,
				hide:       me.onMaskHide,
				scope:      me
			});
		}
	},

	// LoadMasks are normally all-or-nothing; either you get them on every load
	// or you don't get them at all. This method should totally destroy a grid's
	// loading mask. Should be called after first real-time load is successful.
	destroyAndRemoveMask: function(){
		var me = this,
			mask = me.loadMask;

		if(mask && mask.destroy){
			mask.clearListeners();
			mask.bindStore(null);
			mask.destroy();
			me.loadMask = false;
		}
	}
});
