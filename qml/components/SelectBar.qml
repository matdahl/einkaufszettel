import QtQuick 2.7
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.3

Item{
    id: root
    height: units.gu(5)

    // list of categories
    property var categories: []

    function refresh() {
        deleteAllButtons()
        var buttonComponent = Qt.createComponent("SelectBarButton.qml")
        for (var i=0;i<categories.length;i++){
            buttonComponent.createObject(row,{"text":categories[i],"height":root.height})
        }
    }
    function deleteAllButtons(){
        for (var i= row.children.length-1;i>=0;i--){
            row.children[i].destroy()
        }
    }


    Button{
        id: btBack
        height: parent.height
        width: units.gu(4)
        color: UbuntuColors.lightGrey
        anchors.left: parent.left
        anchors.top:  parent.top
        visible: row.width>parent.width
        iconName: "back"
    }
    Item{
        width: (row.width>parent.width) ? parent.width - btBack.width - btNext.width : parent.width
        x:     (row.width>parent.width) ? btBack.width : 0
        height: parent.height
        Row {
            id: row
        }
    }
    Button{
        id: btNext
        height: parent.height
        width: units.gu(4)
        color: UbuntuColors.lightGrey
        anchors.right: parent.right
        anchors.top:  parent.top
        visible: row.width>parent.width
        iconName: "next"
    }
}


