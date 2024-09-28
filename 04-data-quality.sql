-- I have selected the first match in the file

select * from cricket.clean.match_detail_clean
where match_type_number = 4668;

-- selecting the batsman details
select team_name,batter,sum(runs)
from cricket.clean.delivery_clean_table
where match_type_number = 4668
group by team_name, batter
order by 1,2,3 desc;

-- selecting the team details
select team_name, sum(runs) + sum(extras)
from cricket.clean.delivery_clean_table
where match_type_number = 4668
group by team_name 
order by 1,2 desc;