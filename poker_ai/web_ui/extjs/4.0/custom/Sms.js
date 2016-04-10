Ext.ns(
	"Sms.form",
	"Sms.picker",
	"Sms.proxy",
	"Sms.button"
);

Ext.apply(Sms, {
	badRequestHash: {},
	browseAwayConfirmMessage: "You have unsaved changes on this page.",
	confirmBrowseAwayRegistered: false,
	globalRequestId: 1,
	unloading: false,
	uiMessages: {
		invalidCriteria: "There are problems with the given criteria that must be corrected before submitting.",
		missingCriteria: "Select your criteria and click submit.",
		noDataFound:     "There is no data to display using the selected criteria.",
		invalidFields:   "Fields are invalid, please correct and try again."
	}
});

Sms.setPageUnloadVariable = function(){
	Sms.unloading = true;
};

Sms.handleAjaxFailure = function(requestObject){
	// Make sure this isn't DEV, set by JsErrorHandler ct
	if(!window.sendAjaxCallErrors){
		return;
	}
	
	var requestOptions = requestObject.request.options;
	var params = {
		error_type:           "AJAX",//tell the js_error_handler this is a special type of javascript error
		original_params:      Ext.encode(requestOptions.params),
		original_timeout:     requestOptions.timeout,
		original_url:         requestOptions.url,
		response_status:      requestObject.status,
		response_status_text: requestObject.statusText,
		response_text:        requestObject.responseText,
		session_dump:         window.smsSessionDump,
		is_timeout:           !!requestObject.timedout
	};

	Ext.Ajax.request({
		url: "js_error_handler.jsp",
		params: params,
		stopErrorReporting: true, //stop possible infinite loops
		failure: function(response, opts){
			throw "Ajax caller error handler";// see if the regular javascript error handler will catch this
		}
	});
};

// functions for confirming browse away while changes are not saved
Sms.getBrowseAwayConfirmMessage = function(event){
	if(Ext.isGecko || Ext.isIE7){
		event.returnValue = Sms.browseAwayConfirmMessage;
	}
	else{
		return Sms.browseAwayConfirmMessage;
	}
};

Sms.regConfirmBrowseAway = function(confirmMessage){
	// if desktop app set global variable indicating changes
	if (typeof exeoutput !== "undefined")
		exeoutput.SetGlobalVariable("confirmBrowseAwayRegistered", "true", false);
	
	if(Sms.confirmBrowseAwayRegistered){
		return;
	}
	
	if(!window.Nav && (window.top !== window)){
		window.top.Sms.regConfirmBrowseAway();
	}

	if(confirmMessage !== null && typeof confirmMessage !== "undefined"){
		Sms.browseAwayConfirmMessage = confirmMessage;
	}
	
	// if desktop app set global variable indicating no changes
	if (typeof exeoutput !== "undefined")
		exeoutput.SetGlobalVariable("browseAwayConfirmMessage", Sms.browseAwayConfirmMessage, false);

	Ext.EventManager.on(window, "beforeunload", Sms.getBrowseAwayConfirmMessage, Sms);
	
	Sms.confirmBrowseAwayRegistered = true;
};

Sms.deregConfirmBrowseAway = function(){
	
	if (typeof exeoutput !== "undefined")
		exeoutput.SetGlobalVariable("confirmBrowseAwayRegistered", "false", false);
	
	if(!Sms.confirmBrowseAwayRegistered){
		return;
	}
	
	if(!window.Nav && (window.top !== window)){
		window.top.Sms.deregConfirmBrowseAway();
	}

	Sms.deregConfirmBrowseAwayEvent();
	Sms.confirmBrowseAwayRegistered = false;
};

Sms.deregConfirmBrowseAwayEvent = function(){
	Ext.EventManager.un(window, "beforeunload", Sms.getBrowseAwayConfirmMessage, Sms);
};

Sms.getScreenHelpToolConfig = function(destination){
	return {
		type:    "help",
		tooltip: "Help",
		handler: function(){
			window.open("user_guide/sms_user_guide.pdf#pagemode=bookmarks&zoom=78.8&nameddest=" + destination,
				"_blank", "toolbar=0,location=0,status=0,menubar=0,left=20,top=20,width=1000,height=800,resizable=1");
		}
	};
};

