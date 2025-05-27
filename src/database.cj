package CJDataBase

import std.fs.*
import encoding.json.*
import std.collection.*
import std.io.*
import std.convert.*
import std.unicode.*
import serialization.serialization.*

class Database {
    private let path: Path
    private let database_name: String
    private var table_count: UInt64
    private var table_name: ArrayList<String>

    // use命令
    public init(database_name: String, database_path_parent!: String = root_dir) {       
        this.database_name = database_name
        this.path = Path(database_path_parent + database_name)

        if (File.exists(this.path.join("database.meta"))) {
            let database_meta = File(this.path.join("database.meta"), Open(true, false))

            let jsonString = String.fromUtf8(database_meta.readToEnd())

            let r = DatabaseMeta.deserialize(DataModel.fromJson(JsonValue.fromStr(jsonString)))

            if (r.MagicName == "CJDB") {
                this.table_count = UInt64.parse(r.TableCount.toString())
                this.table_name = ArrayList<String>(r.TableName)
                database_meta.close()
            }
            else {
                this.table_count = 0
                this.table_name = ArrayList<String>()
                database_meta.close()
                throw Exception("Database Metadata is invalid.")
            }
        }
        else {
            throw Exception("Database ${this.database_name} doesn't exist.")
        }
    }

    // 创建数据库
    public static func create_database(database_name: String, root_path!: String = root_dir) : Bool {
        // 根文件夹位置
        let path = Path(root_path + database_name)

        // 创建根文件夹
        try {
            Directory.create(path)
        }
        catch (e: FSException) {
            println("Failed to create Database ${database_name} root folder.")
            return false
        }
        
        // 创建数据库注册文件
        let database_meta_file = File(path.join("database.meta"), CreateOrTruncate(true))

        let d = DatabaseMeta("CJDB", database_name, 0, Array<String>())

        database_meta_file.write(d.serialize().toJson().toString().toArray())
        database_meta_file.close()  // 添加文件关闭
        return true
    }

    // 删除数据库
    public static func drop_database(database_name: String, root_path!: String = root_dir) : Bool {
        if (Directory.exists(Path(root_path + database_name))) {
            Directory.delete(Path(root_path + database_name), recursive: true)
            return true
        }
        else {
            throw Exception("Database ${database_name} does not exist.")
            return false
        }
    }

    // 创建表
    public func create_table(table_name: String, column_names: ArrayList<String>, column_types: ArrayList<String>) : Bool {
        // 检查列名和类型数量是否匹配
        if (column_names.size != column_types.size) {
            throw Exception("Column names and types count mismatch.")
            return false
        }
        
        // 检查表是否已存在
        if (this.table_name.contains(table_name)) {
            throw Exception("Table ${table_name} already exists.")
            return false
        }
        
        // 创建表目录
        let table_path = this.path.join(table_name)
        try {
            Directory.create(table_path)
        }
        catch (e: FSException) {
            throw Exception("Failed to create table ${table_name} directory.")
            return false
        }

        // 创建表元数据文件
        let table_meta_file = File(table_path.join("table.meta"), CreateOrTruncate(true))
        // 使用meta.cj中的TableMeta类
        let tm = TableMeta(table_name, 0, 0, Array<Array<String>>())
        for (i in 0..column_names.size) {
            tm.append(column_names[i], column_types[i])
        }
        table_meta_file.write(tm.serialize().toJson().toString().toArray())
        table_meta_file.close()
        
        // 创建空的数据文件
        let data_file = File(table_path.join("page.data"), CreateOrTruncate(true))
        data_file.close()
        
        // // 创建索引目录
        // let index_path = table_path.join("index")
        // try {
        //     Directory.create(index_path)
        // }
        // catch (e: FSException) {
        //     println("Failed to create index directory for table ${table_name}.")
        //     return false
        // }
        
        // // 为每列创建空索引文件
        // for (i in 0..column_names.size) {
        //     let index_file_name = "column_" + i.toString() + ".index"
        //     let index_file = File(index_path.join(index_file_name), CreateOrTruncate(true))
            
        //     let id = IndexData(UInt64(i), Array<Data_file>())
        //     let jsonString = id.serialize().toJson().toString()
        //     index_file.write(jsonString.toArray())
        //     index_file.close()
        // }
        
        // 更新数据库元数据
        this.table_count++
        this.table_name.append(table_name)
        
        // 更新数据库元数据文件
        let database_meta_file = File(this.path.join("database.meta"), CreateOrTruncate(true))
        
        // 构建表名数组
        let tableNameArray = ArrayList<String>()
        for (i in 0..this.table_name.size) {
            tableNameArray.append(this.table_name[i])
        }
        
        // 使用meta.cj中的DatabaseMeta类
        let dbMeta = DatabaseMeta("CJDB", this.database_name, this.table_count, tableNameArray.toArray())
        database_meta_file.write(dbMeta.serialize().toJson().toString().toArray())
        database_meta_file.close()
        
        return true
    }

