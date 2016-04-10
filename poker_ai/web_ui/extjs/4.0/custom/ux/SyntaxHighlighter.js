Ext.define("Sms.ux.SyntaxHighlighter", {
	extend: "Ext.Component",
	alias:  "widget.syntaxhighlighter",

	/**
	 * @cfg {String} brush  The name of the highlighter brush to apply.
	 */
	brush: "text",

	/**
	 * @cfg {String} text  The content to display.
	 */
	text: "",

	/**
	 * @cfg {Number} highlightStart  The first line number (>= 1) to highlight.
	 * Any value less than 1 will disable highlighting.
	 */
	highlightStart: 0,
	
	/**
	 * @cfg {Number} highlightEnd  The last line number (>= 1) to highlight.
	 * Any value less than 1 will disable highlighting.
	 */
	highlightEnd: 0,
	
	/**
	 * @cfg {Boolean} markSoNumbers  true to make SO numbers into links
	 */
	markSoNumbers: false,

	/** @private */
	renderTpl: [
		'<pre class="brush:{brush}">',
			'{text}',
		'</pre>'
	],

	/**
	 * Updates the content text.
	 *
	 * @param {String} [text=""]  The text to display.
	 * @param {Boolean} [silent=false]  `true` to not redraw the content.
	 */
	setText: function(text, silent){
		var me = this;
		me.text = (text || "");

		if(!silent){
			me.updateContent();
		}
	},

	/**
	 * Updates the content brush.
	 *
	 * @param {String} [brush="text"]  The brush code to highlight the content.
	 * @param {Boolean} [silent=false]  `true` to not redraw the content.
	 */
	setBrush: function(brush, silent){
		var me = this;
		me.brush = (brush || "text");

		if(!silent){
			me.updateContent();
		}
	},

	/**
	 * Updates the content brush.
	 *
	 * @param {Number} [start=0]  The first line number to highlight.
	 * @param {Number} [end=0]  The last line number to highlight.
	 * @param {Boolean} [silent=false]  `true` to not redraw the content.
	 */
	setHighlightRange: function(start, end, silent){
		var me = this;
		me.highlightStart = start || 0;
		me.highlightEnd   = end || 0;

		if(!silent){
			me.updateContent();
		}
	},

	/**
	 * Renders the inner content after the component has been rendered into DOM.
	 */
	updateContent: function(){
		var me = this;

		if(me.rendered){
			me.tpl = me.initRenderTpl();
			me.tpl[me.tplWriteMode](me.getTargetEl(), me.initRenderData());
			me.highlightText();
			me.markSoNumbersFn();
			me.cleanEOFIndicator();
			me.ieLineBreakFix();
		}
	},

	/**
	 * Invokes the SyntaxHighlighter highlight method on the content.
	 * @private
	 */
	highlightText: function(){
		var me    = this;
		var dom   = me.getEl().first(null, true);
		var range = me.getLineHighlightRange();
		
		SyntaxHighlighter.highlight({
			toolbar:   false,
			highlight: range
		}, dom);
	},
			
	/**
	 * Makes the possible SO numbers into links in the file if activated
	 * @private
	 */
	markSoNumbersFn: function(){
		var me = this;
		if(me.markSoNumbers)
		{
			var dom = me.getEl().first(null, true);
			var soMatch = /(\D)(8\d{9})(\D)/g;
			var fileOutput = dom.innerHTML;
			
			if(fileOutput)
				fileOutput = fileOutput.replace(soMatch, "$1" + Sms.getViewServiceOrderLink("SAP", "$2") + "$3");
			
			dom.innerHTML = fileOutput;
		}
	},
			
	/**
	 * Makes the possible SO numbers into links in the file if activated
	 * @private
	 */
	cleanEOFIndicator: function(){
		var me = this;
		var dom = me.getEl().first(null, true);
		var eofElementArray = Ext.dom.Query.jsSelect("CODE:last" , dom);
		var eofElement = eofElementArray.length ? eofElementArray[0] : null;
		if(eofElement && eofElement.innerHTML)
			eofElement.innerHTML = eofElement.innerHTML.replace(/ENDOFFILE$/, "");
	},
	
	/**
	 * This function inserts line breaks into IE which matter when someone tries to do a basic copy to clipboard from
	 * highlighted text so that the output formats correctly
	 * @private
	 */
	ieLineBreakFix: function(){
		if(Ext.isIE)
		{
			var me = this;
			var dom = me.getEl().first(null, true);
			var fileOutput = dom.innerHTML;
			fileOutput = fileOutput.replace(/<\/CODE><\/DIV/g, "\n</CODE></DIV");
			dom.innerHTML = fileOutput;
		}
	},

	/**
	 * Returns the array of line numbers to highlight.
	 * @private
	 *
	 * @return {Array} An array of elements in the range of {start..end} inclusive,
	 * or an empty array if highlighting is disabled.
	 */
	getLineHighlightRange: function(){
		var me    = this;
		var start = me.highlightStart;
		var end   = me.highlightEnd;

		return (start > 0 && end > 0) ? me.fillRange(start, end) : [];
	},

	/**
	 * Utility method to create an array containing one element per number in
	 * the range of {start..end} inclusive.
	 * Example: fillRange(3, 8) -> [3, 4, 5, 6, 7, 8]
	 * @private
	 *
	 * @param {Number} start
	 * @param {Number} end
	 */
	fillRange: function(start, end){
		var me  = this;
		var out = [];
		var i;
		//fix in case the numbers come in as string
		if(Ext.isString(start))
			start = parseInt(start, 10);
		if(Ext.isString(end))
			end = parseInt(end, 10);

		if(start > end){
			return me.fillRange(end, start);
		}

		for(i = start; i <= end; i++){
			out.push(i);
		}

		return out;
	},

	/**
	 * Override to automatically highlight content after component render.
	 * @private
	 */
	afterRender: function(){
		var me = this;
		me.callParent();
		me.highlightText();
		me.markSoNumbersFn();
		me.cleanEOFIndicator();
		me.ieLineBreakFix();
	},

	/**
	 * Sets current values of text and brush to the render template.
	 * @private
	 */
	initRenderData: function(){
		var me = this;
		me.renderData = {
			text:  me.text.replace("<", "&lt;") + "ENDOFFILE",
			brush: me.brush
		};
		return me.callParent();
	}
});
