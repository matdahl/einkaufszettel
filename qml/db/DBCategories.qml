import QtQuick 2.12
import QtQuick.LocalStorage 2.0 as Sql

Item {
    id: root

    signal categoriesChanged()

    property var model: ListModel{}
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
        db_entries.itemRemoved.connect(entryRemoved)
        db_entries.itemAdded.connect(entryAdded)
        init()
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

        var index = entriesPerCategory[0].indexOf(item.category)
        if (index >= 0){
            entriesPerCategory[1][index] = entriesPerCategory[1][index] + 1
        } else {
            entriesPerCategory[0].push(item.category)
            entriesPerCategory[1].push(1)
        }

        updateAllCount()
        if (exists(item.category)){
            updateCount(item.category)
        } else {
            updateOtherCount()
        }
        listChanged()
    }

    function entryRemoved(item){
        if (!item)
            return

        var index = entriesPerCategory[0].indexOf(item.category)
        if (entriesPerCategory[1][index]>0){
            entriesPerCategory[1][index] = entriesPerCategory[1][index] - 1
        } else {
            entriesPerCategory[0].splice(index,1)
            entriesPerCategory[1].splice(index,1)
        }

        updateAllCount()
        if (exists(item.category)){
            updateCount(item.category)
        } else {
            updateOtherCount()
        }
        listChanged()
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
            for (var k=0; k<model.count; k++){
                var other = true
                if (model.get(k).name===entriesPerCategory[0][j]){
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

        for (var i=0; i<model.count; i++){
            var index = entriesPerCategory[0].indexOf(model.get(i).name)
            if (index<0)
                list.push(model.get(i).name + " (0)")
            else
                list.push("<b>"+model.get(i).name + " ("+entriesPerCategory[1][index]+")</b>")
        }
        if (sumOther>0)
            list.push("<b>"+i18n.tr("other")+" ("+sumOther+")</b>")
        else
            list.push(i18n.tr("other")+" (0)")

        listChanged()
    }

    function updateAllCount(){
        var count = countAllEntries()
        if (count>0)
            list.splice(0,1,"<b>"+i18n.tr("all")+" ("+count+")</b>")
        else
            list.splice(0,1,i18n.tr("all")+" (0)")
    }

    function updateCount(catName){
        var index = entriesPerCategory[0].indexOf(catName)
        var count = index<0 ? 0 : entriesPerCategory[1][index]
        var catIndex
        for (catIndex=0; catIndex<model.count; catIndex++)
            if (model.get(catIndex).name === catName)
                break
        if (count>0)
            list.splice(catIndex+1,1,"<b>"+catName+" ("+count+")</b>")
        else
            list.splice(catIndex+1,1,catName+" (0)")
    }

    function updateOtherCount(){
        var count = countOtherEntries()
        if (count>0)
            list.splice(list.length-1,1,"<b>"+i18n.tr("other")+" ("+count+")</b>")
        else
            list.splice(list.length-1,1,i18n.tr("other")+" (0)")
    }

    function checkForMarkedCategories(){
        for (var i=0; i<model.count; i++)
            if (model.get(i).marked===1){
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
            updateOtherCount()
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
        while (j < model.count &&
               model.get(j).rank < cat.rank &&
               model.get(j).rank > -1)
            j++
        model.insert(j,cat)
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
        insertToList(-1,"all")
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
                    insertToList(list.length,cat.name)
                    resetRanks = true
                } else {
                    insertByRank(cat)
                }
            }
            insertToList(-2,"other")

            if (resetRanks){
                for (var k=0; k<model.count; k++){
                    model.get(k).rank = k
                    updateRank(model.get(k).name,k)
                }
            }

            checkForMarkedCategories()
            deleteAllRemoved()

            categoriesChanged()
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
            model.append(newCategory)
            categoriesChanged()
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
            categoriesChanged()
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
            for (var i = model.count-1; i>-1; i--){
                if (model.get(i).marked===1){
                    model.remove(i)
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
            model.clear()
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
