/**
 * @class Ext.ux.RowExpander
 * @extends Ext.AbstractPlugin
 * Plugin (ptype = 'rowexpander') that adds the ability to have a Column in a grid which enables
 * a second row body which expands/contracts.  The expand/contract behavior is configurable to react
 * on clicking of the column, double click of the row, and/or hitting enter while a row is selected.
 *
 * @ptype rowexpander
 *
 * From Ext JS 4.1.0 ([original documentation][1])
 *   [1]: http://docs.sencha.com/extjs/4.1.0/#!/api/Ext.ux.RowExpander
 */
Ext.define('Ext.ux.RowExpander', {
    extend: 'Ext.AbstractPlugin',

    requires: [
        'Ext.grid.feature.RowBody',
        'Ext.grid.feature.RowWrap'
    ],

    alias: 'plugin.rowexpander',

    rowBodyTpl: null,

    /**
     * @cfg {Boolean} expandOnEnter
     * <tt>true</tt> to toggle selected row(s) between expanded/collapsed when the enter
     * key is pressed (defaults to <tt>true</tt>).
     */
    expandOnEnter: true,

    /**
     * @cfg {Boolean} expandOnDblClick
     * <tt>true</tt> to toggle a row between expanded/collapsed when double clicked
     * (defaults to <tt>true</tt>).
     */
    expandOnDblClick: true,

    /**
     * @cfg {Boolean} selectRowOnExpand
     * <tt>true</tt> to select a row when clicking on the expander icon
     * (defaults to <tt>false</tt>).
     */
    selectRowOnExpand: false,

    rowBodyTrSelector: '.x-grid-rowbody-tr',
    rowBodyHiddenCls: 'x-grid-row-body-hidden',
    rowCollapsedCls: 'x-grid-row-collapsed',



    renderer: function(value, metadata, record, rowIdx, colIdx) {
        if (colIdx === 0) {
            metadata.tdCls = 'x-grid-td-expander';
        }
        return '<div class="x-grid-row-expander">&#160;</div>';
    },

    /**
     * @event expandbody
     * <b<Fired through the grid's View</b>
     * @param {HTMLElement} rowNode The &lt;tr> element which owns the expanded row.
     * @param {Ext.data.Model} record The record providing the data.
     * @param {HTMLElement} expandRow The &lt;tr> element containing the expanded data.
     */
    /**
     * @event collapsebody
     * <b<Fired through the grid's View.</b>
     * @param {HTMLElement} rowNode The &lt;tr> element which owns the expanded row.
     * @param {Ext.data.Model} record The record providing the data.
     * @param {HTMLElement} expandRow The &lt;tr> element containing the expanded data.
     */

    constructor: function() {
        this.callParent(arguments);
        var grid = this.getCmp();
        this.recordsExpanded = {};
        // <debug>
        if (!this.rowBodyTpl) {
            Ext.Error.raise("The 'rowBodyTpl' config is required and is not defined.");
        }
        // </debug>
        // TODO: if XTemplate/Template receives a template as an arg, should
        // just return it back!
        var rowBodyTpl = Ext.create('Ext.XTemplate', this.rowBodyTpl),
            features = [{
                ftype: 'rowbody',
                columnId: this.getHeaderId(),
                recordsExpanded: this.recordsExpanded,
                rowBodyHiddenCls: this.rowBodyHiddenCls,
                rowCollapsedCls: this.rowCollapsedCls,
                getAdditionalData: this.getRowBodyFeatureData,
                getRowBodyContents: function(data) {
                    return rowBodyTpl.applyTemplate(data);
                }
            },{
                ftype: 'rowwrap'
            }];

        if (grid.features) {
            grid.features = features.concat(grid.features);
        } else {
            grid.features = features;
        }

        // NOTE: features have to be added before init (before Table.initComponent)
    },

    init: function(grid) {
        this.callParent(arguments);

        // Columns have to be added in init (after columns has been used to create the
        // headerCt). Otherwise, shared column configs get corrupted, e.g., if put in the
        // prototype.
        grid.headerCt.insert(0, this.getHeaderConfig());
        grid.on('render', this.bindView, this, {single: true});
    },

    getHeaderId: function() {
        if (!this.headerId) {
            this.headerId = Ext.id();
        }
        return this.headerId;
    },

    getRowBodyFeatureData: function(data, idx, record, orig) {
        var o = Ext.grid.feature.RowBody.prototype.getAdditionalData.apply(this, arguments),
            id = this.columnId;
        o.rowBodyColspan = o.rowBodyColspan - 1;
        o.rowBody = this.getRowBodyContents(data);
        o.rowCls = this.recordsExpanded[record.internalId] ? '' : this.rowCollapsedCls;
        o.rowBodyCls = this.recordsExpanded[record.internalId] ? '' : this.rowBodyHiddenCls;
        o[id + '-tdAttr'] = ' valign="top" rowspan="2" ';
        if (orig[id+'-tdAttr']) {
            o[id+'-tdAttr'] += orig[id+'-tdAttr'];
        }
        return o;
    },

    bindView: function() {
        var view = this.getCmp().getView(),
            viewEl;

        if (!view.rendered) {
            view.on('render', this.bindView, this, {single: true});
        } else {
            viewEl = view.getEl();
            if (this.expandOnEnter) {
                this.keyNav = Ext.create('Ext.KeyNav', viewEl, {
                    'enter' : this.onEnter,
                    scope: this
                });
            }
            if (this.expandOnDblClick) {
                view.on('itemdblclick', this.onDblClick, this);
            }
            this.view = view;
        }
    },

    onEnter: function(e) {
        var view = this.view,
            ds   = view.store,
            sm   = view.getSelectionModel(),
            sels = sm.getSelection(),
            ln   = sels.length,
            i = 0,
            rowIdx;

        for (; i < ln; i++) {
            rowIdx = ds.indexOf(sels[i]);
            this.toggleRow(rowIdx);
        }
    },

    toggleRow: function(rowIdx) {
        var rowNode = this.view.getNode(rowIdx),
            row = Ext.get(rowNode),
            nextBd = Ext.get(row).down(this.rowBodyTrSelector),
            record = this.view.getRecord(rowNode),
            grid = this.getCmp();

        if (row.hasCls(this.rowCollapsedCls)) {
            row.removeCls(this.rowCollapsedCls);
            nextBd.removeCls(this.rowBodyHiddenCls);
            this.recordsExpanded[record.internalId] = true;
            this.view.fireEvent('expandbody', rowNode, record, nextBd.dom);
        } else {
            row.addCls(this.rowCollapsedCls);
            nextBd.addCls(this.rowBodyHiddenCls);
            this.recordsExpanded[record.internalId] = false;
            this.view.fireEvent('collapsebody', rowNode, record, nextBd.dom);
        }
    },

    onDblClick: function(view, cell, rowIdx, cellIndex, e) {

        this.toggleRow(rowIdx);
    },

    getHeaderConfig: function() {
        var me                = this,
            toggleRow         = Ext.Function.bind(me.toggleRow, me),
            selectRowOnExpand = me.selectRowOnExpand;

        return {
            id: this.getHeaderId(),
            width: 24,
            sortable: false,
            resizable: false,
            draggable: false,
            hideable: false,
            menuDisabled: true,
            cls: Ext.baseCSSPrefix + 'grid-header-special',
            renderer: function(value, metadata) {
                metadata.tdCls = Ext.baseCSSPrefix + 'grid-cell-special';

                return '<div class="' + Ext.baseCSSPrefix + 'grid-row-expander">&#160;</div>';
            },
            processEvent: function(type, view, cell, recordIndex, cellIndex, e) {
                if (type == "mousedown" && e.getTarget('.x-grid-row-expander')) {
                    var row = e.getTarget('.x-grid-row');
                    toggleRow(row);
                    return selectRowOnExpand;
                }
            }
        };
    }
});

