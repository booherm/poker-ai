TournamentStepper.maxPlayerCount = 10;
TournamentStepper.maxPotCount = 5;
TournamentStepper.smallBlindSeatNumber = 1;
TournamentStepper.bigBlindSeatNumber = 2;
TournamentStepper.holeCardBorderStyle = "2px solid orange";
TournamentStepper.nonHoleCardBorderStyle = "1px solid black";
	
TournamentStepper.getPlayerHoleCardArrayHtml = function(seatNumber){
	var html = "<table><tr>";
	for(var i = 1; i <= 2; i++){
		var slotId = "seat_" + seatNumber + "_hole_card_" + i;
		html += "<td style='padding: 0 2 0 2;' onclick='TournamentStepper.cardSlotClicked({slotId: \""
			+ slotId + "\", cardType: \"HOLE_CARD\", seatNumber: " + seatNumber + ", cardSlot: " + i + "});'>"
			+ "<img id='" + slotId + "' style='width: 60px; height: 87px; border: " + TournamentStepper.holeCardBorderStyle + ";'/></td>";
	}
	html += "</tr></table>";

	return html;
};

TournamentStepper.getCommunityCardArrayHtml = function(){
	var html = "<table><tr>";
	for(var i = 1; i <= 5; i++){
		var slotId = "community_card_" + i;
		html += "<td style='padding: 0 2 0 2;' onclick='TournamentStepper.cardSlotClicked({slotId: \""
			+ slotId + "\", cardType: \"COMMUNITY_CARD\", seatNumber: null, cardSlot: " + i + "});'>"
			+ "<img id='" + slotId + "' style='width: 60px; height: 87px; border: " + TournamentStepper.nonHoleCardBorderStyle + ";'/></td>";
	}
	html += "</tr></table>";

	return html;
};

TournamentStepper.getPlayerBestHandCardArrayHtml = function(seatNumber){
	var html = "<table><tr>";
	for(var i = 1; i <= 5; i++){
		var slotId = "seat_" + seatNumber + "_best_hand_" + i;
		html += "<td style='padding: 0 2 0 2;'>"
			+ "<img id='" + slotId + "' style='width: 60px; height: 87px; border: " + TournamentStepper.nonHoleCardBorderStyle + ";'/></td>";
	}
	html += "</tr></table>";

	return html;
};

TournamentStepper.getPotArrayHtml = function(potCount){
	
	var html = "<table><tr>"
		+ "<th class='tableHeader'>#</th>"
		+ "<th class='tableHeader'>Amt.</th>"
		+ "<th class='tableHeader'>R1</th>"
		+ "<th class='tableHeader'>R2</th>"
		+ "<th class='tableHeader'>R3</th>"
		+ "<th class='tableHeader'>R4</th>"
		+ "<th class='tableHeader'>Contributor Seats</th>"
		+ "</tr>";
	for(var i = 1; i <= potCount; i++){
		html += "<tr>"
			+ "<td class='potNumberColumn'>" + i + "</td>"
			+ "<td id='pot_value_" + i + "' class='potAmountColumn'></td>"
			+ "<td id='pot_betting_round_1_value_" + i + "' class='potRoundNumberColumn'></td>"
			+ "<td id='pot_betting_round_2_value_" + i + "' class='potRoundNumberColumn'></td>"
			+ "<td id='pot_betting_round_3_value_" + i + "' class='potRoundNumberColumn'></td>"
			+ "<td id='pot_betting_round_4_value_" + i + "' class='potRoundNumberColumn'></td>"
			+ "<td id='pot_members_" + i + "' class='potContributorSeatsColumn'></td>"
			+ "</tr>";
	}
	html += "</table>";

	return html;
};

