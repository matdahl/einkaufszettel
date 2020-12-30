import QtQuick 2.7
import Ubuntu.Components 1.3
import Ubuntu.Components.Pickers 1.3

Button {
    id: root

    width: lbText.width + units.gu(2) > minWidth ? lbText.width + units.gu(2) : minWidth

    property int quantity
    property var dimension

    property int minWidth: units.gu(6)

    Component.onCompleted: reset()
    function reset(){
        expanded = false
        quantity = 1
        dimensions.init()
        dimension = dimensions.unitsModel.get(0)
    }
    onQuantityChanged: inputQuantity.text = quantity

    property bool expanded: false

    onEnabledChanged: if (!enabled) expanded = false
    //onFocusChanged: if (!focus && !inputQuantity.focus && !btUnit.focus && !unitsListView.focus) expanded = false

    onClicked: expanded = !expanded

    Label{
        id: lbText
        anchors.centerIn: parent
        text: quantity + " " + (dimension ? dimension.symbol : "x")
    }

    Rectangle{
        id: panel
        anchors{
            top:  parent.bottom
            left: parent.left
            topMargin: units.gu(1)
        }

        height: units.gu(4) + rowInc.height + rowInput.height + rowDec.height
        width:  root.parent.width - units.gu(4)
        visible: expanded
        radius: units.gu(1)
        color: theme.palette.normal.foreground
        border{
            width: 1
            color: theme.palette.normal.base
        }
        MouseArea{
            anchors.fill: parent
        }

        property int cellwidth: (width-units.gu(5))/4

        Button{
            anchors{
                top:    parent.top
                right:  parent.right
                bottom: parent.bottom
                margins: units.gu(1)
            }
            width: panel.cellwidth
            color: UbuntuColors.orange
            text: i18n.tr("OK")
            onClicked: root.expanded = false
        }

        Row{
            id: rowInc
            anchors{
                top: panel.top
                left: panel.left
                margins: units.gu(1)
            }

            spacing: units.gu(1)
            Button{
                id: btInc100
                width: panel.cellwidth
                color: theme.palette.normal.positive
                Label{
                    anchors.centerIn: parent
                    text: "+ 100"
                    color: theme.palette.normal.positiveText
                }
                onClicked: root.quantity += 100
            }
            Button{
                id: btInc10
                width: panel.cellwidth
                color: theme.palette.normal.positive
                Label{
                    anchors.centerIn: parent
                    text: "+ 10"
                    color: theme.palette.normal.positiveText
                }
                onClicked: root.quantity += 10
            }
            Button{
                id: btInc1
                width: panel.cellwidth
                color: theme.palette.normal.positive
                Label{
                    anchors.centerIn: parent
                    text: "+ 1"
                    color: theme.palette.normal.positiveText
                }
                onClicked: root.quantity += 1
            }
        }

        Row{
            id: rowDec
            anchors{
                top: rowInput.bottom
                left: panel.left
                margins: units.gu(1)
            }
            spacing: units.gu(1)
            Button{
                id: btDec100
                width: panel.cellwidth
                color: theme.palette.normal.negative
                Label{
                    anchors.centerIn: parent
                    text: "- 100"
                    color: theme.palette.normal.negativeText
                }
                onClicked: quantity = quantity>100 ? quantity-100 : 1
            }
            Button{
                id: btDec10
                width: panel.cellwidth
                color: theme.palette.normal.negative
                Label{
                    anchors.centerIn: parent
                    text: "- 10"
                    color: theme.palette.normal.negativeText
                }
                onClicked: quantity = quantity>10 ? quantity-10 : 1
            }
            Button{
                id: btDec1
                width: panel.cellwidth
                color: theme.palette.normal.negative
                Label{
                    anchors.centerIn: parent
                    text: "- 1"
                    color: theme.palette.normal.negativeText
                }
                onClicked: quantity = quantity>1 ? quantity-1 : 1
            }
        }

        Row{
            id: rowInput
            anchors{
                top: rowInc.bottom
                left: panel.left
                margins: units.gu(1)
            }
            spacing: units.gu(1)
            TextField{
                id: inputQuantity
                onTextChanged: {
                    if (text=="") text = "1"
                    root.quantity = text
                }

                validator: DoubleValidator{bottom: 0}
                width: 2*panel.cellwidth + units.gu(1)
                horizontalAlignment: Text.AlignRight
            }
            Button{
                id: btUnit
                width: panel.cellwidth
                property bool expanded: false
                onClicked: expanded = !expanded
                text: (root.dimension) ? root.dimension.symbol : 'x'

                onFocusChanged: if (!focus) expanded = false

                Rectangle{
                    id: unitsPanel
                    anchors.centerIn: parent
                    width: parent.width + units.gu(4)
                    height: units.gu(4)*((unitsListView.model.count<4)? unitsListView.model.count:4)
                    visible: btUnit.expanded

                    radius: units.gu(1)
                    color: theme.palette.highlighted.base

                    UbuntuListView{
                        id: unitsListView
                        anchors.fill: parent
                        currentIndex: -1
                        clip: true
                        model: dimensions.unitsModel
                        delegate: ListItem{
                            height: units.gu(4)
                            Label{
                                anchors.centerIn: parent
                                text: symbol + " - " + name
                            }
                            onClicked: {
                                root.dimension  = unitsListView.model.get(index)
                                btUnit.expanded = false
                            }
                        }
                    }
                }

            }
        }

    }
}
