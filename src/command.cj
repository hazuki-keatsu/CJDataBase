package CJDataBase

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