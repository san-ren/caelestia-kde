pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
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

    property string currentCategory: "favorites"
    property bool sidebarFocused: false
    property var visibleCategories: []
    property int favouriteIndex: 0

    readonly property bool showingFavourites: root.currentCategory === "favorites"
    readonly property var currentItem: root.showingFavourites ? favouriteGrid.itemAt(root.favouriteIndex) : grid.currentItem
    readonly property int count: root.showingFavourites ? favourites.displayEntries.length : grid.count
    readonly property bool folderOpen: favourites.folderOpen

    readonly property int padding: Tokens.padding.large
    readonly property int sidebarWidth: Tokens.sizes.launcher.browseSidebarWidth
    readonly property int tileCellWidth: Tokens.sizes.launcher.browseTileWidth + Tokens.spacing.medium
    readonly property int tileCellHeight: Tokens.sizes.launcher.browseTileHeight + Tokens.spacing.medium

    readonly property int columns: root.showingFavourites ? favourites.columns : Math.max(1, Math.floor((root.implicitWidth - root.sidebarWidth - root.padding * 2 - Tokens.spacing.medium) / root.tileCellWidth))
    readonly property int rows: root.showingFavourites ? favourites.rows : Math.ceil(root.count / root.columns)
    readonly property int rowHeight: root.showingFavourites ? favourites.cellHeight : root.tileCellHeight

    function sameItems(a: var, b: var): bool {
        if (a === b)
            return true;
        if (a.length !== b.length)
            return false;
        for (let i = 0; i < a.length; i++)
            if (a[i] !== b[i])
                return false;
        return true;
    }

    function refresh(): void {
        const all = Apps.allApps();
        const nextCategories = Categories.visibleCategories(all);
        favourites.refresh();
        if (!sameItems(root.visibleCategories, nextCategories))
            root.visibleCategories = nextCategories;
        const nextApps = root.showingFavourites ? [] : Categories.appsFor(root.currentCategory, all);
        if (!sameItems(gridModel.values, nextApps))
            gridModel.values = nextApps;
        if (root.favouriteIndex >= favourites.displayEntries.length)
            root.favouriteIndex = Math.max(0, favourites.displayEntries.length - 1);
    }

    function launch(app): void {
        Apps.launch(app);
        root.visibilities.launcher = false;
    }

    function selectTile(index: int): void {
        if (root.showingFavourites)
            root.favouriteIndex = index;
        else
            grid.currentIndex = index;
    }

    function selectCategory(id: string): void {
        root.currentCategory = id;
        root.sidebarFocused = false;
        const idx = root.visibleCategories.findIndex(d => d.id === id);
        sidebar.currentIndex = Math.max(0, idx);
        root.refresh();
        root.favouriteIndex = 0;
        favouriteView.contentY = 0;
        grid.currentIndex = grid.count > 0 ? 0 : -1;
    }

    function moveFavourite(delta: int): void {
        if (root.count === 0)
            return;
        root.favouriteIndex = Math.max(0, Math.min(root.count - 1, root.favouriteIndex + delta));
        const top = Math.floor(root.favouriteIndex / favourites.columns) * favourites.cellHeight;
        if (top < favouriteView.contentY)
            favouriteView.contentY = top;
        else if (top + favourites.cellHeight > favouriteView.contentY + favouriteView.height)
            favouriteView.contentY = top + favourites.cellHeight - favouriteView.height;
    }

    function incrementCurrentIndex(): void {
        if (root.sidebarFocused)
            sidebar.incrementCurrentIndex();
        else if (root.showingFavourites)
            root.moveFavourite(favourites.columns);
        else
            grid.moveCurrentIndexDown();
    }

    function decrementCurrentIndex(): void {
        if (root.sidebarFocused)
            sidebar.decrementCurrentIndex();
        else if (root.showingFavourites)
            root.moveFavourite(-favourites.columns);
        else
            grid.moveCurrentIndexUp();
    }

    function moveLeft(): void {
        if (root.sidebarFocused)
            return;
        if (root.showingFavourites) {
            if (root.favouriteIndex % favourites.columns === 0)
                root.sidebarFocused = true;
            else
                root.moveFavourite(-1);
            return;
        }
        const before = grid.currentIndex;
        grid.moveCurrentIndexLeft();
        if (grid.currentIndex === before)
            root.sidebarFocused = true;
    }

    function moveRight(): void {
        if (root.sidebarFocused)
            root.selectCategory(sidebar.currentItem?.modelData?.id ?? "favorites");
        else if (root.showingFavourites)
            root.moveFavourite(1);
        else
            grid.moveCurrentIndexRight();
    }

    function toggleFocus(): void {
        if (root.sidebarFocused)
            root.selectCategory(sidebar.currentItem?.modelData?.id ?? "favorites");
        else
            root.sidebarFocused = true;
    }

    function activateCurrent(): void {
        if (root.sidebarFocused) {
            root.selectCategory(sidebar.currentItem?.modelData?.id ?? "favorites");
            return;
        }
        if (root.showingFavourites) {
            const entry = favourites.displayEntries[root.favouriteIndex];
            if (entry) {
                if (entry.kind === "folder")
                    favourites.openFolder(entry.key, favouriteGrid.itemAt(root.favouriteIndex));
                else
                    root.launch(entry.entry);
                return;
            }
        }
        if (grid.currentItem?.modelData)
            root.launch(grid.currentItem.modelData);
    }

    function openContextMenu(app: DesktopEntry, targetItem: Item): void {
        contextMenu.openFor(app, targetItem);
    }

    function closeFolder(): void {
        favourites.closeFolder();
    }

    implicitWidth: Math.min(Tokens.sizes.launcher.browseWidth, root.maxWidth)
    implicitHeight: root.padding * 2 + (root.count === 0 ? root.rowHeight * 2 : root.rows * root.rowHeight)

    Component.onCompleted: {
        root.refresh();
        grid.currentIndex = grid.count > 0 ? 0 : -1;
        sidebar.currentIndex = 0;
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

    AppContextMenu {
        id: contextMenu

        attachTo: root
        visibilities: root.visibilities
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: Tokens.spacing.medium

        Item {
            Layout.preferredWidth: root.sidebarWidth
            Layout.fillHeight: true

            ListView {
                id: sidebar

                anchors.fill: parent

                model: root.visibleCategories
                spacing: Tokens.spacing.extraSmall
                clip: true

                currentIndex: 0
                highlightFollowsCurrentItem: false
                highlight: Item {}

                delegate: CategoryButton {
                    width: parent?.width ?? 0
                    selected: sidebar.currentIndex === index
                    onClicked: root.selectCategory(modelData.id)
                }
            }
        }

        Item {
            id: gridArea

            Layout.fillWidth: true
            Layout.fillHeight: true

            GridView {
                id: grid

                anchors.fill: parent
                visible: !root.showingFavourites

                model: ScriptModel {
                    id: gridModel

                    values: []
                    onValuesChanged: grid.currentIndex = grid.count > 0 ? 0 : -1
                }

                cellWidth: root.tileCellWidth
                cellHeight: root.tileCellHeight
                clip: true

                currentIndex: -1
                highlightFollowsCurrentItem: false
                cacheBuffer: root.tileCellHeight * 4

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: grid
                }

                delegate: AppTile {
                    browser: root
                    selected: grid.currentIndex === index
                }
            }

            Flickable {
                id: favouriteView

                anchors.fill: parent
                visible: root.showingFavourites
                contentWidth: width
                contentHeight: favouriteGrid.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: favourites.dragKeys.length === 0

                FavouritesGrid {
                    id: favouriteGrid

                    controller: favourites
                    browser: root
                    currentIndex: root.favouriteIndex
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: Tokens.spacing.medium
                visible: root.count === 0

                MaterialIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "apps"
                    color: Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.extraLarge
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("No apps in this category")
                    color: Colours.palette.m3outline
                    font: Tokens.font.body.builders.large.weight(Font.Medium).build()
                }
            }
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
        areaWidth: gridArea.width
        currentIndex: root.favouriteIndex
        stretchTiles: false
        visibilities: root.visibilities
        onLaunchRequested: app => root.launch(app)
    }
}
