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



create table actors (
		actor text,
		actorid text,
		films films[],
		quality_class quality_class,
		is_active Boolean,
		primary key(actorid)

);

