Sms.getXmlHttp = function()
{
	var xmlHttp;
	if(window.XMLHttpRequest) // IE7
	{
		try
		{
			return new window.XMLHttpRequest();
		}
		catch(e)
		{}
	}
	
	try
    {
    	xmlHttp = new ActiveXObject("Msxml2.XMLHTTP");
    }
	catch(e)
    {
    	try
		{
			xmlHttp = new ActiveXObject("Microsoft.XMLHTTP");
		}
		catch(e)
		{
			alert("Your browser does not support AJAX.");
			return null;
		}
	}
		
	return xmlHttp;
};

Sms.assertTimeDisplay = function(v)
{
	if(v === 0)
		return "0:00";
	else if(v)
	{
		v = v + "";
		v = Ext.String.trim(v);
		if(v != "")
		{
			var hours;
			var minutes;

			var colonCount = v.split(":").length - 1;
			if(colonCount == 0)
			{
				if(v.search(/(\.)/) != -1)
				{
					var chunks = v.split(".");
					hours = parseInt(chunks[0], 10);
					minutes = Math.round(parseFloat("." + chunks[1]) * 60, 0);
				}
				else
				{
					minutes = parseInt(v, 10);
					hours = Math.floor(minutes / 60);
					minutes = minutes % 60;
				}
			}
			else if(colonCount > 1)
			{
				// stip out colons before the last colon
				var lastColonIndex = v.lastIndexOf(":");
				hours = parseInt(v.substr(0, lastColonIndex).replace(":", ""), 10);
				minutes = parseInt(v.substr(lastColonIndex + 1), 10);
			}
			else
			{
				var splitUp = v.split(":");
				hours = parseInt(splitUp[0], 10);
				minutes = parseInt(splitUp[1], 10);
			}
			if(isNaN(hours))
				hours = 0;
			if(isNaN(minutes))
				minutes = 0;

			if(minutes > 59)
			{
				hours += Math.floor(minutes / 60);
				minutes = minutes % 60;
			}

			v = hours + ":";
			if(minutes < 10)
				v += "0";//add the prefix 0 so that formatting is good :)
			v += minutes;
		}
	}
	else
		v = "";
	return v;
};

Sms.isGoodAjaxResponse = function(xmlHttp)
{
	if(xmlHttp != null && xmlHttp.responseText != null && xmlHttp.responseText.indexOf("[SESSION_NOT_PRESENT]") != -1)
	{
		top.location.href = "";
		return false;
	}
	return true;
};

Ext.ns("Sms.dataUtilities");
	
//save state - a special function because Ext.Ajax.request doesn't work onbrowseaway in IE, but fine in other browsers
//url - url to send saved data to
//data - Ext.util.MixedCollection of the data to save, key as string and item as string
Sms.dataUtilities.saveState = function(url, data)
{
	var params = "ext_request=true";
	if(data)
	{
		data.eachKey(function(key, item){
			if(params.length > 0)
				params += "&";
			params += key + "=" + item;
		});
	}

	var xmlHttp = Sms.getXmlHttp();

	// since this function is getting called on unload, it potentially aborts the ajax call
	// in some cases if the call is asynchronous, so make this a synchronous call
	try{
		xmlHttp.open("POST", url, false);
		xmlHttp.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
		xmlHttp.setRequestHeader("x-requested-with", "OldAjaxMethod");
		xmlHttp.send(params);
	}catch(e){}
};
	
Sms.dataUtilities.getGridStateData = function(grid, gridName)
{
	var cm = grid.columns;
	var data = {"grid_name": gridName};
	var cols = [];

	for(var i = 0; i < cm.length; i++)
	{
		var col = cm[i];
		var colInfo = {
			"data_index": col.dataIndex,
			"width":      col.width,
			"hidden":     col.hidden
		};

		var theFilter = grid.features[0].getFilter(col.dataIndex);
		if(theFilter && theFilter.active)
			colInfo["filter"] = encodeURIComponent(Sms.dataUtilities.decodeFilterToString(theFilter));

		cols.push(colInfo);
	}
	data["columns"] = cols;

	var sortState = grid.getStore().getSorters()[0];
	if(sortState)
	{
		data["sort_data_index"] = sortState.property;
		data["sort_direction"] = sortState.direction;
	}

	return data;
};

