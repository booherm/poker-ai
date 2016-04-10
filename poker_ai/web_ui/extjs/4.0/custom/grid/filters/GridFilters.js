/**
 * @class Ext.ux.grid.menu.RangeMenu
 * @extends Ext.menu.Menu
 * Custom implementation of {@link Ext.menu.Menu} that has preconfigured items for entering numeric
 * range comparison values: less-than, greater-than, and equal-to. This is used internally
 * by {@link Ext.ux.grid.filter.NumericFilter} to create its menu.
 */
Ext.define('Ext.ux.grid.menu.RangeMenu', {
    extend: 'Ext.menu.Menu',

    /**
     * @cfg {String} fieldCls
     * The Class to use to construct each field item within this menu
     * Defaults to:<pre>
     * fieldCls : Ext.form.field.Number
     * </pre>
     */
    fieldCls : 'Ext.form.field.Number',

    /**
     * @cfg {Object} fieldCfg
     * The default configuration options for any field item unless superseded
     * by the <code>{@link #fields}</code> configuration.
     * Defaults to:<pre>
     * fieldCfg : {}
     * </pre>
     * Example usage:
     * <pre><code>
fieldCfg : {
    width: 150,
},
     * </code></pre>
     */

    /**
     * @cfg {Object} fields
     * The field items may be configured individually
     * Defaults to <tt>undefined</tt>.
     * Example usage:
     * <pre><code>
fields : {
    gt: { // override fieldCfg options
        width: 200,
        fieldCls: Ext.ux.form.CustomNumberField // to override default {@link #fieldCls}
    }
},
     * </code></pre>
     */

    /**
     * @cfg {Object} itemIconCls
     * The itemIconCls to be applied to each comparator field item.
     * Defaults to:<pre>
itemIconCls : {
    gt : 'ux-rangemenu-gt',
    lt : 'ux-rangemenu-lt',
    eq : 'ux-rangemenu-eq'
}
     * </pre>
     */
    itemIconCls : {
        gt : 'ux-rangemenu-gt',
        lt : 'ux-rangemenu-lt',
        eq : 'ux-rangemenu-eq'
    },

    /**
     * @cfg {Object} fieldLabels
     * Accessible label text for each comparator field item. Can be overridden by localization
     * files. Defaults to:<pre>
fieldLabels : {
     gt: 'Greater Than',
     lt: 'Less Than',
     eq: 'Equal To'
}</pre>
     */
    fieldLabels: {
        gt: 'Greater Than',
        lt: 'Less Than',
        eq: 'Equal To'
    },

    /**
     * @cfg {Object} menuItemCfgs
     * Default configuration options for each menu item
     * Defaults to:<pre>
menuItemCfgs : {
    emptyText: 'Enter Filter Text...',
    selectOnFocus: true,
    width: 125
}
     * </pre>
     */
    menuItemCfgs : {
        emptyText: 'Enter Number...',
        selectOnFocus: false,
        width: 155
    },

    /**
     * @cfg {Array} menuItems
     * The items to be shown in this menu.  Items are added to the menu
     * according to their position within this array. Defaults to:<pre>
     * menuItems : ['lt','gt','-','eq']
     * </pre>
     */
    menuItems : ['lt', 'gt', '-', 'eq'],

	plain: true,

    constructor : function (config) {
        var me = this,
            fields, fieldCfg, i, len, item, cfg, Cls;

        me.callParent(arguments);

        fields = me.fields = me.fields || {};
        fieldCfg = me.fieldCfg = me.fieldCfg || {};

        me.addEvents(
            /**
             * @event update
             * Fires when a filter configuration has changed
             * @param {Ext.ux.grid.filter.Filter} this The filter object.
             */
            'update'
        );

        me.updateTask = Ext.create('Ext.util.DelayedTask', me.fireUpdate, me);

        for (i = 0, len = me.menuItems.length; i < len; i++) {
            item = me.menuItems[i];
            if (item !== '-') {
                // defaults
                cfg = {
					cls: "ux-gridfilter-text-field",
                    itemId: 'range-' + item,
                    enableKeyEvents: true,
                    hideEmptyLabel: false,
                    labelCls: "ux-rangemenu-icon " + me.itemIconCls[item],
                    labelSeparator: '',
                    labelWidth: 29,
					listeners: {
                        scope: me,
                        change: me.onInputChange,
                        keyup: me.onInputKeyUp,
                        el: {
                            click: function(e) {
                                e.stopPropagation();
                            }
                        }
                    },
                    activate: Ext.emptyFn,
                    deactivate: Ext.emptyFn
                };
                Ext.apply(
                    cfg,
                    // custom configs
                    Ext.applyIf(fields[item] || {}, fieldCfg[item]),
                    // configurable defaults
                    me.menuItemCfgs
                );
                Cls = cfg.fieldCls || me.fieldCls;
                item = fields[item] = Ext.create(Cls, cfg);
            }
            me.add(item);
        }
    },

    /**
     * @private
     * called by this.updateTask
     */
    fireUpdate : function () {
        this.fireEvent('update', this);
    },

    /**
     * Get and return the value of the filter.
     * @return {String} The value of this filter
     */
    getValue : function () {
        var result = {}, key, field;
        for (key in this.fields) {
            field = this.fields[key];
            if (field.isValid() && field.getValue() !== null) {
                result[key] = field.getValue();
            }
        }
        return result;
    },

    /**
     * Set the value of this menu and fires the 'update' event.
     * @param {Object} data The data to assign to this menu
     */
    setValue : function (data) {
        var key;
        for (key in this.fields) {
            this.fields[key].setValue(key in data ? data[key] : '');
        }
        this.fireEvent('update', this);
    },

    /**
     * @private
     * Handler method called when there is a keyup event on an input
     * item of this menu.
     */
    onInputKeyUp: function(field, e) {
        if (e.getKey() === e.RETURN && field.isValid()) {
            e.stopEvent();
            this.hide();
        }
    },

    /**
     * @private
     * Handler method called when the user changes the value of one of the input
     * items in this menu.
     */
    onInputChange: function(field) {
        var me = this,
            fields = me.fields,
            eq = fields.eq,
            gt = fields.gt,
            lt = fields.lt;

        if (field == eq) {
            if (gt) {
                gt.setValue(null);
            }
            if (lt) {
                lt.setValue(null);
            }
        }
        else {
            eq.setValue(null);
        }

        // restart the timer
        this.updateTask.delay(this.updateBuffer);
    }
});

Ext.define("Ext.ux.tree.menu.RangeMenu", {
    extend: "Ext.ux.grid.menu.RangeMenu"
});

/**
 * @class Ext.ux.grid.menu.ListMenu
 * @extends Ext.menu.Menu
 * This is a supporting class for {@link Ext.ux.grid.filter.ListFilter}.
 * Although not listed as configuration options for this class, this class
 * also accepts all configuration options from {@link Ext.ux.grid.filter.ListFilter}.
 */