TournamentStepper.initCardSelectionWindow = function(){
	
	var cardArrayHtml = "<table style='margin: 15px 15px 15px 15px;'>";
	for(var suit = 0; suit < 4; suit++){
		cardArrayHtml += "<tr>";
		for(var card = 1; card <= 13; card++){
			var cardId = (13 * suit) + card;
			cardArrayHtml += "<td style='padding: 10px 3px 10px 3px'>"
				+ "<img src = '" + TournamentStepper.getCardImage(cardId) + "' "
				+ "style = 'width: 60px; height: 87px; border: 1px solid black;' "
				+ "onclick = 'TournamentStepper.cardSelected(" + cardId + ");' "
				+ "/></td>";
		}
		cardArrayHtml += "</tr>";
	}
	cardArrayHtml += "</table>";
	
	TournamentStepper.cardSelectionWindow = Ext.create("Ext.window.Window", {
		title: "Select Card",
		width: 900,
		height: 490,
		html: cardArrayHtml
	});
};

TournamentStepper.initTournamentPanel = function(){
	
	TournamentStepper.playerCountField = Ext.create("Ext.form.field.Number", {
		fieldLabel: "Player Count",
		allowBlank: false,
		repeatTriggerClick: false,
		labelWidth: 150,
		width: 225,
		minValue: 2,
		maxValue: TournamentStepper.maxPlayerCount,
		value: 4,
		step: 1,
		decimalPrecision: 0
	});
	
	TournamentStepper.stateSelectionField = Ext.create("Ext.form.field.Number", {
		fieldLabel: "State",
		allowBlank: true,
		hideTrigger: true,
		labelWidth: 50,
		width: 115,
		minValue: 0,
		decimalPrecision: 0,
		listeners: {change: TournamentStepper.stateSelectionFieldChanged}
	});
	
	TournamentStepper.stateLoadButton = Ext.create("Ext.Button", {
        text: "Load",
		margin: "0 0 0 5",
        width: 40,
		handler: TournamentStepper.loadState,
		disabled: true
    });
	
	TournamentStepper.statePreviousButton = Ext.create("Ext.Button", {
        text: "<",
		margin: "0 0 0 10",
        width: 20,
		handler: TournamentStepper.loadPreviousState,
		disabled: true
    });

	TournamentStepper.stateNextButton = Ext.create("Ext.Button", {
        text: ">",
		margin: "0 0 0 5",
        width: 20,
		handler: TournamentStepper.loadNextState,
		disabled: true
    });
	
	var stateControlContainer = Ext.create("Ext.container.Container", {
		layout: { type: "table", columns: 4, tdAttrs: { style: { verticalAlign: "top"} } },
		items: [
			TournamentStepper.stateSelectionField,
			TournamentStepper.stateLoadButton,
			TournamentStepper.statePreviousButton,
			TournamentStepper.stateNextButton
		]
	});
	
	TournamentStepper.buyInAmountField = Ext.create("Ext.form.field.Number", {
		fieldLabel: "Buy In Amount",
		allowBlank: false,
		repeatTriggerClick: false,
		labelWidth: 150,
		width: 225,
		minValue: 1,
		maxValue: 5000,
		value: 500,
		step: 1,
		decimalPrecision: 0,
		colspan: 2
	});
	
	TournamentStepper.currentGameNumberLabel = Ext.create("Ext.form.field.Display", {
		labelWidth: 150,
		fieldLabel: "Current Game Number",
		colspan: 2
	});
	
	TournamentStepper.gameInProgressLabel = Ext.create("Ext.form.field.Display", {
		labelWidth: 150,
		fieldLabel: "Game In Progress",
		colspan: 2
	});

	var reloadButton = Ext.create("Ext.Button", {
        text: "Reload Page",
        width: 150,
		colspan: 2,
        handler: function () {
            document.location.reload();
        }
    });

	var initInternalTournamentButton = Ext.create("Ext.Button", {
        text: "Init Int. Tournament",
        width: 150,
        handler: function(){ TournamentStepper.initTournament(0); }
    });
	
	var initExternalTournamentButton = Ext.create("Ext.Button", {
        text: "Init Ext. Tournament",
        width: 150,
        handler: function(){ TournamentStepper.initTournament(1); }
    });

	TournamentStepper.stepPlayButton = Ext.create("Ext.Button", {
        text: "Step Play",
        width: 150,
		colspan: 2,
		disabled: true,
        handler: function() {TournamentStepper.stepPlay(0, null);}
    });
	
	var tournamentFieldSet = Ext.create("Ext.form.FieldSet", {
		title: "Tournament",
		layout: { type: "table", columns: 2, tdAttrs: { style: { verticalAlign: "top" } } },
		width: 468,
		style: {borderColor: "black"},
		items: [
			TournamentStepper.playerCountField,
			stateControlContainer,
			TournamentStepper.buyInAmountField,
			TournamentStepper.currentGameNumberLabel,
			TournamentStepper.gameInProgressLabel,
			reloadButton,
			initInternalTournamentButton,
			initExternalTournamentButton,
			TournamentStepper.stepPlayButton
		]
    });
	
	TournamentStepper.statusTextArea = Ext.create("Ext.form.field.TextArea", {
		width: 455,
		height: 85
	});
	
	var statusFieldSet = Ext.create("Ext.form.FieldSet", {
		title: "Status",
		layout: { type: "table", columns: 1, tdAttrs: { style: { verticalAlign: "top" } } },
		width: 468,
		height: 110,
		style: {borderColor: "black"},
		padding: "0 0 3 5",
		items: [
			TournamentStepper.statusTextArea
		]
    });

	var tournamentPanel = Ext.create("Sms.form.Panel", {
        layout: { type: "table", columns: 1, tdAttrs: { style: { verticalAlign: "top" } } },
		border: false,
		bodyStyle: {"background-color": "37F0A3"},
		items: [tournamentFieldSet, statusFieldSet]
    });

	return tournamentPanel;
};

