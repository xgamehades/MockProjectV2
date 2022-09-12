USE `mock_tts_10`;
DROP procedure IF EXISTS `mock_tts_10`.`get_statistic_import`;


DELIMITER $$
USE `mock_tts_10`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_statistic_import`(in inventory_id int ,in supplier_id int,in start_date datetime,in end_date datetime,in sort_by text,in sort_dir bit,in page int, in size int ,in key_search text)
BEGIN
 

DROP TABLE IF EXISTS `mock_tts_10`.`p_return` ;
DROP TABLE IF EXISTS `mock_tts_10`.`p_receive` ;
DROP TABLE IF EXISTS `mock_tts_10`.`final` ;

CREATE TEMPORARY TABLE p_return (
	import_id   int , 
    details_import_id  int , 
    return_import_id  int , 
    product_variant_id  int , 
    return_number  int 
		);
        CREATE TEMPORARY TABLE p_receive (
	inventory_id int,
    supplier_id int,
    account_id int,
    import_id int,
    import_code text,
    details_import_id int,
    product_variant_id int,
    import_price decimal(20,2),
    import_number int ,
    total_price decimal(20,2) ,
    delivery_date text,
    create_at datetime
		);
	
       CREATE TEMPORARY TABLE final (
    inventory_id int,
    supplier_id int,
    account_id int,
    import_id int,
    import_code text,
    details_import_id int,
    product_variant_id int,
    import_price decimal(20,2),
    import_number int ,
    total_price decimal(20,2) ,
    delivery_date text,
    create_at datetime,
    code text,
    name text,
    return_number int,
    receive_number int ,
    product_id int,
    product_code text
  );
    insert into p_receive 
    select imports.inventory_id as inventory_id, 
    imports.supplier_id as supplier_id,
   imports.account_id as account_id,
    imports.id as import_id,
    imports.code as import_code,
    details_imports.id as details_import_id,
    product_variant_id,
    details_imports.import_price as import_price,
    details_imports.quantity as import_number,
    imports.total_price,
    delivery_date,
    create_at
from  details_imports  left join imports on details_imports.import_id=imports.id left join imports_status on imports.id=imports_status.import_id

where imports.is_done=true and imports.is_import=true and imports_status.id and status_id=4 ;

insert into p_return 
select details_imports.import_id as import_id,
 details_imports.id as details_import_id,
 return_import_id,
product_variant_id,
sum(details_return_import.quantity )as return_number
from return_import inner join details_return_import on return_import.id=details_return_import.return_import_id 
	inner join details_imports on details_imports.id=details_return_import.details_import_id
    group by details_import_id , product_variant_id;

insert into final select tbl1.* ,products.code as product_code from
(select p_receive.*,product_variants.code as code,product_variants.name as name,if(p_return.return_number>0,p_return.return_number,0) as return_number,(p_receive.import_number-if(p_return.return_number>0,p_return.return_number,0)) as receive_number  ,product_variants.product_id as product_id
from p_receive left join p_return on p_receive.details_import_id =p_return.details_import_id left join product_variants on product_variants.id=p_receive.product_variant_id
where create_at>=start_date and create_at<=end_date ) as tbl1 left join products on products.id=tbl1.product_id
;



	set @from_string =' from final ' ;

	set @search_value=concat('"%',lower(key_search),'%"');
	set @clause =concat(' where create_at>="',start_date,'" and create_at<="',end_date,'"' ,' and (lower(code) like ',@search_value,' or lower(name) like  ',@search_value ,') ' );
    set @col =' inventory_id, supplier_id, account_id, import_id, import_code, details_import_id, product_variant_id, sum(import_price*(import_number-return_number))/sum(import_number-return_number) as avg_price, sum(import_number) as import_number, sum(return_number) as return_number, (sum(import_number)- sum(return_number)) as receive_number, total_price, delivery_date, create_at, code, name,product_id,product_code' ;
    set @group_by =' group by product_variant_id ';
      if(sort_dir) then 
    begin
        set @order_by =concat(' order by ',sort_by,' asc' );

    end;
    else
    begin
        set @order_by =concat(' order by ',sort_by,' desc' );

    end;
    end if;
    if( inventory_id>0) then
    begin
		set @clause=concat(@clause,' and inventory_id= ',inventory_id);
    end;
    end if;
    if(supplier_id>0) then 
    begin
		set @clause=concat(@clause,' and supplier_id= ',supplier_id);
    end;
    end if;
    
    
    set @query_string=concat('select ',@col,@from_string,@clause,@group_by,@order_by);
        if(page>0 && size>0) then 
    begin
		set @query_string=concat(@query_string,' limit ',size,' offset ',(page-1)*size );
    end;
    end if;
    
-- select @query_string;
PREPARE stmt1 FROM @query_string;
EXECUTE stmt1 ;

END$$

DELIMITER ;

-- procedure filter_product
-- -----------------------------------------------------

USE `mock_tts_10`;
DROP procedure IF EXISTS `mock_tts_10`.`filter_product`;

DELIMITER $$
USE `mock_tts_10`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `filter_product`(in key_word text,in sort_by text,in is_desc bit,in page int,in size int,in is_delete bit)
BEGIN

declare offset_number int ;

declare search_value text;

set search_value=lower(concat('%',key_word,'%'));

set offset_number=(page-1)*size;

 

 

 
DROP TABLE IF EXISTS `mock_tts_10`.`products_count` ;
 CREATE TEMPORARY TABLE products_count (

		id int,

		code text,

		name text,

        description text,

        status_id int ,

        supplier_id int,

        account_id int,

        create_at datetime,

        update_at datetime,

        is_delete bit,

        number_of_variant int,

        total int



		);



insert into products_count (select products.*,count(product_variants.id) as number_of_variant,sum(IF(quantity>0,quantity,0)) as total from products left join product_variants on products.id=product_variants.product_id

left join inventories_product_variant on product_variants.id=inventories_product_variant.product_variant_id 

where (lower(products.name) like search_value or lower(products.code) like search_value) and products.is_delete=is_delete

group by(products.id) ) limit size offset offset_number;

 

 

 

   if (is_desc=true) then

 begin 

 	select * from products_count order by sort_by desc ;

 end;

 else

 begin

 	select * from products_count order by sort_by asc;



 end;

 end if ;








END$$

DELIMITER ;
-- procedure count_product_by_filter
-- -----------------------------------------------------

USE `mock_tts_10`;
DROP procedure IF EXISTS `mock_tts_10`.`count_product_by_filter`;

DELIMITER $$
USE `mock_tts_10`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `count_product_by_filter`(in key_word text,in sort_by text,in is_desc bit,in page int,in size int,in is_delete bit)
BEGIN



declare search_value text ;

set search_value=lower(concat('%',key_word,'%'));

select  count(table1.total) from (select 0 as total  from products left join product_variants on products.id=product_variants.product_id

left join inventories_product_variant on product_variants.id=inventories_product_variant.product_variant_id 

where (lower(products.name) like search_value or lower(products.code) like search_value) and products.is_delete=is_delete

group by(products.id) ) as table1  

group by table1.total;

 

END$$

DELIMITER ;
-- -----------------------------------------------------
-- procedure get_statistic_import_extend
-- -----------------------------------------------------

USE `mock_tts_10`;
DROP procedure IF EXISTS `mock_tts_10`.`get_statistic_import_extend`;

DELIMITER $$
USE `mock_tts_10`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_statistic_import_extend`(in inventory_id int ,in supplier_id int,in start_date datetime,in end_date datetime,in sort_by text,in sort_dir bit,in page int, in size int,in key_search text )
BEGIN
 

