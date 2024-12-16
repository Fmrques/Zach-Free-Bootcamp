-- Cumulative table query -- exercises 1 and 2
-- Creating quality_class with enum:
create type quality_class as enum('star', 'good','average', 'bad');

-- create type films for array
create type films as (
		film text,
		year int4,
		votes int4,
		rating float4,
		filmid text		
);

--create table actors
create table actors (
		actor text,
		actorid text,
		current_year int4,
		films films[],
		quality_class quality_class,
		is_active Boolean,
		primary key(actorid, current_year)

);


-- insert query into actors
INSERT INTO actors (actor, actorid, current_year, films, quality_class, is_active)

WITH yesterday AS (
    SELECT * 
    FROM actors
    WHERE current_year = 1977
),
today AS (
    SELECT * 
    FROM actor_films
    WHERE year = 1978
),
actors_average AS (
    SELECT 
    	t1.actorid as actorid,
        avg(t1.rating) as avg_rating
    FROM today t1
    GROUP BY 
        t1.actorid
),


merged_data AS (
    SELECT 
        COALESCE(t.actor, y.actor) AS actor,
        COALESCE(t.actorid, y.actorid) AS actorid,
        COALESCE(t.YEAR, y.current_year + 1) AS current_year,
        CASE 
            WHEN y.films IS NULL THEN 
                ARRAY[ROW(t.film, t.votes, t.rating, t.filmid)::films]
            WHEN y.films IS NOT NULL THEN 
                y.films || ARRAY_REMOVE(ARRAY[ROW(t.film, t.votes, t.rating, t.filmid)::films], NULL)
            ELSE 
                y.films
        END AS films
        ,CASE 
            WHEN t.year is not NULL then true 
            else false 
            end as is_active
        ,CASE 
            WHEN t.year IS NOT NULL THEN 
                CASE 
                    WHEN ta.avg_rating > 8 THEN 'star'::quality_class
                    WHEN ta.avg_rating > 7 THEN 'good'::quality_class
                    WHEN ta.avg_rating > 6 THEN 'average'::quality_class
                    ELSE 'bad'::quality_class
                END
            ELSE y.quality_class::quality_class
        END AS quality_class
    FROM today t 
    LEFT JOIN actors_average ta 
      ON t.actorid = ta.actorid
    FULL OUTER JOIN yesterday y
        ON t.actorid = y.actorid
)

SELECT 
    actor,
    actorid,
    current_year,
    ARRAY_AGG(film_row) AS films,
    quality_class,
    is_active
   
FROM (
    SELECT 
        actor,
        actorid,
        current_year,
        is_active,
        quality_class,
        film_row
    FROM merged_data, UNNEST(films) AS film_row
    WHERE film_row IS NOT NULL
) unnested_data
GROUP BY actor, actorid, current_year, is_active, quality_class;
