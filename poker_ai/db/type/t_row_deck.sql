CREATE OR REPLACE TYPE t_row_deck AS OBJECT
(
	card_id       NUMBER(2, 0),
	suit          VARCHAR2(8),
	display_value VARCHAR2(4),
	value         NUMBER(2, 0),
	dealt         VARCHAR2(1)
);