/**
 * SMS extensions to {@link Ext.ux.RowExpander}.
 */
Ext.define("Sms.ux.RowExpander", {
	extend: "Ext.ux.RowExpander",
	alias:  "plugin.sms-rowexpander",

	expandOnInit:   false,
	dataIndexRegex: /\{.+(?=\})/ig,

	constructor: function(config){
		var me = this;
		var grid;

		Ext.apply(me, config);

		//<debug>
		if(!me.rowBodyTpl){
			Ext.Error.raise("The 'rowBodyTpl' config is required and is not defined.");
		}
		//</debug>

		grid = me.getCmp();

		grid.expanderDataIndex = [];
		Ext.Array.each(me.rowBodyTpl, function(tplSegment){
			var result = me.dataIndexRegex.exec(tplSegment);
			if(result){
				grid.expanderDataIndex.push(result[0].substr(1));
			}
		});

		me.callParent([config]);
	},

	renderer: (function(){
		var cellExpanderCls = Ext.baseCSSPrefix + "grid-td-expander";

		// The rendered output is the same every time, so cache it up front.
		var columnHtml = Ext.String.format(
			'<div unselectable="on" class="{0} {1}">&#160;</div>',
			Ext.baseCSSPrefix + 'grid-row-expander',
			Ext.baseCSSPrefix + 'unselectable'
		);

		return function(value, metadata, record, rowIdx, colIdx){
			if(colIdx === 0){
				metadata.tdCls = cellExpanderCls;
			}
			return columnHtml;
		};
	}()),

	bindView: function(){
		var me   = this;
		var grid = me.getCmp();
		var view = grid.getView();

		me.callParent(arguments);

		if(view.rendered && me.expandOnInit){
			if(grid.getStore().getCount()){
				// Expand rows immediately if the grid is already loaded,
				// otherwise we have to wait until the view refreshes.
				me.expandAllRecords();
			}
			else{
				// Only expand all records on first refresh. Otherwise, all rows
				// will expand every refresh even if the user collapsed them.
				view.on("refresh", me.expandAllRecords, me, {single: true});
			}
		}
	},

	expandAllRecords: function(){
		var me = this;
		var store = me.getCmp().getStore();

		store.each(function(record){
			me.recordsExpanded[record.internalId] = true;
		});
	},

	getHeaderConfig: function(){
		var me                = this;
		var toggleRow         = Ext.bind(me.toggleRow, me);
		var selectRowOnExpand = me.selectRowOnExpand;

		var cellSpecialCls = Ext.baseCSSPrefix + "grid-cell-special";

		var columnHtml = Ext.String.format(
			'<div unselectable="on" class="{0} {1}">&#160;</div>',
			Ext.baseCSSPrefix + 'grid-row-expander',
			Ext.baseCSSPrefix + 'unselectable'
		);
		
		return Ext.apply(me.callParent(arguments), {
			isRowExpander: true,
			renderer: function(value, metadata){
				metadata.tdCls = cellSpecialCls;
				return columnHtml;
			},
			processEvent: function(type, view, cell, recordIdx, cellIdx, e){
				if(type === "click" && e.getTarget("." + Ext.baseCSSPrefix + "grid-row-expander")){
					toggleRow(e.getTarget("." + Ext.baseCSSPrefix + "grid-row"));
					return selectRowOnExpand;
				}
				return null;
			}
		});
	}
});