Sms.registerOnUnload = function(saveDataFunction) {
	if(!Sms.onUnloadIsSetup)
	{
		if(window.addEventListener)
		{
			window.addEventListener("unload", Sms.unloadHandler, false);
		}
		else if (window.attachEvent)
		{
			window.attachEvent("onunload", Sms.unloadHandler); 
		}		
		
		Sms.onUnloadIsSetup = true;
		Sms.saveDataFunctions = [];
	}

	Sms.saveDataFunctions.push(saveDataFunction);
};

Sms.unloadHandler = function()
{
	if (!Sms.saveDataFunctions)
		Sms.saveDataFunctions = [];
	
	for (var i=0;i<Sms.saveDataFunctions.length;i++)
	{ 
		var saveDataFunction = Sms.saveDataFunctions[i];
		saveDataFunction();
	}
};

Sms.form.getPhoneDisplayValue = function(value){
	if(value && value.length >= 10){
		return "(" + value.substr(0,3) + ") " + value.substr(3,3) + "-" + value.substr(6, 4)
			+ ((value.length > 10) ? (" ext. " + value.substr(10)) : "");
	}
	return value;
};

//extremely helpful to get field values for database format (ExecuteProcedure)
Sms.form.getFieldValue = function(field){
	var className = field.$className;

	if(className === "Ext.form.RadioGroup"){
		return field.getValue()[field.getId() + "_options"];
	}
	else if(className === "Ext.form.CheckboxGroup"){
		var values = field.getValue()[field.getId() + "_checkbox"];
		if(!Ext.isArray(values)){
			values = [values];
		}
		return Ext.encode(values);
	}
	else if(className === "Ext.form.field.Checkbox"){
		return field.getValue() ? "Y" : "N";
	}
	else if(className === "Ext.form.field.Time"){
		//times suck
		var theTime = field.getValue();
		if(Ext.isDate(theTime)){
			return "01/01/1900 " + Ext.Date.format(theTime, "h:i:s A");
		}
	}
	else if(className === "Ext.form.field.Date"){
		var installDate = field.getValue();
		if(Ext.isDate(installDate)){
			return Ext.Date.format(installDate, "m/d/Y");
		}
	}
	else if(className === "Ext.ux.form.field.BoxSelect" || className === "Ext.ux.form.ItemSelector" || className === "Ext.ux.form.MultiSelect"){
		return Ext.encode(field.getValue());
	}
	else{
		return field.getValue();
	}
	
	return null;
};

//an attempt to create a function that returns a display value for fields we use, this should also help with standardizing how each
//field type is displayed with an Ext.form.field.Display field, defaults to Sms.getFieldValue if doesn't need special logic
Sms.form.getFieldDisplayValue = function(field){
	var className = field.$className;
	var fieldStore;

	if(className === "Ext.ux.form.field.BoxSelect" || className === "Ext.ux.form.ItemSelector"){
		fieldStore = field.getStore();
		fieldStore.clearFilter();
		var listValue = "";
		var valueArray = field.getValue();
		for(var i = 0; i < valueArray.length; i++){
			if(listValue.length > 0){
				listValue = listValue + "<br/>";
			}
			var recordIndex = fieldStore.findExact(field.initialConfig.valueField, valueArray[i]);
			if(recordIndex !== -1){
				var record = fieldStore.getAt(recordIndex);
				listValue = listValue + record.get(field.initialConfig.displayField);
			}
			else{
				listValue = listValue + valueArray[i];
			}
		}
		return listValue;
	}
	else if(className === "Ext.form.field.ComboBox"){
		fieldStore = field.getStore();
		fieldStore.clearFilter();
		var recordIndex = fieldStore.findExact(field.initialConfig.valueField, field.getValue());
		if(recordIndex !== -1){
			return fieldStore.getAt(recordIndex).get(field.initialConfig.displayField);
		}
		return "";
	}
	else if(className === "Ext.ux.form.field.Hours"){
		return field.getDisplayValue();
	}
	else{
		return Sms.form.getFieldValue(field);
	}
};