Ext.define("Ext.ux.grid.menu.ListMenu", {
    extend: "Ext.menu.Menu",

	labelField: "text",
	valueField: "id",
    loadingText: "Loading...",

	loadOnShow : true,

	// Specify true to group all items in this list into a single-select
    // radio button group.
    single: false,

    constructor: function(cfg){
		var me = this,
			options = [],
			store,
			i, len, value;

        me.selected = [];
        me.addEvents(
            /**
             * @event checkchange
             * Fires when there is a change in checked items from this list
             * @param {Object} item Ext.menu.CheckItem
             * @param {Object} checked The checked value that was set
             */
            'checkchange'
        );

        me.callParent([cfg = cfg || {}]);

        if(!cfg.store && cfg.options){
            for(i = 0, len = cfg.options.length; i < len; i++){
                value = cfg.options[i];
                switch(Ext.type(value)){
                    case "array":  options.push(value); break;
                    case "object": options.push([value[me.valueField], value[me.labelField]]); break;
                    case "string": options.push([value, value]); break;
                }
            }

            me.store = new Ext.data.ArrayStore({
                fields:    [me.valueField, me.labelField],
                data:      options,
                listeners: {
					load:  me.onLoad,
					scope: me
                }
            });

            me.loaded = true;
        }
		else{
			if(typeof me.store === "string"){
				me.store = Ext.data.StoreManager.lookup(me.store);
			}
			store = me.store;
			me.add({text: me.loadingText, iconCls: 'loading-indicator'});
			me.onLoad(store, me.getStoreRecords(store));
		    store.on("datachanged", me.beforeLoad, me);
        }
    },

	// Template method to retrieve records from store
	getStoreRecords: function(store){
		if(store.getRootNode){
			var root = store.getRootNode(),
				records = [];
			if(root){
				root.cascadeBy(function(node){
					records.push(node);
				});
			}
			return records;
		}
		return store.getRange() || [];
	},

    destroy: function(){
		var me = this;
        if(me.store){
            me.store.destroy();
        }
        me.callParent();
    },

    /**
     * Lists will initially show a 'loading' item while the data is retrieved from the store.
     * In some cases the loaded data will result in a list that goes off the screen to the
     * right (as placement calculations were done with the loading item). This adapter will
     * allow show to be called with no arguments to show with the previous arguments and
     * thus recalculate the width and potentially hang the menu from the left.
     */
    show: function(){
		var lastArgs = null;
        return function(){
            if(arguments.length === 0){
                this.callParent(lastArgs);
            }
			else{
                lastArgs = arguments;
                if(this.loadOnShow && !this.loaded){
                    this.store.load();
                }
                this.callParent(arguments);
            }
        };
    }(),

	// Nifty little function that lets us override under what conditions the
	// menu is reloaded. For the general case, just let it pass right through.
	beforeLoad: function(store, records){
		this.onLoad(store, records);
	},

    onLoad: function(store, records){
		var me = this,
            visible = me.isVisible(),
            gid, item, itemValue, i, len;
        me.hide(false);
        me.removeAll(true);
        gid = me.single ? Ext.id() : null;
        for (i = 0, len = records.length; i < len; i++) {
            itemValue = records[i].get(me.valueField);
			item = new Ext.menu.CheckItem({
                text:        records[i].get(me.labelField),
                group:       gid,
                checked:     Ext.Array.contains(me.selected, itemValue),
                hideOnClick: false,
                value:       itemValue
            });
            item.on("checkchange", me.checkChange, me);
            me.add(item);
        }
        me.loaded = true;
        if (visible) {
            me.show();
        }
        me.fireEvent("load", me, records);
    },

    getSelected: function(){
        return this.selected;
    },

    setSelected: function(value){
		var me = this;
        value = me.selected = [].concat(value);

        if(me.loaded) {
            me.items.each(function(item){
				var i, len;
                item.setChecked(false, true);
                for(i = 0, len = value.length; i < len; i++) {
                    if(item.value == value[i]){
                        item.setChecked(true, true);
                    }
                }
            }, me);
        }
    },

    // Handler for the 'checkchange' event from an check item in this menu
    checkChange: function(item, checked){
		var me = this,
			value = [];

		me.items.each(function(item){
            if(item.checked){
                value.push(item.value);
            }
        }, me);

        me.selected = value;
		me.fireEvent("checkchange", item, checked);
    }
});

Ext.define("Ext.ux.tree.menu.ListMenu", {
	extend: "Ext.ux.grid.menu.ListMenu",

	// Flatten the nodes into a single array to be compatible
	beforeLoad: function(store){
		var me = this,
			records = me.getStoreRecords(store);
		me.onLoad(store, records);
	}
});

/**
 * @class Ext.ux.grid.FiltersFeature
 * @extends Ext.grid.Feature

FiltersFeature is a grid {@link Ext.grid.Feature feature} that allows for a slightly more
robust representation of filtering than what is provided by the default store.

Filtering is adjusted by the user using the grid's column header menu (this menu can be
disabled through configuration). Through this menu users can configure, enable, and
disable filters for each column.

#Features#

##Filtering implementations:##

Default filtering for Strings, Numeric Ranges, Date Ranges, Lists (which can be backed by a
{@link Ext.data.Store}), and Boolean. Additional custom filter types and menus are easily
created by extending {@link Ext.ux.grid.filter.Filter}.

##Graphical Indicators:##

Columns that are filtered have {@link #filterCls a configurable css class} applied to the column headers.

##Automatic Reconfiguration:##

Filters automatically reconfigure when the grid 'reconfigure' event fires.

##Stateful:##

Filter information will be persisted across page loads by specifying a `stateId`
in the Grid configuration.

The filter collection binds to the {@link Ext.grid.Panel#beforestaterestore beforestaterestore}
and {@link Ext.grid.Panel#beforestatesave beforestatesave} events in order to be stateful.

##GridPanel Changes:##

- A `filters` property is added to the GridPanel using this feature.
- A `filterupdate` event is added to the GridPanel and is fired upon onStateChange completion.

##Server side code examples:##

- [PHP](http://www.vinylfox.com/extjs/grid-filter-php-backend-code.php) - (Thanks VinylFox)</li>
- [Ruby on Rails](http://extjs.com/forum/showthread.php?p=77326#post77326) - (Thanks Zyclops)</li>
- [Ruby on Rails](http://extjs.com/forum/showthread.php?p=176596#post176596) - (Thanks Rotomaul)</li>
- [Python](http://www.debatablybeta.com/posts/using-extjss-grid-filtering-with-django/) - (Thanks Matt)</li>
- [Grails](http://mcantrell.wordpress.com/2008/08/22/extjs-grids-and-grails/) - (Thanks Mike)</li>

#Example usage:#

    var store = Ext.create('Ext.data.Store', {
        pageSize: 15
        ...
    });

    var filtersCfg = {
        ftype: 'filters',
        autoReload: false, //don't reload automatically
        local: true, //only filter locally
        // filters may be configured through the plugin,
        // or in the column definition within the headers configuration
        filters: [{
            type: 'numeric',
            dataIndex: 'id'
        }, {
            type: 'string',
            dataIndex: 'name'
        }, {
            type: 'numeric',
            dataIndex: 'price'
        }, {
            type: 'date',
            dataIndex: 'dateAdded'
        }, {
            type: 'list',
            dataIndex: 'size',
            options: ['extra small', 'small', 'medium', 'large', 'extra large'],
            phpMode: true
        }, {
            type: 'boolean',
            dataIndex: 'visible'
        }]
    };

    var grid = Ext.create('Ext.grid.Panel', {
         store: store,
         columns: ...,
         filters: [filtersCfg],
         height: 400,
         width: 700,
         bbar: Ext.create('Ext.PagingToolbar', {
             store: store
         })
    });

    // a filters property is added to the GridPanel
    grid.filters

 * @markdown
 */
