TournamentTester.init = function() {
	
	TournamentTester.evolutionTrialId = Ext.create("Ext.form.field.Number", {
		fieldLabel: "Evolution Trial ID",
		allowBlank: false,
		repeatTriggerClick: false,
		labelWidth: 200,
		width: 280,
		minValue: 1,
		maxValue: 99999999,
		value: 1,
		step: 1,
		padding: "10 0 0 0",
		decimalPrecision: 0
	});
	
	TournamentTester.tournamentCount = Ext.create("Ext.form.field.Number", {
		fieldLabel: "Tournament Count",
		allowBlank: false,
		repeatTriggerClick: false,
		labelWidth: 200,
		width: 280,
		minValue: 1,
		maxValue: 99999999,
		value: 1,
		step: 1,
		decimalPrecision: 0
	});
	
	TournamentTester.playerCount = Ext.create("Ext.form.field.Number", {
		fieldLabel: "Player Count",
		allowBlank: false,
		repeatTriggerClick: false,
		labelWidth: 200,
		width: 280,
		minValue: 2,
		maxValue: 10,
		value: 4,
		step: 1,
		decimalPrecision: 0
	});

	TournamentTester.tournamentBuyInField = Ext.create("Ext.form.field.Number", {
		fieldLabel: "Tournament Buy In",
		allowBlank: false,
		repeatTriggerClick: false,
		labelWidth: 200,
		width: 280,
		minValue: 1,
		maxValue: 5000,
		value: 500,
		step: 1,
		decimalPrecision: 0
	});

	TournamentTester.initialSmallBlindValueField = Ext.create("Ext.form.field.Number", {
		fieldLabel: "Initial Small Blind Amt.",
		allowBlank: false,
		repeatTriggerClick: false,
		labelWidth: 200,
		width: 280,
		minValue: 1,
		maxValue: 5000,
		value: 5,
		step: 1,
		decimalPrecision: 0
	});
	
	TournamentTester.doubleBlindsIntervalField = Ext.create("Ext.form.field.Number", {
		fieldLabel: "Double Blinds Interval",
		allowBlank: false,
		repeatTriggerClick: false,
		labelWidth: 200,
		width: 280,
		minValue: 0,
		maxValue: 5000,
		value: 5,
		step: 1,
		decimalPrecision: 0
	});
	
	TournamentTester.performTestButton = Ext.create("Ext.Button", {
        text: "Perform Test",
        width: 150,
		margin: "10 0 0 100",
		handler: TournamentTester.performTest
    });
	
	var tournamentTesterTab = Ext.create("Sms.form.Panel", {
		layout: { type: "table", columns: 1, tdAttrs: { style: { verticalAlign: "top", padding: "0 10 0 0"} } },
		bodyStyle: {"background-color": "lightgreen"},
		title: "Tournament Tester",
		height: 1000,
		items: [
			TournamentTester.evolutionTrialId,
			TournamentTester.tournamentCount,
			TournamentTester.playerCount,
			TournamentTester.tournamentBuyInField,
			TournamentTester.initialSmallBlindValueField,
			TournamentTester.doubleBlindsIntervalField,
			TournamentTester.performTestButton
		]
    });
	
	return tournamentTesterTab;
	
};

TournamentTester.performTest = function() {
	
	PokerAi.performTournamentTest(
		TournamentTester.evolutionTrialId.getValue(),
		TournamentTester.tournamentCount.getValue(),
		TournamentTester.playerCount.getValue(),
		TournamentTester.tournamentBuyInField.getValue(),
		TournamentTester.initialSmallBlindValueField.getValue(),
		TournamentTester.doubleBlindsIntervalField.getValue()
	);
};
