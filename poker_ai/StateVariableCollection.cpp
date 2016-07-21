#include "StateVariableCollection.hpp"
#include <iostream>

std::map<StateVariableCollection::Constant, float> StateVariableCollection::constantData;
std::map<StateVariableCollection::PokerStateVariable, float> StateVariableCollection::pokerStateData;
std::map<StateVariableCollection::PrivatePlayerStateKey, float, StateVariableCollection::PrivatePlayerStateKeyComparator> StateVariableCollection::privatePlayerStateData;
std::map<StateVariableCollection::PublicPlayerStateKey, float, StateVariableCollection::PublicPlayerStateKeyComparator> StateVariableCollection::publicPlayerStateData;
std::vector<std::string> StateVariableCollection::pokerStateVariableNames;
std::vector<std::string> StateVariableCollection::privatePlayerStateVariableNames;
std::vector<std::string> StateVariableCollection::publicPlayerStateVariableNames;

StateVariableCollection::StateVariableCollection() {
	if (constantData.size() == 0) {

		constantData[CONSTANT_000_0] = 0.0f;
		constantData[CONSTANT_000_1] = 0.1f;
		constantData[CONSTANT_000_2] = 0.2f;
		constantData[CONSTANT_000_3] = 0.3f;
		constantData[CONSTANT_000_4] = 0.4f;
		constantData[CONSTANT_000_5] = 0.5f;
		constantData[CONSTANT_000_6] = 0.6f;
		constantData[CONSTANT_000_7] = 0.7f;
		constantData[CONSTANT_000_8] = 0.8f;
		constantData[CONSTANT_000_9] = 0.9f;
		constantData[CONSTANT_001_0] = 1.0f;
		constantData[CONSTANT_002_0] = 2.0f;
		constantData[CONSTANT_003_0] = 3.0f;
		constantData[CONSTANT_004_0] = 4.0f;
		constantData[CONSTANT_005_0] = 5.0f;
		constantData[CONSTANT_006_0] = 6.0f;
		constantData[CONSTANT_007_0] = 7.0f;
		constantData[CONSTANT_008_0] = 8.0f;
		constantData[CONSTANT_009_0] = 9.0f;
		constantData[CONSTANT_010_0] = 10.0f;
		constantData[CONSTANT_020_0] = 20.0f;
		constantData[CONSTANT_030_0] = 30.0f;
		constantData[CONSTANT_040_0] = 40.0f;
		constantData[CONSTANT_050_0] = 50.0f;
		constantData[CONSTANT_060_0] = 60.0f;
		constantData[CONSTANT_070_0] = 70.0f;
		constantData[CONSTANT_080_0] = 80.0f;
		constantData[CONSTANT_090_0] = 90.0f;
		constantData[CONSTANT_100_0] = 100.0f;

		pokerStateVariableNames.push_back("PLAYER_COUNT");
		pokerStateVariableNames.push_back("BUY_IN_AMOUNT");
		pokerStateVariableNames.push_back("CURRENT_BETTING_ROUND");
		pokerStateVariableNames.push_back("TOURNAMENT_IN_PROGRESS");
		pokerStateVariableNames.push_back("CURRENT_GAME_NUMBER");
		pokerStateVariableNames.push_back("GAME_IN_PROGRESS");
		pokerStateVariableNames.push_back("BETTING_ROUND_IN_PROGRESS");
		pokerStateVariableNames.push_back("SMALL_BLIND_SEAT_NUMBER");
		pokerStateVariableNames.push_back("BIG_BLIND_SEAT_NUMBER");
		pokerStateVariableNames.push_back("TURN_SEAT_NUMBER");
		pokerStateVariableNames.push_back("LAST_TO_RAISE_SEAT_NUMBER");
		pokerStateVariableNames.push_back("MIN_RAISE_AMOUNT");
		pokerStateVariableNames.push_back("SMALL_BLIND_VALUE");
		pokerStateVariableNames.push_back("BIG_BLIND_VALUE");
		pokerStateVariableNames.push_back("COMMUNITY_CARD_1_ID");
		pokerStateVariableNames.push_back("COMMUNITY_CARD_1_SUIT");
		pokerStateVariableNames.push_back("COMMUNITY_CARD_1_VALUE");
		pokerStateVariableNames.push_back("COMMUNITY_CARD_2_ID");
		pokerStateVariableNames.push_back("COMMUNITY_CARD_2_SUIT");
		pokerStateVariableNames.push_back("COMMUNITY_CARD_2_VALUE");
		pokerStateVariableNames.push_back("COMMUNITY_CARD_3_ID");
		pokerStateVariableNames.push_back("COMMUNITY_CARD_3_SUIT");
		pokerStateVariableNames.push_back("COMMUNITY_CARD_3_VALUE");
		pokerStateVariableNames.push_back("COMMUNITY_CARD_4_ID");
		pokerStateVariableNames.push_back("COMMUNITY_CARD_4_SUIT");
		pokerStateVariableNames.push_back("COMMUNITY_CARD_4_VALUE");
		pokerStateVariableNames.push_back("COMMUNITY_CARD_5_ID");
		pokerStateVariableNames.push_back("COMMUNITY_CARD_5_SUIT");
		pokerStateVariableNames.push_back("COMMUNITY_CARD_5_VALUE");

		privatePlayerStateVariableNames.push_back("HOLE_CARD_1_ID");
		privatePlayerStateVariableNames.push_back("HOLE_CARD_2_ID");
		privatePlayerStateVariableNames.push_back("HOLE_CARD_1_SUIT");
		privatePlayerStateVariableNames.push_back("HOLE_CARD_2_SUIT");
		privatePlayerStateVariableNames.push_back("HOLE_CARD_1_VALUE");
		privatePlayerStateVariableNames.push_back("HOLE_CARD_2_VALUE");
		privatePlayerStateVariableNames.push_back("BEST_HAND_CLASSIFICATION");

		publicPlayerStateVariableNames.push_back("TOURNAMENT_RANK");
		publicPlayerStateVariableNames.push_back("STATE");
		publicPlayerStateVariableNames.push_back("SEAT_NUMBER");
		publicPlayerStateVariableNames.push_back("PLAYER_ID");
		publicPlayerStateVariableNames.push_back("ASSUMED_STRATEGY_ID");
		publicPlayerStateVariableNames.push_back("MONEY");
		publicPlayerStateVariableNames.push_back("HAND_SHOWING");
		publicPlayerStateVariableNames.push_back("PRESENTED_BET_OPPORTUNITY");
		publicPlayerStateVariableNames.push_back("GAME_RANK");
		publicPlayerStateVariableNames.push_back("ELIGIBLE_TO_WIN_MONEY");
		publicPlayerStateVariableNames.push_back("TOTAL_POT_CONTRIBUTION");
		publicPlayerStateVariableNames.push_back("TOTAL_POT_DEFICIT");
		publicPlayerStateVariableNames.push_back("AVERAGE_GAME_PROFIT");
		publicPlayerStateVariableNames.push_back("GAMES_PLAYED");
		publicPlayerStateVariableNames.push_back("MAIN_POTS_WON");
		publicPlayerStateVariableNames.push_back("MAIN_POTS_SPLIT");
		publicPlayerStateVariableNames.push_back("SIDE_POTS_WON");
		publicPlayerStateVariableNames.push_back("SIDE_POTS_SPLIT");
		publicPlayerStateVariableNames.push_back("FLOPS_SEEN");
		publicPlayerStateVariableNames.push_back("TURNS_SEEN");
		publicPlayerStateVariableNames.push_back("RIVERS_SEEN");
		publicPlayerStateVariableNames.push_back("PRE_FLOP_FOLDS");
		publicPlayerStateVariableNames.push_back("FLOP_FOLDS");
		publicPlayerStateVariableNames.push_back("TURN_FOLDS");
		publicPlayerStateVariableNames.push_back("RIVER_FOLDS");
		publicPlayerStateVariableNames.push_back("TOTAL_FOLDS");
		publicPlayerStateVariableNames.push_back("PRE_FLOP_CHECKS");
		publicPlayerStateVariableNames.push_back("FLOP_CHECKS");
		publicPlayerStateVariableNames.push_back("TURN_CHECKS");
		publicPlayerStateVariableNames.push_back("RIVER_CHECKS");
		publicPlayerStateVariableNames.push_back("TOTAL_CHECKS");
		publicPlayerStateVariableNames.push_back("PRE_FLOP_CALLS");
		publicPlayerStateVariableNames.push_back("FLOP_CALLS");
		publicPlayerStateVariableNames.push_back("TURN_CALLS");
		publicPlayerStateVariableNames.push_back("RIVER_CALLS");
		publicPlayerStateVariableNames.push_back("TOTAL_CALLS");
		publicPlayerStateVariableNames.push_back("PRE_FLOP_BETS");
		publicPlayerStateVariableNames.push_back("FLOP_BETS");
		publicPlayerStateVariableNames.push_back("TURN_BETS");
		publicPlayerStateVariableNames.push_back("RIVER_BETS");
		publicPlayerStateVariableNames.push_back("TOTAL_BETS");
		publicPlayerStateVariableNames.push_back("PRE_FLOP_TOTAL_BET_AMOUNT");
		publicPlayerStateVariableNames.push_back("FLOP_TOTAL_BET_AMOUNT");
		publicPlayerStateVariableNames.push_back("TURN_TOTAL_BET_AMOUNT");
		publicPlayerStateVariableNames.push_back("RIVER_TOTAL_BET_AMOUNT");
		publicPlayerStateVariableNames.push_back("TOTAL_BET_AMOUNT");
		publicPlayerStateVariableNames.push_back("PRE_FLOP_RAISES");
		publicPlayerStateVariableNames.push_back("FLOP_RAISES");
		publicPlayerStateVariableNames.push_back("TURN_RAISES");
		publicPlayerStateVariableNames.push_back("RIVER_RAISES");
		publicPlayerStateVariableNames.push_back("TOTAL_RAISES");
		publicPlayerStateVariableNames.push_back("PRE_FLOP_TOTAL_RAISE_AMOUNT");
		publicPlayerStateVariableNames.push_back("FLOP_TOTAL_RAISE_AMOUNT");
		publicPlayerStateVariableNames.push_back("TURN_TOTAL_RAISE_AMOUNT");
		publicPlayerStateVariableNames.push_back("RIVER_TOTAL_RAISE_AMOUNT");
		publicPlayerStateVariableNames.push_back("TOTAL_RAISE_AMOUNT");
		publicPlayerStateVariableNames.push_back("TIMES_ALL_IN");
		publicPlayerStateVariableNames.push_back("TOTAL_MONEY_PLAYED");
		publicPlayerStateVariableNames.push_back("TOTAL_MONEY_WON");
		publicPlayerStateVariableNames.push_back("PRE_FLOP_AVERAGE_BET_AMOUNT");
		publicPlayerStateVariableNames.push_back("FLOP_AVERAGE_BET_AMOUNT");
		publicPlayerStateVariableNames.push_back("TURN_AVERAGE_BET_AMOUNT");
		publicPlayerStateVariableNames.push_back("RIVER_AVERAGE_BET_AMOUNT");
		publicPlayerStateVariableNames.push_back("AVERAGE_BET_AMOUNT");
		publicPlayerStateVariableNames.push_back("PRE_FLOP_AVERAGE_RAISE_AMOUNT");
		publicPlayerStateVariableNames.push_back("FLOP_AVERAGE_RAISE_AMOUNT");
		publicPlayerStateVariableNames.push_back("TURN_AVERAGE_RAISE_AMOUNT");
		publicPlayerStateVariableNames.push_back("RIVER_AVERAGE_RAISE_AMOUNT");
		publicPlayerStateVariableNames.push_back("AVERAGE_RAISE_AMOUNT");

		variableSectionBoundaries.constantLowerBound = 0;  // 0
		variableSectionBoundaries.constantUpperBound = Constant::CONSTANT_100_0;  // 28
		variableSectionBoundaries.pokerStateLowerBound = variableSectionBoundaries.constantUpperBound + 1;  // 29
		variableSectionBoundaries.pokerStateUpperBound = variableSectionBoundaries.pokerStateLowerBound + PokerStateVariable::COMMUNITY_CARD_5_VALUE; // 57
		variableSectionBoundaries.privatePlayerStateLowerBound = variableSectionBoundaries.pokerStateUpperBound + 1; // 58
		variableSectionBoundaries.privatePlayerStateUpperBound = variableSectionBoundaries.privatePlayerStateLowerBound + PrivatePlayerStateVariable::BEST_HAND_CLASSIFICATION; // 64
		variableSectionBoundaries.publicPlayerStateLowerBound = variableSectionBoundaries.privatePlayerStateUpperBound + 1; // 65
		variableSectionBoundaries.publicPlayerStateUpperBound = variableSectionBoundaries.publicPlayerStateLowerBound + (maxPlayerCount * (PublicPlayerStateVariable::AVERAGE_RAISE_AMOUNT + 1)) - 1; // 754
		variableSectionBoundaries.publicPlayerStateVariablesPerPlayer = (variableSectionBoundaries.publicPlayerStateUpperBound - variableSectionBoundaries.publicPlayerStateLowerBound + 1) / maxPlayerCount; // 69
	}
}

