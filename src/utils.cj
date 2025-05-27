package CJDataBase

func substring(input: String, start_index: Int64, end_index!: Int64 = input.size) {
    let sb = StringBuilder()
    for (i in start_index..end_index) {
        sb.append(input[i])
    }
    return sb.toString()
}

func substring_for_unicode(input: String, start_index: Int64, end_index!: Int64 = input.size) {
    let sb = StringBuilder()
    for (i in start_index..end_index) {
        sb.append(String.fromUtf8(input[i]))
    }
    return sb.toString()
}

func trim_for_13(input: String) {
    if (input[input.size - 1] == 13) {
        return substring_for_unicode(input, 0, end_index: input.size - 1)
    } else {
        return input
    }
}
