# CJDataBase系统

[English](../README.md) | 中文

## 描述

这是一个数据库演示程序，使用仓颉编程语言编写。

由于时间有限，我决定不实现用于快速搜索的索引文件。

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

## 数据库结构

```structure
name_database（数据库名称）
|--database.meta（数据库元数据）
|--name_table（表名称）
|  |--table.meta（表元数据）
|  |--page.data（页面数据）
|  |--index（索引）
|  |  |--column_0.index（列0索引）
|  |  |--column_1.index（列1索引）
|  |  |--column_2.index（列2索引）
|  !
!
```

### database.meta(.json)

| 键 | 类型 |
| --- | ----- |
| 魔法名称 | "CJDB" |
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

| 索引 | 列_0 | 列_1 | ... |
| ----- | -------- | -------- | --- |
| 无符号整数 | T | T | ... |
| ... | ... | ... | ... |

### column.index(.json)(未实现)

| 键 | 值 |
| --- | ----- |
| 索引 | 无符号整数 |
| 数据 | 映射<值, 行索引> |
