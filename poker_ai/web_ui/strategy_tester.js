StrategyTester.init = function() {
	
	StrategyTester.performTestButton = Ext.create("Ext.Button", {
        text: "Perform Test",
        width: 150,
		margin: "10 0 0 100",
		handler: StrategyTester.performTest
    });
	
	var strategyTesterTab = Ext.create("Sms.form.Panel", {
		layout: { type: "table", columns: 1, tdAttrs: { style: { verticalAlign: "top", padding: "0 10 0 0"} } },
		bodyStyle: {"background-color": "lightgreen"},
		title: "Strategy Tester",
		height: 1000,
		items: [
			StrategyTester.performTestButton
		]
    });
	
	return strategyTesterTab;
	
};

StrategyTester.performTest = function() {
	
	PokerAi.performStrategyTest();
};
