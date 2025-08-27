CREATE OR REPLACE VIEW v_combat_damage AS
SELECT c.id AS combat_id, SUM(cl.damage_done) AS total_damage
FROM combat c
JOIN combat_log cl ON c.id = cl.combat_id AND cl.action_type = 'cast spell' AND cl.outcome = 'hit'
GROUP BY c.id
ORDER BY total_damage DESC;
-- Pise mnozstvo damagu, spraveneho pocas jednotlivych bitiek