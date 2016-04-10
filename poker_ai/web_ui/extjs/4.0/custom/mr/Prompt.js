Ext.namespace("MrPrompt");

// Store for the prompt variable window.
MrPrompt.variableStore = new Ext.data.ArrayStore({
	storeId: "promptvarstore",
	fields:  ["variable_name", "prompt_type", "description"],
	data:    [
		["[SMS_VAR_CURRENT_DATE]",				"DATE",  "Get date value of the current date relative to run date of the report."],
		["[SMS_VAR_CURRENT_FISCAL_YEAR]",		"YEAR",  "Get date value of the current fiscal year relative to run date of the report."],
		["[SMS_VAR_CURRENT_MONTH]",				"MONTH", "Get date value of the current month relative to run date of the report."],
		["[SMS_VAR_CURRENT_MONTH_FIRST_DAY]",	"DATE",	 "Get date value of the first date of the current month relative to run date of the report."],
		["[SMS_VAR_CURRENT_YEAR]",				"YEAR",  "Get date value of the current year relative to run date of the report."],
		["[SMS_VAR_PREV_BUS_DATE]",				"DATE",  "Get date value of the previous business day relative to run date of the report."],
		["[SMS_VAR_PREV_WEEK_DATE]",			"DATE",  "Get date value one week prior to run date of the report."],
		["[SMS_VAR_PREV_TWO_WEEKS_DATE]",		"DATE",  "Get date value two weeks prior to run date of the report."],
		["[SMS_VAR_PREV_MONTH_DATE]",			"DATE",  "Get date value one month prior to run date of the report."],
		["[SMS_VAR_PREV_MONTH]",				"MONTH", "Get date value of the previous month relative to run date of the report."],
		["[SMS_VAR_PREV_MONTH_YEAR]",			"YEAR",  "Get date value of the previous month's year relative to run date of the report."]
	]
});

// This is the prompt variable window used by the MrScheduler.
MrPrompt.variableWindow = new Ext.window.Window({
	title:       "Variables",
	layout:      "fit",
	closeAction: "hide",
	width:       685,
	resizable:   false,
	constrain:   true,
	hideMode:    "display",
	items:       [{
		xtype:              "grid",
		store:              "promptvarstore",
		header:             false,
		disableSelection:   true,
		enableColumnMove:   false,
		enableColumnHide:   false,
		enableColumnResize: false,
		sortableColumns:    false,
		viewConfig: {
			trackOver: false
		},
		columns: [
			{
				xtype:        "templatecolumn",
				text:         "Variable Name",
				width:        235,
				menuDisabled: true,
				tpl: [
					'<a href="javascript:void(0)" onclick="MrPrompt.variableWindow.selectVar(\'{variable_name}\'); return false;">',
						'{variable_name}',
					'</a>',
					{disableFormats: true}
				]
			},
			{
				dataIndex:    "description",
				text:         "Description",
				flex:         1,
				menuDisabled: true
			}
		]
	}],

	bindPromptValueField: function(pvf){
		this.promptValueField = pvf;
	},

	unbindPromptValueField: function(){
		this.promptValueField = null;
	},

	// pvf is the PromptValueField that opened the window
	showByTypeAtPos: function(x, y, pvf){
		var me = this,
			store = me.down("grid").getStore();

		me.bindPromptValueField(pvf);
		store.clearFilter(true);
		store.filter("prompt_type", pvf.promptType);

		// Taken from Ext.Component#showAt, so we can animate from pvf
		if(!me.rendered && (me.autoRender || me.floating)){
			me.doAutoRender();
			me.hidden = true;
		}
		me.setPosition(x, y);
		me.show(pvf);
	},

	selectVar: function(type){
		var me = this;

		me.promptValueField.setPromptVariable(type);
		me.hide(me.promptValueField);
		me.unbindPromptValueField();
	}
});

Ext.apply(MrPrompt, {
	specialChars: [
		["@", "&#64;"],
		["|", "&#124;"],
		[",", "&#44;"]
	],
	encode: function(str){
		return MrPrompt.processSpecialChars(str, 0, 1);
	},
	decode: function(str){
		return MrPrompt.processSpecialChars(str, 1, 0);
	},
	processSpecialChars: function(str, j, k){
		var out = str,
			regex;
		if(!str){
			return str;
		}
		Ext.each(MrPrompt.specialChars, function(charArray){
			regex = new RegExp(Ext.String.escapeRegex(charArray[j]), "g");
			out = out.replace(regex, charArray[k]);
		});
		return out;
	}
});

// Basic container for prompts. Uses the Ext.form.field.Field mixin to make
// itself available to the parent form, and uses submitValue=false to prevent
// child fields from sending their own values on form submit.
Ext.define("MrPrompt.PromptField", {
	extend: "Ext.form.FieldContainer",
	alias:  "widget.promptfield",
	mixins: {
		field: "Ext.form.field.Field"
	},

	labelWidth:  0,  // Not needed, see getLabelCellAttrs function
	labelStyle:  "font-weight:bold;white-space:nowrap;margin-top:3px",
	labelAlign:  "right",

	shrinkWrap:  true,
	defaultType: "promptfieldrow",

	// Extra identifier on label if prompt is required
	requiredPrefix: "* ",

	initComponent: function(){
		var me = this,
			defaultConfig = {
				submitValue: false
			};

		// Reassign config properties to component properties
		me.fieldLabel = (me.isRequired ? me.requiredPrefix : "") + me.promptLabel;
		me.id = "prompt_field_" + me.formatPromptId(me.promptId);
		me.name = "prompt_values_" + me.promptNumber;
		me.value = me.defaultValue;

		// Make sure all the initial prompt configurations get passed to children
		Ext.apply(defaultConfig, me.initialConfig);
		me.fieldDefaults = me.defaults = defaultConfig;
		me.fieldDefaults.fieldDefaults = me.defaults.defaults = defaultConfig;

		// Each prompt field needs to provide two values to the form submission:
		// 1) Prompt values input by the user, AND
		// 2) Prompt ID
		// Rather than count up the prompt fields and add them as extra params
		// when calling form.submit, just create them as hidden inputs here.
		me.items = [{
			xtype:       "hiddenfield",
			name:        "prompt_id_" + me.promptNumber,
			value:       me.promptId,
			hidden:      true,  // Component isn't actually hidden by default
			submitValue: true   // Overrides default
		}];
	
		if(me.bypassCollector){
			// Don't display on UI. Just pass the value along.
			me.hidden = true;
		}
		else{
			// Finish configuring the field container based on prompt type
			MrPrompt.initPromptFieldByType(me);
		}

		me.callParent();
		me.initField();
	},

	// Strips off "[" and "]"
	formatPromptId: function(promptId){
		return promptId.slice(1, -1).toLowerCase();
	},

	// Excludes the labelWidth from the labelableRenderTpl, so our table cells
	// use auto-width and size themselves correctly.
	getLabelCellAttrs: function(){
		var me = this,
			result = "valign='top' halign='" + me.labelAlign + "'"
				+ " class='" + Ext.baseCSSPrefix + "field-label-cell'";
		return result;
	},

	// Fixes a bug where adding a labelable field triggers a label update, but
	// the field container forgets to include the separator.
	updateLabel: function(){
		var me = this,
			label = me.labelEl;
		if(label){
			me.setFieldLabel(me.getFieldLabel());
		}
	},

	getDelimiter: function(){
		var me = this;
		return me.promptConfig.valueDelimiter || ",";
	},

	getValue: function(){
		var me = this,
			data, delim;

		if(me.bypassCollector){
			return me.value;
		}

		data = me.getPromptValueData();
		delim = me.getDelimiter();
		return Ext.Array.pluck(data, "value").join(delim);
	},

	/**
	 * Returns an array of objects describing various properties of the prompt.
	 * All empty values are excluded from the array. The returned properties include:
	 * - id - The prompt ID
	 * - type - The prompt type
	 * - number - The index number of the prompt in the report's prompt list
	 * - value - The value of the prompt
	 * - isVariable - True if the prompt is a variable prompt, false otherwise
	 *
	 * @return {Array} The prompt values (or an empty array if no values are present).
	 */
	getPromptValueData: function(){
		var me = this,
			promptId = me.promptId,
			promptNumber = me.promptNumber,
			promptType = me.promptType,
			promptData = [];

		// If there's no field to get input from, take whatever default value was provided.
		if(me.bypassCollector || !me.promptConfig){
			if(!Ext.isEmpty(me.value)){
				promptData.push({
					id:         promptId,
					type:       promptType,
					number:     promptNumber,
					value:      me.value,
					isVariable: false
				});
			}
			return promptData;
		}

		var splitToArray = (me.isMultiple && !me.promptConfig.showAddRemoveButtons),
			asSingleValue = me.promptConfig.asSingleValue,
			delim = me.getDelimiter(),
			values = [],
			tempArray = [],
			isVariable, value;

		// Iterate over each prompt row, accumulating the values into a single array
		Ext.each(me.query("[isPromptFieldRow]"), function(row){
			value = row.getSubmitValue();
			isVariable = row.isPromptVariable();

			// Since any value in a prompt could be a variable, pair values and
			// isVariable flags together.
			if(splitToArray){
				// Create array of values with special characters encoded
				tempArray = Ext.Array.map(value.split(delim), MrPrompt.encode, MrPrompt);
				Ext.each(tempArray, function(val){
					values.push({
						value: val,
						isVar: isVariable
					});
				});
			}
			else{
				values.push({
					value: MrPrompt.encode(value),
					isVar: isVariable
				});
			}
		});

		//  Combine multiple values into a single-element array using the prompt delimiter
		if(asSingleValue){
			tempArray = Ext.Array.clean(Ext.Array.pluck(values, "value"));
			values = [{
				value: tempArray.join(delim),
				isVar: false
			}];
		}

		// Create the prompt descriptors for each non-empty value.
		tempArray = Ext.Array.filter(values, function(valueObj){
			return !Ext.isEmpty(valueObj.value);
		});
		promptData = Ext.Array.map(tempArray, function(valueObj){
			return {
				id:         promptId,
				type:       promptType,
				number:     promptNumber,
				value:      valueObj.value,
				isVariable: valueObj.isVar
			};
		});

		return promptData;
	}
});

