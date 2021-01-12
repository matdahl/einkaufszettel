import QtQuick 2.7
import Ubuntu.Components 1.3

Item {
    id: root
    property string headerSuffix: i18n.tr("Units")
    property var dimensions

    Component.onCompleted: refresh()

    function refresh(){
        listView.model.clear()
        var rows = dimensions.select()
        if (rows){
            for (var i=0;i<rows.length;i++){
                listView.model.append(rows[i])
            }
        }
    }

    // the flag if check boxes are shown
    property bool checkMode: false

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
                    root.refresh()
                }
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
        model: ListModel{}
        delegate: ListItem{
            leadingActions: ListItemActions{ actions: [
                Action{
                    iconName: "delete"
                    onTriggered: {
                        dimensions.remove(uid)
                        root.refresh()
                    }
                    // the unit "piece" is not deletable
                    visible: symbol !=="x"
                }
            ]}

            Rectangle{
                anchors.fill: parent
                color: theme.palette.normal.positive
                opacity: 0.2
                visible: marked && symbol !=="x"
            }

            CheckBox{
                id: checkBox
                anchors{
                    right: mouseUp.left
                    verticalCenter: parent.verticalCenter
                    margins: units.gu(2)
                }
                visible: root.checkMode && symbol !=="x"
                checked: marked
                onTriggered: {
                    dimensions.toggleMarked(uid)
                    marked = 1-marked
                }
            }

            Label{
                id: lbName
                anchors.verticalCenter: parent.verticalCenter
                x: 0.4*parent.width
                text: name
            }
            Label{
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: lbName.left
                anchors.margins: units.gu(2)
                text: "<b>"+symbol+"</b>"
                horizontalAlignment: Label.AlignRight
            }
            MouseArea{
                id: mouseDown
                // the unit "piece" is not movable
                visible: index<listView.model.count-1 && symbol !== "x"
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
                    dimensions.swapCategories(uid,listView.model.get(index+1).uid)
                    root.refresh()
                }
            }
            MouseArea{
                id: mouseUp
                visible: index>1
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
                    dimensions.swap(uid,listView.model.get(index-1).uid)
                    root.refresh()
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
    Label{
        anchors.centerIn: parent
        text: "("+i18n.tr("No entries") +")"
        visible: listView.model.count===0
    }
}
