import QtQuick 2.7
import Ubuntu.Components 1.3
import Ubuntu.Components.Pickers 1.3
import Ubuntu.Components.Popups 1.3

Button {
    id: root

    width: lbText.width + units.gu(2) > minWidth ? lbText.width + units.gu(2) : minWidth

    property int quantity: 1
    property var dimension

    property int quantityDigits: 4
    property int minWidth: units.gu(6)

    function reset(){
        quantity = 1
        dimensions.init()
        dimension = dimensions.unitsModel.get(0)
    }

    onClicked: PopupUtils.open(popoverComponent,root)

    Label{
        id: lbText
        anchors.centerIn: parent
        text: quantity + " " + (dimension ? dimension.symbol : "x")
    }

    Component{
        id: popoverComponent
        Popover{
            id: popover
            width: row.width

            function updateQuantity(){
                var q = 0
                for (var i=0; i<root.quantityDigits; i++)
                    q += quantityPickers.itemAt(i).selectedIndex * Math.pow(10,root.quantityDigits-i-1)
                root.quantity = q
            }

            function updateDimension(){
                root.dimension = dimensions.unitsModel.get(dimensionPicker.selectedIndex)
            }

            Row{
                id: row
                padding: units.gu(2)
                spacing: units.gu(1)
                Repeater{
                    id: quantityPickers
                    model: root.quantityDigits
                    delegate: Picker{
                        model: 9
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
            }
        }
    }
}
