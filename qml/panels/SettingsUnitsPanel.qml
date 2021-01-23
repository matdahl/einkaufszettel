import QtQuick 2.7
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3

import "../components"
import "../components/listitems"

Item {
    id: root
    property string headerSuffix: i18n.tr("Units")

    property var dimensions

    // the flag if check boxes are shown
    property bool checkMode: false

    property bool hasCheckedEntries: dimensions.hasMarkedUnits

    function deselectAll(){
        dimensions.deselectAll()
    }

    function reset(){
        PopupUtils.open(dialog)
    }



    /* ------------------------------------
     *               Components
     * ------------------------------------ */



    Row{
        id: inputRow
        padding: units.gu(2)
        spacing: units.gu(2)
        TextField{
            id: inputSymbol
            width: units.gu(8)
            placeholderText: i18n.tr("abbr.")
            hasClearButton: false
        }
        TextField{
            id: inputName
            width: root.width - btNewUnit.width - 2*inputRow.padding - 2*inputRow.spacing - inputSymbol.width
            placeholderText: i18n.tr("new unit ...")
            onAccepted: btNewUnit.clicked()
        }
        Button{
            id: btNewUnit
            color: theme.palette.normal.positive
            width: 1.6*height
            Icon{
                anchors.centerIn: parent
                height: 0.7*parent.height
                width:  height
                name:   "add"
                color: theme.palette.normal.positiveText
            }
            onClicked: {
                if (inputSymbol.text !== "" && inputName.text !== ""){
                    dimensions.add(inputSymbol.text,inputName.text)
                    inputName.text = ""
                    inputSymbol.text = ""
                }
            }
        }
    }

    Label{
        anchors.centerIn: parent
        text: "("+i18n.tr("No entries") +")"
        visible: listView.model.count===0
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
        model: dimensions.unitsModel
        delegate: UnitListItem{
            onRemove: dimensions.remove(uid)
            onMoveUp: {
                dimensions.swap(uid,listView.model.get(index-1).uid)
                // swap items in view
                var tempUID = uid
                uid = listView.model.get(index-1).uid
                listView.model.setProperty(index-1,"uid",tempUID)
                listView.model.move(index-1,index,1)
            }
            onMoveDown: {
                dimensions.swap(uid,listView.model.get(index+1).uid)
                // swap items in view
                var tempUID = uid
                uid = listView.model.get(index+1).uid
                listView.model.setProperty(index+1,"uid",tempUID)
                listView.model.move(index+1,index,1)
            }
            onToggleMarked: {
                dimensions.toggleMarked(uid)
            }
        }
    }

    ClearListButtons{
        id: clearList
        hasCheckedItems: dimensions.hasMarkedUnits
        hasDeletedItems: dimensions.hasDeletedUnits
        hasItems:        listView.model.count > 1
        onRemoveAll:      dimensions.removeAll()
        onRemoveSelected: dimensions.removeSelected()
        onRemoveDeleted:  dimensions.removeDeleted()
        onRestoreDeleted: dimensions.restoreDeleted()
    }

    Component {
         id: dialog
         Dialog {
             id: dialogue
             title: i18n.tr("Reset units")
             text: i18n.tr("Are you sure that you want to reset to default units?")
             Button {
                 text: i18n.tr("cancel")
                 onClicked: PopupUtils.close(dialogue)
             }
             Button {
                 text: i18n.tr("reset units")
                 color: UbuntuColors.orange
                 onClicked: {
                     dimensions.resetUnits()
                     PopupUtils.close(dialogue)
                 }
             }
         }
    }
}
