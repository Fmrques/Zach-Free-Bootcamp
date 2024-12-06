-- Cumulative table query -- exercises 1 and 2
select * from actors

INSERT INTO actors (actor, actorid, films, quality_class, is_active)

WITH yesterday AS (
    SELECT * 
    FROM actors
    WHERE films[1].year = 1975
),
today AS (
    SELECT * 
    FROM actor_films
    WHERE year = 1976
),
max_actor_year as (
	select
		actorid,
		max(year) as max_year
	from actor_films
	group by actorid
),
actors_average AS (
    SELECT 
    	t1.actorid as actorid,
        avg(t2.rating) as avg_rating,
        t1.max_year as maxyear
    FROM 
        max_actor_year t1
    left join actor_films t2
    	on t1.actorid = t2.actorid
   		and t1.max_year = t2.year
    GROUP BY 
        t1.actorid,
        t1.max_year
),


merged_data AS (
    SELECT 
        COALESCE(t.actor, y.actor) AS actor,
        COALESCE(t.actorid, y.actorid) AS actorid,
        CASE 
            WHEN y.films IS NULL THEN 
                ARRAY[ROW(t.film, t.year, t.votes, t.rating, t.filmid)::films]
            WHEN y.films IS NOT NULL THEN 
                y.films || ARRAY_REMOVE(ARRAY[ROW(t.film, t.year, t.votes, t.rating, t.filmid)::films], NULL)
            ELSE 
                y.films
        END AS films
        ,CASE 
            WHEN ta.maxyear = 2021 then true 
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
    ARRAY_AGG(film_row) AS films,
    quality_class,
    is_active
   
FROM (
    SELECT 
        actor,
        actorid,
        is_active,
        quality_class,
        film_row
    FROM merged_data, UNNEST(films) AS film_row
    WHERE film_row IS NOT NULL
) unnested_data
GROUP BY actor, actorid, is_active, quality_class
ON CONFLICT (actorid) DO UPDATE
SET films = ARRAY_REMOVE(actors.films || EXCLUDED.films, NULL);