//either input the empty panel text, or a config object for a panel, with the property
//panelText for the text displayed
Sms.getEmptyPanel = function(config){
	var panelText = "";
	if(!Ext.isObject(config)){
		panelText = config;
	}
	else{
		panelText = config.panelText;
		delete config.panelText;
	}
	
	var emptyPanelConfig = {
		hideTitle: true,
		html: {
			tag: "table",
			style: {
				width: "100%",
				height: "100%"
			},
			cn: [{
				tag: "tr",
				cn: [{
					tag: "td",
					style: {
						width: "100%",
						height: "100%"
					},
					"class": "label_center",
					html: panelText
				}]
			}]
		}
	};
	
	if(Ext.isObject(config)){
		Ext.applyIf(config , emptyPanelConfig);
	}
	else{
		config = emptyPanelConfig;
	}
	
	return Ext.create("Ext.panel.Panel", config);
};

Sms.redirectSubPage = function(url){
	if(Sms.confirmBrowseAwayRegistered){
		Ext.Msg.confirm("Unsaved Changes", Sms.browseAwayConfirmMessage + "&nbsp;&nbsp;Are you sure you want to browse away?",
			function(buttonId){
				if(buttonId === "yes"){
					Sms.deregConfirmBrowseAway();
					document.location = url;
				}
			}
		);
	}
	else{
		document.location = url;
	}
};

Sms.uiAlert = function(alertCode){
	var title;
	var message;
	
	if(alertCode === "INVALID_CRITERIA"){
		title = "Invalid Criteria";
		message = Sms.uiMessages.invalidCriteria;
	}
	else if(alertCode === "INVALID_FIELDS"){
		title = "Invalid Fields";
		message = Sms.uiMessages.invalidFields;
	}
	
	Ext.Msg.alert(title, message);
};

Sms.log = function(out){
	if(Sms.environment === "DEV" && window.console && typeof console.log !== "undefined"){
		console.log(out);
	}
};

Sms.removeSWF = function(obj){
	if(!obj){
		return;
	}
	if(Ext.isIE){
		obj.style.display = "none";
		(function(){
			if(obj.readyState === 4){
				for(var i in obj){
					if(typeof obj[i] === "function"){
						obj[i] = null;
					}
				}
				if(obj.parentNode && typeof obj.parentNode.removeChild === "function"){
					obj.parentNode.removeChild(obj);
				}
			}
			else{
				setTimeout(arguments.callee, 10);
			}
		})();
	}
	else{
		obj.parentNode.removeChild(obj);
	}
};

Sms.getLinkHtml = function(displayValue, onclickJs){
	return "<span style=\"font-weight:bold; color:#1F497D; text-decoration:underline\"; "
		+ "onclick = \"" + onclickJs + "\""
		+ "onmouseover = \"this.style.color = '#F79646'; this.style.cursor='pointer'\""
		+ "onmouseout = \"this.style.color = '#1F497D';\""
		+ ">" + displayValue + "</span>";
};

Sms.getViewServiceOrderLink = function(sourceCrm, sohTransId, sorNumber, sorSoSequence){
	return Sms.getLinkHtml(sohTransId, "Sms.viewServiceOrder('"
		+ sourceCrm + "', " + sohTransId + ", " + sorNumber + ", " +  sorSoSequence + ");");
};

Sms.getTemplateViewServiceOrder = function(sourceCrm, sohTransId, sorNumber, sorSoSequence){
	var tpl = new Ext.XTemplate(
		Sms.getLinkHtml("{" + sohTransId + "}", "Sms.viewServiceOrder('"
			+ sourceCrm + "', " + sohTransId + ", " + sorNumber + ", " +  sorSoSequence + ");"),
		{disableFormats: true}
	);
	return tpl;
};

Sms.getTemplateViewSurvey = function(recordNumber){
	var tpl = new Ext.XTemplate(
		"<span style='font-weight:bold;'>" +
			"<tpl if='" + recordNumber + "'>" + Sms.getLinkHtml(recordNumber, "Sms.viewSurvey('{" + recordNumber + "}');") +
			"<tpl else>{" + recordNumber + "}</tpl>" +
		"</span>",
		{disableFormats: true}
	);
	return tpl;
};