void StateVariableCollection::getVariableSectionBoundaries(VariableSectionBoundaries& variableSectionBoundaries) const {
	variableSectionBoundaries = this->variableSectionBoundaries;
}

float StateVariableCollection::getConstantValue(Constant constantId) {
	return constantData[constantId];
}

float StateVariableCollection::getPokerStateVariableValue(PokerStateVariable variableId) {
	PokerStateVariable varId = (PokerStateVariable) (variableId - variableSectionBoundaries.pokerStateLowerBound);
	return pokerStateData[varId];
}

float StateVariableCollection::getPrivatePlayerStateVariableValue(PrivatePlayerStateVariable variableId, unsigned int seatNumber) {
	PrivatePlayerStateVariable varId = (PrivatePlayerStateVariable) (variableId - variableSectionBoundaries.privatePlayerStateLowerBound);
	return privatePlayerStateData[{seatNumber, varId}];
}

float StateVariableCollection::getPublicPlayerStateVariableValue(PublicPlayerStateVariable variableId) {

	PublicPlayerStateVariable varId = (PublicPlayerStateVariable) (variableId - variableSectionBoundaries.publicPlayerStateLowerBound);
	unsigned int seatNumber = (varId / variableSectionBoundaries.publicPlayerStateVariablesPerPlayer) + 1;
	varId = (PublicPlayerStateVariable) (varId - ((seatNumber - 1) * variableSectionBoundaries.publicPlayerStateVariablesPerPlayer));

	std::map<PublicPlayerStateKey, float>::iterator it = publicPlayerStateData.find({seatNumber, varId});
	if (it != publicPlayerStateData.end())
		return it->second;

	return 0.0f;
}

