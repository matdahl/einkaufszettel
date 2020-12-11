import QtQuick 2.7
import QtQuick.LocalStorage 2.0 as Sql

Item {
    id: root

    property var db

    // flag to state whether there are restorable deleted items
    property bool hasDeletedEntries: false

    // connection details
    property string db_name: "einkauf"
    property string db_version: "1.0"
    property string db_description: "DB of Einkaufszettel app"
    property int    db_size: 1024
    property string db_table_categories: "categories"
    property string db_table_items:      "items"

    function db_test_callback(db){/* do nothing */}
    function init(){
        // open database
        db = Sql.LocalStorage.openDatabaseSync(db_name,
                                               db_version,
                                               db_description,
                                               db_size,
                                               db_test_callback(db))
        // create tables if not exist
        try{
            db.transaction(function(tx){
                tx.executeSql("CREATE TABLE IF NOT EXISTS "+db_table_categories+" "
                              +"(name TEXT,UNIQUE(name))")
            })
        } catch (err){
            console.error("Error when creating table '"+db_table_categories+"': " + err)
        }
        try{
            db.transaction(function(tx){
                tx.executeSql("CREATE TABLE IF NOT EXISTS "+db_table_items+" "
                              +"(uid INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, category)")
            })
        } catch (err){
            console.error("Error when creating table '"+db_table_items+"': " + err)
        }
        // check if all required colunms are in table and create missing ones
        try{
            var colnames = []
            db.transaction(function(tx){
                var rt = tx.executeSql("PRAGMA table_info("+db_table_items+")")
                for(var i=0;i<rt.rows.length;i++){
                    colnames.push(rt.rows[i].name)
                }
            })
            // since v1.0.2: require deleteFlag column
            if (colnames.indexOf("deleteFlag")<0){
                db.transaction(function(tx){
                    tx.executeSql("ALTER TABLE "+db_table_items+" ADD deleteFlag INTEGER DEFAULT 0")
                })
            }
        } catch (err){
            console.error("Error when checking columns of table '"+db_table_items+"': " + err)
        }
        // if there are still deleted items left, remove them form DB for a clean start
        removeDeleted()
    }

    function insertCategory(name){
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("INSERT OR IGNORE INTO "+db_table_categories+" VALUES"
                              +"('"+name+"')")
            })
        } catch (err){
            console.error("Error when insert into table '"+db_table_categories+"': " + err)
        }
    }
    function deleteCategory(name){
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("DELETE FROM "+db_table_categories+" WHERE name='"+name+"'")
            })
        } catch (err){
            console.error("Error when delete from table '"+db_table_categories+"': " + err)
        }
    }
    function selectCategories(){
        if (!db) init()
        try{
            var rt
            db.transaction(function(tx){
                rt = tx.executeSql("SELECT * FROM "+db_table_categories)
            })
            return rt.rows
        } catch (err){
            console.error("Error when select from table '"+db_table_categories+"': " + err)
        }
    }

    function insertItem(name,category){
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("INSERT INTO "+db_table_items+" VALUES"
                              +"(NULL,'"+name+"','"+category+"',0)")
            })
        } catch (err){
            console.error("Error when insert into table '"+db_table_items+"': " + err)
        }
    }
    function deleteItem(uid){
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("DELETE FROM "+db_table_items+" WHERE uid='"+uid+"'")
            })
        } catch (err){
            console.error("Error when delete from table '"+db_table_items+"': " + err)
        }
    }
    function selectItems(category){
        if (!db) init()
        try{
            var cmd = "SELECT * FROM "+db_table_items +" WHERE (deleteFlag<>1"
            if (category!=="") cmd += " AND category='"+category+"'"
            cmd += ")"
            var rt
            db.transaction(function(tx){
                rt = tx.executeSql(cmd)
            })
            return rt.rows
        } catch (err){
            console.error("Error when select from table '"+db_table_items+"': " + err)
        }
    }

    /* marks an entry as deleted such that it is not listed anymore but still can be restored */
    function markAsDeleted(uid){
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_items+" SET deleteFlag=1 WHERE uid='"+uid+"'")
            })
            hasDeletedEntries = true
        } catch (err){
            console.error("Error when marking entry as deleted in table '"+db_table_items+"': " + err)
        }

    }

    /* finally remove all entries which are labeled as deleted from database */
    function removeDeleted(){
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("DELETE FROM "+db_table_items+" WHERE deleteFlag=1")
            })
            hasDeletedEntries = false
        } catch (err){
            console.error("Error when remove deleted from table '"+db_table_items+"': " + err)
        }
    }

    /* restore all entries which are labeled as deleted in database */
    function restoreDeleted(){
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_items+" SET deleteFlag=0 WHERE deleteFlag=1")
            })
            hasDeletedEntries = false
        } catch (err){
            console.error("Error when restoring deleted entries in table '"+db_table_items+"': " + err)
        }
    }

    function countEntriesPerCategory(categorylist){
        // get list of all categories
        if (!db) init()
        try{
            var rt
            db.transaction(function(tx){
                rt = tx.executeSql("SELECT category FROM "+db_table_items+" WHERE deleteFlag=0")
            })
            var counts = []
            for (var i=0;i<categorylist.length+1;i++) counts.push(0)
            // go through each DB entry
            for (var i=0; i<rt.rows.length;i++){
                // check which category is the current one - if none fits, count it as "sonstige"
                var j
                for (j=0; j<categorylist.length;j++){
                    if (categorylist[j]===rt.rows[i].category) break
                }
                counts[j] += 1
            }
            return counts
        } catch (err){
            console.error("Error when select from table '"+db_table_items+"': " + err)
        }
    }
}