Sms.sortColumnArrayByVariable = function(a, b)
{
    if(a.columnIndex > b.columnIndex)
        return 1;
    else if(a.columnIndex < b.columnIndex)
        return -1;
};

Sms.applyGridStateColumnFilters = function(theFilters, saveState){
	var columnSaveState = saveState.columns;
	for(var i = 0; i < theFilters.length; i++)
	{
		var columnData = theFilters[i];
		var columnConfig = columnSaveState[columnData.dataIndex];
		if(columnConfig && columnConfig.filter)
		{
			if(columnData.type == "date")
			{
				columnData.value = {};
				Ext.Array.each(["before","after","on"], function(value){
					if(columnConfig.filter[value])
						columnData.value[value] = Ext.Date.parse(columnConfig.filter[value], "m/d/Y");
				});
				
			}
			else
				columnData.value = columnConfig.filter;
		}
	}
	
	return theFilters;
};

Sms.applyGridStateColumns = function(theColumns, saveState){
	var columnSaveState = saveState.columns;
	for(var i = 0; i < theColumns.length; i++)
	{
		var columnData = theColumns[i];
		var columnConfig = columnSaveState[columnData.dataIndex];
		if(columnConfig)
		{
			columnData.columnIndex = columnConfig.index;
			if(columnConfig.width)
			{
				delete columnData.flex;//if you don't remove the flex, the flex will take priority over the manual width
				columnData.width = parseInt(columnConfig.width, 10);
			}
			columnData.hidden = (columnConfig.hidden === true);
		}
	}
	
	try{
        theColumns.sort(Sms.sortColumnArrayByVariable);
    }
    catch(err){}
	
	return theColumns;
};

Sms.registerAutoStateSaveGrid = function(grid, gridNameOrFunction)
{
	var saveStateFunction = function(){
		var gridName = gridNameOrFunction;
		if(Ext.isFunction(gridNameOrFunction))
			gridName = gridNameOrFunction();
		
		if(gridName)
			Sms.dataUtilities.saveColumnData(grid, gridName);
	};
	
	grid.on("columnhide", saveStateFunction);
	grid.on("columnmove", saveStateFunction);
	grid.on("columnresize", saveStateFunction);
	grid.on("columnshow", saveStateFunction);
	grid.getView().on("refresh", saveStateFunction);
	grid.on("reconfigure", saveStateFunction);
};

Sms.dataUtilities.saveColumnData = function(grid, gridName)
{
	var cm = grid.columns;
	
	var config = {};
	var columnConfig = {};

	for(var i = 0; i < cm.length; i++)
	{
		var theFilter = grid.features[0].getFilter(cm[i].dataIndex);
		
		var singleColumnConfig = {
			width:  cm[i].width,
			hidden: cm[i].hidden ? true : false,
			index:  i
		};
		if(theFilter && theFilter.active)
			singleColumnConfig.filter = Sms.dataUtilities.getFilterStandardFormat(theFilter);
		
		columnConfig[cm[i].dataIndex] = singleColumnConfig;
	}
	config.columns = columnConfig;

	var sortState = grid.getStore().getSorters()[0];
	if(sortState)
	{
		config.sortConfig = {
			property:  sortState.property,
			direction: sortState.direction
		};
	}
	
	Sms.getLocalStorage().setItem("STATE_COLUMN_" + gridName, Ext.encode(config), Ext.Date.add(new Date(), Ext.Date.MONTH, 4));
};

Sms.dataUtilities.getTreeStateString = function(someTree, selectedNodeId, extraOptions)
{
	var treeState = Sms.dataUtilities.getTreeStateObject(someTree);
	treeState.selected_node_id = selectedNodeId;
	if(extraOptions)
		treeState.extra_options = extraOptions;
	return treeState;
};

Sms.dataUtilities.saveTreeState = function(someTree, treeName, selectedNodeId, extraOptions)
{
	var treeState = Sms.dataUtilities.getTreeStateObject(someTree);
	treeState.selected_node_id = selectedNodeId;
	if(extraOptions)
		treeState.extra_options = extraOptions;

	Sms.getLocalStorage().setItem("STATE_TREE_" + treeName, Ext.encode(treeState), Ext.Date.add(new Date(), Ext.Date.MONTH, 4));
};
	
