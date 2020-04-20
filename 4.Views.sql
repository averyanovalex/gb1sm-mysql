-- 1. Топология склада (секции и ячейки)
create view store_structure as
select 
	sections.name as `section`,
	cells.code,
	cells.is_blocked 
from cells
join sections on cells.section_id = sections.id 
order by sections.name, cells.code;


select * from store_structure;




-- 2. Количество пустых ячеек по секциям
create view empty_cells_count as
select 
	sections.name as `section`,
	count(*) as `count`
from ( 
		select 
			cells.section_id,
			if (stocks.`count` is null, 0, stocks.`count`) as `count`
		from cells
		left join stocks on cells.id = stocks.cell_id 
) as t1
join sections on  t1.section_id = sections.id
where t1.count = 0
group by sections.name;


select * from empty_cells_count;
