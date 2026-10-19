import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.Services.QuickShare
import qs.services
import qs.modules.nexus
import qs.modules.nexus.common

QtObject {
    id: root

    required property NexusState nState

    readonly property Component quickShareSettings: Component {
        ColumnLayout {
            spacing: Tokens.spacing.extraSmall / 2

            ToggleRow {
                first: true
                text: qsTr("Enable Quick Share")
                subtext: QuickShareService.isEnabled ? qsTr("Listening for nearby devices") : QuickShare.enabled ? qsTr("Checking this machine can receive") : qsTr("Disabled")
                checked: QuickShare.enabled
                onToggled: QuickShare.setEnabled(checked)
            }

            ToggleRow {
                text: qsTr("Discoverable")
                subtext: qsTr("Advertise this machine so nearby devices can send to it")
                enabled: QuickShareService.isEnabled
                checked: QuickShareService.isVisible
                onToggled: QuickShareService.isVisible = checked
            }

            InfoRow {
                last: true
                icon: "wifi"
                label: qsTr("Same network")
                subtext: qsTr("Nearby devices have to be on the same network, which for a phone means the same Wi-Fi")
            }

            RowButton {
                first: true
                last: true
                icon: "security"
                text: qsTr("Quick Share setup")
                subtext: QuickShareSetup.status
                trailingIcon: "chevron_right"
                disabled: QuickShareSetup.busy
                onClicked: QuickShareSetup.run()
            }

            ToggleRow {
                first: true
                last: true
                text: qsTr("Start automatically")
                subtext: qsTr("Turn Quick Share on when the shell starts")
                reset: ({ node: GlobalConfig.services, setting: "quickShareAutoStart" })
                checked: Config.services.quickShareAutoStart
                onToggled: GlobalConfig.services.quickShareAutoStart = checked
            }

            InfoRow {
                first: true
                icon: "download"
                label: qsTr("Received files")
                subtext: qsTr("Saved to your Downloads folder")
            }

            RowButton {
                last: true
                icon: "delete_sweep"
                text: qsTr("Clear transfer history")
                subtext: qsTr("%n transfer(s) recorded", "", QuickShareService.transferHistory.length)
                trailingIcon: "chevron_right"
                onClicked: QuickShareService.clearHistory()
            }
        }
    }

    readonly property Component launcherSettings: Component {
        ColumnLayout {
            spacing: Tokens.spacing.extraSmall / 2

            NavRow {
                first: true
                last: true
                icon: "open_in_new"
                label: qsTr("Open Launcher settings")
                onClicked: root.openSettingsPage("panels/LauncherPanel.qml")
            }
        }
    }

    readonly property Component overviewSettings: Component {
        ColumnLayout {
            spacing: Tokens.spacing.extraSmall / 2

            NavRow {
                first: true
                last: true
                icon: "open_in_new"
                label: qsTr("Open Overview settings")
                onClicked: root.openSettingsPage("panels/OverviewPanel.qml")
            }
        }
    }

    readonly property Component dashboardSettings: Component {
        ColumnLayout {
            spacing: Tokens.spacing.extraSmall / 2

            NavRow {
                first: true
                last: true
                icon: "open_in_new"
                label: qsTr("Open Dashboard settings")
                onClicked: root.openSettingsPage("panels/DashboardPanel.qml")
            }
        }
    }

    readonly property Component wallpaperSettings: Component {
        ColumnLayout {
            spacing: Tokens.spacing.extraSmall / 2

            NavRow {
                first: true
                last: true
                icon: "open_in_new"
                label: qsTr("Open wallpaper settings")
                onClicked: root.openSettingsPage("wallandstyle/WallpaperSettingsPage.qml")
            }
        }
    }

    readonly property Component gameModeSettings: Component {
        ColumnLayout {
            spacing: Tokens.spacing.extraSmall / 2

            ToggleRow {
                first: true
                text: qsTr("Enable automatically")
                subtext: qsTr("Turn on game mode when a target window is focused or running")
                reset: ({ node: GlobalConfig.utilities.gameMode, setting: "autoEnable" })
                checked: Config.utilities.gameMode.autoEnable
                onToggled: GlobalConfig.utilities.gameMode.autoEnable = checked
            }

            NavRow {
                last: true
                icon: "ads_click"
                label: qsTr("Target windows")
                status: qsTr("Add or remove auto-enable targets")
                onClicked: root.targetsRequested()
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall / 2
                visible: Quickshell.env("XDG_CURRENT_DESKTOP").includes("Hyprland")

                SectionHeader {
                    first: true
                    text: qsTr("Hyprland overrides")
                }

                ToggleRow {
                    first: true
                    text: qsTr("Disable animations")
                    reset: ({ node: GlobalConfig.utilities.gameMode, setting: "disableHyprlandAnimations" })
                    checked: Config.utilities.gameMode.disableHyprlandAnimations
                    onToggled: GlobalConfig.utilities.gameMode.disableHyprlandAnimations = checked
                }

                ToggleRow {
                    text: qsTr("Disable blur")
                    reset: ({ node: GlobalConfig.utilities.gameMode, setting: "disableHyprlandBlur" })
                    checked: Config.utilities.gameMode.disableHyprlandBlur
                    onToggled: GlobalConfig.utilities.gameMode.disableHyprlandBlur = checked
                }

                ToggleRow {
                    text: qsTr("Disable gaps and rounding")
                    reset: ({ node: GlobalConfig.utilities.gameMode, setting: "disableHyprlandGaps" })
                    checked: Config.utilities.gameMode.disableHyprlandGaps
                    onToggled: GlobalConfig.utilities.gameMode.disableHyprlandGaps = checked
                }

                ToggleRow {
                    text: qsTr("Disable shadows")
                    reset: ({ node: GlobalConfig.utilities.gameMode, setting: "disableHyprlandShadows" })
                    checked: Config.utilities.gameMode.disableHyprlandShadows
                    onToggled: GlobalConfig.utilities.gameMode.disableHyprlandShadows = checked
                }

                ToggleRow {
                    last: true
                    text: qsTr("Disable window transparency")
                    reset: ({ node: GlobalConfig.utilities.gameMode, setting: "disableWindowTransparency" })
                    checked: Config.utilities.gameMode.disableWindowTransparency
                    onToggled: GlobalConfig.utilities.gameMode.disableWindowTransparency = checked
                }
            }

            SectionHeader {
                text: qsTr("Caelestia feature overrides")
            }

            ToggleRow {
                first: true
                text: qsTr("Disable shell transparency")
                reset: ({ node: GlobalConfig.utilities.gameMode, setting: "disableShellTransparency" })
                checked: Config.utilities.gameMode.disableShellTransparency
                onToggled: GlobalConfig.utilities.gameMode.disableShellTransparency = checked
            }

            ToggleRow {
                text: qsTr("Disable toast notifications transparency")
                reset: ({ node: GlobalConfig.utilities.gameMode, setting: "disableToastTransparency" })
                checked: Config.utilities.gameMode.disableToastTransparency
                onToggled: GlobalConfig.utilities.gameMode.disableToastTransparency = checked
            }

            ToggleRow {
                text: qsTr("Disable desktop lyrics")
                reset: ({ node: GlobalConfig.utilities.gameMode, setting: "disableDesktopLyrics" })
                checked: Config.utilities.gameMode.disableDesktopLyrics
                onToggled: GlobalConfig.utilities.gameMode.disableDesktopLyrics = checked
            }

            ToggleRow {
                last: true
                text: qsTr("Disable visualizer")
                reset: ({ node: GlobalConfig.utilities.gameMode, setting: "disableVisualizer" })
                checked: Config.utilities.gameMode.disableVisualizer
                onToggled: GlobalConfig.utilities.gameMode.disableVisualizer = checked
            }
        }
    }

    readonly property Component pauseWallpaperSettings: Component {
        ColumnLayout {
            spacing: Tokens.spacing.extraSmall / 2

            ToggleRow {
                first: true
                text: qsTr("Pause video wallpapers")
                reset: ({ node: GlobalConfig.background, setting: "videoWallpaperPaused" })
                checked: Config.background.videoWallpaperPaused
                onToggled: GlobalConfig.background.videoWallpaperPaused = checked
            }

            ToggleRow {
                text: qsTr("Enable video audio")
                reset: ({ node: GlobalConfig.background, setting: "videoWallpaperSoundEnabled" })
                checked: Config.background.videoWallpaperSoundEnabled
                onToggled: GlobalConfig.background.videoWallpaperSoundEnabled = checked
            }

            ToggleRow {
                text: qsTr("Pause video on fullscreen")
                reset: ({ node: GlobalConfig.background, setting: "videoWallpaperPauseOnFullscreen" })
                checked: Config.background.videoWallpaperPauseOnFullscreen
                onToggled: GlobalConfig.background.videoWallpaperPauseOnFullscreen = checked
            }

            ToggleRow {
                text: qsTr("Pause video on tiled windows")
                reset: ({ node: GlobalConfig.background, setting: "videoWallpaperPauseOnTiled" })
                checked: Config.background.videoWallpaperPauseOnTiled
                onToggled: GlobalConfig.background.videoWallpaperPauseOnTiled = checked
            }

            ToggleRow {
                text: qsTr("Pause video on all displays")
                reset: ({ node: GlobalConfig.background, setting: "videoWallpaperPauseOnAllDisplays" })
                checked: Config.background.videoWallpaperPauseOnAllDisplays
                onToggled: GlobalConfig.background.videoWallpaperPauseOnAllDisplays = checked
            }

            ToggleRow {
                last: true
                text: qsTr("Mute video when media plays")
                reset: ({ node: GlobalConfig.background, setting: "videoWallpaperMuteOnMedia" })
                checked: Config.background.videoWallpaperMuteOnMedia
                onToggled: GlobalConfig.background.videoWallpaperMuteOnMedia = checked
            }
        }
    }

    readonly property Component visualiserSettings: Component {
        ColumnLayout {
            spacing: Tokens.spacing.extraSmall / 2

            NavRow {
                first: true
                last: true
                icon: "open_in_new"
                label: qsTr("Open visualiser settings")
                onClicked: root.openSettingsPage("wallandstyle/DesktopAddonsPage.qml")
            }
        }
    }

    signal targetsRequested()

    function settingsFor(toggleId: string): var {
        switch (toggleId) {
        case "quickShare":
            return quickShareSettings;
        case "launcher":
            return launcherSettings;
        case "overview":
            return overviewSettings;
        case "dashboard":
            return dashboardSettings;
        case "wallpaper":
            return wallpaperSettings;
        case "gameMode":
            return gameModeSettings;
        case "pauseWallpaper":
            return pauseWallpaperSettings;
        case "visualiser":
            return visualiserSettings;
        default:
            return null;
        }
    }

    function openSettingsPage(pagePath: string): void {
        const pageIdx = PageDictionary.pages.findIndex(p => (p.settings || []).some(s => s.pagePath === pagePath));
        const subPageIdx = PageDictionary.subPageIdxFor(pagePath);
        if (pageIdx < 0 || subPageIdx < 0)
            return;
        root.nState.goToSubPage(pageIdx, subPageIdx);
    }
}
