
       
       DROP TABLE IF EXISTS `mock_tts_10`.`p_export` ;
DROP TABLE IF EXISTS `mock_tts_10`.`p_import` ;
DROP TABLE IF EXISTS `mock_tts_10`.`p_import2` ;
       CREATE TEMPORARY TABLE p_import (
       inventory_id int,
       import_id int,
       detail_import_id int,
       product_variant_id int ,
       product_variant_code text,
       product_variant_name text, 
       import_price decimal(20,2),
       import_number int, 
       return_number int,
       import_date datetime
       );
    CREATE TEMPORARY TABLE p_import2 (
	export_inventory_id int,
	receive_inventory_id int,
	 export_id int ,
	 export_code text,
	 detail_export_id int, 
	 product_variant_id int,
	 product_variant_code text, 
	 product_variant_name text,
	 export_number int, 
	 create_at datetime,
	 date_send text,
	 date_receive text, 
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
	 export_number int, 
	 create_at datetime,
	 date_send text,
	 date_receive text, 
	 status_id int
  );
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
		quantity as export_number,
		exports_status.create_at as create_at,
		date_send,
		date_receive,
		exports_status.status_id 
		from details_exports left join exports on details_exports.export_id=exports.id left join exports_status on exports_status.export_id=exports.id
		left join product_variants on product_variants.id=details_exports.product_variant_id
		where exports_status.status_id>=1   ;
        
		insert into p_import select  
        receive_inventory_id, 
        0,
        0,
        
        product_variant_id,
        product_variant_code,
        product_variant_name,
        0,
        p_export.export_number, 
        0, 
        STR_TO_DATE(date_receive, '%d/%m/%Y %T') from p_export 
		where p_export.receive_inventory_id=3 ;


insert into p_import
		select 
        imports.inventory_id,
		details_imports.import_id as import_id,
		details_imports.id as detail_import_id,
		details_imports.product_variant_id as product_variant_id,
		product_variants.code as product_variant_code,
		product_variants.name as product_variant_name,
		details_imports.import_price as import_price,
		details_imports.quantity as import_number,
		if(p_return.return_number>0,p_return.return_number,0) as return_number
		,imports_status.create_at as import_date
		from  details_imports left join imports on imports.id=details_imports.import_id 
		left join (select details_return_import.details_import_id ,sum(details_return_import.quantity) as return_number  
					from details_return_import group by details_return_import.details_import_id ) as p_return on p_return.details_import_id=details_imports.id
							left join product_variants on product_variants.id=details_imports.product_variant_id
						   left join imports_status on imports_status.import_id= details_imports.import_id and imports_status.status_id=4
		where imports.is_import=true ;
select p_import.product_variant_id,p_import.product_variant_code,p_import.product_variant_name ,sum(import_number) as import_number ,sum(return_number)  as return_number ,sum(export_number) as export_number,(sum(import_number)-sum(return_number))-sum(export_number) as quantity
 from p_import 
			left join (select *  from  p_export where export_inventory_id=3 ) as tbl_export 
			on tbl_export.export_inventory_id=p_import.inventory_id and tbl_export.product_variant_id=p_import.product_variant_id
 where p_import.inventory_id=inventory_id
 group by  p_import.product_variant_id;
 
select tbl1.*,if(export_number>0,export_number,0) as export_number,tbl1.import_number-tbl1.return_number-if(export_number>0,export_number,0) as quantity from (select p_import.product_variant_id,p_import.product_variant_code,p_import.product_variant_name ,sum(import_number) as import_number ,sum(if(return_number>0,return_number,0))  as return_number 
from p_import
where inventory_id=3
group by product_variant_id) as tbl1 left join (select product_variant_id,if(export_number>0,export_number,0) as export_number from p_export
where export_inventory_id=3) as tbl2 on tbl1.product_variant_id=tbl2.product_variant_id
;