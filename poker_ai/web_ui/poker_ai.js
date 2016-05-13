Ext.ns("PokerAiUi");

PokerAiUi.maxPlayerCount = 10;
PokerAiUi.maxPotCount = 5;
PokerAiUi.smallBlindSeatNumber = 1;
PokerAiUi.bigBlindSeatNumber = 2;
PokerAiUi.holeCardBorderStyle = "2px solid orange";
PokerAiUi.nonHoleCardBorderStyle = "1px solid black";
	
PokerAiUi.getCardArrayHtml = function(id, cardCount, holeCardStyle){

	var borderStyle = holeCardStyle ? PokerAiUi.holeCardBorderStyle : PokerAiUi.nonHoleCardBorderStyle;
	var html = "<table><tr>";
	for(var i = 1; i <= cardCount; i++){
		html += "<td style='padding: 0 2 0 2;'><img id='" + id + "_" + i + "' style='width: 60px; height: 87px; border: " + borderStyle + ";'/></td>";
	}
	html += "</tr></table>";

	return html;
};

PokerAiUi.getPotArrayHtml = function(potCount){
	
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

PokerAiUi.initSeat = function(seatNumber){
	
	PokerAiUi["playerIdLabel_" + seatNumber] = Ext.create("Ext.form.field.Display", {
		labelWidth: 100,
		fieldLabel: "Player ID"
	});
	
	PokerAiUi["playerMoneyLabel_" + seatNumber] = Ext.create("Ext.form.field.Display", {
		labelWidth: 100,
		fieldLabel: "Player Money"
	});

	PokerAiUi["playerStateLabel_" + seatNumber] = Ext.create("Ext.form.field.Display", {
		labelWidth: 100,
		fieldLabel: "State",
		value: "No Player"
	});

	PokerAiUi["playerHandShowingLabel_" + seatNumber] = Ext.create("Ext.form.field.Display", {
		labelWidth: 100,
		fieldLabel: "Hand Showing",
		colspan: "2"
	});

	PokerAiUi["playerTournamentRank_" + seatNumber] = Ext.create("Ext.form.field.Display", {
		labelWidth: 150,
		fieldLabel: "Tournament Rank"
	});

	PokerAiUi["playerGameRank_" + seatNumber] = Ext.create("Ext.form.field.Display", {
		labelWidth: 150,
		fieldLabel: "Game Rank"
	});
	
	PokerAiUi["playerTotalPotContribution_" + seatNumber] = Ext.create("Ext.form.field.Display", {
		labelWidth: 150,
		fieldLabel: "Total Pot Contribution"
	});

	PokerAiUi["playerHoleCards_" + seatNumber] = Ext.create("Ext.form.field.Display", {
		fieldLabel: "Hole Cards",
		labelWidth: 100,
		afterSubTpl: PokerAiUi.getCardArrayHtml("seat_" + seatNumber + "_hole_card", 2, true)
	});
	
	PokerAiUi["playerButtonFold_" + seatNumber] = Ext.create("Ext.Button", {
        text: "Fold",
		margin: "5 20 5 10",
        width: 50,
		disabled: true,
        handler: function() {PokerAiUi.playerFold(seatNumber);}
    });

	PokerAiUi["playerButtonCheck_" + seatNumber] = Ext.create("Ext.Button", {
        text: "Check",
		margin: "5 0 0 0",
        width: 50,
		disabled: true,
        handler: function() {PokerAiUi.playerCheck(seatNumber);}
    });
	
	PokerAiUi["playerButtonCall_" + seatNumber] = Ext.create("Ext.Button", {
        text: "Call",
		margin: "0 0 5 10",
		colspan: "2",
		disabled: true,
        width: 50,
        handler: function() {PokerAiUi.playerCall(seatNumber);}
    });

	PokerAiUi["playerButtonBet_" + seatNumber] = Ext.create("Ext.Button", {
        text: "Bet",
		margin: "0 0 0 10",
		disabled: true,
        width: 50,
        handler: function() {PokerAiUi.playerBet(seatNumber);}
    });
	
	PokerAiUi["playerBetAmount_" + seatNumber] = Ext.create("Ext.form.field.Number", {
		allowBlank: false,
		repeatTriggerClick: false,
		width: 100,
		minValue: 1,
		maxValue: 5000,
		value: 10,
		disabled: true,
		step: 1,
		decimalPrecision: 0,
		listeners: {validityChange: function(field, isValid) { PokerAiUi.betValueValidityChange(seatNumber, isValid); }}
	});

	var playerControlsContainer = Ext.create("Ext.container.Container", {
		layout: { type: "table", columns: 2, tdAttrs: { style: { verticalAlign: "top", width: "50px" } } },
		items: [
			PokerAiUi["playerButtonFold_" + seatNumber],
			PokerAiUi["playerButtonCheck_" + seatNumber],
			PokerAiUi["playerButtonCall_" + seatNumber],
			PokerAiUi["playerButtonBet_" + seatNumber],
			PokerAiUi["playerBetAmount_" + seatNumber]
		]
	});
	
	PokerAiUi["playerBestHandCards_" + seatNumber] = Ext.create("Ext.form.field.Display", {
		fieldLabel: "Best Hand",
		labelWidth: 100,
		colspan: "2",
		afterSubTpl: PokerAiUi.getCardArrayHtml("seat_" + seatNumber + "_best_hand", 5, false)
	});
	
	PokerAiUi["playerBestHandRank_" + seatNumber] = Ext.create("Ext.form.field.Display", {
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
			PokerAiUi["playerIdLabel_" + seatNumber],
			PokerAiUi["playerTournamentRank_" + seatNumber],
			
			PokerAiUi["playerMoneyLabel_" + seatNumber],
			PokerAiUi["playerGameRank_" + seatNumber],
			
			PokerAiUi["playerStateLabel_" + seatNumber],
			
			PokerAiUi["playerTotalPotContribution_" + seatNumber],
			PokerAiUi["playerHandShowingLabel_" + seatNumber],
			
			PokerAiUi["playerHoleCards_" + seatNumber],
			playerControlsContainer,
			
			PokerAiUi["playerBestHandCards_" + seatNumber],
			PokerAiUi["playerBestHandRank_" + seatNumber]
		]
    });
	
    PokerAiUi["seatPanel_" + seatNumber] = Ext.create("Sms.form.Panel", {
		border: false,
		bodyStyle: {"background-color": "gray"},
		items: fieldSet
    });
	
	return PokerAiUi["seatPanel_" + seatNumber];
};

