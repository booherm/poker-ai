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
			   player p,
			   strategy s
		WHERE  ps.seat_number = p_seat_number
		   AND ps.player_id = p.player_id
		   AND p.current_strategy_id = s.strategy_id (+);
		   
		EXCEPTION WHEN NO_DATA_FOUND THEN
			NULL;
	END;
	
	IF v_strategy_procedure IS NOT NULL THEN
		pkg_poker_ai.log(p_message => 'deriving move from strategy procedure');
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
		pkg_poker_ai.log(p_message => 'performing random move');
		
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

	v_procedure_plsql VARCHAR2(32000);
	v_variables_sql   VARCHAR2(32000);
	
BEGIN

	-- convert chromosome to strategy table
	pkg_ga_player.load_strategy_build_table(p_strategy_chromosome => p_strategy_chromosome);
	
	-- build strategy procedure as anonymous block
	v_procedure_plsql := '
DECLARE

	v_seat_number        player_state.seat_number%TYPE := :1;
	v_decision_type      INTEGER := :2;
	v_amount_multiplier  NUMBER := 1.0;
	v_player_move        VARCHAR2(30);
	v_player_move_amount player_state.money%TYPE;

BEGIN

';

	v_procedure_plsql := v_procedure_plsql || pkg_ga_player.get_expression_loader || CHR(13);
	
	v_procedure_plsql := v_procedure_plsql || pkg_ga_player.get_decision_tree (
		p_decision_tree_unit_id => 0,
		p_max_depth             => v_strat_chromosome_metadata.stack_depth
	);
	
	v_procedure_plsql := v_procedure_plsql || '
	
	:3 := v_player_move;
	:4 := v_player_move_amount;
	
END;
';

	RETURN v_procedure_plsql;
	
END get_strategy_procedure;

FUNCTION get_expression_loader RETURN VARCHAR2 IS

	v_plsql VARCHAR2(32000);
	
BEGIN

	v_plsql := pkg_ga_util.indent(p_level => 1) || 'DELETE FROM strategy_expression_map;' || CHR(13)
		|| pkg_ga_util.indent(p_level => 1) || 'INSERT INTO strategy_expression_map (' || CHR(13)
		|| pkg_ga_util.indent(p_level => 2) || 'expression_slot_id,' || CHR(13)
		|| pkg_ga_util.indent(p_level => 2) || 'left_operand_id,' || CHR(13)
		|| pkg_ga_util.indent(p_level => 2) || 'operator_id,' || CHR(13)
		|| pkg_ga_util.indent(p_level => 2) || 'right_operand_id' || CHR(13)
		|| pkg_ga_util.indent(p_level => 1) || ')' || CHR(13);
	
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
	
		IF v_rec.expression_slot_id != 0 THEN
			v_plsql := v_plsql || ' UNION ALL' || CHR(13);
		END IF;
		
		v_plsql := v_plsql
			|| pkg_ga_util.indent(p_level => 1) || 'SELECT ' || v_rec.expression_slot_id || ' expression_slot_id, '
			|| v_rec.left_operand_id || ' left_operand_id, '
			|| v_rec.operator_id || ' operator_id, '
			|| v_rec.right_operand_id || ' right_operand_id FROM DUAL';
		
	END LOOP;
	
	v_plsql := v_plsql || ';' || CHR(13);
	
	RETURN v_plsql;
		
END get_expression_loader;

