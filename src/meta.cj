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
