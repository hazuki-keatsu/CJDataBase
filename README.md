# CJDataBaseSystem

English | [中文](./docs/README_zh.md)

## Description

This is a database demo composed with Cangjie, the brand-new language.

## TODO

- [x] `CREATE_DATABASE, DROP_DATABASE, USE, ERR, QUIT`
- [ ] `CREATE_TABLE, DROP_TABLE, INFO_TABLE, INSERT_INTO, DELETE_FROM, SELECT`
- [ ] `Array\<T>` to `csv` Func

## Structure of Database

```structure
name_database
|--database.meta
|--name_table
|  |--table.meta
|  |--page.data
|  |--index
|  |  |--column_0.index
|  |  |--column_1.index
|  |  |--column_2.index
|  !
!
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
| Table Column Info | Map\<String, List<Uint, Type>> |

### page.data(.csv)

| Index | Column_0 | Column_1 | ... |
| ----- | -------- | -------- | --- |
| UInt   | T        | T        | ... |
| ... | ... | ... | ... |

### column.index(.json)

| Key | Value |
| --- | ----- |
| Index | Unit |
| Data | Map<Value, Index_Row> |
