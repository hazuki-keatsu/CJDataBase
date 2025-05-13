package CJDataBase

import std.collection.*

// insert delete select info

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
            case CREATE_DATABASE => return "CREATE_DATABASE"
            case DROP_DATABASE => return "DROP_DATABASE"
            case USE => return "USE"
            case CREATE_TABLE => return "CREATE_TABLE"
            case DROP_TABLE => return "DROP_TABLE"
            case INFO_TABLE => return "INFO_TABLE"
            case INSERT_INTO => return "INSERT_INTO"
            case DELETE_FROM => return "DELETE_FROM"
            case SELECT => return "SELECT"
            case ERR => return "ERR"
            case QUIT => return "QUIT"
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
    let parse: Array<String> = input.split(" ", -1, removeEmpty: true)

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
                        
                        types += clearMark(parse[i]) + " "
                        columns += clearMark(parse[i+1]) + " "
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

    if (cmd == "info" && parse.size == 3 && parse[1].toAsciiUpper() == "table") 
    {
        params["table_name"] = parse[2]
        return (INFO_TABLE, params)
    }

    if (cmd == "insert" && parse.size >= 4 && parse[1].toAsciiLower() == "into") 
    {
        params["table_name"] = parse[2]
        
        // 检查是否有 VALUES 关键字
        var valuesIndex = -1
        for (i in 3..parse.size) {
            if (parse[i].toAsciiLower() == "values") {
                valuesIndex = i
                break
            }
        }
        
        // 没有 VALUES 关键字时，使用传统的键值对格式
        if (valuesIndex == -1) {
            var keys = ""
            var values = ""
            
            // 从第4个参数开始解析键值对 (name=john age=20)
            for (i in 3..parse.size) {
                let parts = parse[i].split("=", 2)
                if (parts.size >= 2) {
                    keys += clearMark(parts[0]) + ","
                    values += clearMark(parts[1]) + ","
                }
            }
            
            // 移除最后的逗号
            if (keys.endsWith(",")) {
                keys = clearMark(keys)
            }
            if (values.endsWith(",")) {
                values = clearMark(values)
            }
            
            params["keys"] = keys
            params["values"] = values
        } 
        // 使用标准 SQL 格式: INSERT INTO table (col1, col2) VALUES (val1, val2)
        else {
            // 识别列名列表
            let note = "(),.;"

            if (parse[3].startsWith("(") && valuesIndex > 3) {
                var columns = ""
                for (i in 3..valuesIndex) {
                    columns += parse[i] + " "
                }
                // 清理括号和逗号
                
                for (i in 1..columns.size)
                {
                    for (n in note)
                    {
                        if (columns[i] == n)
                        {
                            columns.replace(n.toString(), "")
                        }
                    }
                }
                params["columns"] = columns
            }
            
            // 识别值列表
            if (valuesIndex + 1 < parse.size) {
                var valuesList = ""
                for (i in (valuesIndex + 1)..parse.size) {
                    valuesList += parse[i] + " "
                }
                // 清理括号和逗号
                for (i in 1..valuesList.size)
                {
                    for (n in note)
                    {
                        if (valuesList[i] == n)
                        {
                            valuesList.replace(n.toString(), "")
                        }
                    }
                }
                
                params["values"] = valuesList
            }
        }
        
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
        params["columns"] = clearMark(columnsStr)
        
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
            params["order_column"] = clearMark(parse[orderByIndex + 2])
            
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