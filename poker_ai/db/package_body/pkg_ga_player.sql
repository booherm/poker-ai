CREATE OR REPLACE PACKAGE BODY pkg_ga_player AS

PROCEDURE perform_automatic_player_move (
	p_seat_number player_state.seat_number%TYPE
) IS

	v_can_fold           VARCHAR2(1) := pkg_poker_ai.get_can_fold(p_seat_number => p_seat_number);
	v_can_check          VARCHAR2(1) := pkg_poker_ai.get_can_check(p_seat_number => p_seat_number);
	v_can_call           VARCHAR2(1) := pkg_poker_ai.get_can_call(p_seat_number => p_seat_number);
	v_can_bet            VARCHAR2(1) := pkg_poker_ai.get_can_bet(p_seat_number => p_seat_number);
	v_can_raise          VARCHAR2(1) := pkg_poker_ai.get_can_raise(p_seat_number => p_seat_number);
	v_min_bet_amount     player_state.money%TYPE;
	v_max_bet_amount     player_state.money%TYPE;
	v_min_raise_amount   player_state.money%TYPE;
	v_max_raise_amount   player_state.money%TYPE;
	
	v_player_move        VARCHAR2(30);
	v_player_move_amount player_state.money%TYPE;
	v_strategy_procedure strategy.strategy_procedure%TYPE;
	
BEGIN

	-- Load strategy procedure for player.  If not found, perform random move.
	BEGIN
		SELECT s.strategy_procedure
		INTO   v_strategy_procedure
		FROM   player_state ps,
			   strategy s
		WHERE  ps.seat_number = p_seat_number
		   AND ps.current_strategy_id = s.strategy_id;
		   
		EXCEPTION WHEN NO_DATA_FOUND THEN
			NULL;
	END;
	
	IF v_strategy_procedure IS NOT NULL THEN
		pkg_poker_ai.log(p_message => 'player at seat ' || p_seat_number || ' is deriving move from strategy procedure');
		pkg_ga_player.execute_strategy(
			p_strategy_procedure => v_strategy_procedure,
			p_seat_number        => p_seat_number,
			p_can_fold           => v_can_fold,
			p_can_check          => v_can_check,
			p_can_call           => v_can_call,
			p_can_bet            => v_can_bet,
			p_can_raise          => v_can_raise,
			p_player_move        => v_player_move,
			p_player_move_amount => v_player_move_amount
		);
	ELSE
		-- random move and amount
		pkg_poker_ai.log(p_message => 'player at seat ' || p_seat_number || ' is performing random move');
		
		WITH possible_moves AS (
			SELECT 'FOLD'  player_move FROM DUAL WHERE v_can_fold = 'Y'  UNION ALL
			SELECT 'CHECK' player_move FROM DUAL WHERE v_can_check = 'Y' UNION ALL
			SELECT 'CALL'  player_move FROM DUAL WHERE v_can_call = 'Y'  UNION ALL
			SELECT 'BET'   player_move FROM DUAL WHERE v_can_bet = 'Y'   UNION ALL
			SELECT 'RAISE' player_move FROM DUAL WHERE v_can_raise = 'Y'
		)
		
		SELECT MIN(player_move) KEEP (DENSE_RANK FIRST ORDER BY DBMS_RANDOM.RANDOM) player_move
		INTO   v_player_move
		FROM   possible_moves;
		
		IF v_player_move = 'BET' THEN
			v_min_bet_amount := pkg_poker_ai.get_min_bet_amount(p_seat_number => p_seat_number);
			v_max_bet_amount := pkg_poker_ai.get_max_bet_amount(p_seat_number => p_seat_number);
		   
			v_player_move_amount := pkg_ga_util.get_random_int(
				p_lower_limit => v_min_bet_amount,
				p_upper_limit => v_max_bet_amount
			);
		   
		ELSIF v_player_move = 'RAISE' THEN
			v_min_raise_amount := pkg_poker_ai.get_min_raise_amount(p_seat_number => p_seat_number);
			v_max_raise_amount := pkg_poker_ai.get_max_raise_amount(p_seat_number => p_seat_number);

			v_player_move_amount := pkg_ga_util.get_random_int(
				p_lower_limit => v_min_raise_amount,
				p_upper_limit => v_max_raise_amount
			);

		END IF;
	END IF;
	
	pkg_poker_ai.perform_explicit_player_move(
		p_seat_number        => p_seat_number,
		p_player_move        => v_player_move,
		p_player_move_amount => v_player_move_amount
	);
	
END perform_automatic_player_move;

FUNCTION get_strategy_procedure(
	p_strategy_chromosome strategy.strategy_chromosome%TYPE
) RETURN strategy.strategy_procedure%TYPE IS

	v_procedure_plsql strategy.strategy_procedure%TYPE;
	v_variables_sql   strategy.strategy_procedure%TYPE;
	
BEGIN

	-- convert chromosome to strategy table
	pkg_ga_player.load_strategy_build_table(p_strategy_chromosome => p_strategy_chromosome);
	
	-- build strategy procedure as anonymous block
	v_procedure_plsql := '
DECLARE

	v_variable_qualifiers         pkg_strategy_variable.t_strat_variable_qualifiers;
	v_decision_type               INTEGER := :1;
	v_amount_multiplier           NUMBER := 1.0;
	v_player_move                 VARCHAR2(30);
	v_player_move_amount          player_state.money%TYPE;
	v_strategy_expression_map_rec pkg_ga_player.t_strategy_expression_map_rec;
	v_strategy_expression_map_tbl pkg_ga_player.t_strategy_expression_map_tbl;

BEGIN

	v_variable_qualifiers.can_fold := :2;
	v_variable_qualifiers.can_check := :3;
	v_variable_qualifiers.can_call := :4;
	v_variable_qualifiers.can_bet := :5;
	v_variable_qualifiers.can_raise := :6;
	v_variable_qualifiers.seat_number := :7;
	
';

	v_procedure_plsql := v_procedure_plsql || pkg_ga_player.get_expression_loader || CHR(13);
	
	v_procedure_plsql := v_procedure_plsql || pkg_ga_player.get_decision_tree (
		p_decision_tree_unit_id => 0,
		p_max_depth             => v_strat_chromosome_metadata.stack_depth
	);
	
	v_procedure_plsql := v_procedure_plsql || '
	
	:8 := v_player_move;
	:9 := v_player_move_amount;
	
END;
';

	RETURN v_procedure_plsql;
	
END get_strategy_procedure;

FUNCTION get_expression_loader RETURN strategy.strategy_procedure%TYPE IS

	v_plsql  strategy.strategy_procedure%TYPE;
	v_string VARCHAR2(4000);
	
