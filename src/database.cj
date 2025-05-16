package CJDataBase

import std.fs.*
import std.collection.ArrayList
import encoding.json.*
import std.collection.HashMap
import std.io.*
import std.convert.*

func create_database(database_name: String, root_path!: String = "./") : Bool
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

    // 初始化注册文件
    let map = HashMap<String, JsonValue>()
    map["MagicName"] = JsonValue.fromStr("\"CJDB\"")
    map["DatabaseName"] = JsonValue.fromStr("\"" + database_name + "\"")
    map["TableCount"] = JsonInt(0)
    map["TableName"] = JsonArray()

    let json = JsonObject(map)
    database_meta_file.write(json.toString().toArray())
    return true
}

func drop_database(database_name: String, root_path!: String = "./") : Bool
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

class Database {
    let path: Path
    let database_name: String
    let table_count: UInt64
    let table_name: Array<String>

    // use命令
    public init(database_name: String, database_path_parent!: String = "./")
    {
        this.database_name = database_name
        this.path = Path(database_path_parent + database_name)

        if (File.exists(this.path.join("database.meta")))
        {
            let database_meta = File(this.path.join("database.meta"), Open(true, false))

            let jsonString = String.fromUtf8(database_meta.readToEnd())
            
            println(jsonString)

            if (jsonParse(jsonString, "MagicName") == "\"CJDB\"")
            {
                this.table_count = UInt64.parse(jsonParse(jsonString, "TableCount"))
                this.table_name = jsonParse(jsonString, "TableName").split(",")
                database_meta.close()
            }
            else
            {
                this.table_count = 0
                this.table_name = Array<String>()
                database_meta.close()
                throw Exception("Database Metadata is invalid.")
            }
        }
        else
        {
            throw Exception("Database ${this.database_name} doesn't exist.")
        }
    }

    public func create_table() 
    {
        
    }
}