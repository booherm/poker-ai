/**
 * This file is to be included only when generating a report PDF on the server.
 * It redefines MrRunContainer methods in order to work separately from the run
 * container.
 */
MrRunContainer.deferItem = function(itemIndex, className, config){
	Ext.onReady(function(){
		MrRunContainer.items[itemIndex] = Ext.create(className, config);
	});
};

MrRunContainer.init = Ext.emptyFn;
