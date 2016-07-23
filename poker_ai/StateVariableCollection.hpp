#ifndef STATEVARIABLECOLLECTION_HPP
#define STATEVARIABLECOLLECTION_HPP

#include <map>
#include <string>
#include <vector>

class StateVariableCollection {
public:

	enum Constant {
		CONSTANT_000_0,
		CONSTANT_000_1,
		CONSTANT_000_2,
		CONSTANT_000_3,
		CONSTANT_000_4,
		CONSTANT_000_5,
		CONSTANT_000_6,
		CONSTANT_000_7,
		CONSTANT_000_8,
		CONSTANT_000_9,
		CONSTANT_001_0,
		CONSTANT_002_0,
		CONSTANT_003_0,
		CONSTANT_004_0,
		CONSTANT_005_0,
		CONSTANT_006_0,
		CONSTANT_007_0,
		CONSTANT_008_0,
		CONSTANT_009_0,
		CONSTANT_010_0,
		CONSTANT_020_0,
		CONSTANT_030_0,
		CONSTANT_040_0,
		CONSTANT_050_0,
		CONSTANT_060_0,
		CONSTANT_070_0,
		CONSTANT_080_0,
		CONSTANT_090_0,
		CONSTANT_100_0
	};

	enum PokerStateVariable {
		PLAYER_COUNT,
		BUY_IN_AMOUNT,
		CURRENT_BETTING_ROUND,
		TOURNAMENT_IN_PROGRESS,
		CURRENT_GAME_NUMBER,
		GAME_IN_PROGRESS,
		BETTING_ROUND_IN_PROGRESS,
		SMALL_BLIND_SEAT_NUMBER,
		BIG_BLIND_SEAT_NUMBER,
		TURN_SEAT_NUMBER,
		LAST_TO_RAISE_SEAT_NUMBER,
		MIN_RAISE_AMOUNT,
		SMALL_BLIND_VALUE,
		BIG_BLIND_VALUE,
		COMMUNITY_CARD_1_ID,
		COMMUNITY_CARD_1_SUIT,
		COMMUNITY_CARD_1_VALUE,
		COMMUNITY_CARD_2_ID,
		COMMUNITY_CARD_2_SUIT,
		COMMUNITY_CARD_2_VALUE,
		COMMUNITY_CARD_3_ID,
		COMMUNITY_CARD_3_SUIT,
		COMMUNITY_CARD_3_VALUE,
		COMMUNITY_CARD_4_ID,
		COMMUNITY_CARD_4_SUIT,
		COMMUNITY_CARD_4_VALUE,
		COMMUNITY_CARD_5_ID,
		COMMUNITY_CARD_5_SUIT,
		COMMUNITY_CARD_5_VALUE
	};

	enum PrivatePlayerStateVariable {
		HOLE_CARD_1_ID,
		HOLE_CARD_2_ID,
		HOLE_CARD_1_SUIT,
		HOLE_CARD_2_SUIT,
		HOLE_CARD_1_VALUE,
		HOLE_CARD_2_VALUE,
		BEST_HAND_CLASSIFICATION
	};
	
