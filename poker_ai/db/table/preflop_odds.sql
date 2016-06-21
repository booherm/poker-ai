CREATE TABLE preflop_odds
(
	card_1_id           NUMBER(2, 0),
	card_2_id           NUMBER(2, 0),
	rank                NUMBER(10, 0),
	expected_value      NUMBER(10, 2),
	win_percent         NUMBER(10, 2),
	tie_percent         NUMBER(10, 2),
	ouccurrence_percent NUMBER(10, 2),
	cumulative_percent  NUMBER(10, 2)
);

ALTER TABLE preflop_odds ADD
(
	CONSTRAINT pfo_pk_c1idc2id PRIMARY KEY (card_1_id, card_2_id)
);

INSERT INTO preflop_odds (
	card_1_id,
	card_2_id,
	rank,
	expected_value,
	win_percent,
	tie_percent,
	ouccurrence_percent,
	cumulative_percent
)

WITH card_pairings AS (
	SELECT 1 pair_id, 1 combination_card_1, 2 combination_card_2 FROM DUAL UNION ALL
	SELECT 2 pair_id, 1 combination_card_1, 3 combination_card_2 FROM DUAL UNION ALL
	SELECT 3 pair_id, 1 combination_card_1, 4 combination_card_2 FROM DUAL UNION ALL
	SELECT 4 pair_id, 1 combination_card_1, 5 combination_card_2 FROM DUAL UNION ALL
	SELECT 5 pair_id, 1 combination_card_1, 6 combination_card_2 FROM DUAL UNION ALL
	SELECT 6 pair_id, 1 combination_card_1, 7 combination_card_2 FROM DUAL UNION ALL
	SELECT 7 pair_id, 1 combination_card_1, 8 combination_card_2 FROM DUAL UNION ALL
	SELECT 8 pair_id, 1 combination_card_1, 9 combination_card_2 FROM DUAL UNION ALL
	SELECT 9 pair_id, 1 combination_card_1, 10 combination_card_2 FROM DUAL UNION ALL
	SELECT 10 pair_id, 1 combination_card_1, 11 combination_card_2 FROM DUAL UNION ALL
	SELECT 11 pair_id, 1 combination_card_1, 12 combination_card_2 FROM DUAL UNION ALL
	SELECT 12 pair_id, 1 combination_card_1, 13 combination_card_2 FROM DUAL UNION ALL
	SELECT 13 pair_id, 1 combination_card_1, 14 combination_card_2 FROM DUAL UNION ALL
	SELECT 14 pair_id, 1 combination_card_1, 15 combination_card_2 FROM DUAL UNION ALL
	SELECT 15 pair_id, 1 combination_card_1, 16 combination_card_2 FROM DUAL UNION ALL
	SELECT 16 pair_id, 1 combination_card_1, 17 combination_card_2 FROM DUAL UNION ALL
	SELECT 17 pair_id, 1 combination_card_1, 18 combination_card_2 FROM DUAL UNION ALL
	SELECT 18 pair_id, 1 combination_card_1, 19 combination_card_2 FROM DUAL UNION ALL
	SELECT 19 pair_id, 1 combination_card_1, 20 combination_card_2 FROM DUAL UNION ALL
	SELECT 20 pair_id, 1 combination_card_1, 21 combination_card_2 FROM DUAL UNION ALL
	SELECT 21 pair_id, 1 combination_card_1, 22 combination_card_2 FROM DUAL UNION ALL
	SELECT 22 pair_id, 1 combination_card_1, 23 combination_card_2 FROM DUAL UNION ALL
	SELECT 23 pair_id, 1 combination_card_1, 24 combination_card_2 FROM DUAL UNION ALL
	SELECT 24 pair_id, 1 combination_card_1, 25 combination_card_2 FROM DUAL UNION ALL
	SELECT 25 pair_id, 1 combination_card_1, 26 combination_card_2 FROM DUAL UNION ALL
	SELECT 26 pair_id, 1 combination_card_1, 27 combination_card_2 FROM DUAL UNION ALL
	SELECT 27 pair_id, 1 combination_card_1, 28 combination_card_2 FROM DUAL UNION ALL
	SELECT 28 pair_id, 1 combination_card_1, 29 combination_card_2 FROM DUAL UNION ALL
	SELECT 29 pair_id, 1 combination_card_1, 30 combination_card_2 FROM DUAL UNION ALL
	SELECT 30 pair_id, 1 combination_card_1, 31 combination_card_2 FROM DUAL UNION ALL
	SELECT 31 pair_id, 1 combination_card_1, 32 combination_card_2 FROM DUAL UNION ALL
	SELECT 32 pair_id, 1 combination_card_1, 33 combination_card_2 FROM DUAL UNION ALL
	SELECT 33 pair_id, 1 combination_card_1, 34 combination_card_2 FROM DUAL UNION ALL
	SELECT 34 pair_id, 1 combination_card_1, 35 combination_card_2 FROM DUAL UNION ALL
	SELECT 35 pair_id, 1 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 36 pair_id, 1 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 37 pair_id, 1 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 38 pair_id, 1 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 39 pair_id, 1 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 40 pair_id, 1 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 41 pair_id, 1 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 42 pair_id, 1 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 43 pair_id, 1 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 44 pair_id, 1 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 45 pair_id, 1 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 46 pair_id, 1 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 47 pair_id, 1 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 48 pair_id, 1 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 49 pair_id, 1 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 50 pair_id, 1 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 51 pair_id, 1 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 52 pair_id, 2 combination_card_1, 3 combination_card_2 FROM DUAL UNION ALL
	SELECT 53 pair_id, 2 combination_card_1, 4 combination_card_2 FROM DUAL UNION ALL
	SELECT 54 pair_id, 2 combination_card_1, 5 combination_card_2 FROM DUAL UNION ALL
	SELECT 55 pair_id, 2 combination_card_1, 6 combination_card_2 FROM DUAL UNION ALL
	SELECT 56 pair_id, 2 combination_card_1, 7 combination_card_2 FROM DUAL UNION ALL
	SELECT 57 pair_id, 2 combination_card_1, 8 combination_card_2 FROM DUAL UNION ALL
	SELECT 58 pair_id, 2 combination_card_1, 9 combination_card_2 FROM DUAL UNION ALL
	SELECT 59 pair_id, 2 combination_card_1, 10 combination_card_2 FROM DUAL UNION ALL
	SELECT 60 pair_id, 2 combination_card_1, 11 combination_card_2 FROM DUAL UNION ALL
	SELECT 61 pair_id, 2 combination_card_1, 12 combination_card_2 FROM DUAL UNION ALL
	SELECT 62 pair_id, 2 combination_card_1, 13 combination_card_2 FROM DUAL UNION ALL
	SELECT 63 pair_id, 2 combination_card_1, 14 combination_card_2 FROM DUAL UNION ALL
	SELECT 64 pair_id, 2 combination_card_1, 15 combination_card_2 FROM DUAL UNION ALL
	SELECT 65 pair_id, 2 combination_card_1, 16 combination_card_2 FROM DUAL UNION ALL
	SELECT 66 pair_id, 2 combination_card_1, 17 combination_card_2 FROM DUAL UNION ALL
	SELECT 67 pair_id, 2 combination_card_1, 18 combination_card_2 FROM DUAL UNION ALL
	SELECT 68 pair_id, 2 combination_card_1, 19 combination_card_2 FROM DUAL UNION ALL
	SELECT 69 pair_id, 2 combination_card_1, 20 combination_card_2 FROM DUAL UNION ALL
	SELECT 70 pair_id, 2 combination_card_1, 21 combination_card_2 FROM DUAL UNION ALL
	SELECT 71 pair_id, 2 combination_card_1, 22 combination_card_2 FROM DUAL UNION ALL
	SELECT 72 pair_id, 2 combination_card_1, 23 combination_card_2 FROM DUAL UNION ALL
	SELECT 73 pair_id, 2 combination_card_1, 24 combination_card_2 FROM DUAL UNION ALL
	SELECT 74 pair_id, 2 combination_card_1, 25 combination_card_2 FROM DUAL UNION ALL
	SELECT 75 pair_id, 2 combination_card_1, 26 combination_card_2 FROM DUAL UNION ALL
	SELECT 76 pair_id, 2 combination_card_1, 27 combination_card_2 FROM DUAL UNION ALL
	SELECT 77 pair_id, 2 combination_card_1, 28 combination_card_2 FROM DUAL UNION ALL
	SELECT 78 pair_id, 2 combination_card_1, 29 combination_card_2 FROM DUAL UNION ALL
	SELECT 79 pair_id, 2 combination_card_1, 30 combination_card_2 FROM DUAL UNION ALL
	SELECT 80 pair_id, 2 combination_card_1, 31 combination_card_2 FROM DUAL UNION ALL
	SELECT 81 pair_id, 2 combination_card_1, 32 combination_card_2 FROM DUAL UNION ALL
	SELECT 82 pair_id, 2 combination_card_1, 33 combination_card_2 FROM DUAL UNION ALL
	SELECT 83 pair_id, 2 combination_card_1, 34 combination_card_2 FROM DUAL UNION ALL
	SELECT 84 pair_id, 2 combination_card_1, 35 combination_card_2 FROM DUAL UNION ALL
	SELECT 85 pair_id, 2 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 86 pair_id, 2 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 87 pair_id, 2 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 88 pair_id, 2 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 89 pair_id, 2 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 90 pair_id, 2 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 91 pair_id, 2 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 92 pair_id, 2 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 93 pair_id, 2 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 94 pair_id, 2 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 95 pair_id, 2 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 96 pair_id, 2 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 97 pair_id, 2 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 98 pair_id, 2 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 99 pair_id, 2 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 100 pair_id, 2 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 101 pair_id, 2 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 102 pair_id, 3 combination_card_1, 4 combination_card_2 FROM DUAL UNION ALL
	SELECT 103 pair_id, 3 combination_card_1, 5 combination_card_2 FROM DUAL UNION ALL
	SELECT 104 pair_id, 3 combination_card_1, 6 combination_card_2 FROM DUAL UNION ALL
	SELECT 105 pair_id, 3 combination_card_1, 7 combination_card_2 FROM DUAL UNION ALL
	SELECT 106 pair_id, 3 combination_card_1, 8 combination_card_2 FROM DUAL UNION ALL
	SELECT 107 pair_id, 3 combination_card_1, 9 combination_card_2 FROM DUAL UNION ALL
	SELECT 108 pair_id, 3 combination_card_1, 10 combination_card_2 FROM DUAL UNION ALL
	SELECT 109 pair_id, 3 combination_card_1, 11 combination_card_2 FROM DUAL UNION ALL
	SELECT 110 pair_id, 3 combination_card_1, 12 combination_card_2 FROM DUAL UNION ALL
	SELECT 111 pair_id, 3 combination_card_1, 13 combination_card_2 FROM DUAL UNION ALL
	SELECT 112 pair_id, 3 combination_card_1, 14 combination_card_2 FROM DUAL UNION ALL
	SELECT 113 pair_id, 3 combination_card_1, 15 combination_card_2 FROM DUAL UNION ALL
	SELECT 114 pair_id, 3 combination_card_1, 16 combination_card_2 FROM DUAL UNION ALL
	SELECT 115 pair_id, 3 combination_card_1, 17 combination_card_2 FROM DUAL UNION ALL
	SELECT 116 pair_id, 3 combination_card_1, 18 combination_card_2 FROM DUAL UNION ALL
	SELECT 117 pair_id, 3 combination_card_1, 19 combination_card_2 FROM DUAL UNION ALL
	SELECT 118 pair_id, 3 combination_card_1, 20 combination_card_2 FROM DUAL UNION ALL
	SELECT 119 pair_id, 3 combination_card_1, 21 combination_card_2 FROM DUAL UNION ALL
	SELECT 120 pair_id, 3 combination_card_1, 22 combination_card_2 FROM DUAL UNION ALL
	SELECT 121 pair_id, 3 combination_card_1, 23 combination_card_2 FROM DUAL UNION ALL
	SELECT 122 pair_id, 3 combination_card_1, 24 combination_card_2 FROM DUAL UNION ALL
	SELECT 123 pair_id, 3 combination_card_1, 25 combination_card_2 FROM DUAL UNION ALL
	SELECT 124 pair_id, 3 combination_card_1, 26 combination_card_2 FROM DUAL UNION ALL
	SELECT 125 pair_id, 3 combination_card_1, 27 combination_card_2 FROM DUAL UNION ALL
	SELECT 126 pair_id, 3 combination_card_1, 28 combination_card_2 FROM DUAL UNION ALL
	SELECT 127 pair_id, 3 combination_card_1, 29 combination_card_2 FROM DUAL UNION ALL
	SELECT 128 pair_id, 3 combination_card_1, 30 combination_card_2 FROM DUAL UNION ALL
	SELECT 129 pair_id, 3 combination_card_1, 31 combination_card_2 FROM DUAL UNION ALL
	SELECT 130 pair_id, 3 combination_card_1, 32 combination_card_2 FROM DUAL UNION ALL
	SELECT 131 pair_id, 3 combination_card_1, 33 combination_card_2 FROM DUAL UNION ALL
	SELECT 132 pair_id, 3 combination_card_1, 34 combination_card_2 FROM DUAL UNION ALL
	SELECT 133 pair_id, 3 combination_card_1, 35 combination_card_2 FROM DUAL UNION ALL
	SELECT 134 pair_id, 3 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 135 pair_id, 3 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 136 pair_id, 3 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 137 pair_id, 3 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 138 pair_id, 3 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 139 pair_id, 3 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 140 pair_id, 3 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 141 pair_id, 3 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 142 pair_id, 3 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 143 pair_id, 3 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 144 pair_id, 3 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 145 pair_id, 3 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 146 pair_id, 3 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 147 pair_id, 3 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 148 pair_id, 3 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 149 pair_id, 3 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 150 pair_id, 3 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 151 pair_id, 4 combination_card_1, 5 combination_card_2 FROM DUAL UNION ALL
	SELECT 152 pair_id, 4 combination_card_1, 6 combination_card_2 FROM DUAL UNION ALL
	SELECT 153 pair_id, 4 combination_card_1, 7 combination_card_2 FROM DUAL UNION ALL
	SELECT 154 pair_id, 4 combination_card_1, 8 combination_card_2 FROM DUAL UNION ALL
	SELECT 155 pair_id, 4 combination_card_1, 9 combination_card_2 FROM DUAL UNION ALL
	SELECT 156 pair_id, 4 combination_card_1, 10 combination_card_2 FROM DUAL UNION ALL
	SELECT 157 pair_id, 4 combination_card_1, 11 combination_card_2 FROM DUAL UNION ALL
	SELECT 158 pair_id, 4 combination_card_1, 12 combination_card_2 FROM DUAL UNION ALL
	SELECT 159 pair_id, 4 combination_card_1, 13 combination_card_2 FROM DUAL UNION ALL
	SELECT 160 pair_id, 4 combination_card_1, 14 combination_card_2 FROM DUAL UNION ALL
	SELECT 161 pair_id, 4 combination_card_1, 15 combination_card_2 FROM DUAL UNION ALL
	SELECT 162 pair_id, 4 combination_card_1, 16 combination_card_2 FROM DUAL UNION ALL
	SELECT 163 pair_id, 4 combination_card_1, 17 combination_card_2 FROM DUAL UNION ALL
	SELECT 164 pair_id, 4 combination_card_1, 18 combination_card_2 FROM DUAL UNION ALL
	SELECT 165 pair_id, 4 combination_card_1, 19 combination_card_2 FROM DUAL UNION ALL
	SELECT 166 pair_id, 4 combination_card_1, 20 combination_card_2 FROM DUAL UNION ALL
	SELECT 167 pair_id, 4 combination_card_1, 21 combination_card_2 FROM DUAL UNION ALL
	SELECT 168 pair_id, 4 combination_card_1, 22 combination_card_2 FROM DUAL UNION ALL
	SELECT 169 pair_id, 4 combination_card_1, 23 combination_card_2 FROM DUAL UNION ALL
	SELECT 170 pair_id, 4 combination_card_1, 24 combination_card_2 FROM DUAL UNION ALL
	SELECT 171 pair_id, 4 combination_card_1, 25 combination_card_2 FROM DUAL UNION ALL
	SELECT 172 pair_id, 4 combination_card_1, 26 combination_card_2 FROM DUAL UNION ALL
	SELECT 173 pair_id, 4 combination_card_1, 27 combination_card_2 FROM DUAL UNION ALL
	SELECT 174 pair_id, 4 combination_card_1, 28 combination_card_2 FROM DUAL UNION ALL
	SELECT 175 pair_id, 4 combination_card_1, 29 combination_card_2 FROM DUAL UNION ALL
	SELECT 176 pair_id, 4 combination_card_1, 30 combination_card_2 FROM DUAL UNION ALL
	SELECT 177 pair_id, 4 combination_card_1, 31 combination_card_2 FROM DUAL UNION ALL
	SELECT 178 pair_id, 4 combination_card_1, 32 combination_card_2 FROM DUAL UNION ALL
	SELECT 179 pair_id, 4 combination_card_1, 33 combination_card_2 FROM DUAL UNION ALL
	SELECT 180 pair_id, 4 combination_card_1, 34 combination_card_2 FROM DUAL UNION ALL
	SELECT 181 pair_id, 4 combination_card_1, 35 combination_card_2 FROM DUAL UNION ALL
	SELECT 182 pair_id, 4 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 183 pair_id, 4 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 184 pair_id, 4 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 185 pair_id, 4 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 186 pair_id, 4 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 187 pair_id, 4 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 188 pair_id, 4 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 189 pair_id, 4 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 190 pair_id, 4 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 191 pair_id, 4 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 192 pair_id, 4 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 193 pair_id, 4 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 194 pair_id, 4 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 195 pair_id, 4 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 196 pair_id, 4 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 197 pair_id, 4 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 198 pair_id, 4 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 199 pair_id, 5 combination_card_1, 6 combination_card_2 FROM DUAL UNION ALL
	SELECT 200 pair_id, 5 combination_card_1, 7 combination_card_2 FROM DUAL UNION ALL
	SELECT 201 pair_id, 5 combination_card_1, 8 combination_card_2 FROM DUAL UNION ALL
	SELECT 202 pair_id, 5 combination_card_1, 9 combination_card_2 FROM DUAL UNION ALL
	SELECT 203 pair_id, 5 combination_card_1, 10 combination_card_2 FROM DUAL UNION ALL
	SELECT 204 pair_id, 5 combination_card_1, 11 combination_card_2 FROM DUAL UNION ALL
	SELECT 205 pair_id, 5 combination_card_1, 12 combination_card_2 FROM DUAL UNION ALL
	SELECT 206 pair_id, 5 combination_card_1, 13 combination_card_2 FROM DUAL UNION ALL
	SELECT 207 pair_id, 5 combination_card_1, 14 combination_card_2 FROM DUAL UNION ALL
	SELECT 208 pair_id, 5 combination_card_1, 15 combination_card_2 FROM DUAL UNION ALL
	SELECT 209 pair_id, 5 combination_card_1, 16 combination_card_2 FROM DUAL UNION ALL
	SELECT 210 pair_id, 5 combination_card_1, 17 combination_card_2 FROM DUAL UNION ALL
	SELECT 211 pair_id, 5 combination_card_1, 18 combination_card_2 FROM DUAL UNION ALL
	SELECT 212 pair_id, 5 combination_card_1, 19 combination_card_2 FROM DUAL UNION ALL
	SELECT 213 pair_id, 5 combination_card_1, 20 combination_card_2 FROM DUAL UNION ALL
	SELECT 214 pair_id, 5 combination_card_1, 21 combination_card_2 FROM DUAL UNION ALL
	SELECT 215 pair_id, 5 combination_card_1, 22 combination_card_2 FROM DUAL UNION ALL
	SELECT 216 pair_id, 5 combination_card_1, 23 combination_card_2 FROM DUAL UNION ALL
	SELECT 217 pair_id, 5 combination_card_1, 24 combination_card_2 FROM DUAL UNION ALL
	SELECT 218 pair_id, 5 combination_card_1, 25 combination_card_2 FROM DUAL UNION ALL
	SELECT 219 pair_id, 5 combination_card_1, 26 combination_card_2 FROM DUAL UNION ALL
	SELECT 220 pair_id, 5 combination_card_1, 27 combination_card_2 FROM DUAL UNION ALL
	SELECT 221 pair_id, 5 combination_card_1, 28 combination_card_2 FROM DUAL UNION ALL
	SELECT 222 pair_id, 5 combination_card_1, 29 combination_card_2 FROM DUAL UNION ALL
	SELECT 223 pair_id, 5 combination_card_1, 30 combination_card_2 FROM DUAL UNION ALL
	SELECT 224 pair_id, 5 combination_card_1, 31 combination_card_2 FROM DUAL UNION ALL
	SELECT 225 pair_id, 5 combination_card_1, 32 combination_card_2 FROM DUAL UNION ALL
	SELECT 226 pair_id, 5 combination_card_1, 33 combination_card_2 FROM DUAL UNION ALL
	SELECT 227 pair_id, 5 combination_card_1, 34 combination_card_2 FROM DUAL UNION ALL
	SELECT 228 pair_id, 5 combination_card_1, 35 combination_card_2 FROM DUAL UNION ALL
	SELECT 229 pair_id, 5 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 230 pair_id, 5 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 231 pair_id, 5 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 232 pair_id, 5 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 233 pair_id, 5 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 234 pair_id, 5 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 235 pair_id, 5 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 236 pair_id, 5 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 237 pair_id, 5 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 238 pair_id, 5 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 239 pair_id, 5 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 240 pair_id, 5 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 241 pair_id, 5 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 242 pair_id, 5 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 243 pair_id, 5 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 244 pair_id, 5 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 245 pair_id, 5 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 246 pair_id, 6 combination_card_1, 7 combination_card_2 FROM DUAL UNION ALL
	SELECT 247 pair_id, 6 combination_card_1, 8 combination_card_2 FROM DUAL UNION ALL
	SELECT 248 pair_id, 6 combination_card_1, 9 combination_card_2 FROM DUAL UNION ALL
	SELECT 249 pair_id, 6 combination_card_1, 10 combination_card_2 FROM DUAL UNION ALL
	SELECT 250 pair_id, 6 combination_card_1, 11 combination_card_2 FROM DUAL UNION ALL
	SELECT 251 pair_id, 6 combination_card_1, 12 combination_card_2 FROM DUAL UNION ALL
	SELECT 252 pair_id, 6 combination_card_1, 13 combination_card_2 FROM DUAL UNION ALL
	SELECT 253 pair_id, 6 combination_card_1, 14 combination_card_2 FROM DUAL UNION ALL
	SELECT 254 pair_id, 6 combination_card_1, 15 combination_card_2 FROM DUAL UNION ALL
	SELECT 255 pair_id, 6 combination_card_1, 16 combination_card_2 FROM DUAL UNION ALL
	SELECT 256 pair_id, 6 combination_card_1, 17 combination_card_2 FROM DUAL UNION ALL
	SELECT 257 pair_id, 6 combination_card_1, 18 combination_card_2 FROM DUAL UNION ALL
	SELECT 258 pair_id, 6 combination_card_1, 19 combination_card_2 FROM DUAL UNION ALL
	SELECT 259 pair_id, 6 combination_card_1, 20 combination_card_2 FROM DUAL UNION ALL
	SELECT 260 pair_id, 6 combination_card_1, 21 combination_card_2 FROM DUAL UNION ALL
	SELECT 261 pair_id, 6 combination_card_1, 22 combination_card_2 FROM DUAL UNION ALL
	SELECT 262 pair_id, 6 combination_card_1, 23 combination_card_2 FROM DUAL UNION ALL
	SELECT 263 pair_id, 6 combination_card_1, 24 combination_card_2 FROM DUAL UNION ALL
	SELECT 264 pair_id, 6 combination_card_1, 25 combination_card_2 FROM DUAL UNION ALL
	SELECT 265 pair_id, 6 combination_card_1, 26 combination_card_2 FROM DUAL UNION ALL
	SELECT 266 pair_id, 6 combination_card_1, 27 combination_card_2 FROM DUAL UNION ALL
	SELECT 267 pair_id, 6 combination_card_1, 28 combination_card_2 FROM DUAL UNION ALL
	SELECT 268 pair_id, 6 combination_card_1, 29 combination_card_2 FROM DUAL UNION ALL
	SELECT 269 pair_id, 6 combination_card_1, 30 combination_card_2 FROM DUAL UNION ALL
	SELECT 270 pair_id, 6 combination_card_1, 31 combination_card_2 FROM DUAL UNION ALL
	SELECT 271 pair_id, 6 combination_card_1, 32 combination_card_2 FROM DUAL UNION ALL
	SELECT 272 pair_id, 6 combination_card_1, 33 combination_card_2 FROM DUAL UNION ALL
	SELECT 273 pair_id, 6 combination_card_1, 34 combination_card_2 FROM DUAL UNION ALL
	SELECT 274 pair_id, 6 combination_card_1, 35 combination_card_2 FROM DUAL UNION ALL
	SELECT 275 pair_id, 6 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 276 pair_id, 6 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 277 pair_id, 6 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 278 pair_id, 6 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 279 pair_id, 6 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 280 pair_id, 6 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 281 pair_id, 6 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 282 pair_id, 6 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 283 pair_id, 6 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 284 pair_id, 6 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 285 pair_id, 6 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 286 pair_id, 6 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 287 pair_id, 6 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 288 pair_id, 6 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 289 pair_id, 6 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 290 pair_id, 6 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 291 pair_id, 6 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 292 pair_id, 7 combination_card_1, 8 combination_card_2 FROM DUAL UNION ALL
	SELECT 293 pair_id, 7 combination_card_1, 9 combination_card_2 FROM DUAL UNION ALL
	SELECT 294 pair_id, 7 combination_card_1, 10 combination_card_2 FROM DUAL UNION ALL
	SELECT 295 pair_id, 7 combination_card_1, 11 combination_card_2 FROM DUAL UNION ALL
	SELECT 296 pair_id, 7 combination_card_1, 12 combination_card_2 FROM DUAL UNION ALL
	SELECT 297 pair_id, 7 combination_card_1, 13 combination_card_2 FROM DUAL UNION ALL
	SELECT 298 pair_id, 7 combination_card_1, 14 combination_card_2 FROM DUAL UNION ALL
	SELECT 299 pair_id, 7 combination_card_1, 15 combination_card_2 FROM DUAL UNION ALL
	SELECT 300 pair_id, 7 combination_card_1, 16 combination_card_2 FROM DUAL UNION ALL
	SELECT 301 pair_id, 7 combination_card_1, 17 combination_card_2 FROM DUAL UNION ALL
	SELECT 302 pair_id, 7 combination_card_1, 18 combination_card_2 FROM DUAL UNION ALL
	SELECT 303 pair_id, 7 combination_card_1, 19 combination_card_2 FROM DUAL UNION ALL
	SELECT 304 pair_id, 7 combination_card_1, 20 combination_card_2 FROM DUAL UNION ALL
	SELECT 305 pair_id, 7 combination_card_1, 21 combination_card_2 FROM DUAL UNION ALL
	SELECT 306 pair_id, 7 combination_card_1, 22 combination_card_2 FROM DUAL UNION ALL
	SELECT 307 pair_id, 7 combination_card_1, 23 combination_card_2 FROM DUAL UNION ALL
	SELECT 308 pair_id, 7 combination_card_1, 24 combination_card_2 FROM DUAL UNION ALL
	SELECT 309 pair_id, 7 combination_card_1, 25 combination_card_2 FROM DUAL UNION ALL
	SELECT 310 pair_id, 7 combination_card_1, 26 combination_card_2 FROM DUAL UNION ALL
	SELECT 311 pair_id, 7 combination_card_1, 27 combination_card_2 FROM DUAL UNION ALL
	SELECT 312 pair_id, 7 combination_card_1, 28 combination_card_2 FROM DUAL UNION ALL
	SELECT 313 pair_id, 7 combination_card_1, 29 combination_card_2 FROM DUAL UNION ALL
	SELECT 314 pair_id, 7 combination_card_1, 30 combination_card_2 FROM DUAL UNION ALL
	SELECT 315 pair_id, 7 combination_card_1, 31 combination_card_2 FROM DUAL UNION ALL
	SELECT 316 pair_id, 7 combination_card_1, 32 combination_card_2 FROM DUAL UNION ALL
	SELECT 317 pair_id, 7 combination_card_1, 33 combination_card_2 FROM DUAL UNION ALL
	SELECT 318 pair_id, 7 combination_card_1, 34 combination_card_2 FROM DUAL UNION ALL
	SELECT 319 pair_id, 7 combination_card_1, 35 combination_card_2 FROM DUAL UNION ALL
	SELECT 320 pair_id, 7 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 321 pair_id, 7 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 322 pair_id, 7 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 323 pair_id, 7 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 324 pair_id, 7 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 325 pair_id, 7 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 326 pair_id, 7 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 327 pair_id, 7 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 328 pair_id, 7 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 329 pair_id, 7 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 330 pair_id, 7 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 331 pair_id, 7 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 332 pair_id, 7 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 333 pair_id, 7 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 334 pair_id, 7 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 335 pair_id, 7 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 336 pair_id, 7 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 337 pair_id, 8 combination_card_1, 9 combination_card_2 FROM DUAL UNION ALL
	SELECT 338 pair_id, 8 combination_card_1, 10 combination_card_2 FROM DUAL UNION ALL
	SELECT 339 pair_id, 8 combination_card_1, 11 combination_card_2 FROM DUAL UNION ALL
	SELECT 340 pair_id, 8 combination_card_1, 12 combination_card_2 FROM DUAL UNION ALL
	SELECT 341 pair_id, 8 combination_card_1, 13 combination_card_2 FROM DUAL UNION ALL
	SELECT 342 pair_id, 8 combination_card_1, 14 combination_card_2 FROM DUAL UNION ALL
	SELECT 343 pair_id, 8 combination_card_1, 15 combination_card_2 FROM DUAL UNION ALL
	SELECT 344 pair_id, 8 combination_card_1, 16 combination_card_2 FROM DUAL UNION ALL
	SELECT 345 pair_id, 8 combination_card_1, 17 combination_card_2 FROM DUAL UNION ALL
	SELECT 346 pair_id, 8 combination_card_1, 18 combination_card_2 FROM DUAL UNION ALL
	SELECT 347 pair_id, 8 combination_card_1, 19 combination_card_2 FROM DUAL UNION ALL
	SELECT 348 pair_id, 8 combination_card_1, 20 combination_card_2 FROM DUAL UNION ALL
	SELECT 349 pair_id, 8 combination_card_1, 21 combination_card_2 FROM DUAL UNION ALL
	SELECT 350 pair_id, 8 combination_card_1, 22 combination_card_2 FROM DUAL UNION ALL
	SELECT 351 pair_id, 8 combination_card_1, 23 combination_card_2 FROM DUAL UNION ALL
	SELECT 352 pair_id, 8 combination_card_1, 24 combination_card_2 FROM DUAL UNION ALL
	SELECT 353 pair_id, 8 combination_card_1, 25 combination_card_2 FROM DUAL UNION ALL
	SELECT 354 pair_id, 8 combination_card_1, 26 combination_card_2 FROM DUAL UNION ALL
	SELECT 355 pair_id, 8 combination_card_1, 27 combination_card_2 FROM DUAL UNION ALL
	SELECT 356 pair_id, 8 combination_card_1, 28 combination_card_2 FROM DUAL UNION ALL
	SELECT 357 pair_id, 8 combination_card_1, 29 combination_card_2 FROM DUAL UNION ALL
	SELECT 358 pair_id, 8 combination_card_1, 30 combination_card_2 FROM DUAL UNION ALL
	SELECT 359 pair_id, 8 combination_card_1, 31 combination_card_2 FROM DUAL UNION ALL
	SELECT 360 pair_id, 8 combination_card_1, 32 combination_card_2 FROM DUAL UNION ALL
	SELECT 361 pair_id, 8 combination_card_1, 33 combination_card_2 FROM DUAL UNION ALL
	SELECT 362 pair_id, 8 combination_card_1, 34 combination_card_2 FROM DUAL UNION ALL
	SELECT 363 pair_id, 8 combination_card_1, 35 combination_card_2 FROM DUAL UNION ALL
	SELECT 364 pair_id, 8 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 365 pair_id, 8 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 366 pair_id, 8 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 367 pair_id, 8 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 368 pair_id, 8 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 369 pair_id, 8 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 370 pair_id, 8 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 371 pair_id, 8 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 372 pair_id, 8 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 373 pair_id, 8 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 374 pair_id, 8 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 375 pair_id, 8 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 376 pair_id, 8 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 377 pair_id, 8 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 378 pair_id, 8 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 379 pair_id, 8 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 380 pair_id, 8 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 381 pair_id, 9 combination_card_1, 10 combination_card_2 FROM DUAL UNION ALL
	SELECT 382 pair_id, 9 combination_card_1, 11 combination_card_2 FROM DUAL UNION ALL
	SELECT 383 pair_id, 9 combination_card_1, 12 combination_card_2 FROM DUAL UNION ALL
	SELECT 384 pair_id, 9 combination_card_1, 13 combination_card_2 FROM DUAL UNION ALL
	SELECT 385 pair_id, 9 combination_card_1, 14 combination_card_2 FROM DUAL UNION ALL
	SELECT 386 pair_id, 9 combination_card_1, 15 combination_card_2 FROM DUAL UNION ALL
	SELECT 387 pair_id, 9 combination_card_1, 16 combination_card_2 FROM DUAL UNION ALL
	SELECT 388 pair_id, 9 combination_card_1, 17 combination_card_2 FROM DUAL UNION ALL
	SELECT 389 pair_id, 9 combination_card_1, 18 combination_card_2 FROM DUAL UNION ALL
	SELECT 390 pair_id, 9 combination_card_1, 19 combination_card_2 FROM DUAL UNION ALL
	SELECT 391 pair_id, 9 combination_card_1, 20 combination_card_2 FROM DUAL UNION ALL
	SELECT 392 pair_id, 9 combination_card_1, 21 combination_card_2 FROM DUAL UNION ALL
	SELECT 393 pair_id, 9 combination_card_1, 22 combination_card_2 FROM DUAL UNION ALL
	SELECT 394 pair_id, 9 combination_card_1, 23 combination_card_2 FROM DUAL UNION ALL
	SELECT 395 pair_id, 9 combination_card_1, 24 combination_card_2 FROM DUAL UNION ALL
	SELECT 396 pair_id, 9 combination_card_1, 25 combination_card_2 FROM DUAL UNION ALL
	SELECT 397 pair_id, 9 combination_card_1, 26 combination_card_2 FROM DUAL UNION ALL
	SELECT 398 pair_id, 9 combination_card_1, 27 combination_card_2 FROM DUAL UNION ALL
	SELECT 399 pair_id, 9 combination_card_1, 28 combination_card_2 FROM DUAL UNION ALL
	SELECT 400 pair_id, 9 combination_card_1, 29 combination_card_2 FROM DUAL UNION ALL
	SELECT 401 pair_id, 9 combination_card_1, 30 combination_card_2 FROM DUAL UNION ALL
	SELECT 402 pair_id, 9 combination_card_1, 31 combination_card_2 FROM DUAL UNION ALL
	SELECT 403 pair_id, 9 combination_card_1, 32 combination_card_2 FROM DUAL UNION ALL
	SELECT 404 pair_id, 9 combination_card_1, 33 combination_card_2 FROM DUAL UNION ALL
	SELECT 405 pair_id, 9 combination_card_1, 34 combination_card_2 FROM DUAL UNION ALL
	SELECT 406 pair_id, 9 combination_card_1, 35 combination_card_2 FROM DUAL UNION ALL
	SELECT 407 pair_id, 9 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 408 pair_id, 9 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 409 pair_id, 9 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 410 pair_id, 9 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 411 pair_id, 9 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 412 pair_id, 9 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 413 pair_id, 9 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 414 pair_id, 9 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 415 pair_id, 9 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 416 pair_id, 9 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 417 pair_id, 9 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 418 pair_id, 9 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 419 pair_id, 9 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 420 pair_id, 9 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 421 pair_id, 9 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 422 pair_id, 9 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 423 pair_id, 9 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 424 pair_id, 10 combination_card_1, 11 combination_card_2 FROM DUAL UNION ALL
	SELECT 425 pair_id, 10 combination_card_1, 12 combination_card_2 FROM DUAL UNION ALL
	SELECT 426 pair_id, 10 combination_card_1, 13 combination_card_2 FROM DUAL UNION ALL
	SELECT 427 pair_id, 10 combination_card_1, 14 combination_card_2 FROM DUAL UNION ALL
	SELECT 428 pair_id, 10 combination_card_1, 15 combination_card_2 FROM DUAL UNION ALL
	SELECT 429 pair_id, 10 combination_card_1, 16 combination_card_2 FROM DUAL UNION ALL
	SELECT 430 pair_id, 10 combination_card_1, 17 combination_card_2 FROM DUAL UNION ALL
	SELECT 431 pair_id, 10 combination_card_1, 18 combination_card_2 FROM DUAL UNION ALL
	SELECT 432 pair_id, 10 combination_card_1, 19 combination_card_2 FROM DUAL UNION ALL
	SELECT 433 pair_id, 10 combination_card_1, 20 combination_card_2 FROM DUAL UNION ALL
	SELECT 434 pair_id, 10 combination_card_1, 21 combination_card_2 FROM DUAL UNION ALL
	SELECT 435 pair_id, 10 combination_card_1, 22 combination_card_2 FROM DUAL UNION ALL
	SELECT 436 pair_id, 10 combination_card_1, 23 combination_card_2 FROM DUAL UNION ALL
	SELECT 437 pair_id, 10 combination_card_1, 24 combination_card_2 FROM DUAL UNION ALL
	SELECT 438 pair_id, 10 combination_card_1, 25 combination_card_2 FROM DUAL UNION ALL
	SELECT 439 pair_id, 10 combination_card_1, 26 combination_card_2 FROM DUAL UNION ALL
	SELECT 440 pair_id, 10 combination_card_1, 27 combination_card_2 FROM DUAL UNION ALL
	SELECT 441 pair_id, 10 combination_card_1, 28 combination_card_2 FROM DUAL UNION ALL
	SELECT 442 pair_id, 10 combination_card_1, 29 combination_card_2 FROM DUAL UNION ALL
	SELECT 443 pair_id, 10 combination_card_1, 30 combination_card_2 FROM DUAL UNION ALL
	SELECT 444 pair_id, 10 combination_card_1, 31 combination_card_2 FROM DUAL UNION ALL
	SELECT 445 pair_id, 10 combination_card_1, 32 combination_card_2 FROM DUAL UNION ALL
	SELECT 446 pair_id, 10 combination_card_1, 33 combination_card_2 FROM DUAL UNION ALL
	SELECT 447 pair_id, 10 combination_card_1, 34 combination_card_2 FROM DUAL UNION ALL
	SELECT 448 pair_id, 10 combination_card_1, 35 combination_card_2 FROM DUAL UNION ALL
	SELECT 449 pair_id, 10 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 450 pair_id, 10 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 451 pair_id, 10 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 452 pair_id, 10 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 453 pair_id, 10 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 454 pair_id, 10 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 455 pair_id, 10 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 456 pair_id, 10 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 457 pair_id, 10 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 458 pair_id, 10 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 459 pair_id, 10 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 460 pair_id, 10 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 461 pair_id, 10 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 462 pair_id, 10 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 463 pair_id, 10 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 464 pair_id, 10 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 465 pair_id, 10 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 466 pair_id, 11 combination_card_1, 12 combination_card_2 FROM DUAL UNION ALL
	SELECT 467 pair_id, 11 combination_card_1, 13 combination_card_2 FROM DUAL UNION ALL
	SELECT 468 pair_id, 11 combination_card_1, 14 combination_card_2 FROM DUAL UNION ALL
	SELECT 469 pair_id, 11 combination_card_1, 15 combination_card_2 FROM DUAL UNION ALL
	SELECT 470 pair_id, 11 combination_card_1, 16 combination_card_2 FROM DUAL UNION ALL
	SELECT 471 pair_id, 11 combination_card_1, 17 combination_card_2 FROM DUAL UNION ALL
	SELECT 472 pair_id, 11 combination_card_1, 18 combination_card_2 FROM DUAL UNION ALL
	SELECT 473 pair_id, 11 combination_card_1, 19 combination_card_2 FROM DUAL UNION ALL
	SELECT 474 pair_id, 11 combination_card_1, 20 combination_card_2 FROM DUAL UNION ALL
	SELECT 475 pair_id, 11 combination_card_1, 21 combination_card_2 FROM DUAL UNION ALL
	SELECT 476 pair_id, 11 combination_card_1, 22 combination_card_2 FROM DUAL UNION ALL
	SELECT 477 pair_id, 11 combination_card_1, 23 combination_card_2 FROM DUAL UNION ALL
	SELECT 478 pair_id, 11 combination_card_1, 24 combination_card_2 FROM DUAL UNION ALL
	SELECT 479 pair_id, 11 combination_card_1, 25 combination_card_2 FROM DUAL UNION ALL
	SELECT 480 pair_id, 11 combination_card_1, 26 combination_card_2 FROM DUAL UNION ALL
	SELECT 481 pair_id, 11 combination_card_1, 27 combination_card_2 FROM DUAL UNION ALL
	SELECT 482 pair_id, 11 combination_card_1, 28 combination_card_2 FROM DUAL UNION ALL
	SELECT 483 pair_id, 11 combination_card_1, 29 combination_card_2 FROM DUAL UNION ALL
	SELECT 484 pair_id, 11 combination_card_1, 30 combination_card_2 FROM DUAL UNION ALL
	SELECT 485 pair_id, 11 combination_card_1, 31 combination_card_2 FROM DUAL UNION ALL
	SELECT 486 pair_id, 11 combination_card_1, 32 combination_card_2 FROM DUAL UNION ALL
	SELECT 487 pair_id, 11 combination_card_1, 33 combination_card_2 FROM DUAL UNION ALL
	SELECT 488 pair_id, 11 combination_card_1, 34 combination_card_2 FROM DUAL UNION ALL
	SELECT 489 pair_id, 11 combination_card_1, 35 combination_card_2 FROM DUAL UNION ALL
	SELECT 490 pair_id, 11 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 491 pair_id, 11 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 492 pair_id, 11 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 493 pair_id, 11 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 494 pair_id, 11 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 495 pair_id, 11 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 496 pair_id, 11 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 497 pair_id, 11 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 498 pair_id, 11 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 499 pair_id, 11 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 500 pair_id, 11 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 501 pair_id, 11 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 502 pair_id, 11 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 503 pair_id, 11 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 504 pair_id, 11 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 505 pair_id, 11 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 506 pair_id, 11 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 507 pair_id, 12 combination_card_1, 13 combination_card_2 FROM DUAL UNION ALL
	SELECT 508 pair_id, 12 combination_card_1, 14 combination_card_2 FROM DUAL UNION ALL
	SELECT 509 pair_id, 12 combination_card_1, 15 combination_card_2 FROM DUAL UNION ALL
	SELECT 510 pair_id, 12 combination_card_1, 16 combination_card_2 FROM DUAL UNION ALL
	SELECT 511 pair_id, 12 combination_card_1, 17 combination_card_2 FROM DUAL UNION ALL
	SELECT 512 pair_id, 12 combination_card_1, 18 combination_card_2 FROM DUAL UNION ALL
	SELECT 513 pair_id, 12 combination_card_1, 19 combination_card_2 FROM DUAL UNION ALL
	SELECT 514 pair_id, 12 combination_card_1, 20 combination_card_2 FROM DUAL UNION ALL
	SELECT 515 pair_id, 12 combination_card_1, 21 combination_card_2 FROM DUAL UNION ALL
	SELECT 516 pair_id, 12 combination_card_1, 22 combination_card_2 FROM DUAL UNION ALL
	SELECT 517 pair_id, 12 combination_card_1, 23 combination_card_2 FROM DUAL UNION ALL
	SELECT 518 pair_id, 12 combination_card_1, 24 combination_card_2 FROM DUAL UNION ALL
	SELECT 519 pair_id, 12 combination_card_1, 25 combination_card_2 FROM DUAL UNION ALL
	SELECT 520 pair_id, 12 combination_card_1, 26 combination_card_2 FROM DUAL UNION ALL
	SELECT 521 pair_id, 12 combination_card_1, 27 combination_card_2 FROM DUAL UNION ALL
	SELECT 522 pair_id, 12 combination_card_1, 28 combination_card_2 FROM DUAL UNION ALL
	SELECT 523 pair_id, 12 combination_card_1, 29 combination_card_2 FROM DUAL UNION ALL
	SELECT 524 pair_id, 12 combination_card_1, 30 combination_card_2 FROM DUAL UNION ALL
	SELECT 525 pair_id, 12 combination_card_1, 31 combination_card_2 FROM DUAL UNION ALL
	SELECT 526 pair_id, 12 combination_card_1, 32 combination_card_2 FROM DUAL UNION ALL
	SELECT 527 pair_id, 12 combination_card_1, 33 combination_card_2 FROM DUAL UNION ALL
	SELECT 528 pair_id, 12 combination_card_1, 34 combination_card_2 FROM DUAL UNION ALL
	SELECT 529 pair_id, 12 combination_card_1, 35 combination_card_2 FROM DUAL UNION ALL
	SELECT 530 pair_id, 12 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 531 pair_id, 12 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 532 pair_id, 12 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 533 pair_id, 12 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 534 pair_id, 12 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 535 pair_id, 12 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 536 pair_id, 12 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 537 pair_id, 12 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 538 pair_id, 12 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 539 pair_id, 12 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 540 pair_id, 12 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 541 pair_id, 12 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 542 pair_id, 12 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 543 pair_id, 12 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 544 pair_id, 12 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 545 pair_id, 12 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 546 pair_id, 12 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 547 pair_id, 13 combination_card_1, 14 combination_card_2 FROM DUAL UNION ALL
	SELECT 548 pair_id, 13 combination_card_1, 15 combination_card_2 FROM DUAL UNION ALL
	SELECT 549 pair_id, 13 combination_card_1, 16 combination_card_2 FROM DUAL UNION ALL
	SELECT 550 pair_id, 13 combination_card_1, 17 combination_card_2 FROM DUAL UNION ALL
	SELECT 551 pair_id, 13 combination_card_1, 18 combination_card_2 FROM DUAL UNION ALL
	SELECT 552 pair_id, 13 combination_card_1, 19 combination_card_2 FROM DUAL UNION ALL
	SELECT 553 pair_id, 13 combination_card_1, 20 combination_card_2 FROM DUAL UNION ALL
	SELECT 554 pair_id, 13 combination_card_1, 21 combination_card_2 FROM DUAL UNION ALL
	SELECT 555 pair_id, 13 combination_card_1, 22 combination_card_2 FROM DUAL UNION ALL
	SELECT 556 pair_id, 13 combination_card_1, 23 combination_card_2 FROM DUAL UNION ALL
	SELECT 557 pair_id, 13 combination_card_1, 24 combination_card_2 FROM DUAL UNION ALL
	SELECT 558 pair_id, 13 combination_card_1, 25 combination_card_2 FROM DUAL UNION ALL
	SELECT 559 pair_id, 13 combination_card_1, 26 combination_card_2 FROM DUAL UNION ALL
	SELECT 560 pair_id, 13 combination_card_1, 27 combination_card_2 FROM DUAL UNION ALL
	SELECT 561 pair_id, 13 combination_card_1, 28 combination_card_2 FROM DUAL UNION ALL
	SELECT 562 pair_id, 13 combination_card_1, 29 combination_card_2 FROM DUAL UNION ALL
	SELECT 563 pair_id, 13 combination_card_1, 30 combination_card_2 FROM DUAL UNION ALL
	SELECT 564 pair_id, 13 combination_card_1, 31 combination_card_2 FROM DUAL UNION ALL
	SELECT 565 pair_id, 13 combination_card_1, 32 combination_card_2 FROM DUAL UNION ALL
	SELECT 566 pair_id, 13 combination_card_1, 33 combination_card_2 FROM DUAL UNION ALL
	SELECT 567 pair_id, 13 combination_card_1, 34 combination_card_2 FROM DUAL UNION ALL
	SELECT 568 pair_id, 13 combination_card_1, 35 combination_card_2 FROM DUAL UNION ALL
	SELECT 569 pair_id, 13 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 570 pair_id, 13 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 571 pair_id, 13 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 572 pair_id, 13 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 573 pair_id, 13 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 574 pair_id, 13 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 575 pair_id, 13 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 576 pair_id, 13 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 577 pair_id, 13 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 578 pair_id, 13 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 579 pair_id, 13 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 580 pair_id, 13 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 581 pair_id, 13 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 582 pair_id, 13 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 583 pair_id, 13 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 584 pair_id, 13 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 585 pair_id, 13 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 586 pair_id, 14 combination_card_1, 15 combination_card_2 FROM DUAL UNION ALL
	SELECT 587 pair_id, 14 combination_card_1, 16 combination_card_2 FROM DUAL UNION ALL
	SELECT 588 pair_id, 14 combination_card_1, 17 combination_card_2 FROM DUAL UNION ALL
	SELECT 589 pair_id, 14 combination_card_1, 18 combination_card_2 FROM DUAL UNION ALL
	SELECT 590 pair_id, 14 combination_card_1, 19 combination_card_2 FROM DUAL UNION ALL
	SELECT 591 pair_id, 14 combination_card_1, 20 combination_card_2 FROM DUAL UNION ALL
	SELECT 592 pair_id, 14 combination_card_1, 21 combination_card_2 FROM DUAL UNION ALL
	SELECT 593 pair_id, 14 combination_card_1, 22 combination_card_2 FROM DUAL UNION ALL
	SELECT 594 pair_id, 14 combination_card_1, 23 combination_card_2 FROM DUAL UNION ALL
	SELECT 595 pair_id, 14 combination_card_1, 24 combination_card_2 FROM DUAL UNION ALL
	SELECT 596 pair_id, 14 combination_card_1, 25 combination_card_2 FROM DUAL UNION ALL
	SELECT 597 pair_id, 14 combination_card_1, 26 combination_card_2 FROM DUAL UNION ALL
	SELECT 598 pair_id, 14 combination_card_1, 27 combination_card_2 FROM DUAL UNION ALL
	SELECT 599 pair_id, 14 combination_card_1, 28 combination_card_2 FROM DUAL UNION ALL
	SELECT 600 pair_id, 14 combination_card_1, 29 combination_card_2 FROM DUAL UNION ALL
	SELECT 601 pair_id, 14 combination_card_1, 30 combination_card_2 FROM DUAL UNION ALL
	SELECT 602 pair_id, 14 combination_card_1, 31 combination_card_2 FROM DUAL UNION ALL
	SELECT 603 pair_id, 14 combination_card_1, 32 combination_card_2 FROM DUAL UNION ALL
	SELECT 604 pair_id, 14 combination_card_1, 33 combination_card_2 FROM DUAL UNION ALL
	SELECT 605 pair_id, 14 combination_card_1, 34 combination_card_2 FROM DUAL UNION ALL
	SELECT 606 pair_id, 14 combination_card_1, 35 combination_card_2 FROM DUAL UNION ALL
	SELECT 607 pair_id, 14 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 608 pair_id, 14 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 609 pair_id, 14 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 610 pair_id, 14 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 611 pair_id, 14 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 612 pair_id, 14 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 613 pair_id, 14 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 614 pair_id, 14 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 615 pair_id, 14 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 616 pair_id, 14 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 617 pair_id, 14 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 618 pair_id, 14 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 619 pair_id, 14 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 620 pair_id, 14 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 621 pair_id, 14 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 622 pair_id, 14 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 623 pair_id, 14 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 624 pair_id, 15 combination_card_1, 16 combination_card_2 FROM DUAL UNION ALL
	SELECT 625 pair_id, 15 combination_card_1, 17 combination_card_2 FROM DUAL UNION ALL
	SELECT 626 pair_id, 15 combination_card_1, 18 combination_card_2 FROM DUAL UNION ALL
	SELECT 627 pair_id, 15 combination_card_1, 19 combination_card_2 FROM DUAL UNION ALL
	SELECT 628 pair_id, 15 combination_card_1, 20 combination_card_2 FROM DUAL UNION ALL
	SELECT 629 pair_id, 15 combination_card_1, 21 combination_card_2 FROM DUAL UNION ALL
	SELECT 630 pair_id, 15 combination_card_1, 22 combination_card_2 FROM DUAL UNION ALL
	SELECT 631 pair_id, 15 combination_card_1, 23 combination_card_2 FROM DUAL UNION ALL
	SELECT 632 pair_id, 15 combination_card_1, 24 combination_card_2 FROM DUAL UNION ALL
	SELECT 633 pair_id, 15 combination_card_1, 25 combination_card_2 FROM DUAL UNION ALL
	SELECT 634 pair_id, 15 combination_card_1, 26 combination_card_2 FROM DUAL UNION ALL
	SELECT 635 pair_id, 15 combination_card_1, 27 combination_card_2 FROM DUAL UNION ALL
	SELECT 636 pair_id, 15 combination_card_1, 28 combination_card_2 FROM DUAL UNION ALL
	SELECT 637 pair_id, 15 combination_card_1, 29 combination_card_2 FROM DUAL UNION ALL
	SELECT 638 pair_id, 15 combination_card_1, 30 combination_card_2 FROM DUAL UNION ALL
	SELECT 639 pair_id, 15 combination_card_1, 31 combination_card_2 FROM DUAL UNION ALL
	SELECT 640 pair_id, 15 combination_card_1, 32 combination_card_2 FROM DUAL UNION ALL
	SELECT 641 pair_id, 15 combination_card_1, 33 combination_card_2 FROM DUAL UNION ALL
	SELECT 642 pair_id, 15 combination_card_1, 34 combination_card_2 FROM DUAL UNION ALL
	SELECT 643 pair_id, 15 combination_card_1, 35 combination_card_2 FROM DUAL UNION ALL
	SELECT 644 pair_id, 15 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 645 pair_id, 15 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 646 pair_id, 15 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 647 pair_id, 15 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 648 pair_id, 15 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 649 pair_id, 15 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 650 pair_id, 15 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 651 pair_id, 15 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 652 pair_id, 15 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 653 pair_id, 15 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 654 pair_id, 15 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 655 pair_id, 15 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 656 pair_id, 15 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 657 pair_id, 15 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 658 pair_id, 15 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 659 pair_id, 15 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 660 pair_id, 15 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 661 pair_id, 16 combination_card_1, 17 combination_card_2 FROM DUAL UNION ALL
	SELECT 662 pair_id, 16 combination_card_1, 18 combination_card_2 FROM DUAL UNION ALL
	SELECT 663 pair_id, 16 combination_card_1, 19 combination_card_2 FROM DUAL UNION ALL
	SELECT 664 pair_id, 16 combination_card_1, 20 combination_card_2 FROM DUAL UNION ALL
	SELECT 665 pair_id, 16 combination_card_1, 21 combination_card_2 FROM DUAL UNION ALL
	SELECT 666 pair_id, 16 combination_card_1, 22 combination_card_2 FROM DUAL UNION ALL
	SELECT 667 pair_id, 16 combination_card_1, 23 combination_card_2 FROM DUAL UNION ALL
	SELECT 668 pair_id, 16 combination_card_1, 24 combination_card_2 FROM DUAL UNION ALL
	SELECT 669 pair_id, 16 combination_card_1, 25 combination_card_2 FROM DUAL UNION ALL
	SELECT 670 pair_id, 16 combination_card_1, 26 combination_card_2 FROM DUAL UNION ALL
	SELECT 671 pair_id, 16 combination_card_1, 27 combination_card_2 FROM DUAL UNION ALL
	SELECT 672 pair_id, 16 combination_card_1, 28 combination_card_2 FROM DUAL UNION ALL
	SELECT 673 pair_id, 16 combination_card_1, 29 combination_card_2 FROM DUAL UNION ALL
	SELECT 674 pair_id, 16 combination_card_1, 30 combination_card_2 FROM DUAL UNION ALL
	SELECT 675 pair_id, 16 combination_card_1, 31 combination_card_2 FROM DUAL UNION ALL
	SELECT 676 pair_id, 16 combination_card_1, 32 combination_card_2 FROM DUAL UNION ALL
	SELECT 677 pair_id, 16 combination_card_1, 33 combination_card_2 FROM DUAL UNION ALL
	SELECT 678 pair_id, 16 combination_card_1, 34 combination_card_2 FROM DUAL UNION ALL
	SELECT 679 pair_id, 16 combination_card_1, 35 combination_card_2 FROM DUAL UNION ALL
	SELECT 680 pair_id, 16 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 681 pair_id, 16 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 682 pair_id, 16 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 683 pair_id, 16 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 684 pair_id, 16 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 685 pair_id, 16 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 686 pair_id, 16 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 687 pair_id, 16 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 688 pair_id, 16 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 689 pair_id, 16 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 690 pair_id, 16 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 691 pair_id, 16 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 692 pair_id, 16 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 693 pair_id, 16 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 694 pair_id, 16 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 695 pair_id, 16 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 696 pair_id, 16 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 697 pair_id, 17 combination_card_1, 18 combination_card_2 FROM DUAL UNION ALL
	SELECT 698 pair_id, 17 combination_card_1, 19 combination_card_2 FROM DUAL UNION ALL
	SELECT 699 pair_id, 17 combination_card_1, 20 combination_card_2 FROM DUAL UNION ALL
	SELECT 700 pair_id, 17 combination_card_1, 21 combination_card_2 FROM DUAL UNION ALL
	SELECT 701 pair_id, 17 combination_card_1, 22 combination_card_2 FROM DUAL UNION ALL
	SELECT 702 pair_id, 17 combination_card_1, 23 combination_card_2 FROM DUAL UNION ALL
	SELECT 703 pair_id, 17 combination_card_1, 24 combination_card_2 FROM DUAL UNION ALL
	SELECT 704 pair_id, 17 combination_card_1, 25 combination_card_2 FROM DUAL UNION ALL
	SELECT 705 pair_id, 17 combination_card_1, 26 combination_card_2 FROM DUAL UNION ALL
	SELECT 706 pair_id, 17 combination_card_1, 27 combination_card_2 FROM DUAL UNION ALL
	SELECT 707 pair_id, 17 combination_card_1, 28 combination_card_2 FROM DUAL UNION ALL
	SELECT 708 pair_id, 17 combination_card_1, 29 combination_card_2 FROM DUAL UNION ALL
	SELECT 709 pair_id, 17 combination_card_1, 30 combination_card_2 FROM DUAL UNION ALL
	SELECT 710 pair_id, 17 combination_card_1, 31 combination_card_2 FROM DUAL UNION ALL
	SELECT 711 pair_id, 17 combination_card_1, 32 combination_card_2 FROM DUAL UNION ALL
	SELECT 712 pair_id, 17 combination_card_1, 33 combination_card_2 FROM DUAL UNION ALL
	SELECT 713 pair_id, 17 combination_card_1, 34 combination_card_2 FROM DUAL UNION ALL
	SELECT 714 pair_id, 17 combination_card_1, 35 combination_card_2 FROM DUAL UNION ALL
	SELECT 715 pair_id, 17 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 716 pair_id, 17 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 717 pair_id, 17 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 718 pair_id, 17 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 719 pair_id, 17 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 720 pair_id, 17 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 721 pair_id, 17 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 722 pair_id, 17 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 723 pair_id, 17 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 724 pair_id, 17 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 725 pair_id, 17 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 726 pair_id, 17 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 727 pair_id, 17 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 728 pair_id, 17 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 729 pair_id, 17 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 730 pair_id, 17 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 731 pair_id, 17 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 732 pair_id, 18 combination_card_1, 19 combination_card_2 FROM DUAL UNION ALL
	SELECT 733 pair_id, 18 combination_card_1, 20 combination_card_2 FROM DUAL UNION ALL
	SELECT 734 pair_id, 18 combination_card_1, 21 combination_card_2 FROM DUAL UNION ALL
	SELECT 735 pair_id, 18 combination_card_1, 22 combination_card_2 FROM DUAL UNION ALL
	SELECT 736 pair_id, 18 combination_card_1, 23 combination_card_2 FROM DUAL UNION ALL
	SELECT 737 pair_id, 18 combination_card_1, 24 combination_card_2 FROM DUAL UNION ALL
	SELECT 738 pair_id, 18 combination_card_1, 25 combination_card_2 FROM DUAL UNION ALL
	SELECT 739 pair_id, 18 combination_card_1, 26 combination_card_2 FROM DUAL UNION ALL
	SELECT 740 pair_id, 18 combination_card_1, 27 combination_card_2 FROM DUAL UNION ALL
	SELECT 741 pair_id, 18 combination_card_1, 28 combination_card_2 FROM DUAL UNION ALL
	SELECT 742 pair_id, 18 combination_card_1, 29 combination_card_2 FROM DUAL UNION ALL
	SELECT 743 pair_id, 18 combination_card_1, 30 combination_card_2 FROM DUAL UNION ALL
	SELECT 744 pair_id, 18 combination_card_1, 31 combination_card_2 FROM DUAL UNION ALL
	SELECT 745 pair_id, 18 combination_card_1, 32 combination_card_2 FROM DUAL UNION ALL
	SELECT 746 pair_id, 18 combination_card_1, 33 combination_card_2 FROM DUAL UNION ALL
	SELECT 747 pair_id, 18 combination_card_1, 34 combination_card_2 FROM DUAL UNION ALL
	SELECT 748 pair_id, 18 combination_card_1, 35 combination_card_2 FROM DUAL UNION ALL
	SELECT 749 pair_id, 18 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 750 pair_id, 18 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 751 pair_id, 18 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 752 pair_id, 18 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 753 pair_id, 18 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 754 pair_id, 18 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 755 pair_id, 18 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 756 pair_id, 18 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 757 pair_id, 18 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 758 pair_id, 18 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 759 pair_id, 18 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 760 pair_id, 18 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 761 pair_id, 18 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 762 pair_id, 18 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 763 pair_id, 18 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 764 pair_id, 18 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 765 pair_id, 18 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 766 pair_id, 19 combination_card_1, 20 combination_card_2 FROM DUAL UNION ALL
	SELECT 767 pair_id, 19 combination_card_1, 21 combination_card_2 FROM DUAL UNION ALL
	SELECT 768 pair_id, 19 combination_card_1, 22 combination_card_2 FROM DUAL UNION ALL
	SELECT 769 pair_id, 19 combination_card_1, 23 combination_card_2 FROM DUAL UNION ALL
	SELECT 770 pair_id, 19 combination_card_1, 24 combination_card_2 FROM DUAL UNION ALL
	SELECT 771 pair_id, 19 combination_card_1, 25 combination_card_2 FROM DUAL UNION ALL
	SELECT 772 pair_id, 19 combination_card_1, 26 combination_card_2 FROM DUAL UNION ALL
	SELECT 773 pair_id, 19 combination_card_1, 27 combination_card_2 FROM DUAL UNION ALL
	SELECT 774 pair_id, 19 combination_card_1, 28 combination_card_2 FROM DUAL UNION ALL
	SELECT 775 pair_id, 19 combination_card_1, 29 combination_card_2 FROM DUAL UNION ALL
	SELECT 776 pair_id, 19 combination_card_1, 30 combination_card_2 FROM DUAL UNION ALL
	SELECT 777 pair_id, 19 combination_card_1, 31 combination_card_2 FROM DUAL UNION ALL
	SELECT 778 pair_id, 19 combination_card_1, 32 combination_card_2 FROM DUAL UNION ALL
	SELECT 779 pair_id, 19 combination_card_1, 33 combination_card_2 FROM DUAL UNION ALL
	SELECT 780 pair_id, 19 combination_card_1, 34 combination_card_2 FROM DUAL UNION ALL
	SELECT 781 pair_id, 19 combination_card_1, 35 combination_card_2 FROM DUAL UNION ALL
	SELECT 782 pair_id, 19 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 783 pair_id, 19 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 784 pair_id, 19 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 785 pair_id, 19 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 786 pair_id, 19 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 787 pair_id, 19 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 788 pair_id, 19 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 789 pair_id, 19 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 790 pair_id, 19 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 791 pair_id, 19 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 792 pair_id, 19 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 793 pair_id, 19 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 794 pair_id, 19 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 795 pair_id, 19 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 796 pair_id, 19 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 797 pair_id, 19 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 798 pair_id, 19 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 799 pair_id, 20 combination_card_1, 21 combination_card_2 FROM DUAL UNION ALL
	SELECT 800 pair_id, 20 combination_card_1, 22 combination_card_2 FROM DUAL UNION ALL
	SELECT 801 pair_id, 20 combination_card_1, 23 combination_card_2 FROM DUAL UNION ALL
	SELECT 802 pair_id, 20 combination_card_1, 24 combination_card_2 FROM DUAL UNION ALL
	SELECT 803 pair_id, 20 combination_card_1, 25 combination_card_2 FROM DUAL UNION ALL
	SELECT 804 pair_id, 20 combination_card_1, 26 combination_card_2 FROM DUAL UNION ALL
	SELECT 805 pair_id, 20 combination_card_1, 27 combination_card_2 FROM DUAL UNION ALL
	SELECT 806 pair_id, 20 combination_card_1, 28 combination_card_2 FROM DUAL UNION ALL
	SELECT 807 pair_id, 20 combination_card_1, 29 combination_card_2 FROM DUAL UNION ALL
	SELECT 808 pair_id, 20 combination_card_1, 30 combination_card_2 FROM DUAL UNION ALL
	SELECT 809 pair_id, 20 combination_card_1, 31 combination_card_2 FROM DUAL UNION ALL
	SELECT 810 pair_id, 20 combination_card_1, 32 combination_card_2 FROM DUAL UNION ALL
	SELECT 811 pair_id, 20 combination_card_1, 33 combination_card_2 FROM DUAL UNION ALL
	SELECT 812 pair_id, 20 combination_card_1, 34 combination_card_2 FROM DUAL UNION ALL
	SELECT 813 pair_id, 20 combination_card_1, 35 combination_card_2 FROM DUAL UNION ALL
	SELECT 814 pair_id, 20 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 815 pair_id, 20 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 816 pair_id, 20 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 817 pair_id, 20 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 818 pair_id, 20 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 819 pair_id, 20 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 820 pair_id, 20 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 821 pair_id, 20 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 822 pair_id, 20 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 823 pair_id, 20 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 824 pair_id, 20 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 825 pair_id, 20 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 826 pair_id, 20 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 827 pair_id, 20 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 828 pair_id, 20 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 829 pair_id, 20 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 830 pair_id, 20 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 831 pair_id, 21 combination_card_1, 22 combination_card_2 FROM DUAL UNION ALL
	SELECT 832 pair_id, 21 combination_card_1, 23 combination_card_2 FROM DUAL UNION ALL
	SELECT 833 pair_id, 21 combination_card_1, 24 combination_card_2 FROM DUAL UNION ALL
	SELECT 834 pair_id, 21 combination_card_1, 25 combination_card_2 FROM DUAL UNION ALL
	SELECT 835 pair_id, 21 combination_card_1, 26 combination_card_2 FROM DUAL UNION ALL
	SELECT 836 pair_id, 21 combination_card_1, 27 combination_card_2 FROM DUAL UNION ALL
	SELECT 837 pair_id, 21 combination_card_1, 28 combination_card_2 FROM DUAL UNION ALL
	SELECT 838 pair_id, 21 combination_card_1, 29 combination_card_2 FROM DUAL UNION ALL
	SELECT 839 pair_id, 21 combination_card_1, 30 combination_card_2 FROM DUAL UNION ALL
	SELECT 840 pair_id, 21 combination_card_1, 31 combination_card_2 FROM DUAL UNION ALL
	SELECT 841 pair_id, 21 combination_card_1, 32 combination_card_2 FROM DUAL UNION ALL
	SELECT 842 pair_id, 21 combination_card_1, 33 combination_card_2 FROM DUAL UNION ALL
	SELECT 843 pair_id, 21 combination_card_1, 34 combination_card_2 FROM DUAL UNION ALL
	SELECT 844 pair_id, 21 combination_card_1, 35 combination_card_2 FROM DUAL UNION ALL
	SELECT 845 pair_id, 21 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 846 pair_id, 21 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 847 pair_id, 21 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 848 pair_id, 21 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 849 pair_id, 21 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 850 pair_id, 21 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 851 pair_id, 21 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 852 pair_id, 21 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 853 pair_id, 21 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 854 pair_id, 21 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 855 pair_id, 21 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 856 pair_id, 21 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 857 pair_id, 21 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 858 pair_id, 21 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 859 pair_id, 21 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 860 pair_id, 21 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 861 pair_id, 21 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 862 pair_id, 22 combination_card_1, 23 combination_card_2 FROM DUAL UNION ALL
	SELECT 863 pair_id, 22 combination_card_1, 24 combination_card_2 FROM DUAL UNION ALL
	SELECT 864 pair_id, 22 combination_card_1, 25 combination_card_2 FROM DUAL UNION ALL
	SELECT 865 pair_id, 22 combination_card_1, 26 combination_card_2 FROM DUAL UNION ALL
	SELECT 866 pair_id, 22 combination_card_1, 27 combination_card_2 FROM DUAL UNION ALL
	SELECT 867 pair_id, 22 combination_card_1, 28 combination_card_2 FROM DUAL UNION ALL
	SELECT 868 pair_id, 22 combination_card_1, 29 combination_card_2 FROM DUAL UNION ALL
	SELECT 869 pair_id, 22 combination_card_1, 30 combination_card_2 FROM DUAL UNION ALL
	SELECT 870 pair_id, 22 combination_card_1, 31 combination_card_2 FROM DUAL UNION ALL
	SELECT 871 pair_id, 22 combination_card_1, 32 combination_card_2 FROM DUAL UNION ALL
	SELECT 872 pair_id, 22 combination_card_1, 33 combination_card_2 FROM DUAL UNION ALL
	SELECT 873 pair_id, 22 combination_card_1, 34 combination_card_2 FROM DUAL UNION ALL
	SELECT 874 pair_id, 22 combination_card_1, 35 combination_card_2 FROM DUAL UNION ALL
	SELECT 875 pair_id, 22 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 876 pair_id, 22 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 877 pair_id, 22 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 878 pair_id, 22 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 879 pair_id, 22 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 880 pair_id, 22 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 881 pair_id, 22 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 882 pair_id, 22 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 883 pair_id, 22 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 884 pair_id, 22 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 885 pair_id, 22 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 886 pair_id, 22 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 887 pair_id, 22 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 888 pair_id, 22 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 889 pair_id, 22 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 890 pair_id, 22 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 891 pair_id, 22 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 892 pair_id, 23 combination_card_1, 24 combination_card_2 FROM DUAL UNION ALL
	SELECT 893 pair_id, 23 combination_card_1, 25 combination_card_2 FROM DUAL UNION ALL
	SELECT 894 pair_id, 23 combination_card_1, 26 combination_card_2 FROM DUAL UNION ALL
	SELECT 895 pair_id, 23 combination_card_1, 27 combination_card_2 FROM DUAL UNION ALL
	SELECT 896 pair_id, 23 combination_card_1, 28 combination_card_2 FROM DUAL UNION ALL
	SELECT 897 pair_id, 23 combination_card_1, 29 combination_card_2 FROM DUAL UNION ALL
	SELECT 898 pair_id, 23 combination_card_1, 30 combination_card_2 FROM DUAL UNION ALL
	SELECT 899 pair_id, 23 combination_card_1, 31 combination_card_2 FROM DUAL UNION ALL
	SELECT 900 pair_id, 23 combination_card_1, 32 combination_card_2 FROM DUAL UNION ALL
	SELECT 901 pair_id, 23 combination_card_1, 33 combination_card_2 FROM DUAL UNION ALL
	SELECT 902 pair_id, 23 combination_card_1, 34 combination_card_2 FROM DUAL UNION ALL
	SELECT 903 pair_id, 23 combination_card_1, 35 combination_card_2 FROM DUAL UNION ALL
	SELECT 904 pair_id, 23 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 905 pair_id, 23 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 906 pair_id, 23 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 907 pair_id, 23 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 908 pair_id, 23 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 909 pair_id, 23 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 910 pair_id, 23 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 911 pair_id, 23 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 912 pair_id, 23 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 913 pair_id, 23 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 914 pair_id, 23 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 915 pair_id, 23 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 916 pair_id, 23 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 917 pair_id, 23 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 918 pair_id, 23 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 919 pair_id, 23 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 920 pair_id, 23 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 921 pair_id, 24 combination_card_1, 25 combination_card_2 FROM DUAL UNION ALL
	SELECT 922 pair_id, 24 combination_card_1, 26 combination_card_2 FROM DUAL UNION ALL
	SELECT 923 pair_id, 24 combination_card_1, 27 combination_card_2 FROM DUAL UNION ALL
	SELECT 924 pair_id, 24 combination_card_1, 28 combination_card_2 FROM DUAL UNION ALL
	SELECT 925 pair_id, 24 combination_card_1, 29 combination_card_2 FROM DUAL UNION ALL
	SELECT 926 pair_id, 24 combination_card_1, 30 combination_card_2 FROM DUAL UNION ALL
	SELECT 927 pair_id, 24 combination_card_1, 31 combination_card_2 FROM DUAL UNION ALL
	SELECT 928 pair_id, 24 combination_card_1, 32 combination_card_2 FROM DUAL UNION ALL
	SELECT 929 pair_id, 24 combination_card_1, 33 combination_card_2 FROM DUAL UNION ALL
	SELECT 930 pair_id, 24 combination_card_1, 34 combination_card_2 FROM DUAL UNION ALL
	SELECT 931 pair_id, 24 combination_card_1, 35 combination_card_2 FROM DUAL UNION ALL
	SELECT 932 pair_id, 24 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 933 pair_id, 24 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 934 pair_id, 24 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 935 pair_id, 24 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 936 pair_id, 24 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 937 pair_id, 24 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 938 pair_id, 24 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 939 pair_id, 24 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 940 pair_id, 24 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 941 pair_id, 24 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 942 pair_id, 24 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 943 pair_id, 24 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 944 pair_id, 24 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 945 pair_id, 24 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 946 pair_id, 24 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 947 pair_id, 24 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 948 pair_id, 24 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 949 pair_id, 25 combination_card_1, 26 combination_card_2 FROM DUAL UNION ALL
	SELECT 950 pair_id, 25 combination_card_1, 27 combination_card_2 FROM DUAL UNION ALL
	SELECT 951 pair_id, 25 combination_card_1, 28 combination_card_2 FROM DUAL UNION ALL
	SELECT 952 pair_id, 25 combination_card_1, 29 combination_card_2 FROM DUAL UNION ALL
	SELECT 953 pair_id, 25 combination_card_1, 30 combination_card_2 FROM DUAL UNION ALL
	SELECT 954 pair_id, 25 combination_card_1, 31 combination_card_2 FROM DUAL UNION ALL
	SELECT 955 pair_id, 25 combination_card_1, 32 combination_card_2 FROM DUAL UNION ALL
	SELECT 956 pair_id, 25 combination_card_1, 33 combination_card_2 FROM DUAL UNION ALL
	SELECT 957 pair_id, 25 combination_card_1, 34 combination_card_2 FROM DUAL UNION ALL
	SELECT 958 pair_id, 25 combination_card_1, 35 combination_card_2 FROM DUAL UNION ALL
	SELECT 959 pair_id, 25 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 960 pair_id, 25 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 961 pair_id, 25 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 962 pair_id, 25 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 963 pair_id, 25 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 964 pair_id, 25 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 965 pair_id, 25 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 966 pair_id, 25 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 967 pair_id, 25 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 968 pair_id, 25 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 969 pair_id, 25 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 970 pair_id, 25 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 971 pair_id, 25 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 972 pair_id, 25 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 973 pair_id, 25 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 974 pair_id, 25 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 975 pair_id, 25 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 976 pair_id, 26 combination_card_1, 27 combination_card_2 FROM DUAL UNION ALL
	SELECT 977 pair_id, 26 combination_card_1, 28 combination_card_2 FROM DUAL UNION ALL
	SELECT 978 pair_id, 26 combination_card_1, 29 combination_card_2 FROM DUAL UNION ALL
	SELECT 979 pair_id, 26 combination_card_1, 30 combination_card_2 FROM DUAL UNION ALL
	SELECT 980 pair_id, 26 combination_card_1, 31 combination_card_2 FROM DUAL UNION ALL
	SELECT 981 pair_id, 26 combination_card_1, 32 combination_card_2 FROM DUAL UNION ALL
	SELECT 982 pair_id, 26 combination_card_1, 33 combination_card_2 FROM DUAL UNION ALL
	SELECT 983 pair_id, 26 combination_card_1, 34 combination_card_2 FROM DUAL UNION ALL
	SELECT 984 pair_id, 26 combination_card_1, 35 combination_card_2 FROM DUAL UNION ALL
	SELECT 985 pair_id, 26 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 986 pair_id, 26 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 987 pair_id, 26 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 988 pair_id, 26 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 989 pair_id, 26 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 990 pair_id, 26 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 991 pair_id, 26 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 992 pair_id, 26 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 993 pair_id, 26 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 994 pair_id, 26 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 995 pair_id, 26 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 996 pair_id, 26 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 997 pair_id, 26 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 998 pair_id, 26 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 999 pair_id, 26 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 1000 pair_id, 26 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 1001 pair_id, 26 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 1002 pair_id, 27 combination_card_1, 28 combination_card_2 FROM DUAL UNION ALL
	SELECT 1003 pair_id, 27 combination_card_1, 29 combination_card_2 FROM DUAL UNION ALL
	SELECT 1004 pair_id, 27 combination_card_1, 30 combination_card_2 FROM DUAL UNION ALL
	SELECT 1005 pair_id, 27 combination_card_1, 31 combination_card_2 FROM DUAL UNION ALL
	SELECT 1006 pair_id, 27 combination_card_1, 32 combination_card_2 FROM DUAL UNION ALL
	SELECT 1007 pair_id, 27 combination_card_1, 33 combination_card_2 FROM DUAL UNION ALL
	SELECT 1008 pair_id, 27 combination_card_1, 34 combination_card_2 FROM DUAL UNION ALL
	SELECT 1009 pair_id, 27 combination_card_1, 35 combination_card_2 FROM DUAL UNION ALL
	SELECT 1010 pair_id, 27 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 1011 pair_id, 27 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 1012 pair_id, 27 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 1013 pair_id, 27 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 1014 pair_id, 27 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 1015 pair_id, 27 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 1016 pair_id, 27 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 1017 pair_id, 27 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 1018 pair_id, 27 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 1019 pair_id, 27 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 1020 pair_id, 27 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 1021 pair_id, 27 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 1022 pair_id, 27 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 1023 pair_id, 27 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 1024 pair_id, 27 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 1025 pair_id, 27 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 1026 pair_id, 27 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 1027 pair_id, 28 combination_card_1, 29 combination_card_2 FROM DUAL UNION ALL
	SELECT 1028 pair_id, 28 combination_card_1, 30 combination_card_2 FROM DUAL UNION ALL
	SELECT 1029 pair_id, 28 combination_card_1, 31 combination_card_2 FROM DUAL UNION ALL
	SELECT 1030 pair_id, 28 combination_card_1, 32 combination_card_2 FROM DUAL UNION ALL
	SELECT 1031 pair_id, 28 combination_card_1, 33 combination_card_2 FROM DUAL UNION ALL
	SELECT 1032 pair_id, 28 combination_card_1, 34 combination_card_2 FROM DUAL UNION ALL
	SELECT 1033 pair_id, 28 combination_card_1, 35 combination_card_2 FROM DUAL UNION ALL
	SELECT 1034 pair_id, 28 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 1035 pair_id, 28 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 1036 pair_id, 28 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 1037 pair_id, 28 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 1038 pair_id, 28 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 1039 pair_id, 28 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 1040 pair_id, 28 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 1041 pair_id, 28 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 1042 pair_id, 28 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 1043 pair_id, 28 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 1044 pair_id, 28 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 1045 pair_id, 28 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 1046 pair_id, 28 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 1047 pair_id, 28 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 1048 pair_id, 28 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 1049 pair_id, 28 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 1050 pair_id, 28 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 1051 pair_id, 29 combination_card_1, 30 combination_card_2 FROM DUAL UNION ALL
	SELECT 1052 pair_id, 29 combination_card_1, 31 combination_card_2 FROM DUAL UNION ALL
	SELECT 1053 pair_id, 29 combination_card_1, 32 combination_card_2 FROM DUAL UNION ALL
	SELECT 1054 pair_id, 29 combination_card_1, 33 combination_card_2 FROM DUAL UNION ALL
	SELECT 1055 pair_id, 29 combination_card_1, 34 combination_card_2 FROM DUAL UNION ALL
	SELECT 1056 pair_id, 29 combination_card_1, 35 combination_card_2 FROM DUAL UNION ALL
	SELECT 1057 pair_id, 29 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 1058 pair_id, 29 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 1059 pair_id, 29 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 1060 pair_id, 29 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 1061 pair_id, 29 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 1062 pair_id, 29 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 1063 pair_id, 29 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 1064 pair_id, 29 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 1065 pair_id, 29 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 1066 pair_id, 29 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 1067 pair_id, 29 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 1068 pair_id, 29 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 1069 pair_id, 29 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 1070 pair_id, 29 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 1071 pair_id, 29 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 1072 pair_id, 29 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 1073 pair_id, 29 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 1074 pair_id, 30 combination_card_1, 31 combination_card_2 FROM DUAL UNION ALL
	SELECT 1075 pair_id, 30 combination_card_1, 32 combination_card_2 FROM DUAL UNION ALL
	SELECT 1076 pair_id, 30 combination_card_1, 33 combination_card_2 FROM DUAL UNION ALL
	SELECT 1077 pair_id, 30 combination_card_1, 34 combination_card_2 FROM DUAL UNION ALL
	SELECT 1078 pair_id, 30 combination_card_1, 35 combination_card_2 FROM DUAL UNION ALL
	SELECT 1079 pair_id, 30 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 1080 pair_id, 30 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 1081 pair_id, 30 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 1082 pair_id, 30 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 1083 pair_id, 30 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 1084 pair_id, 30 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 1085 pair_id, 30 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 1086 pair_id, 30 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 1087 pair_id, 30 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 1088 pair_id, 30 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 1089 pair_id, 30 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 1090 pair_id, 30 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 1091 pair_id, 30 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 1092 pair_id, 30 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 1093 pair_id, 30 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 1094 pair_id, 30 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 1095 pair_id, 30 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 1096 pair_id, 31 combination_card_1, 32 combination_card_2 FROM DUAL UNION ALL
	SELECT 1097 pair_id, 31 combination_card_1, 33 combination_card_2 FROM DUAL UNION ALL
	SELECT 1098 pair_id, 31 combination_card_1, 34 combination_card_2 FROM DUAL UNION ALL
	SELECT 1099 pair_id, 31 combination_card_1, 35 combination_card_2 FROM DUAL UNION ALL
	SELECT 1100 pair_id, 31 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 1101 pair_id, 31 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 1102 pair_id, 31 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 1103 pair_id, 31 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 1104 pair_id, 31 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 1105 pair_id, 31 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 1106 pair_id, 31 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 1107 pair_id, 31 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 1108 pair_id, 31 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 1109 pair_id, 31 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 1110 pair_id, 31 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 1111 pair_id, 31 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 1112 pair_id, 31 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 1113 pair_id, 31 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 1114 pair_id, 31 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 1115 pair_id, 31 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 1116 pair_id, 31 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 1117 pair_id, 32 combination_card_1, 33 combination_card_2 FROM DUAL UNION ALL
	SELECT 1118 pair_id, 32 combination_card_1, 34 combination_card_2 FROM DUAL UNION ALL
	SELECT 1119 pair_id, 32 combination_card_1, 35 combination_card_2 FROM DUAL UNION ALL
	SELECT 1120 pair_id, 32 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 1121 pair_id, 32 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 1122 pair_id, 32 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 1123 pair_id, 32 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 1124 pair_id, 32 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 1125 pair_id, 32 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 1126 pair_id, 32 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 1127 pair_id, 32 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 1128 pair_id, 32 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 1129 pair_id, 32 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 1130 pair_id, 32 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 1131 pair_id, 32 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 1132 pair_id, 32 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 1133 pair_id, 32 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 1134 pair_id, 32 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 1135 pair_id, 32 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 1136 pair_id, 32 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 1137 pair_id, 33 combination_card_1, 34 combination_card_2 FROM DUAL UNION ALL
	SELECT 1138 pair_id, 33 combination_card_1, 35 combination_card_2 FROM DUAL UNION ALL
	SELECT 1139 pair_id, 33 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 1140 pair_id, 33 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 1141 pair_id, 33 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 1142 pair_id, 33 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 1143 pair_id, 33 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 1144 pair_id, 33 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 1145 pair_id, 33 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 1146 pair_id, 33 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 1147 pair_id, 33 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 1148 pair_id, 33 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 1149 pair_id, 33 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 1150 pair_id, 33 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 1151 pair_id, 33 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 1152 pair_id, 33 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 1153 pair_id, 33 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 1154 pair_id, 33 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 1155 pair_id, 33 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 1156 pair_id, 34 combination_card_1, 35 combination_card_2 FROM DUAL UNION ALL
	SELECT 1157 pair_id, 34 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 1158 pair_id, 34 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 1159 pair_id, 34 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 1160 pair_id, 34 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 1161 pair_id, 34 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 1162 pair_id, 34 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 1163 pair_id, 34 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 1164 pair_id, 34 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 1165 pair_id, 34 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 1166 pair_id, 34 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 1167 pair_id, 34 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 1168 pair_id, 34 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 1169 pair_id, 34 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 1170 pair_id, 34 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 1171 pair_id, 34 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 1172 pair_id, 34 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 1173 pair_id, 34 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 1174 pair_id, 35 combination_card_1, 36 combination_card_2 FROM DUAL UNION ALL
	SELECT 1175 pair_id, 35 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 1176 pair_id, 35 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 1177 pair_id, 35 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 1178 pair_id, 35 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 1179 pair_id, 35 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 1180 pair_id, 35 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 1181 pair_id, 35 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 1182 pair_id, 35 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 1183 pair_id, 35 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 1184 pair_id, 35 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 1185 pair_id, 35 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 1186 pair_id, 35 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 1187 pair_id, 35 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 1188 pair_id, 35 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 1189 pair_id, 35 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 1190 pair_id, 35 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 1191 pair_id, 36 combination_card_1, 37 combination_card_2 FROM DUAL UNION ALL
	SELECT 1192 pair_id, 36 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 1193 pair_id, 36 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 1194 pair_id, 36 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 1195 pair_id, 36 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 1196 pair_id, 36 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 1197 pair_id, 36 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 1198 pair_id, 36 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 1199 pair_id, 36 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 1200 pair_id, 36 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 1201 pair_id, 36 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 1202 pair_id, 36 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 1203 pair_id, 36 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 1204 pair_id, 36 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 1205 pair_id, 36 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 1206 pair_id, 36 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 1207 pair_id, 37 combination_card_1, 38 combination_card_2 FROM DUAL UNION ALL
	SELECT 1208 pair_id, 37 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 1209 pair_id, 37 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 1210 pair_id, 37 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 1211 pair_id, 37 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 1212 pair_id, 37 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 1213 pair_id, 37 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 1214 pair_id, 37 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 1215 pair_id, 37 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 1216 pair_id, 37 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 1217 pair_id, 37 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 1218 pair_id, 37 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 1219 pair_id, 37 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 1220 pair_id, 37 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 1221 pair_id, 37 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 1222 pair_id, 38 combination_card_1, 39 combination_card_2 FROM DUAL UNION ALL
	SELECT 1223 pair_id, 38 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 1224 pair_id, 38 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 1225 pair_id, 38 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 1226 pair_id, 38 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 1227 pair_id, 38 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 1228 pair_id, 38 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 1229 pair_id, 38 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 1230 pair_id, 38 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 1231 pair_id, 38 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 1232 pair_id, 38 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 1233 pair_id, 38 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 1234 pair_id, 38 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 1235 pair_id, 38 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 1236 pair_id, 39 combination_card_1, 40 combination_card_2 FROM DUAL UNION ALL
	SELECT 1237 pair_id, 39 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 1238 pair_id, 39 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 1239 pair_id, 39 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 1240 pair_id, 39 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 1241 pair_id, 39 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 1242 pair_id, 39 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 1243 pair_id, 39 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 1244 pair_id, 39 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 1245 pair_id, 39 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 1246 pair_id, 39 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 1247 pair_id, 39 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 1248 pair_id, 39 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 1249 pair_id, 40 combination_card_1, 41 combination_card_2 FROM DUAL UNION ALL
	SELECT 1250 pair_id, 40 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 1251 pair_id, 40 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 1252 pair_id, 40 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 1253 pair_id, 40 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 1254 pair_id, 40 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 1255 pair_id, 40 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 1256 pair_id, 40 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 1257 pair_id, 40 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 1258 pair_id, 40 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 1259 pair_id, 40 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 1260 pair_id, 40 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 1261 pair_id, 41 combination_card_1, 42 combination_card_2 FROM DUAL UNION ALL
	SELECT 1262 pair_id, 41 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 1263 pair_id, 41 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 1264 pair_id, 41 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 1265 pair_id, 41 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 1266 pair_id, 41 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 1267 pair_id, 41 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 1268 pair_id, 41 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 1269 pair_id, 41 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 1270 pair_id, 41 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 1271 pair_id, 41 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 1272 pair_id, 42 combination_card_1, 43 combination_card_2 FROM DUAL UNION ALL
	SELECT 1273 pair_id, 42 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 1274 pair_id, 42 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 1275 pair_id, 42 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 1276 pair_id, 42 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 1277 pair_id, 42 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 1278 pair_id, 42 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 1279 pair_id, 42 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 1280 pair_id, 42 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 1281 pair_id, 42 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 1282 pair_id, 43 combination_card_1, 44 combination_card_2 FROM DUAL UNION ALL
	SELECT 1283 pair_id, 43 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 1284 pair_id, 43 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 1285 pair_id, 43 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 1286 pair_id, 43 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 1287 pair_id, 43 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 1288 pair_id, 43 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 1289 pair_id, 43 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 1290 pair_id, 43 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 1291 pair_id, 44 combination_card_1, 45 combination_card_2 FROM DUAL UNION ALL
	SELECT 1292 pair_id, 44 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 1293 pair_id, 44 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 1294 pair_id, 44 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 1295 pair_id, 44 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 1296 pair_id, 44 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 1297 pair_id, 44 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 1298 pair_id, 44 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 1299 pair_id, 45 combination_card_1, 46 combination_card_2 FROM DUAL UNION ALL
	SELECT 1300 pair_id, 45 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 1301 pair_id, 45 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 1302 pair_id, 45 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 1303 pair_id, 45 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 1304 pair_id, 45 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 1305 pair_id, 45 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 1306 pair_id, 46 combination_card_1, 47 combination_card_2 FROM DUAL UNION ALL
	SELECT 1307 pair_id, 46 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 1308 pair_id, 46 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 1309 pair_id, 46 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 1310 pair_id, 46 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 1311 pair_id, 46 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 1312 pair_id, 47 combination_card_1, 48 combination_card_2 FROM DUAL UNION ALL
	SELECT 1313 pair_id, 47 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 1314 pair_id, 47 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 1315 pair_id, 47 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 1316 pair_id, 47 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 1317 pair_id, 48 combination_card_1, 49 combination_card_2 FROM DUAL UNION ALL
	SELECT 1318 pair_id, 48 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 1319 pair_id, 48 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 1320 pair_id, 48 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 1321 pair_id, 49 combination_card_1, 50 combination_card_2 FROM DUAL UNION ALL
	SELECT 1322 pair_id, 49 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 1323 pair_id, 49 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 1324 pair_id, 50 combination_card_1, 51 combination_card_2 FROM DUAL UNION ALL
	SELECT 1325 pair_id, 50 combination_card_1, 52 combination_card_2 FROM DUAL UNION ALL
	SELECT 1326 pair_id, 51 combination_card_1, 52 combination_card_2 FROM DUAL
),

