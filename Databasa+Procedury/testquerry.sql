SELECT c.name, cl.class_name, s.spell_name, sc.category_name, i.item_name, ci.quantity
FROM character c
join class cl on c.class_id = cl.id
join character_spell cp on cp.character_id = c.id
join spell s on s.id=cp.spell_id 
join spell_category sc on sc.id = s.spell_category_id
join character_inventory ci on ci.character_id = c.id
join item i on i.id = ci.item_id
