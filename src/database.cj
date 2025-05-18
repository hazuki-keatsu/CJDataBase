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
        
        // 创建索引目录
        let index_path = table_path.join("index")
        try {
            Directory.create(index_path)
        }
        catch (e: FSException) {
            println("Failed to create index directory for table ${table_name}.")
            return false
        }
        
        // 为每列创建空索引文件
        for (i in 0..column_names.size) {
            let index_file_name = "column_" + i.toString() + ".index"
            let index_file = File(index_path.join(index_file_name), CreateOrTruncate(true))
            
            let id = IndexData(UInt64(i), Array<Data_file>())
            let jsonString = id.serialize().toJson().toString()
            index_file.write(jsonString.toArray())
            index_file.close()
        }
        
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
        let tb = Table(Path(root_dir + this.database_name), table_name)
        println("Path: ${tb.getPath()}")
        println("Table Name: ${tb.getTableName()}")
        println("Row Count: ${tb.getRowCount()}")
        println("Column Count: ${tb.getColumnCount()}")
        println("Column Names: ${tb.getColumnNames()}")
        println("Column Types: ${tb.getColumnTypes()}")
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
    public init(database_path: Path, table_name: String) 
    {
        this.path = database_path.join(table_name)
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