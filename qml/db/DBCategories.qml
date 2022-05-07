import QtQuick 2.12
import QtQuick.LocalStorage 2.0 as Sql

Item {
    id: root

    signal categoriesChanged()

    property var model: ListModel{}

    property bool hasChecked: false
    property bool hasDeletedCategories: false

    property int countAll: 0
    property int countOther: 0

    // connection details
    property var    db
    property string db_name: "einkauf"
    property string db_version: "1.0"
    property string db_description: "DB of Einkaufszettel app"
    property int    db_size: 1024
    property string db_table_name: "categories"

    Component.onCompleted: {
        db_entries.itemRemoved.connect(entryRemoved)
        db_entries.itemAdded.connect(entryAdded)
        init()
    }

    function indexOf(catName){
        for (var i=0; i<model.count; i++)
            if (model.get(i).name===catName)
                return i
        return -1
    }

    function exists(catName){
        for (var i=0; i<model.count; i++)
            if (model.get(i).name===catName)
                return true
        return false
    }

    function entryAdded(item){
        if (!item)
            return

        var index = indexOf(item.category)
        if (index<0)
            countOther += 1
        else
            model.get(index).count += 1
        countAll  += 1
        categoriesChanged()
    }

    function entryRemoved(item){
        if (!item)
            return

        var index = indexOf(item.category)
        if (index < 0)
            countOther -= 1
        else
            model.get(index).count -= 1
        countAll -= 1
        categoriesChanged()
    }

    function checkForMarkedCategories(){
        for (var i=0; i<model.count; i++)
            if (model.get(i).marked===1){
                hasChecked = true
                return
            }
        hasChecked = false
    }

    function insertByRank(cat){
        var j=0
        while (j < model.count &&
               model.get(j).rank < cat.rank &&
               model.get(j).rank > -1)
            j++
        for (var i=0; i<db_entries.fullEntryModel.count; i++)
            if (db_entries.fullEntryModel.get(i).category === cat.name)
                cat.count += 1
        model.insert(j,cat)
        recountOther()
        categoriesChanged()
    }

    function deselectAll(){
        for (var i=0;i<root.model.count;i++)
            if (root.model.get(i).marked===1)
                root.toggleMarked(i)
    }

    function recountOther(){
        print("recount other")
        var counter = 0
        for (var j=0; j<db_entries.fullEntryModel.count; j++)
            if (indexOf(db_entries.fullEntryModel.get(j).category) < 0)
                counter++
        countOther = counter
    }


    function db_test_callback(db){/* do nothing */}
    function init(){
        // open database
        db = Sql.LocalStorage.openDatabaseSync(db_name,db_version,db_description,db_size,db_test_callback(db))

        // create categories table if needed
        try{
            db.transaction(function(tx){
                tx.executeSql("CREATE TABLE IF NOT EXISTS "+db_table_name+" "
                              +"(name TEXT"
                              +",marked INT DEFAULT 0"
                              +",deleteFlag INT DEFAULT 0"
                              +",rank INT DEFAULT -1"
                              +",UNIQUE(name)"
                              +")"
                             )
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
        model.clear()
        try{
            var rows
            db.transaction(function(tx){
                rows = tx.executeSql("SELECT * FROM "+db_table_name+" WHERE deleteFlag=0").rows
            })
            var resetRanks = false
            for (var i=0;i<rows.length;i++){
                var cat = {
                    name: rows[i].name,
                    marked: rows[i].marked,
                    deleteFlag: rows[i].deleteFlag,
                    rank: rows[i].rank,
                    count: 0
                }

                if (cat.rank<0){
                    model.append(cat)
                    resetRanks = true
                } else {
                    insertByRank(cat)
                }
            }

            if (resetRanks){
                for (var k=0; k<model.count; k++){
                    model.get(k).rank = k
                    updateRank(model.get(k).name,k)
                }
            }

            checkForMarkedCategories()
            deleteAllRemoved()

            categoriesChanged()

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
                rank: rank,
                count: 0
            }
            insertByRank(newCategory)
        } catch (err){
            console.error("Error when insert category into table '"+db_table_name+"': " + err)
        }
    }
    function remove(index){
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_name+" SET deleteFlag=1 WHERE name=?",
                              [model.get(index).name])
            })
            model.remove(index)
            recountOther()
            checkForMarkedCategories()
            categoriesChanged()
            hasDeletedCategories = true
        } catch (err){
            console.error("Error when remove category: " + err)
        }
    }
    function removeSelected(){
        for (var i = model.count-1; i>-1; i--)
            if (model.get(i).marked===1)
                remove(model.get(i))
    }
    function removeAll(){
        for (var i = model.count-1; i>-1; i--)
            remove(model.get(i))
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

            checkForMarkedCategories()
            recountOther()
            categoriesChanged()
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
            var name = model.get(index).name
            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_name+" SET marked=1-marked WHERE name=?",
                              [name])
            })
            model.get(index).marked = 1-model.get(index).marked
            checkForMarkedCategories()
        } catch (err){
            console.error("Error when toggle marked property of category '"+name+"': " + err)
        }
    }
    function swap(index1,index2){
        if (!db) init()

        try{
            var cat1 = model.get(index1)
            var cat2 = model.get(index2)
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
            model.get(index1).rank = rank2
            model.get(index2).rank = rank1
            model.move(index1,index2,1)
            categoriesChanged()
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