Ext.define("MrPrompt.PromptFieldRow", {
	extend: "Ext.form.FieldContainer",
	alias:  "widget.promptfieldrow",

	shrinkWrap: true,
	layout:     {
		type: "hbox",
		defaultMargins: {
			right:  10
		}
	},
	
	/**
	 * @cfg {Object} startField (required)
	 * A field component to place at the beginning of the prompt row.
	 * Should have getValue, setValue, and markInvalid methods.
	 * The itemId of the object will be overridden to "startField"
	 */
	startField: null,
	
	/**
	 * @cfg {Object} endField
	 * A field component to place at the end of the prompt row.
	 * The itemId of the object will be overridden to "endField"
	 */
	endField: null,

	// Should only be true on report scheduler when prompt has variables to use
	showPromptVariableField: false,

	// Should only be true on prompts that use multiple input fields
	showAddRemoveButtons: false,

	// Identifies this class and all subclasses as prompt field rows
	isPromptFieldRow: true,
	
	initComponent: function(){
		var me = this;

		// Make sure "N" and "Y" are properly converted to booleans
		if(me.fromAddButton){
			me.isVariable = false;
		}
		else if(typeof me.isVariable === "string"){
			me.isVariable = (me.isVariable === "Y");
		}

		me.items = [
			Ext.apply(me.startField, {
				itemId:     "startField",
				value:      !me.isVariable ? me.value : undefined,
				msgTarget:  "side",
				allowBlank: !me.isRequired,
				listeners:  {
					change: MrPrompt.onchange
				}
			})
		];

		if(me.showPromptVariableField){
			me.items.push({
				xtype:       "promptvarfield",
				itemId:      "promptVarField",
				value:       me.isVariable ? me.value : undefined,
				hasVariable: me.isVariable
			});
		}

		if(me.showAddRemoveButtons){
			me.items.push({
				xtype:   "addremovebutton",
				itemId:  "addRemoveBtn",
				initial: me.initial
			});
		}

		if(me.endField){
			me.items.push(
				Ext.apply(me.endField, {
					itemId: "endField"
				})
			);
		}
		
		if (me.description) {
			me.items.push(
			{
				xtype: "component",
				html: "<img data-qtip=\"" + me.promptLabel +" Prompt Help" + "\" src=\"extjs\\4.0\\sms\\icons\\fam\\information.png\"/>",
				width: 10,
				listeners: {
					afterrender: function(component) {
						component.getEl().on("click", function(e) {	
							if (!me.promptEngDescWindow)
							{
								me.promptEngDescWindowContent = Ext.create("Ext.form.Label", {
									header:   false,
									region:   "center",
									margin:   "10 10 10 0",
									defaults: {
										bodyStyle: {
											padding:  "4px",
											fontSize: "9pt"
										}
									}
								});
								me.promptEngDescWindow = Ext.create("Ext.window.Window", {
									title:       "Definition",
									closeAction: "hide",
									layout:      "auto",
									items:       [me.promptEngDescWindowContent]
								});
							}
							me.promptEngDescWindowContent.setText(me.description.split("\\n").join("<br/>"), false);
							me.promptEngDescWindow.showAt(e.getX(), e.getY());
						});
					}
				}
			});
		}
		me.callParent();
	},

	getSubmitValue: function(){
		var me = this,
			value = (me.showPromptVariableField)
				? me.down("#promptVarField").getValue() || me.down("#startField").getSubmitValue()
				: me.down("#startField").getSubmitValue();
		return value;
	},

	isPromptVariable: function(){
		var me = this;
		if(!me.showPromptVariableField){
			return false;
		}
		return me.down("#promptVarField").hasVariable;
	}
});

Ext.define("MrPrompt.AddRemoveButton", {
	extend: "Ext.button.Button",
	alias:  "widget.addremovebutton",

	width:      75,
	addText:    "Add",
	removeText: "Remove",
	initial:    true,
	tabIndex:   -1,

	initComponent: function(){
		var me = this;
		me.text = me.initial ? me.addText : me.removeText;
		me.handler = me.initial ? me.addRow : me.removeRow;
		me.callParent();
	},

	addRow: function(me){
		var promptField = me.up("promptfield"),
			newPromptCfg = Ext.apply({
				initial:       false,
				fromAddButton: true
			}, promptField.promptConfig);

		promptField.add(newPromptCfg);
		promptField.updateLabel();
	},

	removeRow: function(me){
		var promptFieldRow = me.up("[isPromptFieldRow]"),
			promptField = promptFieldRow.up("promptfield");
		promptField.remove(promptFieldRow);
		MrPrompt.onchange();
	}
});