Sms.getTemplateViewConfirmitPeriodicSurvey = function(surveyResponseId){
	var tpl = new Ext.XTemplate(
		"<span style='font-weight: bold;'>",
			"<tpl if='", surveyResponseId, "'>",
				Sms.getLinkHtml("{" + surveyResponseId + "}", "Sms.viewConfirmitPeriodicSurvey({" + surveyResponseId + "});"),
			"</tpl>",
		"</span>",
		{disableFormats: true}
	);
	
	return tpl;
};

Sms.viewServiceOrder = function(sourceCrm, sohTransId){
	if(sourceCrm) {
		if(sourceCrm === "SAP") {
			// open SO in the SOWL SO editor
			window.open("view_sowl_so.jsp?soh_trans_id=" + (sohTransId || ""), "_blank",
				"height=870,width=1275,top=30,left=30,location=no,menubar=no,status=no,toolbar=no,resizable=yes,scrollbars=yes");
		}
		else {
			window.open("view_service_order.jsp?sms_source_crm=" + sourceCrm + "&soh_trans_id=" + (sohTransId || ""), "_blank",
				"height=800,width=955,top=30,left=200,location=no,menubar=no,status=no,toolbar=no,resizable=yes,scrollbars=yes");
		}
	}
};

Sms.viewSurvey = function(surveyRecordNumber){
	window.open("view_survey.jsp?record_number=" + surveyRecordNumber, "_blank",
		"height=875,width=955,top=30,left=200,location=no,menubar=no,status=no,toolbar=no,resizable=yes,scrollbars=yes");
};

Sms.viewMSORServiceOrder = function(sorNumber, soSequence){
	window.open("view_service_order.jsp?sor_number=" + (sorNumber || "") + "&sor_so_sequence=" + soSequence,"_blank",
		"height=800,width=955,top=30,left=200,location=no,menubar=no,status=no,toolbar=no,resizable=yes,scrollbars=yes");
};

Sms.viewConfirmitPeriodicSurvey = function(surveyResponseId){
	window.open("view_cnfp_survey.jsp?survey_response_id=" + surveyResponseId, "_blank",
		"height=875,width=955,top=30,left=200,location=no,menubar=no,status=no,toolbar=no,resizable=yes,scrollbars=yes");
};

Sms.viewConfirmitPeriodicSurveyAlert = function(surveyResponseId){
	window.open("view_cnfp_survey_alert.jsp?survey_response_id=" + surveyResponseId, "_blank",
		"height=400,width=800,top=30,left=200,location=no,menubar=no,status=no,toolbar=no,resizable=no,scrollbars=yes");
};

Sms.viewChatTranscript = function(filter, transcriptId){
	window.open("view_chat_transcript.jsp?transcript_id=" + transcriptId + "&filter=" + filter, "_blank",
		"height=600,width=800,top=30,left=200,location=no,menubar=no,status=no,toolbar=no,resizable=yes,scrollbars=yes");
};

//opens a read only view of a single project by the project id or any id contained in the project and then selects the nodeId
Sms.viewPmItem = function(nodeId){
	window.open("pm_project_management.jsp?screen_mode=VIEW_ITEM_READ_ONLY&select_node_id=" + nodeId, "_blank",
		"height=800,width=1350,top=30,left=200,location=no,menubar=no,status=no,toolbar=no,resizable=yes,scrollbars=yes");
};

//opens a read only view of a single request
Sms.viewBpiRequest = function(requestId){
	window.open("rq_container.jsp?screen_mode=VIEW_ITEM_READ_ONLY&request_id=" + requestId, "_blank",
		"height=800,width=900,top=30,left=200,location=no,menubar=no,status=no,toolbar=no,resizable=yes,scrollbars=yes");
};

//opens a read only or edit view of a customer view
Sms.viewCustomerView = function(viewId){
	window.open("cust_view.jsp?view_id=" + viewId + "&read_only=true", "_blank",
		"height=800,width=800,top=30,left=200,location=no,menubar=no,status=no,toolbar=no,resizable=yes,scrollbars=yes");
};

Sms.viewCustomerHierarchy = function(customerIdType, customerId){
	window.open("view_customer_hierarchy.jsp?customer_id_type=" + customerIdType + "&customer_id=" + customerId, "_blank",
		"height=500,width=900,top=30,left=200,location=no,menubar=no,status=no,toolbar=no,resizable=yes");
};

