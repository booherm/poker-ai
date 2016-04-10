CREATE TABLE hand_compare_test
(
	comparison_number    NUMBER(10, 0),
	h1_c1                NUMBER(2, 0),
	h1_c2                NUMBER(2, 0),
	h1_c3                NUMBER(2, 0),
	h1_c4                NUMBER(2, 0),
	h1_c5                NUMBER(2, 0),
	h2_c1                NUMBER(2, 0),
	h2_c2                NUMBER(2, 0),
	h2_c3                NUMBER(2, 0),
	h2_c4                NUMBER(2, 0),
	h2_c5                NUMBER(2, 0),
	hand_1_rank          VARCHAR2(17),
	hand_1_display_value VARCHAR2(51),
	hand_2_rank          VARCHAR2(17),
	hand_2_display_value VARCHAR2(51),
	better_hand          NUMBER(1, 0)
);
