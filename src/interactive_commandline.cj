package CJDataBase

import std.console.*
import std.convert.*
import std.collection.ArrayList
import std.fs.Directory
import std.collection.HashMap
import std.collection.Map
import std.unicode.*

let root_dir = "./"

class InteractiveCommandline
{
    var current_database: String = ""
    let VERSION: String

    public init(version: String) 
    {
        this.VERSION = version
        println("CJSQL version ${VERSION}")
        println("Enter SQL statements terminated with a \";\"\n")
        println("Enter \".help\" for instructions")

        while (true)
        {
            try {
                // 获取命令输入（可能包含多个命令）
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
                println(commandList)
                
                // 依次执行每个命令
                for (cmd in commandList) {
                    if (cmd.trim().isEmpty()) {
                        continue
                    }
                    
                    // 输出当前执行的命令（便于调试）
                    println("Executing: ${cmd}")
                    
                    // 解析单个命令
                    try {
                        let command = command_recognition(cmd)
                        
                        // 执行该命令
                        execute_command(command)
                        
                        // 对于QUIT命令，提前终止执行剩余命令
                        if (command[0] == QUIT && current_database.isEmpty()) {
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
                println("  CREATE_DATABASE <name>      - Create a new database")
                println("  USE <database>              - Switch to database")
                println("  DROP_DATABASE <name>        - Delete a database")
                println("  CREATE_TABLE <name> <cols>  - Create a new table")
                println("  DROP_TABLE <name>           - Delete a table")
                println("  INFO_TABLE <name>           - Show table information")
                println("  INSERT_INTO <table> ...     - Insert data into table")
                println("  DELETE_FROM <table> ...     - Delete data from table")
                println("  SELECT <cols> FROM <table>  - Query data from table")
                println("  QUIT                        - Exit current database/program")
                println("\nMultiple commands can be separated with semicolons")
            case ".quit" =>
                if (current_database.isEmpty()) {
                    return 
                } else {
                    current_database = ""
                    println("Exited database. Type .quit again to exit program.")
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
        
        // 调试输出
        println("Split commands result:")
        for (i in 0..result.size) {
            println("  Command ${i+1}: ${result[i]}")
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
    private func execute_command(command: (COMMAND, Map<String, String>)) : Unit
    {
        // 输出命令类型和参数（调试）
        println("Command type: ${command[0].toString()}")
        println("Command params:")
        for ((k, v) in command[1])
        {
            println("Key: ${k}; Value: ${v}")
        }
        
        var db: Database
            
        match (command[0]) 
        {
            case QUIT =>
                if (current_database.isEmpty())
                {
                    return
                }
                else
                {
                    current_database = ""
                    println("Exited database. Type QUIT again to exit program.")
                } 
            case CREATE_DATABASE =>
                try {
                    if (!command[1].contains("database_name") || command[1]["database_name"].isEmpty()) {
                        println("Error: Database name is required.")
                        return
                    }
                    Database.create_database(command[1]["database_name"])
                    println("Database ${command[1]["database_name"]} created successfully.")
                } catch (e: Exception) {
                    println("Failed to create database: ${e.message}")
                }
            case USE =>
                if (current_database != "")
                {
                    println("You have already entered database: ${current_database}")
                    println("Type QUIT first to switch databases.")
                }
                else
                {
                    try {
                        if (!command[1].contains("database_name") || command[1]["database_name"].isEmpty()) {
                            println("Error: Database name is required.")
                            return
                        }
                        
                        if (Directory.exists(root_dir + command[1]["database_name"]))
                        {
                            current_database = command[1]["database_name"]
                            println("Successfully switched to database: ${current_database}")
                        }
                        else
                        {
                            println("Error: Database '${command[1]["database_name"]}' does not exist.")
                        }
                    } catch (e: Exception) {
                        println("Failed to use database: ${e.message}")
                    }
                }
            case DROP_DATABASE => 
                try {
                    if (!command[1].contains("database_name") || command[1]["database_name"].isEmpty()) {
                        println("Error: Database name is required.")
                        return
                    }
                    
                    if (command[1]["database_name"] == current_database) {
                        println("Error: Cannot drop the current database. Exit it first.")
                        return
                    }
                    
                    if (!Directory.exists(root_dir + command[1]["database_name"])) {
                        println("Error: Database '${command[1]["database_name"]}' does not exist.")
                        return
                    }
                    
                    Database.drop_database(command[1]["database_name"])
                    println("Database ${command[1]["database_name"]} dropped successfully.")
                } catch (e: Exception) {
                    println("Failed to drop database: ${e.message}")
                }
            case CREATE_TABLE =>
                if (current_database == "")
                {
                    println("Error: You have not used any database. Use a database first.")
                }
                else
                {
                    try {
                        if (!command[1].contains("table_name") || command[1]["table_name"].isEmpty()) {
                            println("Error: Table name is required.")
                            return
                        }
                        
                        if (!command[1].contains("columns") || !command[1].contains("types")) {
                            println("Error: Columns and types are required.")
                            return
                        }
                        
                        db = Database(current_database)
                        db.create_table(
                            command[1]["table_name"], 
                            ArrayList<String>(command[1]["columns"].split(" ", removeEmpty: true)), 
                            ArrayList<String>(command[1]["types"].split(" ", removeEmpty: true))
                        )
                        println("Table ${command[1]["table_name"]} created successfully.")
                    } catch (e: NoneValueException) {
                        println("Error: Invalid syntax. Missing arguments for table creation.")
                    } catch (e: Exception) {
                        println("Failed to create table: ${e.message}")
                    }
                }
            case DROP_TABLE =>  
                if (current_database == "")
                {
                    println("Error: You have not used any database. Use a database first.")
                }
                else
                {
                    try {
                        if (!command[1].contains("table_name") || command[1]["table_name"].isEmpty()) {
                            println("Error: Table name is required.")
                            return
                        }
                        
                        db = Database(current_database)
                        db.drop_table(command[1]["table_name"])
                        println("Table ${command[1]["table_name"]} dropped successfully.")
                    } catch (e: Exception) {
                        println("Failed to drop table: ${e.message}")
                    }
                }
            case INFO_TABLE =>
                if (current_database == "")
                {
                    println("Error: You have not used any database. Use a database first.")
                }
                else
                {
                    try {
                        if (!command[1].contains("table_name") || command[1]["table_name"].isEmpty()) {
                            println("Error: Table name is required.")
                            return
                        }
                        
                        db = Database(current_database)                      
                        db.info_table(command[1]["table_name"])
                    } catch (e: Exception) {
                        println("Failed to get table info: ${e.message}")
                    }
                }
            case INSERT_INTO =>
                if (current_database == "")
                {
                    println("Error: You have not used any database. Use a database first.")
                }
                else
                {
                    try {
                        if (!command[1].contains("table_name") || command[1]["table_name"].isEmpty()) {
                            println("Error: Table name is required.")
                            return
                        }
                        
                        if (!command[1].contains("keys") || !command[1].contains("values")) {
                            println("Error: Keys and values are required.")
                            return
                        }
                        
                        db = Database(current_database)                      
                        db.insert(
                            command[1]["table_name"], 
                            ArrayList<String>(command[1]["keys"].split(" ")), 
                            ArrayList<String>(command[1]["values"].split(" "))
                        )
                        println("Data inserted into table ${command[1]["table_name"]} successfully.")
                    } catch (e: Exception) {
                        println("Failed to insert data: ${e.message}")
                    }
                }
            case DELETE_FROM =>
                if (current_database == "")
                {
                    println("Error: You have not used any database. Use a database first.")
                }
                else
                {
                    try {
                        if (!command[1].contains("table_name") || command[1]["table_name"].isEmpty()) {
                            println("Error: Table name is required.")
                            return
                        }
                        
                        db = Database(current_database)  
                        if (!command[1].contains("condition"))
                        {
                            db.delete(command[1]["table_name"])
                            println("All data deleted from table ${command[1]["table_name"]}.")
                        }   
                        else
                        {
                            db.delete(command[1]["table_name"], command[1]["condition"])
                            println("Data matching condition deleted from table ${command[1]["table_name"]}.")
                        }
                    } catch (e: Exception) {
                        println("Failed to delete data: ${e.message}")
                    }
                }
            case SELECT =>
                if (current_database == "")
                {
                    println("Error: You have not used any database. Use a database first.")
                }
                else
                {
                    try {
                        if (!command[1].contains("table_name") || command[1]["table_name"].isEmpty()) {
                            println("Error: Table name is required.")
                            return
                        }
                        
                        if (!command[1].contains("columns") || command[1]["columns"].isEmpty()) {
                            println("Error: Column selection is required.")
                            return
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
                    }
                }
            case ERR =>
                println("Error: Command syntax is incorrect.")
        }
    }
}