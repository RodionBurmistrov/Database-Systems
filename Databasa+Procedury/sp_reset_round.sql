CREATE OR REPLACE PROCEDURE sp_reset_round(p_combat_id INTEGER)
LANGUAGE plpgsql AS $$
DECLARE
    v_random_item_id INTEGER;
BEGIN
    -- Ci bitka vobec je
    IF (SELECT status FROM combat WHERE id = p_combat_id) != 'active' THEN
        RAISE EXCEPTION 'Combat is not active.';
    END IF;

    -- Refresh AP pre vsetkych ucastnikov
    UPDATE character c
    SET current_ap = c.max_ap
    WHERE c.id IN (SELECT DISTINCT character_id 
                   FROM combat_log 
                   WHERE combat_id = p_combat_id 
                   AND character_id IS NOT NULL);
    
    -- +1 round do combatu
    UPDATE combat
    SET current_round = current_round + 1
    WHERE id = p_combat_id;
    
    -- Select random item
    SELECT id INTO v_random_item_id
    FROM item
    ORDER BY RANDOM()
    LIMIT 1;
    
    -- Log s refresh roundom a itemom
    INSERT INTO combat_log (combat_id, action_type, item_id, round_number, timestamp)
    VALUES (p_combat_id, 'New Round: Item dropped', v_random_item_id, 
            (SELECT current_round FROM combat WHERE id = p_combat_id), 
            CURRENT_TIMESTAMP);
END;
$$;