BEGIN

	DBMS_LOB.CREATETEMPORARY(lob_loc => v_plsql, cache => TRUE, dur => DBMS_LOB.CALL);

	FOR v_rec IN (
		SELECT l_exp_slot_id expression_slot_id,
			   l_exp_l_op_id left_operand_id,
			   l_exp_op_id   operator_id,
			   l_exp_r_op_id right_operand_id
		FROM   strategy_build
		
		UNION ALL

		SELECT r_exp_slot_id expression_slot_id,
			   r_exp_l_op_id left_operand_id,
			   r_exp_op_id   operator_id,
			   r_exp_r_op_id right_operand_id
		FROM   strategy_build
		ORDER BY expression_slot_id
	) LOOP
	
		v_string := pkg_ga_util.indent(p_level => 1) || 'v_strategy_expression_map_rec.left_operand_id := ' || v_rec.left_operand_id || ';' || CHR(13)
			|| pkg_ga_util.indent(p_level => 1) || 'v_strategy_expression_map_rec.operator_id := ' || v_rec.operator_id || ';' || CHR(13)
			|| pkg_ga_util.indent(p_level => 1) || 'v_strategy_expression_map_rec.right_operand_id := ' || v_rec.right_operand_id || ';' || CHR(13)
			|| pkg_ga_util.indent(p_level => 1) || 'v_strategy_expression_map_tbl(' || v_rec.expression_slot_id || ') := v_strategy_expression_map_rec;' || CHR(13);
		
		DBMS_LOB.WRITEAPPEND(lob_loc => v_plsql, amount => LENGTH(v_string), buffer => v_string);
		
	END LOOP;
	
	RETURN v_plsql;
		
END get_expression_loader;

FUNCTION get_decision_tree (
	p_decision_tree_unit_id strategy_build.decision_tree_unit_id%TYPE,
	p_max_depth             INTEGER
) RETURN strategy.strategy_procedure%TYPE IS

	v_depth                    INTEGER;
	v_decision_tree            strategy.strategy_procedure%TYPE;
	v_expression_operator_text VARCHAR2(1);
	
BEGIN

	-- determine tree depth of the requested boolean operator slot ID
	v_depth := FLOOR(LOG(2, p_decision_tree_unit_id + 1) + 0.00000000001);
	
	IF v_depth = p_max_depth - 1 THEN
	
		v_decision_tree := pkg_ga_util.indent(p_level => v_depth + 1) || 'v_player_move := pkg_ga_player.get_move_for_dec_tree_unit(' || CHR(13)
			|| pkg_ga_util.indent(p_level => v_depth + 2) || 'p_decision_type         => v_decision_type,' || CHR(13)
			|| pkg_ga_util.indent(p_level => v_depth + 2) || 'p_decision_tree_unit_id => ' || p_decision_tree_unit_id || CHR(13)
			|| pkg_ga_util.indent(p_level => v_depth + 1) || ');' || CHR(13)
			|| CHR(13)
			|| pkg_ga_util.indent(p_level => v_depth + 1) || 'v_player_move_amount := pkg_ga_player.get_move_amt_for_dec_tree_unit(' || CHR(13)
			|| pkg_ga_util.indent(p_level => v_depth + 2) || 'p_seat_number       => v_variable_qualifiers.seat_number,' || CHR(13)
			|| pkg_ga_util.indent(p_level => v_depth + 2) || 'p_player_move       => v_player_move,' || CHR(13)
			|| pkg_ga_util.indent(p_level => v_depth + 2) || 'p_amount_multiplier => v_amount_multiplier' || CHR(13)
			|| pkg_ga_util.indent(p_level => v_depth + 1) || ');' || CHR(13);		
		
	ELSE
	
		FOR v_rec IN (
			SELECT l_exp_l_op_id,
				   l_exp_op_id,
				   l_exp_r_op_id,
				   bool_op_id,
				   r_exp_l_op_id,
				   r_exp_op_id,
				   r_exp_r_op_id,
				   l_amt_mult_id,
				   r_amt_mult_id
			FROM   strategy_build
			WHERE  decision_tree_unit_id = p_decision_tree_unit_id
		) LOOP
		
			-- left expression left operand
			v_decision_tree := pkg_ga_util.indent(p_level => v_depth + 1) || 'IF pkg_ga_player.get_expression_value('
				|| 'p_expression_id => ' || v_rec.l_exp_l_op_id || ', '
				|| 'p_expression_map => v_strategy_expression_map_tbl, '
				|| 'p_variable_qualifiers => v_variable_qualifiers) ';
				
			-- left expression operator and right operand
			v_expression_operator_text := pkg_ga_player.get_expression_operator_text(p_expression_operator_id => v_rec.l_exp_op_id);
			IF v_expression_operator_text = '/' THEN
				v_decision_tree := v_decision_tree || '/ NVL(NULLIF(pkg_ga_player.get_expression_value('
					|| 'p_expression_id => ' || v_rec.l_exp_r_op_id || ', '
					|| 'p_expression_map => v_strategy_expression_map_tbl, '
					|| 'p_variable_qualifiers => v_variable_qualifiers), 0), 1) ';
			ELSE
				v_decision_tree := v_decision_tree || v_expression_operator_text || ' pkg_ga_player.get_expression_value('
					|| 'p_expression_id => ' || v_rec.l_exp_r_op_id || ', '
					|| 'p_expression_map => v_strategy_expression_map_tbl, '
					|| 'p_variable_qualifiers => v_variable_qualifiers) ';
			END IF;
				
			-- boolean operator
			v_decision_tree := v_decision_tree || pkg_ga_player.get_boolean_operator_text(p_boolean_operator_id => v_rec.bool_op_id) || ' ';
			
			-- right expression left operand
			v_decision_tree := v_decision_tree || 'pkg_ga_player.get_expression_value('
				|| 'p_expression_id => ' || v_rec.r_exp_l_op_id || ', '
				|| 'p_expression_map => v_strategy_expression_map_tbl, '
				|| 'p_variable_qualifiers => v_variable_qualifiers) ';
			
			-- right expression operator and right operand
			v_expression_operator_text := pkg_ga_player.get_expression_operator_text(p_expression_operator_id => v_rec.r_exp_op_id);
			IF v_expression_operator_text = '/' THEN
				v_decision_tree := v_decision_tree || '/ NVL(NULLIF(pkg_ga_player.get_expression_value('
					|| 'p_expression_id => ' || v_rec.r_exp_r_op_id || ', '
					|| 'p_expression_map => v_strategy_expression_map_tbl, '
					|| 'p_variable_qualifiers => v_variable_qualifiers), 0), 1) ';
			ELSE
				v_decision_tree := v_decision_tree || v_expression_operator_text || ' pkg_ga_player.get_expression_value('
					|| 'p_expression_id => ' || v_rec.r_exp_r_op_id || ', '
					|| 'p_expression_map => v_strategy_expression_map_tbl, '
					|| 'p_variable_qualifiers => v_variable_qualifiers) ';
			END IF;
			v_decision_tree := v_decision_tree || 'THEN' || CHR(13);

			-- left branch amount multiplier
			v_decision_tree := v_decision_tree || pkg_ga_util.indent(p_level => v_depth + 2)
				|| 'v_amount_multiplier := v_amount_multiplier * '
				|| pkg_ga_player.get_amount_multiplier_text(p_amount_multiplier_id => v_rec.l_amt_mult_id) || ';' || CHR(13);
				
			-- left branch sub decision tree
			v_decision_tree := v_decision_tree || pkg_ga_player.get_decision_tree(
				p_decision_tree_unit_id => (2 * p_decision_tree_unit_id) + 1,
				p_max_depth             => p_max_depth
			);
			
			-- right branch amount multiplier
			v_decision_tree := v_decision_tree || pkg_ga_util.indent(p_level => v_depth + 1) || 'ELSE' || CHR(13);
			v_decision_tree := v_decision_tree || pkg_ga_util.indent(p_level => v_depth + 2)
				|| 'v_amount_multiplier := v_amount_multiplier * '
				|| pkg_ga_player.get_amount_multiplier_text(p_amount_multiplier_id => v_rec.r_amt_mult_id) || ';' || CHR(13);
				
			-- right branch sub decision tree
			v_decision_tree := v_decision_tree || pkg_ga_player.get_decision_tree(
				p_decision_tree_unit_id => (2 * p_decision_tree_unit_id) + 2,
				p_max_depth             => p_max_depth
			);
			v_decision_tree := v_decision_tree || pkg_ga_util.indent(p_level => v_depth + 1) || 'END IF;' || CHR(13);
			
		END LOOP;
		
	END IF;
	
	RETURN v_decision_tree;
	
