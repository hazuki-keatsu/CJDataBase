package CJDataBase

import std.collection.HashMap
import encoding.json.*
import std.collection.ArrayList

// Json解析器
func jsonParse(input: String, key:String)
{
    let k_v = input.trimLeft("{").trimRight("}").split(",")
    for (i in k_v)
    {
        if (i.contains(key))
        {
            let v = i.split(":")[1]
            if (v.contains("[") && v.contains("]"))
            {
                return v.trimLeft("[").trimRight("]")
            }
            else if (v.contains("{") && v.contains("}"))
            {
                return v.trimLeft("{").trimRight("}")
            }
            else
            {
                return v
            }
            break
        }
    }
    return ""
}

// 表元数据文件构建函数
func table_meta_file_builder(table_name: String, column_names: ArrayList<String>, column_types: ArrayList<String>) : HashMap<String, JsonValue>
{
    // 初始化表元数据
    let map = HashMap<String, JsonValue>()
    map["TableName"] = JsonValue.fromStr("\"" + table_name + "\"")
    map["RowCount"] = JsonInt(0)
    map["ColumnCount"] = JsonInt(column_names.size)
    
    // 创建列信息
    let columnInfoMap = JsonObject()
    for (i in 0..column_names.size) {
        // 为每个列创建类型信息 [索引, 类型]
        let columnInfo = JsonArray()
        columnInfo.add(JsonInt(i))
        columnInfo.add(JsonValue.fromStr("\"" + column_types[i] + "\""))
        
        columnInfoMap.put(column_names[i], columnInfo)
    }
    
    map["TableColumnInfo"] = columnInfoMap
    return map
}