// Add the colored cell renderer to the standard format list
Ext.util.Format.color = function(value, metaData, record, rowIdx, colIdx, store, view){
	var column = view.headerCt.getHeaderAtIndex(colIdx);
	if(column && column.columnColor){
		metaData.style += "background-color:" + ((rowIdx % 2 === 0) ? column.columnColor : column.columnColorAlt) + ";";
	}
	return value;
};

Ext.define("Sms.mr.ExtjsTableToolbar", {
	extend: "Ext.AbstractPlugin",
	alias:  "plugin.extjstabletoolbar",

	init: function(grid){
		var me = this,
			toolbar = ["->"];
		me.grid = grid;

		if(me.isDebugMode){
			toolbar.push("-", {
				iconCls:   "silk-cog",
				tooltip:   "Debug",
				listeners: {click: me.onDebugClick, scope: me}
			});
		}

		toolbar.push("-", {
			xtype:  "smscopytoclipboardbutton",
			itemId: "copy_clip_btn"
		});

		if(me.isTree){
			toolbar.push({
				iconCls:   "silk-expand-all",
				tooltip:   "Expand All",
				itemId:    "expand_all_btn",
				listeners: {click: me.onExpandAllClick, scope: me}
			},{
				iconCls:   "silk-collapse-all",
				tooltip:   "Collapse All",
				itemId:    "collapse_all_btn",
				listeners: {click: me.onCollapseAllClick, scope: me}
			});
		}

		toolbar.push("-", {
			text:      "Reset Column Configuration",
			itemId:    "reset_col_btn",
			listeners: {click: me.onResetColumnClick, scope: me}
		});

		if(grid.hasFilters && !grid.isRealTime){
			toolbar.push("-", {
				text:      "Clear Filter Data",
				itemId:    "clear_filter_btn",
				listeners: {click: me.onClearFilterClick, scope: me}
			});
		}

		toolbar.push("-");

		grid.addDocked({
			xtype: "toolbar",
			dock:  "bottom",
			id:    grid.id + "_toolbar",
			items: toolbar,
			disableExtraButtons: me.disableExtraButtons  // grant function to toolbar
		});
	},

	destroy: function(){
		this.grid = null;
	},

	onDebugClick: function(){
		var grid = this.grid;
		MrRunContainer.openDebugInfo(
			MrRunContainer.reportNumber,
			MrRunContainer.instanceNumber,
			grid.itemIndex,
			false,
			null,
			MrRunContainer.isDrillDown,
			grid.isRealTime);
	},

	onExpandAllClick: function(){
		var grid = this.grid;
		grid.expandAll();
		if(grid.useAutoHeight){
			grid.resizeHeight();
		}
	},

	onCollapseAllClick: function(){
		var grid = this.grid;
		grid.collapseAll();
		if(grid.useAutoHeight){
			grid.resizeHeight();
		}
	},

	onResetColumnClick: function(){
		var grid = this.grid,
			headerCt = grid.headerCt,
			cols = headerCt.getGridColumns(true),
			state = grid.initialState,
			len = cols.length,
			ownerCt, col, colState, i;

		Ext.suspendLayouts();
		for(i = 0; i < len; i++){
			col = cols[i];
			col.show();  // Show everything first to make sure indexes are correct
		}
		
		delete headerCt.gridDataColumns;
		delete headerCt.hideableColumns;
		headerCt.forceFit = state.forceFit;

		// Column states are already ordered. Map this ordering to header.
		for(i = 0; i < len; i++){
			colState = state.columns[i];
			col = headerCt.getHeaderById(colState.id);  // The column that our state applies to

			if(colState.ownerIdx === null){
				// If the column is not part of a group, simply move it into position
				grid.moveColumn(headerCt, col, col.getIndex(), colState.localIdx);
			}
			else{
				// If the column is grouped, move the group into position first
				ownerCt = col.ownerCt;
				grid.moveColumn(headerCt, ownerCt, headerCt.items.indexOf(ownerCt), colState.ownerIdx);
				grid.moveColumn(ownerCt, col, ownerCt.items.indexOf(col), colState.localIdx);
			}

			// Sub-rows will always be at index 0 and fixed width
			if(col.isRowExpander){
				col.width = col.minWidth = col.maxWidth = colState.width;
				delete col.flex;
				continue;
			}

			// Now set the width
			if(headerCt.forceFit){
				// Convert widths to flexes, layout will convert back
				col.flex = colState.width;
				delete col.width;
			}
			else{
				// Maintain fixed width columns
				col.width = colState.width;
				delete col.flex;
			}
		}

		Ext.resumeLayouts();
		headerCt.doLayout();
		grid.view.refresh();
		headerCt.purgeCache();
		headerCt.forceFit = false;
	},

	onClearFilterClick: function(){
		var filters = this.grid.filters;
		if(filters){
			filters.clearFilters();
		}
	},

	disableExtraButtons: function(){
		var me = this,  // Refers to toolbar
			list = [
				"expand_all_btn",
				"collapse_all_btn",
				"reset_col_btn",
				"clear_filter_btn"
			],
			btn, i, len;
		for(i = 0, len = list.length; i < len; i++){
			btn = me.getComponent(list[i]);
			if(btn){
				btn.disable();
			}
		}
	}
});

