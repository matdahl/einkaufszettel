import QtQuick 2.7
import QtQuick.LocalStorage 2.0 as Sql

Item {
    id: root

    property var entryModel: ListModel{}
    property var fullEntryModel: ListModel{}


    property bool hasChecked: false
    property bool hasDeleted: false


    signal itemAdded(var item)
    signal itemRemoved(var item)

    // connection details
    property var db
    property string db_name:        "einkauf"
    property string db_version:     "1.0"
    property string db_description: "DB of Einkaufszettel app"
    property int    db_size:        1024
    property string db_table_name:  "items"

    property string selectedCategory: ""
    property bool showCategoryOther: false

    Component.onCompleted: init()

    function insertByRank(item){
        var j=0
        while (j < entryModel.count &&
               entryModel.get(j).rank < item.rank &&
               entryModel.get(j).rank > -1)
            j++
        entryModel.insert(j,item)
    }

    function fullIndexByUid(uid){
        for (var i=0; i<fullEntryModel.count; i++)
            if (fullEntryModel.get(i).uid === uid)
                return i
        return -1
    }

    function indexByUid(uid){
        for (var i=0; i<entryModel.count; i++)
            if (entryModel.get(i).uid === uid)
                return i
        return -1
    }

    function checkForMarkedEntries(){
        for (var i=0; i<entryModel.count; i++)
            if (entryModel.get(i).marked===1){
                hasChecked = true
                return
            }
        hasChecked = false
    }

    function updateSelectedCategory(catName,isOther){
        if (selectedCategory === catName && showCategoryOther === isOther)
            return

        selectedCategory  = catName
        showCategoryOther = isOther
        refreshEntryModel()
    }

    function refreshEntryModel(){
        var i
        entryModel.clear()
        if (showCategoryOther){
            for (i=0; i<fullEntryModel.count; i++)
                if (!db_categories.exists(fullEntryModel.get(i).category))
                    insertByRank(fullEntryModel.get(i))
        } else {
            if (selectedCategory === "")
                for (i=0; i<fullEntryModel.count; i++)
                        insertByRank(fullEntryModel.get(i))
            else
                for (i=0; i<fullEntryModel.count; i++)
                    if (fullEntryModel.get(i).category === selectedCategory)
                        insertByRank(fullEntryModel.get(i))
        }
        checkForMarkedEntries()
    }

    function db_test_callback(db){/* do nothing */}
    function init(){
        // open database
        db = Sql.LocalStorage.openDatabaseSync(db_name,db_version,db_description,db_size,db_test_callback(db))

        // Create items table if needed
        try{
            db.transaction(function(tx){
                tx.executeSql("CREATE TABLE IF NOT EXISTS "+db_table_name+" "
                              +"(uid INTEGER PRIMARY KEY AUTOINCREMENT"
                              +",name TEXT"
                              +",category TEXT"
                              +",deleteFlag INTEGER DEFAULT 0"
                              +",rank INTEGER DEFAULT -1"
                              +")"
                             )
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
            // since v1.0.2:
            if (colnames.indexOf("deleteFlag")<0){
                db.transaction(function(tx){
                    tx.executeSql("ALTER TABLE "+db_table_name+" ADD deleteFlag INTEGER DEFAULT 0")
                })
            }
            // since v1.3.0:
            if (colnames.indexOf("dimension")<0){
                db.transaction(function(tx){
                    tx.executeSql("ALTER TABLE "+db_table_name+" ADD dimension TEXT DEFAULT 'x'")
                })
            }
            if (colnames.indexOf("quantity")<0){
                db.transaction(function(tx){
                    tx.executeSql("ALTER TABLE "+db_table_name+" ADD quantity INT DEFAULT 1")
                })
            }
            // since v1.3.1:
            if (colnames.indexOf("marked")<0){
                db.transaction(function(tx){
                    tx.executeSql("ALTER TABLE "+db_table_name+" ADD marked INT DEFAULT 0")
                })
            }
            // since v1.4.0:
            if (colnames.indexOf("rank")<0){
                db.transaction(function(tx){
                    tx.executeSql("ALTER TABLE "+db_table_name+" ADD rank INT DEFAULT -1")
                })
            }
        } catch (e2){
            console.error("Error when checking columns of table '"+db_table_name+"': " + e2)
        }

        // init full entryModel
        var resetRanks = false
        try{
            var rows
            db.transaction(function(tx){
                rows = tx.executeSql("SELECT * FROM "+db_table_name+" WHERE deleteFlag=0").rows
            })
            for (var i=0; i<rows.length; i++){
                fullEntryModel.append(rows[i])
                if (rows[i].rank < 0)
                    resetRanks = true
                itemAdded(rows[i])
            }
            if (resetRanks){
                for (var j=0; j<fullEntryModel.count; j++){
                    fullEntryModel.get(j).rank = j
                    db.transaction(function(tx){
                        tx.executeSql("UPDATE "+db_table_name+" SET rank=? WHERE uid=?",
                                      [j,fullEntryModel.get(j).uid])
                    })
                }
            }

            fullEntryModelChanged()
        } catch (e3){
            console.error("Error when selecting all entries: " + e3)
        }

        refreshEntryModel()

        // if there are still deleted items left, remove them from DB for a clean start
        removeDeleted()
    }


    function insert(name,quantity,dimension){
        if (!db) init()
        var catName = showCategoryOther ? i18n.tr("other") : selectedCategory
        try{
            // check if an item with the same name,category and dimension exists already
            var index = -1
            for (var i=0; i<entryModel.count; i++){
                var item = entryModel.get(i)
                if (item.name === name && item.dimension === dimension){
                    index = i
                    break
                }
            }

            // if there is a match, add quantity to this entry
            if (index > -1){
                var match = entryModel.get(index)
                var newQuantity = match.quantity+quantity
                db.transaction(function(tx){
                    tx.executeSql("UPDATE "+db_table_name+" SET quantity = ? WHERE uid=?"
                                 ,[newQuantity,match.uid])
                })
                entryModel.setProperty(index,"quantity",newQuantity)
                for (var j=0; j<fullEntryModel.count; j++){
                    if (fullEntryModel.get(j).uid===match.uid){
                        fullEntryModel.setProperty(j,"quantity",newQuantity)
                        break
                    }
                }
            // create a new entry otherwise
            } else {
                var uid
                db.transaction(function(tx){
                    // increment ranks of all entries
                    tx.executeSql("UPDATE "+db_table_name+" SET rank=rank+1 ")
                    // insert new entry on top of list (rank=0)
                    uid = tx.executeSql("INSERT INTO "+db_table_name+" (name,category,quantity,dimension,rank) VALUES (?,?,?,?,0)"
                                       ,[name,catName,quantity,dimension]).lastInsertId
                })
                var newItem = {
                    uid: uid,
                    name: name,
                    category: catName,
                    deleteFlag: 0,
                    dimension: dimension,
                    quantity: quantity,
                    marked: 0,
                    rank: 0
                }

                fullEntryModel.insert(0,newItem)
                if (selectedCategory === "" || selectedCategory === newItem.category)
                    entryModel.insert(0,newItem)
                itemAdded(newItem)
            }
        } catch (err){
            console.error("Error when insert item: " + err)
        }
    }
    function remove(uid){
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("DELETE FROM "+db_table_name+" WHERE uid='"+uid+"'")
            })
            var index = fullIndexByUid(uid)
            itemRemoved(fullEntryModel.get(index))
            fullEntryModel.remove(index)

            var index2 = indexByUid(uid)
            if (index2 > -1){
                entryModel.remove(index2)
                checkForMarkedEntries()
            }
            hasDeleted = true
        } catch (err){
            console.error("Error when delete entry: " + err)
        }
    }
    function removeAll(){
        for (var i=entryModel.count-1; i>-1; i--){
            var item = entryModel.get(i)
            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_name+" SET deleteFlag=1 WHERE uid='"+item.uid+"'")
            })
            itemRemoved(item)
            fullEntryModel.remove(fullIndexByUid(item.uid))
            entryModel.remove(i)
            hasDeleted = true
        }
        hasChecked = false
    }
    function removeSelected(){
        for (var i=entryModel.count-1; i>-1; i--){
            var item = entryModel.get(i)
            if (item.marked === 0)
                continue

            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_name+" SET deleteFlag=1 WHERE uid='"+item.uid+"'")
            })
            itemRemoved(item)
            fullEntryModel.remove(fullIndexByUid(item.uid))
            entryModel.remove(i)
            hasDeleted = true
        }
        hasChecked = false
    }
    function removeDeleted(){
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("DELETE FROM "+db_table_name+" WHERE deleteFlag=1")
            })
            hasDeleted = false
        } catch (err){
            console.error("Error when remove deleted from table '"+db_table_name+"': " + err)
        }
    }
    function restoreDeleted(){
        if (!db) init()
        try{
            var restored
            db.transaction(function(tx){
                restored = tx.executeSql("SELECT * FROM "+db_table_name+" WHERE deleteFlag=1").rows
            })
            for (var i=0; i<restored.length; i++){
                var item = restored[i]
                item.deleteFlag = 0
                fullEntryModel.insert(0,item)
                var catExist = db_categories.exists(item.category)
                if ((selectedCategory === "" && !showCategoryOther)
                        || (!catExist && showCategoryOther)
                        || (item.category === selectedCategory))
                    insertByRank(restored[i])
                itemAdded(item)
            }

            if (restored.length>0)
                checkForMarkedEntries()

            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_name+" SET deleteFlag=0 WHERE deleteFlag=1")
            })
            hasDeleted = false
        } catch (err){
            console.error("Error when restoring deleted entries in table '"+db_table_name+"': " + err)
        }
    }
    function swap(uid1,uid2){
        if (!db) init()

        // check if both items exists
        var fullIndex1 = fullIndexByUid(uid1)
        var fullIndex2 = fullIndexByUid(uid2)
        if (fullIndex1 === -1 || fullIndex2 === -1)
            return

        var entry1 = fullEntryModel.get(fullIndex1)
        var entry2 = fullEntryModel.get(fullIndex2)

        var rank1 = entry1.rank
        var rank2 = entry2.rank

        var rankMin = entry1.rank < entry2.rank ? entry1.rank : entry2.rank
        var rankMax = entry1.rank > entry2.rank ? entry1.rank : entry2.rank
        var uidMax  = entry1.rank > entry2.rank ? entry1.uid : entry2.uid

        var index1 = indexByUid(uid1)
        var index2 = indexByUid(uid2)

        try{

            // update ranks in database
            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_name+" SET rank=rank+1 WHERE rank>=? AND rank<?",
                              [rankMin,rankMax])
                tx.executeSql("UPDATE "+db_table_name+" SET rank=? WHERE uid=?",
                              [rankMin,uidMax])
            })
            // update ranks in fullEntryModel
            entry1.rank = rank2
            entry2.rank = rank1
            // update ranks in entryModel
            if (index1 > -1)
                entryModel.get(index1).rank = rank2
            if (index2 > -1)
                entryModel.get(index2).rank = rank1
            // swap items in entryModel
            if (index1 > -1 && index2 > -1)
                entryModel.move(index1,index2,1)

        } catch (err){
            console.error("Error when swaping items in table '"+db_table_name+"': " + err)
        }
    }
    function toggleMarked(uid){
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_name+" SET marked=1-marked WHERE uid=?",
                              [uid])
            })
            var indexFull = fullIndexByUid(uid)
            var marked = 1-fullEntryModel.get(indexFull).marked
            fullEntryModel.setProperty(indexFull,"marked",marked)
            var index = indexByUid(uid)
            if (index > -1)
                entryModel.setProperty(index,"marked",marked)

            checkForMarkedEntries()
        } catch (err){
            console.error("Error when toggle marked property of uid="+uid+": " + err)
        }
    }

}