TournamentStepper.initGamePanel = function(){

	TournamentStepper.bettingRoundInProgressLabel = Ext.create("Ext.form.field.Display", {
		labelWidth: 120,
		fieldLabel: "Round In Progress"
	});

	TournamentStepper.bettingRoundLabel = Ext.create("Ext.form.field.Display", {
		fieldLabel: "Betting Round"
	});

	TournamentStepper.turnLabel = Ext.create("Ext.form.field.Display", {
		labelWidth: 120,
		fieldLabel: "Seat Turn"
	});
	
	TournamentStepper.lastToRaiseLabel = Ext.create("Ext.form.field.Display", {
		fieldLabel: "Last to Raise Seat"
	});
	
	TournamentStepper.smallBlindSeatLabel = Ext.create("Ext.form.field.Display", {
		labelWidth: 120,
		fieldLabel: "Small Blind Seat"
	});
	
	TournamentStepper.bigBlindSeatLabel = Ext.create("Ext.form.field.Display", {
		fieldLabel: "Big Blind Seat"
	});
	
	TournamentStepper.communityCardsLabel = Ext.create("Ext.form.field.Display", {
		labelWidth: 100,
		fieldLabel: "Community Cards",
		colspan: 2,
		afterSubTpl: TournamentStepper.getCommunityCardArrayHtml()
	});
	
	TournamentStepper.pots = Ext.create("Ext.form.field.Display", {
		labelWidth: 100,
		fieldLabel: "Pots",
		colspan: 2,
		afterSubTpl: TournamentStepper.getPotArrayHtml(TournamentStepper.maxPotCount)
	});

	TournamentStepper.smallBlindAmountField = Ext.create("Ext.form.field.Number", {
		fieldLabel: "Small Blind Amt.",
		allowBlank: false,
		repeatTriggerClick: false,
		labelWidth: 120,
		width: 175,
		minValue: 1,
		maxValue: 5000,
		value: 5,
		step: 1,
		decimalPrecision: 0
	});

	TournamentStepper.bigBlindAmountField = Ext.create("Ext.form.field.Display", {
		fieldLabel: "Big Blind Amt."
	});

	var gameStateFieldSet = Ext.create("Ext.form.FieldSet", {
		title: "Game State",
		layout: { type: "table", columns: 2, tdAttrs: { style: { verticalAlign: "top" } } },
		width: 468,
		height: 325,
		padding: "0 0 0 0",
		style: {borderColor: "black"},
		items: [
			TournamentStepper.bettingRoundInProgressLabel,
			TournamentStepper.bettingRoundLabel,
			TournamentStepper.turnLabel,
			TournamentStepper.lastToRaiseLabel,
			TournamentStepper.smallBlindSeatLabel,
			TournamentStepper.bigBlindSeatLabel,
			TournamentStepper.smallBlindAmountField,
			TournamentStepper.bigBlindAmountField,
			TournamentStepper.communityCardsLabel,
			TournamentStepper.pots
		]
    });

	var gamePanel = Ext.create("Sms.form.Panel", {
        border: false,
		layout: { type: "table", columns: 1, tdAttrs: { style: { verticalAlign: "top" } } },
		bodyStyle: {"background-color": "37F0A3"},
		items: [gameStateFieldSet]
	});
	
	return gamePanel;
};

