pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.services
import qs.utils
import qs.modules.launcher.services

Item {
    id: root

    property real areaWidth: 0
    property int currentIndex: -1
    property var visibilities: null
    property bool stretchTiles: true

    readonly property int tileWidth: Tokens.sizes.launcher.browseTileWidth
    readonly property int tileHeight: Tokens.sizes.launcher.browseTileHeight
    readonly property int gridSpacing: Tokens.spacing.medium
    readonly property int columns: Math.max(1, Math.floor((root.areaWidth + (root.stretchTiles ? root.gridSpacing : 0)) / (root.tileWidth + root.gridSpacing)))
    readonly property int cellWidth: root.stretchTiles ? Math.floor(root.areaWidth / root.columns) : root.tileWidth + root.gridSpacing
    readonly property int cellHeight: root.tileHeight + root.gridSpacing
    readonly property int rows: Math.max(0, Math.ceil(root.displayEntries.length / root.columns))

    property var entries: []
    property var otherApps: []
    property var dragKeys: []
    property string dragAnchor: ""
    property var previewKeys: null
    property string mergeKey: ""
    property string pendingMergeKey: ""
    property string dragImageKey: ""
    property string folderKey: ""
    property rect folderAnchor: Qt.rect(0, 0, 0, 0)
    property bool folderOpen: false

    readonly property var displayEntries: {
        if (!root.previewKeys)
            return root.entries;
        const byKey = {};
        for (const f of root.entries)
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

    signal launchRequested(var app)

    function slotOf(key: string): int {
        return root.displayEntries.findIndex(e => e.key === key);
    }

    function slotX(slot: int): real {
        return (Math.max(0, slot) % root.columns) * root.cellWidth + (root.stretchTiles ? (root.cellWidth - root.tileWidth) / 2 : 0);
    }

    function slotY(slot: int): real {
        return Math.floor(Math.max(0, slot) / root.columns) * root.cellHeight;
    }

    function sameEntries(a: var, b: var): bool {
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

    function sameIds(a: var, b: var): bool {
        if (a.length !== b.length)
            return false;
        for (let i = 0; i < a.length; ++i)
            if (a[i].id !== b[i].id)
                return false;
        return true;
    }

    function refresh(): void {
        const alpha = Apps.alphaApps;
        const favIds = GlobalConfig.launcher.favouriteApps ?? [];
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

        if (!root.sameEntries(root.entries, list))
            root.entries = list;
        if (!root.sameIds(root.otherApps, others))
            root.otherApps = others;
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

    function dragMove(wrapper: var, drag: var): void {
        if (!root.isInternal(drag))
            return;
        drag.accept(Qt.MoveAction);
        const fromKey = root.dragAnchor;
        const toKey = wrapper.key;
        if (fromKey === toKey)
            return;
        const fromEntry = root.entries.find(f => f.key === fromKey);
        const toEntry = root.entries.find(f => f.key === toKey);
        const canMerge = fromEntry && toEntry && fromEntry.kind === "app";

        if (canMerge && wrapper.overIcon(drag.x, drag.y)) {
            if (toEntry.kind === "folder") {
                mergeTimer.stop();
                root.pendingMergeKey = toKey;
                root.mergeKey = toKey;
                return;
            }
            if (root.mergeKey === toKey)
                return;
            if (root.pendingMergeKey !== toKey) {
                root.pendingMergeKey = toKey;
                mergeTimer.restart();
            }
            return;
        }

        if (root.pendingMergeKey === toKey) {
            mergeTimer.stop();
            root.pendingMergeKey = "";
        }
        if (root.mergeKey === toKey)
            root.mergeKey = "";

        const keys = root.entries.map(f => f.key);
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

    function dragExit(wrapper: var): void {
        if (root.pendingMergeKey === wrapper.key) {
            mergeTimer.stop();
            root.pendingMergeKey = "";
        }
        if (root.mergeKey === wrapper.key)
            root.mergeKey = "";
    }

    function dragBackground(): void {
        mergeTimer.stop();
        root.pendingMergeKey = "";
        root.mergeKey = "";
        root.previewKeys = null;
    }

    function drop(wrapper: var, drop: var): void {
        if (!root.isInternal(drop))
            return;
        drop.accept(Qt.MoveAction);
        const fromKey = root.dragAnchor;
        const toKey = wrapper.key;
        if (fromKey === toKey) {
            root.endDrag();
            return;
        }
        const fromEntry = root.entries.find(f => f.key === fromKey);
        const toEntry = root.entries.find(f => f.key === toKey);
        const canMerge = fromEntry && toEntry && fromEntry.kind === "app";
        const isMerge = canMerge && (root.mergeKey === toKey || root.pendingMergeKey === toKey || wrapper.overIcon(drop.x, drop.y));

        if (isMerge) {
            if (toEntry.kind === "app") {
                LauncherFavourites.makeFolder([fromKey], toKey);
                root.endDrag();
                return;
            }
            if (toEntry.kind === "folder") {
                LauncherFavourites.addToFolder(fromKey, toKey);
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
        mergeTimer.stop();
        root.pendingMergeKey = "";
        dragSource.Drag.active = false;
        root.dragImageKey = "";
        root.dragKeys = [];
        root.dragAnchor = "";
        root.previewKeys = null;
        root.mergeKey = "";
    }

    function openFolder(key: string, anchorItem: Item): void {
        const entry = root.entries.find(f => f.key === key);
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

    Timer {
        id: mergeTimer

        interval: 180
        onTriggered: {
            if (root.pendingMergeKey.length > 0)
                root.mergeKey = root.pendingMergeKey;
        }
    }

    FolderPopup {
        id: folderPopup

        anchors.fill: parent
        controller: root
        open: root.folderOpen
        folderKey: root.folderKey
        anchorRect: root.folderAnchor
        onClosed: root.folderKey = ""
    }
}
