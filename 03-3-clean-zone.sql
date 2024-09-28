use role accountadmin;
use warehouse compute_wh;
use schema cricket.clean;

-- version 1 
-- extracting the elements from the innings array

select 
    m.info:match_type_number::int as match_type_number,
    m.innings
from cricket.raw.match_raw_table m
where match_type_number =4695; -- validating for a particular match

-- version 2
-- extracting further values from innings array
-- it will show the detailed data of each innings
select 
    m.info:match_type_number::int as match_type_number,
    i.value:team::text as team_name,
    i.*
from cricket.raw.match_raw_table m,
lateral flatten (input => m.innings) i
where match_type_number = 4668;

-- version 3
-- extracting the overs from the innings further
select 
    m.info:match_type_number::int as match_type_number,
    i.value:team::text as team_name,
    --o.* -- for getting all overs 
    d.*
from cricket.raw.match_raw_table m,
lateral flatten (input => m.innings) i,
lateral flatten (input =>i.value:overs) o,
lateral flatten (input => o.value:deliveries) d  --further getting the details of each deliveries
where match_type_number = 4668;

--version 3.1
-- flattening the data further for the details of each delivery played in match
select 
    m.info:match_type_number::int as match_type_number,
    i.value:team::text as team_name,
    o.value:over::int as over,
    d.value:bowler::text as bowler,
    d.value:batter::text as batter,
    d.value:non_striker::text as non_striker,
    d.value:runs.batter::text as runs,
    d.value:runs.extras::text as runs,
    d.value:runs.total::text as total,
from cricket.raw.match_raw_table m,
lateral flatten (input => m.innings) i,
lateral flatten (input =>i.value:overs) o,
lateral flatten (input => o.value:deliveries) d 
where match_type_number = 4668;

-- version 4
-- extracting the extras runs from the table

select 
    m.info:match_type_number::int as match_type_number,
    i.value:team::text as team_name,
    o.value:over::int as over,
    d.value:bowler::text as bowler,
    d.value:batter::text as batter,
    d.value:non_striker::text as non_striker,
    d.value:runs.batter::text as runs,
    d.value:runs.extras::text as runs,
    d.value:runs.total::text as total,
    e.key::text as extras_type,
    e.value::number as extra_runs
    
from cricket.raw.match_raw_table m,
lateral flatten (input => m.innings) i,
lateral flatten (input =>i.value:overs) o,
lateral flatten (input => o.value:deliveries) d,
lateral flatten (input => d.value:extras, outer => True) e
where match_type_number = 4668;

-- version 5
-- fetching out the wickets on deliveries and should be added in the dataset formed

select 
    m.info:match_type_number::int as match_type_number,
    i.value:team::text as team_name,
    o.value:over::int+1 as over, -- +1 for making overs start from 1
    d.value:bowler::text as bowler,
    d.value:batter::text as batter,
    d.value:non_striker::text as non_striker,
    d.value:runs.batter::text as runs,
    d.value:runs.extras::text as runs,
    d.value:runs.total::text as total,
    e.key::text as extras_type,
    e.value::number as extra_runs,
    w.value:player_out::text as player_out,
    w.value:kind::text as player_out_kind,
    w.value:fielders::variant as player_out_fielders,
    
from cricket.raw.match_raw_table m,
lateral flatten (input => m.innings) i,
lateral flatten (input =>i.value:overs) o,
lateral flatten (input => o.value:deliveries) d,
lateral flatten (input => d.value:extras, outer => True) e,
lateral flatten (input => d.value:wickets, outer => True) w
where match_type_number = 4668;

-- version 6
-- creating the clean dellivery table 
create or replace transient table cricket.clean.delivery_clean_table as 
select 
    m.info:match_type_number::int as match_type_number,
    i.value:team::text as team_name,
    o.value:over::int as over, -- +1 for making overs start from 1
    d.value:bowler::text as bowler,
    d.value:batter::text as batter,
    d.value:non_striker::text as non_striker,
    d.value:runs.batter::text as runs,
    d.value:runs.extras::text as extras,
    d.value:runs.total::text as total,
    e.key::text as extras_type,
    e.value::number as extra_runs,
    w.value:player_out::text as player_out,
    w.value:kind::text as player_out_kind,
    w.value:fielders::variant as player_out_fielders,
    m.stg_file_name,
    m.stg_file_row_number,
    m.stg_file_hashkey,
    m.stg_modified_ts
from cricket.raw.match_raw_table m,
lateral flatten (input => m.innings) i,
lateral flatten (input =>i.value:overs) o,
lateral flatten (input => o.value:deliveries) d,
lateral flatten (input => d.value:extras, outer => True) e,
lateral flatten (input => d.value:wickets, outer => True) w;


select distinct match_type_number from cricket.clean.delivery_clean_table; -- total number of unique matches

-- describing the delivery table
desc table cricket.clean.delivery_clean_table;

-- add not null and foriegn key relationships

alter table cricket.clean.delivery_clean_table
modify column match_type_number set not null;

alter table cricket.clean.delivery_clean_table
modify column team_name set not  null;

alter table cricket.clean.delivery_clean_table
modify column over set not null;

alter table cricket.clean.delivery_clean_table
modify column bowler set not null;

alter table cricket.clean.delivery_clean_table
modify column batter set not null;

alter table cricket.clean.delivery_clean_table
modify column non_striker set not null;

--foriegn key relationship
alter table cricket.clean.delivery_clean_table
add constraint fk_delivery_match_id
foreign key (match_type_number)
references cricket.clean .match_detail_clean (match_type_number);