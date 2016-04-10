Ext.ns("PokerAiUi");

PokerAiUi.maxPlayerCount = 8;
PokerAiUi.smallBlindSeatNumber = 1;
PokerAiUi.bigBlindSeatNumber = 2;
	
PokerAiUi.getCardArrayHtml = function(id, cardCount){
	
	var html = "<table><tr>";
	for(var i = 1; i <= cardCount; i++){
		html += "<td style='padding: 0 2 0 2;'><img id='" + id + "_" + i + "' style='width: 60px; height: 87px; border: 1px solid black;'/></td>";
	}
	html += "</tr></table>";

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
		fieldLabel: "State"
	});

	PokerAiUi["playerHandShowingLabel_" + seatNumber] = Ext.create("Ext.form.field.Display", {
		labelWidth: 100,
		fieldLabel: "Hand Showing"
	});

	PokerAiUi["playerTournamentRank_" + seatNumber] = Ext.create("Ext.form.field.Display", {
		labelWidth: 150,
		fieldLabel: "Tournament Rank"
	});

	PokerAiUi["playerGameRank_" + seatNumber] = Ext.create("Ext.form.field.Display", {
		labelWidth: 150,
		fieldLabel: "Game Rank"
	});
	
	PokerAiUi["playerBestHandRank_" + seatNumber] = Ext.create("Ext.form.field.Display", {
		labelWidth: 150,
		fieldLabel: "Best Hand Rank"
	});

	PokerAiUi["playerTotalPotContribution_" + seatNumber] = Ext.create("Ext.form.field.Display", {
		labelWidth: 150,
		fieldLabel: "Total Pot Contribution"
	});

	PokerAiUi["playerHoleCards_" + seatNumber] = Ext.create("Ext.form.field.Display", {
		fieldLabel: "Hole Cards",
		labelWidth: 100,
		colspan: "2",
		afterSubTpl: PokerAiUi.getCardArrayHtml("seat_" + seatNumber + "_hole_card", 2)
	});
	
	PokerAiUi["playerBestHandCards_" + seatNumber] = Ext.create("Ext.form.field.Display", {
		fieldLabel: "Best Hand",
		labelWidth: 100,
		colspan: "2",
		afterSubTpl: PokerAiUi.getCardArrayHtml("seat_" + seatNumber + "_best_hand", 5)
	});
	
	var fieldSet = Ext.create("Ext.form.FieldSet", {
		layout: { type: "table", columns: 2, tdAttrs: { style: { verticalAlign: "top" } } },
		width: 500,
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
			PokerAiUi["playerBestHandRank_" + seatNumber],
			PokerAiUi["playerHandShowingLabel_" + seatNumber],
			PokerAiUi["playerTotalPotContribution_" + seatNumber],
			PokerAiUi["playerHoleCards_" + seatNumber],
			PokerAiUi["playerBestHandCards_" + seatNumber]
		]
    });
	
    var seatPanel = Ext.create("Sms.form.Panel", {
		border: false,
		bodyStyle: {"background-color": "lightgreen"},
		items: fieldSet
    });
	
	return seatPanel;
};

PokerAiUi.initCenter = function(){

	PokerAiUi.gameNumberLabel = Ext.create("Ext.form.field.Display", {
		fieldLabel: "Game Number"
	});

	PokerAiUi.bettingRoundLabel = Ext.create("Ext.form.field.Display", {
		fieldLabel: "Betting Round"
	});

	PokerAiUi.turnLabel = Ext.create("Ext.form.field.Display", {
		fieldLabel: "Seat Turn"
	});
	
	PokerAiUi.lastToRaiseLabel = Ext.create("Ext.form.field.Display", {
		fieldLabel: "Last to Raise Seat"
	});
	
	PokerAiUi.smallBlindSeatLabel = Ext.create("Ext.form.field.Display", {
		fieldLabel: "Small Blind Seat"
	});
	
	PokerAiUi.bigBlindSeatLabel = Ext.create("Ext.form.field.Display", {
		fieldLabel: "Big Blind Seat"
	});
	
	PokerAiUi.communityCardsLabel = Ext.create("Ext.form.field.Display", {
		fieldLabel: "Community Cards",
		colspan: 2,
		afterSubTpl: PokerAiUi.getCardArrayHtml("community_card", 5)
	});

	var gameStateFieldSet = Ext.create("Ext.form.FieldSet", {
		title: "Game State",
		layout: { type: "table", columns: 2, tdAttrs: { style: { verticalAlign: "top" } } },
		padding: "0 0 0 0",
		style: {borderColor: "black"},
		items: [
			PokerAiUi.gameNumberLabel,
			PokerAiUi.bettingRoundLabel,
			PokerAiUi.turnLabel,
			PokerAiUi.lastToRaiseLabel,
			PokerAiUi.smallBlindSeatLabel,
			PokerAiUi.bigBlindSeatLabel,
			PokerAiUi.communityCardsLabel
		]
    });

	var centerPanel = Ext.create("Sms.form.Panel", {
        border: false,
		layout: { type: "table", columns: 1, tdAttrs: { style: { verticalAlign: "top" } } },
		bodyStyle: {"background-color": "lightgreen"},
		width: 500,
		items: [
			gameStateFieldSet
		]
	});
	
	return centerPanel;
};

