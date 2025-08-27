CREATE OR REPLACE PROCEDURE sp_loot_item(p_combat_id INTEGER, p_character_id INTEGER, p_item_id INTEGER)
LANGUAGE plpgsql AS $$
DECLARE
    v_dropped_log_id INTEGER;
    v_current_weight NUMERIC;
    v_item_weight NUMERIC;
    v_inventory_capacity INTEGER;
BEGIN
    -- Check if combat je active
    IF (SELECT status FROM combat WHERE id = p_combat_id) != 'active' THEN
        RAISE EXCEPTION 'Combat is not active.';
    END IF;
    
    -- Najst nieco, co este lezi
    SELECT id INTO v_dropped_log_id
    FROM combat_log
    WHERE combat_id = p_combat_id
      AND action_type = 'New Round: Item dropped'
      AND item_id = p_item_id
      AND is_looted = FALSE
    ORDER BY id ASC
    LIMIT 1;
    
	-- Ak neneslo, tak nic
    IF v_dropped_log_id IS NULL THEN
        RAISE NOTICE 'No available item to loot.';
        RETURN;
    END IF;
    
    -- Kolko vazi to, co ma teraz 
    SELECT COALESCE(SUM(i.weight * ci.quantity), 0)
    INTO v_current_weight
    FROM character_inventory ci
    JOIN item i ON ci.item_id = i.id
    WHERE ci.character_id = p_character_id;
    
	-- Vaha Itemu a kapacita inventara
    SELECT weight INTO v_item_weight FROM item WHERE id = p_item_id;
    SELECT inventory_capacity INTO v_inventory_capacity FROM character WHERE id = p_character_id;
    
	-- Porovnanie ci to vie zobrat
    IF v_current_weight + v_item_weight <= v_inventory_capacity THEN
        -- Pridanie do inventaru
        INSERT INTO character_inventory (character_id, item_id, quantity)
        VALUES (p_character_id, p_item_id, 1)
        ON CONFLICT (character_id, item_id) DO UPDATE  -- ak uz podobny zaznam char+idem je, tak iba spravime +1
        SET quantity = character_inventory.quantity + 1;
        
        -- Update current logu
        UPDATE combat_log 
        SET is_looted = TRUE 
        WHERE id = v_dropped_log_id;
        
        -- Uspech, alebo neuspech
        INSERT INTO combat_log (combat_id, character_id, item_id, action_type, outcome, round_number, timestamp)
        VALUES (p_combat_id, p_character_id, p_item_id, 'loot item', 'success', 
                (SELECT current_round FROM combat WHERE id = p_combat_id), 
                CURRENT_TIMESTAMP);
    ELSE
        RAISE NOTICE 'Inventory capacity exceeded.';
        INSERT INTO combat_log (combat_id, character_id, item_id, action_type, outcome, round_number, timestamp)
        VALUES (p_combat_id, p_character_id, p_item_id, 'loot item', 'failed', 
                (SELECT current_round FROM combat WHERE id = p_combat_id), 
                CURRENT_TIMESTAMP);
    END IF;
END;
$$;