END get_decision_tree;

FUNCTION get_expression_value(
	p_expression_id       NUMBER,
	p_expression_map      pkg_ga_player.t_strategy_expression_map_tbl,
	p_variable_qualifiers pkg_strategy_variable.t_strat_variable_qualifiers
) RETURN NUMBER IS

	v_expression_id        NUMBER(10, 0);
	v_value                NUMBER;
	v_left_referenced_ids  t_expression_map_entries;
	v_right_referenced_ids t_expression_map_entries;
	
BEGIN

	-- if expression id is outside the upper bounds of the expression and variables, circle back to start
	v_expression_id := MOD(p_expression_id, pkg_strategy_variable.v_public_variable_count + v_strat_chromosome_metadata.expression_slot_id_count);
	
	IF v_expression_id < v_strat_chromosome_metadata.expression_slot_id_count THEN
	
		-- refers to another expression
		v_left_referenced_ids(v_expression_id) := v_expression_id;
		v_right_referenced_ids(v_expression_id) := v_expression_id;
		v_value := pkg_ga_player.get_sub_expression_value(
			p_expression_id        => v_expression_id,
			p_expression_map       => p_expression_map,
			p_variable_qualifiers  => p_variable_qualifiers,
			p_left_referenced_ids  => v_left_referenced_ids,
			p_right_referenced_ids => v_right_referenced_ids
		);
		
	ELSE
	
		-- refers to a variable
		v_value := pkg_strategy_variable.get_strategy_variable_value(
			p_strategy_variable_id => v_expression_id,
			p_variable_qualifiers  => p_variable_qualifiers
		);
	
	END IF;
	
	RETURN v_value;

END get_expression_value;

FUNCTION get_sub_expression_value(
	p_expression_id               NUMBER,
	p_expression_map              pkg_ga_player.t_strategy_expression_map_tbl,
	p_variable_qualifiers         pkg_strategy_variable.t_strat_variable_qualifiers,
	p_left_referenced_ids  IN OUT t_expression_map_entries,
	p_right_referenced_ids IN OUT t_expression_map_entries
) RETURN NUMBER IS

	v_expression_id       NUMBER(10, 0);
	v_expression_map_rec  t_strategy_expression_map_rec;
	v_value               NUMBER;

	v_left_operand_id     NUMBER(38, 0);
	v_operator_value      VARCHAR2(1);
	v_right_operand_id    NUMBER(38, 0);
	v_left_operand_value  NUMBER;
	v_right_operand_value NUMBER;
	
BEGIN

	-- if expression id is outside the upper bounds of the expression and variables, circle back to start
	v_expression_id := MOD(p_expression_id, pkg_strategy_variable.v_public_variable_count + v_strat_chromosome_metadata.expression_slot_id_count);
	
	IF v_expression_id < v_strat_chromosome_metadata.expression_slot_id_count THEN
	
		-- refers to another expression
		v_expression_map_rec := p_expression_map(v_expression_id);
		v_left_operand_id := MOD(v_expression_map_rec.left_operand_id, pkg_strategy_variable.v_public_variable_count + v_strat_chromosome_metadata.expression_slot_id_count);
		v_operator_value := pkg_ga_player.get_expression_operator_text(p_expression_operator_id => v_expression_map_rec.operator_id);
		v_right_operand_id := MOD(v_expression_map_rec.right_operand_id, pkg_strategy_variable.v_public_variable_count + v_strat_chromosome_metadata.expression_slot_id_count);
		
		IF p_left_referenced_ids.EXISTS(v_left_operand_id) THEN
			IF v_operator_value IN ('+', '-') THEN
				v_left_operand_value := 0;
			ELSE
				v_left_operand_value := 1;
			END IF;
		ELSE
			p_left_referenced_ids(v_left_operand_id) := v_left_operand_id;
			v_left_operand_value := pkg_ga_player.get_sub_expression_value(
				p_expression_id        => v_left_operand_id,
				p_expression_map       => p_expression_map,
				p_variable_qualifiers  => p_variable_qualifiers,
				p_left_referenced_ids  => p_left_referenced_ids,
				p_right_referenced_ids => p_right_referenced_ids
			);
		END IF;
			
		IF p_right_referenced_ids.EXISTS(v_right_operand_id) THEN
			IF v_operator_value IN ('+', '-') THEN
				v_right_operand_value := 0;
			ELSE
				v_right_operand_value := 1;
			END IF;
		ELSE
			p_right_referenced_ids(v_right_operand_id) := v_right_operand_id;
			v_right_operand_value := pkg_ga_player.get_sub_expression_value(
				p_expression_id        => v_right_operand_id,
				p_expression_map       => p_expression_map,
				p_variable_qualifiers  => p_variable_qualifiers,
				p_left_referenced_ids  => p_left_referenced_ids,
				p_right_referenced_ids => p_right_referenced_ids
			);
		END IF;

		IF v_operator_value = '+' THEN
			v_value := v_left_operand_value + v_right_operand_value;
		ELSIF v_operator_value = '-' THEN
			v_value := v_left_operand_value - v_right_operand_value;
		ELSIF v_operator_value = '*' THEN
			v_value := v_left_operand_value * v_right_operand_value;
		ELSIF v_operator_value = '/' THEN
			v_value := v_left_operand_value / NVL(NULLIF(v_right_operand_value, 0), 1);
		END IF;
		
	ELSE
	
		-- refers to a variable
		v_value := pkg_strategy_variable.get_strategy_variable_value(
			p_strategy_variable_id => v_expression_id,
			p_variable_qualifiers  => p_variable_qualifiers
		);
		
	END IF;
	
	RETURN v_value;
	