TournamentStepper.initSeatPanel = function(seatNumber){
	
	TournamentStepper["playerIdLabel_" + seatNumber] = Ext.create("Ext.form.field.Display", {
		labelWidth: 100,
		fieldLabel: "Player ID"
	});
	
	TournamentStepper["playerMoneyLabel_" + seatNumber] = Ext.create("Ext.form.field.Display", {
		labelWidth: 100,
		fieldLabel: "Player Money"
	});

	TournamentStepper["playerStateLabel_" + seatNumber] = Ext.create("Ext.form.field.Display", {
		labelWidth: 100,
		fieldLabel: "State",
		value: "No Player"
	});

	TournamentStepper["playerHandShowingLabel_" + seatNumber] = Ext.create("Ext.form.field.Display", {
		labelWidth: 100,
		fieldLabel: "Hand Showing",
		colspan: "2"
	});

	TournamentStepper["playerTournamentRank_" + seatNumber] = Ext.create("Ext.form.field.Display", {
		labelWidth: 150,
		fieldLabel: "Tournament Rank"
	});

	TournamentStepper["playerGameRank_" + seatNumber] = Ext.create("Ext.form.field.Display", {
		labelWidth: 150,
		fieldLabel: "Game Rank"
	});
	
	TournamentStepper["playerTotalPotContribution_" + seatNumber] = Ext.create("Ext.form.field.Display", {
		labelWidth: 150,
		fieldLabel: "Total Pot Contribution"
	});

	TournamentStepper["playerHoleCards_" + seatNumber] = Ext.create("Ext.form.field.Display", {
		fieldLabel: "Hole Cards",
		labelWidth: 100,
		afterSubTpl: TournamentStepper.getPlayerHoleCardArrayHtml(seatNumber)
	});
	
	TournamentStepper["playerButtonFold_" + seatNumber] = Ext.create("Ext.Button", {
        text: "Fold",
		margin: "5 20 5 10",
        width: 50,
		disabled: true,
        handler: function() {TournamentStepper.playerFold(seatNumber);}
    });

	TournamentStepper["playerButtonCheck_" + seatNumber] = Ext.create("Ext.Button", {
        text: "Check",
		margin: "5 0 0 0",
        width: 50,
		disabled: true,
        handler: function() {TournamentStepper.playerCheck(seatNumber);}
    });
	
	TournamentStepper["playerButtonCall_" + seatNumber] = Ext.create("Ext.Button", {
        text: "Call",
		margin: "0 0 5 10",
		colspan: "2",
		disabled: true,
        width: 50,
        handler: function() {TournamentStepper.playerCall(seatNumber);}
    });

	TournamentStepper["playerButtonBet_" + seatNumber] = Ext.create("Ext.Button", {
        text: "Bet",
		margin: "0 0 0 10",
		disabled: true,
        width: 50,
        handler: function() {TournamentStepper.playerBet(seatNumber);}
    });
	
	TournamentStepper["playerBetAmount_" + seatNumber] = Ext.create("Ext.form.field.Number", {
		allowBlank: false,
		repeatTriggerClick: false,
		width: 100,
		minValue: 1,
		maxValue: 5000,
		value: 10,
		disabled: true,
		step: 1,
		decimalPrecision: 0,
		listeners: {validityChange: function(field, isValid) { TournamentStepper.betValueValidityChange(seatNumber, isValid); }}
	});

	var playerControlsContainer = Ext.create("Ext.container.Container", {
		layout: { type: "table", columns: 2, tdAttrs: { style: { verticalAlign: "top", width: "50px" } } },
		items: [
			TournamentStepper["playerButtonFold_" + seatNumber],
			TournamentStepper["playerButtonCheck_" + seatNumber],
			TournamentStepper["playerButtonCall_" + seatNumber],
			TournamentStepper["playerButtonBet_" + seatNumber],
			TournamentStepper["playerBetAmount_" + seatNumber]
		]
	});
	
	TournamentStepper["playerBestHandCards_" + seatNumber] = Ext.create("Ext.form.field.Display", {
		fieldLabel: "Best Hand",
		labelWidth: 100,
		colspan: "2",
		afterSubTpl: TournamentStepper.getPlayerBestHandCardArrayHtml(seatNumber)
	});
	
	TournamentStepper["playerBestHandRank_" + seatNumber] = Ext.create("Ext.form.field.Display", {
		fieldLabel: "Best Hand Rank",
		labelWidth: 100,
		colspan: "2"
	});
	
	var fieldSet = Ext.create("Ext.form.FieldSet", {
		layout: { type: "table", columns: 2, tdAttrs: { style: { verticalAlign: "top", width: "200px" } } },
		width: 468,
		height: 325,
		padding: "0 0 0 0",
		title: "Seat " + seatNumber,
		style: {borderColor: "black"},
		items: [
			TournamentStepper["playerIdLabel_" + seatNumber],
			TournamentStepper["playerTournamentRank_" + seatNumber],
			
			TournamentStepper["playerMoneyLabel_" + seatNumber],
			TournamentStepper["playerGameRank_" + seatNumber],
			
			TournamentStepper["playerStateLabel_" + seatNumber],
			
			TournamentStepper["playerTotalPotContribution_" + seatNumber],
			TournamentStepper["playerHandShowingLabel_" + seatNumber],
			
			TournamentStepper["playerHoleCards_" + seatNumber],
			playerControlsContainer,
			
			TournamentStepper["playerBestHandCards_" + seatNumber],
			TournamentStepper["playerBestHandRank_" + seatNumber]
		]
    });
	
    TournamentStepper["seatPanel_" + seatNumber] = Ext.create("Sms.form.Panel", {
		border: false,
		bodyStyle: {"background-color": "gray"},
		items: fieldSet
    });
	
	return TournamentStepper["seatPanel_" + seatNumber];
};