Ext.define('Ext.ux.grid.FiltersFeature', {
    extend: 'Ext.grid.feature.Feature',
    alias: 'feature.filters',
    uses: [
        'Ext.ux.grid.menu.ListMenu',
        'Ext.ux.grid.menu.RangeMenu',
        'Ext.ux.grid.filter.BooleanFilter',
        'Ext.ux.grid.filter.DateFilter',
        'Ext.ux.grid.filter.ListFilter',
        'Ext.ux.grid.filter.NumericFilter',
        'Ext.ux.grid.filter.StringFilter'
    ],

    /**
     * @cfg {Boolean} autoReload
     * Defaults to true, reloading the datasource when a filter change happens.
     * Set this to false to prevent the datastore from being reloaded if there
     * are changes to the filters.  See <code>{@link updateBuffer}</code>.
     */
    autoReload : true,
    /**
     * @cfg {Boolean} encode
     * Specify true for {@link #buildQuery} to use Ext.util.JSON.encode to
     * encode the filter query parameter sent with a remote request.
     * Defaults to false.
     */
    /**
     * @cfg {Array} filters
     * An Array of filters config objects. Refer to each filter type class for
     * configuration details specific to each filter type. Filters for Strings,
     * Numeric Ranges, Date Ranges, Lists, and Boolean are the standard filters
     * available.
     */
    /**
     * @cfg {String} filterCls
     * The css class to be applied to column headers with active filters.
     * Defaults to <tt>'ux-filterd-column'</tt>.
     */
    filterCls : 'ux-filtered-column',
    /**
     * @cfg {Boolean} local
     * <tt>true</tt> to use Ext.data.Store filter functions (local filtering)
     * instead of the default (<tt>false</tt>) server side filtering.
     */
    local : false,
    /**
     * @cfg {String} menuFilterText
     * defaults to <tt>'Filters'</tt>.
     */
    menuFilterText : 'Filters',
    /**
     * @cfg {String} paramPrefix
     * The url parameter prefix for the filters.
     * Defaults to <tt>'filter'</tt>.
     */
    paramPrefix : 'filter',
    /**
     * @cfg {Boolean} showMenu
     * Defaults to true, including a filter submenu in the default header menu.
     */
    showMenu : true,
    /**
     * @cfg {String} stateId
     * Name of the value to be used to store state information.
     */
    stateId : undefined,
    /**
     * @cfg {Integer} updateBuffer
     * Number of milliseconds to defer store updates since the last filter change.
     */
    updateBuffer : 500,

    // doesn't handle grid body events
    hasFeatureEvent: false,

	viewSelector:  "gridpanel",
	filterAlias:   "gridfilter",
	filterMaskMsg: "Filtering...",
	filterMaskCls: "",
	useFilterMask: true,

    constructor : function (config) {
        var me = this;

        config = config || {};
        Ext.apply(me, config);

        me.deferredUpdate = new Ext.util.DelayedTask(me.reload, me);

        // Init filters
        me.filters = new Ext.util.MixedCollection(false, function(o){
            return o ? o.dataIndex : null;
        });
        me.filterConfigs = config.filters;
		me.hiddenRecords = [];
		me.createFilters();
    },


    attachEvents: function() {
        var me = this,
            view = me.view,
            headerCt = view.headerCt,
            grid = me.getGridPanel();

        me.bindStore(view.getStore(), true);

        // Listen for header menu being created
        headerCt.on('menucreate', me.onMenuCreate, me);

        view.on('refresh', me.onRefresh, me);
        grid.on({
            scope: me,
            beforestaterestore: me.applyState,
            beforestatesave: me.saveState,
            beforedestroy: me.destroy
        });

        // Add event and filters shortcut on grid panel
        grid.filters = me;
        grid.addEvents('filterupdate');
    },

    /**
     * @private Create the Filter objects for the current configuration, destroying any existing ones first.
     */
    createFilters: function() {
        var me = this,
            filterConfigs = me.filterConfigs,
            hadFilters = me.filters.getCount(),
            state;
        if (hadFilters) {
            state = {};
            me.saveState(null, state);
        }
        me.removeAll();
        me.addFilters(Ext.isEmpty(filterConfigs) ? me.view.headerCt.items.items : filterConfigs);
        if (hadFilters) {
            me.applyState(null, state);
        }
    },

    /**
     * @private Handle creation of the grid's header menu. Initializes the filters and listens
     * for the menu being shown.
     */
    onMenuCreate: function(headerCt, menu) {
        var me = this;
		menu.on('beforeshow', me.onMenuBeforeShow, me);
    },

    /**
     * @private Handle showing of the grid's header menu. Sets up the filter item and menu
     * appropriate for the target column.
     */
    onMenuBeforeShow: function(menu) {
		var me = this,
			menuItem, filter;

		if(me.showMenu){
			menuItem = me.menuItem;
			filter = me.getMenuFilter();
			if(!menuItem || menuItem.isDestroyed){
				me.createMenuItem(menu);
				menuItem = me.menuItem;
			}
			else if(filter){
				menuItem.menu = filter.menu;
			}
			if(filter){
				menuItem.setChecked(filter.active);
			}
			menuItem.setDisabled(!filter || filter.disabled === true);
		}
	},

	createMenuItem: function(menu) {
        var me = this,
			filter = me.getMenuFilter(),
			subMenu = null;

		if(filter){
			subMenu = filter.menu;
		}

		me.sep = menu.add('-');
		me.menuItem = menu.add({
			checked:   false,
			itemId:    'filters',
			text:      me.menuFilterText,
			menu:      subMenu,
			listeners: {
				scope: me,
				checkchange: me.onCheckChange,
				beforecheckchange: me.onBeforeCheck
			}
		});
    },

    getGridPanel: function() {
        return this.view.up(this.viewSelector);
    },

    /**
     * @private
     * Handler for the grid's beforestaterestore event (fires before the state of the
     * grid is restored).
     * @param {Object} grid The grid object
     * @param {Object} state The hash of state values returned from the StateProvider.
     */
    applyState : function (grid, state) {
        var key, filter;
        this.applyingState = true;
        this.clearFilters();
        if (state.filters) {
            for (key in state.filters) {
                filter = this.filters.get(key);
                if (filter) {
                    filter.setValue(state.filters[key]);
                    filter.setActive(true);
                }
            }
        }
        this.deferredUpdate.cancel();
        if (this.local) {
            this.reload();
        }
        delete this.applyingState;
        delete state.filters;
    },

    /**
     * Saves the state of all active filters
     * @param {Object} grid
     * @param {Object} state
     * @return {Boolean}
     */
    saveState : function (grid, state) {
        var filters = {};
        this.filters.each(function (filter) {
            if (filter.active) {
                filters[filter.dataIndex] = filter.getValue();
            }
        });
        return (state.filters = filters);
    },

    /**
     * @private
     * Handler called by the grid 'beforedestroy' event
     */
    destroy : function () {
        var me = this;
        Ext.destroyMembers(me, 'menuItem', 'sep');
        me.removeAll();
        me.clearListeners();
    },

    /**
     * Remove all filters, permanently destroying them.
     */
    removeAll : function () {
        if(this.filters){
            Ext.destroy.apply(Ext, this.filters.items);
            // remove all items from the collection
            this.filters.clear();
        }
    },


    /**
     * Changes the data store bound to this view and refreshes it.
     * @param {Store} store The store to bind to this view
     */
    bindStore : function(store, initial){
        if(!initial && this.store){
            if (this.local) {
                store.un('load', this.onLoad, this);
            } else {
                store.un('beforeload', this.onBeforeLoad, this);
            }
        }
        if(store){
            if (this.local) {
                store.on('load', this.onLoad, this);
            } else {
                store.on('beforeload', this.onBeforeLoad, this);
            }
        }
        this.store = store;
    },


    /**
     * @private
     * Get the filter menu from the filters MixedCollection based on the clicked header
     */
    getMenuFilter : function () {
        var header = this.view.headerCt.getMenu().activeHeader;
        return header ? this.filters.get(header.dataIndex) : null;
    },

    /** @private */
    onCheckChange : function (item, value) {
        this.getMenuFilter().setActive(value);
    },

    /** @private */
    onBeforeCheck : function (check, value) {
        return !value || this.getMenuFilter().isActivatable();
    },

    /**
     * @private
     * Handler for all events on filters.
     * @param {String} event Event name
     * @param {Object} filter Standard signature of the event before the event is fired
     */
    onStateChange : function (event, filter) {
        if (event !== 'serialize') {
            var me = this,
                grid = me.getGridPanel();

            if (filter == me.getMenuFilter()) {
                me.menuItem.setChecked(filter.active, false);
            }

            if ((me.autoReload || me.local) && !me.applyingState) {
                me.deferredUpdate.delay(me.updateBuffer);
            }
            me.updateColumnHeadings();

            if (!me.applyingState) {
                grid.saveState();
            }
            grid.fireEvent('filterupdate', me, filter);
        }
    },

    /**
     * @private
     * Handler for store's beforeload event when configured for remote filtering
     * @param {Object} store
     * @param {Object} options
     */
    onBeforeLoad : function (store, options) {
        options.params = options.params || {};
        this.cleanParams(options.params);
        var params = this.buildQuery(this.getFilterData());
		Ext.apply(options.params, params);
    },

    /**
     * @private
     * Handler for store's load event when configured for local filtering
     * @param {Object} store
     * @param {Object} options
     */
    onLoad : function (store) {
        store.filterBy(this.getRecordFilter());
    },

    /**
     * @private
     * Handler called when the grid's view is refreshed
     */
    onRefresh : function () {
        this.updateColumnHeadings();
    },

    /**
     * Update the styles for the header row based on the active filters
     */
    updateColumnHeadings : function () {
        var me = this,
            headerCt = me.view.headerCt;
        if (headerCt) {
            headerCt.items.each(function(header) {
                var filter = me.getFilter(header.dataIndex);
                header[filter && filter.active ? 'addCls' : 'removeCls'](me.filterCls);
            });
        }
    },

	// Sets up a body mask before beginning the filter
	reload: function(){
		var me = this,
			grid;

		if(me.isLoading){
			return;
		}

		if(me.useFilterMask && me.local){
			grid = me.getGridPanel();
			grid.body.mask(me.filterMaskMsg, me.filterMaskCls);
		}
		Ext.defer(me.doReload, 1, me, arguments);
	},

    doReload : function () {
        var me = this,
            store = me.view.getStore(),
			grid;

		me.isLoading = true;

        if(me.local){
			store.clearFilter(true);
            store.filterBy(me.getRecordFilter());
			if(me.useFilterMask){
				grid = me.getGridPanel();
				grid.body.unmask();
			}
        }
		else{
            me.deferredUpdate.cancel();
            store.loadPage(1);
        }

		delete me.isLoading;
    },

    /**
     * Method factory that generates a record validator for the filters active at the time
     * of invokation.
     * @private
     */
    getRecordFilter : function () {
        var f = [], len, i;
        this.filters.each(function (filter) {
            if (filter.active) {
                f.push(filter);
            }
        });

        len = f.length;
        return function (record) {
            for (i = 0; i < len; i++) {
                if (!f[i].validateRecord(record)) {
                    return false;
                }
            }
            return true;
        };
    },

    /**
     * Adds a filter to the collection and observes it for state change.
     * @param {Object/Ext.ux.grid.filter.Filter} config A filter configuration or a filter object.
     * @return {Ext.ux.grid.filter.Filter} The existing or newly created filter object.
     */
    addFilter : function (config) {
		var me = this,
			Cls = me.getFilterClass(config.type),
            filter;

		if(!Cls){
			return null;
		}
		filter = config.menu ? config : (new Cls(config));
		me.filters.add(filter);
        Ext.util.Observable.capture(filter, me.onStateChange, me);
        return filter;
    },

    /**
     * Adds filters to the collection.
     * @param {Array} filters An Array of filter configuration objects.
     */
    addFilters : function (filters) {
        if (filters) {
            var i, len, filter;
            for (i = 0, len = filters.length; i < len; i++) {
                filter = filters[i];
                // if filter config found add filter for the column
                if (filter) {
                    this.addFilter(filter);
                }
            }
        }
    },

    /**
     * Returns a filter for the given dataIndex, if one exists.
     * @param {String} dataIndex The dataIndex of the desired filter object.
     * @return {Ext.ux.grid.filter.Filter}
     */
    getFilter : function (dataIndex) {
        return this.filters.get(dataIndex);
    },

    /**
     * Turns all filters off. This does not clear the configuration information
     * (see {@link #removeAll}).
     */
    clearFilters : function (silent) {
        this.filters.each(function (filter) {
            filter.setActive(false, silent);
        });
    },

    /**
     * Returns an Array of the currently active filters.
     * @return {Array} filters Array of the currently active filters.
     */
    getFilterData : function () {
        var filters = [], i, len;

        this.filters.each(function (f) {
			if (f.active) {
				var d = [].concat(f.serialize());
                for (i = 0, len = d.length; i < len; i++) {
                    filters.push({
                        field: f.dataIndex,
                        data: d[i]
                    });
                }
            }
        });
        return filters;
    },

    /**
     * Function to take the active filters data and build it into a query.
     * The format of the query depends on the <code>{@link #encode}</code>
     * configuration:
     * <div class="mdetail-params"><ul>
     *
     * <li><b><tt>false</tt></b> : <i>Default</i>
     * <div class="sub-desc">
     * Flatten into query string of the form (assuming <code>{@link #paramPrefix}='filters'</code>:
     * <pre><code>
filters[0][field]="someDataIndex"&
filters[0][data][comparison]="someValue1"&
filters[0][data][type]="someValue2"&
filters[0][data][value]="someValue3"&
     * </code></pre>
     * </div></li>
     * <li><b><tt>true</tt></b> :
     * <div class="sub-desc">
     * JSON encode the filter data
     * <pre><code>
filters[0][field]="someDataIndex"&
filters[0][data][comparison]="someValue1"&
filters[0][data][type]="someValue2"&
filters[0][data][value]="someValue3"&
     * </code></pre>
     * </div></li>
     * </ul></div>
     * Override this method to customize the format of the filter query for remote requests.
     * @param {Array} filters A collection of objects representing active filters and their configuration.
     *    Each element will take the form of {field: dataIndex, data: filterConf}. dataIndex is not assured
     *    to be unique as any one filter may be a composite of more basic filters for the same dataIndex.
     * @return {Object} Query keys and values
     */
    buildQuery : function (filters) {
        var p = {}, i, f, root, dataPrefix, key, tmp,
            len = filters.length;

        if (!this.encode){
            for (i = 0; i < len; i++) {
                f = filters[i];
                root = [this.paramPrefix, '[', i, ']'].join('');
                p[root + '[field]'] = f.field;

                dataPrefix = root + '[data]';
                for (key in f.data) {
                    p[[dataPrefix, '[', key, ']'].join('')] = f.data[key];
                }
            }
        } else {
            tmp = [];
            for (i = 0; i < len; i++) {
                f = filters[i];
                tmp.push(Ext.apply(
                    {},
                    {field: f.field},
                    f.data
                ));
            }
            // only build if there is active filter
            if (tmp.length > 0){
                p[this.paramPrefix] = Ext.JSON.encode(tmp);
            }
        }
        return p;
    },

    /**
     * Removes filter related query parameters from the provided object.
     * @param {Object} p Query parameters that may contain filter related fields.
     */
    cleanParams : function (p) {
        // if encoding just delete the property
        if (this.encode) {
            delete p[this.paramPrefix];
        // otherwise scrub the object of filter data
        } else {
            var regex, key;
            regex = new RegExp('^' + this.paramPrefix + '\[[0-9]+\]');
            for (key in p) {
                if (regex.test(key)) {
                    delete p[key];
                }
            }
        }
    },

    /**
     * Function for locating filter classes, overwrite this with your favorite
     * loader to provide dynamic filter loading.
     * @param {String} type The type of filter to load ('Filter' is automatically
     * appended to the passed type; eg, 'string' becomes 'StringFilter').
     * @return {Class} The Ext.ux.grid.filter.Class
     */
    getFilterClass : function (type) {
		// map the supported Ext.data.Field type values into a supported filter
		switch(type){
			case "auto":
				type = "string";
				break;
			case "int":
			case "float":
				type = "numeric";
				break;
			case "bool":
				type = "boolean";
				break;
		}

		return Ext.ClassManager.getByAlias(this.filterAlias + "." + type);
	}
});