DROP TABLE IF EXISTS `mock_tts_10`.`p_return` ;
DROP TABLE IF EXISTS `mock_tts_10`.`p_receive` ;
DROP TABLE IF EXISTS `mock_tts_10`.`final` ;

CREATE TEMPORARY TABLE p_return (
	import_id   int , 
    details_import_id  int , 
    return_import_id  int , 
    product_variant_id  int , 
    return_number  int 
		);
        CREATE TEMPORARY TABLE p_receive (
	inventory_id int,
    supplier_id int,
    account_id int,
    import_id int,
    import_code text,
    details_import_id int,
    product_variant_id int,
    import_price decimal(20,2),
    import_number int ,
    total_price decimal(20,2) ,
    delivery_date text,
    create_at datetime
		);
	
       CREATE TEMPORARY TABLE final (
    inventory_id int,
    supplier_id int,
    account_id int,
    import_id int,
    import_code text,
    details_import_id int,
    product_variant_id int,
    import_price decimal(20,2),
    import_number int ,
    total_price decimal(20,2) ,
    delivery_date text,
    create_at datetime,
    code text,
    name text,
    return_number int,
    receive_number int
  );
    insert into p_receive 
    select imports.inventory_id as inventory_id, 
    imports.supplier_id as supplier_id,
   imports.account_id as account_id,
    imports.id as import_id,
    imports.code as import_code,
    details_imports.id as details_import_id,
    product_variant_id,
    details_imports.import_price as import_price,
    details_imports.quantity as import_number,
    imports.total_price,
    delivery_date,
    create_at
