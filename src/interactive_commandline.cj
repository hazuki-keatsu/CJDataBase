package CJDataBase

import std.console.*
import std.convert.*
import std.collection.ArrayList
import std.fs.Directory
import std.collection.HashMap
import std.collection.Map
import std.unicode.*

class InteractiveCommandline
{
    static var current_database: String = ""
    let VERSION: String

    public init(version: String) 
    {
        this.VERSION = version
        println("CJSQL version ${VERSION}")
        println("Enter SQL statements terminated with a \";\"\n")
        println("Enter \".help\" for instructions")
        println("Enter \".config\" for config")

        while (true)
        {
            try {
                // 获取命令输入
                let commandInput = get_user_input(current_database)
                
                if (commandInput.isEmpty()) {
                    continue
                }
                
                // 处理特殊命令，如.help
                if (commandInput.startsWith(".")) {
                    handle_dot_commands(commandInput)
                    continue
                }
                
                // 分割多个命令（通过分号分隔）
                let commandList = split_commands(commandInput)
                
                // 依次执行每个命令
                for (cmd in commandList) {
                    if (cmd.trim().isEmpty()) {
                        continue
                    }
                    
                    // 解析单个命令
                    try {
                        let command = command_recognition(cmd)
                        
                        // 执行该命令
                        if (!execute_command(command))
                        {
                            return
                        }
                    
                    } catch (e: Exception) {
                        println("Command parsing error: ${e.message}")
                    }
                }
            } catch (e: Exception) {
                println("Critical error: ${e.message}")
                println("Please check your command syntax and try again.")
            }
        }
    }
    
    // 处理以点开头的特殊命令
    private func handle_dot_commands(command: String) : Unit {
        match (command.trim().toLower()) {
            case ".help" =>
                println("Available commands:")
                println("  1> create database <name>                   - Create a new database")
                println("  2> drop database <name>                     - Delete a database")
                println("  3> use <name>                               - Switch to database")              
                println("  4> create table <name> (<col_type1> <col_name1>, <col_type2> <col_name2>, … )")
                println("                                              - Create a new table")
                println("  5> drop table <name>                        - Delete a table")
                println("  6> info table <name>                        - Show table information")
                println("  7> insert into <table> set <col_name1>=<col_value1>, <col_name2>=<col_value2>, …")
                println("                                              - Insert data into table")
                println("  8> delete from <table> [where condition]    - Delete data from table")
                println("  9> select <col_name1>, <col_name2>, … from <table> [where condition] [order by col_name] [asc/desc]")
                println("                                              - Query data from table")
                println("  10> quit                                    - Exit current database/program")
                println("Multiple commands can be separated with semicolons(;)")
            case ".config" =>
                println("Config:")
                println("  1> Root Directory: ${root_dir}")
                print("Please input the directory you want to store the database:\n> ")
                let input = Console.stdIn.readln()
                if (input != None)
                {
                    root_dir = input.getOrThrow()
                }
            case _ =>
                println("Unknown command: ${command}")
                println("Type .help for available commands")
        }
    }
    
    // 分割多个命令
    private func split_commands(input: String) : ArrayList<String>
    {
        let result = ArrayList<String>()
        
        // 更可靠的方法分割命令
        var currentCommand = ""
        var inQuote = false
        var quoteChar = ' '
        
        for (i in 0..input.size) {
            let currentChar = input[i]
            let charStr = String.fromUtf8(currentChar)
            
            // 处理引号
            if (charStr == "\"" || charStr == "'") {
                if (!inQuote) {
                    inQuote = true
                    quoteChar = charStr[0].toString()
                } else if (charStr[0].toString() == quoteChar) {
                    inQuote = false
                }
                currentCommand += charStr
            }
            // 处理分号
            else if (charStr == ";" && !inQuote) {
                // 添加当前命令到结果
                let trimmedCommand = currentCommand.trim()
                if (!trimmedCommand.isEmpty()) {
                    result.append(trimmedCommand)
                }
                currentCommand = ""
            }
            // 其他字符
            else {
                currentCommand += charStr
            }
        }
        
        // 添加最后一个命令（如果存在）
        let finalCommand = currentCommand.trim()
        if (!finalCommand.isEmpty()) {
            result.append(finalCommand)
        }
        
        return result
    }
    
