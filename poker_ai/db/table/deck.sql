CREATE GLOBAL TEMPORARY TABLE deck
(
	card_id       NUMBER(2, 0),
	suit          VARCHAR2(8),
	display_value VARCHAR2(4),
	value         NUMBER(2, 0),
	dealt         VARCHAR2(1)
) ON COMMIT PRESERVE ROWS;

ALTER TABLE deck ADD
(
	CONSTRAINT d_pk_cid PRIMARY KEY (card_id)
);
