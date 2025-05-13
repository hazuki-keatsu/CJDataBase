package CJDataBase

import std.console.*

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

// 导出数据库
func export()
{

}

// 导入数据库
func register()
{

}

func clearMark(input: String): String {
    var input_ascii = input.trimAscii()

    let builder = StringBuilder()
    // 移除开头和结尾的常见标点符号
    if (input_ascii.startsWith(",") || input_ascii.startsWith(";") || input_ascii.startsWith("(") || 
        input_ascii.startsWith(")") || input_ascii.startsWith("\"") || input_ascii.startsWith("'")) 
    {
        for (i in 1..(input_ascii.size - 1))
        {   
            builder.append(input_ascii[i])
        }
    }
    if (input_ascii.endsWith(",") || input_ascii.endsWith(";") || input_ascii.endsWith(")") || 
        input_ascii.endsWith("(") || input_ascii.endsWith("\"") || input_ascii.endsWith("'")) 
    {
        return builder.toString()
    }
    else
    {
        builder.append(input_ascii[input_ascii.size - 1])
        return builder.toString()
    }
}