Sms.viewCustomerInfo = function(customerId){
    var customerType = "SAP_ID";
	window.open("view_customer_info.jsp?customer_type=" + customerType + "&customer_id=" + customerId, "_blank",
		"height=450,width=600,top=80,left=240,location=no,menubar=no,status=no,toolbar=no,resizable=yes,scrollbars=yes");
};

Sms.viewCustomerInfoTemp = function(customerType, customerId){
	window.open("view_customer_info.jsp?customer_type=" + customerType + "&customer_id=" + customerId, "_blank",
		"height=450,width=600,top=80,left=240,location=no,menubar=no,status=no,toolbar=no,resizable=yes,scrollbars=yes");
};

Sms.viewSapPersonInfo = function(personId){
	window.open("view_sap_person_info.jsp?person_id=" + personId, "_blank",
		"height=400,width=500,top=80,left=240,location=no,menubar=no,status=no,toolbar=no,resizable=yes,scrollbars=yes");
};

Sms.viewAsorServiceOrder = function(sohTransId){
	window.open("view_service_order.jsp?asor_soh_trans_id=" + sohTransId, "_blank",
		"height=800,width=955,top=30,left=200,location=no,menubar=no,status=no,toolbar=no,resizable=yes,scrollbars=yes");
};

Sms.viewBridgeRoutineDetailWindow = function(bridgeRoutineId){
	window.open("view_bridge_routine_field_detail.jsp?bridge_routine_id=" + bridgeRoutineId, "_blank",
		"height=600,width=955,top=30,left=200,location=no,menubar=no,status=no,toolbar=no,resizable=yes,scrollbars=yes");
};

Sms.viewJiraIssue = function(jiraIssueTrackerUrl, issueId)
{
	var url = jiraIssueTrackerUrl + "/" + issueId;
	window.open(url,'_blank','toolbar=1,location=1,directories=1,status=1,menubar=1,scrollbars=1,resizable=1');
};

/**
 * Opens a new browser window to view a bra_data_file's text and scrolls to a line
 *
 * @param {String} fileRevisionId Id of the file to load
 * @param {String} scrollToLineNumber Line number in the file to scroll to
 */
Sms.viewBraFileAtLine = function(fileRevisionId, scrollToLineNumber){
	Sms.viewBraFile({
		fileRevisionId: fileRevisionId,
		scrollToLineNumber: scrollToLineNumber
	});
};

/**
 * Opens a new browser window to view a bra_data_file's text and highlights and
 * scrolls to a bridge routine.
 * 
 * @param {String} fileRevisionId Id of the file to load
 * @param {String} bridgeRoutineId Id of a bridge routine in the file to
 * highlight and scroll to
 */
Sms.viewBraFileBridgeRoutine = function(fileRevisionId, bridgeRoutineId){
	Sms.viewBraFile({
		fileRevisionId: fileRevisionId,
		bridgeRoutineId: bridgeRoutineId
	});
};

/**
 * Opens a new browser window to view a bra_data_file's text with options to
 * highlight and scroll to lines in the file.
 *
 * @param {Object/String} options ID of the file to load or options object
 * containing the ID of the file to load
 * @param {String} options.fileRevisionId Id of the file to load
 * @param {String} [options.bridgeRoutineId] Id of a bridge routine in the file
 * to highlight and scroll to
 * @param {String} [options.scrollToLineNumber] Line number in the file to scroll to
 * @param {String} [options.highlightStart] Line number to start highlighting lines at
 * @param {String} [options.highlightEnd] Line number to end highlighting lines at
 */
Sms.viewBraFile = function(options){
	var fileRevisionId = options;
	if(Ext.isObject(options)){
		fileRevisionId = options.fileRevisionId;
	}
	var windowLink = "view_bridge_routine_file.jsp?file_revision_id=" + fileRevisionId;
	if(options.bridgeRoutineId){
		windowLink += "&bridge_routine_id=" + options.bridgeRoutineId;
	}
	if(options.scrollToLineNumber){
		windowLink += "&scroll_to_line=" + options.scrollToLineNumber;
	}
	if(options.highlightStart){
		windowLink += "&highlight_start=" + options.highlightStart;
	}
	if(options.highlightEnd){
		windowLink += "&highlight_end=" + options.highlightEnd;
	}

	window.open(windowLink, "_blank",
		"height=800,width=955,top=30,left=200,location=no,menubar=no,status=no,toolbar=no,resizable=yes,scrollbars=yes");
};