    // 删除表
    public func drop_table(table_name: String) : Bool
    {
        // 检查表是否存在
        if (!this.table_name.contains(table_name)) {
            throw Exception("Table ${table_name} does not exist.")
            return false
        }
        
        // 表路径
        let table_path = this.path.join(table_name)
        
        // 检查表目录是否存在
        if (!Directory.exists(table_path)) {
            throw Exception("Table directory ${table_name} does not exist.")
            return false
        }
        
        try {
            // 删除表目录及其所有内容(索引目录、表元数据、数据文件等)
            Directory.delete(table_path, recursive: true)
            
            // 从表列表中移除
            for (i in 0..this.table_name.size) {
                if (this.table_name[i] == table_name) {
                    this.table_name.remove(i)
                }
            }
            
            // 更新表计数
            this.table_count--
            
            // 更新数据库元数据文件
            let database_meta_file = File(this.path.join("database.meta"), CreateOrTruncate(true))
            
            // 构建表名数组
            let tableNameArray = ArrayList<String>()
            for (i in 0..this.table_name.size) {
                tableNameArray.append(this.table_name[i])
            }
            
            // 使用meta.cj中的DatabaseMeta类
            let dbMeta = DatabaseMeta("CJDB", this.database_name , this.table_count, tableNameArray.toArray())
            database_meta_file.write(dbMeta.serialize().toJson().toString().toArray())
            database_meta_file.close()
            
            return true
        }
        catch (e: FSException) {
            println("Failed to drop table ${table_name}: ${e}")
            return false
        }
    }

    public func info_table(table_name: String) {
        let tb = Table(table_name,  this.database_name)
        println("Path: ${tb.getPath()}")
        println("Table Name: ${tb.getTableName()}")
        println("Row Count: ${tb.getRowCount()}")
        println("Column Count: ${tb.getColumnCount()}")
        println("Column Names: ${tb.getColumnNames()}")
        println("Column Types: ${tb.getColumnTypes()}")
    }

    public func insert(table_name: String, keys: ArrayList<String>, values: ArrayList<String>) {
        let tb = Table(table_name, this.database_name)
        tb.insert(keys, values)
    }

    public func delete(table_name: String) {
        let json_file = File(Path(root_dir).join(database_name).join(table_name).join("table.meta"), Open(true, true))
        let json_str = String.fromUtf8(json_file.readToEnd().toArray())
        let tm = TableMeta.deserialize(DataModel.fromJson(JsonValue.fromStr(json_str)))
        tm.RowCount = 0

        json_file.write(tm.serialize().toJson().toString().toArray())
        json_file.close()

        // 清空数据文件
        let data_file_path = Path(root_dir).join(database_name).join(table_name).join("page.data")
        if (File.exists(data_file_path)) {
            let data_file = File(data_file_path, CreateOrTruncate(true))
            data_file.close()
            // println("Data file for table ${table_name} has been cleared.")
        }
        
        // 更新元数据文件，将行数重置为0
        let meta_file = File(Path(root_dir).join(database_name).join(table_name).join("table.meta"), CreateOrTruncate(true))
        meta_file.write(tm.serialize().toJson().toString().toArray())
        meta_file.close()
        
        // println("All records in table ${table_name} have been deleted.")
    }

    public func delete(table_name: String, condition: String) : Bool {
        // 使用提取的方法检查表存在性
        if (!validateTableExists(table_name)) {
            return false
        }
        
        // 使用提取的方法解析条件
        let (column_name, operator_name, value) = parseCondition(condition)
        
        // 获取表对象
        let tb = Table(table_name, this.database_name)
        
        // 调用表的delete方法
        let deleted_count = tb.delete(column_name, operator_name, value)
        return deleted_count > 0
    }
    
    // 格式化值（去除多余引号等）
    private func formatValue(value: String) : String {
        if (value == "") {
            return ""
        }
        
        var formatted = value
        // 去除外层引号
        if (formatted.startsWith("\"") && formatted.endsWith("\"")) {
            formatted = substring(formatted, 1, end_index: formatted.size - 1)
        }
        println(formatted)

        return formatted
    }