END get_sub_expression_value;

FUNCTION get_move_for_dec_tree_unit(
	p_decision_type         INTEGER,
	p_decision_tree_unit_id strategy_build.decision_tree_unit_id%TYPE
) RETURN VARCHAR2 IS

	v_decision_choice_count INTEGER;
	v_choice_1              VARCHAR2(30);
	v_choice_2              VARCHAR2(30);
	v_choice_3              VARCHAR2(30);
	v_player_move           VARCHAR2(30);
	
BEGIN

	IF p_decision_type = 0 THEN
		v_decision_choice_count := 3;
		v_choice_1 := 'FOLD';
		v_choice_2 := 'CHECK';
		v_choice_3 := 'BET';
	ELSIF p_decision_type = 1 THEN
		v_decision_choice_count := 3;
		v_choice_1 := 'FOLD';
		v_choice_2 := 'CHECK';
		v_choice_3 := 'RAISE';
	ELSIF p_decision_type = 2 THEN
		v_decision_choice_count := 2;
		v_choice_1 := 'FOLD';
		v_choice_2 := 'CHECK';
	ELSIF p_decision_type = 3 THEN
		v_decision_choice_count := 3;
		v_choice_1 := 'FOLD';
		v_choice_2 := 'CALL';
		v_choice_3 := 'RAISE';
	ELSIF p_decision_type = 4 THEN
		v_decision_choice_count := 2;
		v_choice_1 := 'FOLD';
		v_choice_2 := 'CALL';
	ELSE
		RETURN NULL;
	END IF;
	
	WITH variables AS (
		SELECT pkg_ga_player.v_strat_chromosome_metadata.dec_tree_unit_slots output_slot_count,
			   v_decision_choice_count output_choice_count,
			   p_decision_tree_unit_id decision_tree_unit_id
		FROM   DUAL
	),

	choice_boundaries AS (
		SELECT ((ROWNUM - 1) * (output_slot_count / output_choice_count)) lower_bound,
			   NVL(LEAD(((ROWNUM - 1) * (output_slot_count / output_choice_count))) OVER (
					ORDER BY ((ROWNUM - 1) * (output_slot_count / output_choice_count))), 999999999) upper_bound,
			   CASE ROWNUM
					WHEN 1 THEN v_choice_1
					WHEN 2 THEN v_choice_2
					WHEN 3 THEN v_choice_3
			   END player_move
		FROM   variables
		CONNECT BY ROWNUM <= output_choice_count
	)

	SELECT cb.player_move
	INTO   v_player_move
	FROM   choice_boundaries cb,
		   variables v
	WHERE  cb.lower_bound <= (v.decision_tree_unit_id - v.output_slot_count)
	   AND cb.upper_bound > (v.decision_tree_unit_id - v.output_slot_count);
	
	RETURN v_player_move;
	
END get_move_for_dec_tree_unit;

FUNCTION get_move_amt_for_dec_tree_unit(
	p_seat_number       player_state.seat_number%TYPE,
	p_player_move       VARCHAR2,
	p_amount_multiplier NUMBER
) RETURN player_state.money%TYPE IS

	v_min_amount  player_state.money%TYPE;
	v_max_amount  player_state.money%TYPE;
	v_move_amount player_state.money%TYPE;
	
BEGIN

	IF p_player_move = 'BET' THEN
		v_min_amount := pkg_poker_ai.get_min_bet_amount(p_seat_number => p_seat_number);
		v_max_amount := pkg_poker_ai.get_max_bet_amount(p_seat_number => p_seat_number);
	ELSIF p_player_move = 'RAISE' THEN
		v_min_amount := pkg_poker_ai.get_min_raise_amount(p_seat_number => p_seat_number);
		v_max_amount := pkg_poker_ai.get_max_raise_amount(p_seat_number => p_seat_number);
	ELSE
		RETURN NULL;
	END IF;
	
	IF p_amount_multiplier >= 0.95 THEN
		v_move_amount := v_max_amount;
	ELSIF p_amount_multiplier <= 0.05 THEN
		v_move_amount := v_min_amount;
	ELSE
		v_move_amount := ROUND(v_min_amount + (p_amount_multiplier * (v_max_amount - v_min_amount)));
	END IF;
	
	IF v_move_amount > v_max_amount THEN
		v_move_amount := v_max_amount;
	END IF;
	
	IF v_move_amount < v_min_amount THEN
		v_move_amount := v_min_amount;
	END IF;

	RETURN v_move_amount;
		
END get_move_amt_for_dec_tree_unit;

FUNCTION get_expression_operator_text(
	p_expression_operator_id INTEGER
) RETURN VARCHAR2 RESULT_CACHE IS
BEGIN

	-- 2 bits, 0 <= p_expression_operator_id <= 3
	
	IF p_expression_operator_id = 0 THEN
		RETURN '+';
	ELSIF p_expression_operator_id = 1 THEN
		RETURN '-';
	ELSIF p_expression_operator_id = 2 THEN
		RETURN '*';
	ELSIF p_expression_operator_id = 3 THEN
		RETURN '/';
	END IF;
	
END get_expression_operator_text;

FUNCTION get_boolean_operator_text(
	p_boolean_operator_id INTEGER
) RETURN VARCHAR2 RESULT_CACHE IS
BEGIN

	-- 3 bits, 0 <= p_boolean_operator_id <= 7
	
	IF p_boolean_operator_id = 0 THEN
		RETURN '<';
	ELSIF p_boolean_operator_id = 1 THEN
		RETURN '<=';
	ELSIF p_boolean_operator_id = 2 THEN
		RETURN '=';
	ELSIF p_boolean_operator_id = 3 THEN
		RETURN '>=';
	ELSIF p_boolean_operator_id = 4 THEN
		RETURN '>';
	ELSIF p_boolean_operator_id = 5 THEN
		RETURN '!=';
	ELSIF p_boolean_operator_id = 6 THEN
		RETURN '<';
	ELSIF p_boolean_operator_id = 7 THEN
		RETURN '>';
	END IF;

END get_boolean_operator_text;

FUNCTION get_amount_multiplier_text(
	p_amount_multiplier_id INTEGER
) RETURN VARCHAR2 RESULT_CACHE IS

	v_mult NUMBER;
	
BEGIN

	-- 8 bits, 0 <= p_amount_multiplier_id <= 255
	v_mult := ROUND(p_amount_multiplier_id / 255, 8);
	RETURN TO_CHAR(v_mult);
	
END get_amount_multiplier_text;