Ext.define("MrPrompt.PromptVariableField", {
	extend: "Ext.container.Container",
	alias:  "widget.promptvarfield",

	layout:     "hbox",
	shrinkWrap: true,

	hasVariable:     false,
	promptComponent: null,

	initComponent: function(){
		var me = this,
			isHidden = !me.hasVariable;

		me.items = [
			{
				xtype:      "displayfield",
				itemId:     "variableField",
				value:      me.value,
				hidden:     isHidden,
				fieldStyle: "font-size:12px;line-height:15px"
			},
			{
				xtype:   "button",
				itemId:  "openButton",
				width:   22,
				iconCls: "silk-wrench",
				tooltip: "Open the prompt variable window",
				margin:  "0 0 0 10",
				handler: me.onOpenButtonClick
			},
			{
				xtype:   "button",
				itemId:  "revertButton",
				width:   22,
				iconCls: "silk-table-go",
				tooltip: "Revert back to normal input",
				margin:  "0 0 0 2",
				hidden:  isHidden,
				handler: me.onRevertButtonClick
			}
		];

		me.listeners = {
			afterrender: {
				single: true,
				fn:     function(me){
					var parent = me.up("[isPromptFieldRow]"),
						cmp = parent.down("#startField");
					me.promptComponent = cmp;
					if(me.hasVariable){
						me.hidePromptComponent();
					}
				}
			}
		};

		me.callParent();
	},

	onOpenButtonClick: function(btn, evt){
		var promptVarField = btn.up("promptvarfield"),
			xPos = evt.getX() + 16,
			yPos = evt.getY() + 16;
		MrPrompt.variableWindow.showByTypeAtPos(xPos, yPos, promptVarField);
	},

	onRevertButtonClick: function(btn){
		var me = btn.up("promptvarfield"),
			variableField = me.down("#variableField"),
			revertButton = btn;

		variableField.hide();
		me.showPromptComponent();
		revertButton.hide();
		
		me.hasVariable = false;
		MrPrompt.onchange();
	},

	setPromptVariable: function(type){
		var me = this,
			variableField = me.down("#variableField"),
			revertButton = me.down("#revertButton");

		me.hidePromptComponent();
		variableField.show();
		variableField.setValue(type);
		revertButton.show();
		
		me.hasVariable = true;
		MrPrompt.onchange();
	},

	getValue: function(){
		var me = this;
		return me.hasVariable ? me.down("#variableField").getValue() : null;
	},

	hidePromptComponent: function(){
		var me = this;
		me.promptComponent.disable();
		me.promptComponent.hide();
	},

	showPromptComponent: function(){
		var me = this;
		me.promptComponent.show();
		me.promptComponent.enable();
	}
});

Ext.define("MrPrompt.prompt.SelectPrompt", {
	extend: "Ext.container.Container",
	alias:  "widget.selectprompt",

	shrinkWrap: true,
	layout:     "hbox",

	initComponent: function(){
		var me = this,
			store = Ext.data.StoreManager.lookup(MrPrompt.getPromptStoreId(me.promptNumber)),
			itemConfig = {
				itemId:        "inputField",
				store:         store,
				valueField:    "value_field",
				displayField:  "display_field",
				width:         me.width,
				msgTarget:     "side",
				autoFitErrors: false,
				allowBlank:    !me.isRequired
			},
			value, size;

		delete me.listeners;

		// If isMulti, make an itemselector. Else, make a combobox
		if(me.isMultiple){
			// To make sure "allowBlank" can work right, we have to send "undefined"
			// if the field has no default value (converts to empty array). An array with
			// a single empty string counts has having a value and doesn't validate correctly.
			value = me.defaultValue.split(",");

			// If the store has less items than the list size, fit the list to the data.
			size = Math.min(me.listSize || 10, store.getCount());
			
			var defaultConfiguration = {
				xtype:    "promptitemselector",
				width:    (itemConfig.width * 2) + 30,
				listSize: size,
				value:    (!!value[0]) ? value : undefined
			};
			
			if((store && store.getCount() > 15) && itemConfig.width >= 180)
			{
				defaultConfiguration.searchBoxConfig = {
					width: itemConfig.width - 85,
					plugins: new Ext.ux.form.field.ClearButton({animateClearButton: false, hideClearButtonWhenMouseOut: false})
				};
			}

			Ext.apply(itemConfig, defaultConfiguration);
		}
		else{
			// Insert blank record into store to allow empty value
			if(!me.isRequired){
				store.insert(0, {
					prompt_type:   me.promptType,
					prompt_number: me.promptNumber,
					value_field:   "",
					display_field: "",
					sort_order:    0
				});
			}
            
			Ext.apply(itemConfig, {
				xtype: "combobox",
				value: store.findRecord("value_field", me.defaultValue, 0, false, true, true) || store.getAt(0),
				listeners: {
					select: me.onFieldChange
				}
			});
		}

		me.items = [itemConfig];
		me.width = itemConfig.width + 20;  // Leave extra space for errorEl

		// Wait for the fields to exist before loading the end field
		me.on("afterlayout", me.updateEndField, me, {single: true});

		me.callParent();
	},

	getSubmitValue: function(){
		var me = this,
			value = me.down("#inputField").getValue();
		return Ext.isArray(value) ? value.join(",") : value;
	},

	onFieldChange: function(field){
		MrPrompt.onchange();
		if(field.rendered){
			field.up("selectprompt").updateEndField();
		}
	},

	updateEndField: function(){
        me = this;
        if(me.up("[isPromptFieldRow]").down("#endField") && me.up("[isPromptFieldRow]").down("#endField").xtype === "displayfield"){
            var me = this,
                selectedRec = me.down("#inputField").findRecord("value_field", me.down("#inputField").getValue()),
                nameField = me.up("[isPromptFieldRow]").down("#endField");

            nameField.setValue(selectedRec.get("data_field_1"));
        }
	}
});