    // SELECT 查询函数
    public func select(table_name: String, columns: String, condition: String, order_column: String, order_direction: String) : Bool {
        // 使用提取的方法检查表存在性
        if (!validateTableExists(table_name)) {
            return false
        }
        
        try {
            // 获取表对象
            let tb = Table(table_name, this.database_name)
            
            // 解析要选择的列
            var selected_columns = ArrayList<String>()
            if (columns == "*") {
                // 选择所有列
                selected_columns = tb.getColumnNames()
            } else {
                // 选择指定列
                let col_names = columns.split(" ")
                for (col in col_names) {
                    if (!col.isEmpty()) {
                        selected_columns.append(col)
                    }
                }
            }
            
            // 验证选择的列是否存在
            let all_columns = tb.getColumnNames()
            for (col in selected_columns) {
                var found = false
                for (actual_col in all_columns) {
                    if (col == actual_col) {
                        found = true
                        break
                    }
                }
                
                if (!found) {
                    throw Exception("Column ${col} does not exist in table ${table_name}.")
                    return false
                }
            }
            
            // 读取表数据
            let data = tb.readAllData()
            if (data.isEmpty()) {
                println("No data in table ${table_name}.")
                return true
            }
            
            // 按行解析数据
            let rows = data.split("\n")
            let result_rows = ArrayList<ArrayList<String>>()
            
            // 获取列索引映射
            let column_indices = HashMap<String, UInt64>()
            let all_column_names = tb.getColumnNames()
            let column_types = tb.getColumnTypes()
            
            for (i in 0..all_column_names.size) {
                column_indices.put(all_column_names[i], UInt64(i))
            }
            
            // 筛选符合条件的行
            for (row_str in rows) {
                if (row_str.isEmpty()) {
                    continue
                }
                
                let values = row_str.split(",")
                
                // 检查是否符合条件
                if (!condition.isEmpty()) {
                    var meets_condition = evaluateCondition(condition, values, column_indices, column_types)
                    if (!meets_condition) {
                        continue
                    }
                }
                
                // 提取选定的列
                let selected_values = ArrayList<String>()
                for (col in selected_columns) {
                    let col_index = column_indices[col]
                    if (col_index < UInt64(values.size)) {
                        selected_values.append(values[Int64(col_index)])
                    } else {
                        selected_values.append("")
                    }
                }
                
                result_rows.append(selected_values)
            }
            
            // 如果有排序需求
            if (!order_column.isEmpty()) {
                // 验证排序列是否有效
                if (!column_indices.contains(order_column)) {
                    throw Exception("Order column ${order_column} does not exist.")
                    return false
                }
                
                // 获取排序列的索引
                var order_col_index = -1
                for (i in 0..selected_columns.size) {
                    if (selected_columns[i] == order_column) {
                        order_col_index = i
                        break
                    }
                }
                
                // 如果排序列不在选择列中
                if (order_col_index == -1) {
                    throw Exception("Order column must be in the selected columns.")
                    return false
                }
                
                // 获取排序列的类型
                let col_type = column_types[Int64(column_indices[order_column])]
                let is_numeric = col_type == "int" || col_type == "float"
                
                // 排序
                sortRows(result_rows, order_col_index, is_numeric, order_direction)
            }
            
            // 显示结果标题
            var header = "num>"
            for (i in 0..selected_columns.size) {
                if (i >= 0) {
                    header += "\t"
                }
                header += selected_columns[i]
            }
            println(header)
            
            // 显示分割线
            var separator = ""
            for (i in 0..header.size) {
                separator += "-"
            }
            println(separator)

            // 显示数据行
            var num = 0
            for (row in result_rows) {
                var row_str = "${num}>"
                for (i in 0..row.size) {
                    if (i >= 0) {
                        row_str += "\t"
                    }
                    let value = row[i]

                    row_str += value
                }
                num++
                println(row_str)
            }
            
            return true
        }
        catch (e: Exception) {
            println("Error during select operation: ${e}")
            return false
        }
    }

