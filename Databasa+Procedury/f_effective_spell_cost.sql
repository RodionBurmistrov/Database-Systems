CREATE OR REPLACE FUNCTION f_effective_spell_cost(p_spell_id INTEGER, p_caster_id INTEGER)
RETURNS NUMERIC AS $$
DECLARE
    v_base_cost NUMERIC;
    v_category_modifier NUMERIC;
    v_configured_attribute VARCHAR;
    v_attribute_value INTEGER;
    v_ap_modifier NUMERIC;
BEGIN

	-- Zvolime cenu, category modifier, a aky je atribut scalingu
    SELECT s.base_cost, sc.category_modifier, s.configured_attributes
    INTO v_base_cost, v_category_modifier, v_configured_attribute
    FROM spell s
    JOIN spell_category sc ON s.spell_category_id = sc.id
    WHERE s.id = p_spell_id;

	-- Jak v sp_cast_spell preberieme hodnotu atributu a ap modifikator
    SELECT
        CASE v_configured_attribute
            WHEN 'strength' THEN c.strength
            WHEN 'dexterity' THEN c.dexterity
            WHEN 'constitution' THEN c.constitution
            WHEN 'intelligence' THEN c.intelligence
            ELSE 0
        END,
        cl.ap_modifier
    INTO v_attribute_value, v_ap_modifier
    FROM character c
    JOIN class cl ON c.class_id = cl.id
    WHERE c.id = p_caster_id;

	-- Vratim cenu spellu, podla rovnici, nadej zadaniem. Typ atributu zmenime na NUMERIC, aby to nebolo vzdy nula. Lebo povodne som to definoval ako Integer
    RETURN v_base_cost * v_category_modifier * (1 - (v_attribute_value::NUMERIC / 100)) * v_ap_modifier;
END;
$$ LANGUAGE plpgsql;
