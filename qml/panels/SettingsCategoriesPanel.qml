import QtQuick 2.7
import Ubuntu.Components 1.3

import "../components/"
import "../components/listitems"

Item {
    id: root
    property string headerSuffix: i18n.tr("Categories")

    readonly property bool hasCheckedEntries: db_categories.hasChecked

    function deselectAll(){
        for (var i=0;i<db_categories.model.count;i++)
            if (db_categories.model.get(i).marked===1)
                db_categories.toggleMarked(i)
    }

    function insertCategory(){
        if (!db_categories.exists(inputCategory.text))
            db_categories.insertCategory(inputCategory.text)
        inputCategory.text = ""
    }

    Row{
        id: inputRow
        padding: units.gu(2)
        spacing: units.gu(2)
        TextField{
            id: inputCategory
            width: root.width - btNewCategory.width - 2*inputRow.padding - inputRow.spacing
            placeholderText: i18n.tr("new category ...")
            onAccepted: root.insertCategory()
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
            onClicked: root.insertCategory()
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
        model: db_categories.model
        delegate: CategoryListItem{}
    }
    Label{
        anchors.centerIn: parent
        text: "("+i18n.tr("No entries") +")"
        visible: listView.model.count===0
    }

    ClearListButtons{
        id: clearButtons
        hasItems: listView.model.count>0
        hasCheckedItems: db_categories.hasChecked
        hasDeletedItems: db_categories.hasDeletedCategories

        onRemoveAll:      db_categories.removeAll()
        onRemoveSelected: db_categories.removeSelected()
        onRemoveDeleted:  db_categories.deleteAllRemoved()
        onRestoreDeleted: db_categories.restoreDeleted()
    }
}