PokerAiUi.initCenter = function(){

	PokerAiUi.bettingRoundInProgressLabel = Ext.create("Ext.form.field.Display", {
		labelWidth: 120,
		fieldLabel: "Round In Progress"
	});

	PokerAiUi.bettingRoundLabel = Ext.create("Ext.form.field.Display", {
		fieldLabel: "Betting Round"
	});

	PokerAiUi.turnLabel = Ext.create("Ext.form.field.Display", {
		labelWidth: 120,
		fieldLabel: "Seat Turn"
	});
	
	PokerAiUi.lastToRaiseLabel = Ext.create("Ext.form.field.Display", {
		fieldLabel: "Last to Raise Seat"
	});
	
	PokerAiUi.smallBlindSeatLabel = Ext.create("Ext.form.field.Display", {
		labelWidth: 120,
		fieldLabel: "Small Blind Seat"
	});
	
	PokerAiUi.bigBlindSeatLabel = Ext.create("Ext.form.field.Display", {
		fieldLabel: "Big Blind Seat"
	});
	
	PokerAiUi.communityCardsLabel = Ext.create("Ext.form.field.Display", {
		labelWidth: 100,
		fieldLabel: "Community Cards",
		colspan: 2,
		afterSubTpl: PokerAiUi.getCardArrayHtml("community_card", 5, false)
	});
	
	PokerAiUi.pots = Ext.create("Ext.form.field.Display", {
		labelWidth: 100,
		fieldLabel: "Pots",
		colspan: 2,
		afterSubTpl: PokerAiUi.getPotArrayHtml(PokerAiUi.maxPotCount)
	});

	PokerAiUi.smallBlindAmountField = Ext.create("Ext.form.field.Number", {
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

	PokerAiUi.bigBlindAmountField = Ext.create("Ext.form.field.Number", {
		fieldLabel: "Big Blind Amt.",
		allowBlank: false,
		repeatTriggerClick: false,
		labelWidth: 120,
		width: 175,
		minValue: 1,
		maxValue: 5000,
		value: 10,
		step: 1,
		decimalPrecision: 0
	});

	var gameStateFieldSet = Ext.create("Ext.form.FieldSet", {
		title: "Game State",
		layout: { type: "table", columns: 2, tdAttrs: { style: { verticalAlign: "top" } } },
		width: 468,
		height: 325,
		padding: "0 0 0 0",
		style: {borderColor: "black"},
		items: [
			PokerAiUi.bettingRoundInProgressLabel,
			PokerAiUi.bettingRoundLabel,
			PokerAiUi.turnLabel,
			PokerAiUi.lastToRaiseLabel,
			PokerAiUi.smallBlindSeatLabel,
			PokerAiUi.bigBlindSeatLabel,
			PokerAiUi.smallBlindAmountField,
			PokerAiUi.bigBlindAmountField,
			PokerAiUi.communityCardsLabel,
			PokerAiUi.pots
		]
    });

	var centerPanel = Ext.create("Sms.form.Panel", {
        border: false,
		layout: { type: "table", columns: 1, tdAttrs: { style: { verticalAlign: "top" } } },
		bodyStyle: {"background-color": "37F0A3"},
		items: [gameStateFieldSet]
	});
	
	return centerPanel;
};

PokerAiUi.initControlsPanel = function(){
	
	PokerAiUi.playerCountField = Ext.create("Ext.form.field.Number", {
		fieldLabel: "Player Count",
		allowBlank: false,
		repeatTriggerClick: false,
		labelWidth: 150,
		width: 225,
		minValue: 2,
		maxValue: PokerAiUi.maxPlayerCount,
		value: 4,
		step: 1,
		decimalPrecision: 0
	});
	
	PokerAiUi.buyInAmountField = Ext.create("Ext.form.field.Number", {
		fieldLabel: "Buy In Amount",
		allowBlank: false,
		repeatTriggerClick: false,
		labelWidth: 150,
		width: 225,
		minValue: 1,
		maxValue: 5000,
		value: 500,
		step: 1,
		decimalPrecision: 0
	});
	
	PokerAiUi.currentGameNumberLabel = Ext.create("Ext.form.field.Display", {
		labelWidth: 150,
		fieldLabel: "Current Game Number"
	});
	
	PokerAiUi.gameInProgressLabel = Ext.create("Ext.form.field.Display", {
		labelWidth: 150,
		fieldLabel: "Game In Progress"
	});

	var reloadButton = Ext.create("Ext.Button", {
        text: "Reload Page",
        width: 90,
        handler: function () {
            document.location.reload();
        }
    });

	var initTournamentButton = Ext.create("Ext.Button", {
        text: "Init Tournament",
        width: 150,
        handler: PokerAiUi.initTournament
    });
	
	PokerAiUi.stepPlayButton = Ext.create("Ext.Button", {
        text: "Step Play",
        width: 150,
        handler: function() {PokerAiUi.stepPlay(0, 0);}
    });
	
	var tournamentFieldSet = Ext.create("Ext.form.FieldSet", {
		title: "Tournament",
		layout: { type: "table", columns: 1, tdAttrs: { style: { verticalAlign: "top" } } },
		width: 468,
		style: {borderColor: "black"},
		items: [
			PokerAiUi.playerCountField,
			PokerAiUi.buyInAmountField,
			PokerAiUi.currentGameNumberLabel,
			PokerAiUi.gameInProgressLabel,
			reloadButton,
			initTournamentButton,
			PokerAiUi.stepPlayButton
		]
    });
	
	PokerAiUi.statusTextArea = Ext.create("Ext.form.field.TextArea", {
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
			PokerAiUi.statusTextArea
		]
    });

	var controlsPanel = Ext.create("Sms.form.Panel", {
        layout: { type: "table", columns: 1, tdAttrs: { style: { verticalAlign: "top" } } },
		border: false,
		bodyStyle: {"background-color": "37F0A3"},
		items: [tournamentFieldSet, statusFieldSet]
    });

	return controlsPanel;
};

PokerAiUi.init = function()
{
    PokerAiUi.tableLayoutContainer = Ext.create("Ext.panel.Panel", {
		layout: { type: "table", columns: 4, tdAttrs: { style: { verticalAlign: "top", padding: "0 10 0 0"} } },
		region: "center",
		bodyStyle: {"background-color": "lightgreen"},
		items: [
			PokerAiUi.initSeat(1),
			PokerAiUi.initSeat(2),
			PokerAiUi.initSeat(3),
			PokerAiUi.initSeat(4),
			PokerAiUi.initSeat(10),
			PokerAiUi.initControlsPanel(),
			PokerAiUi.initCenter(),
			PokerAiUi.initSeat(5),
			PokerAiUi.initSeat(9),
			PokerAiUi.initSeat(8),
			PokerAiUi.initSeat(7),
			PokerAiUi.initSeat(6)
		]
    });

	PokerAiUi.viewport = Ext.create("Ext.container.Viewport", {
		layout: "border",
		items: [PokerAiUi.tableLayoutContainer]
	});

};

Ext.onReady(function(){
	PokerAiUi.init();
});

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

PokerAiUi.getCardImage = function(cardId){
	if(cardId == null)
		return "images/cards/blank.png";
	
	return img = "images/cards/" + (cardId == 0 ? "back.jpg" : cardId + ".png");
};

PokerAiUi.initTournament = function(){
	PokerAi.initTournament(
		PokerAiUi.playerCountField.getValue(),
		PokerAiUi.buyInAmountField.getValue(),
		PokerAiUi.smallBlindAmountField.getValue(),
		PokerAiUi.bigBlindAmountField.getValue()
	);
};

PokerAiUi.refreshUi = function(uiData){
	
	// tournament state
	PokerAiUi.playerCountField.setValue(uiData.tournamentState.player_count);
	PokerAiUi.buyInAmountField.setValue(uiData.tournamentState.buy_in_amount);
	PokerAiUi.currentGameNumberLabel.setValue(uiData.tournamentState.current_game_number);
	PokerAiUi.gameInProgressLabel.setValue(uiData.tournamentState.game_in_progress);
	
	// game state
	PokerAiUi.smallBlindSeatLabel.setValue(uiData.gameState.small_blind_seat_number);
	PokerAiUi.bigBlindSeatLabel.setValue(uiData.gameState.big_blind_seat_number);
	PokerAiUi.turnLabel.setValue(uiData.gameState.turn_seat_number);
	if(uiData.gameState.small_blind_value != null)
		PokerAiUi.smallBlindAmountField.setValue(uiData.gameState.small_blind_value);
	if(uiData.gameState.big_blind_value != null)
		PokerAiUi.bigBlindAmountField.setValue(uiData.gameState.big_blind_value);
	PokerAiUi.bettingRoundLabel.setValue(uiData.gameState.betting_round_number);
	PokerAiUi.bettingRoundInProgressLabel.setValue(uiData.gameState.betting_round_in_progress);
	PokerAiUi.lastToRaiseLabel.setValue(uiData.gameState.last_to_raise_seat_number);
	for(var i = 1; i <= 5; i++){
		document.getElementById("community_card_" + i).src = PokerAiUi.getCardImage(uiData.gameState["community_card_" + i]);
	}
	
	// players state
	for(var i = 0; i < uiData.playerState.length; i++){
		
		var playerData = uiData.playerState[i];
		var seatNumber = playerData.seat_number;
		
		PokerAiUi["playerButtonFold_" + seatNumber].setDisabled(true);
		PokerAiUi["playerButtonCheck_" + seatNumber].setDisabled(true);
		PokerAiUi["playerButtonCall_" + seatNumber].setDisabled(true);
		PokerAiUi["playerButtonBet_" + seatNumber].setDisabled(true);
		PokerAiUi["playerBetAmount_" + seatNumber].setDisabled(true);
		PokerAiUi["playerButtonBet_" + seatNumber].setText("Bet");
			
		PokerAiUi["playerIdLabel_" + seatNumber].setValue(playerData.player_id);
		document.getElementById("seat_" + seatNumber + "_hole_card_1").src = PokerAiUi.getCardImage(playerData.hole_card_1);
		document.getElementById("seat_" + seatNumber + "_hole_card_2").src = PokerAiUi.getCardImage(playerData.hole_card_2);
		
		PokerAiUi["playerBestHandRank_" + seatNumber].setValue(playerData.best_hand_rank);
		
		for(var c = 1; c <= 5; c++){
			var cardSlot = document.getElementById("seat_" + seatNumber + "_best_hand_" + c);
			cardSlot.src = PokerAiUi.getCardImage(playerData["best_hand_card_" + c]);
			cardSlot.style.border = playerData["best_hand_card_" + c + "_is_hole_card"] == "Y" ? PokerAiUi.holeCardBorderStyle : PokerAiUi.nonHoleCardBorderStyle;
		}
		
		PokerAiUi["playerHandShowingLabel_" + seatNumber].setValue(playerData.hand_showing);
		PokerAiUi["playerMoneyLabel_" + seatNumber].setValue(playerData.money);
		PokerAiUi["playerStateLabel_" + seatNumber].setValue(playerData.state);
		PokerAiUi["playerGameRank_" + seatNumber].setValue(playerData.game_rank);
		PokerAiUi["playerTournamentRank_" + seatNumber].setValue(playerData.tournament_rank);
		PokerAiUi["playerTotalPotContribution_" + seatNumber].setValue(playerData.total_pot_contribution);

		// player seat backround color
		var playerColor = "lightgreen";
		if(playerData.state == "No Player" || playerData.tournament_rank != null)
			playerColor = "gray";
		else if (playerData.state == "Folded")
			playerColor = "CFD1D0";
		else if(seatNumber == uiData.gameState.turn_seat_number)
			playerColor = "DDF037";
		PokerAiUi["seatPanel_" + seatNumber].setBodyStyle("background-color", playerColor);

		// player control buttons
		if(playerData.can_fold == "Y")
			PokerAiUi["playerButtonFold_" + seatNumber].setDisabled(false);
		if(playerData.can_check == "Y")
			PokerAiUi["playerButtonCheck_" + seatNumber].setDisabled(false);
		if(playerData.can_call == "Y")
			PokerAiUi["playerButtonCall_" + seatNumber].setDisabled(false);
		if(playerData.can_bet == "Y"){
			PokerAiUi["playerButtonBet_" + seatNumber].setDisabled(false);
			PokerAiUi["playerBetAmount_" + seatNumber].setDisabled(false);
			PokerAiUi["playerBetAmount_" + seatNumber].setValue(playerData.min_bet_amount);
			PokerAiUi["playerBetAmount_" + seatNumber].setMinValue(playerData.min_bet_amount);
			PokerAiUi["playerBetAmount_" + seatNumber].setMaxValue(playerData.max_bet_amount);
		}
		if(playerData.can_raise == "Y"){
			PokerAiUi["playerButtonBet_" + seatNumber].setText("Raise");
			PokerAiUi["playerButtonBet_" + seatNumber].setDisabled(false);
			PokerAiUi["playerBetAmount_" + seatNumber].setDisabled(false);
			PokerAiUi["playerBetAmount_" + seatNumber].setValue(playerData.min_raise_amount);
			PokerAiUi["playerBetAmount_" + seatNumber].setMinValue(playerData.min_raise_amount);
			PokerAiUi["playerBetAmount_" + seatNumber].setMaxValue(playerData.max_raise_amount);
		}
		
	}
	
	// pots state
	for(var i = 1; i <= PokerAiUi.maxPotCount; i++){
		document.getElementById("pot_value_" + i).innerHTML = "";
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
	for(var i = 0; i < uiData.statusMessage.length; i++){
		var message = uiData.statusMessage[i].message + "\n";
		PokerAiUi.statusTextArea.setValue(PokerAiUi.statusTextArea.getValue() + message);
	}
	PokerAiUi.statusTextArea.getEl().down("textarea").dom.scrollTop = 99999;
	
	var sbSeatNum = uiData.gameState.small_blind_seat_number;
	var bbSeatNum = uiData.gameState.big_blind_seat_number;
	if(sbSeatNum != null)
		PokerAiUi["playerIdLabel_" + sbSeatNum].setValue(PokerAiUi["playerIdLabel_" + sbSeatNum].getValue() + " - Small Blind");
	if(bbSeatNum != null)
		PokerAiUi["playerIdLabel_" + bbSeatNum].setValue(PokerAiUi["playerIdLabel_" + bbSeatNum].getValue() + " - Big Blind");
	
	PokerAiUi.stepPlayButton.setDisabled(false);

};

PokerAiUi.stepPlay = function(playerMove, playerMoveAmount){
	PokerAiUi.stepPlayButton.setDisabled(true);
	PokerAi.stepPlay(
		PokerAiUi.smallBlindAmountField.getValue(),
		PokerAiUi.bigBlindAmountField.getValue(),
		playerMove,
		playerMoveAmount
	);
};

PokerAiUi.playerFold = function(seatNumber){
	PokerAiUi.stepPlay(1, 0);
};

PokerAiUi.playerCheck = function(seatNumber){
	PokerAiUi.stepPlay(2, 0);
};

PokerAiUi.playerBet = function(seatNumber){
	if(PokerAiUi["playerButtonBet_" + seatNumber].getText() == "Bet")
		PokerAiUi.stepPlay(4, PokerAiUi["playerBetAmount_" + seatNumber].getValue()); // bet
	else
		PokerAiUi.stepPlay(5, PokerAiUi["playerBetAmount_" + seatNumber].getValue()); // raise
};

PokerAiUi.playerCall = function(seatNumber){
	PokerAiUi.stepPlay(3, 0);
};

PokerAiUi.betValueValidityChange = function(seatNumber, isValid){
	PokerAiUi["playerButtonBet_" + seatNumber].setDisabled(!isValid);
};
