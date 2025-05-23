package CJDataBase

func substring(input: String, start_index: Int64, end_index!: Int64 = input.size)
{
    let sb = StringBuilder()
    for (i in start_index..end_index)
    {
        sb.append(input[i])
    }
    return sb.toString()
}

// 一杯茶，一包烟，一个BUG修一天
func substring_for_unicode(input: String, start_index: Int64, end_index!: Int64 = input.size)
{
    let sb = StringBuilder()
    for (i in start_index..end_index)
    {
        sb.append(String.fromUtf8(input[i]))
    }
    return sb.toString()
}

// 一杯茶，一包烟，一个BUG修一天
func trim_for_13(input: String)
{
    if (input[input.size - 1] == 13)
    {
        return substring_for_unicode(input, 0, end_index: input.size - 1)
    }
    else
    {
        return input
    }
}

//                            _ooOoo_  
//                           o8888888o  
//                           88" . "88  
//                           (| -_- |)  
//                            O\ = /O  
//                        ____/`---'\____  
//                      .   ' \\| |// `.  
//                       / \\||| : |||// \  
//                     / _||||| -:- |||||- \  
//                       | | \\\ - /// | |  
//                     | \_| ''\---/'' | |  
//                      \ .-\__ `-` ___/-. /  
//                   ___`. .' /--.--\ `. . __  
//                ."" '< `.___\_<|>_/___.' >'"".  
//               | | : `- \`.;`\ _ /`;.`/ - ` : | |  
//                 \ \ `-. \_ __\ /__ _/ .-` / /  
//         ======`-.____`-.___\_____/___.-`____.-'======  
//                            `=---='  
//  
//         .............................................  
//                  佛祖保佑             永无BUG 
//          佛曰:  
//                  写字楼里写字间，写字间里程序员；  
//                  程序人员写程序，又拿程序换酒钱。  
//                  酒醒只在网上坐，酒醉还来网下眠；  
//                  酒醉酒醒日复日，网上网下年复年。  
//                  但愿老死电脑间，不愿鞠躬老板前；  
//                  奔驰宝马贵者趣，公交自行程序员。  
//                  别人笑我忒疯癫，我笑自己命太贱；  
//                  不见满街漂亮妹，哪个归得程序员？