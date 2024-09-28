use role accountadmin;
use warehouse compute_wh;
use schema cricket.clean;

-- extract players 
-- version -1
select 
    raw.info:match_type_number::int as match_type_number,
    raw.info:players,
    raw.info:teams
from cricket.raw.match_raw_table raw;

--version 2  
-- Validating the Data and observing the JSON file 

select 
    raw.info:match_type_number::int as match_type_number,
    raw.info:players,
    raw.info:teams
from cricket.raw.match_raw_table raw
where match_type_number = 4668;

-- version 3 
-- Flattening the JSON data of PLAYERS and getting the data with and without key for a match

select 
    raw.info:match_type_number::int as match_type_number,
    --p.*
     p.key::text as country
from cricket.raw.match_raw_table raw,
lateral flatten (input => raw.info:players) p,
where match_type_number=4668;

-- version 4
-- Flattening the JSON data of TEAM and getting the data with and without key for a match

select 
    raw.info:match_type_number::int as match_type_number,
     p.key::text as country,
     --team.*
     team.value:: text as player_name
from cricket.raw.match_raw_table raw,
lateral flatten (input => raw.info:players) p,
lateral flatten (input => p.value) team
where match_type_number=4668;


--versionn 5
-- create table for player
 
create or replace table cricket.clean.player_clean_table as 
select 
    raw.info:match_type_number::int as match_type_number, 
    p.key::text as country,
    team.value:: text as player_name,
    stg_file_name ,
    stg_file_row_number,
    stg_file_hashkey,
    stg_modified_ts
from cricket.raw.match_raw_table raw,
lateral flatten (input => raw.info:players) p,
lateral flatten (input => p.value) team;


-- lets describe the table 
desc table cricket.clean.player_clean_table;

-- getting detail of the table 
select get_ddl('table','cricket.clean.player_clean_table');
select * from cricket.clean.player_clean_table;

--describing not null values and foriegn key relationships

alter table cricket.clean.player_clean_table
modify column match_type_number set not null;

alter table cricket.clean.player_clean_table
modify column country set not null;

alter table cricket.clean.player_clean_table 
modify column player_name set not null;

--creating primary key on match detail table to create foriegn key further

alter table cricket.clean.match_detail_clean
add constraint pk_match_type_number primary key (match_type_number);

--adding foreign key 
alter table cricket.clean.player_clean_table
add constraint fk_match_id
foreign key (match_type_number)
references cricket.clean.match_detail_clean(match_type_number)
