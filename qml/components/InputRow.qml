import QtQuick 2.7
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3
import Ubuntu.Components.Popups 1.3

Row{
    id: root

    property string placeholderText: ""
    property string text: input.text
    property bool enabled: true

    property alias  quantity: quantitySelect.quantity
    property string dimension: quantitySelect.dimension ? quantitySelect.dimension.symbol : 'x'


    SortFilterModel{
        id: filterModel
        model: db_history.sortedKeyModel
        filter.property: "key"
        filter.pattern: new RegExp(input.text)
        filterCaseSensitivity: Qt.CaseInsensitive
    }

    signal accepted()
    function reset(){
        input.text = ""
        quantitySelect.reset()
    }

    property int dropDownRowHeight: units.gu(5)
    property int dropDownMaxRows: 5

    padding: units.gu(2)
    spacing: units.gu(1)

    QuantitySelect{
        id: quantitySelect
        enabled: root.enabled
    }

    TextField{
        id: input
        width: root.width - button.width - 2*inputRow.padding - units.gu(2) - quantitySelect.width
        placeholderText: root.placeholderText
        enabled: root.enabled
        onAccepted: root.accepted()

        onFocusChanged: {
            if (focus){
                quantitySelect.expanded = false
                if (text.length>0) dropDown.visible = true
            } else {
                dropDown.visible = false
            }
        }
        onTextChanged:  dropDown.visible = (db_history.active && text.length>0)
        inputMethodHints: Qt.ImhNoPredictiveText
        Rectangle{
            id: dropDown
            anchors{
                left:  input.left
                right: input.right
                top:   input.bottom
            }
            height: (dropDownList.model.count<dropDownMaxRows ? dropDownList.model.count : dropDownMaxRows)*dropDownRowHeight
            visible: false

            color: theme.palette.normal.field
            border.width: 1
            border.color: theme.palette.normal.base
            radius: units.gu(1)

            UbuntuListView{
                id: dropDownList
                anchors.fill: parent
                model: filterModel
                clip: true
                currentIndex: -1
                delegate: ListItem{
                    height: root.dropDownRowHeight
                    Label{
                        anchors.centerIn: parent
                        text: key
                    }
                    onClicked: {
                        input.text = key
                        dropDown.visible = false
                        if (db_history.acceptOnClick) root.accepted()
                    }
                }
            }
        }
    }

    Button{
        id: button
        color: theme.palette.normal.positive
        width: 1.6*height
        Icon{
            anchors.centerIn: parent
            height: 0.7*button.height
            name: "add"
            color: theme.palette.normal.positiveText
        }

        enabled: root.enabled
        onClicked: {
            quantitySelect.expanded = false
            root.accepted()
        }
    }
}
