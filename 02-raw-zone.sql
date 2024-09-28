use role accountadmin;
use warehouse compute_wh;
use schema cricket.raw;

--creating temporary table inside the raw layer
create or replace transient table cricket.raw.match_raw_table(
    meta object not null,
    info variant not null,
    innings ARRAY not null,
    stg_file_name text not null,
    stg_file_row_number int not null,
    stg_file_hashkey text not null,
    stg_modified_ts timestamp not null
)
comment = 'This is the raw table to store all the json data file with root elements extracted';

--copying all the JSON files into the raw table
copy into cricket.raw.match_raw_table from 
    (
    select 
        t.$1:meta::object as meta, 
        t.$1:info::variant as info, 
        t.$1:innings::array as innings, 
        --
        metadata$filename,
        metadata$file_row_number,
        metadata$file_content_key,
        metadata$file_last_modified
    from @cricket.land.my_stg (file_format => 'cricket.land.my_json_format') t
    )
    on_error = continue;

--lets execute the count number of files
select count(*) from cricket.raw.match_raw_table;

--lets run top 10 records in the table 
select * from cricket.raw.match_raw_table ;