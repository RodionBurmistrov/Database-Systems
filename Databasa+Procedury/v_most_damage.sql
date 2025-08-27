CREATE OR REPLACE VIEW v_most_damage AS
SELECT c.name, SUM(cl.damage_done) AS total_damage
FROM character c
JOIN combat_log cl ON c.id = cl.character_id AND cl.action_type = 'cast spell' AND cl.outcome = 'hit'
GROUP BY c.name
ORDER BY total_damage DESC;
-- Pise aka postava dala najviac damagu