    // 排序行
    private func sortRows(rows: ArrayList<ArrayList<String>>, col_index: Int64, is_numeric: Bool, direction: String) {
        // 自定义排序
        for (i in 0..(rows.size - 1)) {
            for (j in 0..(rows.size - i - 2)) {
                var swap = false
                
                if (is_numeric) {
                    // 数值比较
                    try {
                        let val1 = Float64.parse(trim_for_13(rows[j][col_index]))
                        let val2 = Float64.parse(trim_for_13(rows[j+1][col_index]))
                        
                        if (direction == "asc" && val1 > val2) {
                            swap = true
                        } else if (direction == "desc" && val1 < val2) {
                            swap = true
                        }
                    }
                    catch (e: Exception) {
                        // 如果解析失败，按字符串处理
                        let str1 = formatValue(rows[j][col_index])
                        let str2 = formatValue(rows[j+1][col_index])
                        
                        if (direction == "asc" && str1 > str2) {
                            swap = true
                        } else if (direction == "desc" && str1 < str2) {
                            swap = true
                        }
                    }
                }
                else {
                    // 字符串比较
                    let str1 = formatValue(rows[j][col_index])
                    let str2 = formatValue(rows[j+1][col_index])
                    
                    if (direction == "asc" && str1 > str2) {
                        swap = true
                    } else if (direction == "desc" && str1 < str2) {
                        swap = true
                    }
                }
                
                if (swap) {
                    let temp = rows[j]
                    rows[j] = rows[j+1]
                    rows[j+1] = temp
                }
            }
        }
    }
    
    // 提取的私有方法：检查表是否存在
    private func validateTableExists(table_name: String) : Bool {
        if (!this.table_name.contains(table_name)) {
            throw Exception("Table ${table_name} does not exist.")
            return false
        }
        return true
    }

    // 提取的私有方法：解析条件
    private func parseCondition(condition: String) : (String, String, String) {
        var parts = condition.split(" ")
        var op = ""

        if (condition.contains("<")) {
            parts = condition.split("<")
            op = "<"
        }
        else if (condition.contains(">")) {
            parts = condition.split(">")
            op = ">"
        }
        else if (condition.contains("=")) {
            parts = condition.split("=")
            op = "="
        }

        if (parts.size != 2) {
            throw Exception("Invalid condition format. Should be 'column_name operator value'.")
        }
        
        let column_name = parts[0]
        let operator_name = op
        let value = parts[1]
        
        // 验证运算符
        if (operator_name != ">" && operator_name != "<" && operator_name != "=") {
            throw Exception("Invalid operator. Supported operators: >, <, =")
        }

        return (column_name, operator_name, value)
    }  

    // 条件评估方法
    private func evaluateCondition(condition: String, values: Array<String>, column_indices: Map<String, UInt64>, column_types: ArrayList<String>) : Bool {
        // 使用提取的条件解析方法
        let (col_name, op, comparison_value) = parseCondition(condition)
        
        // 检查列是否存在
        if (!column_indices.contains(col_name)) {
            throw Exception("Column ${col_name} not found in condition: ${condition}")
            return false
        }
        
        let col_index = column_indices[col_name]
        if (col_index >= UInt64(values.size)) {
            return false
        }
        
        // 获取列类型
        let col_type = column_types[Int64(col_index)]
        let is_numeric = col_type == "int" || col_type == "float"
        
        // 获取当前值
        let current_value = values[Int64(col_index)]
        
        // 比较
        if (is_numeric) {
            // 数值比较
            try {
                // 对于数值比较，需要处理引号
                var clean_comparison_value = comparison_value
                if (clean_comparison_value.startsWith("\"") && clean_comparison_value.endsWith("\"")) {
                    clean_comparison_value = substring(clean_comparison_value, 1, end_index: clean_comparison_value.size - 1)
                }
                
                let num_current = Float64.parse(trim_for_13(current_value))
                let num_comparison = Float64.parse(trim_for_13(clean_comparison_value))
                
                if (op == "=") {
                    return num_current == num_comparison
                }
                else if (op == ">") {
                    return num_current > num_comparison
                }
                else if (op == "<") {
                    return num_current < num_comparison
                }
            }
            catch (e: Exception) {
                println(e)
                // 如果解析失败，按字符串比较
                return compareStrings(current_value, op, comparison_value)
            }
        }
        else {
            // 字符串比较
            return compareStrings(current_value, op, comparison_value)
        }
        
        return false
    }

    // 字符串比较
    private func compareStrings(str1: String, op: String, str2: String) : Bool {
        var s1 = str1
        var s2 = str2
        
        // 去除引号
        if (s1.startsWith("\"") && s1.endsWith("\"")) {
            s1 = substring(s1, 1, end_index: s1.size - 1)
        }
        
        if (s2.startsWith("\"") && s2.endsWith("\"")) {
            s2 = substring(s2, 1, end_index: s2.size - 1)
        }
        
        if (op == "=") {
            return s1 == s2
        }
        else if (op == ">") {
            return s1 > s2
        }
        else if (op == "<") {
            return s1 < s2
        }
        return false
    }
}