Sms.getSecondsFromEpoch = function(theDate){
	if(Ext.isDate(theDate)){
		return parseInt(Ext.Date.format(theDate, "U"), 10);
	}
	return null;
};

Sms.getLocalStorage = function()
{
	if (typeof exeoutput !== "undefined"){
		var LocalStorageClass = Ext.extend(Ext.util.Observable, {
			constructor: function(config){
				// Call our superclass constructor to complete construction process.
				this.data = {};

				LocalStorageClass.superclass.constructor.call(this, config);
			},
			setItem: function(propertyName, value){
				exeoutput.SetGlobalVariable(propertyName, value, true);
			},
			getItem: function(propertyName){
				var property = exeoutput.GetGlobalVariable(propertyName, "");
				return property;
			}
		});

		window["exeoutputLocalStorage"] = new LocalStorageClass({});
		return exeoutputLocalStorage;
	}
	else if(!window["localStorage"])
	{
		//create a fake localStorage object for people using really old browsers,
		//for the single page app, this will at least save their states between card flips
		var LocalStorageClass = Ext.extend(Ext.util.Observable, {
			constructor: function(config){
				// Call our superclass constructor to complete construction process.
				this.data = {};

				LocalStorageClass.superclass.constructor.call(this, config);
			},
			setItem: function(propertyName, value){
				this.data[propertyName] = value;
			},
			getItem: function(propertyName){
				if(this.data.hasOwnProperty(propertyName))
					return this.data[propertyName];
				return null;
			}
		});

		window["localStorage"] = new LocalStorageClass({});
		
		return localStorage;
	}
	else {
		return localStorage;
	}
};

Ext.onReady(function(){
	Ext.EventManager.on(window, "beforeunload", Sms.setPageUnloadVariable, Sms);
});

// *** Everything below this comment should be moved to different files! ***

//This is a custom proxy that ensures that the last requested response is always the one that updates the proxy
Ext.define("Sms.proxy.Ajax",{
	extend: "Ext.data.proxy.Ajax",
	currentRequestNumber: 0,
	createRequestCallback: function(request, operation, callback, scope) {
        var me = this;
        me.currentRequestNumber = me.currentRequestNumber + 1;
		var currentNumber = me.currentRequestNumber;

        return function(options, success, response) {
			if(currentNumber === me.currentRequestNumber){
				me.processResponse(success, operation, request, response, callback, scope);
			}
        };
    }
});

//set up so that "Y" auto converts in bool to yes on model
Ext.data.Types.BOOL = Ext.data.Types.BOOLEAN = {
	sortType: Ext.data.SortTypes.none,
	type:     "bool",
	convert: function(v){
		if(this.useNull && (v === null || v === "" || typeof v === "undefined")){
			return null;
		}
		return v === true || v === "true" || v === 1 || v === "1" || v === "Y";
	}
};

//set up checkbox so that Y is autoconverted to true
Ext.form.field.Checkbox.override({
	isChecked: function(rawValue, inputValue){
        return (rawValue === true || rawValue === "true" || rawValue === "1" || rawValue === 1 || rawValue === "Y" ||
			(((Ext.isString(rawValue) || Ext.isNumber(rawValue)) && inputValue) ? rawValue == inputValue : this.onRe.test(rawValue)));
    }
});

Ext.define("Sms.Node.Path", {
	override: "Ext.data.Model",
	getSmsPath: function(field){
		field = field || this.idProperty;

		var nodeText  = this.get(field);
		var path      = [nodeText ? nodeText.replace(/>/g, ".") : nodeText];
		var parent    = this.parentNode;
		var separator = " > ";

		path[0].replace(/>/g, ".");

		while(parent){
			nodeText = parent.get(field);
			path.unshift(nodeText ? nodeText.replace(/>/g, ".") : nodeText);
			parent = parent.parentNode;
		}
		
		return separator + path.join(separator);
	}
});

