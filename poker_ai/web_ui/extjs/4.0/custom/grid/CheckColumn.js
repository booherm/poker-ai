/*

This file is part of Ext JS 4

Copyright (c) 2011 Sencha Inc

Contact:  http://www.sencha.com/contact

GNU General Public License Usage
This file may be used under the terms of the GNU General Public License version 3.0 as published by the Free Software Foundation and appearing in the file LICENSE included in the packaging of this file.  Please review the following information to ensure the GNU General Public License version 3.0 requirements will be met: http://www.gnu.org/copyleft/gpl.html.

If you are unsure which license is appropriate for your use, please contact the sales department at http://www.sencha.com/contact.

*/
/**
 * @class Ext.ux.CheckColumn
 * @extends Ext.grid.column.Column
 * <p>A Header subclass which renders a checkbox in each column cell which toggles the truthiness of the associated data field on click.</p>
 * <p><b>Note. As of ExtJS 3.3 this no longer has to be configured as a plugin of the GridPanel.</b></p>
 * <p>Example usage:</p>
 * <pre><code>
// create the grid
var grid = Ext.create('Ext.grid.Panel', {
    ...
    columns: [{
           text: 'Foo',
           ...
        },{
           xtype: 'checkcolumn',
           text: 'Indoor?',
           dataIndex: 'indoor',
           width: 55
        }
    ]
    ...
});
 * </code></pre>
 * In addition to toggling a Boolean value within the record data, this
 * class adds or removes a css class <tt>'x-grid-checked'</tt> on the td
 * based on whether or not it is checked to alter the background image used
 * for a column.
 */
Ext.define('Ext.ux.CheckColumn', {
    extend: 'Ext.grid.column.Column',
    alias: 'widget.checkcolumn',
	
	disableColumn: false,
	disableFunction: null,
	disabledColumnDataIndex: null,
	columnHeaderCheckbox: false,
    displayFunction: null,

    constructor: function(config) {
		
		var me = this;
		if(config.columnHeaderCheckbox)
		{
			var store = config.store;
			store.on("datachanged", function(){
				me.updateColumnHeaderCheckbox(me);
			});
			store.on("update", function(){
				me.updateColumnHeaderCheckbox(me);
			});
			config.text = me.getHeaderCheckboxImage(store, config.dataIndex);
		}
		
        me.addEvents(
            /**
             * @event checkchange
             * Fires when the checked state of a row changes
             * @param {Ext.ux.CheckColumn} this
             * @param {Number} rowIndex The row index
             * @param {Boolean} checked True if the box is checked
             */
            'beforecheckchange',
			/**
             * @event checkchange
             * Fires when the checked state of a row changes
             * @param {Ext.ux.CheckColumn} this
             * @param {Number} rowIndex The row index
             * @param {Boolean} checked True if the box is checked
             */
            'checkchange'
        );
			
        me.callParent(arguments);
    },
	
	updateColumnHeaderCheckbox: function(column){
		var image = column.getHeaderCheckboxImage(column.store, column.dataIndex);
		column.setText(image);
	},
	
	toggleSortState: function(){
		var me = this;
		if(me.columnHeaderCheckbox)
		{
			var store = me.up('tablepanel').store;
			var isAllChecked = me.getStoreIsAllChecked(store, me.dataIndex);
			store.each(function(record){
				record.set(me.dataIndex, !isAllChecked);
				record.commit();
			});
		}
		else
			me.callParent(arguments);
	},
	
	getStoreIsAllChecked: function(store, dataIndex){
		var allTrue = true;
		store.each(function(record){
			if(!record.get(dataIndex))
				allTrue = false;
		});
		return allTrue;
	},
	
	getHeaderCheckboxImage: function(store, dataIndex){
		
		var allTrue = this.getStoreIsAllChecked(store, dataIndex);
			
		var cssPrefix = Ext.baseCSSPrefix,
            cls = [cssPrefix + 'grid-checkheader'];

        if (allTrue) {
            cls.push(cssPrefix + 'grid-checkheader-checked');
        }
        return '<div class="' + cls.join(' ') + '">&#160;</div>'
	},

    /**
     * @private
     * Process and refire events routed from the GridView's processEvent method.
     */
    processEvent: function(type, view, cell, recordIndex, cellIndex, e) {
        if (type == 'mousedown' || (type == 'keydown' && (e.getKey() == e.ENTER || e.getKey() == e.SPACE))) {
            var record = view.panel.store.getAt ? view.panel.store.getAt(recordIndex) : view.getRecord(e.getTarget(view.getItemSelector(), view.getTargetEl())),
                dataIndex = this.dataIndex,
                checked = !record.get(dataIndex),
				column = view.panel.columns[cellIndex];
            if(!(column.disableColumn || record.get(column.disabledColumnDataIndex) || (column.disableFunction && column.disableFunction(checked, record))))
			{
				if(this.fireEvent('beforecheckchange', this, recordIndex, checked, record))
				{
					record.set(dataIndex, checked);
					this.fireEvent('checkchange', this, recordIndex, checked, record);
				}
			}
            // cancel selection.
            return false;
        } else {
            return this.callParent(arguments);
        }
    },
			
	// Note: class names are not placed on the prototype bc renderer scope
    // is not in the header.
    renderer : function(value, metaData, record, rowIndex, colIndex, store, view){
		var disabled = "",
			column = view.panel.columns[colIndex];
		if(!column.displayFunction || (column.displayFunction && column.displayFunction(value, metaData, record, rowIndex, colIndex, store, view)))
		{
			if(column.disableColumn || column.disabledColumnDataIndex || (column.disableFunction && column.disableFunction(value, record)))
				disabled = "-disabled";
			var cssPrefix = Ext.baseCSSPrefix,
				cls = [cssPrefix + 'grid-checkheader' + disabled];

			if (value) {
				cls.push(cssPrefix + 'grid-checkheader-checked' + disabled);
			}
			return '<div class="' + cls.join(' ') + '">&#160;</div>';
		}
		return "";
    }
});

