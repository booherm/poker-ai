/**
 * As the number of records increases, the time required for the browser to render them increases. Paging is used to
 * reduce the amount of data exchanged with the client. Note: if there are more records/rows than can be viewed in the
 * available screen area, vertical scrollbars will be added.
 *
 * Paging is typically handled on the server side (see exception below). The client sends parameters to the server side,
 * which the server needs to interpret and then respond with the appropriate data.
 *
 * Ext.toolbar.Paging is a specialized toolbar that is bound to a {@link Ext.data.Store} and provides automatic
 * paging control. This Component {@link Ext.data.Store#load load}s blocks of data into the {@link #store} by passing
 * parameters used for paging criteria.
 *
 * {@img Ext.toolbar.Paging/Ext.toolbar.Paging.png Ext.toolbar.Paging component}
 *
 * Paging Toolbar is typically used as one of the Grid's toolbars:
 *
 *     @example
 *     var itemsPerPage = 2;   // set the number of items you want per page
 *
 *     var store = Ext.create('Ext.data.Store', {
 *         id:'simpsonsStore',
 *         autoLoad: false,
 *         fields:['name', 'email', 'phone'],
 *         pageSize: itemsPerPage, // items per page
 *         proxy: {
 *             type: 'ajax',
 *             url: 'pagingstore.js',  // url that will load data with respect to start and limit params
 *             reader: {
 *                 type: 'json',
 *                 root: 'items',
 *                 totalProperty: 'total'
 *             }
 *         }
 *     });
 *
 *     // specify segment of data you want to load using params
 *     store.load({
 *         params:{
 *             start:0,
 *             limit: itemsPerPage
 *         }
 *     });
 *
 *     Ext.create('Ext.grid.Panel', {
 *         title: 'Simpsons',
 *         store: store,
 *         columns: [
 *             { header: 'Name',  dataIndex: 'name' },
 *             { header: 'Email', dataIndex: 'email', flex: 1 },
 *             { header: 'Phone', dataIndex: 'phone' }
 *         ],
 *         width: 400,
 *         height: 125,
 *         dockedItems: [{
 *             xtype: 'pagingtoolbar',
 *             store: store,   // same store GridPanel is using
 *             dock: 'bottom',
 *             displayInfo: true
 *         }],
 *         renderTo: Ext.getBody()
 *     });
 *
 * To use paging, pass the paging requirements to the server when the store is first loaded.
 *
 *     store.load({
 *         params: {
 *             // specify params for the first page load if using paging
 *             start: 0,
 *             limit: myPageSize,
 *             // other params
 *             foo:   'bar'
 *         }
 *     });
 *
 * If using {@link Ext.data.Store#autoLoad store's autoLoad} configuration:
 *
 *     var myStore = Ext.create('Ext.data.Store', {
 *         {@link Ext.data.Store#autoLoad autoLoad}: {start: 0, limit: 25},
 *         ...
 *     });
 *
 * The packet sent back from the server would have this form:
 *
 *     {
 *         "success": true,
 *         "results": 2000,
 *         "rows": [ // ***Note:** this must be an Array
 *             { "id":  1, "name": "Bill", "occupation": "Gardener" },
 *             { "id":  2, "name":  "Ben", "occupation": "Horticulturalist" },
 *             ...
 *             { "id": 25, "name":  "Sue", "occupation": "Botanist" }
 *         ]
 *     }
 *
 * ## Paging with Local Data
 *
 * Paging can also be accomplished with local data using extensions:
 *
 *   - [Ext.ux.data.PagingStore][1]
 *   - Paging Memory Proxy (examples/ux/PagingMemoryProxy.js)
 *
 *    [1]: http://sencha.com/forum/showthread.php?t=71532
 */
//a special store that all treepanels using this toolbar should extend from,
//it provides all the fields necessary for paging
Ext.define("Ext.toolbar.TreePagingModel", {
	extend: "Ext.data.Model",
	fields: [
		{name:"id", type:"auto"},
		{name:"text", type:"string"},
		{name:"iconCls", type:"string"},
		{name:"leaf", type:"boolean"},
		{name:"allowSelect", type:"boolean", defaultValue: true},
		{name:"page_number", type:"auto", defaultValue: 1},
		{name:"total_count", type:"auto", defaultValue: 0},
		{name:"is_paging_node", type:"boolean", defaultValue: false}
	]
});

