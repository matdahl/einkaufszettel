import QtQuick 2.7
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3

Item {
    id: root
    anchors.fill: parent

    function show(){
        PopupUtils.open(popoverComponent,root)
    }

    Component{
        id: popoverComponent
        Popover{
            id: popover
            height: root.height
            Component.onCompleted: print("height:",height)

            Column{
                width: popover.contentWidth
                spacing: units.gu(2)
                padding: units.gu(2)
                ScrollView{
                    id: scrollView
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: popover.contentWidth - units.gu(6)

                 //   height: popover.height - checkRow.height - btOK.height - units.gu(8)
                    Component.onCompleted: print("scroll height:",height, popover.height,checkRow.height,btOK.height,units.gu(8))
                }
                Row{
                    id: checkRow
                    spacing: units.gu(2)
                    anchors.horizontalCenter: parent.horizontalCenter
                    CheckBox{
                        Component.onCompleted: checked = settings.showManualOnStart
                        onCheckedChanged: settings.showManualOnStart = checked
                    }
                    Label{
                        text: i18n.tr("Always show on start")
                    }
                }

                Button{
                    id: btOK
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: UbuntuColors.orange
                    text: i18n.tr("OK")
                    onClicked: PopupUtils.close(popover)
                }
            }
        }
    }
}