Ext.define("MrPrompt.prompt.CustomerLookup", {
	extend: "Ext.container.Container",
	alias:  "widget.customerlookupprompt",

	shrinkWrap: true,
	layout:     "hbox",

	initComponent: function(){
		var me = this,
			store = me.initStore(),
			defaultValue, initialIdType, initialId;

		if(me.value && me.value.indexOf("=") !== -1){
			defaultValue = me.value.split("=");
			initialIdType = defaultValue[0];
			initialId = defaultValue[1];
		}

		delete me.listeners;

		me.items = [
			{
				xtype:        "combobox",
				itemId:       "idTypeField",
				store:        store,
				valueField:   "id_type",
				displayField: "description",
				value:        initialIdType || store.getAt(0),
				width:        150,
				margin:       "0 10 0 0",
				listeners:    {
					change: me.onFieldChange
				}
			},
			{
				xtype:             "textfield",
				itemId:            "idField",
				msgTarget:         "side",
				width:             125,
				value:             initialId || "",
				allowBlank:        !me.isRequired,
				checkChangeBuffer: 500,
				validator:         me.validateCustomer,
				listeners:         {
					change: me.onFieldChange
				}
			},
			{
				xtype:      "button",
				itemId:     "lookupButton",
				iconCls:    "silk-magnifier",
				style:      "background-image:none;border-style:none;margin-top:2px",
				tooltip:    "Customer Search",
				overCls:    "",
				pressedCls: "",
				handler:    me.onShowCustomerWindow
			}
		];

		// Wait for the fields to exist before loading the customer name
		if(initialId){
			me.on("afterlayout", me.updateCustomerName, me, {single: true});
		}

		me.callParent();
	},

	onFieldChange: function(field){
		MrPrompt.onchange();
		if(field.rendered){
			field.up("customerlookupprompt").updateCustomerName();
		}
	},

	showCustomerLookupWindow: function(win){
		var me = this,
			idTypeField = me.down("#idTypeField"),
			idField = me.down("#idField"),
			nameField = me.up("[isPromptFieldRow]").down("#endField");

		win.callback = function(custName, custId, custType){
			nameField.setRawValue(custName);
			idField.setRawValue(custId);

			idTypeField.suspendEvents();
			idTypeField.setValue(custType);
			idTypeField.resumeEvents();
		};

		win.setExclusions(me.excludeList);
		win.show(nameField.getValue(), idField.getValue(), idTypeField.getValue());
	},

	onShowCustomerWindow: function(btn){
		var me = btn.up("customerlookupprompt");
		if(!MrPrompt.customerLookupWindow){
			MrPrompt.customerLookupWindow = new Sms.customer.Window();
		}
		me.showCustomerLookupWindow(MrPrompt.customerLookupWindow);
	},

	initStore: function(){
		var me = this,
			extraAttrs = me.extraAttributes,
			excludeList = me.excludeList = extraAttrs ? extraAttrs.split(",") : [],
			data = [],
			sourceStore = Ext.data.StoreManager.lookup(MrPrompt.getPromptStoreId(me.promptNumber)),
			targetStore;

		sourceStore.data.each(function(record){
			var idType = record.get("value_field");
			if(!Ext.Array.contains(excludeList, idType)){
				data.push([idType, record.get("display_field")]);
			}
		});

		targetStore = new Ext.data.ArrayStore({
			fields: ["id_type", "description"],
			data:   data
		});

		return targetStore;
	},

	validateCustomer: function(customerId){
		var idField = this;
		
		// Only run this validator if we're actually submitting data
		if(!MrPrompt.submitValidation || (!idField.allowBlank && customerId.length < 1)){
			return true;
		}

		var me = idField.up("customerlookupprompt"),
			isValid = true;

		Sms.Ajax.request({
			async:    false,
			url:      "lu_customer_data.jsp",
			dataType: "json",
			data:     {
				context:       "VALIDATE_CUSTOMERS",
				employee_id:   MrPrompt.employeeId,
				customer_list: me.getSubmitValue()
			},
			success:  function(data){
				if(data.length){
					isValid = "You do not have permission to view this customer";
				}
			},
			error:    function(){
				Ext.Msg.alert("Error", "An error occurred while validating data.");
				isValid = "Could not validate customer ID";
			}
		});

		return isValid;
	},

	updateCustomerName: function(){
		var me = this,
			idType = me.down("#idTypeField").getValue(),
			custId = me.down("#idField").getValue(),
			nameField = me.up("[isPromptFieldRow]").down("#endField");

		if(!custId || !idType){
			nameField.setValue("");
			return;
		}

		nameField.setValue("Searching...");
		Sms.Ajax.request({
			url:      "lu_customer_data.jsp",
			dataType: "json",
			data:     {
				context:          "CUSTOMER_LOOKUP",
				customer_id:      custId,
				customer_id_type: idType
			},
			success: function(json){
				nameField.setValue(json["customer_name"] || "Customer Not Found");
			},
			error:   function(){
				nameField.setValue("Customer Not Found");
			}
		});
	},

	getSubmitValue: function(){
		var me = this,
			idTypeField = me.down("#idTypeField"),
			idField = me.down("#idField"),
			idType = idTypeField.getValue(),
			custId = idField.getValue();

		if(!idType || !custId){
			return "";
		}
		return idType + "=" + custId;
	}
});

Ext.define("MrPrompt.prompt.PayerLookup", {
	extend: "Ext.container.Container",
	alias:  "widget.payerlookupprompt",

	shrinkWrap: true,
	layout:     "hbox",

	initComponent: function(){
		var me = this;

		delete me.listeners;

		me.items = [
			{
				xtype:             "textfield",
				itemId:            "idField",
				msgTarget:         "side",
				width:             125,
				value:             me.value,
				maxLength:         50,
				allowBlank:        !me.isRequired,
				checkChangeBuffer: 500,
				listeners:         {
					change: me.onFieldChange
				}
			},
			{
				xtype:      "button",
				itemId:     "lookupButton",
				iconCls:    "silk-magnifier",
				style:      "background-image:none;border-style:none;margin-top:2px",
				tooltip:    "Customer Search",
				overCls:    "",
				pressedCls: "",
				handler:    me.onShowPayerWindow
			}
		];

		if(me.value){
			me.on("afterlayout", me.updatePayerName, me, {single: true});
		}

		me.callParent();
	},

	onFieldChange: function(field){
		MrPrompt.onchange();
		if(field.rendered){
			field.up("payerlookupprompt").updatePayerName();
		}
	},

	onShowPayerWindow: function(btn){
		var me = btn.up("payerlookupprompt");
		if(!MrPrompt.payerLookupWindow){
			MrPrompt.payerLookupWindow = Ext.create("Sms.payer.LookupWindow", {});
		}
		me.showPayerLookupWindow(MrPrompt.payerLookupWindow);
	},

	showPayerLookupWindow: function(win){
		var me = this,
			idField = me.down("#idField"),
			nameField = me.up("[isPromptFieldRow]").down("#endField");
		var currentName = nameField.getValue();
		currentName = (currentName === "Payer Not Found.") ? "" : currentName;

		win.setCallback(function(model){
			nameField.setRawValue(model.get("payer_name"));
			idField.setRawValue(model.get("cpid"));
		});

		//win.setExclusions(me.excludeList);
		win.show({
			cpid:       idField.getValue(),
			payer_name: currentName
		});
	},

	updatePayerName: function(){
		var me = this,
			cpid = me.down("#idField").getValue(),
			nameField = me.up("[isPromptFieldRow]").down("#endField");

		if(!cpid){
			nameField.setValue("");
			return;
		}

		nameField.setValue("Searching...");
		Sms.payer.lookupName({
			cpid: cpid,
			success: function(response, opts){
				//make sure we only update the form with the latest request
				var obj = Ext.decode(response.responseText);
				nameField.setValue(obj.payer_name);
			},
			failure: function(response, opts) {
				alert("server-side failure with status code " + response.status);
			}
		});
	},

	getSubmitValue: function(){
		var me = this,
			idField = me.down("#idField"),
			cpid = idField.getValue();

		if(!cpid){
			return "";
		}
		return cpid;
	}
});