TournamentStepper.init = function()
{
	TournamentStepper.initCardSelectionWindow();
	
    var tournamentStepperTab = Ext.create("Ext.panel.Panel", {
		layout: { type: "table", columns: 4, tdAttrs: { style: { verticalAlign: "top", padding: "0 10 0 0"} } },
		bodyStyle: {"background-color": "lightgreen"},
		title: "Tournament Stepper",
		items: [
			TournamentStepper.initSeatPanel(1),
			TournamentStepper.initSeatPanel(2),
			TournamentStepper.initSeatPanel(3),
			TournamentStepper.initSeatPanel(4),
			TournamentStepper.initSeatPanel(10),
			TournamentStepper.initTournamentPanel(),
			TournamentStepper.initGamePanel(),
			TournamentStepper.initSeatPanel(5),
			TournamentStepper.initSeatPanel(9),
			TournamentStepper.initSeatPanel(8),
			TournamentStepper.initSeatPanel(7),
			TournamentStepper.initSeatPanel(6)
		]
    });

	return tournamentStepperTab;
};


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
TournamentStepper.getCardImage = function(cardId){
	if(cardId == null)
		return "images/cards/blank.png";
	
	return img = "images/cards/" + (cardId == 0 ? "back.jpg" : cardId + ".png");
};

