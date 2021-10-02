import QtQuick 2.12
import QtQuick.LocalStorage 2.0 as Sql

Item {
    id: root

    property var rawModel: ListModel{}
    property var list: []

    property bool hasChecked: false
    property bool hasDeletedCategories: false

    property var entriesPerCategory: [[],[]]

    // connection details
    property var    db
    property string db_name: "einkauf"
    property string db_version: "1.0"
    property string db_description: "DB of Einkaufszettel app"
    property int    db_size: 1024
    property string db_table_name: "categories"

    Component.onCompleted: {
        db_entries.fullEntryModelChanged.connect(recountEntries)
        init()
    }

    function recountEntries(){
        var newEntriesPerCategory = [[],[]]
        for (var i=0; i<db_entries.fullEntryModel.count; i++){
            var catName = db_entries.fullEntryModel.get(i).category
            var index = newEntriesPerCategory[0].indexOf(catName)
            if (index<0){
                newEntriesPerCategory[0].push(catName)
                newEntriesPerCategory[1].push(1)
            } else{
                newEntriesPerCategory[1][index] += 1
            }
        }
        // check if something has changed
        var updateNeeded = false
        if (newEntriesPerCategory[0].length !== entriesPerCategory[0].length){
            updateNeeded =true
        } else {
            for (var j=0; j<entriesPerCategory[0].length; j++){
                var k = newEntriesPerCategory[0].indexOf(entriesPerCategory[0][j])
                if (k<0 || newEntriesPerCategory[1][k] !== entriesPerCategory[1][j]){
                    updateNeeded = true
                    break
                }
            }
        }

        if (updateNeeded){
            entriesPerCategory[0] = newEntriesPerCategory[0]
            entriesPerCategory[1] = newEntriesPerCategory[1]
            updateListCounts()
        }
    }

    function countAllEntries(){
        var sum = 0
        for (var j=0; j<entriesPerCategory[0].length; j++)
            sum += entriesPerCategory[1][j]
        return sum
    }

    function countOtherEntries(){
        var sum = 0
        for (var j=0; j<entriesPerCategory[0].length; j++){
            for (var k=0; k<rawModel.count; k++){
                var other = true
                if (rawModel.get(k).name===entriesPerCategory[0][j]){
                    other = false
                    break
                }
            }
            if (other)
                sum += entriesPerCategory[1][j]
        }
        return sum
    }

    function updateListCounts(){
        list = []

        var sumAll   = countAllEntries()
        var sumOther = countOtherEntries()

        if (sumAll>0)
            list.push("<b>"+i18n.tr("all")+" ("+sumAll+")</b>")
        else
            list.push(i18n.tr("all")+" (0)")

        for (var i=0; i<rawModel.count; i++){
            var index = entriesPerCategory[0].indexOf(rawModel.get(i).name)
            if (index<0)
                list.push(rawModel.get(i).name + " (0)")
            else
                list.push("<b>"+rawModel.get(i).name + " ("+entriesPerCategory[1][index]+")</b>")
        }
        if (sumOther>0)
            list.push("<b>"+i18n.tr("other")+" ("+sumOther+")</b>")
        else
            list.push(i18n.tr("other")+" (0)")

        listChanged()
    }

    function updateOtherCount(){
        var count = countOtherEntries()
        if (count>0)
            list.splice(list.length-1,1,"<b>"+i18n.tr("other")+" ("+count+")</b>")
        else
            list.splice(list.length-1,1,i18n.tr("other")+" (0)")
    }

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
            var idx = entriesPerCategory[0].indexOf(name)
            if (idx<0 || entriesPerCategory[1][idx] === 0)
                list.splice(index,0,name + "(0)")
            else
                list.splice(index,0,"<b>" + name + "("+entriesPerCategory[1][idx]+")</b>")
        } else if (index === -1){
            var countAll = countAllEntries()
            if (countAll>0)
                list = ["<b>"+i18n.tr("all")+" ("+countAll+")</b>"]
            else
                list = [i18n.tr("all")+" (0)"]
        } else if (index === -2){
            var countOther = countOtherEntries()
            if (countOther>0)
                list = ["<b>"+i18n.tr("other")+" ("+countOther+")</b>"]
            else
                list = [i18n.tr("other")+" (0)"]
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
            updateOtherCount()
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
            updateOtherCount()
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
            updateOtherCount()
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
            var name = rawModel.get(index).name
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
