Ext.ns("PokerAiUi");
Ext.ns("TournamentStepper");
Ext.ns("GaEvolver");

PokerAiUi.init = function()
{
    var tournamentStepperTab = TournamentStepper.init();
	var gaEvolverTab = GaEvolver.init()
	
	var mainTabPanel = Ext.create("Ext.tab.Panel", {
		items: [tournamentStepperTab, gaEvolverTab]
	});

	PokerAiUi.viewport = Ext.create("Ext.container.Viewport", {
		items: [mainTabPanel]
	});

};

Ext.onReady(function(){
	PokerAiUi.init();
});
