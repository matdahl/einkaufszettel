import QtQuick 2.7
import QtQuick.LocalStorage 2.0 as Sql
import Qt.labs.settings 1.0

Item {
    id: root

    signal historyChanged()

    property var keyModel: ListModel{}
    property bool hasMarkedKeys:  false
    property bool hasDeletedKeys: false

    onHistoryChanged: {
        keyModel.clear()
        var rows = selectKeys()
        hasMarkedKeys = false
        for (var i=0;i<rows.length;i++){
            keyModel.append(rows[i])
            if (rows[i].marked===1) hasMarkedKeys = true
        }
    }

    Component.onCompleted: init()

    Settings{
        id: settings
        property alias active: root.active
        property alias hasMarkedKeys: root.hasMarkedKeys
        property alias hasDeletedKeys: root.hasDeletedKeys
    }

    // flag that states whether history is enabled or not
    property bool active: true

    property var db

    // connection details
    property string db_name: "history"
    property string db_version: "1.0"
    property string db_description: "database to store entry names of Einkaufszettel app"
    property int    db_size: 1024
    property string db_table_keys: "keys"

    function db_test_callback(db){/* do nothing */}
    function init(){
        // open database
        db = Sql.LocalStorage.openDatabaseSync(db_name,
                                               db_version,
                                               db_description,
                                               db_size,
                                               db_test_callback(db))
        // Create key table if needed
        try{
            db.transaction(function(tx){
                tx.executeSql("CREATE TABLE IF NOT EXISTS "+db_table_keys+" "
                              +"(key TEXT,count INTEGER DEFAULT 1,UNIQUE(key))")
            })
        } catch (err){
            console.error("Error when creating table '"+db_table_keys+"': " + err)
        }

        // check if all necessary columns are in table
        try{
            var colnames = []
            db.transaction(function(tx){
                var rt = tx.executeSql("PRAGMA table_info("+db_table_keys+")")
                for(var i=0;i<rt.rows.length;i++){
                    colnames.push(rt.rows[i].name)
                }
            })
            // since v1.3.2: require marked column
            if (colnames.indexOf("marked")<0){
                db.transaction(function(tx){
                    tx.executeSql("ALTER TABLE "+db_table_keys+" ADD marked INT DEFAULT 0")
                })
            }
            // since v1.3.2: require deleteFlag column
            if (colnames.indexOf("deleteFlag")<0){
                db.transaction(function(tx){
                    tx.executeSql("ALTER TABLE "+db_table_keys+" ADD deleteFlag INT DEFAULT 0")
                })
            }
        } catch (err){
            console.error("Error when checking columns of table '"+db_table_keys+"': " + err)
        }
        historyChanged()
    }

    function addKey(key){
        if (!db) init()
        if (active) {
            try{
                // check if key exists already
                db.transaction(function(tx){
                    var rt = tx.executeSql("SELECT * FROM "+db_table_keys+" WHERE key=?",[key])
                    if (rt.rows.length===0){
                        tx.executeSql("INSERT INTO "+db_table_keys+"(key) VALUES (?)",[key])
                    } else {
                        tx.executeSql("UPDATE "+db_table_keys+" SET count=count+1 WHERE key=?",[key])
                    }
                })
                historyChanged()
            } catch (err){
                console.error("Error when insert key '"+key+"' into table '"+db_table_keys+"': " + err)
            }
        }
    }
    function deleteKey(key){
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("DELETE FROM "+db_table_keys+" WHERE key='"+key+"'")
                historyChanged()
            })
        } catch (err){
            console.error("Error when delete from table '"+db_table_keys+"': " + err)
        }
    }
    function selectKeys(){
        if (!db) init()
        try{
            var rt
            db.transaction(function(tx){
                rt = tx.executeSql("SELECT * FROM "+db_table_keys+" WHERE deleteFlag=0")
            })
            return rt.rows
        } catch (err){
            console.error("Error when select from table '"+db_table_keys+"': " + err)
        }
    }
    function toggleMarked(key){
        try{
            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_keys+" SET marked=1-marked WHERE key=?",[key])
            })
            historyChanged()
        } catch (err){
            console.error("Error when toggleing marked flag of key '"+key+"' in table '"+db_table_keys+"': " + err)
        }
    }

    function markSelectedForDelete(){
        try{
            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_keys+" SET deleteFlag=1,marked=0 WHERE marked=1")
            })
            hasDeletedKeys = true
            historyChanged()
        } catch (err){
            console.error("Error when marking selected keys for delete in table '"+db_table_keys+"': " + err)
        }
    }
    function markAllForDelete(){
        try{
            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_keys+" SET deleteFlag=1")
            })
            hasDeletedKeys = true
            historyChanged()
        } catch (err){
            console.error("Error when marking all keys for delete in table '"+db_table_keys+"': " + err)
        }
    }
    function removeDeleted(){
        try{
            db.transaction(function(tx){
                tx.executeSql("DELETE FROM "+db_table_keys+" WHERE deleteFlag=1")
            })
            hasDeletedKeys = false
        } catch (err){
            console.error("Error when removing deleted keys in table '"+db_table_keys+"': " + err)
        }
    }

    function restore(){
        try{
            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_keys+" SET deleteFlag=0")
            })
            hasDeletedKeys = false
            historyChanged()
        } catch (err){
            console.error("Error when restoring all keys in table '"+db_table_keys+"': " + err)
        }
    }
}