Ext.define("MrPrompt.prompt.ProjectLookup", {
	extend: "Ext.container.Container",
	alias:  "widget.projectlookupprompt",

	shrinkWrap:   true,
	layout:       "hbox",
	projectStore: null,

	initComponent: function(){
		var me = this;
		delete me.listeners;
		var value = me.value;
		
		if(!MrPrompt.prompt.ProjectLookupModel)
		{
			Ext.define("MrPrompt.prompt.ProjectLookupModel", {
				extend: "Ext.data.Model",
				fields: [
					{name:"item_id",   type:"string"},
					{name:"item_name", type:"string"},
					{name:"path_text", type:"string"}
				]
			});
		}
		
		me.projectStore = Ext.create("Ext.data.ArrayStore", {
			model: "MrPrompt.prompt.ProjectLookupModel",
			data:  value ? value : []
		});

		me.items = [
			{
				xtype:     "displayfield",
				itemId:    "projectList",
				value:     me.getProjectDisplay(),
				width:     500,
				margin:    "0 5 0 0"
			},
			{
				xtype:     "textfield",
				hidden:    true,
				validator: function(){
					return me.validateProjects(me);
				},
				listeners: {
					validityChange: function(thisField, isValid){
						if(isValid)
							me.down("#projectList").clearInvalid();
						else
							me.down("#projectList").markInvalid("This field is required");
					}
				}
			},
			{
				xtype:   "button",
				text:    "Add/Remove Projects",
				hidden:  !me.isMultiple,
				handler: me.onShowProjectWindow
			},
			{
				xtype:   "button",
				text:    "Add Project",
				hidden:  me.isMultiple,
				handler: me.onShowProjectWindow
			},
			{
				xtype:   "button",
				text:    "Remove Project",
				margin:  "0px 0px 0px 10px",
				hidden:  me.isMultiple,
				handler: me.onRemoveProject
			}
		];

		me.callParent();
	},
	
	updateProjectDisplay: function(){
		var me = this;
		me.down("#projectList").setValue(me.getProjectDisplay());
		me.doLayout();
	},
	
	getProjectDisplay: function(){
		var me = this;
		var projectsDisplay = "<table style='table-layout:fixed;display:inline;' width='460px'>";
		me.projectStore.sort("item_name", "ASC");
		me.projectStore.each(function(record){
			projectsDisplay += "<tr><td width='400px'><a onclick='Sms.viewPmItem(\"" + record.get("item_id") + "\")'"
				+ " style='font-weight:bold;color:#1F497D;cursor:pointer;text-decoration:underline;' onmouseover='this.style.color=\"#F79646\";' onmouseout='this.style.color=\"#1F497D\";' title=\"" + record.get("item_name") + "\">" + record.get("item_name")
				+ "</a></td></tr>";
		});
		if(me.projectStore.getCount() === 0)
			projectsDisplay += "<tr><td width='400px'>&nbsp;</td><tr>";
		projectsDisplay += "</table>";
		return projectsDisplay;
	},

	onShowProjectWindow: function(btn){
		var me = btn.up("projectlookupprompt");
		if(!MrPrompt.projectLookupWindow){
			MrPrompt.projectLookupWindow = Ext.create("Sms.projectDependency.Window", {
				title:              "Project Chooser",
				itemIdFieldName:    "item_id",
				pathTextFieldName:  "path_text",
				textFieldName:      "item_name",
				viewStore:          MrPrompt.projectViewStore,
				defaultViewId:      "1",
				isDependencyWindow: false,
				draggableItemTypes: ["PROJECT"]
			});
		}
		MrPrompt.projectLookupWindow.setMultiSelect(me.isMultiple);
		MrPrompt.projectLookupWindow.setCallBack(function(models){
			var loadData = [];
			for(var i = 0; i < models.length; i++)
			{
				var singleItem = [
					models[i].get("id"),
					models[i].get("node_name"),
					models[i].get("item_path")
				];
				loadData.push(singleItem);
			}
			me.projectStore.loadData(loadData);
			me.updateProjectDisplay();
			me.down("#projectList").clearInvalid();
		});
		MrPrompt.projectLookupWindow.show(null, me.projectStore.getRange());
	},
	
	onRemoveProject: function(btn) {
		var me = btn.up("projectlookupprompt");
		me.projectStore.removeAll();
		me.updateProjectDisplay();
		if(!me.isRequired)
		   me.down("#projectList").clearInvalid();
	},

	validateProjects: function(encompassingField){
		if(!encompassingField.allowBlank && encompassingField.projectStore.getCount() < 1)
			return false;
		return true;
	},

	updateProjectNames: function(){
		// Make an Ajax request to get the project names, or something
	},

	getSubmitValue: function(){
		var me = this;
		return me.projectStore.collect("item_id").join(",");
	}
});

Ext.define("MrPrompt.prompt.CustomerViewCustLookup", {
	extend: "Ext.container.Container",
	alias:  "widget.customerviewcustlookupprompt",

	shrinkWrap: true,
	layout:     "hbox",

	initComponent: function(){
		var me = this,
			store = me.store,
			initial = me.initial,
			initialIdType = me.initialIdType, 
			initialId = me.initialId,
			disabledFlag = me.disabledFlag,
			hideCustTypes = me.store.getCount() <= 1;
	
		delete me.listeners;

		me.items = [
			{
				xtype:        "combobox",
				itemId:       "idTypeField",
				store:        store,
                fieldLabel:   "Other Customer ID(s)",
                labelCls:     "x-form-item-label x-form-item-label-right",
                labelStyle:   "margin-right:5px;font-weight:bold;",
                labelWidth:   130,
				valueField:   "view_id",
				displayField: "description",
				value:        initialIdType || store.getAt(0),
				width:        300,
				margin:       "0 10 10 0",
				disabled:     disabledFlag,
				hidden:       hideCustTypes,
				listeners:    {
					change: me.onFieldChange
				}
			},
			{
				xtype:             "textfield",
				itemId:            "idField",
				msgTarget:         "side",
				width:             125,
				value:             initialId || "",
				checkChangeBuffer: 500,
				disabled:          disabledFlag,
				validator:         me.validateCustomer,
				listeners:         {
					change: me.onFieldChange
				}
			},
			{
				xtype:      "button",
				itemId:     "lookupButton",
				iconCls:    "silk-magnifier",
				style:      "background-image:none;border-style:none;margin-top:2px",
				tooltip:    "Customer Search",
				overCls:    "",
				pressedCls: "",
				disabled:   disabledFlag,
				handler:    me.onShowCustomerWindow
			},
			{
				xtype:    "button",
				itemId:   "addRemoveButton",
				text:     initial ? "Add" : "Remove",
				width:    60,
				margin:   "0 10 10 10",
				disabled: disabledFlag,
				handler:  initial ? me.addRow : me.removeRow
			},
			{
				xtype:  "displayfield",
				itemId: "custViewCustDisplay",
				width:  200,
                listeners: {
                    disable: function(dispField) {
                        dispField.setFieldStyle("opacity: .3");
                    },
                    enable: function(dispField) {
                        dispField.setFieldStyle("opacity: 1");
                    }
                }
			}
		];

		// Wait for the fields to exist before loading the customer name
		if(initialId){
			me.on("afterlayout", me.updateCustomerName, me, {single: true});
		}

		me.callParent();
	},
	
	addRow: function(btn){
		var otherIdsField = btn.up("#otherCustLookup"),
				store = btn.up().store;
		otherIdsField.add({xtype: "customerviewcustlookupprompt", store: store, initial: false});
	},
	
	removeRow: function(btn) {
		var promptField = btn.up("#otherCustLookup"),
			promptFieldRow = btn.up();
		promptField.remove(promptFieldRow);
        MrPrompt.onchange();
	},

	onFieldChange: function(field){
		MrPrompt.onchange();
		if(field.rendered){
			field.up().updateCustomerName();
		}
	},

	onShowCustomerWindow: function(btn){
		var me = btn.up("customerviewcustlookupprompt");
		if(!MrPrompt.customerLookupWindow){
			MrPrompt.customerLookupWindow = new Sms.customer.Window();
		}
		me.showCustomerLookupWindow(MrPrompt.customerLookupWindow);
	},

	validateCustomer: function(customerId){
		var idField = this;
		var idTypeVal = idField.up().down("#idTypeField").getValue(),
				required = idField.isRequired,
				radioField = idField.up("#otherCustIds").down("#idTypeFieldRadio"),
				isValid = true;
		
		// Only run this validator if we're actually submitting data
		if(!MrPrompt.submitValidation || (!radioField.checked || (!required && customerId.length < 1))){
			return true;
		}
		
		if(radioField.checked && required && customerId.length < 1){
			return "This field is required.";
		}

		Sms.Ajax.request({
			async:    false,
			url:      "lu_customer_data.jsp",
			dataType: "json",
			data:     {
				context:       "VALIDATE_CUSTOMERS",
				employee_id:   MrPrompt.employeeId,
				customer_list: idTypeVal + "=" + customerId
			},
			success:  function(data){
				if(data.length){
					isValid = "You do not have permission to view this customer";
				}
			},
			error:    function(){
				Ext.Msg.alert("Error", "An error occurred while validating data.");
				isValid = "Could not validate customer ID";
			}
		});

		return isValid;
	},

	showCustomerLookupWindow: function(win){
		var me = this,
			idTypeField = me.down("#idTypeField"),
			idField = me.down("#idField"),
			nameField = me.down("#custViewCustDisplay");

		win.callback = function(custName, custId, custType){
			nameField.setRawValue(custName);
			idField.setRawValue(custId);

			idTypeField.suspendEvents();
			idTypeField.setValue(custType);
			idTypeField.resumeEvents();
		};

		win.setExclusions(me.excludeList);
		win.show(nameField.getValue(), idField.getValue(), idTypeField.getValue());
	},

	updateCustomerName: function(){
		
		var me = this,
			idType = me.down("#idTypeField").getValue(),
			custId = me.down("#idField").getValue(),
			nameField = me.down("#custViewCustDisplay");

		if(!custId || !idType){
			nameField.setValue("");
			return;
		}

		nameField.setValue("Searching...");
		Sms.Ajax.request({
			url:      "lu_customer_data.jsp",
			dataType: "json",
			data:     {
				context:          "CUSTOMER_LOOKUP",
				customer_id:      custId,
				customer_id_type: idType
			},
			success: function(json){
				nameField.setValue(json["customer_name"] || "Customer Not Found");
			},
			error:   function(){
				nameField.setValue("Customer Not Found");
			}
		});
	}
});

