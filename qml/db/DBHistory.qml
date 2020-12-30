import QtQuick 2.7
import QtQuick.LocalStorage 2.0 as Sql
import Qt.labs.settings 1.0

Item {
    id: root

    Settings{
        id: settings

        property alias active: root.active
        property alias deleteFlag: root.deleteFlag
    }

    // flag that states whether history is enabled or not
    property bool active: true

    // if true, all of the history is marked to be deleted in a reversible way
    property bool deleteFlag: false

    property var db

    signal keysChanged()

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
        // delete history if needed
        if (deleteFlag) deleteAllKeys()
    }

    function addKey(key){
        if (!db) init()
        if (deleteFlag) deleteAllKeys()
        if (active) {
            try{
                db.transaction(function(tx){
                    tx.executeSql("INSERT OR IGNORE INTO "+db_table_keys+"(key) VALUES ('"+key+"')")// ON CONFLICT(key) DO UPDATE SET count=count+1")
                    /*
                    tx.executeSql("IIF (EXISTS(SELECT * FROM "+db_table_keys+" WHERE key='"+key+"'),"
                                 // THEN: update
                                 +"UPDATE "+db_table_keys+" SET count = count+1 WHERE key='"+key+"',"
                                 // ELSE: insert
                                 +"INSERT INTO "+db_table_keys+" (key,count) VALUES('"+key+"',1))")*/
                })
                keysChanged()
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
                keysChanged()
            })
        } catch (err){
            console.error("Error when delete from table '"+db_table_keys+"': " + err)
        }
    }
    function deleteAllKeys(){
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("DELETE FROM "+db_table_keys)
            })
            deleteFlag = false
        } catch (err){
            console.error("Error when delete all from table '"+db_table_keys+"': " + err)
        }
    }
    function selectKeys(){
        if (!db) init()
        if (!deleteFlag) {
            try{
                var rt
                db.transaction(function(tx){
                    rt = tx.executeSql("SELECT * FROM "+db_table_keys)
                })
                return rt.rows
            } catch (err){
                console.error("Error when select from table '"+db_table_keys+"': " + err)
            }
        }
    }

    function markAllForDelete(){
        deleteFlag = true
        keysChanged()
    }
    function restore(){
        deleteFlag = false
        keysChanged()
    }

    Component.onDestruction: if (deleteFlag) deleteAllKeys()
}


