/* took out the blank option from the config, please just add a blank entry to the store this field uses
 * if needed, create a new store just for this field, according to extjs forums, it is better to duplicate stores
 * than to just have one for multiple comboboxes
 */
Ext.define("Sms.form.ComboBox", {
	override: "Ext.form.field.ComboBox",//you can either use the original one or the sms namespace , both will be this extension
	
	listOptionCss: "border-color:#EEEEEE;border-width:1px;border-style:solid;",
	
	constructor: function(config){
		
		//the list config template here makes sure the row is correctly rendered for blank options
		config = Ext.applyIf(config, {
			selectOnFocus:   true,
			forceSelection:  true,
			queryMode:       "local",
			listConfig: {
				tpl: Ext.create("Ext.XTemplate",
					'<ul><tpl for=".">',
						'<li role="option" style="' + this.listOptionCss + '" class="' + Ext.baseCSSPrefix + 'boundlist-item">{[values.' + config.displayField + ' ? values.' + config.displayField + ' : "&nbsp;"]}</li>',
					'</tpl></ul>'
				)
			}
		});
		
		this.callParent(arguments);
	}
});

/* Creates a combobox for the months of the year
 *
 * Config options:
 *     valueField {String} Optional name to give the month number field (defaults to "month")
 *     displayField {String} Optional name to give the month name field (defaults to "monthName")
 *     blankOption {Boolean} Set true to include a blank entry (defaults to false)
 *     startMonth {Number/Boolean}
 *         If 0, uses current month (default).
 *         If 1 to 12, uses that month.
 *         If -1 to -12, uses that many months before current month (e.g. If March, -2 will use January)
 *         If false, uses either January or blank depending on blankOption
 */
Ext.define("Sms.form.MonthComboBox", {
	extend: "Ext.form.field.ComboBox",
	alias:  "widget.monthcombobox",
	noDefault: false,

	constructor: function(config){
		config = Ext.applyIf(config, {
			valueField:   "month",
			displayField: "monthName",
			blankOption:  false,
			startMonth:   0
		});

		this.callParent(arguments);
	},

	initComponent: function(){
		var me = this;

		me.store =  Ext.create("Ext.data.Store", {
			fields: [me.valueField, me.displayField],
			data:   me.createStoreData()
		});
		if(!me.value && !me.noDefault)
			me.value = me.getInitialValue();
		
		me.callParent();
	},

	createStoreData: function(){
		var me = this,
			mainArray = [],
			pushMonth,
			monthNum, monthName, i;

		pushMonth = function(num, name){
			var obj = {};
			obj[me.valueField] = num;
			obj[me.displayField] = name;
			mainArray.push(Ext.merge({}, obj));
		};

		if(me.blankOption){
			pushMonth("", "");
		}

		for(i = 0; i < 12; i++){
			monthNum = i + 1;
			monthName = Ext.Date.monthNames[i];
			pushMonth(monthNum, monthName);
		}

		return mainArray;
	},

	getInitialValue: function(){
		var me = this,
			startMonth = me.startMonth,
			blankOption = me.blankOption,
			currentDate = new Date(),
			monthNum;

		if(typeof startMonth === "number" && startMonth <= 12 && startMonth >= -11){
			if(startMonth === 0){
				monthNum = parseInt(Ext.Date.format(currentDate, "m"), 10);
			}
			else if(startMonth > 0){
				monthNum = startMonth;
			}
			else{
				monthNum = parseInt(Ext.Date.format(currentDate, "m"), 10) + startMonth;
				if(monthNum < 1){
					monthNum += 12;
				}
			}
		}
		else{
			monthNum = (blankOption) ? "" : 1;
		}

		return monthNum;
	}
});

/* Creates a combobox for a sequence of years
 *
 * Config options:
 *     valueField {String} Optional name to give the year value field (defaults to "year")
 *     displayField {String} Optional name to give the year display field (defaults to "yearName")
 *     startYear {Number} Earliest year in the list (defaults to 5 years before current year)
 *     endYear {Number} Latest year in the list (defaults to 5 years after current year)
 *     blankOption {Boolean} Set true to include a blank entry (defaults to false)
 *
 * The following options are prioritized. The first one found is used, the others are ignored
 *     defaultYear {Number} Sets the selected year if between startYear and endYear
 *     yearOffset {Number} Adds this number to the current year to get the selected year (defaultYear = currentYear + yearOffset)
 *     useCurrentYear {Boolean} If true, uses the current year. If false and blankOption is true, uses blank (defaults to true)
 */
