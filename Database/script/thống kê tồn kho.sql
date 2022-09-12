select exports.id as export_id,
exports_status.code as export_code,
details_exports.id as detail_export_id,
exports_status.code as export_code,
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
where exports_status.status_id>=1 ;


DROP TABLE IF EXISTS `mock_tts_10`.`p_import` ;
       CREATE TEMPORARY TABLE p_import (
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


select 
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

select * 
from  details_imports left join imports on imports.id=details_imports.import_id 
left join (select details_return_import.details_import_id ,sum(details_return_import.quantity) as return_number  
			from details_return_import group by details_return_import.details_import_id ) as p_return on p_return.details_import_id=details_imports.id