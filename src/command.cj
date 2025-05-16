package CJDataBase

import std.collection.*

// 命令系统
enum COMMAND { 
    | CREATE_DATABASE
    | DROP_DATABASE
    | USE
    | CREATE_TABLE
    | DROP_TABLE
    | INFO_TABLE
    | INSERT_INTO
    | DELETE_FROM
    | SELECT
    | ERR
    | QUIT

    // 枚举转字符串
    func toString(): String {
        match (this) {
            case CREATE_DATABASE => return "CREATE_DATABASE" //f
            case DROP_DATABASE => return "DROP_DATABASE" //f
            case USE => return "USE" //f
            case CREATE_TABLE => return "CREATE_TABLE"
            case DROP_TABLE => return "DROP_TABLE"
            case INFO_TABLE => return "INFO_TABLE"
            case INSERT_INTO => return "INSERT_INTO"
            case DELETE_FROM => return "DELETE_FROM"
            case SELECT => return "SELECT"
            case ERR => return "ERR" //f
            case QUIT => return "QUIT" //f
        }
    }

    // 比较运算
    operator func ==(right: COMMAND): Bool {
        return this.toString() == right.toString()
    }
}

// 条件系统
enum CONDITION {
    | EQU
    | LOWER
    | HIGHER
    | ERRC

    // 枚举转字符串
    func toString(): String {
        match (this) {
            case EQU => return "="
            case LOWER => return "<"
            case HIGHER => return ">"
            case ERRC => return "errc"
        }
    }

    // 比较运算
    operator func ==(right: COMMAND): Bool {
        return this.toString() == right.toString()
    }
}

