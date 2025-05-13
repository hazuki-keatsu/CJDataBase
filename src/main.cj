package CJDataBase

import std.console.*
import std.convert.*

// 版本标记
let VERSION = "0.1-alpha"

main(): Int64 {
    init_program()

    var current_database: String = ""

    while (true) 
    {
        let command = interactive_commandline(current_database)
        if (command[0] == QUIT)
        {
            break
        }
        else
        {
            println("COMMAND: " + command[0].toString())
            for ((k, v) in command[1])
            {
                println("Key: ${k}, Value: ${v}")
            }
        }
    }
    return 0
}