package CJDataBase

import std.console.*
import std.collection.*
import std.fs.*

// 初始化工作
func init_program ()
{
    println("CJSQL version ${VERSION}")
    println("Enter \".help\" for instructions")
    println("Enter SQL statements terminated with a \";\"\n")
}

// 交互式命令环境
func interactive_commandline(current_database: String)
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
            else
            {
                return v
            }
            break
        }
    }
    return ""
}