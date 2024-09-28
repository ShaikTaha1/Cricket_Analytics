--using role and selecting warehouse
use role sysadmin;
use warehouse compute_wh;

--creating Database 
create database if not exists cricket;

--creating schemas as per requirement
create or replace schema cricket.land;
create or replace schema cricket.raw; 
create or replace schema cricket.clean; 
create or replace schema cricket.consumption;

show schemas  in database cricket; --to view the schemas in the database

--change context and defining further in schema
use schema cricket.land;

-- creating JSON file format (for handling and filtering specific type of data here JSON)
create or replace file format cricket.land.my_json_format
    type = json
    null_if =('\\n','null','')
    strip_outer_array = true
    comment= 'Json File Format with outer strip array flag true'

-- creating internal stage (For temporarily holding the data at time of operation)
create or replace stage cricket.land.my_stg;

--listing the files if there in stage
list @cricket.land.my_stg;

--checking if Data is being loaded or not "list @my_stg/cricket/json/;" alternate query
list @my_stg;

--quick check if the data is comming correctly or not  THIS IS PARSING OF DATA
select 
        t.$1:meta::variant as meta, 
        t.$1:info::variant as info, 
        t.$1:innings::array as innings, 
        metadata$filename as file_name,
        metadata$file_row_number int,
        metadata$file_content_key text,
        metadata$file_last_modified stg_modified_ts
from @my_stg/1384412.json(file_format => 'my_json_format') t;