CREATE TABLE player
(
	player_id NUMBER(10, 0)
);

ALTER TABLE player ADD
(
	CONSTRAINT p_pk_pid PRIMARY KEY (player_id)
);

INSERT INTO player(player_id)
SELECT pai_seq_generic.NEXTVAL player_id
FROM   DUAL
CONNECT BY ROWNUM <= 50;
COMMIT;
