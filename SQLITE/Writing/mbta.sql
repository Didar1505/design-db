PRAGMA foreign_keys = ON;
CREATE TABLE "cards" (
    "id" INTEGER PRIMARY KEY,
    "balance" NUMERIC DEFAULT 0,
    "created_at" NUMERIC DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE "stations" (
    "id" INTEGER PRIMARY KEY,
    "name" TEXT NOT NULL UNIQUE,
    "line" TEXT NOT NULL,
    "zone" INTEGER
);
CREATE TABLE "transactions" (
    "id" INTEGER PRIMARY KEY,
    "card_id" INTEGER,
    "station_id" INTEGER,
    "amount" NUMERIC NOT NULL CHECK("amount" != 0),
    "datetime" NUMERIC DEFAULT CURRENT_TIMESTAMP,
    "type" TEXT NOT NULL CHECK("type" IN ('enter', 'exit', 'deposit')),

    FOREIGN KEY ("card_id")
        REFERENCES "cards"("id")
        ON DELETE CASCADE,

    FOREIGN KEY ("station_id")
        REFERENCES "stations"("id")
);

-- Добавление транспортных карт
INSERT INTO cards (id, balance)
VALUES (1, 25.00);

INSERT INTO cards (id, balance)
VALUES (2, 50.00);

INSERT INTO cards (id, balance)
VALUES (3, 12.50);


-- Добавление станций
INSERT INTO stations (id, name, line, zone)
VALUES (1, 'Central Station', 'Red', 1);

INSERT INTO stations (id, name, line, zone)
VALUES (2, 'University', 'Green', 2);

INSERT INTO stations (id, name, line, zone)
VALUES (3, 'Airport', 'Blue', 3);


-- Добавление операций
INSERT INTO transactions (id, card_id, station_id, amount, type)
VALUES (1, 1, 1, -2.50, 'enter');

INSERT INTO transactions (id, card_id, station_id, amount, type)
VALUES (2, 1, 2, -2.50, 'exit');

INSERT INTO transactions (id, card_id, station_id, amount, type)
VALUES (3, 2, 3, -4.00, 'enter');

INSERT INTO transactions (id, card_id, station_id, amount, type)
VALUES (4, 2, 3, 20.00, 'deposit');

INSERT INTO transactions (id, card_id, station_id, amount, type)
VALUES (5, 3, 1, -2.50, 'enter');