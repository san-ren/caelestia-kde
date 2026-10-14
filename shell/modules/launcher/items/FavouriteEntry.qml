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

    readonly property bool isDragged: root.controller.dragKeys.indexOf(root.key) !== -1
    readonly property bool isMergeTarget: root.controller.mergeKey === root.key

    property int flatIndex: index

    signal dragRequested(string key, real x, real y)

    function overIcon(x: real, y: real): bool {
        return y <= root.height * 0.78 && Math.abs(x - root.width / 2) <= root.width * 0.32;
    }

    implicitWidth: root.controller.tileWidth
    implicitHeight: root.controller.tileHeight

    scale: isDragged ? 0.88 : (isMergeTarget ? 1.08 : 1.0)
    opacity: isDragged ? 0.35 : 1.0
    z: isMergeTarget ? 3 : (isDragged ? 0 : 1)

    Behavior on scale {
        Anim {
            type: Anim.FastSpatial
        }
    }

    Behavior on opacity {
        Anim {
            type: Anim.FastEffects
        }
    }

    StyledRect {
        anchors.fill: parent
        anchors.margins: Tokens.spacing.extraSmall
        radius: Tokens.rounding.large
        color: Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.25)
        border.width: 1
        border.color: Qt.alpha(Colours.palette.m3outline, 0.4)
        opacity: root.isDragged ? 1 : 0

        Behavior on opacity {
            Anim {
                type: Anim.FastEffects
            }
        }
    }

    StyledRect {
        id: mergeHalo

        anchors.fill: parent
        anchors.margins: Tokens.spacing.extraSmall
        radius: Tokens.rounding.large
        color: Qt.alpha(Colours.palette.m3primaryContainer, 0.5)
        border.width: 2
        border.color: Colours.palette.m3primary
        opacity: root.isMergeTarget ? 1 : 0
        scale: root.isMergeTarget ? 1.0 : 0.88

        Behavior on opacity {
            Anim {
                type: Anim.FastEffects
            }
        }

        Behavior on scale {
            Anim {
                type: Anim.FastSpatial
            }
        }
    }

    Loader {
        id: loader

        anchors.fill: parent
        sourceComponent: root.isFolder ? folderComponent : appComponent
    }

    StyledRect {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Tokens.spacing.extraSmall
        anchors.rightMargin: Tokens.spacing.extraSmall
        width: 22
        height: 22
        radius: Tokens.rounding.full
        color: Colours.palette.m3primary
        opacity: root.isMergeTarget ? 1 : 0
        scale: root.isMergeTarget ? 1.0 : 0.4

        Behavior on opacity {
            Anim {
                type: Anim.FastEffects
            }
        }

        Behavior on scale {
            Anim {
                type: Anim.FastSpatial
            }
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: root.isFolder ? "add" : "create_new_folder"
            fontStyle: Tokens.font.icon.small
            color: Colours.palette.m3onPrimary
        }
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
            mergeTarget: root.isMergeTarget
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
