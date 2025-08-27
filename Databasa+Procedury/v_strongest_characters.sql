CREATE OR REPLACE VIEW v_strongest_characters AS
SELECT c.name, (c.strength + c.dexterity + c.constitution + c.intelligence) AS total_stats, c.current_ap, c.health, SUM(cl.damage_done) AS total_damage_dealt
FROM character c
JOIN combat_log cl ON c.id = cl.character_id AND cl.action_type = 'cast spell' AND cl.outcome = 'hit'
GROUP BY c.name, c.strength, c.dexterity, c.constitution, c.intelligence, c.current_ap, c.health
ORDER BY total_stats DESC, c.current_ap DESC, total_damage_dealt DESC;
-- Pise statistika postav, summu parametrov, aktialne zdravie a AP a kolko spravili calkovo damage