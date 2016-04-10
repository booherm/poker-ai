/**
 * A control that allows selection of between two Ext.ux.form.MultiSelect controls.
 */
Ext.define('Ext.ux.form.ItemSelector', {
	extend: 'Ext.ux.form.MultiSelect',
	alias: ['widget.itemselectorfield', 'widget.itemselector'],
	alternateClassName: ['Ext.ux.ItemSelector'],
	requires: [
		'Ext.button.Button',
		'Ext.ux.form.MultiSelect'
	],

	/**
	 * @cfg {Boolean} [hideNavIcons=false] True to hide the navigation icons
	 */
	hideNavIcons:false,

	searchBoxConfig: null,

	sortProperty: null,
	onlySortFromStore: false,
	inactiveOptionsFunction: null,
	/**
	 * @cfg {Array} buttons Defines the set of buttons that should be displayed in between the ItemSelector
	 * fields. Defaults to <tt>['top', 'up', 'add', 'remove', 'down', 'bottom']</tt>. These names are used
	 * to build the button CSS class names, and to look up the button text labels in {@link #buttonsText}.
	 * This can be overridden with a custom Array to change which buttons are displayed or their order.
	 */
	buttons: ['top', 'up', 'add', 'remove', 'down', 'bottom'],
	createdButtons: null,

	/**
	 * @cfg {Object} buttonsText The tooltips for the {@link #buttons}.
	 * Labels for buttons.
	 */
	buttonsText: {
		top: "Move to Top",
		up: "Move Up",
		add: "Add to Selected",
		remove: "Remove from Selected",
		down: "Move Down",
		bottom: "Move to Bottom"
	},

	initComponent: function() {
		var me = this;
		me.createdButtons = {};

		me.ddGroup = me.id + '-dd';
		me.callParent();

		// bindStore must be called after the fromField has been created because
		// it copies records from our configured Store into the fromField's Store
		me.bindStore(me.store);

		me.setValue(me.value);
	},

	createList: function(isFrom){
		var me = this;
		var title = "Selected";

		var searchBoxConfig = null;
		var storeListeners = null;
		var inactiveOptionsFunction = null;
		if(isFrom)
		{
			searchBoxConfig = me.searchBoxConfig;
			title = "Available";
			inactiveOptionsFunction = me.inactiveOptionsFunction;
			storeListeners = {
				load: function(){
					if(me.fromField && me.inactiveOptionsFunction)
						me.fromField.sortInactiveRecords.call(me.fromField, me.fromField.store);
				}
			};
		}
		else
		{
			storeListeners = {
				datachanged: me.onToFieldChange,
				scope: me
			};
		}

		return Ext.create('Ext.ux.form.MultiSelect', {
			title: title,
			submitValue: false,
			flex: 1,
			region: "center",
			dragGroup: me.ddGroup,
			dropGroup: me.ddGroup,
			store: {
				model: me.store.model,
				data: [],
				listeners: storeListeners
			},
			displayField: me.displayField,
			disabled: me.disabled,
			listeners: {
				boundList: {
					scope: me,
					itemdblclick: me.onItemDblClick,
					drop: me.syncValue,
					selectionchange: me.updateButtonDisableState
				}
			},
			height: me.height,
			searchBoxConfig: searchBoxConfig,
			fixedRowHeight: me.fixedRowHeight,
			inactiveOptionsFunction: inactiveOptionsFunction
		});
	},

	clearSearchBox: function(){
		var me = this;
		me.fromField.clearSearchBox();
	},

	onToFieldChange: function() {
		this.checkChange();
	},

	setupItems: function() {
		var me = this;

		me.fromField = me.createList(true);
		me.toField = me.createList(false);

		return {
			layout: {
				type: 'hbox',
				align: 'stretch'
			},
			items: [
				me.fromField,
				{
					xtype: 'container',
					margins: '0 4',
					width: 22,
					layout: {
						type: 'vbox',
						pack: 'center'
					},
					items: me.createButtons()
				},
				{
					flex:   1,
					xtype:  "panel",
					layout: "border",
					height: 150,
					items:  [me.toField]
				}
			]
		};
	},

	createButtons: function(){
		var me = this,
			buttons = me.createdButtons;

		var buttonArray = [];
		if (!me.hideNavIcons) {
			Ext.Array.forEach(me.buttons, function(name) {
				var newButton = Ext.create("Ext.button.Button", {
					xtype: 'button',
					tooltip: me.buttonsText[name],
					handler: me['on' + Ext.String.capitalize(name) + 'BtnClick'],
					cls: Ext.baseCSSPrefix + 'form-itemselector-btn',
					iconCls: Ext.baseCSSPrefix + 'form-itemselector-' + name,
					navBtn: true,
					scope: me,
					disabled: true,
					margin: '4 0 0 0'
				});
				buttons[name] = newButton;
				buttonArray.push(newButton);
			});
		}
		return buttonArray;
	},

	updateButtonDisableState:function(selectionModel, selections){
		var me = this;
		if(me.toField.boundList.getSelectionModel() == selectionModel)
		{
			if(me.createdButtons["remove"])
			{
				if(selections.length)
					me.createdButtons["remove"].enable();
				else
					me.createdButtons["remove"].disable();
			}
			if(me.createdButtons["top"])
			{
				if(selections.length)
					me.createdButtons["top"].enable();
				else
					me.createdButtons["top"].disable();
			}
			if(me.createdButtons["up"])
			{
				if(selections.length)
					me.createdButtons["up"].enable();
				else
					me.createdButtons["up"].disable();
			}
			if(me.createdButtons["down"])
			{
				if(selections.length)
					me.createdButtons["down"].enable();
				else
					me.createdButtons["down"].disable();
			}
			if(me.createdButtons["bottom"])
			{
				if(selections.length)
					me.createdButtons["bottom"].enable();
				else
					me.createdButtons["bottom"].disable();
			}
		}
		else if(me.fromField.boundList.getSelectionModel() == selectionModel)
		{
			if(me.createdButtons["add"])
			{
				if(selections.length)
					me.createdButtons["add"].enable();
				else
					me.createdButtons["add"].disable();
			}
		}
	},

	getSelections: function(list){
		var store = list.getStore(),
			selections = list.getSelectionModel().getSelection();

		return Ext.Array.sort(selections, function(a, b){
			a = store.indexOf(a);
			b = store.indexOf(b);

			if (a < b) {
				return -1;
			} else if (a > b) {
				return 1;
			}
			return 0;
		});
	},

	onTopBtnClick : function() {
		var list = this.toField.boundList,
			store = list.getStore(),
			selected = this.getSelections(list);

		store.suspendEvents();
		store.remove(selected, true);
		store.insert(0, selected);
		store.resumeEvents();
		list.refresh();
		this.syncValue();
		list.getSelectionModel().select(selected);
		this.onToFieldChange();
	},

	onBottomBtnClick : function() {
		var list = this.toField.boundList,
			store = list.getStore(),
			selected = this.getSelections(list);

		store.suspendEvents();
		store.remove(selected, true);
		store.add(selected);
		store.resumeEvents();
		list.refresh();
		this.syncValue();
		list.getSelectionModel().select(selected);
		this.onToFieldChange();
	},

	onUpBtnClick : function() {
		var list = this.toField.boundList,
			store = list.getStore(),
			selected = this.getSelections(list),
			i = 0,
			len = selected.length,
			index = store.getCount();

		// Find index of first selection
		for (; i < len; ++i) {
			index = Math.min(index, store.indexOf(selected[i]));
		}
		// If first selection is not at the top, move the whole lot up
		if (index > 0) {
			store.suspendEvents();
			store.remove(selected, true);
			store.insert(index - 1, selected);
			store.resumeEvents();
			list.refresh();
			this.syncValue();
			list.getSelectionModel().select(selected);
		}
		this.onToFieldChange();
	},

	onDownBtnClick : function() {
		var list = this.toField.boundList,
			store = list.getStore(),
			selected = this.getSelections(list),
			i = 0,
			len = selected.length,
			index = 0;

		// Find index of last selection
		for (; i < len; ++i) {
			index = Math.max(index, store.indexOf(selected[i]));
		}
		// If last selection is not at the bottom, move the whole lot down
		if (index < store.getCount() - 1) {
			store.suspendEvents();
			store.remove(selected, true);
			store.insert(index + 2 - len, selected);
			store.resumeEvents();
			list.refresh();
			this.syncValue();
			list.getSelectionModel().select(selected);
		}
		this.onToFieldChange();
	},

	onAddBtnClick : function() {
		var me = this,
			fromList = me.fromField.boundList,
			selected = this.getSelections(fromList);

		fromList.getStore().remove(selected);
		this.toField.boundList.getStore().add(selected);
		this.syncValue();
	},

	onRemoveBtnClick : function() {
		var me = this,
			toList = me.toField.boundList,
			selected = this.getSelections(toList);

		toList.getStore().remove(selected);
		this.fromField.boundList.getStore().add(selected);
		this.syncValue();
	},

	syncValue: function() {
		this.setValue(this.toField.store.getRange(), true);
	},

	onItemDblClick: function(view, rec){
		var me = this,
			from = me.fromField.store,
			to = me.toField.store,
			current,
			destination;

		if (view === me.fromField.boundList) {
			current = from;
			destination = to;
		} else {
			current = to;
			destination = from;
		}
		current.remove(rec);
		destination.add(rec);
		me.syncValue();
	},

	setValue: function(value, fromUserAction){
		var me = this,
			fromStore = me.fromField.store,
			toStore = me.toField.store,
			selected;

		// Wait for from store to be loaded
		//I've commented this out, not having it doesn't seem to have a negative affect, but it is possible for
		//the from store to be loaded and have a count of 0 in normal situations, which breaks this component
		/*if (!me.fromField.store.getCount()) {
			me.fromField.store.on({
				load: Ext.Function.bind(me.setValue, me, [value]),
				single: true
			});
			return;
		}*/

		value = me.setupValue(value);
		me.mixins.field.setValue.call(me, value);

		selected = me.getRecordsForValue(value);

		Ext.Array.forEach(toStore.getRange(), function(rec){
			if (!Ext.Array.contains(selected, rec)) {
				// not in the selected group, remove it from the toStore
				toStore.remove(rec);
				fromStore.add(rec);
			}
		});
		toStore.removeAll();

		Ext.Array.forEach(selected, function(rec){
			// In the from store, move it over
			if (fromStore.indexOf(rec) > -1) {
				fromStore.remove(rec);
			}
			toStore.add(rec);
		});
		if(me.inactiveOptionsFunction)
			me.fromField.sortInactiveRecords.call(me.fromField, me.fromField.store);
		if(this.sortProperty)
		{
			this.fromField.store.sort(this.sortProperty, "ASC");
			if(!this.onlySortFromStore && !fromUserAction)
			{
				this.toField.store.sort(this.sortProperty, "ASC");
				this.toField.store.sorters.clear();
			}
		}
	},

	onBindStore: function(store, initial) {
		var me = this;

		if (me.fromField) {
			me.fromField.store.removeAll();
			me.toField.store.removeAll();

			// Add everything to the from field as soon as the Store is loaded
			if (store.getCount()) {
				me.populateFromStore(store);
			} else {
				me.store.on('load', me.populateFromStore, me);
			}
		}
	},

	populateFromStore: function(store) {
		this.fromField.store.add(store.getRange());

		// setValue wait for the from Store to be loaded
		this.fromField.store.fireEvent('load', this.fromField.store);
	},

	onEnable: function(){
		var me = this;

		me.callParent();
		me.fromField.enable();
		me.toField.enable();

		Ext.Array.forEach(me.query('[navBtn]'), function(btn){
			btn.enable();
		});
	},

	onDisable: function(){
		var me = this;

		me.callParent();
		me.fromField.disable();
		me.toField.disable();

		Ext.Array.forEach(me.query('[navBtn]'), function(btn){
			btn.disable();
		});
	},

	onDestroy: function(){
		this.bindStore(null);
		this.callParent();
	}
});