Ext.define('Ext.ux.tree.FiltersFeature', {
    extend: 'Ext.ux.grid.FiltersFeature',
    alias: 'feature.treefilters',
    uses: [
        'Ext.ux.tree.menu.ListMenu',
        'Ext.ux.tree.menu.RangeMenu',
        'Ext.ux.tree.filter.BooleanFilter',
        'Ext.ux.tree.filter.DateFilter',
        'Ext.ux.tree.filter.ListFilter',
        'Ext.ux.tree.filter.NumericFilter',
        'Ext.ux.tree.filter.StringFilter'
    ],

	viewSelector: "treepanel",
	filterAlias:  "treefilter",

	doReload: function(){
		var me = this,
            store, tree, view, rootNode,
			prevBulkUpdate,
			configObject, hiddenNotLeaf, recordFilter,
			i, len, hnl;

		me.isLoading = true;

        if(me.local){
            tree = me.getGridPanel();
			view = tree.getView();
			store = tree.getStore();

			for(i = 0, len = me.hiddenRecords.length; i < len; i++){
				configObject = me.hiddenRecords[i];
				configObject.parent.insertChild(configObject.childIndex, configObject.child);
			}

			me.hiddenRecords = [];
			rootNode = store.getRootNode();
			recordFilter = me.getRecordFilter();

			prevBulkUpdate = view.bulkUpdate;
			view.bulkUpdate = true;

			rootNode.cascadeBy(function(record){
				if(record.isLeaf() && !recordFilter(record)){
					me.hiddenRecords.push({
						parent:     record.parentNode,
						child:      record,
						childIndex: record.parentNode.indexOf(record)
					});
				}
			});

			for(i = 0, len = me.hiddenRecords.length; i < len; i++){
				me.hiddenRecords[i].child.remove();
			}

			hiddenNotLeaf = [];
			rootNode.cascadeBy(function(record){
				if(!record.isLeaf() && !record.childNodes.length && !record.isRoot()){
					hiddenNotLeaf.push({
						parent:     record.parentNode,
						child:      record,
						childIndex: record.parentNode.indexOf(record)
					});
				}
			});

			for(i = 0, len = hiddenNotLeaf.length; i < len; i++){
				hnl = hiddenNotLeaf[i];
				hnl.child.remove();
				me.hiddenRecords.push(hnl);
			}

			rootNode.expand(true);

			view.bulkUpdate = prevBulkUpdate;
			view.updateIndexes();
			if(view.stripeRows){
				view.doStripeRows(0);
			}

			if(me.useFilterMask){
				tree = tree || me.getGridPanel();
				tree.body.unmask();
			}
        }
		else{
			store = me.view.getStore();
            me.deferredUpdate.cancel();
            store.loadPage(1);
        }

		delete me.isLoading;
	}
});

