import QtQuick 2.7
import Ubuntu.Components 1.3

Page {
    id: root

    header: PageHeader {
        StyleHints{backgroundColor: colors.currentHeader}

        title: i18n.tr("Shopping List")

        trailingActionBar.actions: [
            Action{
                iconName: "settings"
                onTriggered: {
                    pages.push(Qt.resolvedUrl("SettingsPage.qml"))
                }
            },
            Action{
                iconName: "select-none"
            //    visible: pages.currentItem.hasCheckedEntries
            //    onTriggered: stack.currentItem.deselectAll()
            }
        ]
    }
}
