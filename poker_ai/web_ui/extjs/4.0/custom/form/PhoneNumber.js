/**
 * A field container which has a specialized layout for displaying and accepting
 * phone numbers, specifically phone numbers compliant with the North American
 * Numbering Plan (NANP).
 *
 * # Terminology
 *
 * This component uses NANP terminology to refer to its child fields. Given the
 * fictional number (123) 555-0123, the following parts are called:
 *
 * **(123)**: Area code
 * **555**:   Exchange code (also called "Central Office code")
 * **0123**:  Subscriber number
 *
 * For more information, see http://en.wikipedia.org/wiki/North_American_Numbering_Plan
 */
Ext.define("Sms.form.field.PhoneNumber", {
	extend: "Ext.form.FieldContainer",
	alias:  "widget.smsphone",

	requires: [
		"Ext.form.field.Display",
		"Ext.form.field.Text"
	],

	mixins: {
		field: "Ext.form.field.Field"
	},

	allowBlank: true,
	msgTarget:  "side",

	checkChangeBuffer: 250,

	// If true, an extra field will be added for the extension.
	includeExtension: false,

	// Direct access to child fields
	areaCodeField:     null,
	exchangeCodeField: null,
	subscriberField:   null,
	extensionField:    null,  // Only if includeExtension == true

	// Private
	combineErrors: true,
	layout:        "hbox",
	separatorRe:   /[^\d]/gi,

	initComponent: function(){
		var me = this;

		me.fieldDefaults = {
			allowBlank:        true,  // Field container's allowBlank takes precedence
			checkChangeBuffer: me.checkChangeBuffer,
			enforceMaxLength:  true,
			maskRe:            /\d/,
			preventMark:       true,  // Container will display its own messages
			stripCharsRe:      /[^\d]/gi,
			submitValue:       false,
			validateOnBlur:    false,  // Container will handle all validation
			validateOnChange:  false
		};

		me.callParent();

		var separatorConfig = {
			xtype: "displayfield",
			value: " - ",
			width: 10,
			style: "text-align:center"
		};

		me.areaCodeField = me.add({
			xtype:     "textfield",
			itemId:    "areaCode",
			maxLength: 3,
			width:     30,
			validator: me.validateAreaCode,
			listeners: {
				change: me.onFieldChange,
				scope:  me
			}
		});

		me.add(separatorConfig);

		me.exchangeCodeField = me.add({
			xtype:     "textfield",
			itemId:    "exchangeCode",
			maxLength: 3,
			width:     30,
			validator: me.validateExchangeCode,
			listeners: {
				change: me.onFieldChange,
				scope:  me
			}
		});

		me.add(separatorConfig);

		me.subscriberField = me.add({
			xtype:     "textfield",
			itemId:    "subscriberNumber",
			maxLength: 4,
			width:     35,
			validator: me.validateSubscriberCode,
			listeners: {
				change: me.onFieldChange,
				scope:  me
			}
		});

		if(me.includeExtension){
			me.add({
				xtype: "displayfield",
				value: " ext. ",
				width: 30,
				style: "text-align:center"
			});

			me.extensionField = me.add({
				xtype:     "textfield",
				itemId:    "extension",
				maxLength: 10,
				width:     75,
				listeners: {
					change: me.onFieldChange,
					scope:  me
				}
			});
		}

		me.initField();
	},

	onFieldChange: function(){
		var me = this;
		if(!me.rendered){
			return;
		}
		me._updateInternalValue(me.getValue());
	},

	// Returns an array of the component values
	getComponentValues: function(){
		var me = this,
			components = [
				me.areaCodeField.getValue(),
				me.exchangeCodeField.getValue(),
				me.subscriberField.getValue()
			];

		if(me.extensionField){
			components.push(me.extensionField.getValue());
		}

		return components;
	},

	getFormattedValue: function(){
		var me = this,
			values = me.getComponentValues(),
			value = values[0] + "-" + values[1] + "-" + values[2];

		if(values[3]){
			value += "x" + values[3];
		}

		return value;
	},

	getValue: function(){
		var me = this,
			values = me.getComponentValues(),
			value = values[0] + values[1] + values[2];

		if(me.extensionField && values[3]){
			value += values[3];
		}

		return value;
	},

	getRawValue: function(){
		return this.getValue();
	},

	getErrors: function(value){
		var me     = this,
			errors = [],
			subNum;

		value = value ? me._getPhoneComponents(value) : me.getComponentValues();

		if(!me.disabled){

			if(me.allowBlank && me._hasPartialValue(value)){
				errors.push('Field must be in format "(###) ###-####" or blank.');
			}
			else{
				// Numbers 555-0100 through 555-0199 reserved for fictional use
				// except for area code 800, which only reserves 800-555-0199.
				if(value[1] === "555"){
					subNum = parseInt(value[2], 10);
					if((value[0] === "800" && subNum === 199) || (value[0] !== "800" && subNum >= 100 && subNum <= 199)){
						errors.push('Not a valid phone number.');
					}
				}

				errors = errors.concat(me.areaCodeField.getErrors(value[0]));
				errors = errors.concat(me.exchangeCodeField.getErrors(value[1]));
				errors = errors.concat(me.subscriberField.getErrors(value[2]));

				if(me.extensionField){
					errors = errors.concat(me.extensionField.getErrors(value[3]));
				}
			}
		}

		return errors;
	},

	/**
	 * Field-specific validators
	 */
	validateAreaCode: function(v){
		var me        = this.ownerCt,
			value     = String(v || ""),
			firstChar = value.charAt(0);

		if(!value){
			return (me.allowBlank) ? true : "Area code cannot be empty.";
		}

		// Area code must be 3 digits
		if(value.length < 3){
			return "Area code must be 3 digits.";
		}

		// Area code cannot start with 0 or 1
		if(firstChar === "0" || firstChar === "1"){
			return "Area code cannot start with 0 or 1.";
		}

		return true;
	},

	validateExchangeCode: function(v){
		var me        = this.ownerCt,
			value     = String(v || ""),
			firstChar = value.charAt(0);

		if(!value){
			return (me.allowBlank) ? true : "Exchange code cannot be empty.";
		}

		// Exchange code must be 3 digits
		if(value.length < 3){
			return "Exchange code must be 3 digits.";
		}

		// Exchange code cannot start with 0 or 1
		if(firstChar === "0" || firstChar === "1"){
			return "Exchange code cannot start with 0 or 1.";
		}

		// Cannot end with 11
		if(value.substr(1, 2) === "11"){
			return "Exchange code cannot end with #11.";
		}

		return true;
	},

	validateSubscriberCode: function(v){
		var me        = this.ownerCt,
			value     = String(v || "");

		if(!value){
			return (me.allowBlank) ? true : "Subscriber number cannot be empty.";
		}

		// Subscriber number must be 4 digits
		if(value.length < 4){
			return "Subscriber number must be 4 digits.";
		}

		return true;
	},


	/**
	 * Begin overrides for Ext.form.field.Field
	 */
	initValue: function(){
		var me = this;
		me.value = me.transformOriginalValue(me.value);
		me.originalValue = me.lastValue = me.value;

		me._suspendCheckChange();
		me.setValue(me.value);
		me._resumeCheckChange();
	},

	transformOriginalValue: function(value){
		var me = this,
			newValue = value;
		if(newValue){
			newValue = newValue.replace(me.separatorRe, "");
		}
		return newValue;
	},

	setValue: function(value){
		var me = this;
		var components = me._getPhoneComponents(value || "");

		var updateField = function(field, value){
			field.lastValue = value;
			field.setRawValue(value);
		};

		updateField(me.areaCodeField,     components[0]);
		updateField(me.exchangeCodeField, components[1]);
		updateField(me.subscriberField,   components[2]);
		if(me.extensionField){
			updateField(me.extensionField, components[3]);
		}

		me._updateInternalValue(components.join(""));
		return me;
	},

	validate: function(){
		var me = this,
			isValid = me.isValid();

		if(isValid){
			me.clearInvalid();
		}else{
			me.markInvalid(me.getErrors());
		}

		if(isValid !== me.wasValid){
			me.wasValid = isValid;
			me.fireEvent("validitychange", me, isValid);
			me.updateLayout();
		}

		return isValid;
	},

	/**
	 * Private
	 */
	_suspendCheckChange: function(){
		this.suspendCheckChange++;
	},
	_resumeCheckChange: function(){
		this.suspendCheckChange--;
	},

	_getPhoneComponents: function(number){
		var me = this,
			cleanNumber = number.replace(this.separatorRe, "");
		return [
			cleanNumber.substr(0, 3),
			cleanNumber.substr(3, 3),
			cleanNumber.substr(6, 4),
			me.extensionField ? cleanNumber.substr(10, me.extensionField.maxLength) : ""
		];
	},

	_updateInternalValue: function(value){
		var me = this;
		me.lastValue = me.value;
		me.value = value;
		me.checkChange();
	},

	// Returns true if at least one field has a value, but not all of them.
	_hasPartialValue: function(value){
		var v0       = value[0],
			v1       = value[1],
			v2       = value[2],
			v3       = value[3];
		var isBlank  = !(v0 || v1 || v2 || v3);
		var isFilled = (v0 && v1 && v2);
		return (!isBlank && !isFilled);
	}
}, function(){
	this.borrow(Ext.form.field.Base, ["markInvalid", "clearInvalid"]);
});