Sms.dataUtilities.getTreeStateObject = function(someTree){
	return {
		expand_state: Sms.dataUtilities.buildTreeStateObject(someTree.getRootNode())
	};
};

Sms.dataUtilities.buildTreeStateObject = function(startNode)
{
	var treeState = [];
	startNode.eachChild(function(node){
		if(node.isExpanded() && !node.isLeaf() && node.get("item_identifier") != "time_clock_entries")
		{
			var stateData = {
				id:              node.get("id"),
				item_identifier: node.get("item_identifier"),
				page_number:     node.get("page_number"),
				children:        Sms.dataUtilities.buildTreeStateObject(node)
			};
			treeState.push(stateData);
		}
	});
	return treeState;
};

Sms.dataUtilities.saveTreePathState = function(someTree, treeName, selectedNodeId, extraOptions)
{
	var treeState = Sms.dataUtilities.getTreePathObject(someTree, selectedNodeId);
	treeState.selected_node_id = selectedNodeId;
	if(extraOptions)
		treeState.extra_options = extraOptions;

	Sms.getLocalStorage().setItem("STATE_TREE_" + treeName, Ext.encode(treeState), Ext.Date.add(new Date(), Ext.Date.MONTH, 4));
};

Sms.dataUtilities.getTreePathObject = function(someTree, leafNodeId){
	return {
		expand_state: Sms.dataUtilities.buildTreePathObject(someTree.getRootNode(), leafNodeId)
	};
};

Sms.dataUtilities.buildTreePathObject = function(parentNode, markNodeId) {
	var treeState = [];
	parentNode.eachChild(function(node){
		if (node.get("id") === markNodeId) {
			var pathData = {
				id:              parentNode.get("id"),
				item_identifier: parentNode.get("item_identifier"),
				page_number:     parentNode.get("page_number"),
				children:        []
			};
			treeState.push(pathData);
		} else if (node.isExpanded() && !node.isLeaf() && node.get("item_identifier") != "time_clock_entries") {
			var temp = Sms.dataUtilities.buildTreePathObject(node, markNodeId);
			if (temp.length > 0) {
				if (parentNode.get("id") == "0") treeState = temp;
				else {
					var pathData = {
						id:              parentNode.get("id"),
						item_identifier: parentNode.get("item_identifier"),
						page_number:     parentNode.get("page_number"),
						children:        temp
					};
					treeState.push(pathData);
				}
			}
		} 
	});
	return treeState;
};


Sms.dataUtilities.getFilterStandardFormat = function(theFilter){
	var type = theFilter.type;
	var value = theFilter.getValue();
	
	if(type == "date")
	{
		if(value.before != null)
			value.before = Ext.Date.format(value.before, 'm/d/Y');
		if(value.after != null)
			value.after = Ext.Date.format(value.after, 'm/d/Y');
		if(value.on != null)
			value.on = Ext.Date.format(value.on, 'm/d/Y');
	}
	
	return value;
};

Sms.dataUtilities.decodeFilterToString = function(someFilter)
{
	var returnData = "";
	var type = someFilter.type;
	var value = someFilter.getValue();
	if(type == "numeric")
	{
		var insertComma = false;
		returnData += "{";
		if(value.lt != null)
		{
			returnData += "lt: " + value.lt;
			insertComma = true;
		}
		if(value.gt != null)
		{
			if(insertComma)
				returnData += ",";
			returnData += "gt: " + value.gt;
			insertComma = true;
		}
		if(value.eq != null)
		{
			if(insertComma)
				returnData += ",";
			returnData += "eq: " + value.eq;
		}
		returnData += "}";
	}
	else if(type == "list")
	{
		var first = true;
		returnData = "[";
		for(var i = 0; i < value.length; i++)
		{
			if(!first)
				returnData += ",";
			returnData += "\"" + value[i].replace(/"/g,"\\\"") + "\"";
			first = false;
		}
		returnData += "]";
	}
	else if(type == "date")
	{
		var insertComma = false;
		returnData += "{";
		if(value.before != null)
		{
			returnData += "before: Date.parseDate('" + value.before.format('m/d/Y') + "','m/d/Y')";
			insertComma = true;
		}
		if(value.after != null)
		{
			if(insertComma)
				returnData += ",";
			returnData += "after: Date.parseDate('" + value.after.format('m/d/Y') + "','m/d/Y')";
			insertComma = true;
		}
		if(value.on != null)
		{
			if(insertComma)
				returnData += ",";
			returnData += "on: Date.parseDate('" + value.on.format('m/d/Y') + "','m/d/Y')";
		}
		returnData += "}";
	}
	else if(type == "string")
	{
		returnData = "\"" + value.replace(/"/g,"\\\"") + "\"";
	}
	return returnData;
};

