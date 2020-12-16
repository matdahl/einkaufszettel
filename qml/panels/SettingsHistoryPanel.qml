import QtQuick 2.7
import Ubuntu.Components 1.3

Item {
    id: root

    // the database connector
    property var db_histo

    property string headerSuffix: i18n.tr("History")
    onVisibleChanged: {
        if (visible) {
            refresh()
            if (db_histo.deleteFlag) db_histo.deleteAllKeys()
        }
    }

    function refresh(){
        model.clear()
        var rows = db_histo.selectKeys()
        if (rows){
            for (var i=0;i<rows.length;i++){
                model.append(rows[i])
            }
        }
    }

    property var model: ListModel{}
    SortFilterModel{
        id: filterModel
        model: root.model
        sort.property: "key"
        sort.order: Qt.AscendingOrder
        sortCaseSensitivity: Qt.CaseInsensitive
    }

    UbuntuListView{
        id: listView
        anchors.fill: parent
        currentIndex: -1
        model: filterModel
        delegate: ListItem{
            leadingActions: ListItemActions{ actions: [
                Action{
                    iconName: "delete"
                    onTriggered: {
                        db_histo.deleteKey(key)
                        root.refresh()
                    }
                }
            ]}
            Label{
                id: lbKey
                anchors.fill: parent
                verticalAlignment:   Label.AlignVCenter
                horizontalAlignment: Label.AlignHCenter
                text: key
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

        state: (db_histo.deleteFlag) ? "on" : "off"
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
        onClicked: {
            db_histo.restore()
            root.refresh()
        }
    }

    // button to delete all entries from history
    Button{
        id: btClear
        width: root.width/2
        x:     root.width/4

        text: i18n.tr("delete history")
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
            db_histo.markAllForDelete()
            root.refresh()
        }
    }
    Label{
        anchors.centerIn: parent
        text: "("+i18n.tr("No entries") +")"
        visible: listView.model.count===0
    }
}