Ext.define("MrPrompt.prompt.CustomerView", {
	extend: "Ext.container.Container",
	alias:  "widget.customerviewprompt",

	shrinkWrap: true,
	layout:     "hbox",

	initComponent: function(){
		var me = this,
			viewStore = me.initStore("CUSTOMER_VIEW"),
			customerStore = me.initStore("CUSTOMER_LOOKUP"),
			employeeStore = me.initStore("EMPLOYEE_LIST"),
			isAe = MrPrompt.isAe === "true" ? true : false,
			isManager = MrPrompt.isManager === "true" ? true : false,
			isTeamLead = MrPrompt.isTeamLead === "true" ? true : false,
			custViewSelected = true,
			otherUserViewSelected = false,
			otherCustIdsSelected = false,
			initialViewValue, initialEmpVal, lookupType,
			initialEmpViewVal, initialIdType, initialId;
		var userCustViewStore = new Ext.data.ArrayStore({
			fields: ["view_id", "view_name", "employee_name", "total_records"],
			data:   []
		});
		
		var otherCustLookUpItems = [{
			xtype:         "customerviewcustlookupprompt",
			store:         customerStore,
			initialIdType: null,
			initialId:     null,
			initial:       true,
			disabledFlag:  !otherCustIdsSelected
		}];

		if(!me.isRequired)
			viewStore.insert(0, {});

		if (me.value && me.value.indexOf("=") !== -1){
			var custIds = me.value.split("+"),
					initial = true;
			for(var i = 0; i < custIds.length; i++){
				var defaultValue = custIds[i].split("=");
				lookupType = defaultValue[0];
				initialIdType = defaultValue[1];
				initialId = defaultValue[2];
				if(lookupType === "LOOKUP"){
					otherCustIdsSelected = true;
					custViewSelected = false;
					if(initial){
						otherCustLookUpItems = [{
							xtype: "customerviewcustlookupprompt",
							store: customerStore,
							initialIdType: initialIdType,
							initialId: initialId,
							initial: initial,
							disabledFlag: !otherCustIdsSelected
						}];
					}
					else{
						otherCustLookUpItems.push({
							xtype: "customerviewcustlookupprompt",
							store: customerStore,
							initialIdType: initialIdType,
							initialId: initialId,
							initial: initial,
							disabledFlag: !otherCustIdsSelected
						});
					}
				}
				else if(lookupType === "VIEW_ID" && initialIdType === MrPrompt.employeeId){
					initialViewValue = initialId;
					custViewSelected = true;
				}
				else{
					otherUserViewSelected = true;
					custViewSelected = false;
					initialEmpVal = initialIdType;
					initialEmpViewVal = initialId;
				}
				initial = false;
			}
		}

		delete me.listeners;
        
		me.width = 850;
		me.items = [
			{
				xtype:    "radiogroup",
				itemId:   "custViewRadio",
				columns:  1,
				vertical: true,
				items: [
					{
						xtype:  "container",
						layout: "hbox",
						items: [{
							xtype:       "radio",
							name:        "rg",
							itemId:      "viewIdFieldRadio",
							checked:     custViewSelected,
							listeners:  {
								change: function(me, newValue, oldValue){
									var viewComboBox = me.up().items.get("viewIdField"),
											viewEditButton = me.up().items.get("editViewButton"),
											addViewButton = me.up().items.get("addViewButton");
									if(newValue){
										viewComboBox.setDisabled(false);
										addViewButton.setDisabled(false);
										if(viewComboBox.getValue() && viewComboBox.getValue() !== "")
											viewEditButton.setDisabled(false);
									}
									else{
										viewComboBox.setDisabled(true);
										viewEditButton.setDisabled(true);
										addViewButton.setDisabled(true);
									}
                                    
                                    MrPrompt.onchange();
								}
							}
						},
						{
							xtype:         "combobox",
							itemId:        "viewIdField",
							store:         viewStore,
                            fieldLabel:    "Customer View",
                            labelWidth:    95,
                            labelCls:      "x-form-item-label x-form-item-label-right",
                            labelStyle:    "margin-right:5px;font-weight:bold;",
							valueField:    "view_id",
							displayField:  "description",
							value:         initialViewValue || viewStore.getAt(0),
							margin:        "0 10 10 10",
							width:         400,
							disabled:      !custViewSelected,
							validator:     function(val){
								var me = this;
								if(me.up()){
									var viewRadio = me.up().items.get("viewIdFieldRadio");
									if(viewRadio.value && val === "" && me.isRequired) {
										return "This field is required.";
									}
									else
										return true;
								}
								return true;
							},
							listeners:  {
								select: function(combo, records){
									var me = this;
									if(records.length > 0 && custViewSelected && records[0].get("view_id") !== "")
										me.up().down("#editViewButton").enable();
									else
										me.up().down("#editViewButton").disable();
								}
							}
						},
						{
							xtype:        "button",
							itemId:       "editViewButton",
							iconCls:      "silk-pencil",
							style:        "background-image:none;border-style:none;margin-top:2px",
							tooltip:      "Edit View",
							readOnlyView: false,
							disabled:     viewStore.data.length > 0 && custViewSelected ? false : true,
							overCls:      "",
							pressedCls:   "",
							handler:      me.onShowCustomerViewWindow
						},
						{
							xtype:        "button",
							itemId:       "addViewButton",
							iconCls:      "silk-add",
							style:        "background-image:none;border-style:none;margin-top:2px",
							tooltip:      "Create View",
							readOnlyView: false,
							disabled:     custViewSelected ? false : true,
							overCls:      "",
							pressedCls:   "",
							handler:      me.onShowCustomerViewWindow
						}]
					},
					{
						xtype:    "container",
						layout:   "hbox",
						hidden:   (isAe && !isManager && !isTeamLead) || employeeStore.totalCount === 0,
						items: [{
							xtype:       "radio",
							name:        "rg",
							itemId:      "viewIdUserFieldRadio",
							checked:     otherUserViewSelected,
							listeners:  {
								change: function(me, newValue, oldValue){
									var userComboBox = me.up().items.get("userField"),
											viewComboBox = me.up().items.get("viewIdUserField"),
											viewViewButton = me.up().items.get("viewViewButton");
									if(newValue){
										userComboBox.setDisabled(false);
										viewComboBox.enable();
										viewViewButton.enable();
									}
									else{
										userComboBox.setDisabled(true);
										viewComboBox.disable();
										viewViewButton.disable();
									}
                                    
                                    MrPrompt.onchange();
								}
							}
						},
						{
							xtype:         "combobox",
							itemId:        "userField",
							store:         employeeStore,
                            fieldLabel:    "Other User",
                            labelWidth:    70,
                            labelCls:      "x-form-item-label x-form-item-label-right",
                            labelStyle:    "margin-right:5px;font-weight:bold;",
							valueField:    "view_id",
							displayField:  "description",
							value:         initialEmpVal || employeeStore.getAt(0),
							margin:        "0 10 10 10",
							disabled:      !otherUserViewSelected,
							listeners: {
								select:   me.loadCustViews
							}
						},
						{
							xtype:         "combobox",
							itemId:        "viewIdUserField",
                            fieldLabel:    "Customer View",
                            labelCls:      "x-form-item-label x-form-item-label-right",
                            labelStyle:    "margin-right:5px;font-weight:bold;",
                            labelWidth:    100,
							valueField:    "view_id",
							displayField:  "view_name",
							store:		   userCustViewStore,
							margin:        "0 10 0 10",
							width:         400,
							disabled:      !otherUserViewSelected,
							validator:     me.validateUserViewId
						},
						{
							xtype:        "button",
							itemId:       "viewViewButton",
							iconCls:      "silk-information",
							style:        "background-image:none;border-style:none;margin-top:2px",
							tooltip:      "View this View",
							readOnlyView: true,
							overCls:      "",
							pressedCls:   "",
							disabled:     !otherUserViewSelected,
							handler:      me.onShowCustomerViewWindow
						}]
					},
					{
						xtype:  "container",
						layout: "hbox",
						itemId: "otherCustIds",
						items: 
						[{
							xtype:       "radio",
							itemId:      "idTypeFieldRadio",
							name:        "rg",
							margin:      "0 10 10 0",
							checked:     otherCustIdsSelected,
							listeners:  {
								change: function(me, newValue, oldValue){									
									var otherIdsContainer = me.up().down("#otherCustLookup");
									for(var i = 0; i < otherIdsContainer.items.length; i++) {
										var field = otherIdsContainer.items.getAt(i);
										var custId = field.down("#idField"),
												idType = field.down("#idTypeField"),
												lookupButton = field.down("#lookupButton"),
												addRemoveButton = field.down("#addRemoveButton"),
												custViewCustDisplay = field.down("#custViewCustDisplay");
										if(newValue){
											idType.setDisabled(false);
											custId.enable();
											lookupButton.enable();
											addRemoveButton.enable();
                                            custViewCustDisplay.enable();
										}
										else {
											idType.setDisabled(true);
											custId.disable();
											lookupButton.disable();
											addRemoveButton.disable();
                                            custViewCustDisplay.disable();
										}
									}
                                    
                                    MrPrompt.onchange();
								}
							}
						},
						{
							xtype:  "container",
							layout: "vbox",
							itemId: "otherCustLookup",
							items:  otherCustLookUpItems
						}]
					}
				]
			}
		];

		// Wait for the fields to exist before loading the other user customer views
        me.on("afterlayout", me.loadCustViews, me, {single: true});

		me.callParent();
	},

	onFieldChange: function(field){
		MrPrompt.onchange();
		if(field.rendered){
			field.up("customerviewprompt").updateCustomerName();
		}
	},

	onShowCustomerViewWindow: function(btn){
		var me = btn.up("customerviewprompt"),
            viewCombo = me.down("#viewIdField");
		var viewId = viewCombo.getValue();
        
		if(btn.itemId === "addViewButton")
			viewId = null;
		if(btn.readOnlyView){
			viewId = me.down("#viewIdUserField").getValue();
			Sms.viewCustomerView(viewId);
		}
		else{
			if(MrPrompt.viewport.layoutCounter === 1){
				MrPrompt.editCustomerViewPanel = Ext.create("EditCustomerView.Panel",{
					region: "center",
                    saveCallbackSuccess: function(newViewId, newViewName, component){
                        var viewStore = viewCombo.getStore();
                        var viewIndex = viewStore.find("view_id", newViewId);
                        if(viewIndex > -1){
                            viewStore.getAt(viewIndex).set("description", newViewName);
                        }
                        else{
                            viewStore.insert(0, {view_id: newViewId, description: newViewName});
                        }
                        viewCombo.setValue(newViewId);
                    }
				});
				MrPrompt.custViewPanel = Ext.create("Ext.panel.Panel", {
					layout: "border",
					items: [
						MrPrompt.editCustomerViewPanel
					]
				});
				MrPrompt.viewport.add(MrPrompt.custViewPanel);
			}
			if(MrPrompt.viewport.layoutCounter !== 0){
				MrPrompt.viewport.getLayout().setActiveItem(1);
				MrPrompt.editCustomerViewPanel.initPanelData(viewId, btn.readOnlyView);
			}
		}
	},

	showCustomerLookupWindow: function(win){
		var me = this,
			idTypeField = me.down("#idTypeField"),
			idField = me.down("#idField"),
			nameField = me.up("[isPromptFieldRow]").down("#endField");

		win.callback = function(custName, custId, custType){
			nameField.setRawValue(custName);
			idField.setRawValue(custId);

			idTypeField.suspendEvents();
			idTypeField.setValue(custType);
			idTypeField.resumeEvents();
		};

		win.setExclusions(me.excludeList);
		win.show(nameField.getValue(), idField.getValue(), idTypeField.getValue());
	},

	initStore: function(storeType){
		var me = this,
			data = [],
			sourceStore = Ext.data.StoreManager.lookup(MrPrompt.getPromptStoreId(me.promptNumber)),
			targetStore;

		sourceStore.data.each(function(record){
			var idType = record.get("value_field");
			var promptType = record.get("prompt_type");
			if(promptType === storeType){
				data.push([idType, record.get("display_field")]);
			}
		});

		targetStore = new Ext.data.ArrayStore({
			fields: ["view_id", "description"],
			data:   data
		});

		return targetStore;
	},
	
	loadCustViews: function(me){
		var editViewButton = me.up().down("#editViewButton"),
			viewCombo = me.up().down("#viewIdField"),
			empId, viewId,
			isAe = MrPrompt.isAe === "true" ? true : false,
			isManager = MrPrompt.isManager === "true" ? true : false,
			isTeamLead = MrPrompt.isTeamLead === "true" ? true : false;
	
		if(me.xtype === "customerviewprompt"){
            var viewArray =me.value.split("=");
			empId = me.down("#userField").getValue();
            if(me.value.search("LOOKUP") === -1 && viewArray[1] !== "")
                viewId = viewArray[2];
		}
		else{
			empId = me.getValue();
		}
		
		if(viewCombo !== null && viewCombo.getValue() && !viewCombo.disabled){
			editViewButton.enable();
		}
		else if(viewCombo !== null){
			editViewButton.disable();
		}
		
		if(empId !== null && (!isAe || (isAe && (isManager || isTeamLead)))){
			var custViewCombo = me.up().down("#viewIdUserField"),
			    custViewInfoButton = me.up().down("#viewViewButton");
		
			custViewCombo.setLoading("Loading...");
			Ext.Ajax.request({
				url:   "cust_view_list_data.jsp",
				params:     {
					context:         "LOAD_EMP_VIEW",
					employee_id:     empId,
					include_view_id: viewId
				},
				success:  function(response){
					var obj = Ext.decode(response.responseText);
					custViewCombo.store.loadData(obj.view_list, false);
                    if(!me.isRequired)
                        custViewCombo.store.insert(0, {});
                    if(viewId)
                        custViewCombo.setValue(parseInt(viewId));
                    else
                        custViewCombo.setValue(custViewCombo.store.getAt(0));
					if((obj.view_list.length || obj.view_list.length > 0) && !custViewCombo.disabled)
						custViewInfoButton.enable();
					else
						custViewInfoButton.disable();
                    
                    custViewCombo.setLoading(false);
				},
				error:    function(){
                    custViewCombo.setLoading(false);
					Ext.Msg.alert("Error", "An error occurred while retrieving this employee's views.");
				}
			});
		}
	},
	
	validateUserViewId: function(){
		var me = this,
				required = me.isRequired,
				val = me.getValue(),
				radioField = me.up().down("#viewIdUserFieldRadio");
		if(required && val === null && radioField.checked)
			return "This field is required.";
		else
			return true;
	},
	
	getSubmitValue: function(){
		var me = this,
			selected = me.down("#custViewRadio").getChecked()[0],
			returnVal = "";

		if(selected.itemId === "viewIdFieldRadio"){
			returnVal = "VIEW_ID" + "=" + MrPrompt.employeeId + "=" + me.down("#viewIdField").getValue();
		}
		else if(selected.itemId === "viewIdUserFieldRadio"){
			var userId = me.down("#userField").getValue(),
					userViewId = me.down("#viewIdUserField").getValue();
			if(!userId || !userViewId)
				returnVal = "";
			else
				returnVal = "VIEW_ID=" + userId + "=" + userViewId;
		}
		else {
			var otherIdsContainer = me.down("#otherCustLookup"),
					firstId = true;
			for(var i = 0; i < otherIdsContainer.items.length; i++) {
				var field = otherIdsContainer.items.getAt(i);
				var custId = field.down("#idField").getValue(),
						idType = field.down("#idTypeField").getValue();
				if(!idType || !custId){
					returnVal = returnVal + "";
				}
				else {
					if(firstId)
						returnVal = "LOOKUP=" + idType + "=" + custId;
					else
						returnVal = returnVal + "+LOOKUP=" + idType + "=" + custId;
					firstId = false;
				}
			}
		}
		return returnVal;
	}
});

