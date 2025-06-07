# 仓颉数据库Demo

[English](../README.md) | 中文

## 描述

这是一个数据库演示程序，使用仓颉编程语言编写。

## TODO

- [x] `CREATE_DATABASE`（创建数据库）
- [x] `DROP_DATABASE`（删除数据库）
- [x] `USE`（使用数据库）
- [x] `ERR`（错误处理）
- [x] `QUIT`（退出）
- [x] `CREATE_TABLE`（创建表）
- [x] `DROP_TABLE`（删除表）
- [x] `INFO_TABLE`（表信息）
- [x] `INSERT_INTO`（插入数据）
- [x] `DELETE_FROM`（删除数据）
- [x] `SELECT`（查询数据）
- [x] `HELP` (帮助手册)
- [x] `Root Directory Config` （运行时根目录设置）

## How to Use

1. 运行程序: `cjpm run`
2. 运行 `.help` 以获得帮助手册，你将会得到一下输出

```Help Manual
Available commands:
  1> create database <name>                   - Create a new database
  2> drop database <name>                     - Delete a database
  3> use <name>                               - Switch to database
  4> create table <name> (<col_type1> <col_name1>, <col_type2> <col_name2>, … )
                                              - Create a new table
  5> drop table <name>                        - Delete a table
  6> info table <name>                        - Show table information
  7> insert into <table> set <col_name1>=<col_value1>, <col_name2>=<col_value2>, …
                                              - Insert data into table
  8> delete from <table> [where condition]    - Delete data from table
  9> select <col_name1>, <col_name2>, … from <table> [where condition] [order by col_name] [asc/desc]   
                                              - Query data from table
```

## 数据库结构

```structure
name_database（数据库名称）
|--database.meta（数据库元数据）
|--name_table（表名称）
|  |--table.meta（表元数据）
|  |--page.data（页面数据）
!  !
```

### database.meta(.json)

| 键 | 类型 |
| --- | ----- |
| 标记名称 | "CJDB" |
| 数据库名称 | 字符串 |
| 表数量 | 整数 |
| 表名称 | 列表\<字符串> |

### table.meta(.json)

| 键 | 类型 |
| --- | ---- |
| 表名称 | 字符串 |
| 行数量 | 无符号整数 |
| 列数量 | 无符号整数 |
| 表列信息 | 列表\<列表<类型, 字符串>> |

### page.data(.csv)

| 列_0 | 列_1 | ... |
| -------- | -------- | --- |
| T | T | ... |
| ... | ... | ... |