void StateVariableCollection::dumpData() const {

	std::cout << "Constant Data:" << std::endl;
	for (std::map<Constant, float>::iterator it = constantData.begin(); it != constantData.end(); ++it) {
		std::cout << std::to_string(it->second) << std::endl;
	}

	std::cout << "Poker State Data:" << std::endl;
	for (std::map<PokerStateVariable, float>::iterator it = pokerStateData.begin(); it != pokerStateData.end(); ++it) {
		std::cout << pokerStateVariableNames[it->first] << ": " << std::to_string(it->second) << std::endl;
	}

	std::cout << "Private Player Data:" << std::endl;
	for (std::map<PrivatePlayerStateKey, float>::iterator it = privatePlayerStateData.begin(); it != privatePlayerStateData.end(); ++it) {
		std::cout << "Seat " << std::to_string(it->first.seatNumber) << " " << privatePlayerStateVariableNames[it->first.stateVariableId]
			<< ": " << std::to_string(it->second) << std::endl;
	}

	std::cout << "Public Player Data:" << std::endl;
	for (std::map<PublicPlayerStateKey, float>::iterator it = publicPlayerStateData.begin(); it != publicPlayerStateData.end(); ++it) {
		std::cout << "Seat " << std::to_string(it->first.seatNumber) << " " << publicPlayerStateVariableNames[it->first.stateVariableId]
			<< ": " << std::to_string(it->second) << std::endl;
	}

}

void StateVariableCollection::clear() {
	pokerStateData.clear();
	privatePlayerStateData.clear();
	publicPlayerStateData.clear();
}

void StateVariableCollection::setPokerStateVariableValue(PokerStateVariable variableId, float variableValue) {
	pokerStateData[variableId] = variableValue;
}

void StateVariableCollection::setPrivatePlayerStateVariableValue(PrivatePlayerStateVariable variableId, unsigned int seatNumber, float variableValue) {
	privatePlayerStateData[{seatNumber, variableId}] = variableValue;
}

void StateVariableCollection::setPublicPlayerStateVariableValue(PublicPlayerStateVariable variableId, unsigned int seatNumber, float variableValue) {
	publicPlayerStateData[{seatNumber, variableId}] = variableValue;
}
