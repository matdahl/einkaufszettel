import QtQuick 2.7
import Ubuntu.Components 1.3

Item {
    id: root
    property var dbcon

    signal categoriesChanged()

    function refresh(){
        listView.model.clear()
        var rows = dbcon.selectCategories()
        if (rows){
            for (var i=0;i<rows.length;i++){
                listView.model.append(rows[i])
            }
        }
    }

    Label{
        id: title
        x: units.gu(2)
        y: units.gu(2)
        textSize: Label.Large
        text: i18n.tr("edit categories:")
    }
    Row{
        id: inputRow
        padding: units.gu(2)
        spacing: units.gu(2)
        anchors.top: title.bottom
        TextField{
            id: inputCategory
            width: root.width - btNewCategory.width - 2*inputRow.padding - inputRow.spacing
            placeholderText: i18n.tr("new category ...")
            onAccepted: btNewCategory.clicked()
        }
        Button{
            id: btNewCategory
            color: UbuntuColors.green
            width: 1.6*height
            iconName: "add"
            onClicked: {
                if (inputCategory.text !== ""){
                    dbcon.insertCategory(inputCategory.text)
                    inputCategory.text = ""
                    root.refresh()
                    categoriesChanged()
                }
            }
        }
    }
    UbuntuListView{
        id: listView
        anchors{
            top:    inputRow.bottom
            bottom: root.bottom
            left:   root.left
            right:  root.right
        }
        currentIndex: -1
        model: ListModel{}
        delegate: ListItem{
            leadingActions: ListItemActions{ actions: [
                Action{
                    iconName: "delete"
                    onTriggered: {
                        dbcon.deleteCategory(listView.model.get(index).name)
                        root.refresh()
                        categoriesChanged()
                    }
                }
            ]}
            Label{
                anchors.centerIn: parent
                text: name
            }
            MouseArea{
                id: mouseDown
                visible: index<listView.model.count-1
                anchors{
                    top: parent.top
                    left: parent.left
                    bottom: parent.bottom
                }
                width: 1.5*height
                Icon{
                    name: "down"
                    height: units.gu(3)
                    anchors.centerIn: parent
                }
                onClicked:  {
                    dbcon.swapCategories(listView.model.get(index).name,listView.model.get(index+1).name)
                    root.refresh()
                    categoriesChanged()
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
                width: 1.5*height
                Icon{
                    name: "up"
                    height: units.gu(3)
                    anchors.centerIn: parent
                }
                onClicked: {
                    dbcon.swapCategories(listView.model.get(index).name,listView.model.get(index-1).name)
                    root.refresh()
                    categoriesChanged()
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
}
