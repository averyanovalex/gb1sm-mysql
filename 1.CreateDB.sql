-- Создание таблиц БД Store

drop database if exists store;
create database store;
use store;


-- каталог товаров (категории)
drop table if exists `catalog`;
create table `catalog` (
	id serial primary key,
	name varchar(100),
	created_at datetime default now(),
	updated_at datetime on update current_timestamp
);


-- единицы измерения: кг, шт. и др
drop table if exists units;
create table units (
	id serial primary key,
	name varchar(5),
	created_at datetime default now(),
	updated_at datetime on update current_timestamp
);


-- секции склада: для разных типов товаров: мороз, холод, сухой
drop table if exists sections;
create table sections (
	id serial primary key,
	name varchar(25),
	created_at datetime default now(),
	updated_at datetime on update current_timestamp
);

-- товары
drop table if exists goods;
create table goods (
	id serial primary key,
	name varchar(100),
	description text, 
	catalog_id bigint unsigned default null,
	unit_id bigint unsigned default null,
	section_id bigint unsigned default null,  -- товар закрепляется в какой секции он должен храниться
	weight decimal(5,3)default 0, -- вес одной единицы
	price decimal(10,2) default 0,	-- цена (справочно), учет ведется только количественный
	is_deleted bit default 0, -- удалена, не используется
	created_at datetime default now(),
	updated_at datetime on update current_timestamp,
	
	foreign key (catalog_id) references `catalog`(id),
	foreign key (unit_id) references units(id),
	foreign key (section_id) references sections(id),
	index(name)
	
);


-- партнеры: поставщики, клиенты от кого принимаем и кому отгружаем товар
drop table if exists partners;
create table partners (
	id serial primary key,
	name varchar(100),
	address text,
	inn numeric(12), -- инн
	contact_person varchar(100), -- контактное лицо
	created_at datetime default now(),
	updated_at datetime on update current_timestamp,
	
	index(name),
	index(inn)
);


-- ячейки склада
drop table if exists cells;
create table cells (
	id serial primary key, -- внутренний уникальный id
	code varchar(10), -- код, адрес ячейки в формате понятном кладовщику. 
	-- Пример: М-25-3 (секция "мороз", ряд 25, ярус 3)
	section_id bigint unsigned default null, -- секция к которой относится ячейка
	is_blocked bit default 0, -- заблокирована или не используется
	created_at datetime default now(),
	updated_at datetime on update current_timestamp,
	
	foreign key (section_id) references sections(id),
	index(code)
);


-- таблица остатков
-- ведется количественный учет в разрезах: ячейка, товар, срок годности
drop table if exists stocks;
create table stocks (
	cell_id bigint unsigned not null,  -- ячейка, где лежит остаток
	good_id bigint unsigned not null,  -- товар
	expiration_date date not null, -- срок годности, не может быть пустым
	`count` decimal(10,3) default 0, 
	
	foreign key (good_id) references goods(id),
	foreign key (cell_id) references cells(id),
	primary key(cell_id, good_id, expiration_date)
);


-- приходные ордера на товар (шапка документа)
drop table if exists coming_orders;
create table coming_orders (
	id serial primary key,
	order_date date not null,
	status enum('is_planned', 'in_progress', 'completed', 'canceled'),	
	partner_id bigint unsigned default null, 
	summ decimal(10,2) default 0,	
	comment varchar(255),
	created_at datetime default now(),
	updated_at datetime on update current_timestamp,
	
	foreign key (partner_id) references partners(id),
	index(order_date),
	index(status),
	index(partner_id)
);


-- приходные ордера на товар, табличная часть
drop table if exists coming_order_tables;
create table coming_order_tables (
	order_id bigint unsigned not null,
	line_number smallint unsigned not null,  -- номер строки в документе
	good_id bigint unsigned not null, 
	expiration_date date  not null,  -- срок годности, не может быть пустым
	cell_id bigint unsigned not null, -- ячейка, куда размещен товар
	`count` decimal(5,3) unsigned not null, -- количество в базовых единицах измерения (заданых в таблице goods)
	summ decimal(10,2) unsigned default 0, -- сумма (справочно). учет ведется только количественный
	
	primary key (order_id, line_number),
	foreign key (order_id) references coming_orders(id),
	foreign key (good_id) references goods(id),
	foreign key (cell_id) references cells(id)
);


-- расходные ордера на товар. аналогично приходным
drop table if exists outgoing_orders;
create table outgoing_orders (
	id serial primary key,
	order_date date not null,
	status enum('is_planned', 'in_progress', 'completed', 'canceled'),	
	partner_id bigint unsigned default null,
	summ decimal(10,2) default 0,
	comment varchar(255),
	created_at datetime default now(),
	updated_at datetime on update current_timestamp,
	
	foreign key (partner_id) references partners(id),
	index(order_date),
	index(status),
	index(partner_id)
);


drop table if exists outgoing_order_tables;
create table outgoing_order_tables (
	order_id bigint unsigned not null,
	line_number smallint unsigned not null,
	good_id bigint unsigned not null,
	expiration_date date  not null,
	cell_id bigint unsigned not null,
	`count` decimal(5,3) unsigned not null, 
	summ decimal(10,2) unsigned default 0,
	
	primary key (order_id, line_number),
	foreign key (order_id) references outgoing_orders(id),
	foreign key (good_id) references goods(id),
	foreign key (cell_id) references cells(id)
);


