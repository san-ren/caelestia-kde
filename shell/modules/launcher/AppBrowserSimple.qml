pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.launcher.items
import qs.modules.launcher.services

Item {
    id: root

    required property DrawerVisibilities visibilities
    required property real maxWidth

    readonly property var currentItem: root.itemAt(root.currentIndex)
    readonly property int count: root.displayFavourites.length + root.others.length
    readonly property bool showSeparator: root.displayFavourites.length > 0 && root.others.length > 0

    readonly property int padding: Tokens.padding.large
    readonly property int tileWidth: Tokens.sizes.launcher.browseTileWidth
    readonly property int tileHeight: Tokens.sizes.launcher.browseTileHeight
    readonly property int gridSpacing: Tokens.spacing.medium
    readonly property int columns: Math.max(1, Math.floor((root.implicitWidth - root.padding * 2 + root.gridSpacing) / (root.tileWidth + root.gridSpacing)))
    readonly property int cellWidth: Math.floor((root.implicitWidth - root.padding * 2) / root.columns)
    readonly property int cellHeight: root.tileHeight + root.gridSpacing
    readonly property int favRows: Math.max(0, Math.ceil(root.displayFavourites.length / root.columns))

    property var favourites: []
    property var others: []
    property int currentIndex: 0

    property var dragKeys: []
    property string dragAnchor: ""
    property var previewKeys: null
    property string mergeKey: ""
    property string dragImageKey: ""

    property string folderKey: ""
    property rect folderAnchor: Qt.rect(0, 0, 0, 0)
    property bool folderOpen: false

    readonly property var displayFavourites: {
        if (!root.previewKeys)
            return root.favourites;
        const byKey = {};
        for (const f of root.favourites)
            byKey[f.key] = f;
        const out = [];
        for (const k of root.previewKeys) {
            if (byKey[k]) {
                out.push(byKey[k]);
                delete byKey[k];
            }
        }
        for (const k in byKey)
            out.push(byKey[k]);
        return out;
    }

    function favouriteIds(): list<string> {
        return GlobalConfig.launcher.favouriteApps ?? [];
    }

    function sameIds(a: var, b: var): bool {
        if (a.length !== b.length)
            return false;
        for (let i = 0; i < a.length; ++i)
            if (a[i].id !== b[i].id)
                return false;
        return true;
    }

    function sameFavourites(a: var, b: var): bool {
        if (a.length !== b.length)
            return false;
        for (let i = 0; i < a.length; ++i) {
            if (a[i].key !== b[i].key || (a[i].name ?? "") !== (b[i].name ?? ""))
                return false;
            const am = a[i].members ?? [];
            const bm = b[i].members ?? [];
            if (am.length !== bm.length)
                return false;
            for (let j = 0; j < am.length; ++j)
                if (am[j].id !== bm[j].id)
                    return false;
        }
        return true;
    }

    function refresh(): void {
        const alpha = Apps.alphaApps;
        const favIds = root.favouriteIds();
        const hiddenIds = GlobalConfig.launcher.hiddenApps ?? [];

        const isVisible = a => a && !Strings.testRegexList(hiddenIds, a.id);
        const isFav = a => isVisible(a) && Strings.testRegexList(favIds, a.id);

        const byId = {};
        for (const a of alpha)
            byId[a.id] = a;

        LauncherFavourites.reconcile(alpha.filter(isFav).map(a => a.id));

        const list = [];
        for (const e of LauncherFavourites.entries) {
            if (e.kind === "folder") {
                const members = e.apps.map(id => byId[id]).filter(a => isVisible(a));
                if (members.length >= 2)
                    list.push({ kind: "folder", id: e.id, key: LauncherFavourites.folderKey(e.id), name: e.name, members });
            } else if (isVisible(byId[e.id])) {
                list.push({ kind: "app", id: e.id, key: LauncherFavourites.appKey(e.id), entry: byId[e.id] });
            }
        }

        const placed = new Set(LauncherFavourites.appIds());
        for (const a of alpha) {
            if (isFav(a) && !placed.has(a.id))
                list.push({ kind: "app", id: a.id, key: LauncherFavourites.appKey(a.id), entry: a });
        }

        const others = alpha.filter(a => isVisible(a) && !isFav(a));

        if (!root.sameFavourites(root.favourites, list))
            root.favourites = list;
        if (!root.sameIds(root.others, others))
            root.others = others;

        if (root.currentIndex >= root.count)
            root.currentIndex = Math.max(0, root.count - 1);
    }

    function launch(app): void {
        Apps.launch(app);
        root.visibilities.launcher = false;
    }

    function selectTile(index: int): void {
        root.currentIndex = index;
    }

    function itemAt(index: int): Item {
        if (index < 0)
            return null;
        if (index < root.displayFavourites.length)
            return grid.headerItem?.favouriteRepeater?.itemAt(index) ?? null;
        return grid.itemAtIndex(index - root.displayFavourites.length) ?? null;
    }

    function moveBy(delta: int): void {
        if (root.count === 0)
            return;
        const from = root.currentIndex < 0 ? 0 : root.currentIndex;
        root.currentIndex = Math.max(0, Math.min(root.count - 1, from + delta));
        root.ensureVisible();
    }

    function incrementCurrentIndex(): void {
        root.moveBy(root.columns);
    }

    function decrementCurrentIndex(): void {
        root.moveBy(-root.columns);
    }

    function moveLeft(): void {
        root.moveBy(-1);
    }

    function moveRight(): void {
        root.moveBy(1);
    }

    function toggleFocus(): void {
        root.activateCurrent();
    }

    function activateCurrent(): void {
        const entry = root.displayFavourites[root.currentIndex];
        if (entry) {
            if (entry.kind === "folder")
                root.openFolder(entry.key, root.itemAt(root.currentIndex));
            else
                root.launch(entry.entry);
            return;
        }
        const item = root.currentItem;
        if (item?.modelData)
            root.launch(item.modelData);
    }

    function openContextMenu(app: DesktopEntry, targetItem: Item): void {
        contextMenu.openFor(app, targetItem);
    }

    function openFolder(key: string, anchorItem: Item): void {
        const entry = root.favourites.find(f => f.key === key);
        if (!entry || entry.kind !== "folder")
            return;
        root.folderKey = key;
        root.folderAnchor = anchorItem ? anchorItem.mapToItem(root, 0, 0, anchorItem.width, anchorItem.height) : Qt.rect(0, 0, 0, 0);
        root.folderOpen = true;
    }

    function openFolderContextMenu(key: string, targetItem: Item): void {
        const id = key.slice(2);
        if (!LauncherFavourites.folderById(id))
            return;
        folderPopup.openFolderMenu(id, targetItem);
    }

    function closeFolder(): void {
        root.folderOpen = false;
    }

    function isInternal(drag: var): bool {
        return drag.source === dragSource && root.dragKeys.length > 0;
    }

    function beginDrag(key: string, item: Item, x: real, y: real): void {
        if (root.dragKeys.length > 0 || !item)
            return;
        root.dragImageKey = key;
        root.dragKeys = [key];
        root.dragAnchor = key;
        dragWatchdog.restart();
        item.grabToImage(result => {
            if (root.dragImageKey !== key)
                return;
            dragSource.Drag.mimeData = { "application/x-caelestia-launcher-favourites": key };
            dragSource.Drag.imageSource = result.url;
            dragSource.Drag.hotSpot = Qt.point(x, y);
            dragSource.Drag.active = true;
        });
    }

    function favouriteDragMove(wrapper: var, drag: var): void {
        if (!root.isInternal(drag))
            return;
        drag.accept(Qt.MoveAction);
        const fromKey = root.dragAnchor;
        const toKey = wrapper.key;
        if (fromKey === toKey)
            return;
        const fromEntry = root.favourites.find(f => f.key === fromKey);
        const toEntry = root.favourites.find(f => f.key === toKey);
        if (fromEntry && toEntry && fromEntry.kind === "app" && toEntry.kind === "app" && wrapper.overIcon(drag.x, drag.y)) {
            root.mergeKey = toKey;
            root.previewKeys = null;
            return;
        }
        root.mergeKey = "";
        const keys = root.favourites.map(f => f.key);
        const from = keys.indexOf(fromKey);
        const to = keys.indexOf(toKey);
        if (from === -1 || to === -1)
            return;
        const before = drag.x < wrapper.width / 2;
        keys.splice(from, 1);
        let insert = to + (before ? 0 : 1);
        if (from < insert)
            insert--;
        keys.splice(insert, 0, fromKey);
        root.previewKeys = keys;
    }

    function favouriteDragExit(wrapper: var): void {
        if (root.mergeKey === wrapper.key)
            root.mergeKey = "";
    }

    function favouriteDragBackground(): void {
        root.mergeKey = "";
        root.previewKeys = null;
    }

    function favouriteDrop(wrapper: var, drop: var): void {
        if (!root.isInternal(drop))
            return;
        drop.accept(Qt.MoveAction);
        const fromKey = root.dragAnchor;
        const toKey = wrapper.key;
        if (fromKey === toKey) {
            root.endDrag();
            return;
        }
        if (root.mergeKey === toKey) {
            const fromEntry = root.favourites.find(f => f.key === fromKey);
            const toEntry = root.favourites.find(f => f.key === toKey);
            if (fromEntry && toEntry && fromEntry.kind === "app" && toEntry.kind === "app") {
                LauncherFavourites.makeFolder([fromKey], toKey);
                root.endDrag();
                return;
            }
        }
        if (root.previewKeys)
            LauncherFavourites.setOrder(root.previewKeys);
        root.endDrag();
    }

    function endDrag(): void {
        dragWatchdog.stop();
        dragSource.Drag.active = false;
        root.dragKeys = [];
        root.dragAnchor = "";
        root.previewKeys = null;
        root.mergeKey = "";
    }

    function ensureVisible(): void {
        if (root.currentIndex < 0)
            return;
        if (root.currentIndex < root.displayFavourites.length) {
            grid.contentY = grid.originY;
            return;
        }
        grid.positionViewAtIndex(root.currentIndex - root.displayFavourites.length, GridView.Contain);
    }

    function resetView(): void {
        root.currentIndex = 0;
        grid.cancelFlick();
        grid.contentY = grid.originY;
        root.closeFolder();
    }

    implicitWidth: Math.min(Tokens.sizes.launcher.browseWidth, root.maxWidth)
    implicitHeight: Tokens.sizes.launcher.browseMinHeight

    Component.onCompleted: {
        root.refresh();
        root.resetView();
    }

    Connections {
        function onListChanged(): void {
            root.refresh();
        }

        target: Apps
    }

    Connections {
        function onFavouriteAppsChanged(): void {
            root.refresh();
        }

        function onHiddenAppsChanged(): void {
            root.refresh();
        }

        target: GlobalConfig.launcher
    }

    Connections {
        function onChanged(): void {
            root.refresh();
        }

        target: LauncherFavourites
    }

    Connections {
        function onLauncherChanged(): void {
            if (root.visibilities.launcher)
                root.resetView();
        }

        target: root.visibilities
    }

    AppContextMenu {
        id: contextMenu

        attachTo: root
        visibilities: root.visibilities
    }

    GridView {
        id: grid

        anchors.fill: parent
        anchors.margins: root.padding
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: root.dragKeys.length === 0

        contentY: originY

        onOriginYChanged: {
            if (root.currentIndex === 0 && !grid.moving && !grid.dragging)
                grid.contentY = grid.originY;
        }

        cellWidth: root.cellWidth
        cellHeight: root.cellHeight
        currentIndex: -1
        highlightFollowsCurrentItem: false
        cacheBuffer: root.cellHeight * 4

        model: ScriptModel {
            values: root.others
        }

        header: Item {
            id: headerItem

            readonly property alias favouriteRepeater: favRepeater

            width: grid.width
            height: headerColumn.implicitHeight

            Column {
                id: headerColumn

                width: parent.width
                spacing: root.gridSpacing

                Item {
                    id: favGrid

                    width: grid.width
                    height: root.favRows * root.cellHeight

                    Repeater {
                        id: favRepeater

                        model: root.favourites

                        delegate: FavouriteEntry {
                            id: favEntry

                            readonly property int slot: root.displayFavourites.findIndex(f => f.key === favEntry.key)

                            browser: root
                            flatIndex: slot
                            dimmed: root.dragKeys.indexOf(favEntry.key) !== -1
                            mergeTarget: root.mergeKey === favEntry.key
                            x: (Math.max(0, slot) % root.columns) * root.cellWidth + (root.cellWidth - width) / 2
                            y: Math.floor(Math.max(0, slot) / root.columns) * root.cellHeight
                            onDragRequested: (key, x, y) => root.beginDrag(key, favEntry, x, y)

                            Behavior on x {
                                Anim {}
                            }

                            Behavior on y {
                                Anim {}
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width - Tokens.padding.medium * 2
                    height: 1
                    color: Colours.palette.m3outline
                    opacity: 0.5
                    visible: root.showSeparator

                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        delegate: Tile {
            flatIndex: root.displayFavourites.length + index
        }

        StyledScrollBar.vertical: StyledScrollBar {
            flickable: grid
        }
    }

    DropArea {
        anchors.fill: parent
        z: -1
        onEntered: drag => {
            if (root.isInternal(drag))
                root.favouriteDragBackground();
        }
        onPositionChanged: drag => {
            if (root.isInternal(drag))
                root.favouriteDragBackground();
        }
    }

    Item {
        id: dragSource

        width: 1
        height: 1
        Drag.dragType: Drag.Automatic
        Drag.supportedActions: Qt.MoveAction
        Drag.proposedAction: Qt.MoveAction
        Drag.onDragFinished: root.endDrag()
    }

    Timer {
        id: dragWatchdog

        interval: 500
        onTriggered: {
            if (root.dragKeys.length > 0 && !dragSource.Drag.active)
                root.endDrag();
        }
    }

    FolderPopup {
        id: folderPopup

        anchors.fill: parent
        browser: root
        open: root.folderOpen
        folderKey: root.folderKey
        anchorRect: root.folderAnchor
        onClosed: root.folderKey = ""
    }

    component Tile: Item {
        id: tileWrapper

        required property var modelData
        required property int index

        property int flatIndex: index
        property alias tile: innerTile

        implicitWidth: innerTile.implicitWidth
        implicitHeight: innerTile.implicitHeight

        AppTile {
            id: innerTile

            modelData: tileWrapper.modelData
            index: tileWrapper.flatIndex
            selected: root.currentIndex === tileWrapper.flatIndex
            browser: root
        }
    }
}
