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
    required property var browser

    readonly property string key: root.modelData.key
    readonly property bool isFolder: root.modelData.kind === "folder"
    readonly property alias tile: loader.item

    property int flatIndex: index
    property bool mergeTarget: false
    property bool dimmed: false

    signal dragRequested(string key, real x, real y)

    function overIcon(x: real, y: real): bool {
        return y <= root.height * 0.78 && Math.abs(x - root.width / 2) <= root.width * 0.32;
    }

    implicitWidth: Tokens.sizes.launcher.browseTileWidth
    implicitHeight: Tokens.sizes.launcher.browseTileHeight
    opacity: root.dimmed ? 0.4 : 1

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
        opacity: root.mergeTarget ? 0.18 : 0
        border.width: root.mergeTarget ? 2 : 0
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
            selected: root.browser.currentIndex === root.flatIndex
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
            selected: root.browser.currentIndex === root.flatIndex
            draggable: true
            onDragRequested: (x, y) => root.dragRequested(root.key, x, y)
            onActivated: root.browser.openFolder(root.key, root)
            onContextMenuRequested: (x, y) => root.browser.openFolderContextMenu(root.key, root)
        }
    }

    DropArea {
        anchors.fill: parent
        onEntered: drag => root.browser.favouriteDragMove(root, drag)
        onPositionChanged: drag => root.browser.favouriteDragMove(root, drag)
        onExited: root.browser.favouriteDragExit(root)
        onDropped: drop => root.browser.favouriteDrop(root, drop)
    }
}