FUNCTION get_decision_tree (
	p_decision_tree_unit_id strategy_build.decision_tree_unit_id%TYPE,
	p_max_depth             INTEGER
) RETURN VARCHAR2 IS

	v_depth                    INTEGER;
	v_decision_tree            VARCHAR2(32000);
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
			|| pkg_ga_util.indent(p_level => v_depth + 2) || 'p_seat_number       => v_seat_number,' || CHR(13)
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
			v_decision_tree := pkg_ga_util.indent(p_level => v_depth + 1) || 'IF pkg_ga_player.get_expression_value(p_expression_id => ' || v_rec.l_exp_l_op_id || ') ';
				
			-- left expression operator and right operand
			v_expression_operator_text := pkg_ga_player.get_expression_operator_text(p_expression_operator_id => v_rec.l_exp_op_id);
			IF v_expression_operator_text = '/' THEN
				v_decision_tree := v_decision_tree || '/ NVL(NULLIF(pkg_ga_player.get_expression_value(p_expression_id => ' || v_rec.l_exp_r_op_id || '), 0), 1) ';
			ELSE
				v_decision_tree := v_decision_tree || v_expression_operator_text || ' pkg_ga_player.get_expression_value(p_expression_id => ' || v_rec.l_exp_r_op_id || ') ';
			END IF;
				
			-- boolean operator
			v_decision_tree := v_decision_tree || pkg_ga_player.get_boolean_operator_text(p_boolean_operator_id => v_rec.bool_op_id) || ' ';
			
			-- right expression left operand
			v_decision_tree := v_decision_tree || 'pkg_ga_player.get_expression_value(p_expression_id => ' || v_rec.r_exp_l_op_id || ') ';
			
			-- right expression operator and right operand
			v_expression_operator_text := pkg_ga_player.get_expression_operator_text(p_expression_operator_id => v_rec.r_exp_op_id);
			IF v_expression_operator_text = '/' THEN
				v_decision_tree := v_decision_tree || '/ NVL(NULLIF(pkg_ga_player.get_expression_value(p_expression_id => ' || v_rec.r_exp_r_op_id || '), 0), 1) ';
			ELSE
				v_decision_tree := v_decision_tree || v_expression_operator_text || ' pkg_ga_player.get_expression_value(p_expression_id => ' || v_rec.r_exp_r_op_id || ') ';
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
	p_expression_id strategy_expression_map.expression_slot_id%TYPE
) RETURN strategy_variable.value%TYPE IS

	v_expression_id  strategy_expression_map.expression_slot_id%TYPE;
	v_value          strategy_variable.value%TYPE;
	v_referenced_ids t_expression_map_entries;
	
BEGIN

	-- if expression id is outside the upper bounds of the expression and variables, circle back to start
	v_expression_id := MOD(p_expression_id, v_public_variable_count + v_strat_chromosome_metadata.expression_slot_id_count);
	--DBMS_OUTPUT.PUT_LINE('get_expression_value: start v_expression_id = ' || v_expression_id);
	
	IF v_expression_id < v_strat_chromosome_metadata.expression_slot_id_count THEN
	
		-- refers to another expression
		--DBMS_OUTPUT.PUT_LINE('get_expression_value: refers to another expression, calling get_sub_expression_value');
		v_referenced_ids(v_expression_id) := v_expression_id;
		v_value := pkg_ga_player.get_sub_expression_value(
			p_expression_id  => v_expression_id,
			p_referenced_ids => v_referenced_ids
		);
		
	ELSE
	
		-- refers to a variable
		SELECT value
		INTO   v_value
		FROM   strategy_variable
		WHERE  variable_id = v_expression_id;
		--DBMS_OUTPUT.PUT_LINE('get_expression_value: refers to a variable, returning value ' || v_value);
		
	END IF;
	
	RETURN v_value;

END get_expression_value;

FUNCTION get_sub_expression_value(
	p_expression_id  strategy_expression_map.expression_slot_id%TYPE,
	p_referenced_ids IN OUT t_expression_map_entries
) RETURN strategy_variable.value%TYPE IS

	v_expression_id       strategy_expression_map.expression_slot_id%TYPE;
	v_value               strategy_variable.value%TYPE;

	v_left_operand_id     strategy_expression_map.left_operand_id%TYPE;
	v_operator_value      VARCHAR2(1);
	v_right_operand_id    strategy_expression_map.right_operand_id%TYPE;
	v_left_operand_value  strategy_variable.value%TYPE;
	v_right_operand_value strategy_variable.value%TYPE;
	