from  details_imports  left join imports on details_imports.import_id=imports.id left join imports_status on imports.id=imports_status.import_id

where imports.is_done=true and imports.is_import=true and imports_status.id and status_id=4 ;

insert into p_return 
select details_imports.import_id as import_id,
 details_imports.id as details_import_id,
 return_import_id,
product_variant_id,
sum(details_return_import.quantity )as return_number
from return_import inner join details_return_import on return_import.id=details_return_import.return_import_id 
	inner join details_imports on details_imports.id=details_return_import.details_import_id
    group by details_import_id , product_variant_id;

insert into final
select p_receive.*,product_variants.code as code,product_variants.name as name,if(p_return.return_number>0,p_return.return_number,0) as return_number,(p_receive.import_number-if(p_return.return_number>0,p_return.return_number,0)) as receive_number  
from p_receive left join p_return on p_receive.details_import_id =p_return.details_import_id left join product_variants on product_variants.id=p_receive.product_variant_id
where create_at>=start_date and create_at<=end_date 
;


	set @search_value=concat('"%',lower(key_search),'%"');
	set @clause =concat(' where create_at>="',start_date,'" and create_at<="',end_date,'"' ,' and (lower(code) like ',@search_value,' or lower(name) like  ',@search_value ,') ' );
	set @from_string =' from final ' ;
    set @col =' inventory_id, supplier_id, account_id, import_id, import_code, details_import_id, product_variant_id, import_price, import_number , return_number, (import_number- return_number) as receive_number,(import_number- return_number)*import_price total_price, delivery_date, create_at, code ,name' ;
    set @group_by ='  ';
    if(sort_dir) then 
    begin
        set @order_by =concat(' order by ',sort_by,' asc' );

    end;
    else
    begin
        set @order_by =concat(' order by ',sort_by,' desc' );

    end;
    end if;
    if( inventory_id>0) then
    begin
		set @clause=concat(@clause,' and inventory_id= ',inventory_id);
    end;
    end if;
    if(supplier_id>0) then 
    begin
		set @clause=concat(@clause,' and supplier_id= ',supplier_id);
    end;
    end if;
    
    
    set @query_string=concat('select ',@col,@from_string,@clause,@group_by,@order_by);
        if(page>0 && size>0) then 
    begin
		set @query_string=concat(@query_string,' limit ',size,' offset ',(page-1)*size );
    end;
    end if;
    
-- select @query_string;
PREPARE stmt1 FROM @query_string;
EXECUTE stmt1 ;

END$$

DELIMITER ;
 
-- procedure get_statistic_inventory
-- -----------------------------------------------------

USE `mock_tts_10`;
DROP procedure IF EXISTS `mock_tts_10`.`get_statistic_inventory`;

