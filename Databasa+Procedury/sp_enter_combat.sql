CREATE OR REPLACE PROCEDURE sp_enter_combat(p_combat_id INTEGER, p_character_id INTEGER) 
LANGUAGE plpgsql AS $$
DECLARE
    v_current_ap INTEGER;
BEGIN	

    -- Check if character je free
    IF (SELECT character_status FROM character WHERE id = p_character_id) != 'Out of Battle' THEN
        RAISE EXCEPTION 'Cant enter. Already in combat.';
    END IF;
	
    -- vytiehneme aktualny AP z characteru
    SELECT current_ap INTO v_current_ap FROM character WHERE id = p_character_id;

	--update characteru, ze je v bitke, toto bude potrebne dalej pre to, aby nevedel pouzit rest
    UPDATE character SET character_status = 'In Combat' WHERE id = p_character_id;
    INSERT INTO combat_log (combat_id, character_id, action_type, outcome, round_number, timestamp, ap_worth)
    VALUES (p_combat_id, p_character_id, 'enter combat', 'success', 0, CURRENT_TIMESTAMP, v_current_ap);
END;
$$;