/**
 * Generic container that allows the user to add/remove a variable number of rows.
 *
 * Instead of using the "items" config, use "itemConfig" to set a constructor object.
 * Example:
 *
 *     Ext.create("Sms.container.AddRemove", {
 *         width: 400,
 *         itemConfig: {
 *             xtype: "textfield",
 *             width: 300,
 *             ...
 *         }
 *         ...
 *     });
 *
 * Other config options include:
 *
 *     itemSpacing (Number) - Vertical space between consecutive items
 *
 * Properties:
 *
 *     itemCount (Number) - Current number of items
 *
 * Methods:
 *
 *     each - Takes a function and optional scope as arguments.
 *            Function args are:
 *                item - The current item,
 *                index - The current index,
 *                container - This container object
 *            Executes the function for each item, just like Ext.each.
 *
 *     getAt - Takes an index, returns the item at that index.
 */
Ext.define("Sms.container.AddRemove", {
	extend: "Ext.container.Container",
	alias:  "widget.smsaddremove",

	layout:     "vbox",
	shrinkWrap: true,

	// Set this to an object config in order to generate that object
	itemConfig:  null,

	// The amount
	itemSpacing: 5,

	initComponent: function(){
		var me = this;
		me.callParent();
		me.itemCount = me.indexCounter = 0;

		me.addItemFromConfig();
	},

	addItemFromConfig: function(){
		var me = this,
			baseId = me.id + "-item-" + me.indexCounter;

		me.add({
			xtype:      "container",
			layout:     "hbox",
			shrinkWrap: true,
			itemId:     baseId,
			margin:     me.itemCount ? me.itemSpacing + " 0 0 0" : 0,
			items: [
				me.itemConfig,
				{
					xtype:     "button",
					text:      me.itemCount ? "Remove" : "Add",
					margin:    "0 0 0 10",
					minWidth:  75,
					itemId:    baseId + "-btn",
					listeners: {
						click: me.itemCount ? me.onRemoveClick : me.onAddClick,
						scope: me
					}
				}
			]
		});

		me.itemCount++;
		me.indexCounter++;
	},

	onAddClick: function(){
		this.addItemFromConfig();
	},

	onRemoveClick: function(btn){
		var me = this,
			itemId = btn.itemId.slice(0, -4),
			item = me.down("#" + itemId);
		if(item){
			me.itemCount--;
			me.remove(item);
		}
	},
	
	removeAll: function(){
		var me = this,
			len = me.itemCount, i;
		for(i = len; i > 0; i--){
			me.itemCount--;
			me.remove(i - 1);
		}
		
		this.addItemFromConfig();
	},

	each: function(fn, scope){
		var me = this,
			items = me.items.items,
			len = me.itemCount, i;
		for(i = 0; i < len; i++){
			fn.call(scope, items[i].child(), i, me);
		}
	},

	getAt: function(index){
		return this.items.items[index].child();
	}
});
