//this file is meant to hold all functions and definitions that are shared by all file extensions
Ext.ns("Sms.file");

//please try to keep this array in sync with UtilityMethods.invalidFilenameCharacters
Sms.file.invalidFilenameCharacters = [
	{
		character: "\\",
		description: "backslash"
	},
	{
		character: "/",
		description: "forward slash"
	},
	{
		character: ":",
		description: "colon"
	},
	{
		character: "*",
		description: "star"
	},
	{
		character: "?",
		description: "question mark"
	},
	{
		character: "\"",
		description: "double quote"
	},
	{
		character: "<",
		description: "less than symbol"
	},
	{
		character: ">",
		description: "greater than symbol"
	},
	{
		character: "|",
		description: "pipe"
	},
	{
		character: ",",
		description: "comma"
	},
	{
		character: "'",
		description: "single quote"
	}
];

Ext.define("Sms.file.File", {
	extend: "Ext.data.Model",
	fields: [
		{name:"file_id",  type:"int"},
		{name:"upload_date",    type:"date", dateFormat: "m/d/Y i:s A"},
		{name:"file_name",      type:"string"},
		{name:"file_extension", type:"string"},
		{name:"unique_file_name", type:"string"}
	]
});

/**
* Checks to see if the user has been prompted to download the file or has started to download the file
* and takes appropriate action
* 
* @param {Integer} cacheBusterId Is the unique timestamp of when the user sent the request to the server to download the file
* @param {Function} dialogueLoadHandler Function called when user is prompted for download (or download begins in the case of no prompt)
* @param {Integer} attemptCount Current attempt on checking whether the file download has started or not
* @param {Ext.dom.AbstractElement} downloadIFrame A reference to the dom of the div containing the download iframe
*/
Sms.file.checkFileDialogueStart = function(cacheBusterId, dialogueLoadHandler, attemptCount, downloadIFrame){
	attemptCount++;
	var isSuccessful = Ext.util.Cookies.get("file_download_" + cacheBusterId) == "Y";//see if the cookies indicate a successful download start
	if(isSuccessful || attemptCount > 300)//if the request is successful or has exceeded the maximum allowed attempts
	{
		Sms.file.fileDownloadComplete(downloadIFrame, dialogueLoadHandler, isSuccessful);
	}
	else
		Ext.Function.defer(Sms.file.checkFileDialogueStart, 2000, this, [cacheBusterId, dialogueLoadHandler, attemptCount, downloadIFrame]);//retry
};

Sms.file.desktopAppFileDownloadComplete = function(cacheBusterId, success) {
	if (Sms.file.downloadIFrameHash) {
		var h = Sms.file.downloadIFrameHash[cacheBusterId];
		if (h) {
			Sms.file.fileDownloadComplete(h.downloadIFrame, h.dialogueLoadHandler, "true" === success);
		} else {
			alert('desktopAppFileDownloadComplete - Not found');
		}
	} else {
		alert('no Sms.file.downloadIFrameHash');
	} 
};

Sms.file.fileDownloadComplete = function(downloadIFrame, dialogueLoadHandler, isSuccessful){
	downloadIFrame.destroy();//clean up the iframe, it's no longer needed
	if(dialogueLoadHandler)//call the disalogue handler if it exists
		dialogueLoadHandler(isSuccessful);	
};

/**
* Downloads a file using FileDownloader servlet.
* 
* @param {Object} params Parameters to send to FileDownloader (do not use the property "cache_buster" or it will be overwritten)
*     It is not recommented to use to many or long parameter names or values since they are encoded into the url.
* @param {Function} [dialogueLoadHandler] Function called when user is prompted for download (or download begins in the case of no prompt)
*/
Sms.file.viewAttachment = function(params, dialogueLoadHandler)
{
	var desktopApp = typeof exeoutput !== "undefined";
	var url = desktopApp ? "ghe://heserver/sms.php" : "FileDownloader";
	var first = true;
	if (desktopApp) {
		var command = "sms.SetSessionId|" + Ext.util.Cookies.get("JSESSIONID");
		exeoutput.RunHEScriptCom(command);
	}
	var cacheBusterId = (new Date()).getTime();
	params["cache_buster"] = cacheBusterId;//add the cache buster into the request parameters
	
	//create an iframe specifically for downloading this single file in the html
	var downloadIFrameHtml = "<div style=\"display:none;\">"
		+ "<iframe name=\"file_download_iframe\" id=\"file_download_iframe\" src=\"blank.jsp\"></iframe>"
		+ "<form action=\"" + url + "\" method=\"post\" target=\"file_download_iframe\">";

	for(var i in params)
		downloadIFrameHtml += "<input type=\"hidden\" name=\"" + i + "\"/>";

	downloadIFrameHtml += "</form></div>";
	var downloadIFrame = Ext.getBody().createChild(downloadIFrameHtml);
	//end creation of iframe in html
	
	//fill form values with the parameters
	var form = downloadIFrame.last();
	for(var i in params)
	{
		var input = form.down("input[name=\"" + i + "\"]");
		input.dom.value = params[i];
	}
	
	if(desktopApp)
	{
		var iframe = downloadIFrame.first();
		//this next line only works when there is no download dialog window, so limited to desktop app
		iframe.dom.addEventListener("load", dialogueLoadHandler);
	}
	
	//request the file by submitting the form to the iframe
	form.dom.submit();
	
	//start checking to see if the download has started
	if (!desktopApp)
		Ext.Function.defer(Sms.file.checkFileDialogueStart, 2000, this, [cacheBusterId, dialogueLoadHandler, 0, downloadIFrame]);
	else {
		if (!Sms.file.downloadIFrameHash)
			Sms.file.downloadIFrameHash = {};
		
		Sms.file.downloadIFrameHash[cacheBusterId] = {
			downloadIFrame:      downloadIFrame,
			dialogueLoadHandler: function(){}
		};
		
	}
	
	return cacheBusterId;
};

Sms.file.validateFileName = function(fileName){
	fileName = fileName.split("\\")[fileName.split("\\").length - 1];
	var invalidCharactersPresent = "";
	for(var i = 0; i < Sms.file.invalidFilenameCharacters.length; i++)
	{
		var character = Sms.file.invalidFilenameCharacters[i].character,
			description = Sms.file.invalidFilenameCharacters[i].description;
		if(fileName.indexOf(character) != -1)
		{
			if(invalidCharactersPresent.length)
				invalidCharactersPresent += ", ";
			invalidCharactersPresent += description + ":(" + character + ")";
		}
	}
	if(invalidCharactersPresent.length)
	{
		var userMessage = "Filenames can not contain these characters: " + invalidCharactersPresent + ".\nPlease remove this character and retry your upload.";
		return userMessage;
	}
	return true;
};