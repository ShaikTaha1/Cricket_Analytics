use role accountadmin;
use warehouse compute_wh;
use schema cricket.consumption;

--creating date dimension table of date having data of time
create or replace table date_dim(
    date_id int primary key autoincrement,
    full_dt date,
    day int,
    month int,
    year int,
    quarter int,
    dayofweek int,
    dayofmonth int,
    dayofyear int,
    dayofweekname varchar(3),  -- to store dat names in short like "MON"
    isweekend boolean -- to indicate the weekend
);

-- creating referee dimension table of referees having data of match_referees, reserve_umpires, field_umpires
create or replace table referee_dim(
    referee_id int primary key autoincrement,
    referee_name text not null,
    referee_type text not null
);

-- creating team dimension table having details of the team
create or replace table team_dim(
    team_id int primary key autoincrement,
    team_name text not null
);

--creating player dimension table having details about the players (CHILD table of team_dim table)
create or replace table player_dim(
    player_id int primary key autoincrement,
    team_id int not null,
    player_name text not null
);

-- added foriegn key for joining the player and team table
alter table cricket.consumption.player_dim
add constraint fk_team_player_id
foreign key (team_id)
references cricket.consumption.team_dim (team_id);

-- creating venue dimension table having all details about venue
create or replace table venue_dim(
    venue_id int primary key autoincrement,
    venue_name text not null,
    city text not null,
    state text,
    country text,
    capacity number,
    pitch text,
    flood_light boolean,
    established_dt date,
    playing_are text,
    other_sports text,
    curator text,
    lattitude number(10,6),
    longitude number(10,6)
);

-- creating match type dimension table
create or replace table match_type_dim(
    match_type_id int primary key autoincrement,
    match_type text not null
);

-- match fact table which will have relation with all the requireed dimension table
create or replace table match_fact(
    match_id INT PRIMARY KEY autoincrement,
    date_id INT NOT NULL,
    referee_id INT NOT NULL,
    team_a_id INT NOT NULL,
    team_b_id INT NOT NULL,
    match_type_id INT NOT NULL,
    venue_id INT NOT NULL,
    total_overs number(3),
    balls_per_over number(1),

    
    overs_played_by_team_a number(2),
    bowls_played_by_team_a number(3),
    extra_bowls_played_by_team_a number(3),
    extra_runs_scored_by_team_a number(3),
    fours_by_team_a number(3),
    sixes_by_team_a number(3),
    total_score_by_team_a number(3),
    wicket_lost_by_team_a number(2),

    overs_played_by_team_b number(2),
    bowls_played_by_team_b number(3),
    extra_bowls_played_by_team_b number(3),
    extra_runs_scored_by_team_b number(3),
    fours_by_team_b number(3),
    sixes_by_team_b number(3),
    total_score_by_team_b number(3),
    wicket_lost_by_team_b number(2),

    toss_winner_team_id int not null, 
    toss_decision text not null, 
    match_result text not null, 
    winner_team_id int not null,

    CONSTRAINT fk_date FOREIGN KEY (date_id) REFERENCES date_dim (date_id),
    CONSTRAINT fk_referee FOREIGN KEY (referee_id) REFERENCES referee_dim (referee_id),
    CONSTRAINT fk_team1 FOREIGN KEY (team_a_id) REFERENCES team_dim (team_id),
    CONSTRAINT fk_team2 FOREIGN KEY (team_b_id) REFERENCES team_dim (team_id),
    CONSTRAINT fk_match_type FOREIGN KEY (match_type_id) REFERENCES match_type_dim (match_type_id),
    CONSTRAINT fk_venue FOREIGN KEY (venue_id) REFERENCES venue_dim (venue_id),

    CONSTRAINT fk_toss_winner_team FOREIGN KEY (toss_winner_team_id) REFERENCES team_dim (team_id),
    CONSTRAINT fk_winner_team FOREIGN KEY (winner_team_id) REFERENCES team_dim (team_id)
    
);

-- lets populate the data 
-- we will extract the dimension table data using our detail table from clean layer and it will be based on description field as we don't have master data set.

-- starting with the team dim table
select distinct team_name from (
select first_team as team_name from cricket.clean.match_detail_clean
union all 
select second_team as team_name from cricket.clean.match_detail_clean
);

-- version 2
-- inserting the value into the data set

insert into cricket.consumption.team_dim(team_name)
select distinct team_name from(
select first_team as team_name from cricket.clean.match_detail_clean
union all 
select second_team as team_name from cricket.clean.match_detail_clean
) order by team_name;

-- version 3
-- taking a look to the data set

select * from cricket.consumption.team_dim order by team_name;

-- using the team player *****************************************************

-- version 1
select * from cricket.clean.player_clean_table;

-- version 2
select country, player_name from cricket.clean.player_clean_table group by country, player_name;

-- version 3
select a.country,b.team_id, a.player_name
from cricket.clean.player_clean_table a join cricket.consumption.team_dim b on a.country = b.team_name
group by a.country, b.team_id,a.player_name;

--version 4 inserting the data into dataset
insert into cricket.consumption.player_dim (team_id, player_name)
select b.team_id, a.player_name
from cricket.clean.player_clean_table a join cricket.consumption.team_dim b on a.country=b.team_name
group by b.team_id, a.player_name;

-- version 5 checking the data
select * from cricket.consumption.player_dim;




-- using the Referee Dimension *****************************************************

-- version 1
select * from cricket.clean.match_detail_clean;

-- version 2 here into info we have raw format of referee details available
select info 
from cricket.raw.match_raw_table ; -- limit is optional

-- version 3 
select 
    info:officials.match_referees[0]::text as match_referee,
    info:officials.reserve_umpires[0]::text as reserve_umpire,
    info:officials.tv_umpires[0]::text as tv_umpire,
    info:officials.umpires[0]::text as first_umpire,
    info:officials.umpires[1]::text as second_umpire
    
from cricket.raw.match_raw_table ;

-- using the Venue Dimension *****************************************************

-- version 1
select * from cricket.clean.match_detail_clean;  -- limit is optional

-- version 2
select venue, city from cricket.clean.match_detail_clean;  -- limit is optional

-- version 3
select venue, city from cricket.clean.match_detail_clean
group by venue, city;

-- version 4
insert into cricket.consumption.venue_dim (venue_name,city)
select venue,city 
from (
    select venue,
        case when city is null then 'NA'
        else city
        end as city
    from cricket.clean.match_detail_clean
)
group by venue, city;

-- version 5
select * from cricket.consumption.venue_dim where city = 'Bengaluru';

select city from cricket.consumption.venue_dim group by city having count(1)>1;



-- using the Venue Dimension *****************************************************
-- we have only one match type here

-- version 1
select * from cricket.clean.match_detail_clean ;  -- limit is optional

-- version 2
select match_type from cricket.clean.match_detail_clean group by match_type;

-- version 3 
insert into cricket.consumption.match_type_dim (match_type)
select match_type from cricket.clean.match_detail_clean group by match_type;


-- using the Date Dimension *****************************************************

-- just checking min and max date in dataset
select min(event_date), max(event_date) from cricket.clean.match_detail_clean;








