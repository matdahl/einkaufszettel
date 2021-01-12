/*
 * This component manages the units which can be used to measure quantities of entries
 */

import QtQuick 2.7
import QtQuick.LocalStorage 2.0 as Sql
//import Qt.labs.settings 1.0

Item {
    id: root

    signal unitsChanged()

    onUnitsChanged: {
        unitsModel.clear()
        var rows = select()
        for (var i=0;i<rows.length;i++){
            unitsModel.append(rows[i])
        }
    }

    // the connector with the database
    property var db

    property var unitsModel: ListModel{}

    // connection details
    property string db_name: "units"
    property string db_version: "1.0"
    property string db_description: "database to store units"
    property int    db_size: 128
    property string db_table_units: "units"

    function db_test_callback(db){/* do nothing */}
    function init(){
        if (!db){
            // open database
            db = Sql.LocalStorage.openDatabaseSync(db_name,
                                                   db_version,
                                                   db_description,
                                                   db_size,
                                                   db_test_callback(db))
            /*db.transaction(function(tx){
                tx.executeSql("DROP TABLE "+db_table_units)
            })*/
            // Create key table if needed
            try{
                db.transaction(function(tx){
                    tx.executeSql("CREATE TABLE IF NOT EXISTS "+db_table_units+" "
                                  +"(uid INTEGER PRIMARY KEY AUTOINCREMENT, symbol TEXT, name TEXT, UNIQUE(symbol))")
                })
            } catch (err){
                console.error("Error when creating table '"+db_table_units+"': " + err)
            }
            // check if all necessary columns are in table
            try{
                var colnames = []
                db.transaction(function(tx){
                    var rt = tx.executeSql("PRAGMA table_info("+db_table_units+")")
                    for(var i=0;i<rt.rows.length;i++){
                        colnames.push(rt.rows[i].name)
                    }
                })
                // since v1.3.2: require marked column
                if (colnames.indexOf("marked")<0){
                    db.transaction(function(tx){
                        tx.executeSql("ALTER TABLE "+db_table_units+" ADD marked INT DEFAULT 0")
                    })
                }
            } catch (err){
                console.error("Error when checking columns of table '"+db_table_units+"': " + err)
            }
            // insert standard units
            if (select().length===0){
                add("x",i18n.tr("Piece"))
                add("g",i18n.tr("Gram"))
                add("kg",i18n.tr("Kilogram"))
                add("l",i18n.tr("Liter"))
            }
            unitsChanged()
        }
    }

    function add(symbol,name){
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("INSERT OR IGNORE INTO "+db_table_units+"(symbol,name) VALUES ('"+symbol+"','"+name+"')")
            })
            unitsChanged()
        } catch (err){
            console.error("Error when insert unit '"+name+" ("+symbol+")' into table '"+db_table_units+"': " + err)
        }
    }
    function remove(uid){
        if (!db) init()
        // make sure to not delete the fundamental unit 'piece'
        if (uid!==0){
            try{
                db.transaction(function(tx){
                    tx.executeSql("DELETE FROM "+db_table_units+" WHERE uid="+uid)
                    unitsChanged()
                })
            } catch (err){
                console.error("Error when delete from table '"+db_table_units+"': " + err)
            }
        }
    }
    function select(){
        if (!db) init()
        try{
            var rt
            db.transaction(function(tx){
                rt = tx.executeSql("SELECT * FROM "+db_table_units)
            })
            return rt.rows
        } catch (err){
            console.error("Error when select from table '"+db_table_units+"': " + err)
        }
    }
    function swap(uid1,uid2){
        if (!db) init()
        try{
            db.transaction(function(tx){
                var tempuid = -1
                tx.executeSql("UPDATE "+db_table_units+" SET uid=? WHERE uid=?",[tempuid,uid1])
                tx.executeSql("UPDATE "+db_table_units+" SET uid=? WHERE uid=?",[uid1,uid2])
                tx.executeSql("UPDATE "+db_table_units+" SET uid=? WHERE uid=?",[uid2,tempuid])
            })
        } catch (err){
            console.error("Error when swaping units in table '"+db_table_units+"': " + err)
        }
    }
    function toggleMarked(uid){
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_units+" SET marked=1-marked WHERE uid='"+uid+"'")
            })
        } catch (err){
            console.error("Error when toggle marked property of uid="+uid+" in table '"+db_table_units+"': " + err)
        }
    }

}
