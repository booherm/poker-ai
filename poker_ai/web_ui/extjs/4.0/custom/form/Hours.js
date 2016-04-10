
Ext.define('Ext.ux.form.field.Hours', {
    extend:'Ext.form.field.Text',
	
	alias: 'widget.hoursfield',
	
    fieldStyle:     "text-align:right;",
    allowNegative:  false,
	autoStripChars: true,
    baseChars:      "0123456789:",

    initEvents: function(){
		var allowed = this.baseChars + "";
		if(this.allowNegative)
			allowed += "-";

		this.maskRe = new RegExp("[" + Ext.escapeRe(allowed) + "]");
		if(this.autoStripChars)
			this.stripCharsRe = new RegExp("[^" + allowed + "]", "gi");
		
		this.callParent(arguments);
    },
	
	getMinutesValueForString: function(v)
	{
		v = v + "";
		v = Ext.String.trim(v);
		if(v == "")
			return null;
		
		var splitUp = v.split(":");
		var hoursPortion = 0;
		if(splitUp[0])
			hoursPortion = parseInt(splitUp[0], 10);
		var minutesPortion = 0;
		if(splitUp[1])
			minutesPortion = parseInt(splitUp[1], 10);
		var hours = (hoursPortion * 60) + minutesPortion;
		
		return hours;
	},

	sanitizeString: function(v)
	{
		return Sms.assertTimeDisplay(v);
	},
	
    getValue: function(){
		var v = this.callParent(arguments);
		if(isNaN(v))
			v = this.getMinutesValueForString(v);
		
        return v;
    },
	
	getDisplayValue: function(){
		return Ext.form.field.Text.prototype.getValue.call(this);
	},

	setValue: function(v){
		var f = this.sanitizeString(v);
		
		return this.callParent([f]);
	},
	
	beforeBlur: function(){
		var rawValueString = this.getRawValue();
		var sanitizedRawValueString = this.sanitizeString(rawValueString);
		//alert(sanitizedRawValueString);
		this.setValue(sanitizedRawValueString);
    },
	
	editableHoursFieldGridColumnRenderer: function(value, metaData)
	{
		var displayValue = Sms.timeFormatHours(value);
		if(metaData == null)
			return displayValue;

		metaData.attr = "style='border-style:solid;border-width:1px;border-color:gray;'";

		return displayValue;
	},
	
	hoursFieldGridColumnRenderer: function(value)
	{
		var displayValue = Sms.timeFormatHours(value);
		return displayValue;
	},
	
	getErrors: function(value) {
        var errors = this.callParent(arguments),
            format = Ext.String.format;

		if(errors.length > 0) {
			return errors;
		}
        
        value = Ext.isDefined(value) ? value : this.processValue(this.getRawValue());        
        
        if (Ext.isFunction(this.validator)) {
            var msg = this.validator(value, this);
            if (msg !== true) {
                errors.push(msg);
            }
        }
        
        if (value.length < 1 || value === this.emptyText) {
            if (this.allowBlank) {
                //if value is blank and allowBlank is true, there cannot be any additional errors
                return errors;
            } else {
                errors.push(this.blankText);
            }
        }
        
        if (!this.allowBlank && (value.length < 1 || value === this.emptyText)) { // if it's blank
            errors.push(this.blankText);
        }
        
        if (value.length < this.minLength) {
            errors.push(format(this.minLengthText, this.minLength));
        }
        
        if (value.length > this.maxLength) {
            errors.push(format(this.maxLengthText, this.maxLength));
        }
        
        if (this.vtype) {
            var vt = Ext.form.VTypes;
            if(!vt[this.vtype](value, this)){
                errors.push(this.vtypeText || vt[this.vtype +'Text']);
            }
        }
        
        if (this.regex && !this.regex.test(value)) {
            errors.push(this.regexText);
        }
        
        return errors;
    }
});
