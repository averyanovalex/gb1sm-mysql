-- 1.Создать новый приходный ордер.
-- Создается пустой приходный ордер без строк в статусе is_planned
-- (запись только в таблице coming_orders)

drop procedure if exists `sp_add_comming_order`;

delimiter $$

create procedure `sp_add_comming_order`(order_date date, partner_id bigint, comment varchar(255), 
											out tran_result varchar(200))
begin
	
	-- объявляем переменные
	declare `_rollback` bool default 0;
   	declare code varchar(100);
   	declare error_string varchar(100);
   
    -- обработка ошибок
    declare continue handler for sqlexception
    begin
    	set `_rollback` = 1;
	get stacked diagnostics condition 1
          code = returned_sqlstate, error_string = message_text;
    	set tran_result := concat('error occured. code: ', code, '. text: ', error_string);
    end;
   
    -- старт
    start transaction;
	
    -- вставляем строку
    insert into coming_orders (order_date, status, partner_id, comment)
	  values (order_date, 'is_planned', partner_id, comment);

    -- фиксируем транзакцию
	if `_rollback` then
       rollback;
    else
	set tran_result := 'ok';
       commit;
    end if;
	
	
end $$

delimiter ;



-- проверка: вызываем процедуру
call sp_add_comming_order('2020-04-27', 1, '', @tran_result) ;
select @tran_result;
select * from coming_orders co ;




-- 2. Добавить строку в существующий приходный ордер. 
drop procedure if exists `sp_coming_order_add_line`;

delimiter $$

create procedure `sp_coming_order_add_line`(order_id bigint, good_id bigint, expiration_date date, 
												`count` decimal(5,3), summ decimal(10,2),
												out tran_result varchar(200)
											)
begin
	
	-- объявим переменные
	declare `_rollback` bool default 0;
   	declare code varchar(100);
   	declare error_string varchar(100);
    declare next_line smallint default null;
   
    -- обработка ошибки
    declare continue handler for sqlexception
    begin
    	set `_rollback` = 1;
	get stacked diagnostics condition 1
          code = returned_sqlstate, error_string = message_text;
    	set tran_result := concat('error occured. code: ', code, '. text: ', error_string);
    end;
   
    -- старт 
    start transaction;
   
    -- расчет следующего номера строки документа
    set next_line = (select max(line_number) from coming_order_tables cot2 where cot2.order_id = order_id);
    if next_line is null then
   		set next_line = 1;
   	else
   		set next_line = next_line + 1;
   	end if;
   		
	
    -- вставляем строку
    INSERT INTO coming_order_tables (order_id, line_number, good_id, expiration_date, `count`, `summ`)
	  VALUES (order_id, next_line, good_id , expiration_date, `count`, summ);

    -- фиксируем транзакцию
	if `_rollback` then
       rollback;
    else
	set tran_result := 'ok';
       commit;
    end if;
	
	
end $$

delimiter ;

-- проверка: вызываем процедуру
call sp_coming_order_add_line (6, 1, '2020-05-30', 1, 3000, @tran_result) ;
select @tran_result;
select * from coming_order_tables cot2 where order_id = 5;



-- 3.Средняя размер партий в приходных ордерах по определенному товару
drop function if exists func_avg_part;

delimiter // 
create function func_avg_part(check_good_id bigint)
returns float reads sql data
  begin
	  
	-- переменные
	declare coming_count float;
    declare coming_orders int;
	  
    
	-- получим общее количество, поступившее на склад
	set coming_count = 
		(select sum(`count`)
			from coming_order_tables tab 
			join coming_orders doc on tab.order_id = doc.id 
			where good_id = 1 and doc.status = 'completed'
		);
   
    
	-- получим количество приходных ордеров, которыми посупил товар на склад
	set coming_orders = 
		(select count(*) from (
			select distinct order_id
			from coming_order_tables tab 
			join coming_orders doc on tab.order_id = doc.id 
			where good_id = 1 and doc.status = 'completed') as t1
		);
    
	-- разделим первое на второе и вернем результат
    return coming_count / coming_orders;
  end// 
delimiter ; 


-- проверка: вызовем функцию
select func_avg_part(1)