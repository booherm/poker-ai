GaEvolver.init = function() {
	
	GaEvolver.trialIdField = Ext.create("Ext.form.field.Number", {
		fieldLabel: "Trial ID",
		allowBlank: false,
		repeatTriggerClick: false,
		labelWidth: 200,
		width: 280,
		minValue: 1,
		maxValue: 50000,
		value: 1,
		step: 1,
		decimalPrecision: 0,
		padding: "10 0 0 0"
	});

	GaEvolver.controlGenerationField = Ext.create("Ext.form.field.Number", {
		fieldLabel: "Control Generation",
		allowBlank: false,
		repeatTriggerClick: false,
		labelWidth: 200,
		width: 280,
		minValue: 0,
		maxValue: 50000,
		value: 0,
		step: 1,
		decimalPrecision: 0
	});

	GaEvolver.startFromGenerationField = Ext.create("Ext.form.field.Number", {
		fieldLabel: "Start From Generation",
		allowBlank: false,
		repeatTriggerClick: false,
		labelWidth: 200,
		width: 280,
		minValue: 0,
		maxValue: 50000,
		value: 0,
		step: 1,
		decimalPrecision: 0
	});

	GaEvolver.generationSizeField = Ext.create("Ext.form.field.Number", {
		fieldLabel: "Generation Size",
		allowBlank: false,
		repeatTriggerClick: false,
		labelWidth: 200,
		width: 280,
		minValue: 1,
		maxValue: 5000,
		value: 100,
		step: 1,
		decimalPrecision: 0
	});

	GaEvolver.maxGenerationsField = Ext.create("Ext.form.field.Number", {
		fieldLabel: "Max Generations",
		allowBlank: false,
		repeatTriggerClick: false,
		labelWidth: 200,
		width: 280,
		minValue: 1,
		maxValue: 1000000,
		value: 10000,
		step: 1,
		decimalPrecision: 0
	});
	
	GaEvolver.crossoverRateField = Ext.create("Ext.form.field.Number", {
		fieldLabel: "Crossover Rate",
		allowBlank: false,
		repeatTriggerClick: false,
		labelWidth: 200,
		width: 280,
		minValue: 0,
		maxValue: 1,
		value: 0.85,
		step: 0.1,
		decimalPrecision: 4
	});
	
	GaEvolver.crossoverPointField = Ext.create("Ext.form.field.Number", {
		fieldLabel: "Crossover Point",
		allowBlank: false,
		repeatTriggerClick: false,
		labelWidth: 200,
		width: 280,
		minValue: 1,
		maxValue: 1000000,
		value: 4000,
		step: 1,
		decimalPrecision: 0
	});
	
	GaEvolver.mutationRateField = Ext.create("Ext.form.field.Number", {
		fieldLabel: "Mutation Rate",
		allowBlank: false,
		repeatTriggerClick: false,
		labelWidth: 200,
		width: 280,
		minValue: 0,
		maxValue: 1,
		value: 0.001,
		step: 0.01,
		decimalPrecision: 8
	});

	GaEvolver.playersPerTournamentField = Ext.create("Ext.form.field.Number", {
		fieldLabel: "Players Per Tournament",
		allowBlank: false,
		repeatTriggerClick: false,
		labelWidth: 200,
		width: 280,
		minValue: 2,
		maxValue: 10,
		value: 10,
		step: 1,
		decimalPrecision: 0
	});

	GaEvolver.tournamentWorkerThreadsField = Ext.create("Ext.form.field.Number", {
		fieldLabel: "Tournament Worker Threads",
		allowBlank: false,
		repeatTriggerClick: false,
		labelWidth: 200,
		width: 280,
		minValue: 0,
		maxValue: 100,
		value: 20,
		step: 1,
		decimalPrecision: 0
	});

	GaEvolver.tournamentPlayCountField = Ext.create("Ext.form.field.Number", {
		fieldLabel: "Tournament Play Count",
		allowBlank: false,
		repeatTriggerClick: false,
		labelWidth: 200,
		width: 280,
		minValue: 1,
		maxValue: 5000,
		value: 100,
		step: 1,
		decimalPrecision: 0
	});

	GaEvolver.tournamentBuyInField = Ext.create("Ext.form.field.Number", {
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

	GaEvolver.initialSmallBlindValueField = Ext.create("Ext.form.field.Number", {
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
	
	GaEvolver.doubleBlindsIntervalField = Ext.create("Ext.form.field.Number", {
		fieldLabel: "Double Blinds Interval",
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
	
	GaEvolver.performEvolutionTrialButton = Ext.create("Ext.Button", {
        text: "Perform Evolution Trial",
        width: 150,
		margin: "10 0 0 100",
		handler: GaEvolver.performEvolutionTrial
    });

	GaEvolver.joinEvolutionTrialButton = Ext.create("Ext.Button", {
        text: "Join Evolution Trial",
        width: 150,
		margin: "10 0 0 100",
		handler: GaEvolver.joinEvolutionTrial
    });
	
	var gaEvolverTab = Ext.create("Sms.form.Panel", {
		layout: { type: "table", columns: 1, tdAttrs: { style: { verticalAlign: "top", padding: "0 10 0 0"} } },
		bodyStyle: {"background-color": "lightgreen"},
		title: "GA Evolver",
		height: 1000,
		items: [
			GaEvolver.trialIdField,
			GaEvolver.controlGenerationField,
			GaEvolver.startFromGenerationField,
			GaEvolver.generationSizeField,
			GaEvolver.maxGenerationsField,
			GaEvolver.crossoverRateField,
			GaEvolver.crossoverPointField,
			GaEvolver.mutationRateField,
			GaEvolver.playersPerTournamentField,
			GaEvolver.tournamentWorkerThreadsField,
			GaEvolver.tournamentPlayCountField,
			GaEvolver.tournamentBuyInField,
			GaEvolver.initialSmallBlindValueField,
			GaEvolver.doubleBlindsIntervalField,
			GaEvolver.performEvolutionTrialButton,
			GaEvolver.joinEvolutionTrialButton
		]
    });
	
	return gaEvolverTab;
	
};

GaEvolver.performEvolutionTrial = function() {
	PokerAi.performEvolutionTrial(
		GaEvolver.trialIdField.getValue(),
		GaEvolver.controlGenerationField.getValue(),
		GaEvolver.startFromGenerationField.getValue(),
		GaEvolver.generationSizeField.getValue(),
		GaEvolver.maxGenerationsField.getValue(),
		GaEvolver.crossoverRateField.getValue(),
		GaEvolver.crossoverPointField.getValue(),
		GaEvolver.mutationRateField.getValue(),
		GaEvolver.playersPerTournamentField.getValue(),
		GaEvolver.tournamentWorkerThreadsField.getValue(),
		GaEvolver.tournamentPlayCountField.getValue(),
		GaEvolver.tournamentBuyInField.getValue(),
		GaEvolver.initialSmallBlindValueField.getValue(),
		GaEvolver.doubleBlindsIntervalField.getValue()
	);
};

GaEvolver.joinEvolutionTrial = function() {
	PokerAi.joinEvolutionTrial(
		GaEvolver.trialIdField.getValue(),
		GaEvolver.tournamentWorkerThreadsField.getValue()
	);
};
