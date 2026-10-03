pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.modules.launcher.items
import qs.modules.launcher.services

// The clipboard mode used to be a state on AppList. As its own list the history is built
// once and switching only changes its opacity, instead of rebuilding the delegate list.
StyledListView {
    id: root

    required property StyledTextField search
    required property var visibilities
    required property real maxHeight

    readonly property string actionPrefix: GlobalConfig.launcher.actionPrefix

    readonly property var _cache: ({ value: [] })

    function sameIds(a: var, b: var): bool {
        if (a.length !== b.length)
            return false;
        for (let i = 0; i < a.length; ++i)
            if (a[i].id !== b[i].id)
                return false;
        return true;
    }

    function results(): var {
        const prefix = root.actionPrefix;
        const q = root.search.text.slice((prefix + "clipboard ").length).toLowerCase();
        const src = q ? Clipboard.items.filter(item => item.preview.toLowerCase().includes(q)) : Clipboard.getSortedItems();
        if (root.sameIds(root._cache.value, src))
            return root._cache.value;
        root._cache.value = src;
        return root._cache.value;
    }

    spacing: Tokens.spacing.small
    orientation: Qt.Vertical
    implicitHeight: Math.max(0, Math.min(root.maxHeight, (Tokens.sizes.launcher.itemHeight + spacing) * Math.min(Config.launcher.maxShown, count) - spacing))
    cacheBuffer: Tokens.sizes.launcher.itemHeight * 2

    preferredHighlightBegin: 0
    preferredHighlightEnd: height
    highlightRangeMode: ListView.ApplyRange

    highlightFollowsCurrentItem: false
    highlight: StyledRect {
        radius: Tokens.rounding.large
        color: Colours.palette.m3onSurface
        opacity: 0.08

        y: root.currentItem?.y ?? 0
        implicitWidth: root.width
        implicitHeight: root.currentItem?.implicitHeight ?? 0

        Behavior on y {
            Anim {}
        }
    }

    model: ScriptModel {
        values: root.results()
        onValuesChanged: root.currentIndex = 0
    }

    delegate: ClipItem {
        list: root
    }

    StyledScrollBar.vertical: StyledScrollBar {
        flickable: root
    }

    // Read the history while the list is still hidden so its visible rows are ready.
    Component.onCompleted: Clipboard.reload()
}
