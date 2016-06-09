#include "DbInterface.hpp"
#include <iostream>
#include <string>

DbInterface::DbInterface() {
	ocilib::Environment::Initialize();
	con.Open("XE", "matt", "matt");
}

DbInterface::~DbInterface() {
	con.Close();
	ocilib::Environment::Cleanup();
}

void DbInterface::initTournament(const std::string& tournamentMode, unsigned int playerCount, unsigned int buyInAmount) {
	try
	{
		std::string procCall = "BEGIN pkg_poker_ai.initialize_tournament(";
		procCall.append("p_tournament_mode => :tournamentMode, ");
		procCall.append("p_strategy_ids    => NULL, ");
		procCall.append("p_player_count    => :playerCount, ");
		procCall.append("p_buy_in_amount   => :buyInAmount");
		procCall.append("); END; ");

		ocilib::Statement st(con);
		st.Prepare(procCall);
		ocilib::ostring tournamentMoveOstring(tournamentMode);
		st.Bind("tournamentMode", tournamentMoveOstring, static_cast<unsigned int>(tournamentMoveOstring.size()), ocilib::BindInfo::In);
		st.Bind("playerCount", playerCount, ocilib::BindInfo::In);
		st.Bind("buyInAmount", buyInAmount, ocilib::BindInfo::In);
		st.ExecutePrepared();
	}
	catch (std::exception &ex)
	{
		std::string exceptionString(ex.what());
		std::cout << "exception: " << exceptionString << std::endl;
	}
}

void DbInterface::stepPlay(unsigned int smallBlindAmount, const std::string& playerMove, unsigned int playerMoveAmount) {
	try
	{
		std::string procCall = "BEGIN pkg_poker_ai.step_play(";
		procCall.append("p_small_blind_value  => :smallBlindAmount, ");
		procCall.append("p_player_move        => :playerMove, ");
		procCall.append("p_player_move_amount => :playerMoveAmount");
		procCall.append("); END;");

		ocilib::Statement st(con);
		st.Prepare(procCall);
		st.Bind("smallBlindAmount", smallBlindAmount, ocilib::BindInfo::In);
		ocilib::ostring playerMoveOstring(playerMove);
		st.Bind("playerMove", playerMoveOstring, static_cast<unsigned int>(playerMoveOstring.size()), ocilib::BindInfo::In);
		st.Bind("playerMoveAmount", playerMoveAmount, ocilib::BindInfo::In);
		st.ExecutePrepared();
	}
	catch (std::exception &ex)
	{
		std::string exceptionString(ex.what());
		std::cout << "exception: " << exceptionString << std::endl;
	}
}

void DbInterface::loadState(unsigned int stateId) {
	try
	{
		std::string procCall = "BEGIN pkg_poker_ai.load_state(";
		procCall.append("p_state_id => :stateId");
		procCall.append("); END;");

		ocilib::Statement st(con);
		st.Prepare(procCall);
		st.Bind("stateId", stateId, ocilib::BindInfo::In);
		st.ExecutePrepared();
	}
	catch (std::exception &ex)
	{
		std::string exceptionString(ex.what());
		std::cout << "exception: " << exceptionString << std::endl;
	}
}

void DbInterface::loadPreviousState(unsigned int stateId) {

	try
	{
		std::string procCall = "BEGIN pkg_poker_ai.load_previous_state(";
		procCall.append("p_state_id => :stateId");
		procCall.append("); END;");

		ocilib::Statement st(con);
		st.Prepare(procCall);
		st.Bind("stateId", stateId, ocilib::BindInfo::In);
		st.ExecutePrepared();
	}
	catch (std::exception &ex)
	{
		std::string exceptionString(ex.what());
		std::cout << "exception: " << exceptionString << std::endl;
	}

}

void DbInterface::loadNextState(unsigned int stateId) {
	
	try
	{
		std::string procCall = "BEGIN pkg_poker_ai.load_next_state(";
		procCall.append("p_state_id => :stateId");
		procCall.append("); END;");

		ocilib::Statement st(con);
		st.Prepare(procCall);
		st.Bind("stateId", stateId, ocilib::BindInfo::In);
		st.ExecutePrepared();
	}
	catch (std::exception &ex)
	{
		std::string exceptionString(ex.what());
		std::cout << "exception: " << exceptionString << std::endl;
	}

}

