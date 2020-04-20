use store;

-- 1.Остатки всех товаров на складе (количество и стоимостная оценка)
-- на складе ведется только количественный учет, поэтому стоимостную оценку производим по формуле:
-- количество * учетная цена

select 
	goods.name as good,
	units.name as unit,
	if (stocks.`count` is null, 0, stocks.`count`) as `count`
from goods
left join stocks on goods.id = stocks.good_id 
left join units on goods.unit_id = units.id 
group by good
order by `count` desc;


-- 2. Остатки определенного товара с указанием сроков годности и ячеек
select 
	goods.name as good,
	units.name as unit,
	stocks.expiration_date as expiration_date,
	(select code from cells where cells.id = stocks.cell_id) as cell,
	if (stocks.`count` is null, 0, stocks.`count`) as `count`
from goods
left join stocks on goods.id = stocks.good_id 
left join units on goods.unit_id = units.id 
where goods.id = 4;


-- 3. Просроченные товары на складе
select 
	cells.code as cell,
	goods.name, 
	stocks.expiration_date,
	stocks.`count` 
from stocks 
join cells on stocks.cell_id = cells.id 
join goods on stocks.good_id = goods.id
where expiration_date <= '2020-05-01'
order by cell, name;


-- 4. Товары, которых никогда не было на складе
select 
	`catalog`.name as`catalog`,
	goods.name as good
from goods 
join `catalog` on goods.catalog_id = `catalog`.id 
left join stocks on goods.id = stocks.good_id 
where stocks.good_id is null
order by `catalog`, good


-- 5.Журнал складских документов (ордеров)
select * from
(
	select 
		co.id as `number`,
		co.order_date as `date`,
		'coming order' as `order type`,
		pa.name as partner,
		co.status,
		co.summ as summ	
	from coming_orders as co 
		join partners as pa on co.partner_id = pa.id 
	union
	select 
		oo.id as `number`,
		oo.order_date as `date`,
		'outgoing order' as `order type`,
		pa.name as partner,
		oo.status,
		oo.summ as summ	
	from outgoing_orders as oo 
	 join partners as pa on oo.partner_id = pa.id 
 ) as orders
order by `date`


-- 6.табличная часть приходного ордера
select 
	co.line_number, 
	goods.name,
	co.expiration_date,
	co.`count`,
	co.summ 
from coming_order_tables as co
join goods on co.good_id = goods.id
where co.order_id = 2



-- 7. Количество товарных позиций на складе
select 
	count(*) as 'Товарных позиций на складе'
from ( 
		select distinct good_id 
		from stocks
		where count > 0
) as t1




-- 8. Товарная ведомость (приход расход) за период с даты по сегодняшний день
select 
	name as 'good',
	sum(in_out.`in`) as 'in_count',
	sum(in_out.`out`) as 'out_count'
from goods 
join (
	select 
		good_id, 
		`count` as 'in',
		0 as `out`
	from coming_order_tables 
	where order_id in (select id from coming_orders where order_date >= '2020-04-21')
	union all
	select 
		good_id, 
		0, 
		`count` 
	from outgoing_order_tables  
	where order_id in (select id from outgoing_orders where order_date >= '2020-04-21')
) as in_out on goods.id = in_out.good_id
group by name
order by name 
;