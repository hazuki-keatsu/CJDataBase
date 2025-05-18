package CJDataBase

import std.console.*
import std.convert.*
import std.collection.ArrayList
import std.fs.Directory

let root_dir = "./"

class InteractiveCommandline
{
    var current_database: String = ""
    let VERSION: String

    public init(version: String) 
    {
        this.VERSION = version
        println("CJSQL version ${VERSION}")
        println("Enter \".help\" for instructions")
        println("Enter SQL statements terminated with a \";\"\n")

        while (true)
        {
            let command = interactive_commandline(current_database)
            var db: Database

            // 测试命令
            println("COMMAND: " + command[0].toString())
            for ((k, v) in command[1])
            {
                println("Key: ${k}, Value: ${v}")
            }

            match (command[0]) 
            {
                case QUIT =>
                    if (current_database.isEmpty())
                    {
                        break
                    }
                    else
                    {
                        current_database = ""
                    } 
                case CREATE_DATABASE =>
                    Database.create_database(command[1]["database_name"])
                case USE =>
                    if (current_database != "")
                    {
                        println("You have entered a database!")
                    }
                    else
                    {
                        if (Directory.exists(root_dir + command[1]["database_name"]))
                        {
                            current_database = command[1]["database_name"]
                        }
                        else
                        {
                            println("No such database.")
                        }
                    }
                case DROP_DATABASE => 
                    Database.drop_database(command[1]["database_name"])
                case CREATE_TABLE =>
                    if (current_database == "")
                    {
                        println("You have not used any database.")
                    }
                    else
                    {
                        db = Database(current_database)
                        try {
                            db.create_table(command[1]["table_name"], ArrayList<String>(command[1]["columns"].split(" ", removeEmpty: true)), ArrayList<String>(command[1]["types"].split(" ", removeEmpty: true)))
                        }
                        catch (e: NoneValueException) {
                            println("You seem to input less args.")
                            continue
                        }
                    }
                case DROP_TABLE =>  
                    if (current_database == "")
                    {
                        println("You have not used any database.")
                    }
                    else
                    {
                        db = Database(current_database)
                        db.drop_table(command[1]["table_name"])
                    }
                case INFO_TABLE =>
                    if (current_database == "")
                    {
                        println("You have not used any database.")
                    }
                    else
                    {
                        db = Database(current_database)                      
                        db.info_table(command[1]["table_name"])
                    }
                case INSERT_INTO =>
                    if (current_database == "")
                    {
                        println("You have not used any database.")
                    }
                    else
                    {
                        db = Database(current_database)                      
                        db.insert(command[1]["table_name"], ArrayList<String>(command[1]["keys"].split(" ")), ArrayList<String>(command[1]["values"].split(" ")))
                    }
                case DELETE_FROM =>
                    if (current_database == "")
                    {
                        println("You have not used any database.")
                    }
                    else
                    {
                        db = Database(current_database)  
                        if (!command[1].contains("condition"))
                        {
                            db.delete(command[1]["table_name"])
                        }   
                        else
                        {
                            db.delete(command[1]["table_name"], command[1]["condition"])
                        }
                    }
                case SELECT =>
                    println("un")
                case ERR =>
                    println("Something went wrong. :(")
            }
        }
    }

    // 交互式命令环境
    private func interactive_commandline(current_database: String)
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
            
            command_input = Console.stdIn.readln().getOrThrow()
        } while (command_input.isEmpty())

        return command_recognition(command_input)
    }
}