/**
 * @class Ext.ux.grid.filter.Filter
 * @extends Ext.util.Observable
 * Abstract base class for filter implementations.
 */
Ext.define('Ext.ux.grid.filter.Filter', {
    extend: 'Ext.util.Observable',

    /**
     * @cfg {Boolean} active
     * Indicates the initial status of the filter (defaults to false).
     */
    active : false,
    /**
     * True if this filter is active.  Use setActive() to alter after configuration.
     * @type Boolean
     * @property active
     */
    /**
     * @cfg {String} dataIndex
     * The {@link Ext.data.Store} dataIndex of the field this filter represents.
     * The dataIndex does not actually have to exist in the store.
     */
    dataIndex : null,
    /**
     * The filter configuration menu that will be installed into the filter submenu of a column menu.
     * @type Ext.menu.Menu
     * @property
     */
    menu : null,
    /**
     * @cfg {Number} updateBuffer
     * Number of milliseconds to wait after user interaction to fire an update. Only supported
     * by filters: 'list', 'numeric', and 'string'. Defaults to 500.
     */
    updateBuffer : 500,
	
	configId: null,

    constructor : function (config) {
        Ext.apply(this, config);

        this.addEvents(
            /**
             * @event activate
             * Fires when an inactive filter becomes active
             * @param {Ext.ux.grid.filter.Filter} this
             */
            'activate',
            /**
             * @event deactivate
             * Fires when an active filter becomes inactive
             * @param {Ext.ux.grid.filter.Filter} this
             */
            'deactivate',
            /**
             * @event serialize
             * Fires after the serialization process. Use this to attach additional parameters to serialization
             * data before it is encoded and sent to the server.
             * @param {Array/Object} data A map or collection of maps representing the current filter configuration.
             * @param {Ext.ux.grid.filter.Filter} filter The filter being serialized.
             */
            'serialize',
            /**
             * @event update
             * Fires when a filter configuration has changed
             * @param {Ext.ux.grid.filter.Filter} this The filter object.
             */
            'update'
        );
        Ext.ux.grid.filter.Filter.superclass.constructor.call(this);

        this.menu = this.createMenu(config);
        this.init(config);
        if(config && config.value){
            this.setValue(config.value);
            this.setActive(config.active !== false, true);
            delete config.value;
        }
    },

    /**
     * Destroys this filter by purging any event listeners, and removing any menus.
     */
    destroy : function(){
        if (this.menu){
            this.menu.destroy();
        }
        this.clearListeners();
    },

    /**
     * Template method to be implemented by all subclasses that is to
     * initialize the filter and install required menu items.
     * Defaults to Ext.emptyFn.
     */
    init : Ext.emptyFn,

    /**
     * @private @override
     * Creates the Menu for this filter.
     * @param {Object} config Filter configuration
     * @return {Ext.menu.Menu}
     */
    createMenu: function(config) {
		config.plain = true;
        return Ext.create('Ext.menu.Menu', config);
    },

    /**
     * Template method to be implemented by all subclasses that is to
     * get and return the value of the filter.
     * Defaults to Ext.emptyFn.
     * @return {Object} The 'serialized' form of this filter
     * @methodOf Ext.ux.grid.filter.Filter
     */
    getValue : Ext.emptyFn,

    /**
     * Template method to be implemented by all subclasses that is to
     * set the value of the filter and fire the 'update' event.
     * Defaults to Ext.emptyFn.
     * @param {Object} data The value to set the filter
     * @methodOf Ext.ux.grid.filter.Filter
     */
    setValue : Ext.emptyFn,

    /**
     * Template method to be implemented by all subclasses that is to
     * return <tt>true</tt> if the filter has enough configuration information to be activated.
     * Defaults to <tt>return true</tt>.
     * @return {Boolean}
     */
    isActivatable : function(){
        return true;
    },

    /**
     * Template method to be implemented by all subclasses that is to
     * get and return serialized filter data for transmission to the server.
     * Defaults to Ext.emptyFn.
     */
    getSerialArgs : Ext.emptyFn,

    /**
     * Template method to be implemented by all subclasses that is to
     * validates the provided Ext.data.Record against the filters configuration.
     * Defaults to <tt>return true</tt>.
     * @param {Ext.data.Record} record The record to validate
     * @return {Boolean} true if the record is valid within the bounds
     * of the filter, false otherwise.
     */
    validateRecord : function(){
        return true;
    },

    /**
     * Returns the serialized filter data for transmission to the server
     * and fires the 'serialize' event.
     * @return {Object/Array} An object or collection of objects containing
     * key value pairs representing the current configuration of the filter.
     * @methodOf Ext.ux.grid.filter.Filter
     */
    serialize : function(){
        var args = this.getSerialArgs();
		if(this.configId)
		{
			if(Ext.isArray(args))
			{
				for(var i = 0; i < args.length; i++)
					args[i]["config_id"] = this.configId;
			}
			else if(Ext.isObject(args))
				args["config_id"] = this.configId;
		}
		else
		{
			if(Ext.isArray(args))
			{
				for(var i = 0; i < args.length; i++)
				{
					if(this.dataIndex)
						args[i]["config_id"] = this.dataIndex;
				}
			}
			else if(Ext.isObject(args))
			{
				if(this.dataIndex)
					args["config_id"] = this.dataIndex;
			}
		}
        this.fireEvent('serialize', args, this);
        return args;
    },

    /** @private */
    fireUpdate : function(){
        if (this.active) {
            this.fireEvent('update', this);
        }
        this.setActive(this.isActivatable());
    },

    /**
     * Sets the status of the filter and fires the appropriate events.
     * @param {Boolean} active        The new filter state.
     * @param {Boolean} suppressEvent True to prevent events from being fired.
     * @methodOf Ext.ux.grid.filter.Filter
     */
    setActive : function(active, suppressEvent){
        if(this.active != active){
            this.active = active;
            if (suppressEvent !== true) {
                this.fireEvent(active ? 'activate' : 'deactivate', this);
            }
        }
    }
});