Sms.dataUtilities.createIndentationString = function(indentation){
	var indentationString = [],
		i;
	for(i = 0; i < indentation; i++){
		indentationString.push("--");
	}
	indentationString.push("> ");
	return indentationString.join("");
};

Sms.dataUtilities.getGridClipboardData = function(grid, dataIndex){
	var store  = grid.getStore(),
		storeCount = store.getCount(),
		expand = grid.expanderDataIndex || [],
		copyData = [],
		indexCount = dataIndex.length,
		du = Sms.dataUtilities,
		diObj,
		storeValue, cellValue,
		rowData,
		record,
		i, j,
		fieldDefs = store.model ? store.model.prototype.fields : null;

	// Iterate over each record, collecting the data from each data index
	for(i = 0; i < storeCount; i++){
		record = store.getAt(i);
		
		// First, get the column data
		rowData = [];
		for(j = 0; j < indexCount; j++){
			diObj = dataIndex[j];
			storeValue = record.get(diObj.dataIndex);
			
			try{
				//try to best guess a date format if the column is a date
				if(Ext.isDate(storeValue) && fieldDefs && fieldDefs.get(diObj.dataIndex) && fieldDefs.get(diObj.dataIndex).dateFormat)
					storeValue = Ext.Date.format(storeValue, fieldDefs.get(diObj.dataIndex).dateFormat);
			}
			catch(e)
			{
				//tried our best, just let it pass through with whatever the value is
				storeValue = record.get(diObj.dataIndex);
			}
			
			cellValue = diObj.clipboard ? diObj.clipboard(storeValue) : storeValue;
			rowData.push(du.getInnerHtml(cellValue));
		}

		// If the grid has an expander plugin, get the data from that
		// IMPORTANT: This section depends on custom code that was added to
		// the RowExpander plugin.
		for(j = 0; j < expand.length; j++){
			rowData.push(du.getInnerHtml(record.get(expand[j])));
		}

		if(rowData.length > 0){
			copyData.push(rowData.join("\t"));
		}
	}

	return copyData;
};

Sms.dataUtilities.getTreeGridClipboardData = function(tree, dataIndex){
	var root = tree.getRootNode(),
		copyData = [],
		children = root.childNodes || [],
		childCount = children.length,
		du = Sms.dataUtilities,
		childNode,
		i;

	// Recursively assemble the text output
	for(i = 0; i < childCount; i++){
		childNode = children[i];
		copyData.push(du.getNodeData(childNode, dataIndex, 0));
	}

	return copyData;
};

Sms.dataUtilities.getNodeData = function(node, dataIndex, indentLevel){
	var du = Sms.dataUtilities,
		indent = du.createIndentationString(indentLevel),
		indexCount = dataIndex.length,
		children = node.childNodes || [],
		childCount = children.length,
		copyData = [],
		rowData = [],
		diObj, storeValue, cellValue,
		childNode,
		i;

	// First, get the data for the current node
	for(i = 0; i < indexCount; i++){
		diObj = dataIndex[i];
		storeValue = node.get(diObj.dataIndex);
		cellValue = diObj.clipboard ? diObj.clipboard(storeValue) : storeValue;
		rowData.push(du.getInnerHtml(cellValue));
	}
	copyData.push(indent + rowData.join("\t"));

	// Append data for any child nodes
	for(i = 0; i < childCount; i++){
		childNode = children[i];
		copyData.push(du.getNodeData(childNode, dataIndex, indentLevel + 1));
	}

	return copyData.join("\n");
};

