CREATE OR REPLACE PROCEDURE sp_rest_character(p_character_id INTEGER)
LANGUAGE plpgsql AS $$
BEGIN -- if character nie je v bitke, vie si oddychnut
    IF (SELECT character_status FROM character WHERE id = p_character_id) = 'Out of Battle' THEN
        UPDATE character
        SET health = max_health,
            current_ap = max_ap
        WHERE id = p_character_id;
    ELSE
        RAISE NOTICE 'Cannot rest during combat.';
    END IF;
END;
$$;