TournamentStepper.initTournament = function(tournamentMode){
	PokerAi.initTournament(
		tournamentMode,
		TournamentStepper.playerCountField.getValue(),
		TournamentStepper.buyInAmountField.getValue()
	);
};

TournamentStepper.refreshUi = function(uiData){

	// tournament state
	TournamentStepper.playerCountField.setValue(uiData.tournamentState.player_count);
	TournamentStepper.buyInAmountField.setValue(uiData.tournamentState.buy_in_amount);
	TournamentStepper.currentGameNumberLabel.setValue(uiData.tournamentState.current_game_number);
	TournamentStepper.gameInProgressLabel.setValue(uiData.tournamentState.game_in_progress);
	TournamentStepper.stateSelectionField.setValue(uiData.tournamentState.current_state_id);
	
	// game state
	TournamentStepper.smallBlindSeatLabel.setValue(uiData.gameState.small_blind_seat_number);
	TournamentStepper.bigBlindSeatLabel.setValue(uiData.gameState.big_blind_seat_number);
	TournamentStepper.turnLabel.setValue(uiData.gameState.turn_seat_number);
	if(uiData.gameState.small_blind_value != null)
		TournamentStepper.smallBlindAmountField.setValue(uiData.gameState.small_blind_value);
	TournamentStepper.bigBlindAmountField.setValue(uiData.gameState.big_blind_value);
	TournamentStepper.bettingRoundLabel.setValue(uiData.gameState.betting_round_number);
	TournamentStepper.bettingRoundInProgressLabel.setValue(uiData.gameState.betting_round_in_progress);
	TournamentStepper.lastToRaiseLabel.setValue(uiData.gameState.last_to_raise_seat_number);
	for(var i = 1; i <= 5; i++){
		document.getElementById("community_card_" + i).src = TournamentStepper.getCardImage(uiData.gameState["community_card_" + i]);
	}
	
	// players state
	for(var i = 0; i < uiData.playerState.length; i++){
		
		var playerData = uiData.playerState[i];
		var seatNumber = playerData.seat_number;
		
		// reset controls to disabled state
		TournamentStepper["playerButtonFold_" + seatNumber].setDisabled(true);
		TournamentStepper["playerButtonCheck_" + seatNumber].setDisabled(true);
		TournamentStepper["playerButtonCall_" + seatNumber].setDisabled(true);
		TournamentStepper["playerButtonBet_" + seatNumber].setDisabled(true);
		TournamentStepper["playerBetAmount_" + seatNumber].setDisabled(true);
		TournamentStepper["playerButtonBet_" + seatNumber].setText("Bet");
			
		// set hole cards
		TournamentStepper["playerIdLabel_" + seatNumber].setValue(playerData.player_id);
		document.getElementById("seat_" + seatNumber + "_hole_card_1").src = TournamentStepper.getCardImage(playerData.hole_card_1);
		document.getElementById("seat_" + seatNumber + "_hole_card_2").src = TournamentStepper.getCardImage(playerData.hole_card_2);
		
		// set best hand rank
		TournamentStepper["playerBestHandRank_" + seatNumber].setValue(playerData.best_hand_classification);
		
		// set best hand cards
		for(var c = 1; c <= 5; c++){
			var cardSlot = document.getElementById("seat_" + seatNumber + "_best_hand_" + c);
			cardSlot.src = TournamentStepper.getCardImage(playerData["best_hand_card_" + c]);
			cardSlot.style.border = playerData["best_hand_card_" + c + "_is_hole_card"] ? TournamentStepper.holeCardBorderStyle : TournamentStepper.nonHoleCardBorderStyle;
		}
		
		// other generic attributes
		TournamentStepper["playerHandShowingLabel_" + seatNumber].setValue(playerData.hand_showing);
		TournamentStepper["playerMoneyLabel_" + seatNumber].setValue(playerData.money);
		TournamentStepper["playerStateLabel_" + seatNumber].setValue(playerData.state);
		TournamentStepper["playerGameRank_" + seatNumber].setValue(playerData.game_rank);
		TournamentStepper["playerTournamentRank_" + seatNumber].setValue(playerData.tournament_rank);
		TournamentStepper["playerTotalPotContribution_" + seatNumber].setValue(playerData.total_pot_contribution);

		// player seat backround color
		var playerColor = "lightgreen";
		if(playerData.state == "No Player" || playerData.state == "Out of Tournament")
			playerColor = "gray";
		else if (playerData.state == "Folded")
			playerColor = "CFD1D0";
		else if(seatNumber == uiData.gameState.turn_seat_number && uiData.gameState.betting_round_in_progress == "Yes")
			playerColor = "DDF037";
		TournamentStepper["seatPanel_" + seatNumber].setBodyStyle("background-color", playerColor);

		// player control buttons
		if(playerData.can_fold)
			TournamentStepper["playerButtonFold_" + seatNumber].setDisabled(false);
		if(playerData.can_check)
			TournamentStepper["playerButtonCheck_" + seatNumber].setDisabled(false);
		if(playerData.can_call)
			TournamentStepper["playerButtonCall_" + seatNumber].setDisabled(false);
		if(playerData.can_bet){
			TournamentStepper["playerButtonBet_" + seatNumber].setDisabled(false);
			TournamentStepper["playerBetAmount_" + seatNumber].setDisabled(false);
			TournamentStepper["playerBetAmount_" + seatNumber].setValue(playerData.min_bet_amount);
			TournamentStepper["playerBetAmount_" + seatNumber].setMinValue(playerData.min_bet_amount);
			TournamentStepper["playerBetAmount_" + seatNumber].setMaxValue(playerData.max_bet_amount);
			TournamentStepper["playerBetAmount_" + seatNumber].clearInvalid();
		}
		if(playerData.can_raise){
			TournamentStepper["playerButtonBet_" + seatNumber].setText("Raise");
			TournamentStepper["playerButtonBet_" + seatNumber].setDisabled(false);
			TournamentStepper["playerBetAmount_" + seatNumber].setDisabled(false);
			TournamentStepper["playerBetAmount_" + seatNumber].setValue(playerData.min_raise_amount);
			TournamentStepper["playerBetAmount_" + seatNumber].setMinValue(playerData.min_raise_amount);
			TournamentStepper["playerBetAmount_" + seatNumber].setMaxValue(playerData.max_raise_amount);
			TournamentStepper["playerBetAmount_" + seatNumber].clearInvalid();
		}
		
	}
	
	// pots state
	for(var i = 1; i <= TournamentStepper.maxPotCount; i++){
		document.getElementById("pot_value_" + i).innerHTML = "";
		document.getElementById("pot_betting_round_1_value_" + i).innerHTML = "";
		document.getElementById("pot_betting_round_2_value_" + i).innerHTML = "";
		document.getElementById("pot_betting_round_3_value_" + i).innerHTML = "";
		document.getElementById("pot_betting_round_4_value_" + i).innerHTML = "";
		document.getElementById("pot_members_" + i).innerHTML = "";
	}
	for(var i = 0; i < uiData.potState.length; i++){
		var potData = uiData.potState[i];
		var potNumber = potData.pot_number;
		
		document.getElementById("pot_value_" + potNumber).innerHTML = potData.pot_value;
		document.getElementById("pot_betting_round_1_value_" + potNumber).innerHTML = potData.betting_round_1_bet_value;
		document.getElementById("pot_betting_round_2_value_" + potNumber).innerHTML = potData.betting_round_2_bet_value;
		document.getElementById("pot_betting_round_3_value_" + potNumber).innerHTML = potData.betting_round_3_bet_value;
		document.getElementById("pot_betting_round_4_value_" + potNumber).innerHTML = potData.betting_round_4_bet_value;
		document.getElementById("pot_members_" + potNumber).innerHTML = potData.pot_members;
	}

	// status messages
	var message = "";
	for(var i = 0; i < uiData.statusMessage.length; i++){
		message += uiData.statusMessage[i] + "\n";
	}
	TournamentStepper.statusTextArea.setValue(message);
	TournamentStepper.statusTextArea.getEl().down("textarea").dom.scrollTop = 99999;
	
	// blinds indicators
	var sbSeatNum = uiData.gameState.small_blind_seat_number;
	var bbSeatNum = uiData.gameState.big_blind_seat_number;
	if(sbSeatNum != null)
		TournamentStepper["playerIdLabel_" + sbSeatNum].setValue(TournamentStepper["playerIdLabel_" + sbSeatNum].getValue() + " - Small Blind");
	if(bbSeatNum != null)
		TournamentStepper["playerIdLabel_" + bbSeatNum].setValue(TournamentStepper["playerIdLabel_" + bbSeatNum].getValue() + " - Big Blind");
	
	// all state setup, re-enable step play button
	TournamentStepper.stepPlayButton.setDisabled(false);

};

