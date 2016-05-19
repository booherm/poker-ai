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
		var slotId = id + "_" + i;
		html += "<td style='padding: 0 2 0 2;' onclick='PokerAiUi.cardSlotClicked(\"" + slotId + "\");'>"
			+ "<img id='" + slotId + "' style='width: 60px; height: 87px; border: " + borderStyle + ";'/></td>";
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

PokerAiUi.initCardSelectionWindow = function(){
	
	var cardArrayHtml = "<table style='margin: 15px 15px 15px 15px;'>";
	for(var suit = 0; suit < 4; suit++){
		cardArrayHtml += "<tr>";
		for(var card = 1; card <= 13; card++){
			var cardId = (13 * suit) + card;
			cardArrayHtml += "<td style='padding: 10px 3px 10px 3px'>"
				+ "<img src = '" + PokerAiUi.getCardImage(cardId) + "' "
				+ "style = 'width: 60px; height: 87px; border: 1px solid black;' "
				+ "onclick = 'PokerAiUi.cardSelected(" + cardId + ");' "
				+ "/></td>";
		}
		cardArrayHtml += "</tr>";
	}
	cardArrayHtml += "</table>";
	
	PokerAiUi.cardSelectionWindow = Ext.create("Ext.window.Window", {
		title: "Select Card",
		width: 900,
		height: 490,
		html: cardArrayHtml
	});
};