/**
 * @class Ext.ux.grid.filter.StringFilter
 * @extends Ext.ux.grid.filter.Filter
 * Filter by a configurable Ext.form.field.Text
 * <p><b><u>Example Usage:</u></b></p>
 * <pre><code>
var filters = Ext.create('Ext.ux.grid.GridFilters', {
    ...
    filters: [{
        // required configs
        type: 'string',
        dataIndex: 'name',

        // optional configs
        value: 'foo',
        active: true, // default is false
        iconCls: 'ux-gridfilter-text-icon' // default
        // any Ext.form.field.Text configs accepted
    }]
});
 * </code></pre>
 */
Ext.define("Ext.ux.grid.filter.StringFilter", {
    extend: "Ext.ux.grid.filter.Filter",
    alias:  "gridfilter.string",

    // The iconCls to be applied to the menu item.
    iconCls: "ux-gridfilter-text-icon",

    emptyText: "Enter Filter Text...",
    selectOnFocus: true,
    width: 125,

    // Template method that is to initialize the filter and install required menu items.
    init: function(config){
		var me = this;

        Ext.applyIf(config, {
			cls:             "ux-gridfilter-text-field",
            enableKeyEvents: true,
            labelCls:        "ux-rangemenu-icon " + me.iconCls,
			hideEmptyLabel:  false,
			labelSeparator:  "",
			labelWidth:      29,
			listeners:       {
                scope: me,
                keyup: me.onInputKeyUp,
                el:    {
                    click: function(e){
                        e.stopPropagation();
                    }
                }
            }
        });

        me.inputItem = new Ext.form.field.Text(config);
        me.menu.add(me.inputItem);
		me.menu.showSeparator = false;
        me.updateTask = new Ext.util.DelayedTask(me.fireUpdate, me);
    },

    // Template method that is to get and return the value of the filter.
    getValue: function(){
        return this.inputItem.getValue();
    },

    // Template method that is to set the value of the filter.
    setValue: function(value){
		var me = this;
        me.inputItem.setValue(value);
        me.fireEvent("update", me);
    },

    // Template method that is to return true if the filter
    // has enough configuration information to be activated.
    isActivatable: function(){
        return this.inputItem.getValue().length > 0;
    },

    // Template method that is to get and return serialized filter data for
    // transmission to the server.
    // Returns object or collection of objects containing
    // key value pairs representing the current configuration of the filter.
    getSerialArgs: function(){
        return {type: "string", value: this.getValue()};
    },

    /**
     * Template method that is to validate the provided Ext.data.Record
     * against the filters configuration.
     * @param {Ext.data.Record} record The record to validate
     * @return {Boolean} true if the record is valid within the bounds
     * of the filter, false otherwise.
     */
    validateRecord: function(record){
		var me = this,
			val = Ext.util.Format.stripTags(record.get(me.dataIndex));

		if(typeof val !== "string") {
            return (me.getValue().length === 0);
        }
        return val.toLowerCase().indexOf(me.getValue().toLowerCase()) > -1;
    },

    // Handler method called when there is a keyup event on this.inputItem
    onInputKeyUp: function(field, e){
		var me = this,
			k = e.getKey();

        if(k === e.RETURN && field.isValid()){
            e.stopEvent();
            me.menu.hide();
			return;
        }
        me.updateTask.delay(me.updateBuffer);
    }
});

Ext.define("Ext.ux.tree.filter.StringFilter", {
	extend: "Ext.ux.grid.filter.StringFilter",
	alias:  "treefilter.string"
});

/**
 * @class Ext.ux.grid.filter.DateFilter
 * @extends Ext.ux.grid.filter.Filter
 * Filter by a configurable Ext.picker.DatePicker menu
 * <p><b><u>Example Usage:</u></b></p>
 * <pre><code>
var filters = Ext.create('Ext.ux.grid.GridFilters', {
    ...
    filters: [{
        // required configs
        type: 'date',
        dataIndex: 'dateAdded',

        // optional configs
        dateFormat: 'm/d/Y',  // default
        beforeText: 'Before', // default
        afterText: 'After',   // default
        onText: 'On',         // default
        pickerOpts: {
            // any DatePicker configs
        },

        active: true // default is false
    }]
});
 * </code></pre>
 */