Ext.define("Sms.form.YearComboBox", {
	extend: "Ext.form.field.ComboBox",
	alias:  "widget.yearcombobox",
	noDefault: false,

	constructor: function(config){
		config = Ext.applyIf(config, {
			valueField:     "year",
			displayField:   "yearName",
			blankOption:    false,
			useCurrentYear: true
		});

		this.callParent(arguments);
	},

	initComponent: function(){
		var me = this,
			currentYear = parseInt(Ext.Date.format(new Date(), "Y"), 10);

		if(!me.startYear){
			me.startYear = currentYear - 5;
		}
		if(!me.endYear){
			me.endYear = currentYear + 5;
		}
		me.currentYear = currentYear;

		me.store =  Ext.create("Ext.data.Store", {
			fields: [me.valueField, me.displayField],
			data:   me.createStoreData()
		});
		if(!me.value && !me.noDefault)
			me.value = me.getInitialValue();

		me.callParent();
	},

	createStoreData: function(){
		var me = this,
			mainArray = [],
			pushYear,
			i;

		pushYear = function(num, name){
			var obj = {};
			obj[me.valueField] = num;
			obj[me.displayField] = name;
			mainArray.push(Ext.merge({}, obj));
		};

		if(me.blankOption){
			pushYear("", "");
		}

		for(i = me.startYear; i <= me.endYear; i++){
			pushYear(i, i);
		}

		return mainArray;
	},

	getInitialValue: function(){
		var me = this,
			start = me.startYear,
			end = me.endYear,
			def = me.defaultYear,
			offset = me.yearOffest,
			curr = me.currentYear,
			offcurr = curr + offset,
			year;

		if(typeof def === "number" && def >= start && def <= end){
			year = def;
		}
		else if(typeof offset === "number" && offcurr >= start && offcurr <= end){
			year = offcurr;
		}
		else{
			year = (me.blankOption && me.useCurrentYear === false) ? "" : curr;
		}

		return year;
	}
});

//this currently only supports local mode stores
Ext.define("Sms.form.ComboBoxWithAddition", {
	extend: "Ext.form.field.ComboBox",//you can either use the original one or the sms namespace , both will be this extension
	alias:  "widget.comboboxwithaddition",
	newIndicatorField: null,
	newIndicatorFieldValue: true,
	
	constructor: function(config){
		
		config.forceSelection = true;
		this.callParent(arguments);
	},
	
	getSubTplMarkup: function() {
        var me = this,
            field = Ext.form.field.Text.prototype.getSubTplMarkup.call(me);

        return '<table id="' + me.id + '-triggerWrap" class="' + Ext.baseCSSPrefix + 'form-trigger-wrap" cellpadding="0" cellspacing="0"><tbody><tr>' +
            '<td id="' + me.id + '-inputCell" class="' + Ext.baseCSSPrefix + 'form-trigger-input-cell">' + field + '</td>' +
            me.getTriggerMarkup() +
			me.getAddItemButtonMarkUp() +
            '</tr></tbody></table>';
    },
	
	getAddItemButtonMarkUp: function(){
		var me = this;
		return "<td id='" + me.id + "-add-button' style='width:22px;'></td>";
	},
	
	afterRender: function(){
		var me = this;
		
		me.newEntryButton = Ext.create("Ext.button.Button", {
			iconCls:  "silk-add",
			height:   me.inputEl.getHeight() ? me.inputEl.getHeight() : 22,
			width:    22,
			tooltip:  "Add this as a new Entry",
			renderTo: me.id + "-add-button",
			handler:  function(){
				me.addItemToList.call(me);
			}
		});
		
		Ext.get(me.id + "-add-button").hide();
		
		me.on("select", me.onFilter);
		
		me.callParent(arguments);
	},
	
	onFilter: function(){
		var me = this;
		me.figureButtonDisplay();
	},
	
	onChange: function(){
		var me = this;
		me.figureButtonDisplay();
		me.callParent();
	},
	
	figureButtonDisplay: function(){
		var me = this,
			addButtonContainer = Ext.get(me.id + "-add-button");
			
		if(addButtonContainer)
		{
			if(me.getValue() && (me.getStore().findExact(me.displayField, me.getValue()) == -1))
				addButtonContainer.show();
			else
				addButtonContainer.hide();
		}
	},
	
	doQuery: function(){
		var me = this,
			isLocalMode = me.queryMode === 'local';
		me.callParent(arguments);
		if(isLocalMode && me.callParent(arguments))
		{
			me.onFilter();
			return true;
		}
		return false;
	},
	
	addItemToList: function(){
		var me = this,
			newValue = me.getValue(),
			store = me.getStore();
			
		var newRecordConfig = {};
		newRecordConfig[me.valueField] = newValue;
		newRecordConfig[me.displayField] = newValue;
		if(me.newIndicatorField)
			newRecordConfig[me.newIndicatorField] = me.newIndicatorFieldValue;
			
		store.add(newRecordConfig);
		
		me.setValue(newValue);
		
		me.onFilter();
	}
});