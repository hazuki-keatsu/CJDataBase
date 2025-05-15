package CJDataBase

import std.fs.*
import std.collection.ArrayList
import encoding.json.*
import encoding.json.stream.*
import std.collection.HashMap
import std.io.*

class Database {
    let path: Path
    let database_name: String

    public init(database_name: String, database_path!: String = "./")  {
        // 初始化
        this.path = Path(database_path + database_name)
        this.database_name = database_name
        // 确认数据库是否存在
        if (File.exists(this.path.join("database.meta")))
        {
            
        }
        
    }

    public func create_database()
    {
        // 创建根文件夹
        try {
            Directory.create(this.path)
        }
        catch (e: FSException) {
            println("Database ${database_name} has already existed.")
            return
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
    }
}