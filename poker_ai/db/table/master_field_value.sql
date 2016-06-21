CREATE TABLE master_field_value
(
	field_name_code  VARCHAR2(30),
	field_value_code VARCHAR2(30),
	numeric_value    NUMBER(10, 0),
	display_value    VARCHAR2(100),
	sort_order       NUMBER(10, 0)
);

ALTER TABLE master_field_value ADD
(
	CONSTRAINT mfv_pk_fncfvc PRIMARY KEY (field_name_code, field_value_code)
);

INSERT INTO master_field_value (field_name_code, field_value_code, numeric_value, display_value, sort_order) VALUES ('BETTING_ROUND_NUMBER', '1', 1, '1 - Pre-flop', 10);
INSERT INTO master_field_value (field_name_code, field_value_code, numeric_value, display_value, sort_order) VALUES ('BETTING_ROUND_NUMBER', '2', 2, '2 - Flop', 20);
INSERT INTO master_field_value (field_name_code, field_value_code, numeric_value, display_value, sort_order) VALUES ('BETTING_ROUND_NUMBER', '3', 3, '3 - Turn', 30);
INSERT INTO master_field_value (field_name_code, field_value_code, numeric_value, display_value, sort_order) VALUES ('BETTING_ROUND_NUMBER', '4', 4, '4 - River', 40);
INSERT INTO master_field_value (field_name_code, field_value_code, numeric_value, display_value, sort_order) VALUES ('PLAYER_STATE', 'NO_PLAYER',         0, 'No Player', 10);
INSERT INTO master_field_value (field_name_code, field_value_code, numeric_value, display_value, sort_order) VALUES ('PLAYER_STATE', 'NO_MOVE',           1, 'No Move', 20);
INSERT INTO master_field_value (field_name_code, field_value_code, numeric_value, display_value, sort_order) VALUES ('PLAYER_STATE', 'FOLDED',            2, 'Folded', 30);
INSERT INTO master_field_value (field_name_code, field_value_code, numeric_value, display_value, sort_order) VALUES ('PLAYER_STATE', 'CHECKED',           3, 'Checked', 40);
INSERT INTO master_field_value (field_name_code, field_value_code, numeric_value, display_value, sort_order) VALUES ('PLAYER_STATE', 'CALLED',            4, 'Called', 50);
INSERT INTO master_field_value (field_name_code, field_value_code, numeric_value, display_value, sort_order) VALUES ('PLAYER_STATE', 'BET',               5, 'Bet', 60);
INSERT INTO master_field_value (field_name_code, field_value_code, numeric_value, display_value, sort_order) VALUES ('PLAYER_STATE', 'RAISED',            6, 'Raised', 70);
INSERT INTO master_field_value (field_name_code, field_value_code, numeric_value, display_value, sort_order) VALUES ('PLAYER_STATE', 'OUT_OF_TOURNAMENT', 7, 'Out of Tournament', 80);
INSERT INTO master_field_value (field_name_code, field_value_code, numeric_value, display_value, sort_order) VALUES ('PLAYER_STATE', 'ALL_IN',            8, 'All In', 90);
INSERT INTO master_field_value (field_name_code, field_value_code, numeric_value, display_value, sort_order) VALUES ('HAND_RANK', '00', 0,  'Incomplete Hand', 10);
INSERT INTO master_field_value (field_name_code, field_value_code, numeric_value, display_value, sort_order) VALUES ('HAND_RANK', '01', 1,  'High Card', 20);
INSERT INTO master_field_value (field_name_code, field_value_code, numeric_value, display_value, sort_order) VALUES ('HAND_RANK', '02', 2,  'One Pair', 30);
INSERT INTO master_field_value (field_name_code, field_value_code, numeric_value, display_value, sort_order) VALUES ('HAND_RANK', '03', 3,  'Two Pair', 40);
INSERT INTO master_field_value (field_name_code, field_value_code, numeric_value, display_value, sort_order) VALUES ('HAND_RANK', '04', 4,  'Three of a Kind', 50);
INSERT INTO master_field_value (field_name_code, field_value_code, numeric_value, display_value, sort_order) VALUES ('HAND_RANK', '05', 5,  'Straight', 60);
INSERT INTO master_field_value (field_name_code, field_value_code, numeric_value, display_value, sort_order) VALUES ('HAND_RANK', '06', 6,  'Flush', 70);
INSERT INTO master_field_value (field_name_code, field_value_code, numeric_value, display_value, sort_order) VALUES ('HAND_RANK', '07', 7,  'Full House', 80);
INSERT INTO master_field_value (field_name_code, field_value_code, numeric_value, display_value, sort_order) VALUES ('HAND_RANK', '08', 8,  'Four of a Kind', 90);
INSERT INTO master_field_value (field_name_code, field_value_code, numeric_value, display_value, sort_order) VALUES ('HAND_RANK', '09', 9,  'Straight Flush', 100);
INSERT INTO master_field_value (field_name_code, field_value_code, numeric_value, display_value, sort_order) VALUES ('HAND_RANK', '10', 10, 'Royal Flush', 110);
INSERT INTO master_field_value (field_name_code, field_value_code, numeric_value, display_value, sort_order) VALUES ('CARD_SUIT', 'HEARTS',   1, 'Hearts', 10);
INSERT INTO master_field_value (field_name_code, field_value_code, numeric_value, display_value, sort_order) VALUES ('CARD_SUIT', 'DIAMONDS', 2, 'Diamonds', 20);
INSERT INTO master_field_value (field_name_code, field_value_code, numeric_value, display_value, sort_order) VALUES ('CARD_SUIT', 'SPADES',   3, 'Spades', 30);
INSERT INTO master_field_value (field_name_code, field_value_code, numeric_value, display_value, sort_order) VALUES ('CARD_SUIT', 'CLUBS',    4, 'Clubs', 40);

COMMIT;