// Consolidate any shared functionality between ExtjsTables and ExtjsTrees
Ext.override(Ext.panel.Table, {

	maskRemoveEvent: "viewready",  // Overridden by trees

	initBaseEl: function(){
		var me = this,
			id = "mri_" + me.itemIndex,
			parentEl = me.parentEl = Ext.get(id),
			dom, padTop, padBottom, padLeft, padRight;

		if(!parentEl){
			Ext.Error.raise("Error occurred in ExtjsTable.js: Could not find element \"" + id + "\"");
			return;
		}

		// Use the underlying DOM element to determine how the table is sized
		if(!me.useAutoHeight){
			dom = parentEl.dom;
			while(!dom.clientHeight){
				dom = dom.parentNode;
			}
			me.height = dom.clientHeight;

			// Make adjustments for element padding
			padTop = parseInt(dom.style.paddingTop, 10);
			padBottom = parseInt(dom.style.paddingBottom, 10);
			me.height = me.height - (isNaN(padTop) ? 0 : padTop) - (isNaN(padBottom) ? 0 : padBottom);
		}

		dom = parentEl.dom;
		if(/px$/.test(dom.style.width)){
			me.width = dom.clientWidth;
			padLeft = parseInt(dom.style.paddingLeft, 10);
			padRight = parseInt(dom.style.paddingRight, 10);
			me.width -= (isNaN(padLeft) ? 0 : padLeft) - (isNaN(padRight) ? 0 : padRight);
		}

		// Set the total row style function
		me.viewConfig.getRowClass = me.getTotalRowClass;
	},

	initEvents: function(){
		var me = this,
			reportPanel;
		
		me.on("afterlayout", me.showMaskAfterLayout, me, {single: true});
		me.headerCt.on("afterlayout", me.saveColumnConfig, me, {single: true});

		me.headerCt.on({
			columnhide: me.removeWordWrapOnHide,
			columnshow: me.addWordWrapOnShow,
			scope:      me
		});
		
		if(me.useAutoHeight){
			me.view.on({
				expandbody:   me.resizeHeight,
				collapsebody: me.resizeHeight,
				scope:        me
			});
		}

		reportPanel = MrRunContainer.reportPanel;
		if(reportPanel){
			me.mon(reportPanel, "resize", me.onReportPanelResize, me);
		}
	},

	guaranteeBottomBar: function(){
		var me = this,
			p = me.plugins || [];

		if(!Ext.Array.contains(Ext.Array.pluck(p, "ptype"), "extjstabletoolbar")){
			me.plugins = me.plugins || [];
			me.plugins.push({
				ptype:       "extjstabletoolbar",
				isDebugMode: MrRunContainer.isDebugMode,
				isTree:      false
			});
		}
	},

	showMaskAfterLayout: function(){
		var me = this,
			view = me.view;
	
		me.body.mask("Loading...");
		view.on(me.maskRemoveEvent, me.hideMaskOnViewReady, me, {single: true});
	},

	hideMaskOnViewReady: function(){
		this.body.unmask();
	},

	moveColumn: function(header, column, fromIdx, toIdx){
		if(fromIdx === toIdx){
			return;
		}
		header.items.insert(toIdx, column);
	},

	getTotalRowClass: function(record){
		if(record && record.data["row_type"] === "T"){
			return "mrc-grid-cell-total";
		}
		return "";
	},

	onReportPanelResize: function(){
		var me = this,
			el = me.parentEl;
		if(me.width !== el.getWidth()){
			me.setWidth(el.getWidth());
		}
	},

	saveColumnConfig: function(headerCt){
		var me = this,
			cols = headerCt.getGridColumns(true),
			len = cols.length,
			colState = [],
			col, i;

		// Manually save the necessary values
		// localIdx is position of column relative to owner (header or grouped column)
		// ownerIdx is position of owner relative to header, or null if column is not sub-header
		for(i = 0; i < len; i++){
			col = cols[i];
			colState[i] = {
				id:       col.getId(),
				width:    col.getWidth(),
				localIdx: col.ownerCt.items.indexOf(col),
				ownerIdx: col.isSubHeader ? headerCt.items.indexOf(col.ownerCt) : null
			};
		}

		me.initialState = {
			forceFit: me.forceFit,  // True if created with flex values, false if fixed width
			columns:  colState,
			width:    headerCt.getFullWidth()
		};
		headerCt.forceFit = false;
	},

	removeWordWrapOnHide: function(headerCt, column){
		var me = this,
			wordWrapRe = /wordwrap/i;
		if(column.useWordWrap || wordWrapRe.test(column.tdCls)){
			column.tdCls = column.tdCls.replace("mrc-grid-cell-wordwrap", "");
			column.useWordWrap = true;
			me.view.refresh();
		}
	},

	addWordWrapOnShow: function(headerCt, column){
		var me = this,
			wordWrapRe = /wordwrap/i;
		if(column.useWordWrap && !wordWrapRe.test(column.tdCls)){
			column.tdCls = "mrc-grid-cell-wordwrap " + column.tdCls;
			me.view.refresh();
		}
	},

	resizeHeight: function(){
		// Need to defer in order for the collapse/expand to finish
		Ext.defer(this.doResizeHeight, 1, this);
	},

	doResizeHeight: function(){
		var me = this;
		me.body.setHeight(me.view.el.getHeight() + 2);
		me.doComponentLayout();
	},

	onDestroy: function(){
		Ext.destroy(this.parentEl);
		this.parentEl = null;

		if(this.store.proxy.stop){
			this.store.proxy.stop();
		}
		this.store.destroyStore();

		this.callParent();
	},
	
	googlePepperFix: function(){
		if(Ext.isChrome)
		{
			var me = this;
			Ext.Array.each(me.dockedItems.items, function(dockedItem){
				dockedItem.setHeight(dockedItem.getHeight() + 1);
				dockedItem.setHeight(dockedItem.getHeight() - 1);
			});
		}
	}
});

