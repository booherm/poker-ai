Ext.define('Sms.form.TextArea', {
    extend: 'Ext.form.field.TextArea',
	
	disableHorizontalScroll: false,
	
	afterRender: function(){
		var me = this;
		
		me.callParent(arguments);
		
		if (me.disableHorizontalScroll)
		{
			me.inputEl.setStyle('overflow-x', 'hidden');
		}
		else if (me.preventScrollbars)
		{
			me.inputEl.setStyle('overflow', 'hidden');
		}
		
		if (me.grow) {
			me.inputEl.setHeight(me.growMin);
		}
	}
});

Ext.define("Sms.form.AuditTextArea", {
	extend:          "Sms.form.TextArea",
	alias:           "widget.smsaudittextarea",
	employeeName:    "",
	hasAuditText:    false,
	enableKeyEvents: true,

	// The first time text is entered into the field, create the audit text
	// header and insert the text before the current cursor position
	onKeyDown: function(evt){
		var me = this,
			insertText;
			
		if(!me.readOnly && !me.hasAuditText && !evt.isNavKeyPress() && !evt.isSpecialKey()){
			insertText = [
				"[",
				me.employeeName,
				" - ",
				Ext.Date.format(new Date(), "m/d/Y h:i A"),
				"]:\n"
			].join("");

			if(me.getValue() !== ""){
				insertText = "\n" + insertText;
			}

			me.insertTextAtCursor(insertText);
			me.hasAuditText = true;
		}

		me.callParent(arguments);
	},

	insertTextAtCursor: function(text){
		var me = this,
			el = me.inputEl.dom,
			val = el.value,
			endIndex, range;

		if(Ext.isDefined(el.selectionStart) && Ext.isDefined(el.selectionEnd)){
			endIndex = el.selectionEnd;
			el.value = val.slice(0, endIndex) + text + val.slice(endIndex);
			el.selectionStart = el.selectionEnd = endIndex + text.length;
		}
		else if(document.selection && document.selection.createRange){
			el.focus();
			range = document.selection.createRange();
			range.collapse(false);
			range.text = text + range.text;
			range.select();
		}
	},

	resetAuditText: function(){
		this.hasAuditText = false;
	}
});
