import QtQuick 2.7
import QtQuick.LocalStorage 2.0 as Sql

Item {
    id: root

    property var db

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
            console.error("Error when creating table '"+db_table_categories+"': " + err)
        }
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
                              +"(NULL,'"+name+"','"+category+"')")
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
            var cmd = "SELECT * FROM "+db_table_items +" "
            if (category!=="") cmd += "WHERE category='"+category+"'"
            var rt
            db.transaction(function(tx){
                rt = tx.executeSql(cmd)
            })
            return rt.rows
        } catch (err){
            console.error("Error when select from table '"+db_table_items+"': " + err)
        }
    }


}
