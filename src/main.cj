package CJDataBase

import std.console.*
import std.convert.*

// 版本标记
let VERSION = "0.2-alpha"

main(): Int64 {
    init_program()

    var current_database: String = ""
    var db: Database

    while (true) 
    {
        let command = interactive_commandline(current_database)
        
        // 退出
        if (command[0] == QUIT)
        {
            if (current_database.isEmpty())
            {
                break
            }
            else
            {
                current_database = ""
            }
        }
        else
        {
            // 测试命令
            println("COMMAND: " + command[0].toString())
            for ((k, v) in command[1])
            {
                println("Key: ${k}, Value: ${v}")
            }

            // 创建数据库 
            if (command[0] == CREATE_DATABASE)
            {
                create_database(command[1]["database_name"])
            }
            // 进入数据库 
            else if (command[0] == USE)
            {
                if (current_database != "")
                {
                    println("You have entered a database!")
                }
                else
                {
                    current_database = command[1]["database_name"]
                    db = Database(command[1]["database_name"])
                }   
            }
            else if (command[0] == DROP_DATABASE)
            {
                drop_database(command[1]["database_name"])
            }
        }
    }
    return 0
}