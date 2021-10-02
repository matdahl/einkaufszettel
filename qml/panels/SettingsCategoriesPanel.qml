import QtQuick 2.7
import Ubuntu.Components 1.3

import "../components/"
import "../components/listitems"

Item {
    id: root
    property string headerSuffix: i18n.tr("Categories")

    property bool hasCheckedEntries: false
    function countCheckedEntries(){
        for (var i=0;i<dbcon.categoriesRawModel.count;i++){
            if (dbcon.categoriesRawModel.get(i).marked===1){
                hasCheckedEntries = true
                return
            }
        }
        hasCheckedEntries = false
    }

    // deselect all entries in current list
    function deselectAll(){
        if (!dbcon) return
        for (var i=0;i<dbcon.categoriesModel.count;i++){
            if (dbcon.categoriesModel.get(i).marked===1){
                dbcon.toggleCategoryMarked(dbcon.categoriesModel.get(i).name)
            }
        }
    }

    Component.onCompleted: {
        dbcon.categoriesChanged.connect(countCheckedEntries)
    }

    onVisibleChanged: {
        if (!visible) deselectAll()
    }

    Row{
        id: inputRow
        padding: units.gu(2)
        spacing: units.gu(2)
        TextField{
            id: inputCategory
            width: root.width - btNewCategory.width - 2*inputRow.padding - inputRow.spacing
            placeholderText: i18n.tr("new category ...")
            onAccepted: btNewCategory.clicked()
        }
        Button{
            id: btNewCategory
            color: theme.palette.normal.positive
            width: 1.6*height
            enabled: inputCategory.text !== ""
            Icon{
                anchors.centerIn: parent
                height: 0.7*parent.height
                width:  height
                name:   "add"
                color:  theme.palette.normal.positiveText
            }
            onClicked: {
                db_categories.insertCategory(inputCategory.text)
                inputCategory.text = ""
            }
        }
    }
    UbuntuListView{
        id: listView
        clip: true
        anchors{
            top:    inputRow.bottom
            bottom: root.bottom
            left:   root.left
            right:  root.right
        }
        currentIndex: -1
        model: db_categories.categoriesRawModel
        delegate: CategoryListItem{
            onRemove: dbcon.deleteCategory(listView.model.get(index).name)
            onMoveDown: {
                var name1 = listView.model.get(index).name
                var name2 = listView.model.get(index+1).name
                listView.model.move(index+1,index,1)
                dbcon.swapCategories(name1,name2)
            }
            onMoveUp: {
                var name1 = listView.model.get(index).name
                var name2 = listView.model.get(index-1).name
                listView.model.move(index-1,index,1)
                dbcon.swapCategories(name1,name2)
            }
            onToggleMarked: dbcon.toggleCategoryMarked(name)
        }
    }
    Label{
        anchors.centerIn: parent
        text: "("+i18n.tr("No entries") +")"
        visible: listView.model.count===0
    }

    ClearListButtons{
        id: clearButtons
        hasItems: listView.model.count>0
        hasCheckedItems: hasCheckedEntries
        hasDeletedItems: dbcon.hasDeletedCategories

        onRemoveAll:      dbcon.markCategoriesAsDeleted(false)
        onRemoveSelected: dbcon.markCategoriesAsDeleted(true)
        onRemoveDeleted:  dbcon.removeDeletedCategories()
        onRestoreDeleted: dbcon.restoreDeletedCategories()
    }
}
