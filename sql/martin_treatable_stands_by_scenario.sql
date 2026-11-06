CREATE OR REPLACE FUNCTION martin_treatable_stands_by_scenario(
    z integer,
    x integer,
    y integer,
    query_params json
)
RETURNS bytea AS $$
DECLARE
    p_mvt bytea;
    p_scenario_id integer := (query_params->>'scenario_id')::int;
BEGIN
    IF p_scenario_id IS NULL THEN
        RAISE EXCEPTION 'Scenario ID is required';
    END IF;

    WITH scenario_input AS (
        SELECT
            scenario.configuration->>'stand_size' AS stand_size,
            scenario.forsys_input->'eligible_stand_ids' AS stand_ids
        FROM planning_scenario scenario
        WHERE scenario.id = p_scenario_id
          AND scenario.deleted_at IS NULL
          AND scenario.result_status = 'SUCCESS'
    ),
    input_stand_ids AS (
        SELECT DISTINCT
            ids.value::bigint AS stand_id,
            scenario_input.stand_size
        FROM scenario_input
        CROSS JOIN LATERAL jsonb_array_elements_text(
            CASE
                WHEN jsonb_typeof(scenario_input.stand_ids) = 'array'
                THEN scenario_input.stand_ids
                ELSE '[]'::jsonb
            END
        ) AS ids(value)
    ),
    tile AS (
        SELECT
            stand.id AS id,
            stand.size AS stand_size,
            ST_AsMVTGeom(
                ST_Transform(stand.geometry, 3857),
                ST_TileEnvelope(z, x, y),
                4096, 64, true
            ) AS geom
        FROM input_stand_ids input
        INNER JOIN stands_stand stand
            ON stand.id = input.stand_id
           AND stand.size = input.stand_size
        WHERE stand.geometry && ST_Transform(
            ST_TileEnvelope(
                z, x, y,
                margin => (64.0 / 4096)
            ),
            4269
        )
    )
    SELECT INTO p_mvt
        ST_AsMVT(
            tile.*,
            'treatable_stands_by_scenario',
            4096,
            'geom'
        )
    FROM tile
    WHERE geom IS NOT NULL;

    RETURN p_mvt;
END $$ LANGUAGE plpgsql STABLE STRICT PARALLEL SAFE;