PROCEDURE load_strategy_build_table(
	p_strategy_chromosome strategy.strategy_chromosome%TYPE
) IS
BEGIN

	-- convert chromosome to strategy table
	DELETE FROM strategy_build;
	
	-- decision tree units
	INSERT INTO strategy_build (
		decision_tree_unit_id,
		l_exp_slot_id,
		l_exp_l_op_bit_string_length,
		l_exp_l_op_chrom_start_index,
		l_exp_op_bit_string_length,
		l_exp_op_chrom_start_index,
		l_exp_r_op_bit_string_length,
		l_exp_r_op_chrom_start_index,
		bool_op_bit_string_length,
		bool_op_chrom_start_index,
		r_exp_slot_id,
		r_exp_l_op_bit_string_length,
		r_exp_l_op_chrom_start_index,
		r_exp_op_bit_string_length,
		r_exp_op_chrom_start_index,
		r_exp_r_op_bit_string_length,
		r_exp_r_op_chrom_start_index,
		l_amt_mult_bit_string_length,
		l_amt_mult_chrom_start_index,
		r_amt_mult_bit_string_length,
		r_amt_mult_chrom_start_index
	)
	SELECT (ROWNUM - 1) decision_tree_unit_id,
	
		   ((ROWNUM - 1) * 2) l_exp_slot_id,
	
		   v_strat_chromosome_metadata.exp_operand_id_bit_length l_exp_l_op_bit_string_length,
		   (((ROWNUM - 1) * v_strat_chromosome_metadata.dec_tree_unit_bit_length)
				+ 1
		   ) l_exp_l_op_chrom_start_index,
		   
		   v_strat_chromosome_metadata.exp_operator_id_bit_length l_exp_op_bit_string_length,
		   (((ROWNUM - 1) * v_strat_chromosome_metadata.dec_tree_unit_bit_length)
				+ v_strat_chromosome_metadata.exp_operand_id_bit_length
				+ 1
		   ) l_exp_op_chrom_start_index,
		   
		   v_strat_chromosome_metadata.exp_operand_id_bit_length l_exp_r_op_bit_string_length,
		   (((ROWNUM - 1) * v_strat_chromosome_metadata.dec_tree_unit_bit_length)
				+ v_strat_chromosome_metadata.exp_operand_id_bit_length
				+ v_strat_chromosome_metadata.exp_operator_id_bit_length
				+ 1
		   ) l_exp_r_op_chrom_start_index,
		   
		   v_strat_chromosome_metadata.bool_operator_bit_length bool_op_bit_string_length,
		   (((ROWNUM - 1) * v_strat_chromosome_metadata.dec_tree_unit_bit_length)
				+ v_strat_chromosome_metadata.expression_bit_length
				+ 1
		   ) bool_op_chrom_start_index,
		   
		   (((ROWNUM - 1) * 2) + 1) r_exp_slot_id,
		   
		   v_strat_chromosome_metadata.exp_operand_id_bit_length r_exp_l_op_bit_string_length,
		   (((ROWNUM - 1) * v_strat_chromosome_metadata.dec_tree_unit_bit_length)
				+ v_strat_chromosome_metadata.expression_bit_length
				+ v_strat_chromosome_metadata.bool_operator_bit_length
				+ 1
		   ) r_exp_l_op_chrom_start_index,
		   
		   v_strat_chromosome_metadata.exp_operator_id_bit_length r_exp_op_bit_string_length,
		   (((ROWNUM - 1) * v_strat_chromosome_metadata.dec_tree_unit_bit_length)
				+ v_strat_chromosome_metadata.expression_bit_length
				+ v_strat_chromosome_metadata.bool_operator_bit_length
				+ v_strat_chromosome_metadata.exp_operand_id_bit_length
				+ 1
		   ) r_exp_op_chrom_start_index,
		   
		   v_strat_chromosome_metadata.exp_operand_id_bit_length r_exp_r_op_bit_string_length,
		   (((ROWNUM - 1) * v_strat_chromosome_metadata.dec_tree_unit_bit_length)
				+ v_strat_chromosome_metadata.expression_bit_length
				+ v_strat_chromosome_metadata.bool_operator_bit_length
				+ v_strat_chromosome_metadata.exp_operand_id_bit_length
				+ v_strat_chromosome_metadata.exp_operator_id_bit_length
				+ 1
		   ) r_exp_r_op_chrom_start_index,
		   
		   v_strat_chromosome_metadata.amount_mult_bit_length l_amt_mult_bit_string_length,
		   (((ROWNUM - 1) * v_strat_chromosome_metadata.dec_tree_unit_bit_length)
				+ v_strat_chromosome_metadata.expression_bit_length
				+ v_strat_chromosome_metadata.bool_operator_bit_length
				+ v_strat_chromosome_metadata.expression_bit_length
				+ 1
		   ) l_amt_mult_chrom_start_index,
		   
		   v_strat_chromosome_metadata.amount_mult_bit_length r_amt_mult_bit_string_length,
		   (((ROWNUM - 1) * v_strat_chromosome_metadata.dec_tree_unit_bit_length)
				+ v_strat_chromosome_metadata.expression_bit_length
				+ v_strat_chromosome_metadata.bool_operator_bit_length
				+ v_strat_chromosome_metadata.expression_bit_length
				+ v_strat_chromosome_metadata.amount_mult_bit_length
				+ 1
		   ) r_amt_mult_chrom_start_index
		   
	FROM   DUAL
	CONNECT BY ROWNUM <= v_strat_chromosome_metadata.dec_tree_unit_slots;

	-- set bit strings	
	UPDATE strategy_build
	SET    l_exp_l_op_bit_string = SUBSTR(p_strategy_chromosome, l_exp_l_op_chrom_start_index, l_exp_l_op_bit_string_length),
		   l_exp_op_bit_string = SUBSTR(p_strategy_chromosome, l_exp_op_chrom_start_index, l_exp_op_bit_string_length),
		   l_exp_r_op_bit_string = SUBSTR(p_strategy_chromosome, l_exp_r_op_chrom_start_index, l_exp_r_op_bit_string_length),
		   bool_op_bit_string = SUBSTR(p_strategy_chromosome, bool_op_chrom_start_index, bool_op_bit_string_length),
		   r_exp_l_op_bit_string = SUBSTR(p_strategy_chromosome, r_exp_l_op_chrom_start_index, r_exp_l_op_bit_string_length),
		   r_exp_op_bit_string = SUBSTR(p_strategy_chromosome, r_exp_op_chrom_start_index, r_exp_op_bit_string_length),
		   r_exp_r_op_bit_string = SUBSTR(p_strategy_chromosome, r_exp_r_op_chrom_start_index, r_exp_r_op_bit_string_length),
		   l_amt_mult_bit_string = SUBSTR(p_strategy_chromosome, l_amt_mult_chrom_start_index, l_amt_mult_bit_string_length),
		   r_amt_mult_bit_string = SUBSTR(p_strategy_chromosome, r_amt_mult_chrom_start_index, r_amt_mult_bit_string_length);
	
	-- set IDs
	UPDATE strategy_build
	SET    l_exp_l_op_id = pkg_ga_util.bit_string_to_unsigned_int(p_bit_string => l_exp_l_op_bit_string),
		   l_exp_op_id = pkg_ga_util.bit_string_to_unsigned_int(p_bit_string => l_exp_op_bit_string),
		   l_exp_r_op_id = pkg_ga_util.bit_string_to_unsigned_int(p_bit_string => l_exp_r_op_bit_string),
		   bool_op_id = pkg_ga_util.bit_string_to_unsigned_int(p_bit_string => bool_op_bit_string),
		   r_exp_l_op_id = pkg_ga_util.bit_string_to_unsigned_int(p_bit_string => r_exp_l_op_bit_string),
		   r_exp_op_id = pkg_ga_util.bit_string_to_unsigned_int(p_bit_string => r_exp_op_bit_string),
		   r_exp_r_op_id = pkg_ga_util.bit_string_to_unsigned_int(p_bit_string => r_exp_r_op_bit_string),
		   l_amt_mult_id = pkg_ga_util.bit_string_to_unsigned_int(p_bit_string => l_amt_mult_bit_string),
		   r_amt_mult_id = pkg_ga_util.bit_string_to_unsigned_int(p_bit_string => r_amt_mult_bit_string);

