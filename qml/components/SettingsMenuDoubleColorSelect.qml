import QtQuick 2.7
import QtQuick.Controls 2.2
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3

/*
 * An item for the settings list which pushs a new subpage to the stack if clicked on
 */
ListItem{
    id: root

    property var model: [["#990000","#ff0000"],["#009900","#00ff00"],["#000099","#0000ff"]
                        ,["#990099","#ff00ff"],["#999900","#ffff00"]]

    onModelChanged: {
        // delete old childens
        for (var i=expandedRow.children.length-1;i>-1;i--){
            expandedRow.children[i].destroy()
        }
        // get number of buttons
        var n = model.length
        var w = (layout.width-(n-1)*expandedRow.spacing+0.5*expandedRow.leftPadding)/n

        // create buttons
        var component = Qt.createComponent("DoubleColorButton.qml");
        for (var i=0;i<n;i++){
            var obj = component.createObject(expandedRow)
            obj.width  = w
            obj.height = expandedRow.height - units.gu(1.5)
            obj.y      = units.gu(0.5)
            obj.index  = i
            obj.color1 = model[i][0]
            obj.color2 = model[i][1]
            obj.selected.connect(root.buttonClicked)
        }
    }

    function buttonClicked(index){
        root.expanded = false
        currentSelectedColor = index
    }

    property int collapsedHeight: units.gu(7)
    property int expandedHeight: units.gu(12)
    property bool expanded: false

    // the text to display on the item
    property string text: ""

    // states whether the switcher was checked
    property bool checked: false

    property int currentSelectedColor: 0

    states: [
        State{
            name: "collapsed"
            when: !expanded
            PropertyChanges {target: root; height: collapsedHeight}
        },
        State{
            name: "expanded"
            when: expanded
            PropertyChanges {target: root; height: expandedHeight}
        }
    ]

    transitions: Transition {
        reversible: true
        from: "collapsed"
        to:   "expanded"
        PropertyAnimation{
            property: "height"
            duration: 200
        }
    }
    ListItemLayout {
        id: layout
        anchors.left:  parent.left
        anchors.right: parent.right
        anchors.top:   parent.top
        height: parent.collapsedHeight

        title.text: root.text

        DoubleColorButton{
            id: bt
            onClicked: root.expanded = !root.expanded
            color1: model[currentSelectedColor][0]
            color2: model[currentSelectedColor][1]
        }
    }
    Row{
        id: expandedRow
        anchors {
            left:   layout.left
            right:  layout.right
        }
        height: root.expandedHeight - root.collapsedHeight
        y:      root.collapsedHeight
        leftPadding: units.gu(2)
        spacing: units.gu(0.5)
   }
}