DELIMITER $$
USE `mock_tts_10`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_statistic_inventory`(in inventory_id int,in start_date datetime,in end_date datetime,in sort_by text,in sort_dir bit,in page int, in size int ,in key_word text)
BEGIN


DROP TABLE IF EXISTS `mock_tts_10`.`p_export` ;
DROP TABLE IF EXISTS `mock_tts_10`.`p_import` ;

       CREATE TEMPORARY TABLE p_import (
       inventory_id int,
       import_id int,
       detail_import_id int,
       product_variant_id int ,
       product_variant_code text,
       product_variant_name text, 
       product_id int,
       import_price decimal(20,2),
       import_number int, 
       return_number int,
       import_date datetime
		, 
	 status_id int
       );

       CREATE TEMPORARY TABLE p_export (
	export_inventory_id int,
	receive_inventory_id int,
	 export_id int ,
	 export_code text,
	 detail_export_id int, 
	 product_variant_id int,
	 product_variant_code text, 
	 product_variant_name text,
     product_id int,
	 export_number int, 
	 create_at datetime,
	 date_send text,
	 date_receive text, 
	 status_id int
  );
	
        
	

insert into p_import 
	select 
        imports.inventory_id,
		details_imports.import_id as import_id,
		details_imports.id as detail_import_id,
		details_imports.product_variant_id as product_variant_id,
		product_variants.code as product_variant_code,
		product_variants.name as product_variant_name,
        product_variants.product_id as product_id,
		details_imports.import_price as import_price,
		details_imports.quantity as import_number,
		if(p_return.return_number>0,p_return.return_number,0) as return_number,imports_status.create_at as import_date,
        max(imports_status.status_id)
        
		from  details_imports left join imports on imports.id=details_imports.import_id 
		left join (select details_return_import.details_import_id ,sum(details_return_import.quantity) as return_number  
					from details_return_import group by details_return_import.details_import_id ) as p_return on p_return.details_import_id=details_imports.id
							left join product_variants on product_variants.id=details_imports.product_variant_id
						   left join imports_status on imports_status.import_id= details_imports.import_id and imports_status.status_id>=4
		where imports.is_import=true or imports.is_import=true  and create_at<=end_date
        group by imports.inventory_id,details_imports.product_variant_id;

set @key_search=concat('"%',lower(key_word),'%"');


 if(inventory_id>0) then 
    begin
    insert into	 p_export 
		  select 
		exports.export_inventory_id ,
        exports.receive_inventory_id ,
		exports.id as export_id,
		exports_status.code as export_code,
		details_exports.id as detail_export_id,
		product_variants.id as product_variant_id,
		product_variants.code as product_variant_code,
		product_variants.name as product_variant_name,
        product_variants.product_id as product_id,
		quantity as export_number,
		exports_status.create_at as create_at,
		date_send,
		date_receive,
		exports_status.status_id 
		from details_exports left join exports on details_exports.export_id=exports.id left join exports_status on exports_status.export_id=exports.id
		left join product_variants on product_variants.id=details_exports.product_variant_id
		where exports_status.status_id>1 and  STR_TO_DATE(date_send, '%d/%m/%Y %T')<=end_date  ;
         
		insert into p_import select  
        receive_inventory_id, 
        0,
        0,
        
        product_variant_id,
        product_variant_code,
        product_variant_name,
        product_id
        ,
        0,
        p_export.export_number, 
        0, 
        STR_TO_DATE(date_receive, '%d/%m/%Y %T'),
        status_id
        
        from p_export 
		where  STR_TO_DATE(date_receive, '%d/%m/%Y %T')<end_date  ;
        
	set @sql_string=concat('select tbl1.*,if(export_number>0,export_number,0) as export_number,tbl1.import_number-tbl1.return_number-if(export_number>0,export_number,0) as quantity from 
    (select p_import.product_variant_id,p_import.product_variant_code,p_import.product_variant_name ,p_import.product_id,sum(import_number) as import_number ,sum(if(return_number>0,return_number,0))  as return_number 
	from p_import
	where inventory_id=',inventory_id,'
	group by product_variant_id) as tbl1 left join (select product_variant_id,if(export_number>0,export_number,0) as export_number from p_export
	where  export_inventory_id=',inventory_id,' ) as tbl2 on tbl1.product_variant_id=tbl2.product_variant_id '
		,concat(' where (lower(product_variant_code) like ',@key_search,' or lower(product_variant_name) like  ',@key_search ,') ' )
	);
    end;
    else
    begin
      set @sql_string=concat('select tbl1.*,if(export_number>0,export_number,0) as export_number,tbl1.import_number-tbl1.return_number-if(export_number>0,export_number,0) as quantity from
      (select p_import.product_variant_id,p_import.product_variant_code,p_import.product_variant_name ,p_import.product_id,sum(import_number) as import_number ,sum(if(return_number>0,return_number,0))  as return_number 
	from p_import
	group by product_variant_id ) as tbl1 left join (select product_variant_id,if(export_number>0,export_number,0) as export_number from p_export)
	 as tbl2 on tbl1.product_variant_id=tbl2.product_variant_id '
	,concat(' where (lower(product_variant_code) like ',@key_search,' or lower(product_variant_name) like  ',@key_search ,') ' )
	);

    end;
    end if;

    if(sort_dir) then 
    begin
        set @order_by =concat(' order by ',sort_by,' asc' );

    end;
    else
    begin
        set @order_by =concat(' order by ',sort_by,' desc' );

    end;
    end if;
 set @sql_string=concat(@sql_string,@order_by );
        if(page>0 && size>0) then 
    begin
		set @sql_string=concat(@sql_string,' limit ',size,' offset ',(page-1)*size );
    end;
    end if;
    

 PREPARE excute_string FROM @sql_string;
-- select @sql_string;
 EXECUTE excute_string ;


END$$

DELIMITER ;

