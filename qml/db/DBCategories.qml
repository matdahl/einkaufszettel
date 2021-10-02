import QtQuick 2.12
import QtQuick.LocalStorage 2.0 as Sql

Item {
    id: root

    property var rawModel: ListModel{}
    property var list: []

    property bool hasChecked: false
    property bool hasDeletedCategories: false

    // connection details
    property var    db
    property string db_name: "einkauf"
    property string db_version: "1.0"
    property string db_description: "DB of Einkaufszettel app"
    property int    db_size: 1024
    property string db_table_name: "categories"

    Component.onCompleted: init()

    function checkForMarkedCategories(){
        for (var i=0; i<rawModel.count; i++)
            if (rawModel.get(i).marked===1){
                hasChecked = true
                return
            }
        hasChecked = false
    }

    function insertToList(index,name){
        if (index > -1){
            list.splice(index,0,name)
        } else if (index === -1){
            list = [i18n.tr("all")]
        } else if (index === -2){
            list.push(i18n.tr("other"))
        }
    }

    function insertByRank(cat){
        var j=0
        while (j < rawModel.count &&
               rawModel.get(j).rank < cat.rank &&
               rawModel.get(j).rank > -1)
            j++
        rawModel.insert(j,cat)
        insertToList(j+1,cat.name)
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
        rawModel.clear()
        insertToList(-1,"all")
        try{
            var rows
            db.transaction(function(tx){
                rows = tx.executeSql("SELECT * FROM "+db_table_name+" WHERE deleteFlag=0").rows
            })
            var resetRanks = false
            for (var i=0;i<rows.length;i++){
                if (rows[i].rank<0){
                    rawModel.append(rows[i])
                    insertToList(list.length,rows[i].name)
                    resetRanks = true
                } else {
                    insertByRank(rows[i])
                }
            }
            insertToList(-2,"other")

            if (resetRanks){
                for (var k=0; k<rawModel.count; k++){
                    rawModel.get(k).rank = k
                    updateRank(rawModel.get(k).name,k)
                }
            }

            checkForMarkedCategories()
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
            insertToList(rawModel.count,name)
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
            checkForMarkedCategories()
            hasDeletedCategories = true
        } catch (err){
            console.error("Error when remove category: " + err)
        }
    }
    function removeSelected(){
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_name+" SET deleteFlag=1 WHERE marked=1")
            })
            for (var i = rawModel.count-1; i>-1; i--){
                if (rawModel.get(i).marked===1){
                    rawModel.remove(i)
                    list.splice(i+1,1)
                }
            }
            checkForMarkedCategories()
            hasDeletedCategories = true
            listChanged()
        } catch (err){
            console.error("Error when marking selected categories as deleted: " + err)
        }
    }
    function removeAll(){
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_name+" SET deleteFlag=1")
            })
            rawModel.clear()
            list = []
            hasChecked = false
            hasDeletedCategories = true
            listChanged()
        } catch (err){
            console.error("Error when marking all categories as deleted: " + err)
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

            checkForMarkedCategories()
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
            checkForMarkedCategories()
        } catch (err){
            console.error("Error when toggle marked property of category '"+name+"': " + err)
        }
    }
    function swap(index1,index2){
        if (!db) init()

        try{
            var cat1 = rawModel.get(index1)
            var cat2 = rawModel.get(index2)
            var rank1 = cat1.rank
            var rank2 = cat2.rank
            var name1 = cat1.name
            var name2 = cat2.name

            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_name+" SET rank=? WHERE name=?",
                              [rank2,name1])
                tx.executeSql("UPDATE "+db_table_name+" SET rank=? WHERE name=?",
                              [rank1,name2])
            })
            rawModel.get(index1).rank = rank2
            rawModel.get(index2).rank = rank1
            rawModel.move(index1,index2,1)
            list[index1+1] = name2
            list[index2+1] = name1
            listChanged()
        } catch (err){
            console.error("Error when swap categories: " + err)
        }
    }

    function updateRank(name,rank){
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_name+" SET rank=? WHERE name=?",
                              [rank,name])
            })
        } catch (err){
            console.error("Error when updating rank of category '"+name+": " + err)
        }
    }
}