Ext.define("Ext.ux.grid.filter.DateFilter", {
    extend: "Ext.ux.grid.filter.Filter",
    alias:  "gridfilter.date",
    uses:   ["Ext.picker.Date", "Ext.menu.Menu"],

    // Text to display for before, on, and after options
    afterText:  "After",
    beforeText: "Before",
	onText:     "On",

	// Map for assigning the comparison values used in serialization.
    compareMap: {
        before: "lt",
        after:  "gt",
        on:     "eq"
    },

    // The date format to return when using getValue.
    dateFormat : 'm/d/Y',

	// Array of date formats to check against when filtering
	dateFormats: [
		"m/d/Y",
		"m/Y",
		"m/d/Y h:i:s A",
		"Y-m-d",
		"m/d/Y H:i:s",
		"Y-m-d H:i:s.u"
	],

	// Last known date format to return a result
	lastDateFormat: null,

	// Minimum and maximum bounds for acceptable dates
	minDate: undefined,
	maxDate: undefined,

    // The items to be shown in this menu
    menuItems: ["before", "after", "-", "on"],

    // Default configuration options for each menu item
    menuItemCfgs: {
        selectOnFocus: true,
        width:         125
    },

	// Configuration options for the date picker associated with each field.
    pickerOpts: {},

	// Template method that is to initialize the filter and install required menu items.
    init: function(config){
        var me = this,
            pickerCfg, i, len, item, cfg;

        pickerCfg = Ext.apply(me.pickerOpts, {
            xtype:     "datepicker",
            minDate:   me.minDate,
            maxDate:   me.maxDate,
            format:    me.dateFormat,
            listeners: {
				select: me.onMenuSelect,
				scope:  me
            }
        });

        me.fields = {};
        for(i = 0, len = me.menuItems.length; i < len; i++){
            item = me.menuItems[i];
            if(item !== "-"){
                cfg = {
					itemId: "range-" + item,
                    text:   me[item + "Text"],
                    menu:   new Ext.menu.Menu({
                        items: [Ext.apply(pickerCfg, {itemId: item})]
                    }),
                    listeners: {
						checkchange: me.onCheckChange,
                        scope:       me
                    }
                };
                item = me.fields[item] = new Ext.menu.CheckItem(cfg);
            }
            me.menu.add(item);
        }
    },

    onCheckChange: function(){
		var me = this;
		me.setActive(me.isActivatable());
		me.fireEvent("update", me);
    },

    // Handler method called when there is a keyup event on an input
    // item of this menu.
    onInputKeyUp: function(field, e){
        var k = e.getKey();
        if(k == e.RETURN && field.isValid()){
            e.stopEvent();
            this.menu.hide();
        }
    },

    // Handler for when the DatePicker for a field fires the 'select' event
    onMenuSelect: function(picker, date){
		var me = this,
			fields = me.fields,
            field = fields[picker.itemId];

		field.setChecked(true);

		if(field == fields.on){
            fields.before.setChecked(false, true);
            fields.after.setChecked(false, true);
        }
		else{
            fields.on.setChecked(false, true);
            if(field == fields.after && me.getFieldValue("before") < date){
                fields.before.setChecked(false, true);
            }
			else if(field == fields.before && me.getFieldValue("after") > date){
                fields.after.setChecked(false, true);
            }
        }
        me.fireEvent("update", me);
        picker.up("menu").hide();
    },

    // Template method that is to get and return the value of the filter.
	getValue: function(){
        var me = this,
			fields = me.fields,
			result = {},
			key;

		for(key in fields){
            if(fields[key].checked){
                result[key] = me.getFieldValue(key);
            }
        }
        return result;
    },

    // Template method that is to set the value of the filter.
	// Set preserve = true to preserve the checked status
    // of the other fields. Defaults to false, unchecking the other fields
    setValue: function(value, preserve){
		var me = this,
			fields = me.fields,
			val, key;

        for(key in fields){
			val = value[key];
            if(val){
                me.getPicker(key).setValue(val);
                fields[key].setChecked(true);
            }
			else if(!preserve){
                fields[key].setChecked(false);
            }
        }
        me.fireEvent("update", me);
    },

    // Template method that is to return true if the filter
    // has enough configuration information to be activated.
    isActivatable: function(){
		var fields = this.fields,
			key;
        for(key in fields){
            if(fields[key].checked){
                return true;
            }
        }
        return false;
    },

    // Template method that is to get and return serialized filter data for
    // transmission to the server.
    // Returns object or collection of objects containing
    // key value pairs representing the current configuration of the filter.
    getSerialArgs: function(){
		var me = this,
			fields = me.fields,
			args = [],
			key;

        for(key in fields){
            if(fields[key].checked){
                args.push({
                    type:       "date",
                    comparison: me.compareMap[key],
                    value:      Ext.Date.format(me.getFieldValue(key), me.dateFormat)
                });
            }
        }
        return args;
    },

    // Get and return the date menu picker value
	// Item is the field identifier ('before', 'after', 'on')
    getFieldValue: function(item){
        return this.getPicker(item).getValue();
    },

    // Gets the menu picker associated with the passed field
	// Item is the field identifier ('before', 'after', 'on')
    getPicker: function(item){
        return this.fields[item].menu.items.first();
    },

	/**
     * Template method that is to validate the provided Ext.data.Record
     * against the filters configuration.
     * @param {Ext.data.Record} record The record to validate
     * @return {Boolean} true if the record is valid within the bounds
     * of the filter, false otherwise.
     *
	 * This method has been heavily edited from its original version to account
	 * for the different date formats in use by SMS. The basic principle is to
	 * supply an array of possible formats in the "dateFormats" property above,
	 * and a "lastDateFormat" property as a shortcut. Since filtering is done
	 * sequentially and all dates of the given dataIndex should be the same
	 * format, we can use it quite reliably.
	 */
    validateRecord: function(record){
		var me = this,
			val = record.get(me.dataIndex),
			len = me.dateFormats.length,
			ct = Ext.Date.clearTime,
			parse = Ext.Date.parse,
			dateObj, key, pickerValue, fmt, i;

		// Fast exit for empty values
		if(!val){
			return false;
		}

		// Check which date format worked last time and try it first
		if(Ext.isDate(val))
			dateObj = val;
		else if(me.lastDateFormat){
			val = Ext.util.Format.stripTags(val);
			dateObj = parse(val, me.lastDateFormat);
		}

		// If the last date format didn't work, check all of them
		if(!dateObj){
			me.lastDateFormat = null;
			for(i = 0; i < len; i++){
				fmt = me.dateFormats[i];
				dateObj = parse(val, fmt);
				if(dateObj){
					me.lastDateFormat = fmt;
					break;
				}
			}
		}

		// If we didn't find a match, we're done
		if(!dateObj){
			return false;
		}

		// We found a matching format and saved it for next time. Now we can
		// do the actual comparisons
		val = ct(dateObj).getTime();
        for(key in me.fields){
            if(me.fields[key].checked){
                pickerValue = ct(me.getFieldValue(key), true).getTime();
                if(key === "before" && pickerValue <= val){
                    return false;
                }
                if(key === "after" && pickerValue >= val){
                    return false;
                }
                if(key === "on" && pickerValue !== val){
                    return false;
                }
            }
        }
        return true;
    }
});

Ext.define("Ext.ux.tree.filter.DateFilter", {
	extend: "Ext.ux.grid.filter.DateFilter",
	alias:  "treefilter.date"
});

/**
 * @class Ext.ux.grid.filter.ListFilter
 * @extends Ext.ux.grid.filter.Filter
 * <p>List filters are able to be preloaded/backed by an Ext.data.Store to load
 * their options the first time they are shown. ListFilter utilizes the
 * {@link Ext.ux.grid.menu.ListMenu} component.</p>
 * <p>Although not shown here, this class accepts all configuration options
 * for {@link Ext.ux.grid.menu.ListMenu}.</p>
 *
 * <p><b><u>Example Usage:</u></b></p>
 * <pre><code>
var filters = Ext.create('Ext.ux.grid.GridFilters', {
    ...
    filters: [{
        type: 'list',
        dataIndex: 'size',
        phpMode: true,
        // options will be used as data to implicitly creates an ArrayStore
        options: ['extra small', 'small', 'medium', 'large', 'extra large']
    }]
});
 * </code></pre>
 *
 */
Ext.define("Ext.ux.grid.filter.ListFilter", {
    extend: "Ext.ux.grid.filter.Filter",
    alias:  "gridfilter.list",

    /**
     * @cfg {Array} options
     * <p><code>data</code> to be used to implicitly create a data store
     * to back this list when the data source is <b>local</b>. If the
     * data for the list is remote, use the <code>{@link #store}</code>
     * config instead.</p>
     * <br><p>Each item within the provided array may be in one of the
     * following formats:</p>
     * <div class="mdetail-params"><ul>
     * <li><b>Array</b> :
     * <pre><code>
options: [
    [11, 'extra small'],
    [18, 'small'],
    [22, 'medium'],
    [35, 'large'],
    [44, 'extra large']
]
     * </code></pre>
     * </li>
     * <li><b>Object</b> :
     * <pre><code>
labelField: 'name', // override default of 'text'
options: [
    {id: 11, name:'extra small'},
    {id: 18, name:'small'},
    {id: 22, name:'medium'},
    {id: 35, name:'large'},
    {id: 44, name:'extra large'}
]
     * </code></pre>
     * </li>
     * <li><b>String</b> :
     * <pre><code>
     * options: ['extra small', 'small', 'medium', 'large', 'extra large']
     * </code></pre>
     * </li>
     */
    /**
     * @cfg {Boolean} phpMode
     * <p>Adjust the format of this filter. Defaults to false.</p>
     * <br><p>When GridFilters <code>@cfg encode = false</code> (default):</p>
     * <pre><code>
// phpMode == false (default):
filter[0][data][type] list
filter[0][data][value] value1
filter[0][data][value] value2
filter[0][field] prod

// phpMode == true:
filter[0][data][type] list
filter[0][data][value] value1, value2
filter[0][field] prod
     * </code></pre>
     * When GridFilters <code>@cfg encode = true</code>:
     * <pre><code>
// phpMode == false (default):
filter : [{"type":"list","value":["small","medium"],"field":"size"}]

// phpMode == true:
filter : [{"type":"list","value":"small,medium","field":"size"}]
     * </code></pre>
     */
    phpMode: false,

	/**
     * @cfg {Ext.data.Store} store
     * The {@link Ext.data.Store} this list should use as its data source
     * when the data source is <b>remote</b>. If the data for the list
     * is local, use the <code>{@link #options}</code> config instead.
     */

	// Class to use when instantiating the ListMenu
	menuClass: "Ext.ux.grid.menu.ListMenu",

    // Template method that is to initialize the filter.
    init: function(config){
		var me = this;
        me.dt = new Ext.util.DelayedTask(me.fireUpdate, me);
    },

    // Creates the Menu for this filter.
    createMenu: function(config){
		var me = this,
			menu = Ext.create(me.menuClass, config);
        menu.on("checkchange", me.onCheckChange, me);
        return menu;
    },

    // Template method that is to get and return the value of the filter.
    getValue: function(){
        return this.menu.getSelected();
    },

    // Template method that is to set the value of the filter.
    setValue: function(value){
		var me = this;
		me.menu.setSelected(value);
        me.fireEvent("update", me);
    },

    // Template method that is to return true if the filter
    // has enough configuration information to be activated.
    isActivatable: function(){
        return this.getValue().length > 0;
    },

    // Template method that is to get and return serialized filter data for
    // transmission to the server.
    // Returns object or collection of objects containing
    // key value pairs representing the current configuration of the filter.
    getSerialArgs: function(){
		var me = this;
        return {type: "list", value: me.phpMode ? me.getValue().join(",") : me.getValue()};
    },

    onCheckChange: function(){
		var me = this;
        me.dt.delay(me.updateBuffer);
    },

	/**
     * Template method that is to validate the provided Ext.data.Record
     * against the filters configuration.
     * @param {Ext.data.Record} record The record to validate
     * @return {Boolean} true if the record is valid within the bounds
     * of the filter, false otherwise.
     */
    validateRecord : function (record) {
		var me = this,
			valuesArray = me.getValue(),
			val = Ext.util.Format.stripTags(record.get(me.dataIndex));
        return Ext.Array.indexOf(valuesArray, val || "(Blanks)") > -1;
    }
});

