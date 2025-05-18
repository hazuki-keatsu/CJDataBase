package CJDataBase

import serialization.serialization.*
import encoding.json.*

class DatabaseMeta <: Serializable<DatabaseMeta> {
    public DatabaseMeta(
        public var MagicName: String,
        public var DatabaseName: String,
        public var TableCount: UInt64,
        public var TableName: Array<String>
    ) {}

    public func serialize(): DataModel {
        DataModelStruct()
            .add(field<String>("MagicName", MagicName))
            .add(field<String>("DatabaseName", DatabaseName))
            .add(field<UInt64>("TableCount", TableCount))
            .add(field<Array<String>>("TableName", TableName))
    }

    public static func deserialize(dm: DataModel): DatabaseMeta {
        let dms = match (dm) {
            case d: DataModelStruct => d
            case _ => throw Exception("this data is not DataModelStruct")
        }
        DatabaseMeta(
            String.deserialize(dms.get("MagicName")),
            String.deserialize(dms.get("DatabaseName")),
            UInt64.deserialize(dms.get("TableCount")),
            Array<String>.deserialize(dms.get("TableName"))
        )
    }

    public func append(tableName: String)
    {
        let newSize = this.TableName.size + 1
        let newTableNames = Array<String>(newSize, item: "")
        
        for (i in 0..this.TableName.size)
        {
            newTableNames[i] = this.TableName[i]
        }
        
        newTableNames[this.TableName.size] = tableName
        
        this.TableName = newTableNames
        
        this.TableCount++
    }

    public func remove(tableName: String) : Bool
    {
        // 寻找要删除的表名的索引
        var indexToRemove = -1
        for (i in 0..this.TableName.size)
        {
            if (this.TableName[i] == tableName)
            {
                indexToRemove = i
                break
            }
        }
        
        // 如果没找到，返回false
        if (indexToRemove == -1)
        {
            return false
        }
        
        // 创建新的更小的数组
        let newSize = this.TableName.size - 1
        let newTableNames = Array<String>(newSize, item: "")
        
        // 复制除了要删除的元素之外的所有元素
        var newIndex = 0
        for (i in 0..this.TableName.size)
        {
            if (i != indexToRemove)
            {
                newTableNames[newIndex] = this.TableName[i]
                newIndex++
            }
        }
        
        // 更新TableName引用
        this.TableName = newTableNames
        
        // 减少表计数
        this.TableCount--
        
        return true
    }
}

public class TableMeta <: Serializable<TableMeta> {
    public TableMeta(
        public var TableName: String,
        public var RowCount: UInt64,
        public var ColumnCount: UInt64,
        public var TableColumnInfo: Array<Array<String>>
    ) {}
    public func serialize(): DataModel {
        DataModelStruct()
            .add(field<String>("TableName", TableName))
            .add(field<UInt64>("RowCount", RowCount))
            .add(field<UInt64>("ColumnCount", ColumnCount))
            .add(field<Array<Array<String>>>("TableColumnInfo", TableColumnInfo))
    }
    public static func deserialize(dm: DataModel): TableMeta {
        let dms = match (dm) {
            case d: DataModelStruct => d
            case _ => throw Exception("this data is not DataModelStruct")
        }
        TableMeta(
            String.deserialize(dms.get("TableName")),
            UInt64.deserialize(dms.get("RowCount")),
            UInt64.deserialize(dms.get("ColumnCount")),
            Array<Array<String>>.deserialize(dms.get("TableColumnInfo"))
        )
    }

    public func append(columnName: String, columnType: String)
    {
        // 创建新数组以增加容量
        let newSize = this.TableColumnInfo.size + 1
        let newTableColumnInfo = Array<Array<String>>(newSize, item: Array<String>())
        
        // 复制现有列信息
        for (i in 0..this.TableColumnInfo.size)
        {
            newTableColumnInfo[i] = this.TableColumnInfo[i]
        }
        
        // 创建新列的信息数组
        let newColumn = Array<String>(2, item: "")
        newColumn[0] = columnName
        newColumn[1] = columnType
        
        // 添加新列信息
        newTableColumnInfo[this.TableColumnInfo.size] = newColumn
        
        // 更新TableColumnInfo引用
        this.TableColumnInfo = newTableColumnInfo
        
        // 增加列计数
        this.ColumnCount++
    }

    public func remove(columnName: String) : Bool
    {
        // 寻找要删除的列名的索引
        var indexToRemove = -1
        for (i in 0..this.TableColumnInfo.size)
        {
            if (this.TableColumnInfo[i].size > 0 && this.TableColumnInfo[i][0] == columnName)
            {
                indexToRemove = i
                break
            }
        }
        
        // 如果没找到，返回false
        if (indexToRemove == -1)
        {
            return false
        }
        
        // 创建新的更小的数组
        let newSize = this.TableColumnInfo.size - 1
        let newTableColumnInfo = Array<Array<String>>(newSize, item: Array<String>())
        
        // 复制除了要删除的元素之外的所有元素
        var newIndex = 0
        for (i in 0..this.TableColumnInfo.size)
        {
            if (i != indexToRemove)
            {
                newTableColumnInfo[newIndex] = this.TableColumnInfo[i]
                newIndex++
            }
        }
        
        // 更新TableColumnInfo引用
        this.TableColumnInfo = newTableColumnInfo
        
        // 减少列计数
        this.ColumnCount--
        
        return true
    }
}

public class IndexData <: Serializable<IndexData> {
    public IndexData(
        public var index_file: UInt64,
        public var data_file: Array<Array<Data_file>>
    ) {}
    public func serialize(): DataModel {
        DataModelStruct()
            .add(field<UInt64>("index_file", index_file))
            .add(field<Array<Array<Data_file>>>("data_file", data_file))
    }
    public static func deserialize(dm: DataModel): IndexData {
        let dms = match (dm) {
            case d: DataModelStruct => d
            case _ => throw Exception("this data is not DataModelStruct")
        }
        IndexData(
            UInt64.deserialize(dms.get("index_file")),
            Array<Array<Data_file>>.deserialize(dms.get("data_file"))
        )
    }
}

public class Data_file <: Serializable<Data_file> {
    public Data_file(
        public var data: String,
        public var index: UInt64
    ) {}
    public func serialize(): DataModel {
        DataModelStruct()
            .add(field<String>("data", data))
            .add(field<UInt64>("index", index))
    }
    public static func deserialize(dm: DataModel): Data_file {
        let dms = match (dm) {
            case d: DataModelStruct => d
            case _ => throw Exception("this data is not DataModelStruct")
        }
        Data_file(
            String.deserialize(dms.get("data")),
            UInt64.deserialize(dms.get("index"))
        )
    }
}

// func parse() {
//     let jv = JsonValue.fromStr("""
//         {"MagicName":"CJDB","DatabaseName":"db","TableCount":1,"TableName":["user"]}
//     """)
//     let dm = DataModel.fromJson(jv)
//     let r = DatabaseMeta.deserialize(dm)
//     let newDm = r.serialize()
//     println(newDm.toJson().toJsonString())
// }
