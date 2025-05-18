package CJDataBase

import std.fs.*
import std.collection.ArrayList
import encoding.json.*
import std.collection.HashMap
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
    public init(database_name: String, database_path_parent!: String = root_dir)
    {       
        this.database_name = database_name
        this.path = Path(database_path_parent + database_name)

        if (File.exists(this.path.join("database.meta")))
        {
            let database_meta = File(this.path.join("database.meta"), Open(true, false))

            let jsonString = String.fromUtf8(database_meta.readToEnd())
            
            println(jsonString)

            let r = DatabaseMeta.deserialize(DataModel.fromJson(JsonValue.fromStr(jsonString)))

            if (r.MagicName == "CJDB")
            {
                this.table_count = UInt64.parse(r.TableCount.toString())
                this.table_name = ArrayList<String>(r.TableName)
                database_meta.close()
            }
            else
            {
                this.table_count = 0
                this.table_name = ArrayList<String>()
                database_meta.close()
                throw Exception("Database Metadata is invalid.")
            }
        }
        else
        {
            throw Exception("Database ${this.database_name} doesn't exist.")
        }
    }

    // 创建数据库
    public static func create_database(database_name: String, root_path!: String = root_dir) : Bool
    {
        // 根文件夹位置
        let path = Path(root_path + database_name)

        // 创建根文件夹
        try 
        {
            Directory.create(path)
        }
        catch (e: FSException) 
        {
            println("Failed to create Database ${database_name} root folder.")
            return false
        }
        
        // 创建数据库注册文件
        let database_meta_file = File(path.join("database.meta"), CreateOrTruncate(true))

        let d = DatabaseMeta("CJDB", database_name, 0, Array<String>())

        database_meta_file.write(d.serialize().toJson().toString().toArray())
        return true
    }

    // 删除数据库
    public static func drop_database(database_name: String, root_path!: String = root_dir) : Bool
    {
        if (Directory.exists(Path(root_path + database_name)))
        {
            Directory.delete(Path(root_path + database_name), recursive: true)
            return true
        }
        else
        {
            throw Exception("Database ${database_name} does not exist.")
            return false
        }
    }

    // 创建表
    public func create_table(table_name: String, column_names: ArrayList<String>, column_types: ArrayList<String>) : Bool
    {
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
        let tm = TableMeta(table_name, 0, UInt64.parse(column_names.size.toString()), Array<Array<String>>())
        for (i in 0..column_names.size)
        {
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
        let dbMeta = DatabaseMeta("CJDB", "\"" + this.database_name + "\"", this.table_count, tableNameArray.toArray())
        database_meta_file.write(dbMeta.serialize().toJson().toString().toArray())
        database_meta_file.close()
        
        println("Table ${table_name} created successfully.")
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
            for (i in 0..this.table_name.size)
            {
                if (this.table_name[i] == table_name)
                {
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
            let dbMeta = DatabaseMeta("CJDB", "\"" + this.database_name + "\"", this.table_count, tableNameArray.toArray())
            database_meta_file.write(dbMeta.serialize().toJson().toString().toArray())
            database_meta_file.close()
            
            println("Table ${table_name} dropped successfully.")
            return true
        }
        catch (e: FSException) {
            println("Failed to drop table ${table_name}: ${e}")
            return false
        }
    }

    public func info_table(table_name: String) 
    {
        let tb = Table(table_name,  this.database_name)
        println("Path: ${tb.getPath()}")
        println("Table Name: ${tb.getTableName()}")
        println("Row Count: ${tb.getRowCount()}")
        println("Column Count: ${tb.getColumnCount()}")
        println("Column Names: ${tb.getColumnNames()}")
        println("Column Types: ${tb.getColumnTypes()}")
    }

    public func insert(table_name: String, keys: ArrayList<String>, values: ArrayList<String>) : Bool
    {
        let tb = Table(table_name, this.database_name)
        tb.insert(keys, values)
    }

    public func delete(table_name: String, condition: String) : Bool
    {
        // 检查表是否存在
        if (!this.table_name.contains(table_name)) {
            throw Exception("Table ${table_name} does not exist.")
            return false
        }
        
        var parts = condition.split(" ")
        var op = ""

        if (condition.contains("<"))
        {
            parts = condition.split("<")
            op = "<"
        }
        else if (condition.contains(">"))
        {
            parts = condition.split(">")
            op = ">"
        }
        else if (condition.contains("="))
        {
            parts = condition.split("=")
            op = "="
        }

        if (parts.size != 2) {
            throw Exception("Invalid condition format. Should be 'column_name operator value'.")
            return false
        }
        
        let column_name = parts[0]
        let operator_name = op
        let value = parts[1]
        
        // 验证运算符
        if (operator_name != ">" && operator_name != "<" && operator_name != "=") {
            throw Exception("Invalid operator. Supported operators: >, <, =")
            return false
        }
        
        // 获取表对象
        let tb = Table(table_name, this.database_name)
        
        // 调用表的delete_where方法
        let deleted_count = tb.delete_where(column_name, operator_name, value)
        return deleted_count > 0
    }

    public func delete(table_name: String)
    {
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
            println("Data file for table ${table_name} has been cleared.")
        }
        
        // 更新元数据文件，将行数重置为0
        let meta_file = File(Path(root_dir).join(database_name).join(table_name).join("table.meta"), CreateOrTruncate(true))
        meta_file.write(tm.serialize().toJson().toString().toArray())
        meta_file.close()
        
        println("All records in table ${table_name} have been deleted.")
    }
}

