CREATE OR REPLACE VIEW v_combat_state AS
SELECT c.id AS combat_id, c.current_round, ch.name, ch.current_ap, ch.character_status, c.status
FROM combat c
JOIN combat_log cl ON c.id = cl.combat_id
JOIN character ch ON cl.character_id = ch.id
GROUP BY c.id, c.current_round, ch.name, ch.current_ap, ch.character_status
ORDER BY c.id;
-- Pise status, round a ucastnikov vsetkych bitiek + ich aktualne AP
