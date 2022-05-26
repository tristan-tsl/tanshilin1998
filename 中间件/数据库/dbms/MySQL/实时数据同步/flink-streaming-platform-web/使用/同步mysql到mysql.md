第三方jar

```
https://repo1.maven.org/maven2/com/alibaba/ververica/flink-sql-connector-mysql-cdc/1.2.0/flink-sql-connector-mysql-cdc-1.2.0.jar


http://ccblog.cn/jars/flink-connector-jdbc_2.11-1.12.0.jar
```



测试cdc

```
CREATE TABLE mysqlcdc_product__t_sku_tristan (
    `id` 				INT 			,		
    `sku_no` 			STRING 			,		
    `spu_id` 			INT 			,		
    `class_id` 			INT 			,		
    `spu_name` 			STRING 			,		
    `spu_shortname` 	STRING 			,		
    `spu_pinyin` 		STRING 			,		
    `sku_spec` 			STRING 			,		
    `sku_unit` 			STRING 			,		
    `sku_meature_mode` 	INT 			,		
    `sku_pics` 			STRING 			,		
    `sku_barcode` 		STRING 			,		
    `sku_remark` 		STRING 			,		
    `ratio` 			DECIMAL(10, 3) 	,		
    `is_accurate` 		INT 			,		
    `status` 			INT 			,		
    `is_deleted` 		INT 			,		
    `c_t` 				INT 			,		
    `c_u` 				STRING 			,		
    `u_t` 				INT 			,		
    `u_u` 				STRING 			,
    PRIMARY KEY (id) NOT ENFORCED
) WITH (
    'connector' = 'mysql-cdc',
    'hostname' = 'wjh-local-stage.mysql.polardb.rds.aliyuncs.com',
    'port' = '3306',
    'username' = 'u_dts',
    'password' = 'Waf8xauwVcUzUE',
    'database-name' = 'product_2zjt_0000',
    'table-name' = 't_sku_tristan'
);
CREATE TABLE print_product__t_sku_tristan (
    `id` 				INT 			,		
    `sku_no` 			STRING 			,		
    `spu_id` 			INT 			,		
    `class_id` 			INT 			,		
    `spu_name` 			STRING 			,		
    `spu_shortname` 	STRING 			,		
    `spu_pinyin` 		STRING 			,		
    `sku_spec` 			STRING 			,		
    `sku_unit` 			STRING 			,		
    `sku_meature_mode` 	INT 			,		
    `sku_pics` 			STRING 			,		
    `sku_barcode` 		STRING 			,		
    `sku_remark` 		STRING 			,		
    `ratio` 			DECIMAL(10, 3) 	,		
    `is_accurate` 		INT 			,		
    `status` 			INT 			,		
    `is_deleted` 		INT 			,		
    `c_t` 				INT 			,		
    `c_u` 				STRING 			,		
    `u_t` 				INT 			,		
    `u_u` 				STRING 			,
    PRIMARY KEY (id) NOT ENFORCED
) WITH (
    'connector' = 'print'
);
insert into print_product__t_sku_tristan select * from mysqlcdc_product__t_sku_tristan;

```



测试cdc-2-mysql

```
CREATE TABLE mysqlcdc_product__t_sku_tristan (
    `id` 				INT 			,		
    `sku_no` 			STRING 			,		
    `spu_id` 			INT 			,		
    `class_id` 			INT 			,		
    `spu_name` 			STRING 			,		
    `spu_shortname` 	STRING 			,		
    `spu_pinyin` 		STRING 			,		
    `sku_spec` 			STRING 			,		
    `sku_unit` 			STRING 			,		
    `sku_meature_mode` 	INT 			,		
    `sku_pics` 			STRING 			,		
    `sku_barcode` 		STRING 			,		
    `sku_remark` 		STRING 			,		
    `ratio` 			DECIMAL(10, 3) 	,		
    `is_accurate` 		INT 			,		
    `status` 			INT 			,		
    `is_deleted` 		INT 			,		
    `c_t` 				INT 			,		
    `c_u` 				STRING 			,		
    `u_t` 				INT 			,		
    `u_u` 				STRING 			,
    PRIMARY KEY (id) NOT ENFORCED
) WITH (
    'connector' = 'mysql-cdc',
    'hostname' = 'wjh-local-stage.mysql.polardb.rds.aliyuncs.com',
    'port' = '3306',
    'username' = 'u_dts',
    'password' = 'Waf8xauwVcUzUE',
    'database-name' = 'product_2zjt_0000',
    'table-name' = 't_sku_tristan'
);
CREATE TABLE mysql_vendor_manager__t_sku_tristan (
    `id` 				INT 			,		
    `sku_no` 			STRING 			,		
    `spu_id` 			INT 			,		
    `class_id` 			INT 			,		
    `spu_name` 			STRING 			,		
    `spu_shortname` 	STRING 			,		
    `spu_pinyin` 		STRING 			,		
    `sku_spec` 			STRING 			,		
    `sku_unit` 			STRING 			,		
    `sku_meature_mode` 	INT 			,		
    `sku_pics` 			STRING 			,		
    `sku_barcode` 		STRING 			,		
    `sku_remark` 		STRING 			,		
    `ratio` 			DECIMAL(10, 3) 	,		
    `is_accurate` 		INT 			,		
    `status` 			INT 			,		
    `is_deleted` 		INT 			,		
    `c_t` 				INT 			,		
    `c_u` 				STRING 			,		
    `u_t` 				INT 			,		
    `u_u` 				STRING 			,
    PRIMARY KEY (id) NOT ENFORCED
 ) WITH (
   'connector' = 'jdbc',
   'url' = 'jdbc:mysql://:3306/vendor_manager?characterEncoding=UTF-8',
   'table-name' = 't_sku_tristan',
   'username' = 'u_dts',
   'password' = 'Waf8xauwVcUzUE'
 );
 insert into mysql_vendor_manager__t_sku_tristan select * from mysqlcdc_product__t_sku_tristan;
```

