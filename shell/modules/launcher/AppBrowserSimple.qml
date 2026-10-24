pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.launcher.items
import qs.modules.launcher.services

Item {
    id: root

    required property DrawerVisibilities visibilities
    required property real maxWidth

    readonly property var currentItem: root.itemAt(root.currentIndex)
    readonly property int count: favourites.displayEntries.length + favourites.otherApps.length
    readonly property bool showSeparator: favourites.displayEntries.length > 0 && favourites.otherApps.length > 0
    readonly property bool folderOpen: favourites.folderOpen

    readonly property int padding: Tokens.padding.large

    property int currentIndex: 0

    function refresh(): void {
        favourites.refresh();
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
        if (index < favourites.displayEntries.length)
            return grid.headerItem ? grid.headerItem.favouriteAt(index) : null;
        return grid.itemAtIndex(index - favourites.displayEntries.length) ?? null;
    }

    function moveBy(delta: int): void {
        if (root.count === 0)
            return;
        const from = root.currentIndex < 0 ? 0 : root.currentIndex;
        root.currentIndex = Math.max(0, Math.min(root.count - 1, from + delta));
        root.ensureVisible();
    }

    function incrementCurrentIndex(): void {
        root.moveBy(favourites.columns);
    }

    function decrementCurrentIndex(): void {
        root.moveBy(-favourites.columns);
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
        const entry = favourites.displayEntries[root.currentIndex];
        if (entry) {
            if (entry.kind === "folder")
                favourites.openFolder(entry.key, root.itemAt(root.currentIndex));
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

    function closeFolder(): void {
        favourites.closeFolder();
    }

    function ensureVisible(): void {
        if (root.currentIndex < 0)
            return;
        if (root.currentIndex < favourites.displayEntries.length) {
            grid.contentY = grid.originY;
            return;
        }
        grid.positionViewAtIndex(root.currentIndex - favourites.displayEntries.length, GridView.Contain);
    }

    function resetView(): void {
        root.currentIndex = 0;
        grid.cancelFlick();
        grid.contentY = grid.originY;
        favourites.closeFolder();
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
        interactive: favourites.dragKeys.length === 0

        contentY: originY

        onOriginYChanged: {
            if (root.currentIndex === 0 && !grid.moving && !grid.dragging)
                grid.contentY = grid.originY;
        }

        cellWidth: favourites.cellWidth
        cellHeight: favourites.cellHeight
        currentIndex: -1
        highlightFollowsCurrentItem: false
        cacheBuffer: favourites.cellHeight * 4

        model: ScriptModel {
            values: favourites.otherApps
        }

        header: Item {
            id: headerItem

            function favouriteAt(index: int): Item {
                return favGrid.itemAt(index);
            }

            width: grid.width
            height: headerColumn.implicitHeight

            Column {
                id: headerColumn

                width: parent.width
                spacing: favourites.gridSpacing

                FavouritesGrid {
                    id: favGrid

                    controller: favourites
                    browser: root
                    currentIndex: root.currentIndex
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
            flatIndex: favourites.displayEntries.length + index
        }

        StyledScrollBar.vertical: StyledScrollBar {
            flickable: grid
        }
    }

    DropArea {
        anchors.fill: parent
        z: -1
        onEntered: drag => {
            if (favourites.isInternal(drag))
                favourites.dragBackground();
        }
        onPositionChanged: drag => {
            if (favourites.isInternal(drag))
                favourites.dragBackground();
        }
    }

    FavouritesController {
        id: favourites

        anchors.fill: parent
        areaWidth: grid.width
        currentIndex: root.currentIndex
        visibilities: root.visibilities
        gridItem: favGrid
        onLaunchRequested: app => root.launch(app)
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