PokerAiUi.initControlsPanel = function(){
	
	var reloadButton = Ext.create("Ext.Button", {
        text: "Reload Page",
        width: 90,
        handler: function () {
            document.location.reload();
        }
    });

	PokerAiUi.playerCountField = Ext.create("Ext.form.field.Number", {
		fieldLabel: "Player Count",
		allowBlank: false,
		repeatTriggerClick: false,
		labelWidth: 100,
		minValue: 2,
		maxValue: 8,
		value: 8,
		step: 1,
		decimalPrecision: 0
	});
	
	PokerAiUi.buyInAmountField = Ext.create("Ext.form.field.Number", {
		fieldLabel: "Buy In Ammount",
		allowBlank: false,
		repeatTriggerClick: false,
		labelWidth: 100,
		minValue: 1,
		maxValue: 5000,
		value: 500,
		step: 1,
		decimalPrecision: 0
	});
	
	PokerAiUi.smallBlindAmountField = Ext.create("Ext.form.field.Number", {
		fieldLabel: "Small Blind Amt.",
		allowBlank: false,
		repeatTriggerClick: false,
		labelWidth: 100,
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
		labelWidth: 100,
		minValue: 1,
		maxValue: 5000,
		value: 10,
		step: 1,
		decimalPrecision: 0
	});
	
	PokerAiUi.gamesPlayedLabel = Ext.create("Ext.form.field.Display", {
		labelWidth: 100,
		fieldLabel: "Games Played"
	});
	
	var initTournamentButton = Ext.create("Ext.Button", {
        text: "Init Tournament",
        width: 150,
        handler: PokerAiUi.initTournament
    });
	
	var initGameButton = Ext.create("Ext.Button", {
        text: "Init Game",
        width: 150,
        handler: PokerAiUi.initGame
    });
	
	var tournamentFieldSet = Ext.create("Ext.form.FieldSet", {
		title: "Tournament",
		layout: { type: "table", columns: 1, tdAttrs: { style: { verticalAlign: "top" } } },
		margin: "0 0 0 10",
		style: {borderColor: "black"},
		items: [
			reloadButton,
			PokerAiUi.playerCountField,
			PokerAiUi.buyInAmountField,
			PokerAiUi.smallBlindAmountField,
			PokerAiUi.bigBlindAmountField,
			PokerAiUi.gamesPlayedLabel,
			initTournamentButton,
			initGameButton
		]
    });

	var roundFieldSet = Ext.create("Ext.form.FieldSet", {
		title: "Round",
		layout: { type: "table", columns: 1, tdAttrs: { style: { verticalAlign: "top" } } },
		style: {borderColor: "black"},
		margin: "0 0 0 10"
    });

	var controlsPanel = Ext.create("Sms.form.Panel", {
        layout: { type: "table", columns: 1, tdAttrs: { style: { verticalAlign: "top" } } },
		width: 300,
		region: "east",
		bodyStyle: {"background-color": "darkgreen"},
		items: [tournamentFieldSet, roundFieldSet]
    });

	return controlsPanel;
};

PokerAiUi.init = function()
{
    PokerAiUi.tableLayoutContainer = Ext.create("Ext.panel.Panel", {
		layout: { type: "table", columns: 3, tdAttrs: { style: { verticalAlign: "top", padding: "0 10 0 0"} } },
		region: "center",
		bodyStyle: {"background-color": "lightgreen"},
		items: [
			PokerAiUi.initSeat(1),
			PokerAiUi.initSeat(2),
			PokerAiUi.initSeat(3),
			PokerAiUi.initSeat(4),
			PokerAiUi.initCenter(),
			PokerAiUi.initSeat(5),
			PokerAiUi.initSeat(6),
			PokerAiUi.initSeat(7),
			PokerAiUi.initSeat(8)
		]
    });

	PokerAiUi.viewport = Ext.create("Ext.container.Viewport", {
		layout: "border",
		items: [
			PokerAiUi.tableLayoutContainer,
			PokerAiUi.initControlsPanel()
		]
	});

};

Ext.onReady(function(){
	PokerAiUi.init();
});

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

PokerAiUi.getCardImage = function(cardId){
	return img = "images/cards/" + (cardId == "" ? "back.jpg" : cardId + ".png");
};

