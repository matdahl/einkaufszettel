import QtQuick 2.7
import QtQuick.LocalStorage 2.0 as Sql

Item {
    id: root

    property var categoriesModel: ListModel{}
    property var categoriesRawModel: ListModel{}
    property var categoriesList: []

    signal categoryListChanged()
    signal categoriesChanged()
    signal itemsChanged()

    onCategoriesChanged: {
        // refresh categoriesModel
        categoriesModel.clear()
        categoriesRawModel.clear()
        categoriesList = [i18n.tr("all")]
        categoriesModel.append({name:i18n.tr("all")})
        var cats = selectCategories()
        var resetRanks = false
        for (var i=0;i<cats.length;i++){
            // insertion sort by rank, if rank<0, then append and reset afterwards
            if (cats[i].rank<0){
                categoriesModel.append(cats[i])
                categoriesRawModel.append(cats[i])
                categoriesList.push(cats[i].name)
                resetRanks = true
            } else {
                var j=0
                while (j < categoriesRawModel.count &&
                       categoriesRawModel.get(j).rank < cats[i].rank &&
                       categoriesRawModel.get(j).rank > -1)
                    j++
                categoriesModel.insert(j+1,cats[i])
                categoriesRawModel.insert(j,cats[i])
                categoriesList.splice(j+1,0,cats[i])
            }
        }
        // reset ranks if needed
        categoriesModel.append({name:i18n.tr("other")})
        categoriesList.push(i18n.tr("other"))
        if (resetRanks){
            for (var k=0; k<categoriesRawModel.count; k++){
                categoriesRawModel.get(k).rank = k
                categoriesModel.get(k+1).rank = k
                updateRank(categoriesRawModel.get(k).name,k)
            }
        }

        // notify components to refresh
        categoryListChanged()
    }

    function getCategoryIndexByName(catName){
        for (var i=0; i<categoriesRawModel.count; i++)
            if (categoriesRawModel.get(i).name === catName)
                return i
        return -1
    }

    property var db

    // flag to state whether there are restorable deleted items
    property bool hasDeletedEntries: false

    // flag to state whether there are restorable deleted categories
    property bool hasDeletedCategories: false

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
        init_categories()
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


    function init_categories(){
        // Create categories table if needed
        try{
            db.transaction(function(tx){
                tx.executeSql("CREATE TABLE IF NOT EXISTS "+db_table_categories+" "
                              +"(name TEXT, marked INT DEFAULT 0, deleteFlag INT DEFAULT 0, rank INT DEFAULT -1, UNIQUE(name))")
            })
        } catch (err){
            console.error("Error when creating table '"+db_table_categories+"': " + err)
        }
        // check if all necessary columns are in table
        try{
            var colnames = []
            db.transaction(function(tx){
                var rt = tx.executeSql("PRAGMA table_info("+db_table_categories+")")
                for(var i=0;i<rt.rows.length;i++){
                    colnames.push(rt.rows[i].name)
                }
            })
            // since v1.3.2: require marked column
            if (colnames.indexOf("marked")<0){
                db.transaction(function(tx){
                    tx.executeSql("ALTER TABLE "+db_table_categories+" ADD marked INT DEFAULT 0")
                })
            }
            // since v1.3.2: require deleteFlag column
            if (colnames.indexOf("deleteFlag")<0){
                db.transaction(function(tx){
                    tx.executeSql("ALTER TABLE "+db_table_categories+" ADD deleteFlag INT DEFAULT 0")
                })
            }
            // since v1.4.0: require rank column
            if (colnames.indexOf("rank")<0){
                db.transaction(function(tx){
                    tx.executeSql("ALTER TABLE "+db_table_categories+" ADD rank INT DEFAULT -1")
                })
            }
        } catch (err){
            console.error("Error when checking columns of table '"+db_table_categories+"': " + err)
        }
        categoriesChanged()
    }

    function insertCategory(name){
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("INSERT OR IGNORE INTO "+db_table_categories+"(name) VALUES"
                              +"('"+name+"')")
            })
            categoriesChanged()
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
            categoriesChanged()
        } catch (err){
            console.error("Error when delete from table '"+db_table_categories+"': " + err)
        }
    }
    function selectCategories(){
        if (!db) init()
        try{
            var rt
            db.transaction(function(tx){
                rt = tx.executeSql("SELECT * FROM "+db_table_categories+" WHERE deleteFlag=0")
            })
            return rt.rows
        } catch (err){
            console.error("Error when select from table '"+db_table_categories+"': " + err)
        }
    }
    function swapCategories(catName1,catName2){
        if (!db) init()

        var idx1 = getCategoryIndexByName(catName1)
        var idx2 = getCategoryIndexByName(catName2)
        if (idx1 < 0 || idx2 < 0)
            return

        var rank1 = categoriesRawModel.get(idx1).rank
        var rank2 = categoriesRawModel.get(idx2).rank

        try{
            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_categories+" SET rank=? WHERE name=?",[rank2,catName1])
                tx.executeSql("UPDATE "+db_table_categories+" SET rank=? WHERE name=?",[rank1,catName2])
            })
            categoriesRawModel.get(idx1).rank = rank2
            categoriesRawModel.get(idx2).rank = rank1
            categoriesModel.get(idx1+1).rank = rank2
            categoriesModel.get(idx2+1).rank = rank1
            categoriesRawModel.move(idx1,idx2,1)
            categoriesModel.move(idx1+1,idx2+1,1)
            categoriesList[idx1] = catName2
            categoriesList[idx2] = catName1

            categoryListChanged()
        } catch (err){
            console.error("Error when swaping categories in table '"+db_table_categories+"': " + err)
        }
    }
    function updateRank(catName,rank){
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_categories+" SET rank=? WHERE name=?",[rank,catName])
            })
        } catch (err){
            console.error("Error when updating rank of category '"+catName+"' in table '"+db_table_categories+"': " + err)
        }
    }

    function toggleCategoryMarked(cat){
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_categories+" SET marked=1-marked WHERE name='"+cat+"'")
            })
            categoriesChanged()
        } catch (err){
            console.error("Error when toggle marked property of category '"+cat+"' in table '"+db_table_categories+"': " + err)
        }
    }
    function markCategoriesAsDeleted(selectedOnly){
        if (!db) init()
        try{
            var cmd = "UPDATE "+db_table_categories+" SET deleteFlag=1"
            if (selectedOnly) cmd += " WHERE marked=1"
            db.transaction(function(tx){
                tx.executeSql(cmd)
            })
            hasDeletedCategories = true
            categoriesChanged()
        } catch (err){
            console.error("Error when marking category as deleted in table '"+db_table_categories+"': " + err)
        }
    }
    function removeDeletedCategories(){
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("DELETE FROM "+db_table_categories+" WHERE deleteFlag=1")
            })
            hasDeletedCategories = false
        } catch (err){
            console.error("Error when remove deleted from table '"+db_table_categories+"': " + err)
        }
    }
    function restoreDeletedCategories(){
        if (!db) init()
        try{
            db.transaction(function(tx){
                tx.executeSql("UPDATE "+db_table_categories+" SET deleteFlag=0")
            })
            categoriesChanged()
            hasDeletedCategories = false
        } catch (err){
            console.error("Error when restoring deleted categories in table '"+db_table_categories+"': " + err)
        }
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

    /* counts for each category the number of not deleted items in database */
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
                rt = tx.executeSql("SELECT category FROM "+db_table_items+" WHERE deleteFlag=0")
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
            console.error("Error when counting items in table '"+db_table_items+"': " + err)
        }
    }

    /* prints all items from the database to the terminal - for debugging purposes only */
    function printAllItems(){
        if (!db) init()
        try{
            var rows
            db.transaction(function(tx){
                rows = tx.executeSql("SELECT * FROM "+db_table_items).rows
            })
            for (var i=0;i<rows.length;i++){
                print(rows[i].uid,rows[i].name,rows[i].category,rows[i].deleteFlag,rows[i].selected)
            }
        } catch (err){
            console.error("Error when selecting all from table '"+db_table_items+"': " + err)
        }
    }
}


