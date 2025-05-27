# CJDataBaseSystem

English | [中文](./docs/README_zh.md)

## Description

This is a database demo composed with Cangjie, the brand-new language.

## TODO

- [x] `CREATE_DATABASE`
- [x] `DROP_DATABASE`
- [x] `USE`
- [x] `ERR`
- [x] `QUIT`
- [x] `CREATE_TABLE`
- [x] `DROP_TABLE`
- [x] `INFO_TABLE`
- [x] `INSERT_INTO`
- [x] `DELETE_FROM`
- [x] `SELECT`
- [x] `HELP`
- [x] `Root Directory Config`

## How to Use

1. Run program: `cjpm run`
2. Run `.help` for Manual and you will get the output below

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

## Structure of Database

```structure
name_database
|--database.meta
|--name_table
|  |--table.meta
|  |--page.data
!  !
```

### database.meta(.json)

| Key | Type |
| --- | ----- |
| Magic Name | "CJDB" |
| Database Name | String |
| Table Count | Int |
| Table Name | List\<String> |

### table.meta(.json)

| Key | Type |
| --- | ---- |
| Table Name | String |
| Row Count | UInt |
| Column Count | UInt |
| Table Column Info | List<List<Type, String>> |

### page.data(.csv)

| Column_0 | Column_1 | ... |
| -------- | -------- | --- |
| T        | T        | ... |
| ... | ... | ... |
