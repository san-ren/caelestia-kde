pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    property string name
    property var members: []
    property bool selected: false
    property bool draggable: false

    signal activated()
    signal dragRequested(real x, real y)
    signal contextMenuRequested(real x, real y)

    implicitWidth: Tokens.sizes.launcher.browseTileWidth
    implicitHeight: Tokens.sizes.launcher.browseTileHeight

    StyledRect {
        anchors.fill: parent
        anchors.margins: Tokens.spacing.extraSmall
        radius: Tokens.rounding.large
        color: Colours.palette.m3primary
        opacity: root.selected ? 0.14 : 0

        Behavior on opacity {
            Anim {
                type: Anim.StandardSmall
            }
        }
    }

    StateLayer {
        id: tileArea

        anchors.fill: parent
        radius: Tokens.rounding.large
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        dragEnabled: root.draggable
        onDragRequested: (x, y) => root.dragRequested(x, y)
        onClicked: mouse => {
            if (tileArea.dragSent)
                return;
            if (mouse.button === Qt.RightButton)
                root.contextMenuRequested(mouse.x, mouse.y);
            else
                root.activated();
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: Tokens.spacing.extraSmall

        StyledRect {
            id: card

            anchors.horizontalCenter: parent.horizontalCenter
            implicitWidth: Math.round(root.implicitWidth * 0.52)
            implicitHeight: implicitWidth
            radius: Tokens.rounding.large
            color: Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.85)

            Grid {
                anchors.centerIn: parent
                columns: 2
                spacing: card.implicitWidth * 0.08

                Repeater {
                    model: root.members.slice(0, 4)

                    IconImage {
                        required property var modelData

                        asynchronous: true
                        source: WinIcons.sourceFor(modelData, "", modelData?.id ?? "", 0)
                        width: card.implicitWidth * 0.36
                        height: card.implicitWidth * 0.36
                    }
                }
            }
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.name
            color: root.selected ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.large
            elide: Text.ElideRight
            maximumLineCount: 1
            width: root.implicitWidth - Tokens.padding.medium * 2
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
