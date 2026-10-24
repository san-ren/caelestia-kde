pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls as Controls
import qs.components.effects
import qs.services
import qs.modules.launcher.items

Item {
    id: root

    required property var controller
    property bool open: false
    property string folderKey: ""
    property rect anchorRect: Qt.rect(0, 0, 0, 0)

    readonly property var folder: root.controller.entries.find(f => f.key === root.shownId) ?? null
    readonly property string folderId: root.shownId.slice(2)
    readonly property var members: root.folder?.members ?? []
    readonly property int tileWidth: Tokens.sizes.launcher.browseTileWidth
    readonly property int tileHeight: Tokens.sizes.launcher.browseTileHeight
    readonly property int cellWidth: root.tileWidth + Tokens.spacing.medium
    readonly property int cellHeight: root.tileHeight + Tokens.spacing.medium
    readonly property int columns: 5
    readonly property int rows: Math.max(3, Math.ceil(root.members.length / root.columns))
    readonly property var displayMembers: {
        if (!root.memberPreview)
            return root.members;
        const byId = {};
        for (const m of root.members)
            byId[m.id] = m;
        const out = [];
        for (const id of root.memberPreview) {
            if (byId[id]) {
                out.push(byId[id]);
                delete byId[id];
            }
        }
        for (const id in byId)
            out.push(byId[id]);
        return out;
    }

    property string shownId: ""
    property real panelScale: 0.82
    property real panelOpacity: 0.0
    property bool animating: false
    property real dropOutMultiplier: root.dropOutHover ? 0.4 : 1.0
    property int memberIndex: -1
    property var memberPreview: null
    property var memberDragKeys: []
    property string memberDragAnchor: ""
    property bool dropOutHover: false
    property bool pendingRename: false

    signal closed()

    function selectTile(index: int): void {
        root.memberIndex = index;
    }

    function launch(app: var): void {
        root.controller.launchRequested(app);
    }

    function openContextMenu(app: var, item: Item): void {
        memberMenu.openFor(app, item);
    }

    function openFolderMenu(id: string, anchorItem: Item): void {
        folderMenu.openFor(id, anchorItem);
    }

    function refresh(): void {
        root.controller.refresh();
    }

    function beginMemberDrag(item: var, x: real, y: real): void {
        if (root.memberDragKeys.length > 0 || !item)
            return;
        const id = item.appId;
        root.memberDragKeys = [id];
        root.memberDragAnchor = id;
        memberDragWatchdog.restart();
        item.grabToImage(result => {
            if (root.memberDragAnchor !== id)
                return;
            memberDragSource.Drag.mimeData = { "application/x-caelestia-launcher-folder-members": id };
            memberDragSource.Drag.imageSource = result.url;
            memberDragSource.Drag.hotSpot = Qt.point(x, y);
            memberDragSource.Drag.active = true;
        });
    }

    function isInternal(drag: var): bool {
        return drag.source === memberDragSource && root.memberDragKeys.length > 0;
    }

    function memberDragMove(tile: var, drag: var): void {
        if (!root.isInternal(drag))
            return;
        drag.accept(Qt.MoveAction);
        const fromId = root.memberDragAnchor;
        const toId = tile.appId;
        if (fromId === toId)
            return;
        const ids = root.members.map(m => m.id);
        const from = ids.indexOf(fromId);
        const to = ids.indexOf(toId);
        if (from === -1 || to === -1)
            return;
        const before = drag.x < tile.width / 2;
        ids.splice(from, 1);
        let insert = to + (before ? 0 : 1);
        if (from < insert)
            insert--;
        ids.splice(insert, 0, fromId);
        root.memberPreview = ids;
    }

    function memberDrop(tile: var, drop: var): void {
        if (!root.isInternal(drop))
            return;
        drop.accept(Qt.MoveAction);
        if (root.memberPreview)
            LauncherFavourites.setMemberOrder(root.folderId, root.memberPreview);
        root.endMemberDrag();
    }

    function moveOut(toSlot: int): void {
        const slot = toSlot >= 0 ? toSlot : root.controller.entries.length;
        LauncherFavourites.moveOut(root.folderId, root.memberDragAnchor, slot);
        const stillFolder = LauncherFavourites.folderById(root.folderId);
        root.endMemberDrag();
        if (!stillFolder)
            root.controller.closeFolder();
    }

    function endMemberDrag(): void {
        memberDragWatchdog.stop();
        memberDragSource.Drag.active = false;
        root.memberDragKeys = [];
        root.memberDragAnchor = "";
        root.memberPreview = null;
        root.dropOutHover = false;
    }

    function finishClose(): void {
        root.memberPreview = null;
        root.memberIndex = -1;
        root.pendingRename = false;
        root.closed();
    }

    visible: root.open || root.animating || root.panelOpacity > 0

    onOpenChanged: {
        if (root.open) {
            root.shownId = root.folderKey;
            root.memberIndex = root.members.length > 0 ? 0 : -1;
            closeAnim.stop();
            if (root.controller.visibilities?.skipLauncherAnim) {
                root.panelScale = 1.0;
                root.panelOpacity = 1.0;
                root.animating = false;
                if (root.pendingRename) {
                    root.pendingRename = false;
                    title.startRename(root.folder?.name ?? "");
                }
            } else {
                root.animating = true;
                openAnim.restart();
            }
        } else {
            openAnim.stop();
            if (root.controller.visibilities?.skipLauncherAnim) {
                root.panelScale = 0.82;
                root.panelOpacity = 0.0;
                root.animating = false;
                root.finishClose();
            } else {
                root.animating = true;
                closeAnim.restart();
            }
        }
    }

    onFolderChanged: {
        if (root.open && root.shownId && !root.folder)
            root.controller.closeFolder();
    }

    ParallelAnimation {
        id: openAnim

        onFinished: {
            root.animating = false;
            if (root.pendingRename) {
                root.pendingRename = false;
                title.startRename(root.folder?.name ?? "");
            }
        }

        NumberAnimation {
            target: root
            property: "panelScale"
            from: root.panelScale < 0.82 ? 0.82 : root.panelScale
            to: 1.0
            duration: Tokens.anim.durations.expressiveDefaultSpatial
            easing: Tokens.anim.expressiveDefaultSpatial
        }

        NumberAnimation {
            target: root
            property: "panelOpacity"
            from: root.panelOpacity
            to: 1.0
            duration: Tokens.anim.durations.expressiveDefaultEffects
            easing: Tokens.anim.expressiveDefaultEffects
        }
    }

    SequentialAnimation {
        id: closeAnim

        onFinished: {
            root.animating = false;
            root.finishClose();
        }

        NumberAnimation {
            target: root
            property: "panelScale"
            to: 1.025
            duration: 75
            easing.type: Easing.OutQuad
        }

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "panelScale"
                to: 0.82
                duration: 180
                easing: Tokens.anim.emphasizedAccel
            }

            NumberAnimation {
                target: root
                property: "panelOpacity"
                to: 0.0
                duration: 180
                easing: Tokens.anim.expressiveFastEffects
            }
        }
    }

    Behavior on dropOutMultiplier {
        Anim {
            type: Anim.FastEffects
        }
    }

    Rectangle {
        id: scrim

        anchors.fill: parent
        color: "#000000"
        opacity: 0.3 * root.panelOpacity
        visible: opacity > 0
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.open
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: root.controller.closeFolder()
    }

    DropArea {
        anchors.fill: parent
        onEntered: drag => {
            if (!root.isInternal(drag))
                return;
            drag.accept(Qt.MoveAction);
            root.dropOutHover = true;
        }
        onExited: root.dropOutHover = false
        onDropped: drop => {
            if (!root.isInternal(drop))
                return;
            drop.accept(Qt.MoveAction);
            root.controller.dropOutMember(root, drop.x, drop.y);
        }
    }

    Elevation {
        id: panel

        readonly property real pad: Tokens.padding.large

        readonly property real targetX: Math.round(Math.max(pad, Math.min(root.width - width - pad, (root.width - width) / 2)))
        readonly property real targetY: Math.round(Math.max(pad, Math.min(root.height - height - pad, (root.height - height) / 2)))

        readonly property real anchorCenterX: root.anchorRect.width > 0 ? root.anchorRect.x + root.anchorRect.width / 2 : targetX + width / 2
        readonly property real anchorCenterY: root.anchorRect.height > 0 ? root.anchorRect.y + root.anchorRect.height / 2 : targetY + height / 2

        width: Math.min(root.width - pad * 2, root.columns * root.cellWidth + pad * 2)
        height: Math.min(root.height - pad * 2, title.height + Tokens.spacing.medium + root.rows * root.cellHeight + pad * 2)
        x: targetX
        y: targetY
        radius: Tokens.rounding.large
        level: 3
        opacity: root.panelOpacity * root.dropOutMultiplier
        transform: Scale {
            origin.x: panel.width / 2 + Math.max(-panel.width * 0.2, Math.min(panel.width * 0.2, (panel.anchorCenterX - (panel.targetX + panel.width / 2)) * 0.25))
            origin.y: panel.height / 2 + Math.max(-panel.height * 0.2, Math.min(panel.height * 0.2, (panel.anchorCenterY - (panel.targetY + panel.height / 2)) * 0.25))
            xScale: root.panelScale
            yScale: root.panelScale
        }

        Behavior on width {
            Anim {}
        }

        Behavior on height {
            Anim {}
        }

        StyledRect {
            anchors.fill: parent
            radius: parent.radius
            color: GlobalConfig.appearance.pitchBlack ? "#000000" : Qt.alpha(Colours.palette.m3surfaceContainer, 0.96)
            clip: true

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onPressed: root.endMemberDrag()
            }

            DropArea {
                anchors.fill: parent
                onDropped: drop => {
                    if (!root.isInternal(drop))
                        return;
                    drop.accept(Qt.MoveAction);
                    root.endMemberDrag();
                }
            }

            FolderTitle {
                id: title

                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: panel.pad
                width: Math.min(implicitWidth, parent.width - panel.pad * 2 - 40)
                text: root.folder?.name ?? ""
                onRenameRequested: title.startRename(root.folder?.name ?? "")
                onRenameCommitted: text => LauncherFavourites.renameFolder(root.folderId, text)
                onRenameCancelled: {}
            }

            Controls.IconButton {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: panel.pad - Tokens.padding.small
                anchors.rightMargin: panel.pad - Tokens.padding.small
                type: Controls.IconButton.Text
                icon: "folder_off"
                onClicked: {
                    LauncherFavourites.ungroup(root.folderId);
                    root.controller.closeFolder();
                }
            }

            Flickable {
                id: flick

                anchors.top: title.bottom
                anchors.topMargin: Tokens.spacing.medium
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: panel.pad
                anchors.rightMargin: panel.pad
                anchors.bottomMargin: panel.pad
                contentWidth: grid.width
                contentHeight: grid.height
                interactive: contentHeight > height
                clip: true

                Item {
                    id: grid

                    width: root.columns * root.cellWidth
                    height: root.rows * root.cellHeight

                    Repeater {
                        model: root.members

                        MemberTile {}
                    }
                }
            }
        }
    }

    AppContextMenu {
        id: memberMenu

        attachTo: root
        visibilities: root.controller.visibilities ?? null
    }

    Controls.Menu {
        id: folderMenu

        property string folderId: ""

        function openFor(id: string, targetItem: Item): void {
            folderId = id;
            attachTo = targetItem;
            expanded = true;
        }

        attachTo: root

        attachSideX: Controls.Menu.Left
        attachSideY: Controls.Menu.Top
        thisSideX: Controls.Menu.Left
        thisSideY: Controls.Menu.Bottom

        items: [
            Controls.MenuItem {
                text: qsTr("Rename")
                icon: "edit"
                onClicked: {
                    if (!LauncherFavourites.folderById(folderMenu.folderId))
                        return;
                    root.pendingRename = true;
                    root.controller.openFolder(LauncherFavourites.folderKey(folderMenu.folderId), folderMenu.attachTo);
                }
            },
            Controls.MenuItem {
                text: qsTr("Ungroup")
                icon: "folder_off"
                onClicked: {
                    if (!folderMenu.folderId)
                        return;
                    LauncherFavourites.ungroup(folderMenu.folderId);
                    root.controller.closeFolder();
                }
            }
        ]
    }

    Item {
        id: memberDragSource

        width: 1
        height: 1
        Drag.dragType: Drag.Automatic
        Drag.supportedActions: Qt.MoveAction
        Drag.proposedAction: Qt.MoveAction
        Drag.onDragFinished: root.endMemberDrag()
    }

    Timer {
        id: memberDragWatchdog

        interval: 500
        onTriggered: {
            if (root.memberDragKeys.length > 0 && !memberDragSource.Drag.active)
                root.endMemberDrag();
        }
    }

    component MemberTile: Item {
        id: tile

        required property var modelData
        required property int index

        readonly property string appId: tile.modelData?.id ?? ""
        readonly property int slot: {
            const idx = root.displayMembers.findIndex(m => m.id === tile.appId);
            return idx === -1 ? tile.index : idx;
        }

        readonly property int row: Math.floor(tile.slot / root.columns)
        readonly property int col: tile.slot % root.columns

        readonly property bool isDragged: root.memberDragKeys.indexOf(tile.appId) !== -1

        width: root.tileWidth
        height: root.tileHeight
        x: tile.col * root.cellWidth
        y: tile.row * root.cellHeight
        z: isDragged ? 2 : 1
        scale: isDragged ? 0.88 : 1.0
        opacity: isDragged ? 0.35 : 1.0

        Behavior on x {
            Anim {}
        }

        Behavior on y {
            Anim {}
        }

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

        AppTile {
            anchors.fill: parent
            modelData: tile.modelData
            index: tile.index
            selected: root.memberIndex === tile.index
            browser: root
            draggable: true
            onDragRequested: (x, y) => root.beginMemberDrag(tile, x, y)
        }

        DropArea {
            anchors.fill: parent
            onEntered: drag => root.memberDragMove(tile, drag)
            onPositionChanged: drag => root.memberDragMove(tile, drag)
            onDropped: drop => root.memberDrop(tile, drop)
        }
    }
}
