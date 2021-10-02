import QtQuick 2.12
import QtQuick.LocalStorage 2.0 as Sql

Item {
    id: root

    property var rawModel: ListModel{}
    property var list: []

    property bool hasDeletedCategories: false

    // connection details
    property var    db
    property string db_name: "einkauf"
    property string db_version: "1.0"
    property string db_description: "DB of Einkaufszettel app"
    property int    db_size: 1024
    property string db_table_name: "categories"

    Component.onCompleted: init()

    function insertByRank(cat){
        var j=0
        while (j < rawModel.count &&
               rawModel.get(j).rank < cat.rank &&
               rawModel.get(j).rank > -1)
            j++
        rawModel.insert(j,cat)
        list.splice(j+1,0,cat.name)
    }

    function db_test_callback(db){/* do nothing */}
    function init(){
        // open database
        db = Sql.LocalStorage.openDatabaseSync(db_name,db_version,db_description,db_size,db_test_callback(db))

        // create categories table if needed
        try{
            db.transaction(function(tx){
                tx.executeSql("CREATE TABLE IF NOT EXISTS "+db_table_name+" "
                              +"(name TEXT, marked INT DEFAULT 0, deleteFlag INT DEFAULT 0, rank INT DEFAULT -1, UNIQUE(name))")
            })
        } catch (err){
            console.error("Error when creating table '"+db_table_name+"': " + err)
        }

        // check if all necessary columns are in table
        try{
            var colnames = []
            db.transaction(function(tx){
                var rt = tx.executeSql("PRAGMA table_info("+db_table_name+")")
                for(var i=0;i<rt.rows.length;i++){
                    colnames.push(rt.rows[i].name)
                }
            })
            // since v1.3.2: require marked column
            if (colnames.indexOf("marked")<0){
                db.transaction(function(tx){
                    tx.executeSql("ALTER TABLE "+db_table_name+" ADD marked INT DEFAULT 0")
                })
            }
            // since v1.3.2: require deleteFlag column
            if (colnames.indexOf("deleteFlag")<0){
                db.transaction(function(tx){
                    tx.executeSql("ALTER TABLE "+db_table_name+" ADD deleteFlag INT DEFAULT 0")
                })
            }
            // since v1.4.0: require rank column
            if (colnames.indexOf("rank")<0){
                db.transaction(function(tx){
                    tx.executeSql("ALTER TABLE "+db_table_name+" ADD rank INT DEFAULT -1")
                })
            }
        } catch (errCols){
            console.error("Error when checking columns of table '"+db_table_name+"': " + errCols)
        }

        // read all categories from database
        //categoriesModel.clear()
        rawModel.clear()
        list = [i18n.tr("all")]
        try{
            var rows
            db.transaction(function(tx){
                rows = tx.executeSql("SELECT * FROM "+db_table_name+" WHERE deleteFlag=0").rows
            })
            var resetRanks = false
            for (var i=0;i<rows.length;i++){
                if (rows[i].rank<0){
                    rawModel.append(rows[i])
                    list.push(rows[i].name)
                    resetRanks = true
                } else {
                    insertByRank(rows[i])
                }
            }
            list.push(i18n.tr("other"))

            if (resetRanks){
                for (var k=0; k<rawModel.count; k++){
                    rawModel.get(k).rank = k
                    updateRank(rawModel.get(k).name,k)
                }
            }

            deleteAllRemoved()
            listChanged()

        } catch (e){
            console.error("Error when reading categories from database: " + e)
        }
    }

    function insertCategory(name){
        if (!db) init()
        try{
            var rank = 0
            db.transaction(function(tx){
                var ranks = tx.executeSql("SELECT rank FROM "+db_table_name).rows
                for (var i=0; i<ranks.length; i++)
                    if (parseInt(ranks[i].rank) >= rank)
                        rank = parseInt(ranks[i].rank)+1

                tx.executeSql("INSERT OR IGNORE INTO "+db_table_name+"(name,rank) VALUES (?,?)",
                              [name,rank])
            })
            var newCategory = {
                name: name,
                marked: 0,
                deleteFlag: 0,
                rank: rank
            }
            rawModel.append(newCategory)
            var nCategories = rawModel.count
            list.splice(nCategories,0,name)
            listChanged()
        } catch (err){
            console.error("Error when insert category into table '"+db_table_name+"': " + err)
        }
    }

    function remove(index){
        if (!db) init()
        try{
            var name = list[index+1]
            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_name+" SET deleteFlag=1 WHERE name=?",
                              [name])
            })
            rawModel.remove(index)
            list.splice(index+1,1)
            listChanged()
            hasDeletedCategories = true
        } catch (err){
            console.error("Error when remove category: " + err)
        }
    }

    function deleteAllRemoved(){
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("DELETE FROM "+db_table_name+" WHERE deleteFlag=1")
            })
            hasDeletedCategories = false
        } catch (err){
            console.error("Error when delete all removed categories: " + err)
        }
    }

    function restoreDeleted(){
        if (!db) init()
        try{
            var restored
            db.transaction(function(tx){
                restored = tx.executeSql("SELECT * FROM "+db_table_name+" WHERE deleteFlag>0").rows
            })
            for (var i=0; i<restored.length; i++){
                restored[i].deleteFlag = 0
                insertByRank(restored[i])
            }
            if (restored.length>0)
                listChanged()

            hasDeletedCategories = false

            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_name+" SET deleteFlag=0")
            })

        } catch (err){
            console.error("Error when restoring deleted categories: " + err)
        }
    }


    function toggleMarked(index){
        if (!db) init()
        try{
            var name = list[index+1]
            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_name+" SET marked=1-marked WHERE name=?",
                              [name])
            })
            rawModel.get(index).marked = 1-rawModel.get(index).marked
        } catch (err){
            console.error("Error when toggle marked property of category '"+name+"': " + err)
        }
    }
}