// Main entry point for grid and treegrid clipboard text. Collects the header
// data first, then splits into the specialized functions for body data.
Sms.dataUtilities.getGridClipboardText = function(grid){
	var columns = grid.columns,
		copyData = [],
		headerData = [],
		subHeaderData = [],
		dataIndex = [],
		du = Sms.dataUtilities,
		columnCount = columns.length,
		hasSubHeaders = false,
		startIndex = 0,
		headerText,
		subColumnCount,
		visibleSubColumns,
		columnCollection,
		i, j, col, subCol;

	var canCopyColumn = function(col){
		return (!col.hidden) && (col.clipboard !== false);
	};

	// If grid has a row expander plugin, skip the first column
	if(grid.expanderDataIndex){
		startIndex = 1;
	}

	// Collect the header titles
	for(i = startIndex; i < columnCount; i++){
		col = columns[i];
		if(canCopyColumn(col)){
			headerText = du.getInnerHtml(col.text);

			// Flatten the data index references to a single array
			if(col.dataIndex){
				dataIndex.push({
					dataIndex: col.dataIndex,
					clipboard: col.clipboard
				});
			}

			// If the column has sub-columns, handle them
			// IMPORTANT: This function only supports two levels of headers.
			// When upgrading to fully-nested headers, use a recursive algorithm.
			if(col.items && col.xtype !== "actioncolumn"){
				if(Ext.isArray(col.items)){
					columnCollection = new Ext.util.MixedCollection(false);
					columnCollection.addAll(col.items);
				}
				else{
					columnCollection = col.items;
				}

				subColumnCount = columnCollection.getCount();
				visibleSubColumns = 0;
				for(j = 0; j < subColumnCount; j++){
					subCol = columnCollection.getAt(j);
					if(canCopyColumn(subCol)){
						hasSubHeaders = true;
						visibleSubColumns++;
						subHeaderData.push(du.getInnerHtml(subCol.text));

						if(subCol.dataIndex){
							dataIndex.push({
								dataIndex: subCol.dataIndex,
								clipboard: subCol.clipboard
							});
						}
					}
				}

				// If there are no sub-columns, but there could be, create a spacer
				// in the array to keep everything lined up
				if(subColumnCount === 0){
					subHeaderData.push("");
				}

				// Pad the main header with extra tabs to account for the sub-columns
				for(j = 0; j < visibleSubColumns - 1; j++){
					headerText += "\t";
				}
			}

			headerData.push(headerText);
		}
	}

	// Add the headers to the final data array
	copyData.push(headerData.join("\t"));
	if(hasSubHeaders){
		copyData.push(subHeaderData.join("\t"));
	}

	// Branch out and collect data for the right kind of grid
	if(grid.store.hasOwnProperty("tree")){
		copyData = copyData.concat(du.getTreeGridClipboardData(grid, dataIndex));
	}
	else{
		copyData = copyData.concat(du.getGridClipboardData(grid, dataIndex));
	}

	return copyData.join("\n");
};
	
Sms.dataUtilities.getInnerHtml = (function(){
	// Stores pre-compiled regex as private vars. Huge performance boost.
	var re = /\<.*?\>/g,
		br = /<br\s*[\/]?>/gi,
		nbsp = /&nbsp;/g,
		space = /&#160;/g,
		lt = /&lt;/g,
		gt = /&gt;/g,
		slash = /\\"/g,
		dquote = /\"/g,
		trim = /^\s+|\s+$/g;
	return function(s){
		if(s == null){
			return "";
		}
		s = String(s)
			.replace(br, " ")
			.replace(re, "")
			.replace(nbsp, " ")
			.replace(space, " ")
			.replace(lt, "<")
			.replace(gt, ">")
			.replace(slash, '\\ ')
			.replace(dquote, "")
			.replace(trim, "");
		return s;
	};
}());
	
/**
 * @param {Object[]} data
 *     Array of {valueField, displayField} pairs
 * @param {String} valueField (optional)
 *     Defaults to "v"
 * @param {String} displayField (optional)
 *     Defaults to "d"
 * @returns {Ext.data.Store}
 *     A minimally configured store for use in a combobox
 */