Ext.define("MrPrompt.prompt.ItemSelector", {
	extend: "Ext.ux.form.ItemSelector",
	alias:  "widget.promptitemselector",

	buttons: ["add", "remove"],

	fixedRowHeight: 16,

	initComponent: function(){
		var me = this;
		me.height = Math.max((me.fixedRowHeight * me.listSize) + 30, 63);

		if(Ext.isIE8){
			me.margin = '0 0 2 0';
		}

		me.listeners = {
			change: function(me){
				me.sortBothFields();
				MrPrompt.onchange();
			},
			afterrender: {
				single: true,
				fn:     function(me){
					me.addSorters();

					// Sort on drag & drop
					me.mon(me.toField.dropZone.view, "drop", me.sortBothFields, me);
					me.mon(me.fromField.dropZone.view, "drop", me.sortBothFields, me);
				}
			}
		};

		me.callParent();
	},

	addSorters: function(){
		var me = this,
			sorter = new Ext.util.Sorter({
				property:  "sort_order",
				direction: "ASC",
				root:      "data"
			}),
			toStore = me.toField.boundList.getStore(),
			fromStore = me.fromField.boundList.getStore();

		toStore.sorters.add(sorter);
		fromStore.sorters.add(sorter);
		toStore.sort();
		fromStore.sort();
	},

	sortBothFields: function(){
		var me = this;
		me.toField.boundList.getStore().sort();
		me.fromField.boundList.getStore().sort();
	}
});