BEGIN

	-- if expression id is outside the upper bounds of the expression and variables, circle back to start
	v_expression_id := MOD(p_expression_id, v_public_variable_count + v_strat_chromosome_metadata.expression_slot_id_count);
	--DBMS_OUTPUT.PUT_LINE('get_sub_expression_value: start v_expression_id = ' || v_expression_id);
	
	IF v_expression_id < v_strat_chromosome_metadata.expression_slot_id_count THEN
	
		-- refers to another expression
		--DBMS_OUTPUT.PUT_LINE('get_sub_expression_value: refers to another expression, looking up expression');
		SELECT MOD(left_operand_id, v_public_variable_count + v_strat_chromosome_metadata.expression_slot_id_count) left_operand_id,
			   pkg_ga_player.get_expression_operator_text(p_expression_operator_id => operator_id) operator_value,
			   MOD(right_operand_id, v_public_variable_count + v_strat_chromosome_metadata.expression_slot_id_count) right_operand_id
		INTO   v_left_operand_id,
			   v_operator_value,
			   v_right_operand_id
		FROM   strategy_expression_map
		WHERE  expression_slot_id = v_expression_id;
		
		IF p_referenced_ids.EXISTS(v_left_operand_id) THEN
			--DBMS_OUTPUT.PUT_LINE('get_sub_expression_value: found circular reference, replacing with safe value');
			IF v_operator_value IN ('+', '-') THEN
				v_left_operand_value := 0;
			ELSE
				v_left_operand_value := 1;
			END IF;
		ELSE
			p_referenced_ids(v_left_operand_id) := v_left_operand_id;
			v_left_operand_value := pkg_ga_player.get_sub_expression_value(
				p_expression_id  => v_left_operand_id,
				p_referenced_ids => p_referenced_ids
			);
		END IF;
			
		IF p_referenced_ids.EXISTS(v_right_operand_id) THEN
			--DBMS_OUTPUT.PUT_LINE('get_sub_expression_value: found circular reference, replacing with safe value');
			IF v_operator_value IN ('+', '-') THEN
				v_right_operand_value := 0;
			ELSE
				v_right_operand_value := 1;
			END IF;
		ELSE
			p_referenced_ids(v_right_operand_id) := v_right_operand_id;
			v_right_operand_value := pkg_ga_player.get_sub_expression_value(
				p_expression_id  => v_right_operand_id,
				p_referenced_ids => p_referenced_ids
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
		
		--DBMS_OUTPUT.PUT_LINE('get_sub_expression_value: returning derived value ' || v_value);
		
	ELSE
	
		-- refers to a variable
		SELECT value
		INTO   v_value
		FROM   strategy_variable
		WHERE  variable_id = v_expression_id;
		--DBMS_OUTPUT.PUT_LINE('get_sub_expression_value: refers to a variable, returning value ' || v_value);
		
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
) RETURN VARCHAR2 IS
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
) RETURN VARCHAR2 IS
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
) RETURN VARCHAR2 IS

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

	v_variables_sql VARCHAR2(32000);
	v_decision_type INTEGER;
	
BEGIN

	-- load strategy execution variables table
	v_variables_sql := '
INSERT INTO strategy_variable (
	variable_id,
	variable_name,
	value
)

WITH seats AS (
	SELECT ROWNUM seat_number
	FROM   DUAL
	CONNECT BY ROWNUM <= ' || pkg_poker_ai.v_max_player_count || '
),

players AS (
	SELECT s.seat_number,
		   NVL(ps.player_id, -1) player_id,
		   NVL(ps.money, -1) money,
		   NVL(mfv.numeric_value, -1) state
	FROM   seats s,
		   player_state ps,
		   master_field_value mfv
	WHERE  s.seat_number = ps.seat_number (+)
	   AND mfv.field_name_code (+) = ''PLAYER_STATE''
	   AND ps.state = mfv.field_value_code (+)
),