func command_recognition(input: String) : (COMMAND, Map<String, String>)
{
    // 命令识别
    let parse: Array<String> = input.replace("(", " ").replace(")", " ").replace(",", " ").split(" ", removeEmpty: true)

    let params: Map<String, String> = HashMap<String, String>()

    if (parse.isEmpty()) {
        return (ERR, params)
    }

    let cmd = parse[0].toString().toAsciiLower()

    if (cmd == "quit" || cmd == "exit")
    {  
        return (QUIT, params)
    }

    if (cmd == "create")
    {
        if (parse.size < 2)
        {
            return (ERR, params)
        }

        let subCmd = parse[1].toAsciiLower()

        if (subCmd == "database")
        {
            if (parse.size >= 3)
            {
                params["database_name"] = parse[2]
                return (CREATE_DATABASE, params)
            }
        } 
        else if (subCmd == "table") 
        {
            if (parse.size >= 3) 
            {
                params["table_name"] = parse[2]
                
                if (parse.size > 3) 
                {
                    var columns = ""
                    var types = ""
                    for (i in 3..parse.size:2) 
                    {
                        types += parse[i] + " "
                        columns += parse[i+1] + " "
                    }
                    params["types"] = types
                    params["columns"] = columns
                }
                
                return (CREATE_TABLE, params)
            }
        }

    }

    if (cmd == "drop") {
        if (parse.size < 3) 
        {
            return (ERR, params)
        }
        
        let subCmd = parse[1].toAsciiLower()
        
        if (subCmd == "database") 
        {
            params["database_name"] = parse[2]
            return (DROP_DATABASE, params)
        } 
        else if (subCmd == "table") 
        {
            params["table_name"] = parse[2]
            return (DROP_TABLE, params)
        }
    }

    if (cmd == "use") 
    {
        if (parse.size >= 2) 
        {
            params["database_name"] = parse[1]
            return (USE, params)
        }
    }

    if (cmd == "info" && parse.size == 3 && parse[1].toAsciiLower() == "table") 
    {
        params["table_name"] = parse[2]
        return (INFO_TABLE, params)
    }

    if (cmd == "insert" && parse.size >= 4 && parse[1].toAsciiLower() == "into") 
    {
        params["table_name"] = parse[2]
        
        var keys = ""
        var values = ""
        
        // 从第4个参数开始解析键值对 (name=john age=20)
        for (i in 3..parse.size) {
            let parts = parse[i].split("=", 2)
            if (parts.size >= 2) {
                if (parts[1].endsWith(","))
                {
                    parts[1].replace(",", "")
                }
                keys += parts[0] + " "
                values += parts[1] + " "
            }
        }
        
        params["keys"] = keys
        params["values"] = values
        
        return (INSERT_INTO, params)
    }

    if (cmd == "delete" && parse.size >= 3 && parse[1].toAsciiLower() == "from") 
    {
        params["table_name"] = parse[2]
        
        // 如果有 WHERE 子句
        var whereIndex = -1
        for (i in 3..parse.size) {
            if (parse[i].toAsciiLower() == "where") {
                whereIndex = i
                break
            }
        }
        
        if (whereIndex != -1 && whereIndex + 1 < parse.size) 
        {
            var condition = ""
            for (i in (whereIndex + 1)..parse.size) 
            {
                condition += parse[i] + " "
            }
            params["condition"] = condition.trimAscii()
        }
        
        return (DELETE_FROM, params)
    }

    if (cmd == "select" && parse.size >= 3) 
    {
        // 寻找 FROM 关键字位置
        var fromIndex = -1
        for (i in 1..parse.size) 
        {
            if (parse[i].toAsciiLower() == "from") 
            {
                fromIndex = i
                break
            }
        }
        
        if (fromIndex == -1 || fromIndex + 1 >= parse.size) 
        {
            return (ERR, params)
        }
        
        // 提取列名，处理逗号分隔的多个列名 (select col1,col2,col3 from...)
        var columnsStr = ""
        for (i in 1..fromIndex) 
        {
            columnsStr += parse[i] + " "
        }
        // 处理列名中的逗号
        columnsStr = columnsStr.replace(",", " ").trimAscii()
        params["columns"] = columnsStr
        
        // 表名
        params["table_name"] = parse[fromIndex + 1]
        
        // 检查是否有 WHERE 子句或 ORDER BY 子句
        var whereIndex = -1
        var orderByIndex = -1
        
        for (i in (fromIndex + 2)..parse.size) 
        {
            if (parse[i].toAsciiLower() == "where") 
            {
                whereIndex = i
                break
            }
            else if (parse[i].toAsciiLower() == "order" && i + 2 < parse.size && parse[i + 1].toAsciiLower() == "by") 
            {
                orderByIndex = i
                break
            }
        }
        
        // 处理 WHERE 子句
        if (whereIndex != -1) 
        {
            var condition = ""
            var i = whereIndex + 1
            
            // 收集 WHERE 条件直到找到 ORDER BY 或结束
            while (i < parse.size) 
            {
                if (parse[i].toAsciiLower() == "order" && i + 2 < parse.size && parse[i + 1].toAsciiLower() == "by") 
                {
                    orderByIndex = i
                    break
                }
                condition += parse[i] + " "
                i += 1
            }
            
            params["condition"] = condition.trimAscii()
        }
        
        // 处理 ORDER BY 子句
        if (orderByIndex != -1 && orderByIndex + 2 < parse.size) 
        {
            params["order_column"] = parse[orderByIndex + 2]
            
            // 检查是否有 ASC/DESC
            if (orderByIndex + 3 < parse.size) 
            {
                let orderDirection = parse[orderByIndex + 3].toAsciiLower()
                if (orderDirection == "asc" || orderDirection == "desc") 
                {
                    params["order_direction"] = orderDirection
                }
            }
        }
        
        return (SELECT, params)
    }

    return (ERR, params)
}

// 条件解析
func condition_recognition(input: String)
{
    if (input.contains("="))
    {
        let params = input.split("=")
        return (EQU, params)
    }
    else if (input.contains("<"))
    {
        let params = input.split("<")
        return (LOWER, params)
    }
    else if (input.contains(">"))
    {
        let params = input.split(">")
        return (HIGHER, params)
    }
    else
    {
        return (ERRC, Array<String>())
    }
}