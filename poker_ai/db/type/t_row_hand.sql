CREATE OR REPLACE TYPE t_row_hand AS OBJECT
(
	card_id          NUMBER(2, 0),
	suit             VARCHAR2(8),
	value            NUMBER(2, 0),
	value_occurences NUMBER(1, 0)
);