Ext.define('Ext.toolbar.TreePaging', {
    extend: 'Ext.toolbar.Paging',
    alias: 'widget.treepagingtoolbar',
    alternateClassName: 'Ext.TreePagingToolbar',
	
	currentPage: 1,
	totalCount:  null,
	
	pageSize: 100,
	
	pageAllNodes: false,
	pageAllNodesDisplayDataIndex: "text",
	
    initComponent : function(){
		var me = this;
        me.callParent();
		me.pageSize = me.store.pageSize;
		me.store.getProxy().extraParams["limit"] = me.pageSize;
		
		Ext.toolbar.TreePaging.addToPagers(me);
    },
    // private
    updateInfo : function(){
        var me = this,
            displayItem = me.child('#displayItem'),
            store = me.store,
            pageData = me.getPageData(),
            count, msg;

        if (displayItem) {
            count = store.getRootNode().childNodes ? store.getRootNode().childNodes.length : 0;
            if (count === 0) {
                msg = me.emptyMsg;
            } else {
                msg = Ext.String.format(
                    me.displayMsg,
                    pageData.fromRecord,
                    pageData.toRecord,
                    pageData.total
                );
            }
            displayItem.setText(msg);
            me.doComponentLayout();
        }
    },
	
	onLoad : function(treestore, node, records, successful){
		if(!successful)//load of the node was not successful, let the store handle the error
			return false;
		var me = this;
		if(treestore.$className == "Ext.toolbar.TreePaging" || treestore.getRootNode() == node)
		{
			var pageData,
				currPage,
				pageCount,
				afterText;

			if (!me.rendered) {
				return;
			}
			var pageNumberFromData = me.store.getProxy().getReader().jsonData.page_number;
			me.currentPage = (pageNumberFromData || pageNumberFromData == 0) ? parseInt(pageNumberFromData, 10) : me.currentPage;
			me.totalCount = node.isLoaded() ? me.store.getProxy().getReader().jsonData.total_count : 0;

			pageData = me.getPageData();
			currPage = pageData.currentPage;
			pageCount = pageData.pageCount;
			afterText = Ext.String.format(me.afterPageText, isNaN(pageCount) ? 1 : pageCount);

			me.child('#afterTextItem').setText(afterText);
			me.child('#inputItem').setValue(currPage);
			me.child('#first').setDisabled(currPage === 1);
			me.child('#prev').setDisabled(currPage === 1);
			me.child('#next').setDisabled(currPage === pageCount);
			me.child('#last').setDisabled(currPage === pageCount);
			me.child('#inputItem').enable();
			me.child('#refresh').enable();
			me.updateInfo();
			me.fireEvent('change', me, pageData);
		}
		else if(me.pageAllNodes)
		{
			var totalCount = node.isLoaded() ? me.store.getProxy().getReader().jsonData.total_count : 0;
			node.set("total_count", totalCount);
			
			if(totalCount > me.pageSize)
			{
				var pageNumberFromData = me.store.getProxy().getReader().jsonData.page_number;
				var pageNumber = (pageNumberFromData || pageNumberFromData == 0) ? pageNumberFromData : node.get("page_number");
				var displayStart = ((pageNumber - 1) * me.pageSize) + 1;
				var displayEnd = (pageNumber * me.pageSize) > totalCount ? totalCount : (pageNumber * me.pageSize);

				//this is not the root node, create a node to immitate a pager, but with less functionality than the root node
				var nodeConfig = {
					iconCls:        "silk-none",
					leaf:           true,
					allowSelect:    false,
					allowDrag:      false,
					is_paging_node: true,
					prevent_mark:   true
				};
				var newNode = node.appendChild(nodeConfig);
				newNode.set(me.pageAllNodesDisplayDataIndex, "<img style=\"vertical-align:middle;\" src=\"images/sort_arrow_left.gif\" onclick=\"Ext.toolbar.TreePaging.subNodePageLeft(" + me.identifier + ", '" + newNode.id + "');\"/>"
					+ "<img style=\"vertical-align:middle;\" src=\"images/sort_arrow_right.gif\" onclick=\"Ext.toolbar.TreePaging.subNodePageRight(" + me.identifier + ", '" + newNode.id + "');\"/>"
					+ "&nbsp;&nbsp;Displaying " + displayStart + "-" + displayEnd + " of " + totalCount);
				newNode.commit();
			}
		}
		else if(treestore.$className == "Ext.toolbar.TreePaging")
		{
			me.child('#inputItem').enable();
			me.child('#refresh').enable();
		}
		me.storeIsLoading = false;
    },
	
	statics: {
		
		treePagers: null,
		pagerCount: 0,
		
		subNodePageLeft: function(identifier, nodeId){
			var treePager = Ext.toolbar.TreePaging.getPager(identifier);
			var store = treePager.store;
			var node = store.getRootNode().findChildBy(function(testNode){
				if(testNode.id == nodeId)
					return true;
			}, this, true).parentNode;
			if(node.get("page_number") > 1)
			{
				if (treePager.fireEvent('beforechange', treePager, (node.get("page_number") - 1), node) !== false){
					node.set("page_number", (node.get("page_number") - 1));
					store.load({
						node: node
					});
				}
			}
		},
		
		subNodePageRight: function(identifier, nodeId){
			var treePager = Ext.toolbar.TreePaging.getPager(identifier);
			var store = treePager.store;
			var node = store.getRootNode().findChildBy(function(testNode){
				if(testNode.id == nodeId)
					return true;
			}, this, true).parentNode;
			if((node.get("page_number") * treePager.pageSize) < node.get("total_count"))
			{
				if (treePager.fireEvent('beforechange', treePager, (node.get("page_number") + 1), node) !== false){
					node.set("page_number", (node.get("page_number") + 1));
					store.load({
						node: node
					});
				}
			}
		},
		
		subNodePageTo: function(identifier, nodeId, pageNumber, callback){
			var treePager = Ext.toolbar.TreePaging.getPager(identifier);
			var store = treePager.store;
			var node = store.getNodeById(nodeId);
			if((pageNumber * treePager.pageSize) < node.get("total_count"))
			{
				if (treePager.fireEvent('beforechange', treePager, pageNumber, node) !== false){
					node.set("page_number", pageNumber);
					store.load({
						node: node,
						callback: function(){
							callback(store, node);
						}
					});
				}
			}
		},
		
		addToPagers: function(treePager){
			this.pagerCount = this.pagerCount + 1;
			if(!this.treePagers)
				this.treePagers = new Ext.util.MixedCollection();
			this.treePagers.add(this.pagerCount, treePager);
			treePager.identifier = this.pagerCount;
		},
		
		getPager: function(identifier){
			if(!this.treePagers)
				return null;
			return this.treePagers.get(identifier);
		}
	},

    // private
    getPageData : function(){
        var me = this,
			totalCount = me.totalCount;
			
		return {
            total : totalCount,
            currentPage : me.currentPage,
            pageCount: (totalCount == 0) ? 1 : Math.ceil(totalCount / me.pageSize),
            fromRecord: ((me.currentPage - 1) * me.pageSize) + 1,
            toRecord: Math.min(me.currentPage * me.pageSize, totalCount)
        };
    },
	
	onPagingKeyDown : function(field, e){
        var me = this,
            k = e.getKey(),
            pageData = me.getPageData(),
            increment = e.shiftKey ? 10 : 1,
            pageNum;

		if(!me.storeIsLoading)
		{
			if (k == e.RETURN) {
				e.stopEvent();
				pageNum = me.readPageFromInput(pageData);
				if (pageNum !== false) {
					pageNum = Math.min(Math.max(1, pageNum), pageData.pageCount);
					if(me.fireEvent('beforechange', me, pageNum, me.store.getRootNode()) !== false){
						me.currentPage = pageNum;
						me.storeIsLoading = true;
						me.store.load();
					}
				}
			} else if (k == e.HOME || k == e.END) {
				e.stopEvent();
				pageNum = k == e.HOME ? 1 : pageData.pageCount;
				field.setValue(pageNum);
			} else if (k == e.UP || k == e.PAGEUP || k == e.DOWN || k == e.PAGEDOWN) {
				e.stopEvent();
				pageNum = me.readPageFromInput(pageData);
				if (pageNum) {
					if (k == e.DOWN || k == e.PAGEDOWN) {
						increment *= -1;
					}
					pageNum += increment;
					if (pageNum >= 1 && pageNum <= pageData.pages) {
						field.setValue(pageNum);
					}
				}
			}
		}
    },

    // private
    beforeLoad : function(store, operation, eOpts){
		var me = this,
			node = operation.node,
			currentPage = node.get("page_number");
		
		if(node == me.store.getRootNode())
			currentPage = me.currentPage;//from the bar on the bottom, not a node
		
		me.store.getProxy().extraParams["start"] = (currentPage - 1) * me.pageSize;
		var refresh = me.child('#refresh');
		var inputItem = me.child('#inputItem');
		if(me.rendered && refresh && inputItem && node == me.store.getRootNode()){
			refresh.disable();
			inputItem.disable();
		}
    },

    /**
     * Move to the first page, has the same effect as clicking the 'first' button.
     */
    moveFirst : function(){
        if (this.fireEvent('beforechange', this, 1, this.store.getRootNode()) !== false){
			this.currentPage = 1;
            this.store.load();
        }
    },

    /**
     * Move to the previous page, has the same effect as clicking the 'previous' button.
     */
    movePrevious : function(){
        var me = this,
            prev = me.currentPage - 1;

        if (prev > 0) {
            if (me.fireEvent('beforechange', me, prev, me.store.getRootNode()) !== false) {
				me.currentPage = prev;
                me.store.load();
            }
        }
    },

    /**
     * Move to the next page, has the same effect as clicking the 'next' button.
     */
    moveNext : function(){
        var me = this,
            total = me.getPageData().pageCount,
            next = me.currentPage + 1;

		if (next <= total) {
            if (me.fireEvent('beforechange', me, next, me.store.getRootNode()) !== false) {
				me.currentPage = next;
                me.store.load();
            }
        }
    },

    /**
     * Move to the last page, has the same effect as clicking the 'last' button.
     */
    moveLast : function(){
        var me = this,
            last = me.getPageData().pageCount;

        if (me.fireEvent('beforechange', me, last, me.store.getRootNode()) !== false) {
			me.currentPage = last;
            me.store.load();
        }
    },
	
	/**
     * Select a node's page a nodes to a specific page
     */
	moveTo : function(pageNumber, inputNode, callback){
		var me = this,
		    parentNode = inputNode ? inputNode : me.store.getRootNode();
		if(parentNode == me.store.getRootNode())
		{
			if (me.fireEvent('beforechange', me, pageNumber, parentNode) !== false) {
				me.currentPage = pageNumber;
				me.store.load({
					callback: function(){
						if(callback)
							callback(me.store, me.store.getRootNode());
					}
				});
			}
		}
		else
			Ext.toolbar.TreePaging.subNodePageTo(me.identifier, parentNode.get("id"), pageNumber, callback);
	},

    /**
     * Refresh the current page, has the same effect as clicking the 'refresh' button.
     */
    doRefresh : function(){
        var me = this,
            current = me.store.currentPage;

        if (me.fireEvent('beforechange', me, current, me.store.getRootNode()) !== false) {
            me.store.load();
        }
    },
	
	loadToItem : function(node, findNodeId, callback){
        var me = this,
            current = me.store.currentPage;

		if(node == me.store.getRootNode() || !node)
		{
			if (me.fireEvent('beforechange', me, current, me.store.getRootNode()) !== false) {
				if(callback)
					me.store.getRootNode().on('expand', callback, me.store.getRootNode(), {single: true});
				me.store.load({
					node: me.store.getRootNode(),
					params:{
						search_node_id: findNodeId
					}
				});
			}
		}
		else
		{
			if(callback)
				node.on('expand', callback, node, {single: true});
			me.store.load({
				node: node,
				params:{
					search_node_id: findNodeId
				},
				callback: function(){
					node.expand();
				}
			});
		}
    },
	
	loadPath: function(node, path, callback){
		var me = this;
		if(!node)
			node = me.store.getRootNode();
		if(Ext.isString(path))
			path = path.split("/");
		if(!Ext.isArray(path))
			return;
		if(path.length > 0)
		{
			var nodeToFind = path.splice(0, 1);
			if(Ext.isArray(nodeToFind))
				nodeToFind = nodeToFind[0];
			me.loadToItem(node, nodeToFind, function(){
				var foundNode = node.findChildBy(function(possibleMatchNode){
					if(possibleMatchNode.getId() == nodeToFind)
						return true;
				});
				if(foundNode && path.length > 0)
					me.loadPath(foundNode, path, callback);
				else if(Ext.isFunction(callback))
					callback(foundNode);
			});
		}
	},

    /**
     * Binds the paging toolbar to the specified {@link Ext.data.Store}
     * @param {Ext.data.Store} store The store to bind to this toolbar
     * @param {Boolean} initial (Optional) true to not remove listeners
     */
    bindStore : function(store, initial){
        var me = this;

        if (!initial && me.store) {
            if(store !== me.store && me.store.autoDestroy){
                me.store.destroyStore();
            }else{
                me.store.un('beforeload', me.beforeLoad, me);
                me.store.un('load', me.onLoad, me);
                me.store.un('exception', me.onLoadError, me);
            }
            if(!store){
                me.store = null;
            }
        }
        if (store) {
            store = Ext.data.StoreManager.lookup(store);
            store.on({
                scope: me,
                beforeload: me.beforeLoad,
                load: me.onLoad,
                exception: me.onLoadError
            });
        }
        me.store = store;
    },

    /**
     * Unbinds the paging toolbar from the specified {@link Ext.data.Store} **(deprecated)**
     * @param {Ext.data.Store} store The data store to unbind
     */
    unbind : function(store){
        this.bindStore(null);
    },

    /**
     * Binds the paging toolbar to the specified {@link Ext.data.Store} **(deprecated)**
     * @param {Ext.data.Store} store The data store to bind
     */
    bind : function(store){
        this.bindStore(store);
    },

    // private
    onDestroy : function(){
        this.bindStore(null);
        this.callParent();
    }
});