	enum PublicPlayerStateVariable {
		TOURNAMENT_RANK,
		STATE,
		SEAT_NUMBER,
		PLAYER_ID,
		ASSUMED_STRATEGY_ID,
		MONEY,
		HAND_SHOWING,
		PRESENTED_BET_OPPORTUNITY,
		GAME_RANK,
		ELIGIBLE_TO_WIN_MONEY,
		TOTAL_POT_CONTRIBUTION,
		TOTAL_POT_DEFICIT,
		AVERAGE_GAME_PROFIT,
		GAMES_PLAYED,
		MAIN_POTS_WON,
		MAIN_POTS_SPLIT,
		SIDE_POTS_WON,
		SIDE_POTS_SPLIT,
		FLOPS_SEEN,
		TURNS_SEEN,
		RIVERS_SEEN,
		PRE_FLOP_FOLDS,
		FLOP_FOLDS,
		TURN_FOLDS,
		RIVER_FOLDS,
		TOTAL_FOLDS,
		PRE_FLOP_CHECKS,
		FLOP_CHECKS,
		TURN_CHECKS,
		RIVER_CHECKS,
		TOTAL_CHECKS,
		PRE_FLOP_CALLS,
		FLOP_CALLS,
		TURN_CALLS,
		RIVER_CALLS,
		TOTAL_CALLS,
		PRE_FLOP_BETS,
		FLOP_BETS,
		TURN_BETS,
		RIVER_BETS,
		TOTAL_BETS,
		PRE_FLOP_TOTAL_BET_AMOUNT,
		FLOP_TOTAL_BET_AMOUNT,
		TURN_TOTAL_BET_AMOUNT,
		RIVER_TOTAL_BET_AMOUNT,
		TOTAL_BET_AMOUNT,
		PRE_FLOP_RAISES,
		FLOP_RAISES,
		TURN_RAISES,
		RIVER_RAISES,
		TOTAL_RAISES,
		PRE_FLOP_TOTAL_RAISE_AMOUNT,
		FLOP_TOTAL_RAISE_AMOUNT,
		TURN_TOTAL_RAISE_AMOUNT,
		RIVER_TOTAL_RAISE_AMOUNT,
		TOTAL_RAISE_AMOUNT,
		TIMES_ALL_IN,
		TOTAL_MONEY_PLAYED,
		TOTAL_MONEY_WON,
		PRE_FLOP_AVERAGE_BET_AMOUNT,
		FLOP_AVERAGE_BET_AMOUNT,
		TURN_AVERAGE_BET_AMOUNT,
		RIVER_AVERAGE_BET_AMOUNT,
		AVERAGE_BET_AMOUNT,
		PRE_FLOP_AVERAGE_RAISE_AMOUNT,
		FLOP_AVERAGE_RAISE_AMOUNT,
		TURN_AVERAGE_RAISE_AMOUNT,
		RIVER_AVERAGE_RAISE_AMOUNT,
		AVERAGE_RAISE_AMOUNT
	};

	struct VariableSectionBoundaries {
		unsigned int constantLowerBound;
		unsigned int constantUpperBound;
		unsigned int pokerStateLowerBound;
		unsigned int pokerStateUpperBound;
		unsigned int privatePlayerStateLowerBound;
		unsigned int privatePlayerStateUpperBound;
		unsigned int publicPlayerStateLowerBound;
		unsigned int publicPlayerStateUpperBound;
		unsigned int publicPlayerStateVariablesPerPlayer;
	};

	StateVariableCollection();
	void getVariableSectionBoundaries(VariableSectionBoundaries& variableSectionBoundaries) const;
	float getConstantValue(Constant constantId);
	float getPokerStateVariableValue(PokerStateVariable variableId);
	float getPrivatePlayerStateVariableValue(PrivatePlayerStateVariable variableId, unsigned int seatNumber);
	float getPublicPlayerStateVariableValue(PublicPlayerStateVariable variableId);
	void dumpData();
	void clear();
	void setPokerStateVariableValue(PokerStateVariable variableId, float variableValue);
	void setPrivatePlayerStateVariableValue(PrivatePlayerStateVariable variableId, unsigned int seatNumber, float variableValue);
	void setPublicPlayerStateVariableValue(PublicPlayerStateVariable variableId, unsigned int seatNumber, float variableValue);

private:

	struct PrivatePlayerStateKey {
		unsigned int seatNumber;
		PrivatePlayerStateVariable stateVariableId;
	};

	struct PrivatePlayerStateKeyComparator {
		bool operator ()(const StateVariableCollection::PrivatePlayerStateKey& left, const StateVariableCollection::PrivatePlayerStateKey& right) const {
			if (left.seatNumber == right.seatNumber)
				return left.stateVariableId < right.stateVariableId;

			return left.seatNumber < right.seatNumber;
		}
	};

	struct PublicPlayerStateKey {
		unsigned int seatNumber;
		PublicPlayerStateVariable stateVariableId;
	};

	struct PublicPlayerStateKeyComparator {
		bool operator ()(const StateVariableCollection::PublicPlayerStateKey& left, const StateVariableCollection::PublicPlayerStateKey& right) const {
			if (left.seatNumber == right.seatNumber)
				return left.stateVariableId < right.stateVariableId;

			return left.seatNumber < right.seatNumber;
		}
	};

	const unsigned int maxPlayerCount = 10;
	VariableSectionBoundaries variableSectionBoundaries;
	std::map<Constant, float> constantData;
	std::map<PokerStateVariable, float> pokerStateData;
	std::map<PrivatePlayerStateKey, float, PrivatePlayerStateKeyComparator> privatePlayerStateData;
	std::map<PublicPlayerStateKey, float, PublicPlayerStateKeyComparator> publicPlayerStateData;
	std::vector<std::string> pokerStateVariableNames;
	std::vector<std::string> privatePlayerStateVariableNames;
	std::vector<std::string> publicPlayerStateVariableNames;
};

#endif