variables AS (
';
	FOR v_i IN 1 .. pkg_poker_ai.v_max_player_count LOOP
		v_variables_sql := v_variables_sql || '
	SELECT ''PLAYER_STATE_SEAT_' || LPAD(v_i, 2, '0') || '.PLAYER_ID'' variable_name, player_id value FROM players WHERE seat_number = ' || v_i || ' UNION ALL
	SELECT ''PLAYER_STATE_SEAT_' || LPAD(v_i, 2, '0') || '.MONEY''     variable_name, money     value FROM players WHERE seat_number = ' || v_i || ' UNION ALL
	SELECT ''PLAYER_STATE_SEAT_' || LPAD(v_i, 2, '0') || '.STATE''     variable_name, state     value FROM players WHERE seat_number = ' || v_i || ' UNION ALL
';
	END LOOP;
	v_variables_sql := v_variables_sql || '
	SELECT ''TOURNAMENT_STATE.PLAYER_COUNT''        variable_name, player_count                  value FROM tournament_state UNION ALL
	SELECT ''TOURNAMENT_STATE.BUY_IN_AMOUNT''       variable_name, buy_in_amount                 value FROM tournament_state UNION ALL
	SELECT ''TOURNAMENT_STATE.CURRENT_GAME_NUMBER'' variable_name, current_game_number           value FROM tournament_state UNION ALL
	SELECT ''GAME_STATE.SMALL_BLIND_SEAT_NUMBER''   variable_name, small_blind_seat_number       value FROM game_state UNION ALL
	SELECT ''GAME_STATE.BIG_BLIND_SEAT_NUMBER''     variable_name, big_blind_seat_number         value FROM game_state UNION ALL
	SELECT ''GAME_STATE.TURN_SEAT_NUMBER''          variable_name, turn_seat_number              value FROM game_state UNION ALL
	SELECT ''GAME_STATE.SMALL_BLIND_VALUE''         variable_name, small_blind_value             value FROM game_state UNION ALL
	SELECT ''GAME_STATE.BIG_BLIND_VALUE''           variable_name, big_blind_value               value FROM game_state UNION ALL
	SELECT ''GAME_STATE.BETTING_ROUND_NUMBER''      variable_name, NVL(betting_round_number, -1) value FROM game_state UNION ALL
	SELECT ''GAME_STATE.LAST_TO_RAISE_SEAT_NUMBER'' variable_name, last_to_raise_seat_number     value FROM game_state UNION ALL
	SELECT ''GAME_STATE.MIN_RAISE_AMOUNT''          variable_name, min_raise_amount              value FROM game_state UNION ALL
	SELECT ''GAME_STATE.COMMUNITY_CARD_1''          variable_name, community_card_1              value FROM game_state UNION ALL
	SELECT ''GAME_STATE.COMMUNITY_CARD_2''          variable_name, community_card_2              value FROM game_state UNION ALL
	SELECT ''GAME_STATE.COMMUNITY_CARD_3''          variable_name, community_card_3              value FROM game_state UNION ALL
	SELECT ''GAME_STATE.COMMUNITY_CARD_4''          variable_name, community_card_4              value FROM game_state UNION ALL
	SELECT ''GAME_STATE.COMMUNITY_CARD_5''          variable_name, community_card_5              value FROM game_state UNION ALL
	SELECT ''DECISION_TYPE.CAN_FOLD''               variable_name, ' || CASE WHEN p_can_fold  = 'Y' THEN '1' ELSE '0' END || ' value FROM DUAL UNION ALL
	SELECT ''DECISION_TYPE.CAN_CHECK''              variable_name, ' || CASE WHEN p_can_check = 'Y' THEN '1' ELSE '0' END || ' value FROM DUAL UNION ALL
	SELECT ''DECISION_TYPE.CAN_CALL''               variable_name, ' || CASE WHEN p_can_call  = 'Y' THEN '1' ELSE '0' END || ' value FROM DUAL UNION ALL
	SELECT ''DECISION_TYPE.CAN_BET''                variable_name, ' || CASE WHEN p_can_bet   = 'Y' THEN '1' ELSE '0' END || ' value FROM DUAL UNION ALL
	SELECT ''DECISION_TYPE.CAN_RAISE''              variable_name, ' || CASE WHEN p_can_raise = 'Y' THEN '1' ELSE '0' END || ' value FROM DUAL UNION ALL
	SELECT ''CONSTANT 000.0''                       variable_name, 000.0                         value FROM DUAL UNION ALL
	SELECT ''CONSTANT 000.1''                       variable_name, 000.1                         value FROM DUAL UNION ALL
	SELECT ''CONSTANT 000.2''                       variable_name, 000.2                         value FROM DUAL UNION ALL
	SELECT ''CONSTANT 000.3''                       variable_name, 000.3                         value FROM DUAL UNION ALL
	SELECT ''CONSTANT 000.4''                       variable_name, 000.4                         value FROM DUAL UNION ALL
	SELECT ''CONSTANT 000.5''                       variable_name, 000.5                         value FROM DUAL UNION ALL
	SELECT ''CONSTANT 000.6''                       variable_name, 000.6                         value FROM DUAL UNION ALL
	SELECT ''CONSTANT 000.7''                       variable_name, 000.7                         value FROM DUAL UNION ALL
	SELECT ''CONSTANT 000.9''                       variable_name, 000.9                         value FROM DUAL UNION ALL
	SELECT ''CONSTANT 001.0''                       variable_name, 001.0                         value FROM DUAL UNION ALL
	SELECT ''CONSTANT 002.0''                       variable_name, 002.0                         value FROM DUAL UNION ALL
	SELECT ''CONSTANT 003.0''                       variable_name, 003.0                         value FROM DUAL UNION ALL
	SELECT ''CONSTANT 004.0''                       variable_name, 004.0                         value FROM DUAL UNION ALL
	SELECT ''CONSTANT 005.0''                       variable_name, 005.0                         value FROM DUAL UNION ALL
	SELECT ''CONSTANT 006.0''                       variable_name, 006.0                         value FROM DUAL UNION ALL
	SELECT ''CONSTANT 007.0''                       variable_name, 007.0                         value FROM DUAL UNION ALL
	SELECT ''CONSTANT 008.0''                       variable_name, 008.0                         value FROM DUAL UNION ALL
	SELECT ''CONSTANT 009.0''                       variable_name, 009.0                         value FROM DUAL UNION ALL
	SELECT ''CONSTANT 010.0''                       variable_name, 010.0                         value FROM DUAL UNION ALL
	SELECT ''CONSTANT 020.0''                       variable_name, 020.0                         value FROM DUAL UNION ALL
	SELECT ''CONSTANT 030.0''                       variable_name, 030.0                         value FROM DUAL UNION ALL
	SELECT ''CONSTANT 040.0''                       variable_name, 040.0                         value FROM DUAL UNION ALL
	SELECT ''CONSTANT 050.0''                       variable_name, 050.0                         value FROM DUAL UNION ALL
	SELECT ''CONSTANT 060.0''                       variable_name, 060.0                         value FROM DUAL UNION ALL
	SELECT ''CONSTANT 070.0''                       variable_name, 070.0                         value FROM DUAL UNION ALL
	SELECT ''CONSTANT 080.0''                       variable_name, 080.0                         value FROM DUAL UNION ALL
	SELECT ''CONSTANT 090.0''                       variable_name, 090.0                         value FROM DUAL UNION ALL
	SELECT ''CONSTANT 100.0''                       variable_name, 100.0                         value FROM DUAL
),

