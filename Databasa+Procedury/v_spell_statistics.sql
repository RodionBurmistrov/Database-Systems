CREATE OR REPLACE VIEW v_spell_statistics AS
SELECT s.spell_name, COUNT(cl.spell_id) AS usage_count, ROUND(AVG(cl.damage_done), 2) AS avg_damage, 
	ROUND(SUM(CASE WHEN cl.outcome = 'hit' THEN 1 ELSE 0 END) / COUNT(*)::NUMERIC * 100, 2) AS hit_percentage
FROM spell s
JOIN combat_log cl ON s.id = cl.spell_id
WHERE cl.action_type = 'cast spell'
GROUP BY s.spell_name
ORDER BY hit_percentage DESC;
-- Pise kolkokrat sa pouzil spell, jeho priemerny damage a percento kolko krat trafil