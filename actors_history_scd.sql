
--create scd type
create type scd_type as (
			quality_class quality_class,
			is_active boolean,
			start_date int4,
			end_date int4
)


--backfill query
with last_year_scd as (
	select * from actors_scd
	where current_year = 1976
	and end_date = 1976
),
historical_scd as (
	select 
		actor,
		quality_class,
		is_active,
		start_date,
		end_date
	from actors_scd
	where current_year = 1976
	and end_date < 1976

),
this_year_data as (
	select * from actors
	where current_year = 1977
),
unchanged_records as (
select 
	ts.actor,
	ts.quality_class, 
	ts.is_active,
	ls.start_date, 
	ls.current_year	 as end_year
 from this_year_data ts
 join last_year_scd ls
 on ts.actor = ls.actor
 where ts.quality_class = ls.quality_class
 and ts.is_active = ls.is_active
),
changed_records as (
	select 
		ts.actor,
		unnest(ARRAY[
		ROW(
			ls.quality_class,
			ls.is_active,
			ls.start_date, 
			ls.end_date
		)::scd_type,
		ROW(
			ts.quality_class,
			ts.is_active,
			ts.current_year, 
			ts.current_year
		)::scd_type
		]) as records
	 from this_year_data ts
	 left join last_year_scd ls
	 on ts.actor = ls.actor
	 where (ts.quality_class <> ls.quality_class
	 or ts.is_active <> ls.is_active)
),
unnested_changed_records as (
	select 
		actor,
		(records::scd_type).quality_class,
		(records::scd_type).is_active,
		(records::scd_type).start_date,
	   	(records::scd_type).end_date
	from changed_records

),
new_records as (
	select 
		ts.actor,
		ts.quality_class,
		ts.is_active,
		ts.current_year as start_date,
		ts.current_year as end_date
	from this_year_data ts 
	left join last_year_scd ls
	on ts.actor = ls.actor
	and ls.actor is NULL
)



select * from historical_scd 

union all

select * from unchanged_records

union all

select * from unnested_changed_records

union all

select * from new_records

