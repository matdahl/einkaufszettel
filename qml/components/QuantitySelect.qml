import QtQuick 2.7
import Ubuntu.Components 1.3
import Ubuntu.Components.Pickers 1.3
import Ubuntu.Components.Popups 1.3

Button {
    id: root

    width: lbText.width + units.gu(2) > minWidth ? lbText.width + units.gu(2) : minWidth

    property int quantity: 1
    property int dimensionIndex: 0

    property int quantityDigits: 4
    property int minWidth: units.gu(6)

    function reset(){
        quantity = 1
        dimensionIndex = 0
        dimensions.init()
    }

    onClicked: PopupUtils.open(popoverComponent,root)

    Label{
        id: lbText
        anchors.centerIn: parent
        text: quantity + " " + dimensions.unitsModel.get(root.dimensionIndex).symbol
    }

    Component{
        id: popoverComponent
        Popover{
            id: popover
            width: row.width

            Component.onCompleted: {
                var q = root.quantity
                for (var i=0; i<root.quantityDigits; i++)
                    quantityPickers.itemAt(i).selectedIndex = (q / Math.pow(10,root.quantityDigits-i-1)) % 10
                dimensionPicker.selectedIndex = root.dimensionIndex
            }

            function updateQuantity(){
                var q = 0
                for (var i=0; i<root.quantityDigits; i++)
                    q += quantityPickers.itemAt(i).selectedIndex * Math.pow(10,root.quantityDigits-i-1)
                root.quantity = q
            }

            function updateDimension(){
                root.dimensionIndex = dimensionPicker.selectedIndex
            }

            Row{
                id: row
                padding: units.gu(2)
                spacing: units.gu(1)

                Row{
                    Repeater{
                        id: quantityPickers
                        model: root.quantityDigits
                        delegate: Picker{
                            model: 10
                            width: units.gu(4)
                            onSelectedIndexChanged: popover.updateQuantity()
                            delegate: PickerDelegate{
                                Label{
                                    anchors.centerIn: parent
                                    text: modelData
                                }
                            }
                        }
                    }
                }

                Rectangle{
                    anchors.verticalCenter: dimensionPicker.verticalCenter
                    height: dimensionPicker.height - units.gu(4)
                    width: units.gu(0.25)
                    color: theme.palette.normal.base
                }

                Picker{
                    id: dimensionPicker
                    model: dimensions.unitsModel
                    width: units.gu(6)
                    circular: false
                    onSelectedIndexChanged: popover.updateDimension()
                    delegate: PickerDelegate{
                        Label{
                            anchors.centerIn: parent
                            text: symbol
                        }
                    }
                }

                Button{
                    height: dimensionPicker.height
                    width: units.gu(7)
                    text: i18n.tr("OK")
                    color: UbuntuColors.orange
                    onClicked: PopupUtils.close(popover)
                }
            }
        }
    }
}
