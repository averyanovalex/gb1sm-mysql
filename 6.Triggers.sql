-- 1.Проверяем, чтобы срок годности не был просроченным
delimiter //
create trigger check_expiration_date_before_insert before insert on coming_order_tables
for each row
begin
	if new.expiration_date < current_date() then 
		signal sqlstate '45000' set message_text = 'Добавление отменено! Срок годности не может быть меньше текущей даты!';
	end if;
end//
delimiter ;


-- проверка:
call sp_coming_order_add_line (5, 1, '2020-03-30', 1, 3000, @tran_result) ;
select @tran_result;



-- 2.проверяем, чтобы инн был 10 или 12 цифр
delimiter //
create trigger check_inn_before_update before update on partners
for each row
begin
    if length(new.inn) <> 10 and length(new.inn) <> 12  then
        signal sqlstate '45001' set message_text = 'Обновление отменено! Неверный ИНН';
    end if;
end//
delimiter ;


-- проверка:
select * from partners p;

update partners 
set 
	inn = 123456789012
where
	id = 1;