    // 获取用户输入
    private func get_user_input(current_database: String) : String
    {
        var command_input: String
        do {
            if (current_database == "")
            {
                print("CJSQL> ")
            }
            else
            {
                print("CJSQL - ${current_database}> ")
            }
            
            try {
                command_input = Console.stdIn.readln().getOrThrow()
            } catch (e: Exception) {
                println("Error reading input: ${e.message}")
                return ""
            }
        } while (command_input.isEmpty())
        
        return command_input
    }

    // 执行单个命令
    private func execute_command(command: (COMMAND, Map<String, String>)) : Bool
    {   
        var db: Database
            
        match (command[0]) 
        {
            case QUIT =>
                if (current_database.isEmpty())
                {
                    return false
                }
                else
                {
                    current_database = ""
                    println("Exited database. Type QUIT again to exit program.")
                    return true
                } 
            case CREATE_DATABASE =>
                try {
                    if (!command[1].contains("database_name") || command[1]["database_name"].isEmpty()) {
                        println("Error: Database name is required.")
                    }
                    Database.create_database(command[1]["database_name"])
                    println("Database ${command[1]["database_name"]} created successfully.")
                    return true
                } catch (e: Exception) {
                    println("Failed to create database: ${e.message}")
                    return true
                }
            case USE =>
                if (current_database != "")
                {
                    println("You have already entered database: ${current_database}")
                    println("Type QUIT first to switch databases.")
                    return true
                }
                else
                {
                    try {
                        if (!command[1].contains("database_name") || command[1]["database_name"].isEmpty()) {
                            println("Error: Database name is required.")
                            return true
                        }
                        
                        if (Directory.exists(root_dir + command[1]["database_name"]))
                        {
                            current_database = command[1]["database_name"]
                            println("Successfully switched to database: ${current_database}")
                            return true
                        }
                        else
                        {
                            println("Error: Database '${command[1]["database_name"]}' does not exist.")
                            return true
                        }
                    } catch (e: Exception) {
                        println("Failed to use database: ${e.message}")
                        return true
                    }
                }
            case DROP_DATABASE => 
                try {
                    if (!command[1].contains("database_name") || command[1]["database_name"].isEmpty()) {
                        println("Error: Database name is required.")
                        return true
                    }
                    
                    if (command[1]["database_name"] == current_database) {
                        println("Error: Cannot drop the current database. Exit it first.")
                        return true
                    }
                    
                    if (!Directory.exists(root_dir + command[1]["database_name"])) {
                        println("Error: Database '${command[1]["database_name"]}' does not exist.")
                        return true
                    }
                    
                    Database.drop_database(command[1]["database_name"])
                    println("Database ${command[1]["database_name"]} dropped successfully.")
                    return true
                } catch (e: Exception) {
                    println("Failed to drop database: ${e.message}")
                    return true
                }
            case CREATE_TABLE =>
                if (current_database == "")
                {
                    println("Error: You have not used any database. Use a database first.")
                    return true
                }
                else
                {
                    try {
                        if (!command[1].contains("table_name") || command[1]["table_name"].isEmpty()) {
                            println("Error: Table name is required.")
                            return true
                        }
                        
                        if (!command[1].contains("columns") || !command[1].contains("types")) {
                            println("Error: Columns and types are required.")
                            return true
                        }
                        
                        db = Database(current_database)
                        db.create_table(
                            command[1]["table_name"], 
                            ArrayList<String>(command[1]["columns"].split(" ", removeEmpty: true)), 
                            ArrayList<String>(command[1]["types"].split(" ", removeEmpty: true))
                        )
                        println("Table ${command[1]["table_name"]} created successfully.")
                        return true
                    } catch (e: NoneValueException) {
                        println("Error: Invalid syntax. Missing arguments for table creation.")
                        return true
                    } catch (e: Exception) {
                        println("Failed to create table: ${e.message}")
                        return true
                    }
                }
            case DROP_TABLE =>  
                if (current_database == "")
                {
                    println("Error: You have not used any database. Use a database first.")
                    return true
                }
                else
                {
                    try {
                        if (!command[1].contains("table_name") || command[1]["table_name"].isEmpty()) {
                            println("Error: Table name is required.")
                            return true
                        }
                        
                        db = Database(current_database)
                        db.drop_table(command[1]["table_name"])
                        println("Table ${command[1]["table_name"]} dropped successfully.")
                        return true
                    } catch (e: Exception) {
                        println("Failed to drop table: ${e.message}")
                        return true
                    }
                }
            case INFO_TABLE =>
                if (current_database == "")
                {
                    println("Error: You have not used any database. Use a database first.")
                    return true
                }
                else
                {
                    try {
                        if (!command[1].contains("table_name") || command[1]["table_name"].isEmpty()) {
                            println("Error: Table name is required.")
                            return true
                        }
                        
                        db = Database(current_database)                      
                        db.info_table(command[1]["table_name"])
                        return true
                    } catch (e: Exception) {
                        println("Failed to get table info: ${e.message}")
                        return true
                    }
                }
            case INSERT_INTO =>
                if (current_database == "")
                {
                    println("Error: You have not used any database. Use a database first.")
                    return true
                }
                else
                {
                    try {
                        if (!command[1].contains("table_name") || command[1]["table_name"].isEmpty()) {
                            println("Error: Table name is required.")
                            return true
                        }
                        
                        if (!command[1].contains("keys") || !command[1].contains("values")) {
                            println("Error: Keys and values are required.")
                            return true
                        }
                        
                        db = Database(current_database)                      
                        db.insert(
                            command[1]["table_name"], 
                            ArrayList<String>(command[1]["keys"].split(" ")), 
                            ArrayList<String>(command[1]["values"].split(" "))
                        )
                        println("Data inserted into table ${command[1]["table_name"]} successfully.")
                        return true
                    } catch (e: Exception) {
                        println("Failed to insert data: ${e.message}")
                        return true
                    }
                }
            case DELETE_FROM =>
                if (current_database == "")
                {
                    println("Error: You have not used any database. Use a database first.")
                    return true
                }
                else
                {
                    try {
                        if (!command[1].contains("table_name") || command[1]["table_name"].isEmpty()) {
                            println("Error: Table name is required.")
                            return true
                        }
                        
                        db = Database(current_database)  
                        if (!command[1].contains("condition"))
                        {
                            db.delete(command[1]["table_name"])
                            println("All data deleted from table ${command[1]["table_name"]}.")
                            return true
                        }   
                        else
                        {
                            db.delete(command[1]["table_name"], command[1]["condition"])
                            println("Data matching condition deleted from table ${command[1]["table_name"]}.")
                            return true
                        }
                    } catch (e: Exception) {
                        println("Failed to delete data: ${e.message}")
                        return true
                    }
                }
            case SELECT =>
                if (current_database == "")
                {
                    println("Error: You have not used any database. Use a database first.")
                    return true
                }
                else
                {
                    try {
                        if (!command[1].contains("table_name") || command[1]["table_name"].isEmpty()) {
                            println("Error: Table name is required.")
                            return true
                        }
                        
                        if (!command[1].contains("columns") || command[1]["columns"].isEmpty()) {
                            println("Error: Column selection is required.")
                            return true
                        }
                        
                        db = Database(current_database)
                        
                        // 处理列
                        let columns_str = command[1]["columns"]
                        
                        // 处理条件
                        let condition = if (command[1].contains("condition")) { command[1]["condition"] } else { "" }
                        
                        // 处理排序
                        let order_column = if (command[1].contains("order_column")) { command[1]["order_column"] } else { "" }
                        let order_direction = if (command[1].contains("order_direction")) { command[1]["order_direction"] } else { "asc" }
                        
                        db.select(command[1]["table_name"], columns_str, condition, order_column, order_direction)
                    } catch (e: Exception) {
                        println("Failed to execute SELECT query: ${e.message}")
                        return true
                    }
                }
            case ERR =>
                println("Error: Command syntax is incorrect.")
                return true
        }
    }
}