//request handlers specific to SMS
Ext.data.Connection.override({
	//add the extra parameter to connect to tell if it is a null request
	request: function(options){
		var me = this;

		if(!options.params){
			options.params = {};
		}

		options.params.ext_request = true;
		if(!options.params.ajax_request_number){
			options.params.ajax_request_number = Sms.globalRequestId;
			Sms.globalRequestId++;
		}
		options.params.caller_jsp_page = window.thisJspPage;
		options.params.page_loaded_time = window.currentTimestamp;

		if(options && !options.stopErrorReporting){
			var oldFailure = options.failure;
			options.failure = function(requestObject, responseObject){
				//if the page is unloading we don't want the call to error since the browser just cut it off anyway
				if(!Sms.unloading && !requestObject.request.aborted){
					Ext.Function.defer(Sms.handleAjaxFailure, 500, this, [requestObject]);
					if(oldFailure){  //if a default failure function exists, call it.
						oldFailure(requestObject, responseObject);
					}
				}
			};
		}
		return me.callOverridden(arguments);
	},

	onComplete: function(request){
		var retryRequest = false;
		
		if(request.timedout){
			retryRequest = true;
		}
		else{
			//Begin invalid session handler
			var statusCode = null;
			var responseObject = {};
			try {
				statusCode = request.xhr.status;
			}
			catch (e){
				// in some browsers we can't access the status if the readyState is not 4, so the request has failed
				statusCode = 403;
			}

			try{
				responseObject = Ext.decode(request.xhr.responseText) || {};
			}
			catch(e){
				responseObject = {};
			}

			if((statusCode === 403 || responseObject.session_invalid) && !Sms.invalidSession){
				Sms.invalidSession = true;
				Sms.deregConfirmBrowseAway();
				top.Index.showInvalidSessionMessage();
				delete this.requests[request.id];
				return null;
			}
			//End invalid session handler

			//Begin null request handler
			if(responseObject.null_request){
				request.options.disableCaching = true;
				this.request(request.options);
				delete this.requests[request.id];
				return null;
			}//End null request handler
			else if(responseObject.ajax_response_status && responseObject.ajax_response_status === "running"){
				// the backend is taking way to long to process the data, cause an error
				var response = this.createResponse(request);
				var options = request.options;
				this.fireEvent('requestexception', this, response, options);
				Ext.callback(options.failure, options.scope, [response, options]);
				Ext.callback(options.callback, options.scope, [options, false, response]);
				delete this.requests[request.id];
				return response;
			}//handle 'network?' issues, that on retry seem to work fine.
			else if(!request.aborted &&
				(statusCode === 0 ||
				 statusCode === 12031 ||
				 statusCode === 12152 ||
				 statusCode === 12030 ||
				 statusCode === 400)){
				retryRequest = true;
			}
		}	

		if(retryRequest && !request.options.disableTimeoutRetry){
			if(Sms.badRequestHash[request.options.params.ajax_request_number]){
				Sms.badRequestHash[request.options.params.ajax_request_number]++;
			}
			else{
				Sms.badRequestHash[request.options.params.ajax_request_number] = 1;
			}

			if(Sms.badRequestHash[request.options.params.ajax_request_number] < 3){
				request.options.disableCaching = true;
				request.options.stopErrorReporting = true;//because the failure was recorded on the first one already
				this.request(request.options);
				delete this.requests[request.id];
				return null;
			}
		}

		return this.callOverridden(arguments);
	},

	// Original method in 4.0.7 caused errors in IE (SMS-360). Fixed in 4.1.0 but
	// introduced another bug. This version taken from 4.1.2.
	abort: function(request){
        var me = this,
			xhr;
        if(!request){
            request = me.getLatest();
        }
        if(request && me.isLoading(request)){
			xhr = request.xhr;
			try{
				xhr.onreadystatechange = null;
			}
			catch(e){
				xhr.onreadystatechange = Ext.emptyFn;  // Fix for SMS-360
			}
            xhr.abort();
            me.clearTimeout(request);
            if(!request.timedout){
                request.aborted = true;
            }
            me.onComplete(request);
            me.cleanup(request);
        }
    },

	// Original method had a tendency to throw errors if code stops on a breakpoint
	onStateChange: function(request){
		if(request && request.xhr && request.xhr.readyState === 4){
			this.clearTimeout(request);
			this.onComplete(request);
			this.cleanup(request);
		}
	}
});