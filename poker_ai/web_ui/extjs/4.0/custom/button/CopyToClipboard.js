Ext.define("Sms.button.CopyToClipboard", {
	extend: "Ext.button.Button",
	alias: 'widget.smscopytoclipboardbutton',
	
	gridMode: true,
	
	copyText: "",
	
	constructor: function(config){
		var me = this;
		
		//apply basic attributes if they aren't specified
		Ext.applyIf(config, {
			cls:     "ctc_button"
		});
		
		if(config.gridMode !== false)
		{
			Ext.applyIf(config, {
				iconCls: "silk-grid"
			});
		}
		
		me.callParent(arguments);
		
		me.on("afterrender", me.checkAttachClip, me, {single: true});
	},
	
	checkAttachClip: function(me){
		if(me.isVisible(true)){
			me.attachClip(me);
		}
		else{
			Ext.Function.defer(me.checkAttachClip, 500, me, [me]);
		}
	},
	
	setCopyText: function(text){
		this.copyText = text;
	},
	
	attachClip: function(me){
		var clip,
			grid = me.gridMode ? (me.findParentByType("grid") || me.findParentByType("treepanel")) : false,
			desktopApp = typeof exeoutput !== "undefined";

		if (desktopApp) {
			me.on("click", Ext.bind(me.mouseDownListener, me, [clip, me, grid]), me);
		} else {
			clip = me.clip = new ZeroClipboard.Client();

			if(!clip){
				Ext.Error.raise("Error occurred while trying to create ZeroClipboard button");
				return;
			}

			clip.glue(me.el.dom);
			clip.addEventListener("mouseDown", Ext.bind(me.mouseDownListener, me, [clip, me, grid]));
			clip.show();

			var div = clip.div;
			me.el.dom.appendChild(div);
			div.style.top = div.style.left = "0px";
			div.style.position = "absolute";
			div.removeAttribute("title");
			div.setAttribute("data-qtip", "Copy to Clipboard");
		}
			
	},

	mouseDownListener: function(clip, btn, grid){

		var text, textHolder, range,
			desktopApp = typeof exeoutput !== "undefined";
		btn.toggle();
		if(btn.gridMode)
			text = Sms.dataUtilities.getGridClipboardText(grid);
		else
			text = btn.copyText;
		try{
			if (text.length > 1000000)
				Ext.Msg.alert("Error", "The volume of data from this report item is too excessive to be copied to the clipboard.");
			else
				clip.setText(text);
		}
		catch(err){
			try{
				if(Ext.isIE6 || Ext.isIE7 || (Ext.isIE && !window.clipboardData)){
					// Older method of getting text to clipboard. Only works in IE < 9.  8 is not included because the next if works correctly without a message
					textHolder = document.createElement("textarea");
					textHolder.style.display = "none";
					textHolder.innerText = text;
					range = textHolder.createTextRange();
					range.execCommand("Copy");
					textHolder = null;
					range = null;
				}
				else if(desktopApp)
				{
					// issues with passing slash and percent in a sring to a HeScript function
					// this is a workaround untill I can find a better way.
					var encodedText = text.replace(/\//g, "<encoded_slash>"); 
					encodedText = encodedText.replace(/%/g, "<encoded_percent>");
					encodedText = encodedText.replace(/\|/g, "<encoded_pipe>");
					var command = "sms.CopyToClipboard|" + encodedText;
					exeoutput.RunHEScriptCom(command);
				}
				else if(window.clipboardData){
					//For IE8 and above
					window.clipboardData.setData("Text", text);
				}
				else{
					// No other browser supports native clipboard access (yet)
					throw "Error";
				}
			}
			catch(error){
				Ext.Msg.alert("Error", "An error occurred while copying to clipboard.");
			}
		}
		btn.toggle();
	},

	onDestroy: function(){
		var clip = this.clip;
		if(clip){
			Sms.removeSWF(clip.movie);
			clip.destroy();
			clip.handlers.mousedown[0] = null;
			clip.movie = null;
		}
		this.clip = null;
		this.callParent();
	}
});