PokerAiUi.clearSeat = function(seatNumber){
	
	PokerAiUi["playerIdLabel_" + seatNumber].setValue("");
	PokerAiUi["playerTournamentRank_" + seatNumber].setValue("");
	PokerAiUi["playerMoneyLabel_" + seatNumber].setValue("");
	PokerAiUi["playerGameRank_" + seatNumber].setValue("");
	PokerAiUi["playerStateLabel_" + seatNumber].setValue("");
	PokerAiUi["playerBestHandRank_" + seatNumber].setValue("");
	PokerAiUi["playerHandShowingLabel_" + seatNumber].setValue("");
	PokerAiUi["playerTotalPotContribution_" + seatNumber].setValue("");
	
	PokerAiUi["playerHoleCards_" + seatNumber],
	PokerAiUi["playerBestHandCards_" + seatNumber]

	for(var i = 1; i <= 2; i++)
		document.getElementById("seat_" + seatNumber + "_hole_card_" + i).src = "";
	
	for(var i = 1; i <= 5; i++)
		document.getElementById("seat_" + seatNumber + "_best_hand_1").src = "";
		
	
};

PokerAi.clearGame = function(){
	
	PokerAiUi.gameNumberLabel.setValue("");
	PokerAiUi.bettingRoundLabel.setValue("");
	PokerAiUi.turnLabel.setValue("");
	PokerAiUi.lastToRaiseLabel.setValue("");
	PokerAiUi.smallBlindSeatLabel.setValue("");
	PokerAiUi.bigBlindSeatLabel.setValue("");
	PokerAiUi.smallBlindAmountLabel.setValue("");
	PokerAiUi.bigBlindAmountLabel.setValue("");
	//PokerAiUi.communityCardsLabel.setValue("");

};

PokerAiUi.initTournament = function(){
	PokerAi.initTournament(PokerAiUi.playerCountField.getValue(), PokerAiUi.buyInAmountField.getValue());
};

PokerAiUi.initTournamentCallback = function(response){
	
	for(var i = 1; i <= PokerAiUi.maxPlayerCount; i++)
		PokerAiUi.clearSeat(i);
	
	var playerState = response.playerState;
	for(var i = 0; i < playerState.length; i++){
		var playerRec = playerState[i];
		var seatNumber = playerRec[1];
		
		PokerAiUi["playerIdLabel_" + seatNumber].setValue(playerRec[0]);
		PokerAiUi["playerTournamentRank_" + seatNumber].setValue(playerRec[15]);
		PokerAiUi["playerMoneyLabel_" + seatNumber].setValue(playerRec[12]);
		PokerAiUi["playerGameRank_" + seatNumber].setValue(playerRec[14]);
		PokerAiUi["playerStateLabel_" + seatNumber].setValue(playerRec[13]);
		PokerAiUi["playerBestHandRank_" + seatNumber].setValue(playerRec[5]);
		PokerAiUi["playerHandShowingLabel_" + seatNumber].setValue(playerRec[11]);
		
		/*
		document.getElementById("seat_" + seatNumber + "_hole_card_1").src = PokerAiUi.getCardImage(playerRec[2]);
		document.getElementById("seat_" + seatNumber + "_hole_card_2").src = PokerAiUi.getCardImage(playerRec[3]);

		document.getElementById("seat_" + seatNumber + "_best_hand_1").src = PokerAiUi.getCardImage(playerRec[6]);
		document.getElementById("seat_" + seatNumber + "_best_hand_2").src = PokerAiUi.getCardImage(playerRec[7]);
		document.getElementById("seat_" + seatNumber + "_best_hand_3").src = PokerAiUi.getCardImage(playerRec[8]);
		document.getElementById("seat_" + seatNumber + "_best_hand_4").src = PokerAiUi.getCardImage(playerRec[9]);
		document.getElementById("seat_" + seatNumber + "_best_hand_5").src = PokerAiUi.getCardImage(playerRec[10]);
		*/

	}
	
	PokerAiUi.gamesPlayedLabel.setValue(0);
	/*
	P
	okerAiUi.gameNumberLabel.setValue("");
	PokerAiUi.bettingRoundLabel.setValue("");
	PokerAiUi.turnLabel.setValue("");
	PokerAiUi.lastToRaiseLabel.setValue("");
	PokerAiUi.smallBlindSeatLabel.setValue("");
	PokerAiUi.bigBlindSeatLabel.setValue("");
	PokerAiUi.smallBlindAmountLabel.setValue("");
	PokerAiUi.bigBlindAmountLabel.setValue("");
*/

	PokerAiUi["playerIdLabel_1"].setValue(PokerAiUi["playerIdLabel_1"].getValue() + " - Small Blind");
	PokerAiUi["playerIdLabel_2"].setValue(PokerAiUi["playerIdLabel_2"].getValue() + " - Big Blind");
	
};

PokerAiUi.initGame = function(){
	PokerAi.initGame(PokerAiUi.smallBlindSeatNumber, PokerAiUi.smallBlindAmountField.getValue(), PokerAiUi.bigBlindAmountField.getValue());
};
