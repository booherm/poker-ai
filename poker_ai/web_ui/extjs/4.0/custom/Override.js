//this apply records which namespaces are created for debuggin errors with printStackTrace()
Ext.apply(Ext.ClassManager, {
	namespaces: [],
	createNamespaces: function() {
		var root = Ext.global,
			parts, part, i, j, ln, subLn;

		for (i = 0, ln = arguments.length; i < ln; i++) {
			parts = this.parseNamespace(arguments[i]);
			var partName = "";
			
			for (j = 0, subLn = parts.length; j < subLn; j++) {
				part = parts[j];

				if (typeof part !== 'string') {
					root = part;
				} else {
					if(partName)
						partName += ".";
					partName += part;
					if (!root[part]) {
						root[part] = {};
						this.namespaces.push({
							name:   partName,
							object: root[part]
						});
					}

					root = root[part];
				}
			}
		}

		return root;
	}
});

//Emails can have ' in them
Ext.apply(Ext.form.VTypes, {
    email : function(val) {
		var email = /^(\w+)([\-+'.][\w]+)*@(\w[\-\w]*\.){1,5}([A-Za-z]){2,6}$/;
		return email.test(val);
    },
	
	emailMask : /[a-z0-9'_\.\-@\+]/i
});

//This will make editable cells in grids have a border so the user knows they are editable
Ext.override(Ext.grid.Panel, {
	markEditableCells: true,
	markInvalidCells: false
});

Ext.override(Ext.grid.header.Container, {
	prepareData: function(data, rowIdx, record, view, panel) {
		var obj       = {},
            headers   = this.gridDataColumns || this.getGridColumns(),
            headersLn = headers.length,
            colIdx    = 0,
            header,
            headerId,
            renderer,
            value,
            metaData,
            store = panel.store;

        for (; colIdx < headersLn; colIdx++) {
            metaData = {
                tdCls: '',
                style: ''
            };
            header = headers[colIdx];
            headerId = header.id;
            renderer = header.renderer;
            value = data[header.dataIndex];
            
            if (typeof renderer === "string") {
                header.renderer = renderer = Ext.util.Format[renderer];
            }
            if (typeof renderer === "function") {
                value = renderer.call(
                    header.scope || this.ownerCt,
                    value,
                    metaData,
                    record,
                    rowIdx,
                    colIdx,
                    store,
                    view
                );
            }

			var borderColor = "";
			if((header.editorMarked || (header.initialConfig && header.initialConfig.editor)) && panel.markEditableCells && !record.get("prevent_mark"))
			{
				//this will put a border around editable cells so the user knows they're editable
				borderColor = "gray";
				header.editorMarked = true;
			}
			
			if((panel.markInvalidCells || panel.markEditableCells) && record.get("invalid_message") && (record.get("invalid_column") == colIdx || record.get("invalid_column_" + header.dataIndex)))
			{
				//mark cell invalid
				borderColor = "red";
				metaData.tdCls = "x-form-invalid-field";
				metaData.tdAttr = " data-errorqtip=\"" +  record.get("invalid_message") + "\" ";
			}
			
			if(borderColor)
			{
				if(!metaData.style)
					metaData.style = "border: 1px " + borderColor + " solid;";
				else
					metaData.style = metaData.style + ";border: 1px " + borderColor + " solid;";
			}
			
			if(this.markDirty !== false){
				obj[headerId+'-modified'] = record.isModified(header.dataIndex) ? Ext.baseCSSPrefix + 'grid-dirty-cell' : '';
			}
            obj[headerId+'-tdCls'] = metaData.tdCls;
            obj[headerId+'-tdAttr'] = metaData.tdAttr;
            obj[headerId+'-style'] = metaData.style;
            if (typeof value === "undefined" || value === null || value === '') {
                value = header.emptyCellText || "&#160;";
            }
            obj[headerId] = value;
        }
        return obj;
    },
	purgeCache: function(){
		// Override prevents header from destroying filters when destroying the menu.
		// The only item that needs to change is the column hide menu.
		var me = this,
			menu = me.menu,
			colMenu, colIdx;
		delete me.gridDataColumns;
		delete me.hideableColumns;
		if(menu){
			menu.hide();
			colMenu = menu.getComponent("columnItem");
			if(colMenu){
				colIdx = menu.items.indexOf(colMenu);
				menu.remove(colMenu);
				menu.insert(colIdx, {
					itemId: "columnItem",
					text:   me.columnsText,
					cls:    Ext.baseCSSPrefix + "cols-icon",
					menu:   me.getColumnMenu(me)
				});
			}
		}
	}
});

Ext.override(Ext.form.field.Base, {
	labelableRenderProps: [ 'allowBlank', 'id', 'labelAlign', 'fieldBodyCls', 'baseBodyCls',
                            'clearCls', 'labelSeparator', 'msgTarget' ]
});

Ext.override(Ext.form.field.Text, {
	minLengthText: "The minimum length for this field is {0} characters.",
	maxLengthText: "The maximum length for this field is {0} characters."
});

if(Ext.getVersion('core').match('4.1.0'))
{
	// Attempt at solving the Vector2D problem by eliminating the need for using
	// a VML component on panel collapse.
	Ext.override(Ext.panel.Panel, {
		getReExpander: function(direction){
			var me          = this,
				collapseDir = direction || me.collapseDirection,
				reExpander  = me.reExpander || me.findReExpander(collapseDir),
				defaults;

			me.expandDirection = me.getOppositeDirection(collapseDir);

			if(!reExpander){
				defaults = {
					dock:        collapseDir,
					cls:         Ext.baseCSSPrefix + 'docked ' + me.baseCls + '-' + me.ui + '-collapsed',
					ownerCt:     me,
					ownerLayout: me.componentLayout
				};

				// No need to show anything here, so just use a dummy container
				if(me.collapseMode === 'mini'){
					if(collapseDir === 'left' || collapseDir === 'right'){
						defaults.width = 1;
					}
					else{
						defaults.height = 1;
					}
					me.reExpander = reExpander = new Ext.container.Container(Ext.apply({
						hideMode:    'offsets',
						baseCls:     me.baseCls + '-header',
						ui:          me.ui
					}, defaults));
					reExpander.addClsWithUI(me.getHeaderCollapsedClasses(reExpander));
				}
				else{
					me.reExpander = reExpander = me.createReExpander(collapseDir, defaults);
				}
				me.dockedItems.insert(0, reExpander);
			}
			return reExpander;
		}
	});

	//fix for extremely rare case when click gets propagated down to column on data cell click and e is not event object
	Ext.override(Ext.grid.column.Column, {
		onElClick: function(e, t) {


			var me = this,
				ownerHeaderCt = me.getOwnerHeaderCt();

			if (ownerHeaderCt && !ownerHeaderCt.ddLock) {

				if (me.triggerEl && (e.target === me.triggerEl.dom || t === me.triggerEl.dom || e.within(me.triggerEl))) {
					ownerHeaderCt.onHeaderTriggerClick(me, e, t);

				} else if (e.getKey && (e.getKey() || (!me.isOnLeftEdge(e) && !me.isOnRightEdge(e)))) {//fix is on this line
					me.toggleSortState();
					ownerHeaderCt.onHeaderClick(me, e, t);
				}
			}
		}
	});
	
	// Changes order of adding displayInfo and prependButtons items
	Ext.define("Sms.toolbar.Paging", {
		override: "Ext.toolbar.Paging",
		initComponent: function(){
			var me = this,
				pagingItems = me.getPagingItems(),
				userItems = me.items || me.buttons || [];
			if (me.displayInfo) {
				pagingItems.push({xtype: "tbfill"});  // "->"
				pagingItems.push({xtype: "tbtext", itemId: "displayItem"});
			}
			if (me.prependButtons) {
				me.items = userItems.concat(pagingItems);
			} else {
				me.items = pagingItems.concat(userItems);
			}
			delete me.buttons;
			Ext.toolbar.Toolbar.prototype.initComponent.call(this);
			me.addEvents("change", "beforechange");
			me.on("beforerender", me.onLoad, me, {single: true});
			me.bindStore(me.store || "ext-empty-store", true);
		},
		clearData: function(){
			var me = this,
				displayItem = me.child('#displayItem'),
				currPage = 0,
				afterText = Ext.String.format(me.afterPageText, 0);
			me.store.removeAll();
			displayItem.setText(me.emptyMsg);
			me.child('#afterTextItem').setText(afterText);
			me.child('#inputItem').setDisabled(true).setValue(currPage);
			me.child('#first').setDisabled(true);
			me.child('#prev').setDisabled(true);
			me.child('#next').setDisabled(true);
			me.child('#last').setDisabled(true);
			me.child('#refresh').disable();
		}
	});

	Ext.override(Ext.data.Store, {
		loadRecords: function(records, options) {
			var me = this,
				len = records.length,
				start = (options = options || {}).start,
				snapshot = me.snapshot,
				resume = false,
				i;
			if(!options.addRecords){
				delete me.snapshot;
				me.clearData(true);
			}
			else if(snapshot){
				snapshot.addAll(records);
			}
			me.data.addAll(records);
			if(Ext.isDefined(start)){
				for(i = 0; i < len; i++){
					records[i].index = start + i;
					records[i].join(me);
				}
			}
			else{
				for(i = 0; i < len; i++){
					records[i].join(me);
				}
			}
			// Override: original code calls resumeEvents which will cancel any user-made call to suspendEvents
			if(!me.eventsSuspended){
				me.suspendEvents();
				resume = true;
			}
			if(me.filterOnLoad && !me.remoteFilter){
				me.filter();
			}
			if(me.sortOnLoad && !me.remoteSort){
				me.sort();
			}
			if(resume){
				me.resumeEvents();
			}
			me.fireEvent('datachanged', me, records);
			me.fireEvent('refresh', me);
		}
	});
	
	//fix for Time field blanking out on blur
	Ext.override(Ext.form.field.Time, {
		beforeBlur: function() {
			this.doQueryTask.cancel();
			//this.assertValue();
		}
	});

	// I can't believe this still hasn't been fixed
	Ext.dom.Element.addMembers({
		mask: function(msg, msgCls, elHeight){
			var me = this,
				dom = me.dom,
				setExpression = Ext.isFunction(dom.style.setExpression),
				data = (me.$cache || me.getCache()).data,
				maskEl = data.maskEl,
				maskMsg = data.maskMsg,
				XMASKED = Ext.baseCSSPrefix + "masked",
				XMASKEDRELATIVE = Ext.baseCSSPrefix + "masked-relative",
				EXTELMASKMSG = Ext.baseCSSPrefix + "mask-msg",
				DOC = document,
				bodyRe = /^body/i;
			if(!(bodyRe.test(dom.tagName) && me.getStyle("position") === "static")){
				me.addCls(XMASKEDRELATIVE);
			}
			if(maskEl){
				maskEl.remove();
			}
			if(maskMsg){
				maskMsg.remove();
			}
			Ext.DomHelper.append(dom, [
				{cls: Ext.baseCSSPrefix + "mask"},
				{
					cls: msgCls ? EXTELMASKMSG + " " + msgCls : EXTELMASKMSG,
					cn:  {
						tag:  "div",
						html: msg || ""
					}
				}
			]);
			maskMsg = Ext.get(dom.lastChild);
			maskEl = Ext.get(maskMsg.dom.previousSibling);
			data.maskMsg = maskMsg;
			data.maskEl = maskEl;
			me.addCls(XMASKED);
			maskEl.setDisplayed(true);
			if(typeof msg === "string"){
				maskMsg.setDisplayed(true);
				maskMsg.center(me);
			}
			else{
				maskMsg.setDisplayed(false);
			}
			if(!Ext.supports.IncludePaddingInWidthCalculation && setExpression){
				maskEl.dom.style.setExpression("width", "this.parentNode.clientWidth + 'px'");
			}
			if(!Ext.supports.IncludePaddingInHeightCalculation && setExpression){
				maskEl.dom.style.setExpression("height", "this.parentNode." + (dom == DOC.body ? "scrollHeight" : "offsetHeight") + " + 'px'");
			}
			else if(Ext.isIE && !(Ext.isIE7 && Ext.isStrict) && me.getStyle("height") === "auto"){
				maskEl.setSize(undefined, elHeight || me.getHeight());
			}
			return maskEl;
		},
		unmask: function(){
			var me = this,
				data = (me.$cache || me.getCache()).data,
				maskEl = data.maskEl,
				maskMsg = data.maskMsg,
				XMASKED = Ext.baseCSSPrefix + "masked",
				XMASKEDRELATIVE = Ext.baseCSSPrefix + "masked-relative",
				style;
			if(maskEl){
				style = maskEl.dom.style;
				if(Ext.isFunction(style.clearExpression)){
					style.clearExpression("width");
					style.clearExpression("height");
				}
				if(maskEl){
					maskEl.remove();
					delete data.maskEl;
				}
				if(maskMsg){
					maskMsg.remove();
					delete data.maskMsg;
				}
				me.removeCls([XMASKED, XMASKEDRELATIVE]);
			}
		}
	});
	
	Ext.dom.Element.override({
		getScroll: function() {
			var d = this.dom,
				doc = document,
				body = doc.body,
				docElement = doc.documentElement,
				l,
				t,
				ret;

			if (d == doc || d == body) {
				if (Ext.isIE && Ext.isStrict) {
					l = docElement.scrollLeft;
					t = docElement.scrollTop;
				} else {
					try{
						l = window.pageXOffset;
						t = window.pageYOffset;
					}catch(e){
						//handles rare firefox error SMS-875
						l = null;
						t = null;
					}
				}
				ret = {
					left: l || (body ? body.scrollLeft : 0),
					top : t || (body ? body.scrollTop : 0)
				};
			} else {
				ret = {
					left: d.scrollLeft,
					top : d.scrollTop
				};
			}

			return ret;
		}
	});

	// Fix for SMS-416
	Ext.override(Ext.toolbar.Toolbar, {
		lookupComponent: function(c){
			if(typeof c === "string"){
				var T = Ext.toolbar.Toolbar,
					shortcut = T.shortcutsHV[this.vertical ? 1 : 0][c] || T.shortcuts[c];
				if(typeof shortcut === "string"){
					c = {xtype: shortcut};
				}else if (shortcut){
					c = Ext.apply({}, shortcut);
				}else{
					c = {xtype: "tbtext", text: c};
				}
				this.applyDefaults(c);
			}
			return this.callParent([c]);
		}
	});

	// EXTJSIV-6062
	Ext.data.Types.AUTO.convert = function(v){ return v; };

	// EXTJSIV-5962
	Ext.override(Ext.layout.container.Box, {
		finishedLayout: function(ownerContext){
			var me = this;
			me.overflowHandler.finishedLayout(ownerContext);
			me.callParent(arguments);
			if(Ext.isWebKit){
				me.targetEl.setWidth(ownerContext.innerCtContext.props.width);
			}
		}
	});

	// EXTJSIV-6933
	Ext.override(Ext.data.proxy.Proxy, {
		setReader: function(reader){
			var me        = this;
			var needsCopy = true;
			var current   = me.reader;

			if(reader === undefined || typeof reader === "string"){
				reader = {
					type: reader
				};
				needsCopy = false;
			}

			if(reader.isReader){
				reader.setModel(me.model);
			}
			else{
				if(needsCopy){
					reader = Ext.apply({}, reader);
				}
				Ext.applyIf(reader, {
					proxy: me,
					model: me.model,
					type:  me.defaultReaderType
				});

				reader = Ext.createByAlias("reader." + reader.type, reader);
			}

			if(reader !== current && reader.onMetaChange){
				reader.onMetaChange = Ext.Function.createSequence(reader.onMetaChange, me.onMetaChange, me);
			}

			me.reader = reader;
			return me.reader;
		}
	});

	// EXTJSIV-10586
	Ext.define("Sms.data.AbstractStore", {
		override: "Ext.data.AbstractStore",

		constructor: function(config){
			var me = this;
			var filters;

			Ext.apply(me, config);
			me.removed = [];

			me.mixins.observable.constructor.apply(me, arguments);
			me.model = Ext.ModelManager.getModel(me.model);

			Ext.applyIf(me, {
				modelDefaults: {}
			});

			if(!me.model && me.fields){
				me.model = Ext.define("Ext.data.Store.ImplicitModel-" + (me.storeId || Ext.id()), {
					extend: "Ext.data.Model",
					fields: me.fields,
					proxy:  me.proxy || me.defaultProxyType
				});
				delete me.fields;
				me.implicitModel = true;
			}

			me.setProxy(me.proxy || me.model.getProxy());

			if(me.id && !me.storeId){
				me.storeId = me.id;
				delete me.id;
			}

			if(me.storeId){
				Ext.data.StoreManager.register(me);
			}

			me.mixins.sortable.initSortable.call(me);

			filters = me.decodeFilters(me.filters);
			me.filters = new Ext.util.MixedCollection();
			me.filters.addAll(filters);
		},

		setProxy: function(proxy){
			var me = this;

			if(me.proxy && me.proxy.isProxy){
				me.proxy.un("metachange", me.onMetaChange, me);
			}
			me.callParent([proxy]);
			me.proxy.on("metachange", me.onMetaChange, me);

			return me.proxy;
		},

		destroyStore: function(){
			var me = this;
			if(me.proxy){
				me.proxy.un("metachange", me.onMetaChange, me);
			}
			me.callParent();
		}
	});

	// EXTJSIV-2550
	Ext.override(Ext.grid.plugin.CellEditing, {
		onEditComplete: function(editor, value, startValue){
			var me = this,
				grid = me.grid,
				activeColumn = me.getActiveColumn(),
				selModel = grid.getSelectionModel(),
				context = me.context,
				record;

			if(activeColumn){
				record = me.context.record;

				me.setActiveEditor(null);
				me.setActiveColumn(null);
				me.setActiveRecord(null);

				context.value = value;  // <-- This is the important part
				if(!me.validateEdit()){
					return;
				}

				if(!record.isEqual(value, startValue)){
					record.set(activeColumn.dataIndex, value);
				}

				if(selModel.setCurrentPosition){
					selModel.setCurrentPosition(selModel.getCurrentPosition());
				}

				grid.getView().getEl(activeColumn).focus();
				me.fireEvent("edit", me, context);
				me.editing = false;
			}
		}
	});

	// EXTJSIV-6524
	Ext.override(Ext.view.View, {
		inputTagRe:  /^textarea$|^input$/i,
		handleEvent: function(e){
			var me  = this;
			var key = (e.type === "keydown") && e.getKey();

			if(me.processUIEvent(e) !== false){
				me.processSpecialEvent(e);
			}

			// After all listeners have processed the event, then unless the user
			// is typing into an input field, prevent browser's default action
			// on SPACE which is to focus the event's target element. Focusing
			// causes the browser to attempt to scroll the element into view.
			if(key === e.SPACE && !me.inputTagRe.test(e.getTarget().tagName)){
				e.stopEvent();
			}
		}
	});
}
	
//SMS-1323 Time Tracking - Tabbing cells and hitting submit in quick succession produce: Ext.grid.CellEditor.realign(true) error
Ext.override(Ext.grid.CellEditor, {
	realign: function(autoSize) {
		try {
			var me = this,
				boundEl = me.boundEl,
				innerCell = boundEl.first(),
				children = innerCell.dom.childNodes,
				childCount = children.length,
				offsets = Ext.Array.clone(me.offsets),
				inputEl = me.field.inputEl,
				lastChild, leftBound, rightBound, width;

			if(me.isForTree && (childCount > 1 || (childCount === 1 && children[0].nodeType !== 3))) {
				lastChild = innerCell.last();
				leftBound = lastChild.getOffsetsTo(innerCell)[0] + lastChild.getWidth();
				rightBound = innerCell.getWidth();
				width = rightBound - leftBound;
				if(!me.editingPlugin.grid.columnLines) {
								width --;
				}

				offsets[0] += leftBound;
				me.addCls(Ext.baseCSSPrefix + 'grid-editor-on-text-node');
			} 

			else {
				width = boundEl.getWidth() - 1;
			}

			if (autoSize === true) {
				me.field.setWidth(width);
			}

			me.alignTo(boundEl, me.alignment, offsets);
		}
		catch(err) {
				//No loss of function, so no message, just toss the error and continue
		}
	}
});

Ext.override(Ext.form.field.Base, {
	
	useSmsReadOnlyField:   false,
	readOnlyField:         null,
	canHaveReadOnlyField:  true,
	readOnlyFieldWidth:    null,
	readOnlyFieldRenderer: function(value){return value;},
	
	constructor: function(config){
		var me = this;
		me.callParent(arguments);
	},
	
	onAdded: function(container, pos){
		
		var me = this;
		me.callParent(arguments);
		
		if(!me.readOnlyField && me.canHaveReadOnlyField && me.useSmsReadOnlyField)
		{
			me.readOnlyField = Ext.create("Ext.form.field.Display", {
				fieldLabel: me.fieldLabel,
				hidden:     true,
				fieldStyle: {
					height: "22px"
				},
				width:      me.readOnlyFieldWidth ? me.readOnlyFieldWidth : me.width,
				anchor:     me.anchor,
				flex:       me.readOnlyFieldWidth ? null : me.flex,
				renderer:   me.readOnlyFieldRenderer
			});
			
			container.insert(pos, me.readOnlyField);
			
			if(me.readOnly)
				me.setReadOnly(me.readOnly);
		}
	},
	
	onChange: function(){
		var me = this;
		if(me.readOnlyField)
			me.readOnlyField.setValue(me.getValue());
		
		me.callParent(arguments);
		
	},
	
	setReadOnly: function(readOnly){
		var me = this;
		me.readOnly = readOnly;
		if(me.readOnlyField)
		{
			me.setVisible(!readOnly);
			me.readOnlyField.setVisible(readOnly);
		}
		me.callParent(arguments);
	}
	
});

Ext.override(Ext.form.field.Trigger, {
	setReadOnly: function(readOnly){
		var me = this;
		me.readOnly = readOnly;
		if(me.readOnlyField)
		{
			me.setVisible(!readOnly);
			me.readOnlyField.setVisible(readOnly);
		}
		me.callParent(arguments);
	}
});

Ext.override(Ext.form.field.ComboBox, {
	
	onChange: function(){
		var me = this;
		
		me.callParent(arguments);
		
		if(me.readOnlyField)
		{
			var selectedValue = me.getValue();
			var selectedRecordIndex = me.store.findExact(me.valueField, selectedValue);
			if(selectedRecordIndex != -1)
			{
				var displayValue = me.store.getAt(selectedRecordIndex).get(me.displayField);
				me.readOnlyField.setValue(displayValue);
			}
			else
				me.readOnlyField.setValue("");
			
		}
		
	}
	
});

Ext.override(Ext.form.field.Date, {
	
	onChange: function(){
		var me = this;
		
		me.callParent(arguments);
		
		if(me.readOnlyField)
		{
			var value = me.getValue();
			if(value)
				me.readOnlyField.setValue(Ext.Date.format(value, "m/d/Y"));
			else
				me.readOnlyField.setValue("");
		}
		
	}
	
});

Ext.override(Ext.form.field.Time, {
	
	displayMask: "h:i A",
	
	onChange: function(){
		var me = this;
		
		me.callParent(arguments);
		
		if(me.readOnlyField)
		{
			var value = me.getValue();
			if(value)
				me.readOnlyField.setValue(Ext.Date.format(value, me.displayMask));
			else
				me.readOnlyField.setValue("");
		}
		
	}
	
});

Ext.override(Ext.form.field.Display, {
	canHaveReadOnlyField: false
});

Ext.override(Ext.form.field.TextArea, {
	canHaveReadOnlyField: false
});

Ext.override(Ext.form.field.Trigger, {
	
	afterTriggerTpl: null,
	
	getSubTplMarkup: function() {
		
        var me = this,
            field = Ext.form.field.Text.prototype.getSubTplMarkup.call(this);

        return '<table id="' + me.id + '-triggerWrap" class="' + Ext.baseCSSPrefix + 'form-trigger-wrap" cellpadding="0" cellspacing="0"><tbody><tr>' +
            '<td id="' + me.id + '-inputCell" class="' + Ext.baseCSSPrefix + 'form-trigger-input-cell">' + field + '</td>' +
            me.getTriggerMarkup() +
			(me.afterTriggerTpl ? me.afterTriggerTpl : "") +
            '</tr></tbody></table>';
    }
});

Ext.override(Ext.form.field.ComboBox, {
	anyMatch: false,
	doQuery: function(queryString, forceAll, rawQuery) {
        queryString = queryString || '';

        // store in object and pass by reference in 'beforequery'
        // so that client code can modify values.
        var me = this,
            qe = {
                query: queryString,
                forceAll: forceAll,
                combo: me,
                cancel: false
            },
            store = me.store,
            isLocalMode = me.queryMode === 'local',
            needsRefresh;

        if (me.fireEvent('beforequery', qe) === false || qe.cancel) {
            return false;
        }

        // get back out possibly modified values
        queryString = qe.query;
        forceAll = qe.forceAll;

        // query permitted to run
        if (forceAll || (queryString.length >= me.minChars)) {
            // expand before starting query so LoadMask can position itself correctly
            me.expand();

            // make sure they aren't querying the same thing
            if (!me.queryCaching || me.lastQuery !== queryString) {
                me.lastQuery = queryString;

                if (isLocalMode) {
                    // forceAll means no filtering - show whole dataset.
                    store.suspendEvents();
                    needsRefresh = me.clearFilter();
                    if (queryString || !forceAll) {
						me.activeFilter = new Ext.util.Filter({
                            root: 'data',
							anyMatch: me.anyMatch,
                            property: me.displayField,
                            value: queryString
                        });
                        store.filter(me.activeFilter);
                        needsRefresh = true;
                    } else {
                        delete me.activeFilter;
                    }
                    store.resumeEvents();
                    if (me.rendered && needsRefresh) {
                        me.getPicker().refresh();
                    }
                } else {
                    // Set flag for onLoad handling to know how the Store was loaded
                    me.rawQuery = rawQuery;

                    // In queryMode: 'remote', we assume Store filters are added by the developer as remote filters,
                    // and these are automatically passed as params with every load call, so we do *not* call clearFilter.
                    if (me.pageSize) {
                        // if we're paging, we've changed the query so start at page 1.
                        me.loadPage(1);
                    } else {
                        store.load({
                            params: me.getParams(queryString)
                        });
                    }
                }
            }

            // Clear current selection if it does not match the current value in the field
            if (me.getRawValue() !== me.getDisplayValue()) {
                me.ignoreSelection++;
                me.picker.getSelectionModel().deselectAll();
                me.ignoreSelection--;
            }

            if (isLocalMode) {
                me.doAutoSelect();
            }
            if (me.typeAhead) {
                me.doTypeAhead();
            }
        }
        return true;
    }
});