END load_strategy_build_table;

PROCEDURE execute_strategy(
	p_strategy_procedure strategy.strategy_procedure%TYPE,
	p_seat_number        player_state.seat_number%TYPE,
	p_can_fold           VARCHAR2,
	p_can_check          VARCHAR2,
	p_can_call           VARCHAR2,
	p_can_bet            VARCHAR2,
	p_can_raise          VARCHAR2,
	p_player_move        OUT VARCHAR2,
	p_player_move_amount OUT player_state.money%TYPE
) IS

	v_decision_type INTEGER;
	
BEGIN

	v_decision_type := pkg_ga_player.get_decision_type(
		p_can_fold  => p_can_fold,
		p_can_check => p_can_check,
		p_can_call  => p_can_call,
		p_can_bet   => p_can_bet,
		p_can_raise => p_can_raise
	);

	EXECUTE IMMEDIATE p_strategy_procedure USING
		IN v_decision_type,
		IN p_can_fold,
		IN p_can_check,
		IN p_can_call,
		IN p_can_bet,
		IN p_can_raise,
		IN p_seat_number,
		OUT p_player_move,
		OUT p_player_move_amount;
	
END execute_strategy;

FUNCTION get_decision_type(
	p_can_fold  VARCHAR2,
	p_can_check VARCHAR2,
	p_can_call  VARCHAR2,
	p_can_bet   VARCHAR2,
	p_can_raise VARCHAR2
) RETURN INTEGER RESULT_CACHE IS
BEGIN

	-- TYPE_ID CAN_FOLD CAN_CHECK CAN_CALL CAN_BET CAN_RAISE
	-- -----------------------------------------------------
	--       0        Y         Y        N       Y         N
	--       1        Y         Y        N       N         Y
	--       2        Y         Y        N       N         N
	--       3        Y         N        Y       N         Y
	--       4        Y         N        Y       N         N
	--       5        N         N        N       N         N
	
	IF p_can_fold = 'Y' AND p_can_check = 'Y' AND p_can_call = 'N' AND p_can_bet = 'Y' AND p_can_raise = 'N' THEN
		RETURN 0;
	ELSIF p_can_fold = 'Y' AND p_can_check = 'Y' AND p_can_call = 'N' AND p_can_bet = 'N' AND p_can_raise = 'Y' THEN
		RETURN 1;
	ELSIF p_can_fold = 'Y' AND p_can_check = 'Y' AND p_can_call = 'N' AND p_can_bet = 'N' AND p_can_raise = 'N' THEN
		RETURN 2;
	ELSIF p_can_fold = 'Y' AND p_can_check = 'N' AND p_can_call = 'Y' AND p_can_bet = 'N' AND p_can_raise = 'Y' THEN
		RETURN 3;
	ELSIF p_can_fold = 'Y' AND p_can_check = 'N' AND p_can_call = 'Y' AND p_can_bet = 'N' AND p_can_raise = 'N' THEN
		RETURN 4;
	ELSIF p_can_fold = 'N' AND p_can_check = 'N' AND p_can_call = 'N' AND p_can_bet = 'N' AND p_can_raise = 'N' THEN
		RETURN 5;
	ELSE
		RETURN NULL;
	END IF;
		
END get_decision_type;

PROCEDURE update_strategy_fitness (
	p_fitness_test_id strategy_fitness.fitness_test_id%TYPE
) IS

	v_perf_strat_fitness_update VARCHAR2(1);
	v_min_average_game_profit   strategy_fitness.average_game_profit%TYPE;
	