// 数据表
class Table
{
    private let path: Path
    private let table_name: String
    private var row_count: UInt64
    private var column_count: UInt64
    private var column_names: ArrayList<String>
    private var column_types: ArrayList<String>
    
    // 初始化表，自动读取元数据
    public init(table_name: String, database_name: String, database_path!: Path = Path("./")) 
    {
        this.path = database_path.join(database_name).join(table_name)
        this.table_name = table_name
        this.column_names = ArrayList<String>()
        this.column_types = ArrayList<String>()
        
        // 检查表目录是否存在
        if (!Directory.exists(this.path)) 
        {
            throw Exception("Table directory ${table_name} does not exist.")
        }
        
        // 读取表元数据
        let meta_file_path = this.path.join("table.meta")
        if (!File.exists(meta_file_path)) 
        {
            throw Exception("Table metadata for ${table_name} does not exist.")
        }
        
        try 
        {
            let table_meta_file = File(meta_file_path, Open(true, false))
            let jsonString = String.fromUtf8(table_meta_file.readToEnd())
            
            // 使用TableMeta类解析表元数据
            let jv = JsonValue.fromStr(jsonString)
            let dm = DataModel.fromJson(jv)
            let tableMeta = TableMeta.deserialize(dm)
            
            if (tableMeta.TableName == this.table_name) 
            {
                this.row_count = tableMeta.RowCount
                this.column_count = tableMeta.ColumnCount
                
                // 从TableColumnInfo中提取列名和类型
                let columnInfo = tableMeta.TableColumnInfo
                for (i in 0..columnInfo.size) 
                {
                    if (columnInfo[i].size >= 2) 
                    {
                        this.column_names.append(columnInfo[i][0])
                        this.column_types.append(columnInfo[i][1])
                    }
                }
                
                table_meta_file.close()
            } 
            else 
            {
                this.row_count = 0
                this.column_count = 0
                table_meta_file.close()
                throw Exception("Table Metadata is invalid.")
            }
        } 
        catch (e: FSException) 
        {
            throw Exception("Failed to read table metadata: ${e}")
        }
        catch (e: Exception)
        {
            throw Exception("Failed to parse table metadata: ${e}")
        }
    }   
    
    // 插入数据
    public func insert(keys: ArrayList<String>, values: ArrayList<String>) : Bool
    {
        // 检查键和值的数量是否匹配
        if (keys.size != values.size) {
            throw Exception("Keys and values count mismatch.")
            return false
        }
        
        // 创建一个映射，存储列名与值的对应关系
        let valueMap = HashMap<String, String>()
        for (i in 0..keys.size) {
            valueMap.put(keys[i], values[i])
        }
        
        // 创建完整的行数据（按表中列的顺序）
        let rowData = ArrayList<String>()
        for (i in 0..this.column_names.size) {
            let columnName = this.column_names[i]
            let columnType = this.column_types[i]
            
            if (!valueMap.contains(columnName)) {
                throw Exception("Missing value for column ${columnName}")
                return false
            }
            
            let value = valueMap.get(columnName).getOrThrow()
            
            // 根据列类型验证和格式化值
            try {
                // 如果是字符串类型（被引号包裹）
                if (value.startsWith("\"") && value.endsWith("\"")) {
                    // 对于字符串类型，保持原样
                    rowData.append(value)
                }
                // 如果是整数类型
                else if (columnType == "int") {
                    // 验证是否为有效整数
                    let _ = Int64.parse(value)
                    rowData.append(value)
                }
                // 如果是浮点数类型
                else if (columnType == "float") {
                    // 验证是否为有效浮点数
                    let _ = Float64.parse(value)
                    rowData.append(value)
                }
                // 其他类型（默认作为字符串处理）
                else {
                    rowData.append("\"" + value + "\"")
                }
            }
            catch (e: Exception) {
                throw Exception("Invalid value type for column ${columnName}: ${value} should be ${columnType}")
                return false
            }
        }
        
        try {
            // 打开数据文件进行追加
            let dataFile = File(this.path.join("page.data"), Append)
            
            var csvLine:String = ""
            for (i in rowData)
            {
                csvLine += i + ","
            }

            csvLine = csvLine.trimRight(",")
            
            // 如果不是第一行，先添加一个换行符
            if (this.row_count > 0) {
                dataFile.write("\n".toArray())
            }
            
            // 写入CSV行
            dataFile.write(csvLine.toArray())
            dataFile.close()
            
            // 更新行计数
            this.row_count++
            
            // 更新表元数据文件
            let tableMeta = TableMeta(this.table_name, this.row_count, this.column_count, Array<Array<String>>())
            
            // 添加列信息
            for (i in 0..this.column_names.size) {
                tableMeta.append(this.column_names[i], this.column_types[i])
            }
            
            let metaFile = File(this.path.join("table.meta"), CreateOrTruncate(true))
            metaFile.write(tableMeta.serialize().toJson().toString().toArray())
            metaFile.close()
            
            println("Data inserted successfully.")
            return true
        }
        catch (e: FSException) {
            println("Failed to write data to file: ${e}")
            return false
        }
        catch (e: Exception) {
            println("Error during insert operation: ${e}")
            return false
        }
    }

