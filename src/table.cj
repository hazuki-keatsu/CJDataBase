package CJDataBase

import std.fs.*
import std.collection.ArrayList
import std.collection.HashMap
import std.convert.*
import encoding.json.*
import serialization.serialization.*

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
            let tableMeta = TableMeta(this.table_name, this.row_count, 0, Array<Array<String>>())
            
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

    // 按条件删除记录
    public func delete(column_name: String, operator_name: String, value: String) : UInt64
    {
        // 检查列是否存在
        var column_index = -1
        for (i in 0..this.column_names.size) {
            if (this.column_names[i] == column_name) {
                column_index = i
                break
            }
        }
        
        if (column_index == -1) {
            throw Exception("Column ${column_name} does not exist in table.")
            return 0
        }
        
        // 获取列类型
        let column_type = this.column_types[column_index]
        let is_numeric = column_type == "int" || column_type == "float"
        
        try {
            // 读取所有现有数据
            let data_file_path = this.path.join("page.data")
            if (!File.exists(data_file_path)) {
                throw Exception("Data file not found for table ${this.table_name}.")
                return 0
            }
            
            let data_file = File(data_file_path, Open(true, false))
            let file_content = String.fromUtf8(data_file.readToEnd())
            data_file.close()
            
            // 如果文件为空，没有记录可删除
            if (file_content.isEmpty()) {
                return 0
            }
            
            // 按行分割
            let lines = file_content.split("\n")
            let new_lines = ArrayList<String>()
            var deleted_count: UInt64 = 0
            
            // 如果是数值比较，预先转换条件值
            var numeric_condition_value: Float64 = 0.0
            if (is_numeric) {
                try {
                    numeric_condition_value = Float64.parse(value)
                } 
                catch (e: Exception) {
                    throw Exception("Invalid numeric value for comparison: ${value}")
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
                if (column_index >= values.size) {
                    // 行格式不正确，保留该行
                    new_lines.append(line)
                    continue
                }
                
                // 获取当前单元格值
                let cell_value = values[column_index]
                var keep_row = true
                
                // 根据类型和运算符进行比较
                if (is_numeric) {
                    // 数值比较
                    try {
                        let numeric_cell_value = Float64.parse(cell_value)
                        
                        if (operator_name == "=") {
                            keep_row = numeric_cell_value != numeric_condition_value
                        } 
                        else if (operator_name == ">") {
                            keep_row = numeric_cell_value <= numeric_condition_value
                        } 
                        else if (operator_name == "<") {
                            keep_row = numeric_cell_value >= numeric_condition_value
                        }
                    } 
                    catch (e: Exception) {
                        // 无效的数值，保留行
                        keep_row = true
                    }
                } 
                else {
                    // 字符串比较
                    // 处理字符串值（去除引号）
                    var str_cell_value = cell_value
                    var str_cond_value = value
                    
                    if (str_cell_value.startsWith("\"") && str_cell_value.endsWith("\"")) {
                        str_cell_value = substring(str_cell_value, 1, end_index: str_cell_value.size - 1)
                    }
                    
                    if (str_cond_value.startsWith("\"") && str_cond_value.endsWith("\"")) {
                        str_cond_value = substring(str_cond_value, 1, end_index: str_cond_value.size - 1)
                    }
                    
                    if (operator_name == "=") {
                        keep_row = str_cell_value != str_cond_value
                    } 
                    else if (operator_name == ">") {
                        keep_row = str_cell_value <= str_cond_value
                    } 
                    else if (operator_name == "<") {
                        keep_row = str_cell_value >= str_cond_value
                    }
                }
                
                // 如果符合保留条件，将该行添加到新行列表
                if (keep_row) {
                    new_lines.append(line)
                } else {
                    deleted_count++
                }
            }
            
            // 如果没有找到匹配的记录，直接返回
            if (deleted_count == 0) {
                return 0
            }
            
            // 重写数据文件
            let new_data_file = File(data_file_path, CreateOrTruncate(true))
            
            // 写入保留的行
            for (i in 0..new_lines.size) {
                if (i > 0) {
                    new_data_file.write("\n".toArray())
                }
                new_data_file.write(new_lines[i].toArray())
            }
            
            new_data_file.close()
            
            // 更新行计数
            this.row_count -= deleted_count
            
            // 更新表元数据
            let table_meta = TableMeta(this.table_name, this.row_count, 0, Array<Array<String>>())
            
            // 添加列信息
            for (i in 0..this.column_names.size) {
                table_meta.append(this.column_names[i], this.column_types[i])
            }
            
            let meta_file = File(this.path.join("table.meta"), CreateOrTruncate(true))
            meta_file.write(table_meta.serialize().toJson().toString().toArray())
            meta_file.close()
            
            println("Deleted ${deleted_count} records from table ${this.table_name} where ${column_name} ${operator_name} ${value}.")
            return deleted_count
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

    // 读取所有数据
    public func readAllData() : String {
        try {
            let data_file_path = this.path.join("page.data")
            if (!File.exists(data_file_path)) {
                return ""
            }
            
            let data_file = File(data_file_path, Open(true, false))
            let content = String.fromUtf8(data_file.readToEnd())
            data_file.close()
            
            return content
        }
        catch (e: FSException) {
            println("Failed to read data file: ${e}")
            return ""
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