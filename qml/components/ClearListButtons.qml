import QtQuick 2.7
import Lomiri.Components 1.3

Item{
    id: root
    anchors.fill: parent

    signal removeAll()
    signal removeSelected()
    signal removeDeleted()
    signal restoreDeleted()

    property bool hasItems: false
    property bool hasDeletedItems: false
    property bool hasCheckedItems: false

    /*!
     * the time range in milliseconds for how long the last delete operation can be undone
     */
    property int restoreTimeout: 10000

    // button to restore entries which where previously deleted
    Button{
        id: btRestore
        width: 0.4*root.width
        x:     0.3*root.width

        iconName: "undo"
        color: theme.palette.normal.base

        state: hasDeletedItems ? btClear.state=="on" ? "on2" : "on1" : "off"
        states: [
            State{
                name: "off"
                PropertyChanges {target: btRestore; y: root.parent.height}
            },
            State{
                name: "on1"
                PropertyChanges {target: btRestore; y: root.parent.height - height - units.gu(2)}
            },
            State{
                name: "on2"
                PropertyChanges {target: btRestore; y: root.parent.height - height - btClear.height - units.gu(4)}
            }
        ]
        transitions: [
            Transition {
                reversible: true
                from: "off"
                to: "on2"
                PropertyAnimation{
                    property: "y"
                    duration: 800
                }
            },
            Transition {
                reversible: true
                from: "off"
                to: "on1"
                PropertyAnimation{
                    property: "y"
                    duration: 400
                }
            },
            Transition {
                reversible: true
                from: "on1"
                to: "on2"
                PropertyAnimation{
                    property: "y"
                    duration: 400
                }
            }
        ]
        onClicked: restoreDeleted()
    }

    // button to delete all currently displayed entries
    Button{
        id: btClear
        width: root.width/2
        x:     root.width/4

        text: hasCheckedItems ? i18n.tr("delete selected") : i18n.tr("clear list")
        color: LomiriColors.orange
        state: hasItems ? "on" : "off"
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
            removeDeleted()
            // mark all entries which are currently in listView as deleted
            if (hasCheckedItems){
                removeSelected()
            } else {
                removeAll()
            }
            //for (var i=listView.model.count-1;i>-1;i--){
            //    dbcon.markAsDeleted(listView.model.get(i).uid)
            //}
            // (re)start timer to automatically delete items from database
            deleteTimer.restart()
        }
    }

    // a timer to finally delete list entries 10s after they have been marked as deledeletedEntries:
    Timer{
        id: deleteTimer
        interval: restoreTimeout
        onTriggered:{
            removeDeleted()
        }
    }

}