    // 删除满足条件的记录
    public func delete(condition_column: String, condition_value: String) : UInt64
    {
        // 检查条件列是否存在
        var columnIndex = -1
        for (i in 0..this.column_names.size) {
            if (this.column_names[i] == condition_column) {
                columnIndex = i
                break
            }
        }
        
        if (columnIndex == -1) {
            throw Exception("Column ${condition_column} does not exist in table.")
            return 0
        }
        
        try {
            // 读取所有现有数据
            let dataFilePath = this.path.join("page.data")
            if (!File.exists(dataFilePath)) {
                throw Exception("Data file not found for table ${this.table_name}.")
                return 0
            }
            
            let dataFile = File(dataFilePath, Open(true, false))
            let fileContent = String.fromUtf8(dataFile.readToEnd())
            dataFile.close()
            
            // 如果文件为空，没有记录可删除
            if (fileContent.isEmpty()) {
                return 0
            }
            
            // 按行分割
            let lines = fileContent.split("\n")
            let newLines = ArrayList<String>()
            var deletedCount: UInt64 = 0
            
            // 处理每一行
            for (line in lines) {
                // 跳过空行
                if (line.isEmpty()) {
                    continue
                }
                
                // 解析CSV行
                let values = line.split(",")
                
                // 确保索引有效
                if (columnIndex >= values.size) {
                    // 行格式不正确，保留该行
                    newLines.append(line)
                    continue
                }
                
                // 检查条件
                let cellValue = values[columnIndex]
                
                // 如果不匹配条件，保留此行
                if (cellValue != condition_value) {
                    newLines.append(line)
                } else {
                    deletedCount++
                }
            }
            
            // 没有找到匹配的记录
            if (deletedCount == 0) {
                return 0
            }
            
            // 重写数据文件
            let newDataFile = File(dataFilePath, CreateOrTruncate(true))
            
            // 写入保留的行
            for (i in 0..newLines.size) {
                if (i > 0) {
                    newDataFile.write("\n".toArray())
                }
                newDataFile.write(newLines[i].toArray())
            }
            
            newDataFile.close()
            
            // 更新行计数
            this.row_count -= deletedCount
            
            // 更新表元数据
            let tableMeta = TableMeta(this.table_name, this.row_count, this.column_count, Array<Array<String>>())
            
            // 添加列信息
            for (i in 0..this.column_names.size) {
                tableMeta.append(this.column_names[i], this.column_types[i])
            }
            
            let metaFile = File(this.path.join("table.meta"), CreateOrTruncate(true))
            metaFile.write(tableMeta.serialize().toJson().toString().toArray())
            metaFile.close()
            
            println("Deleted ${deletedCount} records from table ${this.table_name}.")
            return deletedCount
        }
        catch (e: FSException) {
            println("Failed to delete records: ${e}")
            return 0
        }
        catch (e: Exception) {
            println("Error during delete operation: ${e}")
            return 0
        }
    }