void DbInterface::editCard(const std::string& cardType, unsigned int seatNumber, unsigned int cardSlot, unsigned int cardId) {

	try
	{
		std::string procCall = "BEGIN pkg_poker_ai.edit_card(";
		procCall.append("p_card_type   => :cardType, ");
		procCall.append("p_seat_number => :seatNumber, ");
		procCall.append("p_card_slot   => :cardSlot, ");
		procCall.append("p_card_id     => :cardId");
		procCall.append("); END;");

		ocilib::Statement st(con);
		st.Prepare(procCall);
		ocilib::ostring cardTypeOstring(cardType);
		st.Bind("cardType", cardTypeOstring, static_cast<unsigned int>(cardTypeOstring.size()), ocilib::BindInfo::In);
		st.Bind("seatNumber", seatNumber, ocilib::BindInfo::In);
		st.Bind("cardSlot", cardSlot, ocilib::BindInfo::In);
		st.Bind("cardId", cardId, ocilib::BindInfo::In);
		st.ExecutePrepared();
	}
	catch (std::exception &ex)
	{
		std::string exceptionString(ex.what());
		std::cout << "exception: " << exceptionString << std::endl;
	}

}

void DbInterface::getUiState(Json::Value& uiData) {
	try
	{
		// call for tournament state
		std::string procCall = "BEGIN pkg_poker_ai.select_ui_state(";
		procCall.append("p_tournament_state => :tournamentStateRs, ");
		procCall.append("p_game_state       => :gameStateRs, ");
		procCall.append("p_player_state     => :playerStateRs, ");
		procCall.append("p_pots             => :potsRs, ");
		procCall.append("p_status           => :statusRs");
		procCall.append("); END;");
		ocilib::Statement sts(con);
		ocilib::Statement tournamentStateRsBind(con);
		ocilib::Statement gameStateBind(con);
		ocilib::Statement playerStateBind(con);
		ocilib::Statement potsBind(con);
		ocilib::Statement statusBind(con);
		sts.Prepare(procCall);
		sts.Bind("tournamentStateRs", tournamentStateRsBind, ocilib::BindInfo::Out);
		sts.Bind("gameStateRs", gameStateBind, ocilib::BindInfo::Out);
		sts.Bind("playerStateRs", playerStateBind, ocilib::BindInfo::Out);
		sts.Bind("potsRs", potsBind, ocilib::BindInfo::Out);
		sts.Bind("statusRs", statusBind, ocilib::BindInfo::Out);
		sts.ExecutePrepared();

		// tournament state
		ocilib::Resultset tournamentStateRs = tournamentStateRsBind.GetResultset();
		Json::Value tournamentStateData(Json::objectValue);
		tournamentStateRs.Next();
		tournamentStateData["player_count"] = tournamentStateRs.IsColumnNull("player_count") ? Json::Value::null : tournamentStateRs.Get<unsigned int>("player_count");
		tournamentStateData["buy_in_amount"] = tournamentStateRs.IsColumnNull("buy_in_amount") ? Json::Value::null : tournamentStateRs.Get<unsigned int>("buy_in_amount");
		tournamentStateData["current_game_number"] = tournamentStateRs.IsColumnNull("current_game_number") ? Json::Value::null : tournamentStateRs.Get<unsigned int>("current_game_number");
		tournamentStateData["game_in_progress"] = tournamentStateRs.IsColumnNull("game_in_progress") ? Json::Value::null : tournamentStateRs.Get<std::string>("game_in_progress");
		tournamentStateData["current_state_id"] = tournamentStateRs.IsColumnNull("current_state_id") ? Json::Value::null : tournamentStateRs.Get<unsigned int>("current_state_id");
		uiData["tournamentState"] = tournamentStateData;

		// game state
		ocilib::Resultset gameStateRs = gameStateBind.GetResultset();
		Json::Value gameStateData(Json::objectValue);
		gameStateRs.Next();
		gameStateData["small_blind_seat_number"] = gameStateRs.IsColumnNull("small_blind_seat_number") ? Json::Value::null : gameStateRs.Get<unsigned int>("small_blind_seat_number");
		gameStateData["big_blind_seat_number"] = gameStateRs.IsColumnNull("big_blind_seat_number") ? Json::Value::null : gameStateRs.Get<unsigned int>("big_blind_seat_number");
		gameStateData["turn_seat_number"] = gameStateRs.IsColumnNull("turn_seat_number") ? Json::Value::null : gameStateRs.Get<unsigned int>("turn_seat_number");
		gameStateData["small_blind_value"] = gameStateRs.IsColumnNull("small_blind_value") ? Json::Value::null : gameStateRs.Get<unsigned int>("small_blind_value");
		gameStateData["big_blind_value"] = gameStateRs.IsColumnNull("big_blind_value") ? Json::Value::null : gameStateRs.Get<unsigned int>("big_blind_value");
		gameStateData["betting_round_number"] = gameStateRs.IsColumnNull("betting_round_number") ? Json::Value::null : gameStateRs.Get<std::string>("betting_round_number");
		gameStateData["betting_round_in_progress"] = gameStateRs.IsColumnNull("betting_round_in_progress") ? Json::Value::null : gameStateRs.Get<std::string>("betting_round_in_progress");
		gameStateData["last_to_raise_seat_number"] = gameStateRs.IsColumnNull("last_to_raise_seat_number") ? Json::Value::null : gameStateRs.Get<unsigned int>("last_to_raise_seat_number");
		gameStateData["community_card_1"] = gameStateRs.IsColumnNull("community_card_1") ? Json::Value::null : gameStateRs.Get<unsigned int>("community_card_1");
		gameStateData["community_card_2"] = gameStateRs.IsColumnNull("community_card_2") ? Json::Value::null : gameStateRs.Get<unsigned int>("community_card_2");
		gameStateData["community_card_3"] = gameStateRs.IsColumnNull("community_card_3") ? Json::Value::null : gameStateRs.Get<unsigned int>("community_card_3");
		gameStateData["community_card_4"] = gameStateRs.IsColumnNull("community_card_4") ? Json::Value::null : gameStateRs.Get<unsigned int>("community_card_4");
		gameStateData["community_card_5"] = gameStateRs.IsColumnNull("community_card_5") ? Json::Value::null : gameStateRs.Get<unsigned int>("community_card_5");
		uiData["gameState"] = gameStateData;

		// players state
		ocilib::Resultset playerStateRs = playerStateBind.GetResultset();
		Json::Value playerArray(Json::arrayValue);
		while (playerStateRs.Next())
		{
			Json::Value playerStateData(Json::objectValue);
			playerStateData["seat_number"] = playerStateRs.IsColumnNull("seat_number") ? Json::Value::null : playerStateRs.Get<unsigned int>("seat_number");
			playerStateData["player_id"] = playerStateRs.IsColumnNull("player_id") ? Json::Value::null : playerStateRs.Get<unsigned int>("player_id");
			playerStateData["hole_card_1"] = playerStateRs.IsColumnNull("hole_card_1") ? Json::Value::null : playerStateRs.Get<unsigned int>("hole_card_1");
			playerStateData["hole_card_2"] = playerStateRs.IsColumnNull("hole_card_2") ? Json::Value::null : playerStateRs.Get<unsigned int>("hole_card_2");
			playerStateData["best_hand_combination"] = playerStateRs.IsColumnNull("best_hand_combination") ? Json::Value::null : playerStateRs.Get<std::string>("best_hand_combination");
			playerStateData["best_hand_rank"] = playerStateRs.IsColumnNull("best_hand_rank") ? Json::Value::null : playerStateRs.Get<std::string>("best_hand_rank");
			playerStateData["best_hand_card_1"] = playerStateRs.IsColumnNull("best_hand_card_1") ? Json::Value::null : playerStateRs.Get<unsigned int>("best_hand_card_1");
			playerStateData["best_hand_card_2"] = playerStateRs.IsColumnNull("best_hand_card_2") ? Json::Value::null : playerStateRs.Get<unsigned int>("best_hand_card_2");
			playerStateData["best_hand_card_3"] = playerStateRs.IsColumnNull("best_hand_card_3") ? Json::Value::null : playerStateRs.Get<unsigned int>("best_hand_card_3");
			playerStateData["best_hand_card_4"] = playerStateRs.IsColumnNull("best_hand_card_4") ? Json::Value::null : playerStateRs.Get<unsigned int>("best_hand_card_4");
			playerStateData["best_hand_card_5"] = playerStateRs.IsColumnNull("best_hand_card_5") ? Json::Value::null : playerStateRs.Get<unsigned int>("best_hand_card_5");
			playerStateData["best_hand_card_1_is_hole_card"] = playerStateRs.IsColumnNull("best_hand_card_1_is_hole_card") ? Json::Value::null : playerStateRs.Get<std::string>("best_hand_card_1_is_hole_card");
			playerStateData["best_hand_card_2_is_hole_card"] = playerStateRs.IsColumnNull("best_hand_card_2_is_hole_card") ? Json::Value::null : playerStateRs.Get<std::string>("best_hand_card_2_is_hole_card");
			playerStateData["best_hand_card_3_is_hole_card"] = playerStateRs.IsColumnNull("best_hand_card_3_is_hole_card") ? Json::Value::null : playerStateRs.Get<std::string>("best_hand_card_3_is_hole_card");
			playerStateData["best_hand_card_4_is_hole_card"] = playerStateRs.IsColumnNull("best_hand_card_4_is_hole_card") ? Json::Value::null : playerStateRs.Get<std::string>("best_hand_card_4_is_hole_card");
			playerStateData["best_hand_card_5_is_hole_card"] = playerStateRs.IsColumnNull("best_hand_card_5_is_hole_card") ? Json::Value::null : playerStateRs.Get<std::string>("best_hand_card_5_is_hole_card");
			playerStateData["hand_showing"] = playerStateRs.IsColumnNull("hand_showing") ? Json::Value::null : playerStateRs.Get<std::string>("hand_showing");
			playerStateData["money"] = playerStateRs.IsColumnNull("money") ? Json::Value::null : playerStateRs.Get<unsigned int>("money");
			playerStateData["state"] = playerStateRs.IsColumnNull("state") ? Json::Value::null : playerStateRs.Get<std::string>("state");
			playerStateData["game_rank"] = playerStateRs.IsColumnNull("game_rank") ? Json::Value::null : playerStateRs.Get<unsigned int>("game_rank");
			playerStateData["tournament_rank"] = playerStateRs.IsColumnNull("tournament_rank") ? Json::Value::null : playerStateRs.Get<unsigned int>("tournament_rank");
			playerStateData["total_pot_contribution"] = playerStateRs.IsColumnNull("total_pot_contribution") ? Json::Value::null : playerStateRs.Get<unsigned int>("total_pot_contribution");
			playerStateData["can_fold"] = playerStateRs.IsColumnNull("can_fold") ? Json::Value::null : playerStateRs.Get<std::string>("can_fold");
			playerStateData["can_check"] = playerStateRs.IsColumnNull("can_check") ? Json::Value::null : playerStateRs.Get<std::string>("can_check");
			playerStateData["can_call"] = playerStateRs.IsColumnNull("can_call") ? Json::Value::null : playerStateRs.Get<std::string>("can_call");
			playerStateData["can_bet"] = playerStateRs.IsColumnNull("can_bet") ? Json::Value::null : playerStateRs.Get<std::string>("can_bet");
			playerStateData["min_bet_amount"] = playerStateRs.IsColumnNull("min_bet_amount") ? Json::Value::null : playerStateRs.Get<unsigned int>("min_bet_amount");
			playerStateData["max_bet_amount"] = playerStateRs.IsColumnNull("max_bet_amount") ? Json::Value::null : playerStateRs.Get<unsigned int>("max_bet_amount");
			playerStateData["can_raise"] = playerStateRs.IsColumnNull("can_raise") ? Json::Value::null : playerStateRs.Get<std::string>("can_raise");
			playerStateData["min_raise_amount"] = playerStateRs.IsColumnNull("min_raise_amount") ? Json::Value::null : playerStateRs.Get<unsigned int>("min_raise_amount");
			playerStateData["max_raise_amount"] = playerStateRs.IsColumnNull("max_raise_amount") ? Json::Value::null : playerStateRs.Get<unsigned int>("max_raise_amount");

			playerArray.append(playerStateData);
		}
		uiData["playerState"] = playerArray;

		// pots state
		ocilib::Resultset potsRs = potsBind.GetResultset();
		Json::Value potsArray(Json::arrayValue);
		while (potsRs.Next())
		{
			Json::Value potData(Json::objectValue);
			potData["pot_number"] = potsRs.IsColumnNull("pot_number") ? Json::Value::null : potsRs.Get<unsigned int>("pot_number");
			potData["pot_value"] = potsRs.IsColumnNull("pot_value") ? Json::Value::null : potsRs.Get<unsigned int>("pot_value");
			potData["betting_round_1_bet_value"] = potsRs.IsColumnNull("betting_round_1_bet_value") ? Json::Value::null : potsRs.Get<unsigned int>("betting_round_1_bet_value");
			potData["betting_round_2_bet_value"] = potsRs.IsColumnNull("betting_round_2_bet_value") ? Json::Value::null : potsRs.Get<unsigned int>("betting_round_2_bet_value");
			potData["betting_round_3_bet_value"] = potsRs.IsColumnNull("betting_round_3_bet_value") ? Json::Value::null : potsRs.Get<unsigned int>("betting_round_3_bet_value");
			potData["betting_round_4_bet_value"] = potsRs.IsColumnNull("betting_round_4_bet_value") ? Json::Value::null : potsRs.Get<unsigned int>("betting_round_4_bet_value");
			potData["pot_members"] = potsRs.IsColumnNull("pot_members") ? Json::Value::null : potsRs.Get<std::string>("pot_members");

			potsArray.append(potData);
		}
		uiData["potState"] = potsArray;

		// status messages
		ocilib::Resultset statusRs = statusBind.GetResultset();
		Json::Value statusMessageArray(Json::arrayValue);
		while (statusRs.Next())
		{
			Json::Value statusMessageData(Json::objectValue);
			unsigned int logRecordNumber = statusRs.Get<unsigned int>("log_record_number");
			statusMessageData["log_record_number"] = logRecordNumber;
			statusMessageData["message"] = statusRs.IsColumnNull("message") ? Json::Value::null : statusRs.Get<std::string>("message");
			statusMessageArray.append(statusMessageData);
		}
		uiData["statusMessage"] = statusMessageArray;

	}
	catch (std::exception &ex)
	{
		std::string exceptionString(ex.what());
		std::cout << "exception: " << exceptionString << std::endl;
	}
}