PokerAiUi.initTournamentPanel = function(){
	
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
	
	PokerAiUi.stateSelectionField = Ext.create("Ext.form.field.Number", {
		fieldLabel: "State",
		allowBlank: true,
		hideTrigger: true,
		labelWidth: 50,
		width: 115,
		minValue: 0,
		decimalPrecision: 0,
		listeners: {change: PokerAiUi.stateSelectionFieldChanged}
	});
	
	PokerAiUi.stateLoadButton = Ext.create("Ext.Button", {
        text: "Load",
		margin: "0 0 0 5",
        width: 40,
		handler: PokerAiUi.loadState,
		disabled: true
    });
	
	PokerAiUi.statePreviousButton = Ext.create("Ext.Button", {
        text: "<",
		margin: "0 0 0 10",
        width: 20,
		handler: PokerAiUi.loadPreviousState,
		disabled: true
    });

	PokerAiUi.stateNextButton = Ext.create("Ext.Button", {
        text: ">",
		margin: "0 0 0 5",
        width: 20,
		handler: PokerAiUi.loadNextState,
		disabled: true
    });
	
	var stateControlContainer = Ext.create("Ext.container.Container", {
		layout: { type: "table", columns: 4, tdAttrs: { style: { verticalAlign: "top"} } },
		items: [
			PokerAiUi.stateSelectionField,
			PokerAiUi.stateLoadButton,
			PokerAiUi.statePreviousButton,
			PokerAiUi.stateNextButton
		]
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
		decimalPrecision: 0,
		colspan: 2
	});
	
	PokerAiUi.currentGameNumberLabel = Ext.create("Ext.form.field.Display", {
		labelWidth: 150,
		fieldLabel: "Current Game Number",
		colspan: 2
	});
	
	PokerAiUi.gameInProgressLabel = Ext.create("Ext.form.field.Display", {
		labelWidth: 150,
		fieldLabel: "Game In Progress",
		colspan: 2
	});

	var reloadButton = Ext.create("Ext.Button", {
        text: "Reload Page",
        width: 90,
		colspan: 2,
        handler: function () {
            document.location.reload();
        }
    });

	var initTournamentButton = Ext.create("Ext.Button", {
        text: "Init Tournament",
        width: 150,
		colspan: 2,
        handler: PokerAiUi.initTournament
    });
	
	PokerAiUi.stepPlayButton = Ext.create("Ext.Button", {
        text: "Step Play",
        width: 150,
		colspan: 2,
        handler: function() {PokerAiUi.stepPlay("AUTO", null);}
    });
	
	var tournamentFieldSet = Ext.create("Ext.form.FieldSet", {
		title: "Tournament",
		layout: { type: "table", columns: 2, tdAttrs: { style: { verticalAlign: "top" } } },
		width: 468,
		style: {borderColor: "black"},
		items: [
			PokerAiUi.playerCountField,
			stateControlContainer,
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

	var tournamentPanel = Ext.create("Sms.form.Panel", {
        layout: { type: "table", columns: 1, tdAttrs: { style: { verticalAlign: "top" } } },
		border: false,
		bodyStyle: {"background-color": "37F0A3"},
		items: [tournamentFieldSet, statusFieldSet]
    });

	return tournamentPanel;
};

PokerAiUi.initGamePanel = function(){

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

	PokerAiUi.bigBlindAmountField = Ext.create("Ext.form.field.Display", {
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

	var gamePanel = Ext.create("Sms.form.Panel", {
        border: false,
		layout: { type: "table", columns: 1, tdAttrs: { style: { verticalAlign: "top" } } },
		bodyStyle: {"background-color": "37F0A3"},
		items: [gameStateFieldSet]
	});
	
	return gamePanel;
};

PokerAiUi.initSeatPanel = function(seatNumber){
	
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

PokerAiUi.init = function()
{
	PokerAiUi.initCardSelectionWindow();
	
    PokerAiUi.tableLayoutContainer = Ext.create("Ext.panel.Panel", {
		layout: { type: "table", columns: 4, tdAttrs: { style: { verticalAlign: "top", padding: "0 10 0 0"} } },
		region: "center",
		bodyStyle: {"background-color": "lightgreen"},
		items: [
			PokerAiUi.initSeatPanel(1),
			PokerAiUi.initSeatPanel(2),
			PokerAiUi.initSeatPanel(3),
			PokerAiUi.initSeatPanel(4),
			PokerAiUi.initSeatPanel(10),
			PokerAiUi.initTournamentPanel(),
			PokerAiUi.initGamePanel(),
			PokerAiUi.initSeatPanel(5),
			PokerAiUi.initSeatPanel(9),
			PokerAiUi.initSeatPanel(8),
			PokerAiUi.initSeatPanel(7),
			PokerAiUi.initSeatPanel(6)
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
		PokerAiUi.smallBlindAmountField.getValue()
	);
};

PokerAiUi.refreshUi = function(uiData){

	// tournament state
	PokerAiUi.playerCountField.setValue(uiData.tournamentState.player_count);
	PokerAiUi.buyInAmountField.setValue(uiData.tournamentState.buy_in_amount);
	PokerAiUi.currentGameNumberLabel.setValue(uiData.tournamentState.current_game_number);
	PokerAiUi.gameInProgressLabel.setValue(uiData.tournamentState.game_in_progress);
	PokerAiUi.stateSelectionField.setValue(uiData.tournamentState.current_state_id);
	
	// game state
	PokerAiUi.smallBlindSeatLabel.setValue(uiData.gameState.small_blind_seat_number);
	PokerAiUi.bigBlindSeatLabel.setValue(uiData.gameState.big_blind_seat_number);
	PokerAiUi.turnLabel.setValue(uiData.gameState.turn_seat_number);
	if(uiData.gameState.small_blind_value != null)
		PokerAiUi.smallBlindAmountField.setValue(uiData.gameState.small_blind_value);
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
		
		// reset controls to disabled state
		PokerAiUi["playerButtonFold_" + seatNumber].setDisabled(true);
		PokerAiUi["playerButtonCheck_" + seatNumber].setDisabled(true);
		PokerAiUi["playerButtonCall_" + seatNumber].setDisabled(true);
		PokerAiUi["playerButtonBet_" + seatNumber].setDisabled(true);
		PokerAiUi["playerBetAmount_" + seatNumber].setDisabled(true);
		PokerAiUi["playerButtonBet_" + seatNumber].setText("Bet");
			
		// set hole cards
		PokerAiUi["playerIdLabel_" + seatNumber].setValue(playerData.player_id);
		document.getElementById("seat_" + seatNumber + "_hole_card_1").src = PokerAiUi.getCardImage(playerData.hole_card_1);
		document.getElementById("seat_" + seatNumber + "_hole_card_2").src = PokerAiUi.getCardImage(playerData.hole_card_2);
		
		// set best hand rank
		PokerAiUi["playerBestHandRank_" + seatNumber].setValue(playerData.best_hand_rank);
		
		// set best hand cards
		for(var c = 1; c <= 5; c++){
			var cardSlot = document.getElementById("seat_" + seatNumber + "_best_hand_" + c);
			cardSlot.src = PokerAiUi.getCardImage(playerData["best_hand_card_" + c]);
			cardSlot.style.border = playerData["best_hand_card_" + c + "_is_hole_card"] == "Y" ? PokerAiUi.holeCardBorderStyle : PokerAiUi.nonHoleCardBorderStyle;
		}
		
		// other generic attributes
		PokerAiUi["playerHandShowingLabel_" + seatNumber].setValue(playerData.hand_showing);
		PokerAiUi["playerMoneyLabel_" + seatNumber].setValue(playerData.money);
		PokerAiUi["playerStateLabel_" + seatNumber].setValue(playerData.state);
		PokerAiUi["playerGameRank_" + seatNumber].setValue(playerData.game_rank);
		PokerAiUi["playerTournamentRank_" + seatNumber].setValue(playerData.tournament_rank);
		PokerAiUi["playerTotalPotContribution_" + seatNumber].setValue(playerData.total_pot_contribution);

		// player seat backround color
		var playerColor = "lightgreen";
		if(playerData.state == "No Player" || playerData.state == "Out of Tournament")
			playerColor = "gray";
		else if (playerData.state == "Folded")
			playerColor = "CFD1D0";
		else if(seatNumber == uiData.gameState.turn_seat_number && uiData.gameState.betting_round_in_progress == "Yes")
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
			PokerAiUi["playerBetAmount_" + seatNumber].clearInvalid();
		}
		if(playerData.can_raise == "Y"){
			PokerAiUi["playerButtonBet_" + seatNumber].setText("Raise");
			PokerAiUi["playerButtonBet_" + seatNumber].setDisabled(false);
			PokerAiUi["playerBetAmount_" + seatNumber].setDisabled(false);
			PokerAiUi["playerBetAmount_" + seatNumber].setValue(playerData.min_raise_amount);
			PokerAiUi["playerBetAmount_" + seatNumber].setMinValue(playerData.min_raise_amount);
			PokerAiUi["playerBetAmount_" + seatNumber].setMaxValue(playerData.max_raise_amount);
			PokerAiUi["playerBetAmount_" + seatNumber].clearInvalid();
		}
		
	}
	
	// pots state
	for(var i = 1; i <= PokerAiUi.maxPotCount; i++){
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
		message += uiData.statusMessage[i].message + "\n";
	}
	PokerAiUi.statusTextArea.setValue(message);
	PokerAiUi.statusTextArea.getEl().down("textarea").dom.scrollTop = 99999;
	
	// blinds indicators
	var sbSeatNum = uiData.gameState.small_blind_seat_number;
	var bbSeatNum = uiData.gameState.big_blind_seat_number;
	if(sbSeatNum != null)
		PokerAiUi["playerIdLabel_" + sbSeatNum].setValue(PokerAiUi["playerIdLabel_" + sbSeatNum].getValue() + " - Small Blind");
	if(bbSeatNum != null)
		PokerAiUi["playerIdLabel_" + bbSeatNum].setValue(PokerAiUi["playerIdLabel_" + bbSeatNum].getValue() + " - Big Blind");
	
	// all state setup, re-enable step play button
	PokerAiUi.stepPlayButton.setDisabled(false);

};

PokerAiUi.stepPlay = function(playerMove, playerMoveAmount){
	PokerAiUi.stepPlayButton.setDisabled(true);
	PokerAi.stepPlay(
		PokerAiUi.smallBlindAmountField.getValue(),
		playerMove,
		playerMoveAmount
	);
};

PokerAiUi.playerFold = function(seatNumber){
	PokerAiUi.stepPlay("FOLD", null);
};

PokerAiUi.playerCheck = function(seatNumber){
	PokerAiUi.stepPlay("CHECK", null);
};

PokerAiUi.playerBet = function(seatNumber){
	if(PokerAiUi["playerButtonBet_" + seatNumber].getText() == "Bet")
		PokerAiUi.stepPlay("BET", PokerAiUi["playerBetAmount_" + seatNumber].getValue());
	else
		PokerAiUi.stepPlay("RAISE", PokerAiUi["playerBetAmount_" + seatNumber].getValue());
};

PokerAiUi.playerCall = function(seatNumber){
	PokerAiUi.stepPlay("CALL", null);
};

PokerAiUi.betValueValidityChange = function(seatNumber, isValid){
	PokerAiUi["playerButtonBet_" + seatNumber].setDisabled(!isValid);
};

PokerAiUi.cardSlotClicked = function(id){
	PokerAiUi.editingCardSlotId = id;
	PokerAiUi.cardSelectionWindow.show();
};

PokerAiUi.cardSelected = function(cardId){
	console.log("card selected for slot " + PokerAiUi.editingCardSlotId + " = " + cardId);
	PokerAiUi.cardSelectionWindow.hide();
};

PokerAiUi.loadState = function(){
	PokerAi.loadState(PokerAiUi.stateSelectionField.getValue());
};

PokerAiUi.loadPreviousState = function(){
	PokerAi.loadPreviousState(PokerAiUi.stateSelectionField.getValue());
};

PokerAiUi.loadNextState = function(){
	PokerAi.loadNextState(PokerAiUi.stateSelectionField.getValue());
};

PokerAiUi.stateSelectionFieldChanged = function(field, newValue){
	var disabled = newValue === "";
	PokerAiUi.stateLoadButton.setDisabled(disabled);
	PokerAiUi.statePreviousButton.setDisabled(disabled);
	PokerAiUi.stateNextButton.setDisabled(disabled);
};