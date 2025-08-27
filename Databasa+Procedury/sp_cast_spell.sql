CREATE OR REPLACE PROCEDURE sp_cast_spell(p_combat_id INTEGER, p_caster_id INTEGER, p_target_id INTEGER, p_spell_id INTEGER)
LANGUAGE plpgsql AS $$
DECLARE
    v_current_ap INTEGER;
    v_effective_cost NUMERIC;
    v_d20_roll INTEGER;
	v_d20_roll_final INTEGER;
    v_attribute_bonus INTEGER;
    v_ac_target INTEGER;
    v_damage NUMERIC;
    v_base_damage NUMERIC;
    v_configured_attribute VARCHAR;
    v_attribute_value INTEGER;
    v_target_health INTEGER;
BEGIN
    -- Pozriet aktivnost combatu
    IF (SELECT status FROM combat WHERE id = p_combat_id) != 'active' THEN
        RAISE EXCEPTION 'Combat is not active.';
    END IF;

    -- Pozrieme pritomnost castera
    IF NOT EXISTS (SELECT 1 FROM combat_log WHERE combat_id = p_combat_id AND character_id = p_caster_id) THEN
        RAISE EXCEPTION 'Caster is not in this combat.';
    END IF;

    -- Pozrieme pritomnost targetu
    IF NOT EXISTS (SELECT 1 FROM combat_log WHERE combat_id = p_combat_id AND character_id = p_target_id) THEN
        RAISE EXCEPTION 'Target is not in this combat.';
    END IF;

    -- Ci caster vobec vie spell
    IF NOT EXISTS (SELECT 1 FROM character_spell WHERE character_id = p_caster_id AND spell_id = p_spell_id) THEN
        RAISE EXCEPTION 'Caster does not know this spell.';
    END IF;

	-- Volanie funkcii na pocitanie ceny spellu, dalej je to iba v_effective_cost
    SELECT current_ap INTO v_current_ap FROM character WHERE id = p_caster_id;
    v_effective_cost := f_effective_spell_cost(p_spell_id, p_caster_id);

	-- Nema AP, teda neide to
    IF v_current_ap < v_effective_cost THEN
        RAISE NOTICE 'Insufficient AP to cast spell.';
        RETURN;
    END IF;

	-- Ak ma, tak sa mu to odcita v tabulke characteri
    UPDATE character SET current_ap = current_ap - v_effective_cost WHERE id = p_caster_id;

	-- Hotovo, pocitame Damage
    SELECT base_damage, configured_attributes INTO v_base_damage, v_configured_attribute FROM spell WHERE id = p_spell_id;

	-- Pozrieme aky to ma atribut na scaling, dalej je v v_attribute_value
    SELECT
        CASE v_configured_attribute
            WHEN 'strength' THEN strength
            WHEN 'dexterity' THEN dexterity
            WHEN 'constitution' THEN constitution
            WHEN 'intelligence' THEN intelligence
            ELSE 0
        END
    INTO v_attribute_value
    FROM character WHERE id = p_caster_id;

	-- Na kalkulaciu tohto som sa pozriel do internetu, konkretne https://stackoverflow.com/questions/1400505/generate-a-random-number-in-the-range-1-10
	-- CEIL teda aj zokruhluje napriklad 0.00001 na 1, ale 0,0000 na 0
    v_d20_roll := CEIL(RANDOM() * 20);
    v_attribute_bonus := v_attribute_value / 5; -- Pre balance, lebo s tym som trochu pohral, aby to realne malo balance
	v_d20_roll_final := v_d20_roll; -- prepisem d20 do zvlast variable, aby som to vypisal v loge
    v_d20_roll := v_d20_roll + v_attribute_bonus; -- toto zvycajne malo od ~10 do az 40, tak muselo sa to vydelit 5, aby to bolo v priemere od 0 
												-- (co musi postava pouzivat to, co jej nepatri) do 20, ak sa jej velmi podari s tym.
												-- a viac priemerne od 4 do 24 (to iba dufat, ze nepriatel nema vsetko na 10 lvl) 

	-- Obrana targetu. Pocita sa cez to, co sme mali dane rovnicu, je to take ze v rozmedzi ~12 (ked postava ma dexterity 2 a bonus 1)  az ~25 (dex=10, armour=10) 
    SELECT 10 + (dexterity / 2) + cl.armor_bonus
    INTO v_ac_target
    FROM character c
    JOIN class cl ON c.class_id = cl.id
    WHERE c.id = p_target_id;


	--	Porovnavanie stastia a obrany a vysledok, update pre character 
    IF v_d20_roll > v_ac_target THEN
        v_damage := v_base_damage * (1 + v_attribute_value / 20.0);
        UPDATE character SET health = GREATEST(0, health - v_damage) WHERE id = p_target_id;
        INSERT INTO combat_log (combat_id, character_id, spell_id, action_type, outcome, round_number, timestamp, d20_roll, ap_worth, damage_done)
        VALUES (p_combat_id, p_caster_id, p_spell_id, 'cast spell', 'hit', (SELECT current_round FROM combat WHERE id = p_combat_id), CURRENT_TIMESTAMP, v_d20_roll_final, v_effective_cost, v_damage);
        
        -- Ak nepriatel ma 0, tak volame endbattle
        SELECT health INTO v_target_health FROM character WHERE id = p_target_id;
        IF v_target_health <= 0 THEN
            CALL sp_end_combat(p_combat_id);
            -- Piseme log na prehru
            INSERT INTO combat_log (combat_id, action_type, outcome, round_number, timestamp)
            VALUES (p_combat_id, 'combat ended', 'target defeated', (SELECT current_round FROM combat WHERE id = p_combat_id), CURRENT_TIMESTAMP);
        END IF;
    ELSE
        INSERT INTO combat_log (combat_id, character_id, spell_id, action_type, outcome, round_number, timestamp, d20_roll, ap_worth)
        VALUES (p_combat_id, p_caster_id, p_spell_id, 'cast spell', 'miss', (SELECT current_round FROM combat WHERE id = p_combat_id), CURRENT_TIMESTAMP, v_d20_roll_final, v_effective_cost);
    END IF;
END;
$$;

