import QtQuick 2.7
import QtQml 2.2
import QtQuick.Controls 2.2
import Ubuntu.Components 1.3

import "../components"

Item {
    id: root
    property string headerSuffix: ""

    // the connector to interact with the entries and categories database
    property var dbcon

    // the connector to interact with the history database
    property var db_histo

    Sections{
        id: sections
        anchors{
            top:   parent.top
            left:  parent.left
            right: parent.right
        }
        height: units.gu(6)
        model: []

        // connect signals from DB connector with slots
        Component.onCompleted: {
            dbcon.itemsChanged.connect(recount)
            dbcon.categoriesChanged.connect(refresh)
            // refresh to initialise the model
            refresh()
        }
        onSelectedIndexChanged: listView.refresh()

        /* refreshs the sections in case the categories changed */
        function refresh(){
            // empty old model
            model.length = 0
            for (var i=0;i<dbcon.categoriesModel.count;i++){
                model.push(dbcon.categoriesModel.get(i).name)
            }
            // count entries per category
            recount()
        }

        /* update the counts of entries per category */
        function recount(){
            var counts = dbcon.countEntriesPerCategory()
            model[0] = (counts[0]>0) ? "<b>"+i18n.tr("all")+" ("+counts[0]+")</b>"
                                              :       i18n.tr("all")+" (0)"
            var j
            for (j=1;j<model.length-1;j++){
                model[j] = (counts[j]>0) ? "<b>"+dbcon.categoriesModel.get(j).name+" ("+counts[j]+")</b>"
                                                  :       dbcon.categoriesModel.get(j).name+" (0)"
            }
            model[j] = (counts[j]>0) ? "<b>"+i18n.tr("other")+" ("+counts[j]+")</b>"
                                              :       i18n.tr("other")+" (0)"
            // trigger event to repaint view
            var temp = selectedIndex
            modelChanged()
            selectedIndex = temp
        }
    }

    Label{
        anchors.centerIn: parent
        text: "("+i18n.tr("No entries") +")"
        visible: listView.model.count===0
    }

    UbuntuListView{
        id: listView
        anchors{
            top:    inputRow.bottom
            bottom: root.bottom
            left:   root.left
            right:  root.right
            bottomMargin: units.gu(6)
        }
        clip: true
        currentIndex: -1
        model: ListModel{}

        Component.onCompleted: {
            dbcon.itemsChanged.connect(refresh)
            refresh()
        }

        function refresh(){
            model.clear()
            // check if all entries should be displayed
            if (sections.selectedIndex==0){
                var rows = dbcon.selectItems("")
                for (var i=rows.length-1; i>-1; i--) {
                    listView.model.append(rows[i])
                }
            } else {
                var category = dbcon.categoriesModel.get(sections.selectedIndex).name
                if (category===i18n.tr("other")) category = ""
                var rows = dbcon.selectItems(category)
                if (rows){
                    for (var i= rows.length-1;i>-1;i--){
                        // if category=other, then check whether category exists
                        if (category===""){
                            var found = false
                            for (var j=1; j<dbcon.categoriesList.length-1; j++){
                                if (dbcon.categoriesList[j]===rows[i].category) found = true
                            }
                            if (found) continue
                        }
                        listView.model.append(rows[i])
                    }
                }
            }
        }

        delegate: ListItem{
            leadingActions: ListItemActions{
                actions: [
                    Action{
                        iconName: "delete"
                        onTriggered: dbcon.deleteItem(listView.model.get(index).uid)
                    }
                ]
            }
            Rectangle{
                anchors.fill: parent
                color: theme.palette.normal.positive
                opacity: 0.2
                visible: marked
            }

            CheckBox{
                id: checkBox
                anchors{
                    right: mouseUp.left
                    verticalCenter: parent.verticalCenter
                    margins: units.gu(2)
                }
                visible: checkMode
                checked: marked
                onTriggered: {
                    dbcon.toggleItemMarked(uid)
                    marked = 1-marked
                }
            }

            TextArea{
                id: lbName
                anchors{
                    left: mouseDown.right
                    right: checkBox.visible ? checkBox.left : mouseUp.left
                    top: parent.top
                    bottom: parent.bottom
                    leftMargin: units.gu(6)
                }
                x: 0.35*parent.width
                text: name
                verticalAlignment: Qt.AlignVCenter
                readOnly: true
            }
            Label{
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: lbName.left
                anchors.margins: units.gu(1)
                text: "<b>"+quantity+" "+dimension+"</b>"
                horizontalAlignment: Label.AlignRight
            }
            Label{
                anchors.bottom: parent.bottom
                anchors.left:   parent.left
                textSize: Label.Small
                text: category
            }
            MouseArea{
                id: mouseDown
                visible: index<listView.model.count-1
                anchors{
                    top: parent.top
                    left: parent.left
                    bottom: parent.bottom
                }
                width: height
                Icon{
                    name: "down"
                    height: units.gu(3)
                    anchors.centerIn: parent
                }
                onClicked:{
                    dbcon.swapItems(listView.model.get(index).uid,listView.model.get(index+1).uid)
                    // swap items in view
                    var tempUID = uid
                    uid = listView.model.get(index+1).uid
                    listView.model.setProperty(index+1,"uid",tempUID)
                    listView.model.move(index+1,index,1)
                }
            }
            MouseArea{
                id: mouseUp
                visible: index>0
                anchors{
                    top:    parent.top
                    right:  parent.right
                    bottom: parent.bottom
                }
                width: 1.2*height
                Icon{
                    name: "up"
                    height: units.gu(3)
                    anchors.centerIn: parent
                }
                onClicked: {
                    dbcon.swapItems(listView.model.get(index).uid,listView.model.get(index-1).uid)
                    // swap items in view
                    var tempUID = uid
                    uid = listView.model.get(index-1).uid
                    listView.model.setProperty(index-1,"uid",tempUID)
                    listView.model.move(index-1,index,1)
                }
            }
            Rectangle{
                id: downGradient
                width: 0.5*parent.width
                height: width
                x: 0
                y: 0.5*(parent.height-height)
                rotation: 90
                gradient: Gradient {
                        GradientStop { position: 1.0; color: "#88aa8888"}
                        GradientStop { position: 0.0; color: "#00aa8888"}
                    }
                visible: mouseDown.pressed
            }
            Rectangle{
                id: upGradient
                width: 0.5*parent.width
                height: width
                x: 0.5*parent.width
                y: 0.5*(parent.height-height)
                rotation: 90
                gradient: Gradient {
                        GradientStop { position: 0.0; color: "#8888aa88"}
                        GradientStop { position: 1.0; color: "#0088aa88"}
                    }
                visible: mouseUp.pressed
            }
        }
    }


    InputRow{
        id: inputRow
        width: parent.width
        anchors.top: sections.bottom
        placeholderText: i18n.tr("new entry ...")
        enabled: sections.selectedIndex>0
        db_histo: root.db_histo
        Component.onCompleted: {
            updateModel(db_histo)
        }
        onAccepted: {
            if (text !== ""){
                // insert new entry to database
                dbcon.insertItem(text.trim(),dbcon.categoriesList[sections.selectedIndex],inputRow.quantity,inputRow.dimension)
                // insert new entry to history
                db_histo.addKey(text.trim())
                reset()
                updateModel(db_histo)
            }
        }
    }
    // button to restore entries which where previously deleted
    Button{
        id: btRestore
        width: 0.4*root.width
        x:     0.3*root.width

        iconName: "undo"
        color: theme.palette.normal.base

        state: (dbcon.hasDeletedEntries) ? "on" : "off"
        states: [
            State{
                name: "off"
                PropertyChanges {target: btRestore; y: root.parent.height}
            },
            State{
                name: "on"
                PropertyChanges {target: btRestore; y: root.parent.height - height - units.gu(2)}
            }
        ]
        transitions: Transition {
            reversible: true
            from: "off"
            to: "on"
            PropertyAnimation{
                property: "y"
                duration: 400
            }
        }
        onClicked: dbcon.restoreDeleted()
    }

    // button to delete all currently displayed entries
    Button{
        id: btClear
        width: root.width/2
        x:     root.width/4

        text: i18n.tr("clear list")
        color: UbuntuColors.orange
        state: (listView.model.count>0) ? "on" : "off"
        states: [
            State{
                name: "off"
                PropertyChanges {target: btClear; y:root.parent.height}
            },
            State{
                name: "on"
                PropertyChanges {target: btClear; y:root.parent.height - height - units.gu(2)}
            }
        ]
        transitions: Transition {
            reversible: true
            from: "off"
            to: "on"
            PropertyAnimation{
                property: "y"
                duration: 400
            }
        }
        onClicked: {
            // remove all entries that were deleted last time
            dbcon.removeDeleted()
            // mark all entries which are currently in listView as deleted
            for (var i=listView.model.count-1;i>-1;i--){
                dbcon.markAsDeleted(listView.model.get(i).uid)
            }
            // (re)start timer to automatically delete items from database
            deleteTimer.restart()
        }
    }

    // a timer to finally delete list entries 10s after they have been marked as deledeletedEntries:
    Timer{
        id: deleteTimer
        interval: 10000
        onTriggered:{
            dbcon.removeDeleted()
        }
    }

    // Navigation buttons to switch between categories
    Button{
        id: btPrevious
        anchors{
            bottom: parent.bottom
            left: parent.left
            margins: units.gu(2)
        }
        height: units.gu(4)
        width:  units.gu(6)
        visible: sections.selectedIndex>0
        onClicked: sections.selectedIndex -= 1
        Icon{
            anchors.centerIn: parent
            height: 0.7*parent.height
            name: "previous"
            color: theme.palette.normal.baseText
        }
    }
    Button{
        id: btNext
        anchors{
            bottom: parent.bottom
            right: parent.right
            margins: units.gu(2)
        }
        height: units.gu(4)
        width:  units.gu(6)
        visible: sections.selectedIndex <sections.model.length-1
        onClicked: sections.selectedIndex += 1
        Icon{
            anchors.centerIn: parent
            height: 0.7*parent.height
            name: "next"
            color: theme.palette.normal.baseText
        }
    }
}
