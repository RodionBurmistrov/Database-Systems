
-- class
CREATE TABLE class (
  id                  SERIAL PRIMARY KEY, --Serial mi dovoluje nezapisovat tuto hodnotu samemu
  class_name          VARCHAR   NOT NULL,
  ap_modifier         NUMERIC   NOT NULL,
  inventory_modifier  NUMERIC   NOT NULL,
  armor_bonus         INTEGER   NOT NULL
);

-- spell_category
CREATE TABLE spell_category (
  id                  SERIAL PRIMARY KEY,
  category_name       VARCHAR   NOT NULL,
  category_modifier   NUMERIC   NOT NULL
);

-- character	
CREATE TABLE character (
  id                   SERIAL PRIMARY KEY,
  name                 VARCHAR   NOT NULL,
  class_id             INTEGER   NOT NULL
    REFERENCES class(id)
    ON UPDATE CASCADE 	-- Ak updatnem classu, character to pociti
    ON DELETE RESTRICT, -- Neviem vymazat classu, ak je aspon jeden char s nou
  strength             INTEGER   NOT NULL,
  dexterity            INTEGER   NOT NULL,
  constitution         INTEGER   NOT NULL,
  intelligence         INTEGER   NOT NULL,
  health               INTEGER   NOT NULL,
  max_health           INTEGER   NOT NULL,
  current_ap           INTEGER   NOT NULL,
  max_ap               INTEGER   NOT NULL,
  inventory_capacity   INTEGER   NOT NULL,
  character_status     VARCHAR   NOT NULL
);

-- spell
CREATE TABLE spell (
  id                    SERIAL PRIMARY KEY,
  spell_name            VARCHAR   NOT NULL,
  base_cost             NUMERIC   NOT NULL,
  base_damage           NUMERIC   NOT NULL,
  configured_attributes VARCHAR,
  spell_category_id     INTEGER   NOT NULL
    REFERENCES spell_category(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
);

-- items
CREATE TABLE item (
  id         SERIAL PRIMARY KEY,
  item_name  VARCHAR   NOT NULL,
  weight     NUMERIC   NOT NULL,
  properties VARCHAR
);

-- combats
CREATE TABLE combat (
  id            SERIAL PRIMARY KEY,
  current_round INTEGER   NOT NULL,
  status        VARCHAR   NOT NULL
);


-- character-spell PIVOTNA
CREATE TABLE character_spell (
  character_id INTEGER NOT NULL
    REFERENCES character(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,	-- Ak sa vymaze jedno z nich, nema zmysel teda cely zaznam
  spell_id     INTEGER NOT NULL
    REFERENCES spell(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  PRIMARY KEY (character_id, spell_id)
);

-- character-item PIVOTNA
CREATE TABLE character_inventory (
  character_id INTEGER NOT NULL
    REFERENCES character(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,	-- Ak sa vymaze jedno z nich, nema zmysel teda cely zaznam
  item_id      INTEGER NOT NULL
    REFERENCES item(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  quantity     INTEGER NOT NULL,
  PRIMARY KEY (character_id, item_id)
);

-- combat_log
CREATE TABLE combat_log (
  id            SERIAL PRIMARY KEY,
  combat_id     INTEGER   NOT NULL
    REFERENCES combat(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,	-- Ak sa vymaze combat, padnu aj jeho logi
  character_id  INTEGER
    REFERENCES character(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL,	-- Ak nieco z toho zanikne, tak nema zmysel vymazavat cely log
  spell_id      INTEGER
    REFERENCES spell(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  item_id       INTEGER
    REFERENCES item(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  action_type   VARCHAR   NOT NULL,
  outcome       VARCHAR,
  round_number  INTEGER   NOT NULL,
  d20_roll      INTEGER,
  ap_worth		INTEGER,
  damage_done   INTEGER,
  heal_done     INTEGER,
  is_looted		BOOLEAN DEFAULT FALSE,
  timestamp     TIMESTAMP NOT NULL

);



-- INDEXY 
-- pouzil som iba tieto, lebo hlavne som pouzival SELECT iba na tieto atributy pocas testingu
CREATE INDEX idx_combat_log_combat_id ON combat_log(combat_id);
CREATE INDEX idx_combat_log_character_id ON combat_log(character_id);
CREATE INDEX idx_combat_log_combat_character_id ON combat_log(combat_id, character_id);
CREATE INDEX idx_character_spell_character_id ON character_spell(character_id);
CREATE INDEX idx_character_inventory_character_id ON character_inventory(character_id);



-- INSERT
-- na testovanie-odovzdanie som sa rozhodol ze mi stacia 2, ved podla navrhu zadania mam cisto 1x1 PVP
INSERT INTO class (class_name, ap_modifier, inventory_modifier, armor_bonus) VALUES
('Warrior', 2, 1.5, 5),
('Mage', 1.5, 0.8, 2);

INSERT INTO spell_category (category_name, category_modifier) VALUES
('Sword Arts', 1.2),
('Fire Magic', 1.0);

INSERT INTO character (name, class_id, strength, dexterity, constitution, intelligence, health, max_health, current_ap, max_ap, inventory_capacity, character_status) VALUES
('Aragorn', 1, 15, 4, 14, 10, 50, 50, 55, 55, 44, 'Out of Battle'),
('Gendalf', 2, 8, 2, 9, 16, 40, 40, 39, 39, 14, 'Out of Battle');

INSERT INTO spell (spell_name, base_cost, base_damage, configured_attributes, spell_category_id) VALUES
('SwordAttack', 5.0, 15.0, 'strength', 1),
('FireBall', 4.0, 10.0, 'intelligence', 2);

INSERT INTO item (item_name, weight, properties) VALUES
('Healing Potion', 1.0, '10'),
('Sword', 3.0, '20');

INSERT INTO character_spell (character_id, spell_id) VALUES
(1, 1), -- Aragorn vie SwordAttack
(2, 2); -- Gandalf knows FireBall

INSERT INTO character_inventory (character_id, item_id, quantity) VALUES
(1, 2, 1), -- Aragorn ma 1 mec
(2, 1, 2); -- Gandalf ma 2 lieki

INSERT INTO combat (current_round, status) VALUES
(0, 'waiting');