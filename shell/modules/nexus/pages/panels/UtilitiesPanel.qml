pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property var connectivityToggles: [
        { id: "wifi", label: qsTr("Wi-Fi") },
        { id: "hotspot", label: qsTr("Hotspot") },
        { id: "bluetooth", label: qsTr("Bluetooth") },
        { id: "vpn", label: qsTr("VPN") },
        { id: "quickShare", label: qsTr("Quick Share") }
    ]
    readonly property var toolToggles: [
        { id: "settings", label: qsTr("Settings") },
        { id: "colorpicker", label: qsTr("Color Picker") },
        { id: "launcher", label: qsTr("Launcher") },
        { id: "overview", label: qsTr("Overview") },
        { id: "dashboard", label: qsTr("Dashboard") },
        { id: "wallpaper", label: qsTr("Wallpaper") },
    ]
    readonly property var systemToggles: [
        { id: "mic", label: qsTr("Microphone") },
        { id: "dnd", label: qsTr("Do Not Disturb") },
        { id: "gameMode", label: qsTr("Game Mode") },
        { id: "pauseWallpaper", label: qsTr("Pause Wallpaper") },
        { id: "visualiser", label: qsTr("Audio Visualiser") },
        { id: "nightlight", label: qsTr("Night Light") },
        { id: "easyeffects", label: qsTr("EasyEffects") },
        { id: "restartShell", label: qsTr("Restart Shell") }
    ]

    readonly property var allToggleDefs: [...root.connectivityToggles, ...root.toolToggles, ...root.systemToggles]
    readonly property bool customOrder: Config.utilities.quickTogglesCustomOrder ?? false
    readonly property var orderedIds: {
        const labels = {};
        root.allToggleDefs.forEach(d => {
            labels[d.id] = d.label;
        });
        const stored = Config.utilities.quickToggles || [];
        if (root.customOrder) {
            const known = stored.filter(t => t.id in labels).map(t => t.id);
            const knownSet = new Set(known);
            const missing = root.allToggleDefs.filter(d => !knownSet.has(d.id)).map(d => d.id);
            return [...known, ...missing];
        }
        const storedOrder = {};
        stored.forEach((t, i) => {
            storedOrder[t.id] = i;
        });
        return [...root.connectivityToggles, ...root.toolToggles, ...root.systemToggles]
            .map((d, i) => ({ id: d.id, i: i }))
            .sort((a, b) => ((storedOrder[a.id] ?? 9999) - (storedOrder[b.id] ?? 9999)) || (a.i - b.i))
            .map(entry => entry.id);
    }

    property string expandedId: ""

    readonly property QuickToggleSettings toggleSettings: QuickToggleSettings {
        nState: root.nState
        onTargetsRequested: targetsDialog.open()
    }

    function toggleLabel(id: string): string {
        const def = root.allToggleDefs.find(d => d.id === id);
        return def ? def.label : id;
    }

    function toggleEnabled(id: string): bool {
        const stored = Config.utilities.quickToggles || [];
        const found = stored.find(t => t.id === id);
        return found ? found.enabled !== false : true;
    }

    function writeOrder(ids: var): void {
        GlobalConfig.utilities.quickToggles = ids.map(id => ({
                    id: id,
                    enabled: root.toggleEnabled(id)
                }));
    }

    function settingsFor(toggleId: string): var {
        return root.toggleSettings.settingsFor(toggleId);
    }

    title: qsTr("Quick toggle")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Trigger")
        }

        ToggleRow {
            first: true
            text: qsTr("Enabled")
            reset: ({ node: GlobalConfig.utilities, setting: "enabled" })
            checked: Config.utilities.enabled
            onToggled: GlobalConfig.utilities.enabled = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("Show on hover")
            subtext: qsTr("Reveal when the cursor reaches the screen edge")
            reset: ({ node: GlobalConfig.utilities, setting: "showOnHover" })
            checked: Config.utilities.showOnHover
            onToggled: GlobalConfig.utilities.showOnHover = checked
        }

        StepperRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            enabled: Config.utilities.enabled && Config.utilities.showOnHover
            label: qsTr("Hover trigger depth")
            subtext: qsTr("Distance in from the screen edge that opens the quick toggles")
            reset: ({ node: GlobalConfig.utilities, setting: "hoverThickness" })
            value: Config.utilities.hoverThickness
            from: 1
            to: 100
            stepSize: 1
            onMoved: v => GlobalConfig.utilities.hoverThickness = v
        }

        StepperRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            enabled: Config.utilities.enabled && Config.utilities.showOnHover
            label: qsTr("Hover trigger width")
            subtext: qsTr("How much of that edge opens the quick toggles, as a percentage of their width")
            reset: ({ node: GlobalConfig.utilities, setting: "hoverWidth" })
            value: Config.utilities.hoverWidth
            from: 10
            to: 100
            stepSize: 5
            onMoved: v => GlobalConfig.utilities.hoverWidth = v
        }

        StepperRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            last: true
            enabled: Config.utilities.enabled
            label: qsTr("Drag threshold")
            subtext: qsTr("Pixels dragged before the quick toggle opens")
            reset: ({ node: GlobalConfig.utilities, setting: "dragThreshold" })
            value: Config.utilities.dragThreshold
            from: 0
            to: 200
            stepSize: 5
            onMoved: v => GlobalConfig.utilities.dragThreshold = v
        }

        SectionHeader {
            text: qsTr("Panel content")
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall / 2
            enabled: Config.utilities.enabled
            opacity: enabled ? 1 : 0.4

            ToggleRow {
                first: true
                text: qsTr("Keep Awake")
                subtext: qsTr("Show the Keep Awake card")
                reset: ({ node: GlobalConfig.utilities, setting: "showKeepAwake" })
                checked: Config.utilities.showKeepAwake
                onToggled: GlobalConfig.utilities.showKeepAwake = checked
            }

            ToggleRow {
                text: qsTr("Screen Capture")
                subtext: qsTr("Show the screen capture card")
                reset: ({ node: GlobalConfig.utilities, setting: "showScreenRecorder" })
                checked: Config.utilities.showScreenRecorder
                onToggled: GlobalConfig.utilities.showScreenRecorder = checked
            }

            ToggleRow {
                text: qsTr("GIF Recorder")
                subtext: qsTr("Show the Record GIF option in the recorder menu")
                reset: ({ node: GlobalConfig.utilities, setting: "showGifRecorder" })
                checked: Config.utilities.showGifRecorder
                onToggled: GlobalConfig.utilities.showGifRecorder = checked
            }

            ToggleRow {
                text: qsTr("Quick Share")
                subtext: qsTr("Show the Quick Share card while it is enabled")
                reset: ({ node: GlobalConfig.utilities, setting: "showQuickShare" })
                checked: Config.utilities.showQuickShare
                onToggled: GlobalConfig.utilities.showQuickShare = checked
            }

            ToggleRow {
                last: true
                text: qsTr("Quick Toggles")
                subtext: qsTr("Show the Quick Toggles card")
                reset: ({ node: GlobalConfig.utilities, setting: "showQuickToggles" })
                checked: Config.utilities.showQuickToggles
                onToggled: GlobalConfig.utilities.showQuickToggles = checked
            }
        }

        SectionHeader {
            text: qsTr("Quick toggle content")
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall / 2
            enabled: Config.utilities.enabled
            opacity: enabled ? 1 : 0.4

            StepperRow {
                first: true
                label: qsTr("Toggles per page")
                subtext: qsTr("Entries shown on each page of the drawer")
                reset: ({ node: GlobalConfig.utilities, setting: "quickTogglesPerPage" })
                value: Config.utilities.quickTogglesPerPage ?? 6
                from: 2
                to: 12
                stepSize: 1
                onMoved: value => GlobalConfig.utilities.quickTogglesPerPage = Math.round(value)
            }

            ToggleRow {
                last: true
                text: qsTr("Custom order")
                subtext: qsTr("Rearrange toggles with drag handles")
                reset: ({
                        customGet: () => Config.utilities.quickTogglesCustomOrder ?? false,
                        customSet: v => {
                            GlobalConfig.utilities.quickTogglesCustomOrder = v;
                        },
                        customDef: false
                    })
                checked: root.customOrder
                onToggled: GlobalConfig.utilities.quickTogglesCustomOrder = checked
            }

            ListEditor {
                function labelFor(item: var): string {
                    return root.toggleLabel(item);
                }

                function toggledFor(item: var): bool {
                    return root.toggleEnabled(item);
                }

                Layout.topMargin: Tokens.spacing.extraSmall / 2
                allowRemove: false
                allowReorder: root.customOrder
                settingsFor: toggleId => root.settingsFor(toggleId)
                expandedId: root.expandedId
                values: root.orderedIds
                onItemMoved: (from, to) => {
                    const ids = [...root.orderedIds];
                    const moved = ids.splice(from, 1)[0];
                    ids.splice(to, 0, moved);
                    root.writeOrder(ids);
                }
                onItemToggled: (index, checked) => {
                    const stored = Config.utilities.quickToggles || [];
                    const id = root.orderedIds[index];
                    if (checked && root.settingsFor(id))
                        root.expandedId = id;
                    else if (!checked && root.expandedId === id)
                        root.expandedId = "";
                    const entry = stored.find(t => t.id === id);
                    if (entry) {
                        const list = stored.map(t => ({
                                    id: t.id,
                                    enabled: t.id === id ? checked : (t.enabled !== false)
                                }));
                        GlobalConfig.utilities.quickToggles = list;
                    } else {
                        GlobalConfig.utilities.quickToggles = [...stored.map(t => ({
                                    id: t.id,
                                    enabled: t.enabled !== false
                                })), {
                                id: id,
                                enabled: checked
                            }];
                    }
                }
                onSettingsToggled: itemId => root.expandedId = root.expandedId === itemId ? "" : itemId
            }
        }

        GameModeTargetsDialog {
            id: targetsDialog

            Layout.preferredHeight: 0
        }
    }
}
