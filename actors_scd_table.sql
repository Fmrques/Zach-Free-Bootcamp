


-- create table actors_scd
create table actors_scd (
	actor text,
	quality_class quality_class,
	is_active boolean,
	start_date int4,
	end_date int4,
	current_year int4,
	primary key (actor, start_date)

);

--insert query into actors_scd
insert into actors_scd

with with_previous as (
select 
actor,
current_year,
quality_class,
is_active,
lag(quality_class) over (partition by actor order by current_year) as previous_quality_class,
lag(is_active) over (partition by actor order by current_year) as previous_is_active

from actors
where current_year <= 1976
),

with_identifier as (
select *,
case when quality_class <> previous_quality_class then 1
     when is_active <> previous_is_active then 1
     else 0
     end as status_identifier
from with_previous),

with_time_status as (
	select *,
	sum(status_identifier) over (partition by actor order by current_year) as streak_identifier
from with_identifier
)

select 
	actor,
	quality_class,
	is_active,
	min(current_year) as start_date,
	max(current_year) as end_date,
	1976 as current_year
from with_time_status
group by actor, is_active, quality_class, streak_identifier
order by actor, streak_identifier