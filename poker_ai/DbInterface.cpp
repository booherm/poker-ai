#include "DbInterface.hpp"
#include <iostream>
#include <string>

DbInterface::DbInterface() {
	ocilib::Environment::Initialize();
	con.Open("XE", "matt", "matt");
}

DbInterface::~DbInterface() {
	con.Commit();
	con.Close();
	ocilib::Environment::Cleanup();
}

void DbInterface::test() {
	try
	{
		ocilib::Statement st(con);
		st.Execute("SELECT ROWNUM intcol, 'Hello ' || ROWNUM strcol FROM DUAL CONNECT BY ROWNUM <= 10");
		ocilib::Resultset rs = st.GetResultset();
		while (rs.Next())
		{
			std::cout << rs.Get<int>(1) << " - " << rs.Get<ocilib::ostring>(2) << std::endl;
		}
	}
	catch (std::exception &ex)
	{
		std::string exceptionString(ex.what());
		std::cout << "exception: " << exceptionString << std::endl;
	}
}

void DbInterface::initTournament(unsigned int playerCount, unsigned int buyInAmount) {
	try
	{
		ocilib::Statement st(con);
		st.Prepare("BEGIN pkg_poker_ai.initialize_tournament(p_player_count => :playerCount, p_buy_in_amount => :buyInAmount); END;");
		st.Bind("playerCount", playerCount, ocilib::BindInfo::In);
		st.Bind("buyInAmount", buyInAmount, ocilib::BindInfo::In);
		st.ExecutePrepared();
		con.Commit();
	}
	catch (std::exception &ex)
	{
		std::string exceptionString(ex.what());
		std::cout << "exception: " << exceptionString << std::endl;
	}
}

void DbInterface::initGame(unsigned int smallBlindSeatNumber, unsigned int smallBlindAmount, unsigned int bigBlindAmount) {
	try
	{
		std::string procCall = "BEGIN pkg_poker_ai.initialize_game(";
		procCall.append("p_small_blind_seat_number => :smallBlindSeatNumber, ");
		procCall.append("p_small_blind_value       => :smallBlindAmount, ");
		procCall.append("p_big_blind_value         => :bigBlindAmount");
		procCall.append("); END;");

		ocilib::Statement st(con);
		st.Prepare(procCall);
		st.Bind("smallBlindSeatNumber", smallBlindSeatNumber, ocilib::BindInfo::In);
		st.Bind("smallBlindAmount", smallBlindAmount, ocilib::BindInfo::In);
		st.Bind("bigBlindAmount", bigBlindAmount, ocilib::BindInfo::In);
		st.ExecutePrepared();
		con.Commit();
	}
	catch (std::exception &ex)
	{
		std::string exceptionString(ex.what());
		std::cout << "exception: " << exceptionString << std::endl;
	}
}

void DbInterface::getPlayerState(Json::Value& playerState) {
	try
	{
		ocilib::Statement statementBind(con);
		ocilib::Statement spss(con);
		spss.Prepare("BEGIN pkg_poker_ai.select_player_state(p_result_set => :resultSet); END;");
		spss.Bind("resultSet", statementBind, ocilib::BindInfo::Out);
		spss.ExecutePrepared();
		ocilib::Resultset resultSet = statementBind.GetResultset();

		Json::Value playerArray(Json::arrayValue);
		while (resultSet.Next())
		{
			Json::Value playerInfo(Json::arrayValue);
			playerInfo.append(resultSet.Get<unsigned int>("player_id"));
			playerInfo.append(resultSet.Get<unsigned int>("seat_number"));
			playerInfo.append(resultSet.Get<unsigned int>("hole_card_1"));
			playerInfo.append(resultSet.Get<unsigned int>("hole_card_2"));
			playerInfo.append(resultSet.Get<std::string>("best_hand_combination"));
			playerInfo.append(resultSet.Get<std::string>("best_hand_rank"));
			playerInfo.append(resultSet.Get<unsigned int>("best_hand_card_1"));
			playerInfo.append(resultSet.Get<unsigned int>("best_hand_card_2"));
			playerInfo.append(resultSet.Get<unsigned int>("best_hand_card_3"));
			playerInfo.append(resultSet.Get<unsigned int>("best_hand_card_4"));
			playerInfo.append(resultSet.Get<unsigned int>("best_hand_card_5"));
			playerInfo.append(resultSet.Get<std::string>("hand_showing"));
			playerInfo.append(resultSet.Get<unsigned int>("money"));
			playerInfo.append(resultSet.Get<std::string>("state"));
			playerInfo.append(resultSet.Get<unsigned int>("game_rank"));
			playerInfo.append(resultSet.Get<unsigned int>("tournament_rank"));
			playerArray.append(playerInfo);
		}
		playerState["playerState"] = playerArray;

	}
	catch (std::exception &ex)
	{
		std::string exceptionString(ex.what());
		std::cout << "exception: " << exceptionString << std::endl;
	}
}