card_pair_info AS (
	SELECT cp.pair_id,
           cp.combination_card_1,
           cp.combination_card_2,
           d1.suit card_1_suit,
           d1.display_value card_1_display_value,
           d2.suit card_2_suit,
           d2.display_value card_2_display_value,
		   CASE WHEN d1.suit = d2.suit THEN 'Y' ELSE 'N' END suited,
		   CASE WHEN d1.display_value LIKE '10%' THEN 'T'
				ELSE SUBSTR(d1.display_value, 1, 1)
		   END card_1_name,
		   CASE WHEN d2.display_value LIKE '10%' THEN 'T'
				ELSE SUBSTR(d2.display_value, 1, 1)
		   END card_2_name
	FROM   card_pairings cp,
           deck d1,
           deck d2
	WHERE  cp.combination_card_1 = d1.card_id
	   AND cp.combination_card_2 = d2.card_id
	ORDER BY cp.pair_id
),

stats AS (
	SELECT 1 rank, 'AAo' name, 0.7 expected_value, 84.93 win_percent, 0.54 tie_percent, 0.45 occurrence_percent, 0.45 cumulative_percent FROM DUAL UNION ALL
	SELECT 2 rank, 'KKo' name, 0.64 expected_value, 82.11 win_percent, 0.55 tie_percent, 0.45 occurrence_percent, 0.9 cumulative_percent FROM DUAL UNION ALL
	SELECT 3 rank, 'QQo' name, 0.59 expected_value, 79.63 win_percent, 0.58 tie_percent, 0.45 occurrence_percent, 1.35 cumulative_percent FROM DUAL UNION ALL
	SELECT 4 rank, 'JJo' name, 0.54 expected_value, 77.15 win_percent, 0.63 tie_percent, 0.45 occurrence_percent, 1.8 cumulative_percent FROM DUAL UNION ALL
	SELECT 5 rank, 'TTo' name, 0.5 expected_value, 74.66 win_percent, 0.7 tie_percent, 0.45 occurrence_percent, 2.26 cumulative_percent FROM DUAL UNION ALL
	SELECT 6 rank, '99o' name, 0.44 expected_value, 71.66 win_percent, 0.78 tie_percent, 0.45 occurrence_percent, 2.71 cumulative_percent FROM DUAL UNION ALL
	SELECT 7 rank, '88o' name, 0.38 expected_value, 68.71 win_percent, 0.89 tie_percent, 0.45 occurrence_percent, 3.16 cumulative_percent FROM DUAL UNION ALL
	SELECT 8 rank, 'AKs' name, 0.34 expected_value, 66.21 win_percent, 1.65 tie_percent, 0.3 occurrence_percent, 3.46 cumulative_percent FROM DUAL UNION ALL
	SELECT 9 rank, '77o' name, 0.32 expected_value, 65.72 win_percent, 1.02 tie_percent, 0.45 occurrence_percent, 3.92 cumulative_percent FROM DUAL UNION ALL
	SELECT 10 rank, 'AQs' name, 0.32 expected_value, 65.31 win_percent, 1.79 tie_percent, 0.3 occurrence_percent, 4.22 cumulative_percent FROM DUAL UNION ALL
	SELECT 11 rank, 'AJs' name, 0.3 expected_value, 64.39 win_percent, 1.99 tie_percent, 0.3 occurrence_percent, 4.52 cumulative_percent FROM DUAL UNION ALL
	SELECT 12 rank, 'AKo' name, 0.3 expected_value, 64.46 win_percent, 1.7 tie_percent, 0.9 occurrence_percent, 5.42 cumulative_percent FROM DUAL UNION ALL
	SELECT 13 rank, 'ATs' name, 0.29 expected_value, 63.48 win_percent, 2.22 tie_percent, 0.3 occurrence_percent, 5.73 cumulative_percent FROM DUAL UNION ALL
	SELECT 14 rank, 'AQo' name, 0.28 expected_value, 63.5 win_percent, 1.84 tie_percent, 0.9 occurrence_percent, 6.63 cumulative_percent FROM DUAL UNION ALL
	SELECT 15 rank, 'AJo' name, 0.27 expected_value, 62.53 win_percent, 2.05 tie_percent, 0.9 occurrence_percent, 7.54 cumulative_percent FROM DUAL UNION ALL
	SELECT 16 rank, 'KQs' name, 0.26 expected_value, 62.4 win_percent, 1.98 tie_percent, 0.3 occurrence_percent, 7.84 cumulative_percent FROM DUAL UNION ALL
	SELECT 17 rank, '66o' name, 0.26 expected_value, 62.7 win_percent, 1.16 tie_percent, 0.45 occurrence_percent, 8.29 cumulative_percent FROM DUAL UNION ALL
	SELECT 18 rank, 'A9s' name, 0.25 expected_value, 61.5 win_percent, 2.54 tie_percent, 0.3 occurrence_percent, 8.59 cumulative_percent FROM DUAL UNION ALL
	SELECT 19 rank, 'ATo' name, 0.25 expected_value, 61.56 win_percent, 2.3 tie_percent, 0.9 occurrence_percent, 9.5 cumulative_percent FROM DUAL UNION ALL
	SELECT 20 rank, 'KJs' name, 0.25 expected_value, 61.47 win_percent, 2.18 tie_percent, 0.3 occurrence_percent, 9.8 cumulative_percent FROM DUAL UNION ALL
	SELECT 21 rank, 'A8s' name, 0.23 expected_value, 60.5 win_percent, 2.87 tie_percent, 0.3 occurrence_percent, 10.1 cumulative_percent FROM DUAL UNION ALL
	SELECT 22 rank, 'KTs' name, 0.23 expected_value, 60.58 win_percent, 2.4 tie_percent, 0.3 occurrence_percent, 10.4 cumulative_percent FROM DUAL UNION ALL
	SELECT 23 rank, 'KQo' name, 0.22 expected_value, 60.43 win_percent, 2.04 tie_percent, 0.9 occurrence_percent, 11.31 cumulative_percent FROM DUAL UNION ALL
	SELECT 24 rank, 'A7s' name, 0.21 expected_value, 59.38 win_percent, 3.19 tie_percent, 0.3 occurrence_percent, 11.61 cumulative_percent FROM DUAL UNION ALL
	SELECT 25 rank, 'A9o' name, 0.21 expected_value, 59.44 win_percent, 2.64 tie_percent, 0.9 occurrence_percent, 12.51 cumulative_percent FROM DUAL UNION ALL
	SELECT 26 rank, 'KJo' name, 0.21 expected_value, 59.44 win_percent, 2.25 tie_percent, 0.9 occurrence_percent, 13.42 cumulative_percent FROM DUAL UNION ALL
	SELECT 27 rank, '55o' name, 0.2 expected_value, 59.64 win_percent, 1.36 tie_percent, 0.45 occurrence_percent, 13.87 cumulative_percent FROM DUAL UNION ALL
	SELECT 28 rank, 'QJs' name, 0.2 expected_value, 59.07 win_percent, 2.37 tie_percent, 0.3 occurrence_percent, 14.17 cumulative_percent FROM DUAL UNION ALL
	SELECT 29 rank, 'K9s' name, 0.19 expected_value, 58.63 win_percent, 2.7 tie_percent, 0.3 occurrence_percent, 14.47 cumulative_percent FROM DUAL UNION ALL
	SELECT 30 rank, 'A5s' name, 0.19 expected_value, 58.06 win_percent, 3.71 tie_percent, 0.3 occurrence_percent, 14.78 cumulative_percent FROM DUAL UNION ALL
	SELECT 31 rank, 'A6s' name, 0.19 expected_value, 58.17 win_percent, 3.45 tie_percent, 0.3 occurrence_percent, 15.08 cumulative_percent FROM DUAL UNION ALL
	SELECT 32 rank, 'A8o' name, 0.19 expected_value, 58.37 win_percent, 2.99 tie_percent, 0.9 occurrence_percent, 15.98 cumulative_percent FROM DUAL UNION ALL
	SELECT 33 rank, 'KTo' name, 0.19 expected_value, 58.49 win_percent, 2.48 tie_percent, 0.9 occurrence_percent, 16.89 cumulative_percent FROM DUAL UNION ALL
	SELECT 34 rank, 'QTs' name, 0.18 expected_value, 58.17 win_percent, 2.59 tie_percent, 0.3 occurrence_percent, 17.19 cumulative_percent FROM DUAL UNION ALL
	SELECT 35 rank, 'A4s' name, 0.18 expected_value, 57.13 win_percent, 3.79 tie_percent, 0.3 occurrence_percent, 17.49 cumulative_percent FROM DUAL UNION ALL
	SELECT 36 rank, 'A7o' name, 0.17 expected_value, 57.16 win_percent, 3.34 tie_percent, 0.9 occurrence_percent, 18.4 cumulative_percent FROM DUAL UNION ALL
	SELECT 37 rank, 'K8s' name, 0.16 expected_value, 56.79 win_percent, 3.04 tie_percent, 0.3 occurrence_percent, 18.7 cumulative_percent FROM DUAL UNION ALL
	SELECT 38 rank, 'A3s' name, 0.16 expected_value, 56.33 win_percent, 3.77 tie_percent, 0.3 occurrence_percent, 19 cumulative_percent FROM DUAL UNION ALL
	SELECT 39 rank, 'QJo' name, 0.16 expected_value, 56.9 win_percent, 2.45 tie_percent, 0.9 occurrence_percent, 19.9 cumulative_percent FROM DUAL UNION ALL
	SELECT 40 rank, 'K9o' name, 0.15 expected_value, 56.4 win_percent, 2.8 tie_percent, 0.9 occurrence_percent, 20.81 cumulative_percent FROM DUAL UNION ALL
	SELECT 41 rank, 'A5o' name, 0.15 expected_value, 55.74 win_percent, 3.9 tie_percent, 0.9 occurrence_percent, 21.71 cumulative_percent FROM DUAL UNION ALL
	SELECT 42 rank, 'A6o' name, 0.15 expected_value, 55.87 win_percent, 3.62 tie_percent, 0.9 occurrence_percent, 22.62 cumulative_percent FROM DUAL UNION ALL
	SELECT 43 rank, 'Q9s' name, 0.15 expected_value, 56.22 win_percent, 2.88 tie_percent, 0.3 occurrence_percent, 22.92 cumulative_percent FROM DUAL UNION ALL
	SELECT 44 rank, 'K7s' name, 0.15 expected_value, 55.84 win_percent, 3.38 tie_percent, 0.3 occurrence_percent, 23.22 cumulative_percent FROM DUAL UNION ALL
	SELECT 45 rank, 'JTs' name, 0.15 expected_value, 56.15 win_percent, 2.74 tie_percent, 0.3 occurrence_percent, 23.52 cumulative_percent FROM DUAL UNION ALL
	SELECT 46 rank, 'A2s' name, 0.14 expected_value, 55.5 win_percent, 3.74 tie_percent, 0.3 occurrence_percent, 23.83 cumulative_percent FROM DUAL UNION ALL
	SELECT 47 rank, 'QTo' name, 0.14 expected_value, 55.94 win_percent, 2.68 tie_percent, 0.9 occurrence_percent, 24.73 cumulative_percent FROM DUAL UNION ALL
	SELECT 48 rank, '44o' name, 0.14 expected_value, 56.25 win_percent, 1.53 tie_percent, 0.45 occurrence_percent, 25.18 cumulative_percent FROM DUAL UNION ALL
	SELECT 49 rank, 'A4o' name, 0.13 expected_value, 54.73 win_percent, 3.99 tie_percent, 0.9 occurrence_percent, 26.09 cumulative_percent FROM DUAL UNION ALL
	SELECT 50 rank, 'K6s' name, 0.13 expected_value, 54.8 win_percent, 3.67 tie_percent, 0.3 occurrence_percent, 26.39 cumulative_percent FROM DUAL UNION ALL
	SELECT 51 rank, 'K8o' name, 0.12 expected_value, 54.43 win_percent, 3.17 tie_percent, 0.9 occurrence_percent, 27.3 cumulative_percent FROM DUAL UNION ALL
	SELECT 52 rank, 'Q8s' name, 0.12 expected_value, 54.41 win_percent, 3.2 tie_percent, 0.3 occurrence_percent, 27.6 cumulative_percent FROM DUAL UNION ALL
	SELECT 53 rank, 'A3o' name, 0.11 expected_value, 53.85 win_percent, 3.97 tie_percent, 0.9 occurrence_percent, 28.5 cumulative_percent FROM DUAL UNION ALL
	SELECT 54 rank, 'K5s' name, 0.11 expected_value, 53.83 win_percent, 3.91 tie_percent, 0.3 occurrence_percent, 28.8 cumulative_percent FROM DUAL UNION ALL
	SELECT 55 rank, 'J9s' name, 0.11 expected_value, 54.11 win_percent, 3.1 tie_percent, 0.3 occurrence_percent, 29.11 cumulative_percent FROM DUAL UNION ALL
	SELECT 56 rank, 'Q9o' name, 0.1 expected_value, 53.86 win_percent, 2.99 tie_percent, 0.9 occurrence_percent, 30.01 cumulative_percent FROM DUAL UNION ALL
	SELECT 57 rank, 'JTo' name, 0.1 expected_value, 53.82 win_percent, 2.84 tie_percent, 0.9 occurrence_percent, 30.92 cumulative_percent FROM DUAL UNION ALL
	SELECT 58 rank, 'K7o' name, 0.1 expected_value, 53.41 win_percent, 3.54 tie_percent, 0.9 occurrence_percent, 31.82 cumulative_percent FROM DUAL UNION ALL
	SELECT 59 rank, 'A2o' name, 0.09 expected_value, 52.94 win_percent, 3.96 tie_percent, 0.9 occurrence_percent, 32.73 cumulative_percent FROM DUAL UNION ALL
	SELECT 60 rank, 'K4s' name, 0.09 expected_value, 52.88 win_percent, 3.99 tie_percent, 0.3 occurrence_percent, 33.03 cumulative_percent FROM DUAL UNION ALL
	SELECT 61 rank, 'Q7s' name, 0.08 expected_value, 52.52 win_percent, 3.55 tie_percent, 0.3 occurrence_percent, 33.33 cumulative_percent FROM DUAL UNION ALL
	SELECT 62 rank, 'K6o' name, 0.08 expected_value, 52.29 win_percent, 3.85 tie_percent, 0.9 occurrence_percent, 34.23 cumulative_percent FROM DUAL UNION ALL
	SELECT 63 rank, 'K3s' name, 0.08 expected_value, 52.07 win_percent, 3.96 tie_percent, 0.3 occurrence_percent, 34.53 cumulative_percent FROM DUAL UNION ALL
	SELECT 64 rank, 'T9s' name, 0.08 expected_value, 52.37 win_percent, 3.3 tie_percent, 0.3 occurrence_percent, 34.84 cumulative_percent FROM DUAL UNION ALL
	SELECT 65 rank, 'J8s' name, 0.08 expected_value, 52.31 win_percent, 3.4 tie_percent, 0.3 occurrence_percent, 35.14 cumulative_percent FROM DUAL UNION ALL
	SELECT 66 rank, '33o' name, 0.07 expected_value, 52.83 win_percent, 1.7 tie_percent, 0.45 occurrence_percent, 35.59 cumulative_percent FROM DUAL UNION ALL
	SELECT 67 rank, 'Q6s' name, 0.07 expected_value, 51.67 win_percent, 3.86 tie_percent, 0.3 occurrence_percent, 35.89 cumulative_percent FROM DUAL UNION ALL
	SELECT 68 rank, 'Q8o' name, 0.07 expected_value, 51.93 win_percent, 3.33 tie_percent, 0.9 occurrence_percent, 36.8 cumulative_percent FROM DUAL UNION ALL
	SELECT 69 rank, 'K5o' name, 0.06 expected_value, 51.25 win_percent, 4.12 tie_percent, 0.9 occurrence_percent, 37.7 cumulative_percent FROM DUAL UNION ALL
	SELECT 70 rank, 'J9o' name, 0.06 expected_value, 51.63 win_percent, 3.22 tie_percent, 0.9 occurrence_percent, 38.61 cumulative_percent FROM DUAL UNION ALL
	SELECT 71 rank, 'K2s' name, 0.06 expected_value, 51.23 win_percent, 3.94 tie_percent, 0.3 occurrence_percent, 38.91 cumulative_percent FROM DUAL UNION ALL
	SELECT 72 rank, 'Q5s' name, 0.05 expected_value, 50.71 win_percent, 4.11 tie_percent, 0.3 occurrence_percent, 39.21 cumulative_percent FROM DUAL UNION ALL
	SELECT 73 rank, 'T8s' name, 0.04 expected_value, 50.5 win_percent, 3.65 tie_percent, 0.3 occurrence_percent, 39.51 cumulative_percent FROM DUAL UNION ALL
	SELECT 74 rank, 'K4o' name, 0.04 expected_value, 50.22 win_percent, 4.2 tie_percent, 0.9 occurrence_percent, 40.42 cumulative_percent FROM DUAL UNION ALL
	SELECT 75 rank, 'J7s' name, 0.04 expected_value, 50.45 win_percent, 3.74 tie_percent, 0.3 occurrence_percent, 40.72 cumulative_percent FROM DUAL UNION ALL
	SELECT 76 rank, 'Q4s' name, 0.03 expected_value, 49.76 win_percent, 4.18 tie_percent, 0.3 occurrence_percent, 41.02 cumulative_percent FROM DUAL UNION ALL
	SELECT 77 rank, 'Q7o' name, 0.03 expected_value, 49.9 win_percent, 3.72 tie_percent, 0.9 occurrence_percent, 41.93 cumulative_percent FROM DUAL UNION ALL
	SELECT 78 rank, 'T9o' name, 0.03 expected_value, 49.81 win_percent, 3.43 tie_percent, 0.9 occurrence_percent, 42.83 cumulative_percent FROM DUAL UNION ALL
	SELECT 79 rank, 'J8o' name, 0.02 expected_value, 49.71 win_percent, 3.55 tie_percent, 0.9 occurrence_percent, 43.74 cumulative_percent FROM DUAL UNION ALL
	SELECT 80 rank, 'K3o' name, 0.02 expected_value, 49.33 win_percent, 4.18 tie_percent, 0.9 occurrence_percent, 44.64 cumulative_percent FROM DUAL UNION ALL
	SELECT 81 rank, 'Q6o' name, 0.02 expected_value, 48.99 win_percent, 4.05 tie_percent, 0.9 occurrence_percent, 45.55 cumulative_percent FROM DUAL UNION ALL
	SELECT 82 rank, 'Q3s' name, 0.02 expected_value, 48.93 win_percent, 4.16 tie_percent, 0.3 occurrence_percent, 45.85 cumulative_percent FROM DUAL UNION ALL
	SELECT 83 rank, '98s' name, 0.01 expected_value, 48.85 win_percent, 3.88 tie_percent, 0.3 occurrence_percent, 46.15 cumulative_percent FROM DUAL UNION ALL
	SELECT 84 rank, 'T7s' name, 0.01 expected_value, 48.65 win_percent, 3.97 tie_percent, 0.3 occurrence_percent, 46.45 cumulative_percent FROM DUAL UNION ALL
	SELECT 85 rank, 'J6s' name, 0.01 expected_value, 48.57 win_percent, 4.06 tie_percent, 0.3 occurrence_percent, 46.75 cumulative_percent FROM DUAL UNION ALL
	SELECT 86 rank, 'K2o' name, 0.01 expected_value, 48.42 win_percent, 4.17 tie_percent, 0.9 occurrence_percent, 47.66 cumulative_percent FROM DUAL UNION ALL
	SELECT 87 rank, '22o' name, 0 expected_value, 49.38 win_percent, 1.89 tie_percent, 0.45 occurrence_percent, 48.11 cumulative_percent FROM DUAL UNION ALL
	SELECT 88 rank, 'Q2s' name, 0 expected_value, 48.1 win_percent, 4.13 tie_percent, 0.3 occurrence_percent, 48.41 cumulative_percent FROM DUAL UNION ALL
	SELECT 89 rank, 'Q5o' name, 0 expected_value, 47.95 win_percent, 4.32 tie_percent, 0.9 occurrence_percent, 49.32 cumulative_percent FROM DUAL UNION ALL
	SELECT 90 rank, 'J5s' name, 0 expected_value, 47.82 win_percent, 4.33 tie_percent, 0.3 occurrence_percent, 49.62 cumulative_percent FROM DUAL UNION ALL
	SELECT 91 rank, 'T8o' name, 0 expected_value, 47.81 win_percent, 3.8 tie_percent, 0.9 occurrence_percent, 50.52 cumulative_percent FROM DUAL UNION ALL
	SELECT 92 rank, 'J7o' name, 0 expected_value, 47.72 win_percent, 3.91 tie_percent, 0.9 occurrence_percent, 51.43 cumulative_percent FROM DUAL UNION ALL
	SELECT 93 rank, 'Q4o' name, -0.01 expected_value, 46.92 win_percent, 4.4 tie_percent, 0.9 occurrence_percent, 52.33 cumulative_percent FROM DUAL UNION ALL
	SELECT 94 rank, '97s' name, -0.01 expected_value, 46.99 win_percent, 4.25 tie_percent, 0.3 occurrence_percent, 52.63 cumulative_percent FROM DUAL UNION ALL
	SELECT 95 rank, 'J4s' name, -0.01 expected_value, 46.86 win_percent, 4.4 tie_percent, 0.3 occurrence_percent, 52.94 cumulative_percent FROM DUAL UNION ALL
	SELECT 96 rank, 'T6s' name, -0.02 expected_value, 46.8 win_percent, 4.28 tie_percent, 0.3 occurrence_percent, 53.24 cumulative_percent FROM DUAL UNION ALL
	SELECT 97 rank, 'J3s' name, -0.03 expected_value, 46.04 win_percent, 4.37 tie_percent, 0.3 occurrence_percent, 53.54 cumulative_percent FROM DUAL UNION ALL
	SELECT 98 rank, 'Q3o' name, -0.03 expected_value, 46.02 win_percent, 4.38 tie_percent, 0.9 occurrence_percent, 54.44 cumulative_percent FROM DUAL UNION ALL
	SELECT 99 rank, '98o' name, -0.03 expected_value, 46.06 win_percent, 4.05 tie_percent, 0.9 occurrence_percent, 55.35 cumulative_percent FROM DUAL UNION ALL
	SELECT 100 rank, '87s' name, -0.04 expected_value, 45.68 win_percent, 4.5 tie_percent, 0.3 occurrence_percent, 55.65 cumulative_percent FROM DUAL UNION ALL
	SELECT 101 rank, 'T7o' name, -0.04 expected_value, 45.82 win_percent, 4.15 tie_percent, 0.9 occurrence_percent, 56.56 cumulative_percent FROM DUAL UNION ALL
	SELECT 102 rank, 'J6o' name, -0.04 expected_value, 45.71 win_percent, 4.26 tie_percent, 0.9 occurrence_percent, 57.46 cumulative_percent FROM DUAL UNION ALL
	SELECT 103 rank, '96s' name, -0.05 expected_value, 45.15 win_percent, 4.55 tie_percent, 0.3 occurrence_percent, 57.76 cumulative_percent FROM DUAL UNION ALL
	SELECT 104 rank, 'J2s' name, -0.05 expected_value, 45.2 win_percent, 4.35 tie_percent, 0.3 occurrence_percent, 58.06 cumulative_percent FROM DUAL UNION ALL
	SELECT 105 rank, 'Q2o' name, -0.05 expected_value, 45.1 win_percent, 4.37 tie_percent, 0.9 occurrence_percent, 58.97 cumulative_percent FROM DUAL UNION ALL
	SELECT 106 rank, 'T5s' name, -0.05 expected_value, 44.93 win_percent, 4.55 tie_percent, 0.3 occurrence_percent, 59.27 cumulative_percent FROM DUAL UNION ALL
	SELECT 107 rank, 'J5o' name, -0.05 expected_value, 44.9 win_percent, 4.55 tie_percent, 0.9 occurrence_percent, 60.18 cumulative_percent FROM DUAL UNION ALL
	SELECT 108 rank, 'T4s' name, -0.06 expected_value, 44.2 win_percent, 4.65 tie_percent, 0.3 occurrence_percent, 60.48 cumulative_percent FROM DUAL UNION ALL
	SELECT 109 rank, '97o' name, -0.07 expected_value, 44.07 win_percent, 4.45 tie_percent, 0.9 occurrence_percent, 61.38 cumulative_percent FROM DUAL UNION ALL
	SELECT 110 rank, '86s' name, -0.07 expected_value, 43.81 win_percent, 4.84 tie_percent, 0.3 occurrence_percent, 61.68 cumulative_percent FROM DUAL UNION ALL
	SELECT 111 rank, 'J4o' name, -0.07 expected_value, 43.86 win_percent, 4.63 tie_percent, 0.9 occurrence_percent, 62.59 cumulative_percent FROM DUAL UNION ALL
	SELECT 112 rank, 'T6o' name, -0.07 expected_value, 43.84 win_percent, 4.48 tie_percent, 0.9 occurrence_percent, 63.49 cumulative_percent FROM DUAL UNION ALL
	SELECT 113 rank, '95s' name, -0.08 expected_value, 43.31 win_percent, 4.81 tie_percent, 0.3 occurrence_percent, 63.8 cumulative_percent FROM DUAL UNION ALL
	SELECT 114 rank, 'T3s' name, -0.08 expected_value, 43.37 win_percent, 4.62 tie_percent, 0.3 occurrence_percent, 64.1 cumulative_percent FROM DUAL UNION ALL
	SELECT 115 rank, '76s' name, -0.09 expected_value, 42.82 win_percent, 5.08 tie_percent, 0.3 occurrence_percent, 64.4 cumulative_percent FROM DUAL UNION ALL
	SELECT 116 rank, 'J3o' name, -0.09 expected_value, 42.96 win_percent, 4.61 tie_percent, 0.9 occurrence_percent, 65.3 cumulative_percent FROM DUAL UNION ALL
	SELECT 117 rank, '87o' name, -0.09 expected_value, 42.69 win_percent, 4.71 tie_percent, 0.9 occurrence_percent, 66.21 cumulative_percent FROM DUAL UNION ALL
	SELECT 118 rank, 'T2s' name, -0.1 expected_value, 42.54 win_percent, 4.59 tie_percent, 0.3 occurrence_percent, 66.51 cumulative_percent FROM DUAL UNION ALL
	SELECT 119 rank, '85s' name, -0.1 expected_value, 41.99 win_percent, 5.1 tie_percent, 0.3 occurrence_percent, 66.81 cumulative_percent FROM DUAL UNION ALL
	SELECT 120 rank, '96o' name, -0.11 expected_value, 42.1 win_percent, 4.77 tie_percent, 0.9 occurrence_percent, 67.72 cumulative_percent FROM DUAL UNION ALL
	SELECT 121 rank, 'J2o' name, -0.11 expected_value, 42.04 win_percent, 4.59 tie_percent, 0.9 occurrence_percent, 68.62 cumulative_percent FROM DUAL UNION ALL
	SELECT 122 rank, 'T5o' name, -0.11 expected_value, 41.85 win_percent, 4.78 tie_percent, 0.9 occurrence_percent, 69.53 cumulative_percent FROM DUAL UNION ALL
	SELECT 123 rank, '94s' name, -0.12 expected_value, 41.4 win_percent, 4.9 tie_percent, 0.3 occurrence_percent, 69.83 cumulative_percent FROM DUAL UNION ALL
	SELECT 124 rank, '75s' name, -0.12 expected_value, 40.97 win_percent, 5.39 tie_percent, 0.3 occurrence_percent, 70.13 cumulative_percent FROM DUAL UNION ALL
	SELECT 125 rank, 'T4o' name, -0.12 expected_value, 41.05 win_percent, 4.89 tie_percent, 0.9 occurrence_percent, 71.04 cumulative_percent FROM DUAL UNION ALL
	SELECT 126 rank, '93s' name, -0.13 expected_value, 40.8 win_percent, 4.91 tie_percent, 0.3 occurrence_percent, 71.34 cumulative_percent FROM DUAL UNION ALL
	SELECT 127 rank, '86o' name, -0.13 expected_value, 40.69 win_percent, 5.08 tie_percent, 0.9 occurrence_percent, 72.24 cumulative_percent FROM DUAL UNION ALL
	SELECT 128 rank, '65s' name, -0.13 expected_value, 40.34 win_percent, 5.57 tie_percent, 0.3 occurrence_percent, 72.54 cumulative_percent FROM DUAL UNION ALL
	SELECT 129 rank, '84s' name, -0.14 expected_value, 40.1 win_percent, 5.19 tie_percent, 0.3 occurrence_percent, 72.85 cumulative_percent FROM DUAL UNION ALL
	SELECT 130 rank, '95o' name, -0.14 expected_value, 40.13 win_percent, 5.06 tie_percent, 0.9 occurrence_percent, 73.75 cumulative_percent FROM DUAL UNION ALL
	SELECT 131 rank, 'T3o' name, -0.14 expected_value, 40.15 win_percent, 4.87 tie_percent, 0.9 occurrence_percent, 74.66 cumulative_percent FROM DUAL UNION ALL
	SELECT 132 rank, '92s' name, -0.15 expected_value, 39.97 win_percent, 4.88 tie_percent, 0.3 occurrence_percent, 74.96 cumulative_percent FROM DUAL UNION ALL
	SELECT 133 rank, '76o' name, -0.15 expected_value, 39.65 win_percent, 5.33 tie_percent, 0.9 occurrence_percent, 75.86 cumulative_percent FROM DUAL UNION ALL
	SELECT 134 rank, '74s' name, -0.16 expected_value, 39.1 win_percent, 5.48 tie_percent, 0.3 occurrence_percent, 76.16 cumulative_percent FROM DUAL UNION ALL
	SELECT 135 rank, 'T2o' name, -0.16 expected_value, 39.23 win_percent, 4.85 tie_percent, 0.9 occurrence_percent, 77.07 cumulative_percent FROM DUAL UNION ALL
	SELECT 136 rank, '54s' name, -0.17 expected_value, 38.53 win_percent, 5.84 tie_percent, 0.3 occurrence_percent, 77.37 cumulative_percent FROM DUAL UNION ALL
	SELECT 137 rank, '85o' name, -0.17 expected_value, 38.74 win_percent, 5.37 tie_percent, 0.9 occurrence_percent, 78.28 cumulative_percent FROM DUAL UNION ALL
	SELECT 138 rank, '64s' name, -0.17 expected_value, 38.48 win_percent, 5.7 tie_percent, 0.3 occurrence_percent, 78.58 cumulative_percent FROM DUAL UNION ALL
	SELECT 139 rank, '83s' name, -0.18 expected_value, 38.28 win_percent, 5.18 tie_percent, 0.3 occurrence_percent, 78.88 cumulative_percent FROM DUAL UNION ALL
	SELECT 140 rank, '94o' name, -0.18 expected_value, 38.08 win_percent, 5.17 tie_percent, 0.9 occurrence_percent, 79.78 cumulative_percent FROM DUAL UNION ALL
	SELECT 141 rank, '75o' name, -0.18 expected_value, 37.67 win_percent, 5.67 tie_percent, 0.9 occurrence_percent, 80.69 cumulative_percent FROM DUAL UNION ALL
	SELECT 142 rank, '82s' name, -0.19 expected_value, 37.67 win_percent, 5.18 tie_percent, 0.3 occurrence_percent, 80.99 cumulative_percent FROM DUAL UNION ALL
	SELECT 143 rank, '73s' name, -0.19 expected_value, 37.3 win_percent, 5.46 tie_percent, 0.3 occurrence_percent, 81.29 cumulative_percent FROM DUAL UNION ALL
	SELECT 144 rank, '93o' name, -0.19 expected_value, 37.42 win_percent, 5.18 tie_percent, 0.9 occurrence_percent, 82.2 cumulative_percent FROM DUAL UNION ALL
	SELECT 145 rank, '65o' name, -0.2 expected_value, 37.01 win_percent, 5.86 tie_percent, 0.9 occurrence_percent, 83.1 cumulative_percent FROM DUAL UNION ALL
	SELECT 146 rank, '53s' name, -0.2 expected_value, 36.75 win_percent, 5.86 tie_percent, 0.3 occurrence_percent, 83.4 cumulative_percent FROM DUAL UNION ALL
	SELECT 147 rank, '63s' name, -0.2 expected_value, 36.68 win_percent, 5.69 tie_percent, 0.3 occurrence_percent, 83.71 cumulative_percent FROM DUAL UNION ALL
	SELECT 148 rank, '84o' name, -0.21 expected_value, 36.7 win_percent, 5.47 tie_percent, 0.9 occurrence_percent, 84.61 cumulative_percent FROM DUAL UNION ALL
	SELECT 149 rank, '92o' name, -0.21 expected_value, 36.51 win_percent, 5.16 tie_percent, 0.9 occurrence_percent, 85.52 cumulative_percent FROM DUAL UNION ALL
	SELECT 150 rank, '43s' name, -0.22 expected_value, 35.72 win_percent, 5.82 tie_percent, 0.3 occurrence_percent, 85.82 cumulative_percent FROM DUAL UNION ALL
	SELECT 151 rank, '74o' name, -0.22 expected_value, 35.66 win_percent, 5.77 tie_percent, 0.9 occurrence_percent, 86.72 cumulative_percent FROM DUAL UNION ALL
	SELECT 152 rank, '72s' name, -0.23 expected_value, 35.43 win_percent, 5.43 tie_percent, 0.3 occurrence_percent, 87.02 cumulative_percent FROM DUAL UNION ALL
	SELECT 153 rank, '54o' name, -0.23 expected_value, 35.07 win_percent, 6.16 tie_percent, 0.9 occurrence_percent, 87.93 cumulative_percent FROM DUAL UNION ALL
	SELECT 154 rank, '64o' name, -0.23 expected_value, 35 win_percent, 6.01 tie_percent, 0.9 occurrence_percent, 88.83 cumulative_percent FROM DUAL UNION ALL
	SELECT 155 rank, '52s' name, -0.24 expected_value, 34.92 win_percent, 5.83 tie_percent, 0.3 occurrence_percent, 89.14 cumulative_percent FROM DUAL UNION ALL
	SELECT 156 rank, '62s' name, -0.24 expected_value, 34.83 win_percent, 5.66 tie_percent, 0.3 occurrence_percent, 89.44 cumulative_percent FROM DUAL UNION ALL
	SELECT 157 rank, '83o' name, -0.25 expected_value, 34.74 win_percent, 5.46 tie_percent, 0.9 occurrence_percent, 90.34 cumulative_percent FROM DUAL UNION ALL
	SELECT 158 rank, '42s' name, -0.26 expected_value, 33.91 win_percent, 5.82 tie_percent, 0.3 occurrence_percent, 90.64 cumulative_percent FROM DUAL UNION ALL
	SELECT 159 rank, '82o' name, -0.26 expected_value, 34.08 win_percent, 5.48 tie_percent, 0.9 occurrence_percent, 91.55 cumulative_percent FROM DUAL UNION ALL
	SELECT 160 rank, '73o' name, -0.26 expected_value, 33.71 win_percent, 5.76 tie_percent, 0.9 occurrence_percent, 92.45 cumulative_percent FROM DUAL UNION ALL
	SELECT 161 rank, '53o' name, -0.27 expected_value, 33.16 win_percent, 6.19 tie_percent, 0.9 occurrence_percent, 93.36 cumulative_percent FROM DUAL UNION ALL
	SELECT 162 rank, '63o' name, -0.27 expected_value, 33.06 win_percent, 6.01 tie_percent, 0.9 occurrence_percent, 94.26 cumulative_percent FROM DUAL UNION ALL
	SELECT 163 rank, '32s' name, -0.28 expected_value, 33.09 win_percent, 5.78 tie_percent, 0.3 occurrence_percent, 94.57 cumulative_percent FROM DUAL UNION ALL
	SELECT 164 rank, '43o' name, -0.29 expected_value, 32.06 win_percent, 6.15 tie_percent, 0.9 occurrence_percent, 95.47 cumulative_percent FROM DUAL UNION ALL
	SELECT 165 rank, '72o' name, -0.3 expected_value, 31.71 win_percent, 5.74 tie_percent, 0.9 occurrence_percent, 96.38 cumulative_percent FROM DUAL UNION ALL
	SELECT 166 rank, '52o' name, -0.31 expected_value, 31.19 win_percent, 6.18 tie_percent, 0.9 occurrence_percent, 97.28 cumulative_percent FROM DUAL UNION ALL
	SELECT 167 rank, '62o' name, -0.31 expected_value, 31.07 win_percent, 5.99 tie_percent, 0.9 occurrence_percent, 98.19 cumulative_percent FROM DUAL UNION ALL
	SELECT 168 rank, '42o' name, -0.33 expected_value, 30.11 win_percent, 6.16 tie_percent, 0.9 occurrence_percent, 99.09 cumulative_percent FROM DUAL UNION ALL
	SELECT 169 rank, '32o' name, -0.35 expected_value, 29.23 win_percent, 6.12 tie_percent, 0.9 occurrence_percent, 100 cumulative_percent FROM DUAL
)

SELECT cpi.combination_card_1 card_1_id,
	   cpi.combination_card_2 card_2_id,
	   s.rank,
	   s.expected_value,
	   s.win_percent,
	   s.tie_percent,
	   s.occurrence_percent,
	   s.cumulative_percent
FROM   card_pair_info cpi,
	   stats s
WHERE  (cpi.card_1_name || cpi.card_2_name || CASE WHEN cpi.suited = 'Y' THEN 's' ELSE 'o' END = s.name
		OR cpi.card_2_name || cpi.card_1_name || CASE WHEN cpi.suited = 'Y' THEN 's' ELSE 'o' END = s.name)
ORDER BY s.rank;

COMMIT;
