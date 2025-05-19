package CJDataBase

import std.argopt.*

var root_dir = "./"
let version = "1.0-alpha"

main(arg: Array<String>): Int64 {

    if (arg.size > 1)
    {
        let shortArgs: Array<String> = arg
        let longArgName: Array<String> = Array<String>(["--root_dir="])
        let ao: ArgOpt = ArgOpt(shortArgs, "", longArgName)
        if (ao.getArg("--root_dir") != None)
        {
            root_dir = ao.getArg("--root_dir").getOrThrow()
        }
    }
    
    InteractiveCommandline(version)

    return 0
}