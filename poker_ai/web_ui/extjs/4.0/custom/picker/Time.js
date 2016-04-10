/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */


Ext.define("Sms.picker.Time", {
	override: "Ext.picker.Time",
	
	listOptionCss: "border-color:#EEEEEE;border-width:1px;border-style:solid;",
	
	constructor: function(config){
		config.tpl = Ext.create("Ext.XTemplate",
			'<ul><tpl for=".">',
				'<li role="option" style="' + this.listOptionCss + '" class="' + Ext.baseCSSPrefix + 'boundlist-item">{[values.' + this.displayField + ' ? values.' + this.displayField + ' : "&nbsp;"]}</li>',
			'</tpl></ul>'
		);
			
		this.callParent(arguments);
	}
});