sorted_variables AS (
	SELECT variable_name,
		   value
	FROM   variables
	ORDER BY variable_name
)

SELECT ((ROWNUM - 1) + ' || v_strat_chromosome_metadata.expression_slot_id_count || ') variable_id,
	   variable_name,
	   value
FROM   sorted_variables
';
	
	DELETE FROM strategy_variable;
	EXECUTE IMMEDIATE v_variables_sql;
	v_public_variable_count := SQL%ROWCOUNT;
	
	v_decision_type := pkg_ga_player.get_decision_type(
		p_can_fold  => p_can_fold,
		p_can_check => p_can_check,
		p_can_call  => p_can_call,
		p_can_bet   => p_can_bet,
		p_can_raise => p_can_raise
	);

	EXECUTE IMMEDIATE p_strategy_procedure USING
		IN p_seat_number,
		IN v_decision_type,
		OUT p_player_move,
		OUT p_player_move_amount;
	
END execute_strategy;

FUNCTION get_decision_type(
	p_can_fold  VARCHAR2,
	p_can_check VARCHAR2,
	p_can_call  VARCHAR2,
	p_can_bet   VARCHAR2,
	p_can_raise VARCHAR2
) RETURN INTEGER IS
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

BEGIN

	-- package variables initialization
	
	v_strat_chromosome_metadata.exp_operand_id_bit_length := 8;
	v_strat_chromosome_metadata.exp_operator_id_bit_length := 2;
	v_strat_chromosome_metadata.bool_operator_bit_length := 3;
	v_strat_chromosome_metadata.amount_mult_bit_length := 8;
	v_strat_chromosome_metadata.stack_depth := 4;
	
	v_strat_chromosome_metadata.expression_bit_length := (2 * v_strat_chromosome_metadata.exp_operand_id_bit_length)
		+ v_strat_chromosome_metadata.exp_operator_id_bit_length;
	v_strat_chromosome_metadata.dec_tree_unit_bit_length := (2 * v_strat_chromosome_metadata.expression_bit_length)
		+ v_strat_chromosome_metadata.bool_operator_bit_length
		+ (2 * v_strat_chromosome_metadata.amount_mult_bit_length);
	v_strat_chromosome_metadata.dec_tree_unit_slots := POWER(2, v_strat_chromosome_metadata.stack_depth - 1) - 1;
	v_strat_chromosome_metadata.chromosome_bit_length := v_strat_chromosome_metadata.dec_tree_unit_bit_length * v_strat_chromosome_metadata.dec_tree_unit_slots;
	v_strat_chromosome_metadata.expression_slot_id_count := 2 * v_strat_chromosome_metadata.dec_tree_unit_slots;

END pkg_ga_player;
