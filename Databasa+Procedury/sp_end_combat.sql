CREATE OR REPLACE PROCEDURE sp_end_combat(p_combat_id INTEGER)
LANGUAGE plpgsql AS $$
BEGIN
    -- Update combat na zavrety
    UPDATE combat
    SET status = 'ended'
    WHERE id = p_combat_id;

    -- Charactery su automaticky "Out of Battle"
    UPDATE "character" c
    SET character_status = 'Out of Battle'
    WHERE c.id IN (SELECT DISTINCT character_id 
                   FROM combat_log 
                   WHERE combat_id = p_combat_id 
                   AND character_id IS NOT NULL);
END;
$$;

