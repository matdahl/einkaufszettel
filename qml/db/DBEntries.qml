import QtQuick 2.7
import QtQuick.LocalStorage 2.0 as Sql

Item {
    id: root

    property var db

    // connection details
    property string db_name:        "einkauf"
    property string db_version:     "1.0"
    property string db_description: "DB of Einkaufszettel app"
    property int    db_size:        1024
    property string db_table_name:  "items"

    property string selectedCategory: ""
    property bool showCategoryOther: false

    property var entryModel: ListModel{}
    property var fullEntryModel: ListModel{}

    Component.onCompleted: refresh()
    onSelectedCategoryChanged: refresh()
    onShowCategoryOtherChanged: refresh()

    function refresh(){
        if (showCategoryOther){
            // tbd
        } else {
            entryModel.clear()
            var rows = selectItems(selectedCategory)
            for (var i=0;i<rows.length;i++)
                entryModel.append(rows[i])
        }
    }

    function db_test_callback(db){/* do nothing */}
    function init(){
        // open database
        db = Sql.LocalStorage.openDatabaseSync(db_name,db_version,db_description,db_size,db_test_callback(db))

        // Create items table if needed
        try{
            db.transaction(function(tx){
                tx.executeSql("CREATE TABLE IF NOT EXISTS "+db_table_name+" "
                              +"(uid INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, category TEXT, deleteFlag INTEGER DEFAULT 0)")
            })
        } catch (e1){
            console.error("Error when creating table '"+db_table_name+"': " + e1)
        }
        // check if all required colunms are in table and create missing ones
        try{
            var colnames = []
            db.transaction(function(tx){
                var rt = tx.executeSql("PRAGMA table_info("+db_table_name+")")
                for(var i=0;i<rt.rows.length;i++){
                    colnames.push(rt.rows[i].name)
                }
            })
            // since v1.0.2: require deleteFlag column
            if (colnames.indexOf("deleteFlag")<0){
                db.transaction(function(tx){
                    tx.executeSql("ALTER TABLE "+db_table_name+" ADD deleteFlag INTEGER DEFAULT 0")
                })
            }
            // since v1.3.0: require dimension column
            if (colnames.indexOf("dimension")<0){
                db.transaction(function(tx){
                    tx.executeSql("ALTER TABLE "+db_table_name+" ADD dimension TEXT DEFAULT 'x'")
                })
            }
            // since v1.3.0: require quantity column
            if (colnames.indexOf("quantity")<0){
                db.transaction(function(tx){
                    tx.executeSql("ALTER TABLE "+db_table_name+" ADD quantity INT DEFAULT 1")
                })
            }
            // since v1.3.1: require selected column
            if (colnames.indexOf("marked")<0){
                db.transaction(function(tx){
                    tx.executeSql("ALTER TABLE "+db_table_name+" ADD marked INT DEFAULT 0")
                })
            }
        } catch (e2){
            console.error("Error when checking columns of table '"+db_table_name+"': " + e2)
        }

        // init full entryModel
        try{
            var rows
            db.transaction(function(tx){
                rows = tx.executeSql("SELECT * FROM "+db_table_name+" WHERE deleteFlag=0").rows
            })
            for (var i=0; i<rows.length; i++){
                fullEntryModel.append(rows[i])
            }
            fullEntryModelChanged()
        } catch (e3){
            console.error("Error when selecting all entries: " + e3)
        }

        // if there are still deleted items left, remove them from DB for a clean start
        removeDeleted()
    }


    function insertItem(name,category,quantity,dimension){
        if (!db) init()
        try{
            // check if an item with the same name,category and dimension exists already
            var rows
            db.transaction(function(tx){
                rows = tx.executeSql("SELECT uid FROM "+db_table_name+" WHERE name=? AND category=? AND dimension=?"
                                    ,[name,category,dimension]).rows
            })
            // if there is a match, add quantity to this entry
            var uid
            if (rows.length>0){
                db.transaction(function(tx){
                    tx.executeSql("UPDATE "+db_table_name+" SET quantity = quantity + ? WHERE uid=?"
                                 ,[quantity,rows[0].uid])
                })
                uid = rows[0].uid
            } else { // create a new entry
                db.transaction(function(tx){
                    uid = tx.executeSql("INSERT INTO "+db_table_name+" (name,category,quantity,dimension) VALUES (?,?,?,?)"
                                       ,[name,category,quantity,dimension]).lastInsertId
                })
            }
            // update model if needed
            // tbd
        } catch (err){
            console.error("Error when insert into table '"+db_table_name+"': " + err)
        }
    }
    function deleteItem(uid){
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("DELETE FROM "+db_table_name+" WHERE uid='"+uid+"'")
            })
            itemsChanged()
        } catch (err){
            console.error("Error when delete from table '"+db_table_name+"': " + err)
        }
    }
    function selectItems(category){
        if (!db) init()
        try{
            var cmd = "SELECT * FROM "+db_table_name +" WHERE (deleteFlag<>1"
            if (category!=="") cmd += " AND category='"+category+"'"
            cmd += ")"
            var rt
            db.transaction(function(tx){
                rt = tx.executeSql(cmd)
            })
            return rt.rows
        } catch (err){
            console.error("Error when select from table '"+db_table_name+"': " + err)
        }
    }
    function swapItems(uid1,uid2){
        if (!db) init()
        try{
            db.transaction(function(tx){
                var tempID = -1
                // swap uids, then DB will sort it
                tx.executeSql("UPDATE "+db_table_name+" SET uid="+tempID+" WHERE uid="+uid1)
                tx.executeSql("UPDATE "+db_table_name+" SET uid="+uid1+" WHERE uid="+uid2)
                tx.executeSql("UPDATE "+db_table_name+" SET uid="+uid2+" WHERE uid="+tempID)
            })
        } catch (err){
            console.error("Error when swaping items in table '"+db_table_name+"': " + err)
        }
    }
    function toggleItemMarked(uid){
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_name+" SET marked=1-marked WHERE uid='"+uid+"'")
            })
        } catch (err){
            console.error("Error when toggle marked property of uid="+uid+" in table '"+db_table_name+"': " + err)
        }
    }
    function markAsDeleted(uid){
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_name+" SET deleteFlag=1 WHERE uid='"+uid+"'")
            })
            itemsChanged()
            hasDeletedEntries = true
        } catch (err){
            console.error("Error when marking entry as deleted in table '"+db_table_name+"': " + err)
        }
    }
    function removeDeleted(){
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("DELETE FROM "+db_table_name+" WHERE deleteFlag=1")
            })
            hasDeletedEntries = false
        } catch (err){
            console.error("Error when remove deleted from table '"+db_table_name+"': " + err)
        }
    }
    function restoreDeleted(){
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_name+" SET deleteFlag=0 WHERE deleteFlag=1")
            })
            itemsChanged()
            hasDeletedEntries = false
        } catch (err){
            console.error("Error when restoring deleted entries in table '"+db_table_name+"': " + err)
        }
    }
    function countEntriesPerCategory(){
        if (!db) init()
        try{
            // get list of all categories
            var rawcats = []
            for (var i=1;i<categoriesModel.count-1;i++){
                rawcats.push(categoriesModel.get(i).name)
            }
            var rt
            db.transaction(function(tx){
                rt = tx.executeSql("SELECT category FROM "+db_table_name+" WHERE deleteFlag=0")
            })
            var counts = [0,0]
            for (var i=0;i<rawcats.length;i++) counts.push(0)
            // go through each DB entry
            for (var i=0; i<rt.rows.length;i++){
                // check which category is the current one - if none fits, count it as "other"
                var j
                for (j=0; j<rawcats.length;j++){
                    if (rawcats[j]===rt.rows[i].category) break
                }
                counts[j+1] += 1
                // count all
                counts[0] += 1
            }
            return counts
        } catch (err){
            console.error("Error when counting items in table '"+db_table_name+"': " + err)
        }
    }

}
