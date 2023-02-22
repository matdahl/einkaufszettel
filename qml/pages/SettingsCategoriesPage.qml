import QtQuick 2.7
import Lomiri.Components 1.3

import "../components/"
import "../components/listitems"

Page {
    id: root

    function insertCategory(){
        if (!db_categories.exists(inputCategory.text))
            db_categories.insertCategory(inputCategory.text)
        inputCategory.text = ""
    }

    header: PageHeader {
        StyleHints{backgroundColor: colors.currentHeader}
        title: i18n.tr("Shopping List") + " - " + i18n.tr("Categories")
        trailingActionBar.actions: [
            Action{
                iconName: "select-none"
                visible: db_categories.hasChecked
                onTriggered: db_categories.deselectAll()
            }
        ]
    }

    Row{
        id: inputRow
        anchors.top: header.bottom
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
    LomiriListView{
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
