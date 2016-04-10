Ext.define("Sms.file.Grid", {
	
	extend: "Ext.grid.Panel",
	
	// The default config
	extraParamsFunction:    function(){return {};},
	name:                   "",
	url:                    "",
	readOnly:               false,
	uniqueFileIdentifier:   "",
	uploadCompleteFunction: function(){return {};},
	deleteCompleteFunction: function(){return {};},
	id:                     null,
	fileUploadConfig:       null,
	removeButtonConfig:     null,
	model:                  "Sms.file.File",

    constructor: function(config) {
		var me = this;
		me.modByEmployee = "";
		me.modDateEmployee = "";
		me.fileUploadConfig = {};
		me.removeButtonConfig = {};
		
		me.viewConfig = {
			markDirty: false
		};
		
		Ext.apply(me, config);
		
		me.columns = {
			defaults:{
				menuDisabled: true,
				hideable:     false,
				draggable:    false
			},
			items: me.getOriginalColumnConfig()
		};
		
		me.id = me.id ? me.id : Ext.id();
		
		var cellEditing = Ext.create("Ext.grid.plugin.CellEditing", {
			clicksToEdit: 1,
			listeners: {
				edit: function(editor, e){
					if(e.field == "file_name")
						me.renameFile(me.getStore().getAt(e.rowIdx));
				}
			}
		});
		
		if(Ext.isArray(me.plugins))
			me.plugins.push(cellEditing);
		else if(Ext.isObject(me.plugins))
		{
			me.plugins = [
				me.plugins,
				cellEditing
			];
		}
		else
			me.plugins = [cellEditing];
		
		me.store = Ext.create("Ext.data.ArrayStore", {
			model: "Sms.file.File",
			data: []
		});
		
		Ext.applyIf(me.fileUploadConfig, {
			buttonOnly: true,
			fieldStyle: "height: 22px;",
			buttonConfig: {
				text:    "Upload File",
				iconCls: "silk-add",
				height:  22
			},
			name:    me.id + "_upload_button"
		});
		
		Ext.applyIf(me.removeButtonConfig, {
			text: "Remove File",
			iconCls: "silk-delete",
			name: me.id + "_remove_button",
			disabled: true,
			handler: function(){
				var records = me.getSelectionModel().getSelection();
				if(records.length)
					me.removeAttachment(records[0]);
			}
		});
		
		var gridButtons = [];
		if(!me.readOnly)
		{
			me.fileUploadField = new Ext.form.field.File(me.fileUploadConfig);
			me.fileUploadField.on("change", function(){
				me.addAttachment();
			});
			var buttonContainer = new Ext.container.Container({
				id:     me.name + "_form",
				height: 22,
				autoEl: {
					tag: "form",
					enctype: "multipart/form-data"
				},
				items: [me.fileUploadField]
			});
			gridButtons.push(buttonContainer);
			
			me.removeFileButton = Ext.create("Ext.button.Button", me.removeButtonConfig);
			gridButtons.push(me.removeFileButton);
		}
		
		me.tbar = gridButtons;
		
		me.bbar = [
			"->",
			"-",
			{xtype: "smscopytoclipboardbutton"},
			"-",
			{
				text:    "Reset Column Configuration",
				handler: function(){
					me.reconfigure(null, me.getOriginalColumnConfig());
				}
			},
			"-"
		];
		
		me.callParent();
	},
	
	getOriginalColumnConfig: function(){
		var me = this;
		
		var columnConfig =  [
			{
				text:      "File ID",
				dataIndex: "file_id",
				width:     100,
				renderer: function(value, metaData){
					metaData.style += "text-align:right;";
					return value;
				}
			},
			{
				text:      "Upload Date",
				dataIndex: "upload_date",
				width:     150,
				renderer: function(value){
					if(Ext.isDate(value))
						return Ext.Date.format(value, "m/d/Y i:s A") + " CT";
					return value;
				}
			},
			{
				text:      "File Name",
				dataIndex: "file_name",
				flex:      1
			},
			{
				text:      "&nbsp;",
				dataIndex: "file_id",
				width:     100,
				renderer: function(value, metaData){
					return "<b><a href=\"#\" name=\"open_link\">Open</a></b>";
				},
				listeners: {
					click: function(gridView, htmlSomething, rowIndex, columnIndex, theEvent){
						var grid = gridView.panel;
						var store = grid.getStore();
						var record = store.getAt(rowIndex);
						var targetName = theEvent.target.name;
						if(targetName == "open_link")
							grid.viewAttachment(record.get("file_id"), record.get("file_name"));
					}
				}
			}
		];
		
		if(!me.readOnly)
		{
			columnConfig[2].editor = {
				xtype:      "textfield",
				maxLength:  100,
				allowBlank: false,
				validator: function(value){
					if(value.match(/\./g) && (value.match(/\./g).length > 1))
						return "File Name cannot contain more than one period.";
					var userMessageFromCharacters = Sms.file.validateFileName(value);
					if(userMessageFromCharacters !== true)
						return userMessageFromCharacters;
					if(!value.split(".")[0].length)
						return "File name cannot be blank";
					return true;
				}
			};
		}
		
		return columnConfig;
	},
	
	onViewReady: function(table, eOpts){
		var me = this;
		
		me.on("selectionchange", me.removeButtonEnableCheck, me);
		
		me.callParent();
	},
	
	getFileUploadField: function(){
		return this.fileUploadField;
	},
	
	removeButtonEnableCheck: function(selectionModel, records){
		var me = this;
		if(me.removeFileButton && records.length)
			me.removeFileButton.enable();
		else
			me.removeFileButton.disable();
	},
	
	addAttachment: function()
	{
		var me = this;
		var fileName = me.fileUploadField.getValue();
		if(fileName)
		{
			fileName = fileName.split("\\")[fileName.split("\\").length - 1];
			var userMessage = Sms.file.validateFileName(fileName);
			if(userMessage !== true)
			{
				Ext.Msg.alert("File Upload", userMessage);
				me.fileUploadField.reset();
				return false;
			}
			
			me.uniqueFileIdentifier = "file_upload_" + Ext.Date.now();
			Ext.util.Cookies.set("unique_file_identifier", me.uniqueFileIdentifier);

			Ext.MessageBox.show({
				title:        "File Upload",
				msg:          "Uploading File...",
				progress:     true,
				progressText: "0%",
				closable:     false});
			Ext.Function.defer(me.fileProgress, 3000, me, [fileName]);
			Ext.Ajax.request({
				url: me.url,
				form: me.name + "_form",
				isUpload: true,
				disableTimeoutRetry: true,
				success: function(response, opts){
					// nothing because it returns instantly
				},
				failure: function(response, opts) {
					var o = Ext.decode(response.responseText);
					me.fileUploadField.reset();
					alert(o.result.errorMessage);
				},
				params: me.extraParamsFunction()
			});
		}
	},
	
	fileProgress: function(fileName)
	{
		var me = this;
		Ext.Ajax.request({
			url: me.url,
			success: function(response)
			{
				var o = Ext.decode(response.responseText);
				if(o.percent == "DATABASE")
				{
					Ext.MessageBox.updateProgress(1,"Processing...", "Uploading File...");
					Ext.Function.defer(me.fileProgress, 3000, me, [fileName]);
				}
				else if(o.percent == "COMPLETE")
				{
					me.fileUploadField.reset();
					me.getStore().insert(0, o.custom_data.new_file_data);
					
					me.uploadCompleteFunction(o);
					Ext.MessageBox.hide();
				}
				else if(o.percent == "FAILED")
				{
					me.fileUploadField.reset();
					Ext.MessageBox.hide();
					Ext.Msg.alert("File Too Large", "Can't upload files larger than 10mb");
				}
				else
				{
					Ext.MessageBox.updateProgress(o.percent / 100, o.percent + "%", "Uploading File...");
					Ext.Function.defer(me.fileProgress, 3000, me, [fileName]);
				}
			},
			failure: function(response, o) {
				me.fileUploadField.reset();
				alert(o.statusText);
				Ext.MessageBox.hide();
			},
			params: {
				unique_file_identifier: me.uniqueFileIdentifier
			}
		});
	},
	
	removeAttachment: function(record)
	{
		var me = this;
		
		var params = me.extraParamsFunction();
		Ext.apply(params, {
			file_id:    record.get("file_id"),
			context:    "FILE_DELETE"
		});
		if(confirm("Are you sure you want to delete the attachment: " + record.get("file_name") + "?"))
		{
			me.setLoading("Deleting File...");
			Ext.Ajax.request({
				url: me.url,
				disableTimeoutRetry: true,
				success: function(response, o)
				{
					var respText = Ext.decode(response.responseText);
					me.deleteCompleteFunction(respText.mod_by_employee);
					me.getStore().remove(record);
					me.setLoading(false);
				},
				failure: function(response, o) {
					var responseObject = Ext.decode(response.responseText);
					alert(responseObject.errorMessage);
				},
				params: params
			});
		}
	},
	
	viewAttachment: function(fileId, fileName)
	{
		var me = this;
		var params = me.extraParamsFunction();
		params["file_id"] = fileId;
		params["file_name"] = fileName;
		Sms.file.viewAttachment(params);
	},
	
	renameFile: function(record){
		var me = this;
		
		var newFileName = record.get("file_name");
		if(newFileName.indexOf(".") == -1)
			newFileName += "." + record.get("file_extension");
		
		var fileNamePieces = newFileName.split(".");
		if(newFileName.length > 100)
		{
			var extraLength = newFileName.length - 100;
			newFileName = fileNamePieces[0].substring(0, fileNamePieces[0].length - extraLength) + "." + fileNamePieces[1];
		}
		record.set("file_name", newFileName);
		record.set("file_extension", fileNamePieces[1]);
		
		var params = me.extraParamsFunction();
		Ext.apply(params, {
			file_id:    record.get("file_id"),
			context:    "FILE_RENAME",
			file_name:  newFileName
		});
		
		me.setLoading("Renaming File...");
		Ext.Ajax.request({
			url: me.url,
			disableTimeoutRetry: true,
			success: function(response, o)
			{
				me.setLoading(false);
			},
			failure: function(response, o) {
				var responseObject = Ext.decode(response.responseText);
				alert(responseObject.errorMessage);
			},
			params: params
		});
	}
});