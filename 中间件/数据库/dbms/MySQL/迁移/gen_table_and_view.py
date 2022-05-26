import threading
import time

from component import mymysql

is_execute = True
global_threads = []


def get_db_pool(db_pool_conf):
    db_pool = None
    retry_times = 0
    is_not_ok = True
    while is_not_ok:
        retry_times += 1
        try:
            db_pool = mymysql.init(db_pool_conf)
            is_not_ok = False
        except Exception:
            print("get_db_pool-retry", str(db_pool_conf), str(retry_times))
            import traceback, sys
            traceback.print_exc()  # 打印异常信息
        time.sleep(1)
    return db_pool


def sync_database(database, is_init_table):
    source_db_db_pool = get_db_pool({
        "host": ""
        , "port": 3306
        , "database": database
        , "user": ""
        , "password": ""
        , "charset": "utf8mb4"
    })
    target_db_pool = get_db_pool({
        "host": "192.168.90.20"
        , "port": 31355
        , "database": database
        , "user": "stagecs"
        , "password": "wjh_stage_mariadb_%$865"
        , "charset": "utf8mb4"
    })
    # 表级别
    tables = mymysql.query(source_db_db_pool, """
        show tables;
        """)
    for table in tables:
        table = table[tuple(table)[0]]
        global global_threads
        cur_thread = threading.Thread(target=do_sync_source_schema_2_target,
                                      args=(source_db_db_pool, target_db_pool, database, table, is_init_table,))
        global_threads.append(cur_thread)
        cur_thread.start()
        # cur_thread.join()

def do_sync_source_schema_2_target(source_db_db_pool, target_db_pool, database, table, is_init_table):
    retry_times = 0
    is_not_ok = True
    while is_not_ok:
        retry_times += 1
        try:
            sync_source_schema_2_target(source_db_db_pool, target_db_pool, database, table, is_init_table)
            is_not_ok = False
        except Exception:
            print("do_sync_source_schema_2_target-retry-", database, table, is_init_table, retry_times)
            import traceback, sys
            traceback.print_exc()  # 打印异常信息
        time.sleep(3)


def sync_source_schema_2_target(source_db_db_pool, target_db_pool, database, table, is_init_table):
    # 表定义级别
    table_schemas = mymysql.query(source_db_db_pool, """
            show create table %s
            """ % table)
    table_schema = table_schemas[0]
    print("mysql-updating", database, table)
    if is_init_table:
        if "Create Table" in table_schema:
            print("table:" + "-" * 20 + table)
            table_schema = table_schema["Create Table"].strip()
            if table_schema.endswith("broadcast"):
                table_schema = table_schema[:-len("broadcast")]
            if "BY GROUP" in table_schema:
                table_schema = table_schema.replace("BY GROUP", "")
            if table_schema.endswith(
                    "dbpartition by hash(`warehouse_id`) tbpartition by hash(`warehouse_id`) tbpartitions 40"):
                table_schema = table_schema[:-len(
                    "dbpartition by hash(`warehouse_id`) tbpartition by hash(`warehouse_id`) tbpartitions 40")]
            if "VIRTUAL," in table_schema:
                table_schema = table_schema.replace("VIRTUAL,", ",")
            print("table_schema:", table_schema)
            if is_execute:
                mymysql.update(target_db_pool, """
                DROP TABLE IF EXISTS %s;
                """ % table)
                mymysql.update(target_db_pool, table_schema)
    else:
        if "CREATE VIEW" in table_schema:
            print("view:", "-" * 20, table)
            table_schema = table_schema["CREATE VIEW"]
            print("table_schema:", table_schema)
            if is_execute:
                mymysql.update(target_db_pool, """
                DROP VIEW IF EXISTS %s;
                """ % table)
                mymysql.update(target_db_pool, table_schema)
    print("mysql-updated", database, table)


def sync_table(is_init_table):
    source_db_pool = get_db_pool({
        "host": ""
        , "port": 3306
        , "user": ""
        , "password": ""
        , "charset": "utf8mb4"
    })
    # 数据库级别
    databases = mymysql.query(source_db_pool, """
    select distinct table_schema
    from information_schema.`TABLES`   
    where  1=1
    and table_schema not in ('mysql', 'information_schema', 'performance_schema', 'sys', 'vendor_manager_prod'
    )
    """)
    print("databases:", "-" * 100, databases)
    for database in databases:
        database = database["table_schema"]
        print("database:", "-" * 100, database)
        global global_threads
        cur_thread = threading.Thread(target=sync_database, args=(database, is_init_table))
        global_threads.append(cur_thread)
        cur_thread.start()
        # cur_thread.join()


if __name__ == '__main__':
    start_time = int(time.time())
    # sync_table(True)
    sync_table(False)
    for item in global_threads:
        item.join()
    print("耗时:" + str(int(time.time()) - start_time))
