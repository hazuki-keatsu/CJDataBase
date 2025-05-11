package CJDataBase

import std.console.*
import std.convert.*

// 版本标记
let VERSION = "0.1-alpha"

// 初始化工作
func init_program ()
{
    println("CJSQL version ${VERSION}")
    println("Enter \".help\" for instructions")
    println("Enter SQL statements terminated with a \";\"\n")
}

// 交互式命令环境
func interactive_commandline() : (COMMAND, String)
{
    var command_input: String
    do {
        print("CJSQL> ")
        command_input = Console.stdIn.readln().getOrThrow()
    } while (command_input.isEmpty())

    // 命令识别
    if (command_input.contains("create database "))
    {
        var name = command_input.replace("create database ", "")
        return (CREATE_DATABASE, name)
    }
    else if (command_input.contains("drop database "))
    {
        var name = command_input.replace("drop database ", "")
        return (DROP_DATABASE, name)
    }
    else if (command_input.contains("use "))
    {
        var name = command_input.replace("use ", "")
        return (USE, name)
    }

    else if (command_input.contains("quit"))
    {
        return (QUIT, "")
    }
    else
    {
        return (ERR, "")
    }

}

main(): Int64 {
    init_program()

    while (true) 
    {
        let command = interactive_commandline()
        if (command[0] == QUIT)
        {
            break
        }
        else
        {
            println("COMMAND: " + command[0].toString() + " NAME: " + command[1])
        }
    }
    return 0
}