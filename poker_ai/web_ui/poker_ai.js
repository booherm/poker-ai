Ext.ns("PokerAiUi");
Ext.ns("TournamentStepper");
Ext.ns("TournamentTester");
Ext.ns("StrategyTester");
Ext.ns("GaEvolver");

PokerAiUi.init = function()
{
    var tournamentStepperTab = TournamentStepper.init();
    var tournamentTesterTab = TournamentTester.init();
    var strategyTesterTab = StrategyTester.init();
	var gaEvolverTab = GaEvolver.init()
	
	var mainTabPanel = Ext.create("Ext.tab.Panel", {
		items: [tournamentStepperTab, tournamentTesterTab, strategyTesterTab, gaEvolverTab]
	});

	PokerAiUi.viewport = Ext.create("Ext.container.Viewport", {
		items: [mainTabPanel]
	});

};

Ext.onReady(function(){
	PokerAiUi.init();
});
