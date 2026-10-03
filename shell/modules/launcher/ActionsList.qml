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

// The `>` command menu used to be a state on AppList: typing `>` created the whole list
// and built its rows frame by frame. As its own list it is built once and typing `>` only
// changes its opacity.
StyledListView {
    id: root

    required property StyledTextField search
    required property var visibilities
    required property real maxHeight

    readonly property string actionPrefix: GlobalConfig.launcher.actionPrefix
    readonly property var subModes: ["calc", "scheme", "variant", "emoji", "clipboard", "windows", "wallpaper", "keybinds", "animations"]

    readonly property var _cache: ({ key: "\u0000", value: [] })

    function currentQuery(): string {
        const prefix = root.actionPrefix;
        if (!root.search.text.startsWith(prefix))
            return "";
        for (const m of root.subModes) {
            if (root.search.text.startsWith(`${prefix}${m} `))
                return "";
        }
        return root.search.text.slice(prefix.length).trim().toLowerCase();
    }

    function results(): var {
        const q = root.currentQuery();
        if (root._cache.key === q)
            return root._cache.value;
        const value = Actions.query(q);
        root._cache.key = q;
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

    delegate: ActionItem {
        list: root
    }

    StyledScrollBar.vertical: StyledScrollBar {
        flickable: root
    }
}