BEGIN

	SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END perf_strat_fitness_update
	INTO   v_perf_strat_fitness_update
	FROM   player_state
	WHERE  current_strategy_id IS NOT NULL;
	
	IF v_perf_strat_fitness_update = 'Y' THEN
	
		pkg_poker_ai.log(p_message => 'updating strategy fitness statistics');
		
		-- update aggregate strategy fitness values
		MERGE INTO strategy_fitness d USING (
			SELECT *
			FROM   player_state
		) s ON (
			d.strategy_id = s.current_strategy_id
			AND d.fitness_test_id = p_fitness_test_id
		) WHEN MATCHED THEN UPDATE SET
			d.tournaments_played = d.tournaments_played + 1,
			d.games_played = d.games_played + s.games_played,
			d.main_pots_won = d.main_pots_won + s.main_pots_won,
			d.main_pots_split = d.main_pots_split + s.main_pots_split,
			d.side_pots_won = d.side_pots_won + s.side_pots_won,
			d.side_pots_split = d.side_pots_split + s.side_pots_split,
			d.flops_seen = d.flops_seen + s.flops_seen,
			d.turns_seen = d.turns_seen + s.turns_seen,
			d.rivers_seen = d.rivers_seen + s.rivers_seen,
			d.pre_flop_folds = d.pre_flop_folds + s.pre_flop_folds,
			d.flop_folds = d.flop_folds + s.flop_folds,
			d.turn_folds = d.turn_folds + s.turn_folds,
			d.river_folds = d.river_folds + s.river_folds,
			d.total_folds = d.total_folds + s.total_folds,
			d.pre_flop_checks = d.pre_flop_checks + s.pre_flop_checks,
			d.flop_checks = d.flop_checks + s.flop_checks,
			d.turn_checks = d.turn_checks + s.turn_checks,
			d.river_checks = d.river_checks + s.river_checks,
			d.total_checks = d.total_checks + s.total_checks,
			d.pre_flop_calls = d.pre_flop_calls + s.pre_flop_calls,
			d.flop_calls = d.flop_calls + s.flop_calls,
			d.turn_calls = d.turn_calls + s.turn_calls,
			d.river_calls = d.river_calls + s.river_calls,
			d.total_calls = d.total_calls + s.total_calls,
			d.pre_flop_bets = d.pre_flop_bets + s.pre_flop_bets,
			d.flop_bets = d.flop_bets + s.flop_bets,
			d.turn_bets = d.turn_bets + s.turn_bets,
			d.river_bets = d.river_bets + s.river_bets,
			d.total_bets = d.total_bets + s.total_bets,
			d.pre_flop_total_bet_amount = d.pre_flop_total_bet_amount + s.pre_flop_total_bet_amount,
			d.flop_total_bet_amount = d.flop_total_bet_amount + s.flop_total_bet_amount,
			d.turn_total_bet_amount = d.turn_total_bet_amount + s.turn_total_bet_amount,
			d.river_total_bet_amount = d.river_total_bet_amount + s.river_total_bet_amount,
			d.total_bet_amount = d.total_bet_amount + s.total_bet_amount,
			d.pre_flop_raises = d.pre_flop_raises + s.pre_flop_raises,
			d.flop_raises = d.flop_raises + s.flop_raises,
			d.turn_raises = d.turn_raises + s.turn_raises,
			d.river_raises = d.river_raises + s.river_raises,
			d.total_raises = d.total_raises + s.total_raises,
			d.pre_flop_total_raise_amount = d.pre_flop_total_raise_amount + s.pre_flop_total_raise_amount,
			d.flop_total_raise_amount = d.flop_total_raise_amount + s.flop_total_raise_amount,
			d.turn_total_raise_amount = d.turn_total_raise_amount + s.turn_total_raise_amount,
			d.river_total_raise_amount = d.river_total_raise_amount + s.river_total_raise_amount,
			d.total_raise_amount = d.total_raise_amount + s.total_raise_amount,
			d.times_all_in = d.times_all_in + s.times_all_in,
			d.total_money_played = d.total_money_played + s.total_money_played,
			d.total_money_won = d.total_money_won + s.total_money_won
		WHEN NOT MATCHED THEN INSERT (
			strategy_id,
			fitness_test_id,
			tournaments_played,
			games_played,
			main_pots_won,
			main_pots_split,
			side_pots_won,
			side_pots_split,
			flops_seen,
			turns_seen,
			rivers_seen,
			pre_flop_folds,
			flop_folds,
			turn_folds,
			river_folds,
			total_folds,
			pre_flop_checks,
			flop_checks,
			turn_checks,
			river_checks,
			total_checks,
			pre_flop_calls,
			flop_calls,
			turn_calls,
			river_calls,
			total_calls,
			pre_flop_bets,
			flop_bets,
			turn_bets,
			river_bets,
			total_bets,
			pre_flop_total_bet_amount,
			flop_total_bet_amount,
			turn_total_bet_amount,
			river_total_bet_amount,
			total_bet_amount,
			pre_flop_raises,
			flop_raises,
			turn_raises,
			river_raises,
			total_raises,
			pre_flop_total_raise_amount,
			flop_total_raise_amount,
			turn_total_raise_amount,
			river_total_raise_amount,
			total_raise_amount,
			times_all_in,
			total_money_played,
			total_money_won
		) VALUES (
			s.current_strategy_id,    -- strategy_id,
			p_fitness_test_id,        -- fitness_test_id
			1,                        -- tournaments_played,
			s.games_played,
			s.main_pots_won,
			s.main_pots_split,
			s.side_pots_won,
			s.side_pots_split,
			s.flops_seen,
			s.turns_seen,
			s.rivers_seen,
			s.pre_flop_folds,
			s.flop_folds,
			s.turn_folds,
			s.river_folds,
			s.total_folds,
			s.pre_flop_checks,
			s.flop_checks,
			s.turn_checks,
			s.river_checks,
			s.total_checks,
			s.pre_flop_calls,
			s.flop_calls,
			s.turn_calls,
			s.river_calls,
			s.total_calls,
			s.pre_flop_bets,
			s.flop_bets,
			s.turn_bets,
			s.river_bets,
			s.total_bets,
			s.pre_flop_total_bet_amount,
			s.flop_total_bet_amount,
			s.turn_total_bet_amount,
			s.river_total_bet_amount,
			s.total_bet_amount,
			s.pre_flop_raises,
			s.flop_raises,
			s.turn_raises,
			s.river_raises,
			s.total_raises,
			s.pre_flop_total_raise_amount,
			s.flop_total_raise_amount,
			s.turn_total_raise_amount,
			s.river_total_raise_amount,
			s.total_raise_amount,
			s.times_all_in,
			s.total_money_played,
			s.total_money_won
		);

		-- udpate averages dependent on newly updated aggregate values
		MERGE INTO strategy_fitness d USING (
			SELECT *
			FROM   player_state
		) s ON (
			d.strategy_id = s.current_strategy_id
			AND d.fitness_test_id = p_fitness_test_id
		) WHEN MATCHED THEN UPDATE SET
			d.average_tournament_profit = (d.total_money_won - d.total_money_played) / NULLIF(d.tournaments_played, 0),
			d.average_game_profit = (d.total_money_won - d.total_money_played) / NULLIF(d.games_played, 0),
			d.pre_flop_average_bet_amount = d.pre_flop_total_bet_amount / NULLIF(d.pre_flop_bets, 0),
			d.flop_average_bet_amount = d.flop_total_bet_amount / NULLIF(d.flop_bets, 0),
			d.turn_average_bet_amount = d.turn_total_bet_amount / NULLIF(d.turn_bets, 0),
			d.river_average_bet_amount = d.river_total_bet_amount / NULLIF(d.river_bets, 0),
			d.average_bet_amount = d.total_bet_amount / NULLIF(d.total_bets, 0),
			d.pre_flop_average_raise_amount = d.pre_flop_total_raise_amount / NULLIF(d.pre_flop_raises, 0),
			d.flop_average_raise_amount = d.flop_total_raise_amount / NULLIF(d.flop_raises, 0),
			d.turn_average_raise_amount = d.turn_total_raise_amount / NULLIF(d.turn_raises, 0),
			d.river_average_raise_amount = d.river_total_raise_amount / NULLIF(d.river_raises, 0),
			d.average_raise_amount = d.total_raise_amount / NULLIF(d.total_raises, 0);

		-- normalize fitness scores for the fitness test group to be a value >= 0
		SELECT MIN(average_game_profit) min_average_game_profit
		INTO   v_min_average_game_profit
		FROM   strategy_fitness
		WHERE  fitness_test_id = p_fitness_test_id
		   AND average_game_profit < 0;
		   
		UPDATE strategy_fitness
		SET    fitness_score = NVL(ABS(v_min_average_game_profit), 0) + average_game_profit
		WHERE  fitness_test_id = p_fitness_test_id;

	END IF;
	
END update_strategy_fitness;

