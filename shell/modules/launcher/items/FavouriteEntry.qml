pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.launcher.items

Item {
    id: root

    required property var modelData
    required property int index
    required property var controller
    required property var browser
    required property bool selected

    readonly property string key: root.modelData.key
    readonly property bool isFolder: root.modelData.kind === "folder"
    readonly property alias tile: loader.item

    property int flatIndex: index

    signal dragRequested(string key, real x, real y)

    function overIcon(x: real, y: real): bool {
        return y <= root.height * 0.78 && Math.abs(x - root.width / 2) <= root.width * 0.32;
    }

    implicitWidth: root.controller.tileWidth
    implicitHeight: root.controller.tileHeight
    opacity: root.controller.dragKeys.indexOf(root.key) !== -1 ? 0.4 : 1

    Behavior on opacity {
        Anim {
            type: Anim.FastEffects
        }
    }

    StyledRect {
        anchors.fill: parent
        anchors.margins: Tokens.spacing.extraSmall
        radius: Tokens.rounding.large
        color: Colours.palette.m3primary
        opacity: root.controller.mergeKey === root.key ? 0.18 : 0
        border.width: root.controller.mergeKey === root.key ? 2 : 0
        border.color: Colours.palette.m3primary

        Behavior on opacity {
            Anim {
                type: Anim.FastEffects
            }
        }
    }

    Loader {
        id: loader

        anchors.fill: parent
        sourceComponent: root.isFolder ? folderComponent : appComponent
    }

    Component {
        id: appComponent

        AppTile {
            modelData: root.modelData.entry
            index: root.flatIndex
            selected: root.selected
            browser: root.browser
            draggable: true
            onDragRequested: (x, y) => root.dragRequested(root.key, x, y)
        }
    }

    Component {
        id: folderComponent

        FolderTile {
            name: root.modelData.name
            members: root.modelData.members
            selected: root.selected
            draggable: true
            onDragRequested: (x, y) => root.dragRequested(root.key, x, y)
            onActivated: root.controller.openFolder(root.key, root)
            onContextMenuRequested: (x, y) => root.controller.openFolderContextMenu(root.key, root)
        }
    }

    DropArea {
        anchors.fill: parent
        onEntered: drag => root.controller.dragMove(root, drag)
        onPositionChanged: drag => root.controller.dragMove(root, drag)
        onExited: root.controller.dragExit(root)
        onDropped: drop => root.controller.drop(root, drop)
    }
}