Ext.define("Sms.mr.ExtjsTable", {
	extend: "Ext.grid.Panel",

	initComponent: function(){
		var me = this,
			store;

		me.initBaseEl();
		me.callParent(arguments);
		me.initEvents();

		// Configure event handlers to save selection state before each load
		if(me.isRealTime || me.isDrillDown){
			store = me.store;
			store.on("beforeload", me.onBeforeStoreLoad, me);
			store.load();
		}
	},

	onBeforeStoreLoad: function(){
		var me = this,
			records = me.getSelectionModel().getSelection(),
			i, len;

		me.selectionState = [];
		for(i = 0, len = records.length; i < len; i++){
			if(typeof records[i].index !== "undefined"){
				me.selectionState.push(records[i].index);
			}
		}
	},

	onStoreLoad: function(){
		var me = this,
			view = me.view,
			store, selModel, records, rec, i, len;
		me.callParent(arguments);

		// Turn off load masking after the initial load
		view.destroyAndRemoveMask();
		me.googlePepperFix();
		
		if(!me.selectionState || me.selectionState.length === 0){
			return;
		}
		
		store = me.store;
		selModel = me.getSelectionModel();
		records = [];
		for(i = 0, len = me.selectionState.length; i < len; i++){
			rec = store.getAt(me.selectionState[i]);
			if(rec){
				records.push(rec);
			}
		}
		if(records.length > 0){
			selModel.select(records);
		}
		me.selectionState = [];
	}
});

