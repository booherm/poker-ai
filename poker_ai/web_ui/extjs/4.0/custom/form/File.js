Sms.file.fieldReferences = {};

Sms.file.currentReferenceNumber = 0;

Sms.file.removeAttachment = function(referenceNumber, fileName){
	var field = Sms.file.fieldReferences[referenceNumber];
	field.removeAttachment(fileName);
};

Sms.file.viewAttachmentByName = function(referenceNumber, fileName)
{
	var field = Sms.file.fieldReferences[referenceNumber];
	var params = field.extraParamsFunction();
	var desktopApp = typeof exeoutput !== "undefined";
	
	if (desktopApp) {
		Ext.apply(params, {file_name: fileName});
		Sms.file.viewAttachment(params);
	}
	else {
		var url = "FileDownloader";
		var first = true;
		for(var i in params)
		{
			if(first)
				url += "?";
			else
				url += "&";
			url += i + "=" + encodeURIComponent(params[i]);
			first = false;
		}
		if(first)
			url += "?";
		else
			url += "&";
		url += "file_name=" + encodeURIComponent(fileName);

		document.location = url;
	}
};

Ext.define("Sms.form.field.File", {
	
	attachmentsConfig: {
		width: 500
	},

	fileUploadConfig: {
		buttonOnly: true,
		buttonText: "Upload File",
		//name:       PmProjectManagement.project.idPrepend + "attachment_upload",
		listeners: {
			change: function(){
				PmProjectManagement.project.addAttachment();
			}
		}
	},
	
	// The default config
	extraParamsFunction: function(){return {};},
	name:     "",
	url:      "",
	readOnly: false,
	uniqueFileIdentifier: "",
	hyperlink:    true,
	removeOption: true,
	singleFile:   false,
	fieldLabel:   "Attachments",
	labelWidth:   150,
	uploadCompleteFunction: function(){return {};},
	deleteCompleteFunction: function(){return {};},

    constructor: function(config) {
		var me = this;
		Ext.apply(me, config);
		
		Ext.apply(me.fileUploadConfig, {
			name:      me.name,
			listeners: {
				change: function(){
					me.addAttachment();
				}
			}
		});
		
		var fileItems = [];
		me.attachmentsField = new Ext.form.field.Display(me.attachmentsConfig);
		fileItems.push(me.attachmentsField);
		if(!me.readOnly)
		{
			me.fileUploadField = new Ext.form.field.File(me.fileUploadConfig);
			var buttonContainer = new Ext.container.Container({
				id:     me.name + "_form",
				autoEl: {
					tag: "form",
					enctype: "multipart/form-data"
				},
				items: [me.fileUploadField]
			});
			fileItems.push(buttonContainer);
		}
		me.fieldContainer = new Ext.form.FieldContainer({
			fieldLabel: me.fieldLabel,
			labelWidth: me.labelWidth,
			width:  850,
			layout: "column",
			items:  fileItems
		});
		
		//register this class in the namespace for file deletion references
		Sms.file.fieldReferences[Sms.file.currentReferenceNumber] = me;
		me.referenceNumber = Sms.file.currentReferenceNumber;
		Sms.file.currentReferenceNumber = Sms.file.currentReferenceNumber + 1;
		
		if(me.value)
			me.setValue(me.value);
		
		return me;
	},
	
	setValue: function(valueArray){
		var me = this;
		if(valueArray == null)
			valueArray = [];
		me.value = valueArray;
		var displayHtml = me.createFileListDisplay(valueArray, me.readOnly);
		if(me.attachmentsField)//make sure the attachments field has been made
			me.attachmentsField.setValue(displayHtml);
	},
	
	createFileListDisplay: function(attachmentsArray, readOnly)
	{
		var me = this;
		var attachmentsDisplay = "<table style='table-layout:fixed;display:inline;' width='460px'>";
		
		if (me.singleFile == true && attachmentsArray.length >= 1)
		{
			attachmentsArray[0] = attachmentsArray[attachmentsArray.length - 1];
			attachmentsArray.length = 1;
		}
		
		attachmentsArray.sort();
		for(var i = 0; i < attachmentsArray.length; i++)
		{
			if (me.hyperlink == false)
			{
				attachmentsDisplay += "<tr><td width='400px'>" + attachmentsArray[i] + "</td><td>";
			}
			else
			{
				attachmentsDisplay += "<tr><td width='400px'><a onclick='Sms.file.viewAttachmentByName(" + this.referenceNumber + ",\"" + attachmentsArray[i]
					+ "\")' style='font-weight:bold;color:#1F497D;cursor:pointer;text-decoration:underline;' onmouseover='this.style.color=\"#F79646\";' onmouseout='this.style.color=\"#1F497D\";' title=\"" + attachmentsArray[i] + "\">" + attachmentsArray[i]
					+ "</a></td><td>";
			}
		
			if (me.removeOption == true)
			{
				if(readOnly)
					attachmentsDisplay += "&nbsp;";
				else
				{
					attachmentsDisplay += "<a onclick='Sms.file.removeAttachment(" + this.referenceNumber + ",\"" + attachmentsArray[i]
						+ "\")' style='font-weight:bold;color:#1F497D;cursor:pointer;font-weight:bold;text-decoration:underline;' onmouseover='this.style.color=\"#F79646\";' onmouseout='this.style.color=\"#1F497D\";'>Remove</a>";
				}
				attachmentsDisplay += "</td></tr>";
			}
		}
		
		if(attachmentsArray.length == 0)
			attachmentsDisplay += "<tr><td width='400px'>&nbsp;</td><td>&nbsp;</td><tr>";
		attachmentsDisplay += "</table>";
		return attachmentsDisplay;
	},
	
	getContainer: function(){
		return this.fieldContainer;
	},
	
	getFileUploadField: function(){
		return this.fileUploadField;
	},
	
	getAttachmentsField: function(){
		return this.attachmentsField;
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
			var overWrite = false;
			for(var i = 0; i < me.value.length; i++)
				overWrite = overWrite || fileName == me.value[i];

			if(!overWrite || confirm("Are you sure you want to overwrite: " + fileName))
			{
				me.uniqueFileIdentifier = "file_upload_" + Ext.Date.now();
				Ext.util.Cookies.set("unique_file_identifier", me.uniqueFileIdentifier);
				
				Ext.MessageBox.show({
					title:        "File Upload",
					msg:          "Uploading File...",
					progress:     true,
					progressText: "0%",
					closable:     false});
				Ext.Function.defer(me.fileProgress, 3000, me, [fileName, overWrite]);
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
			else
				me.fileUploadField.reset();
		}
	},
	
	fileProgress: function(fileName, isOverWrite)
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
					Ext.Function.defer(me.fileProgress, 3000, me, [fileName,isOverWrite]);
				}
				else if(o.percent == "COMPLETE")
				{
					if(!isOverWrite)
						me.value.push(o.file_name);
					me.attachmentsField.setValue(me.createFileListDisplay(me.value, me.readOnly));
					me.fileUploadField.reset();
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
					Ext.Function.defer(me.fileProgress, 3000, me, [fileName,isOverWrite]);
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
	
	removeAttachment: function(fileName)
	{
		var me = this;
		
		var params = me.extraParamsFunction();
		Ext.apply(params, {
			file_name:  fileName,
			context:    "FILE_DELETE"
		});
		if(confirm("Are you sure you want to delete the attachment: " + fileName + "?"))
		{
			Ext.Ajax.request({
				url: me.url,
				disableTimeoutRetry: true,
				success: function(response, o)
				{
					if (response.responseText !== ""){
						var responseObject = Ext.decode(response.responseText);
						me.deleteCompleteFunction(responseObject);
					}
					var attachList = me.value;
					Ext.Array.remove(attachList, fileName);//this is so slick...
					me.setValue(attachList);
				},
				failure: function(response, o) {
					var responseObject = Ext.decode(response.responseText);
					alert(responseObject.errorMessage);
				},
				params: params
			});
		}
	}
});