    // 根据条件删除记录
    public func delete_where(condition_column: String, operator_name: String, condition_value: String) : UInt64
    {
        // 检查条件列是否存在
        var columnIndex = -1
        for (i in 0..this.column_names.size) {
            if (this.column_names[i] == condition_column) {
                columnIndex = i
                break
            }
        }
        
        if (columnIndex == -1) {
            throw Exception("Column ${condition_column} does not exist in table.")
            return 0
        }
        
        // 获取列类型
        let columnType = this.column_types[columnIndex]
        let isNumeric = columnType == "int" || columnType == "float"
        
        try {
            // 读取所有现有数据
            let dataFilePath = this.path.join("page.data")
            if (!File.exists(dataFilePath)) {
                throw Exception("Data file not found for table ${this.table_name}.")
                return 0
            }
            
            let dataFile = File(dataFilePath, Open(true, false))
            let fileContent = String.fromUtf8(dataFile.readToEnd())
            dataFile.close()
            
            // 如果文件为空，没有记录可删除
            if (fileContent.isEmpty()) {
                return 0
            }
            
            // 按行分割
            let lines = fileContent.split("\n")
            let newLines = ArrayList<String>()
            var deletedCount: UInt64 = 0
            
            // 如果是数值比较，预先转换条件值
            var numericConditionValue: Float64 = 0.0
            if (isNumeric) {
                try {
                    numericConditionValue = Float64.parse(condition_value)
                } 
                catch (e: Exception) {
                    throw Exception("Invalid numeric value for comparison: ${condition_value}")
                    return 0
                }
            }
            
            // 处理每一行
            for (line in lines) {
                // 跳过空行
                if (line.isEmpty()) {
                    continue
                }
                
                // 解析CSV行
                let values = line.split(",")
                
                // 确保索引有效
                if (columnIndex >= values.size) {
                    // 行格式不正确，保留该行
                    newLines.append(line)
                    continue
                }
                
                // 获取当前单元格值
                let cellValue = values[columnIndex]
                var keepRow = true
                
                // 根据类型和运算符进行比较
                if (isNumeric) {
                    // 数值比较
                    try {
                        let numericCellValue = Float64.parse(cellValue)
                        
                        if (operator_name == "=") {
                            keepRow = numericCellValue != numericConditionValue
                        } 
                        else if (operator_name == ">") {
                            keepRow = numericCellValue <= numericConditionValue
                        } 
                        else if (operator_name == "<") {
                            keepRow = numericCellValue >= numericConditionValue
                        }
                    } 
                    catch (e: Exception) {
                        // 无效的数值，保留行
                        keepRow = true
                    }
                } 
                else {
                    // 字符串比较
                    // 处理字符串值（去除引号）
                    var strCellValue = cellValue
                    var strCondValue = condition_value
                    
                    if (strCellValue.startsWith("\"") && strCellValue.endsWith("\"")) {
                        strCellValue = substring(strCellValue, 1, end_index: strCellValue.size - 1)
                    }
                    
                    if (strCondValue.startsWith("\"") && strCondValue.endsWith("\"")) {
                        strCondValue = substring(strCondValue, 1, end_index: strCondValue.size - 1)
                    }
                    
                    if (operator_name == "=") {
                        keepRow = strCellValue != strCondValue
                    } 
                    else if (operator_name == ">") {
                        keepRow = strCellValue <= strCondValue
                    } 
                    else if (operator_name == "<") {
                        keepRow = strCellValue >= strCondValue
                    }
                }
                
                // 如果符合保留条件，将该行添加到新行列表
                if (keepRow) {
                    newLines.append(line)
                } else {
                    deletedCount++
                }
            }
            
            // 没有找到匹配的记录
            if (deletedCount == 0) {
                return 0
            }
            
            // 重写数据文件
            let newDataFile = File(dataFilePath, CreateOrTruncate(true))
            
            // 写入保留的行
            for (i in 0..newLines.size) {
                if (i > 0) {
                    newDataFile.write("\n".toArray())
                }
                newDataFile.write(newLines[i].toArray())
            }
            
            newDataFile.close()
            
            // 更新行计数
            this.row_count -= deletedCount
            
            // 更新表元数据
            let tableMeta = TableMeta(this.table_name, this.row_count, this.column_count, Array<Array<String>>())
            
            // 添加列信息
            for (i in 0..this.column_names.size) {
                tableMeta.append(this.column_names[i], this.column_types[i])
            }
            
            let metaFile = File(this.path.join("table.meta"), CreateOrTruncate(true))
            metaFile.write(tableMeta.serialize().toJson().toString().toArray())
            metaFile.close()
            
            println("Deleted ${deletedCount} records from table ${this.table_name} where ${condition_column} ${operator_name} ${condition_value}.")
            return deletedCount
        }
        catch (e: FSException) {
            println("Failed to delete records: ${e}")
            return 0
        }
        catch (e: Exception) {
            println("Error during delete operation: ${e}")
            return 0
        }
    }

    // 获取表行数
    public func getRowCount() : UInt64 
    {
        return this.row_count
    }
    
    // 获取表列数
    public func getColumnCount() : UInt64 
    {
        return this.column_count
    }
    
    // 获取列名列表
    public func getColumnNames() : ArrayList<String> 
    {
        return this.column_names
    }
    
    // 获取列类型列表
    public func getColumnTypes() : ArrayList<String> 
    {
        return this.column_types
    }
    
    // 获取表路径
    public func getPath() : Path 
    {
        return this.path
    }
    
    // 获取表名
    public func getTableName() : String 
    {
        return this.table_name
    }
}