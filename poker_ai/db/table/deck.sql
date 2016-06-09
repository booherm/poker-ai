CREATE TABLE deck
(
	card_id       NUMBER(2, 0),
	suit          VARCHAR2(8),
	display_value VARCHAR2(4),
	value         NUMBER(2, 0),
	dealt         VARCHAR2(1)
);

ALTER TABLE deck ADD
(
	CONSTRAINT d_pk_cid PRIMARY KEY (card_id)
);

INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (0,  NULL, 'N/A', NULL, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (1,  'HEARTS',   '2 H',  2, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (2,  'HEARTS',   '3 H',  3, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (3,  'HEARTS',   '4 H',  4, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (4,  'HEARTS',   '5 H',  5, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (5,  'HEARTS',   '6 H',  6, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (6,  'HEARTS',   '7 H',  7, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (7,  'HEARTS',   '8 H',  8, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (8,  'HEARTS',   '9 H',  9, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (9,  'HEARTS',   '10 H', 10, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (10, 'HEARTS',   'J H',  11, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (11, 'HEARTS',   'Q H',  12, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (12, 'HEARTS',   'K H',  13, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (13, 'HEARTS',   'A H',  14, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (14, 'DIAMONDS', '2 D',  2, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (15, 'DIAMONDS', '3 D',  3, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (16, 'DIAMONDS', '4 D',  4, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (17, 'DIAMONDS', '5 D',  5, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (18, 'DIAMONDS', '6 D',  6, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (19, 'DIAMONDS', '7 D',  7, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (20, 'DIAMONDS', '8 D',  8, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (21, 'DIAMONDS', '9 D',  9, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (22, 'DIAMONDS', '10 D', 10, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (23, 'DIAMONDS', 'J D',  11, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (24, 'DIAMONDS', 'Q D',  12, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (25, 'DIAMONDS', 'K D',  13, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (26, 'DIAMONDS', 'A D',  14, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (27, 'SPADES',   '2 S',  2, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (28, 'SPADES',   '3 S',  3, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (29, 'SPADES',   '4 S',  4, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (30, 'SPADES',   '5 S',  5, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (31, 'SPADES',   '6 S',  6, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (32, 'SPADES',   '7 S',  7, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (33, 'SPADES',   '8 S',  8, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (34, 'SPADES',   '9 S',  9, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (35, 'SPADES',   '10 S', 10, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (36, 'SPADES',   'J S',  11, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (37, 'SPADES',   'Q S',  12, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (38, 'SPADES',   'K S',  13, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (39, 'SPADES',   'A S',  14, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (40, 'CLUBS',    '2 C',  2, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (41, 'CLUBS',    '3 C',  3, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (42, 'CLUBS',    '4 C',  4, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (43, 'CLUBS',    '5 C',  5, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (44, 'CLUBS',    '6 C',  6, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (45, 'CLUBS',    '7 C',  7, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (46, 'CLUBS',    '8 C',  8, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (47, 'CLUBS',    '9 C',  9, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (48, 'CLUBS',    '10 C', 10, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (49, 'CLUBS',    'J C',  11, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (50, 'CLUBS',    'Q C',  12, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (51, 'CLUBS',    'K C',  13, 'N');
INSERT INTO deck(card_id, suit, display_value, value, dealt) VALUES (52, 'CLUBS',    'A C',  14, 'N');

COMMIT;
