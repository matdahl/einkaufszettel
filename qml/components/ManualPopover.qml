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

            Label{
                id: lbTitle
                anchors{
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    topMargin: units.gu(2)
                }
                textSize: Label.Large
                font.bold: true
                text: i18n.tr("Einkaufszettel")
            }

            Rectangle{
                anchors{
                    fill: scrollView
                    margins: units.gu(-1)
                }
                radius: units.gu(1)
                color: theme.palette.normal.base
                opacity: 0.2
            }

            /* ---- manual content ---- */
            ScrollView{
                    id: scrollView
                    anchors{
                        top: lbTitle.bottom
                        left: parent.left
                        right: parent.right
                        margins: units.gu(2)
                    }
                    height: root.height - lbTitle.height - popoverFooter.height - units.gu(12)
                    Component.onCompleted: print("scroll height:",height)

                    Column{
                        id: contentCol
                        width: scrollView.width
                        spacing: units.gu(1)

                        ManualText{
                            text: "<b>" + i18n.tr("Welcome to Einkaufszettel!") + "</b><br><br>"
                                + i18n.tr("This app helps you to organise your shopping lists. Below you find the manual.")
                        }

                        ManualCaption{
                            title: i18n.tr("Categories")
                        }

                    }
                }


            /* ---- footer part of the manual ---- */
            Item{
                id: popoverFooter
                anchors{
                    top: scrollView.bottom
                    left: parent.left
                    right: parent.right
                    margins: units.gu(2)
                }
                height: units.gu(4)

                CheckBox{
                    id: cbShowOnStart
                    anchors{
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                    }
                    Component.onCompleted: checked = settings.showManualOnStart
                    onCheckedChanged: settings.showManualOnStart = checked
                }

                Label{
                    anchors{
                        verticalCenter: parent.verticalCenter
                        left: cbShowOnStart.right
                        right: btOK.left
                        leftMargin: units.gu(1)
                        rightMargin: units.gu(2)
                    }
                    text: i18n.tr("Show on start")
                }

                Button{
                    id: btOK
                    anchors{
                        verticalCenter: parent.verticalCenter
                        right: parent.right
                    }
                    color: UbuntuColors.orange
                    text: i18n.tr("OK")
                    onClicked: PopupUtils.close(popover)
                }
            }

            // insert empty item to ensure there is a bottom margin in the popover
            Item{
                anchors.top: popoverFooter.bottom
                width: scrollView.width
                height: units.gu(4)
            }
        }
    }
}
