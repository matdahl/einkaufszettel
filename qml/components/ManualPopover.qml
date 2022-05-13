import QtQuick 2.7
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3

Item {
    id: root

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
                    topMargin: units.gu(-1)
                    bottomMargin: units.gu(-1)
                    margins: units.gu(-2)
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
                        margins: units.gu(3)
                    }
                    height: root.parent.height - lbTitle.height - popoverFooter.height - units.gu(14)

                    Column{
                        id: contentCol
                        width: scrollView.width
                        spacing: units.gu(1)

                        ManualText{
                            text: "<b>" + i18n.tr("Welcome to Einkaufszettel!") + "</b>"
                        }
                        ManualText{
                            text: i18n.tr("This app helps you to organise your shopping lists.")
                        }

                        ManualText{
                            text: i18n.tr("Just enter new items in the text field on the top of the list. "
                                          +"The new item is automatically added to the currently selected category. "
                                          +"When you've put an item into your cart, you can select it and "
                                          +"remove all items that you bought by clicking '%1'.").arg(i18n.tr("delete selected"))
                        }

                        ManualCaption{
                            title: i18n.tr("Categories")
                        }

                        ManualText{
                            text: i18n.tr("You can organise different items separately by defining costum categories in the settings. "
                                          +"Each category has its own list, so that items can be managed clearly and arranged by topics. "
                                          +"In addition to costum categories, there are always two default categories, that can't be edited:")
                        }
                        ManualText{
                            text: i18n.tr("%1: In this list, the items from all categories are shown.").arg("<i>"+i18n.tr("all")+"</i>")
                        }
                        ManualText{
                            text: i18n.tr("%1: In this list, all items that do not belong to any other category are shown. If you delete a category that still has items in it, they will also end up here.").arg("<i>"+i18n.tr("other")+"</i>")
                        }

                        ManualCaption{
                            title: i18n.tr("Suggestions")
                        }

                        ManualText{
                            text: i18n.tr("Based on your previous entries, you can get suggestions when typing new entries, filtered by your input and sorted by the frequency, you used an entry before. "
                                          +"This makes it more convenient to input items that you frequently buy. "
                                          +"You can manage the history, that is used to generate suggestions in the settings and remove items from there. "
                                          +"If you don't like the suggestions, you can also disable this feature entirely.")
                        }

                        ManualCaption{
                            title: i18n.tr("Units")
                        }

                        ManualText{
                            text: i18n.tr("To manage the amount you need from a certain item, you can use units. "
                                          +"By default, you always enter one 'piece of' the item. If you enter an item, that exists already in the list, the specified amount of the item will be added to the existing entry.")
                        }

                        ManualCaption{
                            title: i18n.tr("Appearance")
                        }

                        ManualText{
                            text: i18n.tr("You can choose between a dark or a light appearance and select from 8 different color flavours. "
                                         +"The default setting is the magenta flavoured dark mode. "
                                         +"You can change the appearance in the settings if you prefer an other flavour.")
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