Sms.dataUtilities.createStoreFromComboArray = function(data, valueField, displayField){
	var store;

	valueField   = (typeof valueField === "string")   ? valueField   : "v";
	displayField = (typeof displayField === "string") ? displayField : "d";

	store = new Ext.data.Store({
		fields: [valueField, displayField],
		data:   data
	});

	return store;
};

var stripTagsRE = /<\/?[^>]+>/gi;
function asFloat(s) {
	if(s == null || s == "" || s == "null")
		return Number.MAX_VALUE;
	s = String(s + "").replace(stripTagsRE, "").replace(/([^0-9\.\-])/g, "");
	var val = parseFloat(String(s).replace(/,/g, ""));
	return isNaN(val) ? 0 : val;
}

function asDate(s) {
	if(!s){
		return 0;
	}
	s = String(s + "").replace(stripTagsRE, "");
	if(Ext.isDate(s)){
		return s.getTime();
	}
	
	var offset = 0;
	if (String(s).indexOf("IST") > 0) { 
		offset = 11.5;
		s = String(s).substring(0, String(s).indexOf("IST", 0));
	}
	
	var date = Date.parse(String(s));
	if (isNaN(date)) {
		date = Date.parseDate(String(s), "m/Y");
		
		if (date) {
			date = date.getTime();
		} else {
			var patt1 = /^\d{1,2}:\d{2}\s*[ap]m/i;
			if (patt1.test(s)) {
				date = Date.parse(("1/1/1970 " + s));
			}
		}
	}
	
	if (date) {
		date = date + (offset*3600000);
	}

	return date;
}

function asInt(s) {
	if(s == null || s == "" || s == "null")
		return Number.MAX_VALUE;
	s = String(s + "").replace(stripTagsRE, "");
	var val = parseInt(String(s).replace(/,/g, ""), 10);
	return isNaN(val) ? 0 : val;
}

// Testing for ExtjsUtilities.getInnerHtml
// Run by calling "Sms.dataUtilities.test.<function to test>() in console"
Sms.dataUtilities.test = (function(){
	var assertEqual = function(a, b, msg){
		var result = (a === b);
		if(result){
			Sms.log("Test passed!");
		}else{
			Sms.log(Ext.String.format("Test failed...\n    a = {0}\n    b = {1}\n    {2}", a, b, msg));
		}
		return result;
	};

	return {
		getInnerHtml: function(){
			var du = Sms.dataUtilities,
				input, output;

			input = null;
			output = du.getInnerHtml(input);
			assertEqual(output, "", "Null did not return empty string");

			input = false;
			output = du.getInnerHtml(input);
			assertEqual(output, "false", "False did not return string 'false'");

			input = "abcdefg";
			output = du.getInnerHtml(input);
			assertEqual(output, input, "Legal characters were stripped");

			input = "abcd<br/>efg";
			output = du.getInnerHtml(input);
			assertEqual(output, "abcd efg", "Line break tag not replaced with space");

			input = "<a href='#' onclick='doStuff(false);'>abcdefg</a>";
			output = du.getInnerHtml(input);
			assertEqual(output, "abcdefg", "HTML tags not removed");

			input = "abcd &lt; efg &gt; hijk&nbsp;lmno";
			output = du.getInnerHtml(input);
			assertEqual(output, "abcd < efg > hijk lmno", "HTML entities not replaced");

			input = "abcd \"efg\" hijk";
			output = du.getInnerHtml(input);
			assertEqual(output, "abcd efg hijk", "Double-quotes not replaced");

			// Regression test SMS-465: MR Container - Expected ')'
			input = "abcd\\\"efg\"hijk";
			output = du.getInnerHtml(input);
			assertEqual(output, "abcd\\ efghijk", "Quotes preceeded by slash not replaced");

			// Regression test SMS-651: Overall - Copy to Clipboard not trimming whitespace
			input = "  abcd efg	";
			output = du.getInnerHtml(input);
			assertEqual(output, "abcd efg", "Leading and trailing whitespace not trimmed");
		}
	};
}());