Ext.define("MrPrompt.prompt.ZoneTimeField", {
	extend: "Ext.form.field.Time",
	alias:  "widget.zonetimefield",

	// So much effort just to get a timezone label on the right side.
	// If we ever upgrade to 4.1.1, we should be able to use "afterBodyEl" instead.
	labelableRenderTpl: [
		'<tr id="{id}-inputRow" <tpl if="inFormLayout">id="{id}"</tpl>>',

			// Body element
			'<td class="{baseBodyCls} {fieldBodyCls}" id="{id}-bodyEl" role="presentation" colspan="{bodyColspan}">',
				'{beforeSubTpl}',
				'{[values.$comp.getSubTplMarkup()]}',
				'{afterSubTpl}',
			'</td>',

			// Label element
			'<td id="{id}-labelCell" style="{labelCellStyle}" {labelCellAttrs}>',
				'{beforeLabelTpl}',
				'<label id="{id}-labelEl" {labelAttrTpl}<tpl if="inputId"> for="{inputId}"</tpl> class="{labelCls}"',
					'<tpl if="labelStyle"> style="{labelStyle}"</tpl>>',
					'{beforeLabelTextTpl}',
					'<tpl if="fieldLabel">{fieldLabel}</tpl>',
					'{afterLabelTextTpl}',
				'</label>',
				'{afterLabelTpl}',
			'</td>',

			// Error element
			'<td id="{id}-errorEl" class="{errorMsgCls}" style="display:none" width="{errorIconWidth}"></td>',
		'</tr>',
		{disableFormats: true}
	]
});

// This method takes an incomplete PromptField component and uses its prompt type
// to populate its child items and configure event handling and layouts.
MrPrompt.initPromptFieldByType = function(promptField){
	var type    = promptField.promptType,
		isMulti = promptField.isMultiple,
		values  = promptField.value,
		vars    = promptField.isVariable.split(",");
	var	cfgRec  = MrPrompt.configStore.getAt(MrPrompt.configStore.findExact("prompt_type", type));
	var cfgObj  = JSON.parse(cfgRec.get("config_json") || "{}");
	var config  = Ext.Object.merge({}, cfgObj);
	
	// Don't show add/remove buttons if the startField supports multiple input
	if(!isMulti){
		config.showAddRemoveButtons = false;
	}

	if(MrPrompt.isReportScheduler){
		// Add the prompt variable field to any prompt type that has prompts in the variable store
		config.showPromptVariableField = (MrPrompt.variableStore.findRecord("prompt_type", type) !== null);
	}
	else{
		// Don't show prompt variable field unless loaded into the report scheduler
		config.showPromptVariableField = false;
	}

	if(config.showAddRemoveButtons){
		// Add a prompt field row for each default value that exists in the config
		Ext.each(values.split(config.valueDelimiter || ","), function(value, idx){
			promptField.items.push(Ext.apply({
				value:      MrPrompt.decode(value),
				initial:    (idx === 0),
				isVariable: (vars[idx] === "Y")
			}, config));
		});
	}
	else{
		promptField.items.push(Ext.apply({
			value:      Ext.isString(values) ? MrPrompt.decode(values) : values,
			isVariable: (vars[0] === "Y")
		}, config));
	}

	// Keep a reference to the finished config object, for adding rows
	promptField.promptConfig = config;
};
