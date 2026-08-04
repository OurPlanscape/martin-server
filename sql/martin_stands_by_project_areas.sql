CREATE OR REPLACE FUNCTION martin_stands_by_project_areas(
    z integer,
    x integer,
    y integer,
    query_params json
)
RETURNS bytea AS $$
DECLARE
    p_mvt bytea;
    p_scenario_id integer := (query_params->>'scenario_id')::int;
    p_stand_size varchar;
    p_scenario_type varchar;
BEGIN

    IF p_scenario_id IS NULL THEN
        RAISE EXCEPTION 'Scenario ID is required';
    END IF;

    SELECT
        scenario.configuration->>'stand_size',
        scenario.type
    INTO
        p_stand_size,
        p_scenario_type
    FROM planning_scenario scenario
    WHERE
        scenario.id = p_scenario_id
        AND scenario.deleted_at IS NULL;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Could not find Scenario';
    END IF;

    IF p_scenario_type IS DISTINCT FROM 'PROJECT_AREAS' THEN
        RAISE EXCEPTION 'Scenario type must be PROJECT_AREAS';
    END IF;

    IF p_stand_size IS NULL THEN
        RAISE EXCEPTION 'Scenario stand size is required';
    END IF;

    WITH project_areas AS (
        SELECT
            pa.id,
            pa.name,
            pa.geometry
        FROM planning_projectarea pa
        WHERE
            pa.scenario_id = p_scenario_id
            AND pa.deleted_at IS NULL
            AND (
                (query_params->>'project_area_id') IS NULL
                OR pa.id = (query_params->>'project_area_id')::int
            )
    )
    SELECT INTO p_mvt
        ST_AsMVT(
            tile,
            'stands_by_project_areas',
            4096,
            'geom'
        )
    FROM (
        SELECT
            stand.id AS id,
            stand.size AS stand_size,
            p_scenario_id AS scenario_id,
            project_area.id AS project_area_id,
            project_area.name AS project_area_name,
            ST_AsMVTGeom(
                ST_Transform(stand.geometry, 3857),
                ST_TileEnvelope(z, x, y),
                4096,
                64,
                true
            ) AS geom
        FROM stands_stand stand
        INNER JOIN project_areas project_area
            ON stand.geometry && project_area.geometry
            AND ST_Within(
                ST_Centroid(stand.geometry),
                project_area.geometry
            )
        WHERE
            stand.size = p_stand_size
            AND stand.geometry && ST_Transform(
                ST_TileEnvelope(
                    z,
                    x,
                    y,
                    margin => (64.0 / 4096)
                ),
                4269
            )
    ) AS tile
    WHERE geom IS NOT NULL;

    RETURN p_mvt;

END $$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;