Ext.define("Ext.ux.tree.filter.ListFilter", {
	extend:    "Ext.ux.grid.filter.ListFilter",
	alias:     "treefilter.list",
	menuClass: "Ext.ux.tree.menu.ListMenu"
});

/**
 * @class Ext.ux.grid.filter.NumericFilter
 * @extends Ext.ux.grid.filter.Filter
 * Filters using an Ext.ux.grid.menu.RangeMenu.
 * <p><b><u>Example Usage:</u></b></p>
 * <pre><code>
var filters = Ext.create('Ext.ux.grid.GridFilters', {
    ...
    filters: [{
        type: 'numeric',
        dataIndex: 'price'
    }]
});
 * </code></pre>
 * <p>Any of the configuration options for {@link Ext.ux.grid.menu.RangeMenu} can also be specified as
 * configurations to NumericFilter, and will be copied over to the internal menu instance automatically.</p>
 */
Ext.define("Ext.ux.grid.filter.NumericFilter", {
    extend: "Ext.ux.grid.filter.Filter",
    alias:  "gridfilter.numeric",
    uses:  ["Ext.form.field.Number"],

	// Class to use for instantiating the menu
	menuClass: "Ext.ux.grid.menu.RangeMenu",

	// Pre-compiled regular expressions, for performance
	stripTagsRE: /<\/?[^>]+>/gi,
	numericRE: /[^\d\.\-]/g,

    // Creates the Menu for this filter.
    createMenu: function(config){
        var me = this,
            menu = Ext.create(me.menuClass, config);
        menu.on("update", me.fireUpdate, me);
        return menu;
    },

    // Template method that is to get and return the value of the filter.
    getValue: function(){
        return this.menu.getValue();
    },

    // Template method that is to set the value of the filter.
    setValue: function(value){
        this.menu.setValue(value);
    },

    // Template method that is to return true if the filter
    // has enough configuration information to be activated.
    isActivatable: function(){
		var me = this,
			values = me.getValue(),
            key;

        for(key in values){
            if(values[key] !== undefined){
                return true;
            }
        }
        return false;
    },

    // Template method that is to get and return serialized filter data for
    // transmission to the server.
    // Returns object or collection of objects containing
    // key value pairs representing the current configuration of the filter.
    getSerialArgs: function(){
		var values = this.menu.getValue(),
			args = [],
			key;
        for(key in values){
            args.push({
                type:       "numeric",
                comparison: key,
                value:      values[key]
            });
        }
        return args;
    },

    /**
     * Template method that is to validate the provided Ext.data.Record
     * against the filters configuration.
     * @param {Ext.data.Record} record The record to validate
     * @return {Boolean} true if the record is valid within the bounds
     * of the filter, false otherwise.
     */
    validateRecord: function(record){
		var me = this,
			raw = record.data[me.dataIndex],
			val = (raw == null) ? "" : String(raw).replace(me.stripTagsRE, "").replace(me.numericRE, ""),
            values = me.getValue(),
            isNumber = Ext.isNumber;
		if(val === ""){
			return false;
		}
		val = parseFloat(val);
		if(isNaN(val)){
			return false;
		}
		if(isNumber(values.eq) && val != values.eq){
            return false;
        }
        if(isNumber(values.lt) && val >= values.lt){
            return false;
        }
        if(isNumber(values.gt) && val <= values.gt){
            return false;
        }
        return true;
    }
});

Ext.define("Ext.ux.tree.filter.NumericFilter", {
	extend:    "Ext.ux.grid.filter.NumericFilter",
	alias:     "treefilter.numeric",
	menuClass: "Ext.ux.tree.menu.RangeMenu"
});

/**
 * @class Ext.ux.grid.filter.BooleanFilter
 * @extends Ext.ux.grid.filter.Filter
 * Boolean filters use unique radio group IDs (so you can have more than one!)
 * <p><b><u>Example Usage:</u></b></p>
 * <pre><code>
var filters = Ext.create('Ext.ux.grid.GridFilters', {
    ...
    filters: [{
        // required configs
        type: 'boolean',
        dataIndex: 'visible'

        // optional configs
        defaultValue: null, // leave unselected (false selected by default)
        yesText: 'Yes',     // default
        noText: 'No'        // default
    }]
});
 * </code></pre>
 */
Ext.define("Ext.ux.grid.filter.BooleanFilter", {
    extend: "Ext.ux.grid.filter.Filter",
    alias:  "gridfilter.boolean",

	// Set this to null if you do not want either option to be checked by default. Defaults to false.
	defaultValue: false,

	// Text to display for yes (true) and no (false) options
	yesText: "Yes",
	noText: "No",

	// Template method that is to initialize the filter and install required menu items.
    init: function(config){
        var me = this,
			gId = Ext.id(),
			opts;

		opts = me.options = [
			new Ext.menu.CheckItem({text: me.yesText, group: gId, checked: me.defaultValue === true}),
			new Ext.menu.CheckItem({text: me.noText,  group: gId, checked: me.defaultValue === false})
		];

		me.menu.add(opts[0], opts[1]);

		opts[0].on({
			click:       me.fireUpdate,
			checkchange: me.fireUpdate,
			scope:       me
		});
		opts[1].on({
			click:       me.fireUpdate,
			checkchange: me.fireUpdate,
			scope:       me
		});
	},

    // Template method that is to get and return the value of the filter.
	// Returns the value of this filter
    getValue: function(){
		return this.options[0].checked;
	},

    // Template method that is to set the value of the filter.
	// Returns the value to set the filter
	setValue: function(value){
		this.options[value ? 0 : 1].setChecked(true);
	},

    // Template method that is to get and return serialized filter data for
    // transmission to the server.
    // Returns object or collection of objects containing
    // key value pairs representing the current configuration of the filter.
    getSerialArgs: function (){
		return {type: "boolean", value: this.getValue()};
	},

    // Template method that is to validate the provided Ext.data.Record
    // against the filters configuration.
    // Returns true if the record is valid within the bounds of the filter, false otherwise.
    validateRecord: function(record){
		var me = this,
			raw = Ext.util.Format.stripTags(record.get(me.dataIndex)),
			val = Ext.data.Types.BOOL.convert(raw);
		return val == me.getValue();
	}
});

Ext.define("Ext.ux.tree.filter.BooleanFilter", {
	extend: "Ext.ux.grid.filter.BooleanFilter",
	alias:  "treefilter.boolean"
});
