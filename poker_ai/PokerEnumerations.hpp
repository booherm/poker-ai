#ifndef POKERENUMERATIONS_HPP
#define POKERENUMERATIONS_HPP

namespace PokerEnums {

	enum PlayerMove {
		AUTO = 0,
		FOLD = 1,
		CHECK = 2,
		CALL = 3,
		BET = 4,
		RAISE = 5
	};

	enum HandClassification {
		INCOMPLETE_HAND = 0,
		HIGH_CARD = 1,
		ONE_PAIR = 2,
		TWO_PAIR = 3,
		THREE_OF_A_KIND = 4,
		STRAIGHT = 5,
		FLUSH = 6,
		FULL_HOUSE = 7,
		FOUR_OF_A_KIND = 8,
		STRAIGHT_FLUSH = 9,
		ROYAL_FLUSH = 10
	};

	enum State {
		NO_PLAYER = 0,
		NO_MOVE = 1,
		FOLDED = 2,
		CHECKED = 3,
		CALLED = 4,
		MADE_BET = 5,
		RAISED = 6,
		OUT_OF_TOURNAMENT = 7,
		ALL_IN = 8
	};

	enum BettingRound {
		NO_BETTING_ROUND = 0,
		PRE_FLOP = 1,
		FLOP = 2,
		TURN = 3,
		RIVER = 4,
		SHOWDOWN = 5
	};

};

#endif