Ext.define("Sms.mr.ExtjsTree", {
	extend: "Ext.tree.Panel",

	maskRemoveEvent: "refresh",  // viewready doesn't work on trees
	folderSort:      true,
	rowLines:        true,

	initComponent: function(){
		var me = this;

		me.initBaseEl();
		me.callParent(arguments);
		me.initEvents();

		me.on({
			itemcollapse: me.updateHeight,
			itemexpand:   me.updateHeight
		});

		if(me.isRealTime){
			me.mon(me.store, {
				smsbeforenodefill: me.saveExpandSelectState,
				load:              me.onTreeStoreLoad,
				scope:             me
			});
		}
		else if(me.expandOnInit){
			if(me.isDrillDown){
				me.mon(me.store, {
					smsbeforenodefill: {fn: "saveExpandSelectState", scope: me, single: true},
					load:              {fn: "onTreeStoreLoad",       scope: me, single: true}
				});
			}
			else{
				me.on("afterlayout", me.expandAfterRender, me, {single: true});
			}
		}
		
		if(me.useAutoHeight)
			me.on("afterlayout", me.autoHeightInitialFix, me, {single: true});
	},

	saveExpandSelectState: function(store, node){
		var me       = this,
			selected = new Ext.util.MixedCollection(),
			expanded = new Ext.util.MixedCollection(),
			root     = store.getRootNode(),
			idProp   = node.idProperty;

		// Root node must have node_id set, otherwise path will be invalid.
		if(!root.data[idProp]){
			root.set(idProp, "ROOT");
		}

		// Expanding a child node implies that all of its ancestors are expaned.
		// Only the leaf-most expanded nodes need to be added.
		node.cascadeBy(function(n){
			if(n.isExpanded() && !n.isRoot()){
				expanded.removeAtKey(n.parentNode.getId());
				expanded.add(n.getId(), n.getPath());
			}
		});
		me.expandedNodes = expanded;

		Ext.Array.each(me.getSelectionModel().getSelection(), function(n){
			selected.add(n.internalId, n.getPath("index"));
		});
		me.selectedNodes = selected;

		// Prepare for bulk remove
		me.getView().beginBulkUpdate();
	},

	onTreeStoreLoad: function(){
		var me       = this,
			view     = me.getView(),
			selModel = me.getSelectionModel(),
			expanded = me.expandedNodes,
			selected = me.selectedNodes;

		if(me.destroying || view.isDestroyed){
			return;
		}

		view.endBulkUpdate();

		if(me.rendered){
			if(me.expandOnInit){
				delete me.expandOnInit;
				me.expandAll();
			}
			else if(expanded){
				expanded.each(function(path){
					me.expandPath(path);
				});
				me.expandedNodes = expanded = null;
			}
			
			if(selected){
				selected.each(function(path){
					var keys = Ext.Array.slice(path.split("/"), 2),  // Ignore leading "" and root node
						node = me.store.getRootNode();

					Ext.Array.each(keys, function(index){
						node = node.getChildAt(index);
						return !!node;  // Stop iteration if node was not found
					});

					if(node){
						selModel.select(node);
					}
				});
				me.selectedNodes = selected = null;
			}
		}
		else if(me.expandOnInit){
			delete me.expandOnInit;
			me.on("afterrender", me.expandAfterRender, me, {single: true});
		}

		// Ext.tree.View has its own removed node cache that never clears.
		view.store.removed.length = 0;
		
		me.googlePepperFix();

		// By default, the view will display a load mask every time the tree
		// loads. Remove it after the first load finishes.
		view.destroyAndRemoveMask();
	},

	updateHeight: function(){
		var me = this;
		if(me.useAutoHeight && !me.view.bulkUpdate){
			me.resizeHeight();
		}
		me.googlePepperFix();
	},

	expandAfterRender: function(){
		this.expandAll();
	},
	
	autoHeightInitialFix: function(){
		var me = this;
		setTimeout(function(){
			me.setHeight(null);
		}, 1000);
	}
});
