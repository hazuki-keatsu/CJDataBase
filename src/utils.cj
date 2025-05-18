package CJDataBase

import std.collection.HashMap
import encoding.json.*
import std.collection.ArrayList
import std.unicode.*
import std.convert.*

func substring(input: String, start_index: Int, end_index!: Int = input.size)
{
    let sb = StringBuilder()
    for (i in start_index..end_index)
    {
        sb.append(input[i])
    }
    return sb.toString()
}