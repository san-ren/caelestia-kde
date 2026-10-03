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

// The emoji mode used to be a state on AppList, which swapped the delegate and rebuilt
// the whole list on every switch: first with the previous mode's data, then again once
// the emoji model was ready. As its own list it is built once and switching only changes
// its opacity.
StyledListView {
    id: root

    required property StyledTextField search
    required property var visibilities
    required property real maxHeight

    readonly property string actionPrefix: GlobalConfig.launcher.actionPrefix

    // Keep the previous result array when the query has not changed: handing ScriptModel a
    // new array resets it and makes the ListView rebuild every visible row.
    readonly property var _cache: ({ key: "\u0000", value: [] })

    function currentQuery(): string {
        const prefix = root.actionPrefix + "emoji ";
        if (!root.search.text.startsWith(prefix))
            return "";
        return root.search.text.slice(prefix.length).toLowerCase();
    }

    function results(): var {
        const q = root.currentQuery();
        const key = q + "|" + ((GlobalConfig.launcher.favouriteEmojis || []).length);
        if (root._cache.key === key)
            return root._cache.value;
        const value = q ? Emojis.search(q) : Emojis.getSortedItems();
        root._cache.key = key;
        root._cache.value = value;
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

    delegate: EmojiItem {
        list: root
    }

    StyledScrollBar.vertical: StyledScrollBar {
        flickable: root
    }
}