TournamentStepper.stepPlay = function(playerMove, playerMoveAmount){
	TournamentStepper.stepPlayButton.setDisabled(true);
	PokerAi.stepPlay(
		TournamentStepper.stateSelectionField.getValue(),
		TournamentStepper.smallBlindAmountField.getValue(),
		playerMove,
		playerMoveAmount
	);
};

TournamentStepper.playerFold = function(seatNumber){
	TournamentStepper.stepPlay(1, null);
};

TournamentStepper.playerCheck = function(seatNumber){
	TournamentStepper.stepPlay(2, null);
};

TournamentStepper.playerBet = function(seatNumber){
	if(TournamentStepper["playerButtonBet_" + seatNumber].getText() == "Bet")
		TournamentStepper.stepPlay(4, TournamentStepper["playerBetAmount_" + seatNumber].getValue());
	else
		TournamentStepper.stepPlay(5, TournamentStepper["playerBetAmount_" + seatNumber].getValue());
};

TournamentStepper.playerCall = function(seatNumber){
	TournamentStepper.stepPlay(3, null);
};

TournamentStepper.betValueValidityChange = function(seatNumber, isValid){
	TournamentStepper["playerButtonBet_" + seatNumber].setDisabled(!isValid);
};

TournamentStepper.cardSlotClicked = function(cardSlot){
	
	// card can only be edited if a card exists in the specified slot
	//console.log("current slot src = " + document.getElementById(cardSlot.slotId).src);
	
	var cardSlotCurrentSrc = document.getElementById(cardSlot.slotId).src;
	if(cardSlotCurrentSrc !== "" && cardSlotCurrentSrc.indexOf("blank.png") === -1){
		TournamentStepper.editingCardSlot = cardSlot;
		TournamentStepper.cardSelectionWindow.show();
	}
};

TournamentStepper.cardSelected = function(cardId){
	TournamentStepper.cardSelectionWindow.hide();
	PokerAi.editCard(TournamentStepper.stateSelectionField.getValue(),
		TournamentStepper.editingCardSlot.cardType,
		TournamentStepper.editingCardSlot.seatNumber,
		TournamentStepper.editingCardSlot.cardSlot,
		cardId
	);
};

TournamentStepper.loadState = function(){
	PokerAi.loadState(TournamentStepper.stateSelectionField.getValue());
};

TournamentStepper.loadPreviousState = function(){
	PokerAi.loadPreviousState(TournamentStepper.stateSelectionField.getValue());
};

TournamentStepper.loadNextState = function(){
	PokerAi.loadNextState(TournamentStepper.stateSelectionField.getValue());
};

TournamentStepper.stateSelectionFieldChanged = function(field, newValue){
	var disabled = newValue === "";
	TournamentStepper.stateLoadButton.setDisabled(disabled);
	TournamentStepper.statePreviousButton.setDisabled(disabled);
	TournamentStepper.stateNextButton.setDisabled(disabled);
};