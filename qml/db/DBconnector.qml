import QtQuick 2.7
import QtQuick.LocalStorage 2.0 as Sql

Item {
    id: root

    signal itemsChanged()


    function getCategoryIndexByName(catName){
        for (var i=0; i<categoriesRawModel.count; i++)
            if (categoriesRawModel.get(i).name === catName)
                return i
        return -1
    }

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
        // Create items table if needed
        try{
            db.transaction(function(tx){
                tx.executeSql("CREATE TABLE IF NOT EXISTS "+db_table_items+" "
                              +"(uid INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, category TEXT, deleteFlag INTEGER DEFAULT 0)")
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
            // since v1.3.0: require dimension column
            if (colnames.indexOf("dimension")<0){
                db.transaction(function(tx){
                    tx.executeSql("ALTER TABLE "+db_table_items+" ADD dimension TEXT DEFAULT 'x'")
                })
            }
            // since v1.3.0: require quantity column
            if (colnames.indexOf("quantity")<0){
                db.transaction(function(tx){
                    tx.executeSql("ALTER TABLE "+db_table_items+" ADD quantity INT DEFAULT 1")
                })
            }
            // since v1.3.1: require selected column
            if (colnames.indexOf("marked")<0){
                db.transaction(function(tx){
                    tx.executeSql("ALTER TABLE "+db_table_items+" ADD marked INT DEFAULT 0")
                })
            }
        } catch (err){
            console.error("Error when checking columns of table '"+db_table_items+"': " + err)
        }
        // if there are still deleted items left, remove them form DB for a clean start
        removeDeleted()
    }




    function insertItem(name,category,quantity,dimension){
        if (!db) init()
        try{
            // check if an item with the same name,category and dimension exists already
            var rows
            db.transaction(function(tx){
                rows = tx.executeSql("SELECT uid FROM "+db_table_items+" WHERE name=? AND category=? AND dimension=?"
                                    ,[name,category,dimension]).rows
            })
            // if there is a match, add quantity to this entry
            if (rows.length>0){
                db.transaction(function(tx){
                    tx.executeSql("UPDATE "+db_table_items+" SET quantity = quantity + ? WHERE uid=?"
                                 ,[quantity,rows[0].uid])
                })
            } else { // create a new entry
                db.transaction(function(tx){
                    tx.executeSql("INSERT INTO "+db_table_items+" (name,category,quantity,dimension) VALUES (?,?,?,?)"
                                 ,[name,category,quantity,dimension])
                })
            }
            itemsChanged()
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
            itemsChanged()
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

    /* swap two items in database by exchanging their uids */
    function swapItems(uid1,uid2){
        if (!db) init()
        try{
            db.transaction(function(tx){
                var tempID = -1
                // swap uids, then DB will sort it
                tx.executeSql("UPDATE "+db_table_items+" SET uid="+tempID+" WHERE uid="+uid1)
                tx.executeSql("UPDATE "+db_table_items+" SET uid="+uid1+" WHERE uid="+uid2)
                tx.executeSql("UPDATE "+db_table_items+" SET uid="+uid2+" WHERE uid="+tempID)
            })
            //itemsChanged()
        } catch (err){
            console.error("Error when swaping items in table '"+db_table_items+"': " + err)
        }
    }

    /* toggles the selected property of item with given uid */
    function toggleItemMarked(uid){
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_items+" SET marked=1-marked WHERE uid='"+uid+"'")
            })
            //itemsChanged()
        } catch (err){
            console.error("Error when toggle marked property of uid="+uid+" in table '"+db_table_items+"': " + err)
        }
        //printAllItems()
    }

    /* marks an entry as deleted such that it is not listed anymore but still can be restored */
    function markAsDeleted(uid){
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_items+" SET deleteFlag=1 WHERE uid='"+uid+"'")
            })
            itemsChanged()
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
            itemsChanged()
            hasDeletedEntries = false
        } catch (err){
            console.error("Error when restoring deleted entries in table '"+db_table_items+"': " + err)
        }
    }


}


