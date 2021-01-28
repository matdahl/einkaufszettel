import QtQuick 2.7
import QtQuick.LocalStorage 2.0 as Sql
import Qt.labs.settings 1.0
import Ubuntu.Components 1.3

Item {
    id: root

    // this signal is emitted when a key or the count of a key was changed and all models are refreshed
    signal historyChanged()

    function refreshHistory(){
        rawModel.clear()
        var rows = selectKeys()

        // read all keys into unsorted rawModel
        for (var i=0;i<rows.length;i++){
            rawModel.append(rows[i])
        }
        sortedKeyModel.model = rawModel
        checkForMarkedEntries()
        historyChanged()
    }

    function checkForMarkedEntries(){
        hasMarkedKeys = false
        for (var i=0; i<sortedKeyModel.count;i++){
            if (sortedKeyModel.get(i).marked===1) {
                hasMarkedKeys = true
                break
            }
        }
    }

    ListModel{
        id: rawModel
    }

    property var sortedKeyModel: SortFilterModel{
                                    model: rawModel
                                    sort.property: "key"
                                    sort.order: Qt.AscendingOrder
    }


    Component.onCompleted: init()

    Settings{
        id: settings
        property alias active: root.active
        property alias acceptOnClick: root.acceptOnClick
        property alias hasMarkedKeys: root.hasMarkedKeys
        property alias hasDeletedKeys: root.hasDeletedKeys
    }

    // flag that states whether history is enabled or not
    property bool active: true

    // flag whether entries are created when clicking on suggestion
    property bool acceptOnClick: false

    property bool hasMarkedKeys:  false
    property bool hasDeletedKeys: false


    // connection details
    property var db
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
        refreshHistory()
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
                refreshHistory()
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
                refreshHistory()
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
        if (!db) init()
        try{
            // toggle in DB
            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_keys+" SET marked=1-marked WHERE key=?",[key])
            })
            // toggle in model
            for (var i=0;i<rawModel.count;i++){
                if (rawModel.get(i).key===key){
                    rawModel.get(i).marked = 1 - rawModel.get(i).marked
                    break
                }
            }
            checkForMarkedEntries()
            historyChanged()
        } catch (err){
            console.error("Error when toggleing marked flag of key '"+key+"' in table '"+db_table_keys+"': " + err)
        }
    }
    function deselectAll(){
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_keys+" SET marked=0")
            })
            refreshHistory()
        } catch (err){
            console.error("Error when deselect all keys in table '"+db_table_keys+"': " + err)
        }
    }

    function markSelectedForDelete(){
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_keys+" SET deleteFlag=1,marked=0 WHERE marked=1")
            })
            hasDeletedKeys = true
            refreshHistory()
        } catch (err){
            console.error("Error when marking selected keys for delete in table '"+db_table_keys+"': " + err)
        }
    }
    function markAllForDelete(){
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_keys+" SET deleteFlag=1")
            })
            hasDeletedKeys = true
            refreshHistory()
        } catch (err){
            console.error("Error when marking all keys for delete in table '"+db_table_keys+"': " + err)
        }
    }
    function removeDeleted(){
        if (!db) init()
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
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_keys+" SET deleteFlag=0")
            })
            hasDeletedKeys = false
            refreshHistory()
        } catch (err){
            console.error("Error when restoring all keys in table '"+db_table_keys+"': " + err)
        }
    }
}