PROCEDURE create_new_generation(
	p_from_generation     strategy.generation%TYPE,
	p_fitness_test_id     strategy_fitness.fitness_test_id%TYPE,
	p_new_generation_size INTEGER,
	p_crossover_rate      NUMBER,
	p_crossover_point     INTEGER,
	p_mutation_rate       NUMBER
) IS
BEGIN

	FOR v_rec IN (
	
		-- current generation attributes
		WITH current_generation AS (
			SELECT /*+ MATERIALIZE */
				   s.strategy_id,
				   s.strategy_chromosome,
				   sf.fitness_score
			FROM   strategy s,
				   strategy_fitness sf
			WHERE  s.generation = p_from_generation
			   AND s.strategy_id = sf.strategy_id
			   AND sf.fitness_test_id = p_fitness_test_id
		),

		-- total fitness of current generation
		total_fitness AS (
			SELECT /*+ MATERIALIZE */
				   SUM(fitness_score) total_fitness_score
			FROM   current_generation
		),
		
		-- fitness proportion of each strategy in current generation
		proportioned_generation AS (
			SELECT /*+ MATERIALIZE */
				   cg.strategy_id,
				   (cg.fitness_score / NULLIF(tf.total_fitness_score, 0)) fitness_proportion,
				   DENSE_RANK() OVER (ORDER BY cg.fitness_score / NULLIF(tf.total_fitness_score, 0), cg.strategy_id) strategy_rank
			FROM   current_generation cg,
				   total_fitness tf
		),
		
		-- fitness proportion limits of each strategy in current generation
		proportion_limits AS (
			SELECT /*+ MATERIALIZE */
				   pg_b.strategy_id,
				   SUM(CASE WHEN pg_a.strategy_rank < pg_b.strategy_rank THEN pg_a.fitness_proportion END) lower_limit,
				   (SUM(CASE WHEN pg_a.strategy_rank < pg_b.strategy_rank THEN pg_a.fitness_proportion END) + pg_b.fitness_proportion) upper_limit
			FROM   proportioned_generation pg_a,
				   proportioned_generation pg_b
			WHERE  pg_b.fitness_proportion > 0
			GROUP BY
				pg_b.strategy_id,
				pg_b.fitness_proportion
		),
		
		-- random numbers to represent parent selection from current generation
		random_parent_numbers AS (
			SELECT /*+ MATERIALIZE */
				   CASE WHEN DBMS_RANDOM.VALUE < p_crossover_rate THEN 'Y' ELSE 'N' END perform_crossover,
				   DBMS_RANDOM.VALUE parent_a_rand,
				   DBMS_RANDOM.VALUE parent_b_rand
			FROM   DUAL
			CONNECT BY ROWNUM <= p_new_generation_size / 2
		),

		-- roulette wheel selection of parent strategies from current generation
		parent_strategy_ids AS (
			SELECT /*+ MATERIALIZE */
				   rpn.perform_crossover,
				   pl_a.strategy_id parent_a,
				   pl_b.strategy_id parent_b
			FROM   random_parent_numbers rpn,
				   proportion_limits pl_a,
				   proportion_limits pl_b
			WHERE  pl_a.lower_limit <= rpn.parent_a_rand
			   AND pl_a.upper_limit > rpn.parent_a_rand
			   AND pl_b.lower_limit <= rpn.parent_b_rand
			   AND pl_b.upper_limit > rpn.parent_b_rand
		),
		
		-- selected parent chromosomes
		parent_chromosomes AS (
			SELECT psi.perform_crossover,
				   cg_a.strategy_chromosome parent_a_chromosome,
				   cg_b.strategy_chromosome parent_b_chromosome
			FROM   parent_strategy_ids psi,
				   strategy cg_a,
				   strategy cg_b
			WHERE  psi.parent_a = cg_a.strategy_id
			   AND psi.parent_b = cg_b.strategy_id
		),
		
		-- parent chromosome crossover to form children
		crossed_over AS (
			SELECT CASE WHEN perform_crossover = 'N' THEN parent_a_chromosome
						ELSE SUBSTR(parent_a_chromosome, 1, p_crossover_point) || SUBSTR(parent_b_chromosome, p_crossover_point + 1)
				   END child_a_chromosome,
				   CASE WHEN perform_crossover = 'N' THEN parent_b_chromosome
						ELSE SUBSTR(parent_b_chromosome, 1, p_crossover_point) || SUBSTR(parent_a_chromosome, p_crossover_point + 1)
				   END child_b_chromosome
			FROM   parent_chromosomes
		)
		
		-- mutated children
		SELECT pkg_ga_util.mutate_chromosome(p_chromosome => child_a_chromosome, p_mutation_rate => p_mutation_rate) child_a_chromosome,
			   pkg_ga_util.mutate_chromosome(p_chromosome => child_b_chromosome, p_mutation_rate => p_mutation_rate) child_b_chromosome
		FROM   crossed_over
		
	) LOOP
	
		-- child a
		INSERT INTO strategy (
			strategy_id,
			generation,
			strategy_chromosome,
			strategy_procedure
		) VALUES (	
			pai_seq_stratid.NEXTVAL,
			p_from_generation + 1,
			v_rec.child_a_chromosome,
			pkg_ga_player.get_strategy_procedure(p_strategy_chromosome => v_rec.child_a_chromosome)
		);
		
		-- child b
		INSERT INTO strategy (
			strategy_id,
			generation,
			strategy_chromosome,
			strategy_procedure
		) VALUES (	
			pai_seq_stratid.NEXTVAL,
			p_from_generation + 1,
			v_rec.child_b_chromosome,
			pkg_ga_player.get_strategy_procedure(p_strategy_chromosome => v_rec.child_b_chromosome)
		);
	
	END LOOP;
	
END create_new_generation;

BEGIN

	-- package variables initialization
	
	v_strat_chromosome_metadata.exp_operand_id_bit_length := 10;
	v_strat_chromosome_metadata.exp_operator_id_bit_length := 2;
	v_strat_chromosome_metadata.bool_operator_bit_length := 3;
	v_strat_chromosome_metadata.amount_mult_bit_length := 8;
	v_strat_chromosome_metadata.stack_depth := 8;
	
	v_strat_chromosome_metadata.expression_bit_length := (2 * v_strat_chromosome_metadata.exp_operand_id_bit_length)
		+ v_strat_chromosome_metadata.exp_operator_id_bit_length;
	v_strat_chromosome_metadata.dec_tree_unit_bit_length := (2 * v_strat_chromosome_metadata.expression_bit_length)
		+ v_strat_chromosome_metadata.bool_operator_bit_length
		+ (2 * v_strat_chromosome_metadata.amount_mult_bit_length);
	v_strat_chromosome_metadata.dec_tree_unit_slots := POWER(2, v_strat_chromosome_metadata.stack_depth - 1) - 1;
	v_strat_chromosome_metadata.chromosome_bit_length := v_strat_chromosome_metadata.dec_tree_unit_bit_length * v_strat_chromosome_metadata.dec_tree_unit_slots;
	v_strat_chromosome_metadata.expression_slot_id_count := 2 * v_strat_chromosome_metadata.dec_tree_unit_slots;

END pkg_ga_player;
