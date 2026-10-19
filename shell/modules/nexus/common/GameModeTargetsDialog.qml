pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import qs.modules.nexus.common

Item {
    id: root

    function open(): void {
        dialog.open();
    }

    function addTarget(pattern: string): void {
        if (!pattern)
            return;
        const list = Array.from(GlobalConfig.utilities.gameMode.autoEnableRegexes);
        if (!list.includes(pattern)) {
            list.push(pattern);
            GlobalConfig.utilities.gameMode.autoEnableRegexes = list;
            GlobalConfig.save();
        }
        customInput.text = "";
    }

    function removeTarget(index: int): void {
        const list = Array.from(GlobalConfig.utilities.gameMode.autoEnableRegexes);
        list.splice(index, 1);
        GlobalConfig.utilities.gameMode.autoEnableRegexes = list;
        GlobalConfig.save();
    }

    Popup {
        id: dialog

        width: 560
        height: Math.min(620, column.implicitHeight + Tokens.padding.large * 2)
        padding: Tokens.padding.large
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        parent: Overlay.overlay

        x: parent ? Math.round((parent.width - width) / 2) : 0
        y: parent ? Math.round((parent.height - height) / 2) : 0

        enter: DialogTransition {}
        exit: DialogTransition {
            exiting: true
        }

        background: Item {
            Elevation {
                anchors.fill: bgRect
                level: 3
                radius: bgRect.radius
            }

            Rectangle {
                id: bgRect

                anchors.fill: parent
                color: Colours.palette.m3surfaceContainerHigh
                radius: Tokens.rounding.large
                border.width: 1
                border.color: Colours.palette.m3outlineVariant
            }
        }

        contentItem: ColumnLayout {
            id: column

            spacing: Tokens.spacing.small

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Target windows")
                    font: Tokens.font.title.small
                }

                IconButton {
                    type: IconButton.Text
                    isRound: true
                    icon: "close"
                    onClicked: dialog.close()
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Game mode turns on by itself when one of these windows is focused or running")
                font: NexusStyle.secondaryFont
                color: Colours.palette.m3onSurfaceVariant
                wrapMode: Text.Wrap
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: inputRow.implicitHeight + Tokens.padding.medium * 2

                ConnectedRect {
                    anchors.fill: parent
                }

                RowLayout {
                    id: inputRow

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.medium
                    spacing: Tokens.spacing.medium

                    Column {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            text: qsTr("Custom regex")
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }

                        StyledText {
                            text: qsTr("Add a custom class or regex pattern")
                            font: NexusStyle.secondaryFont
                            color: Colours.palette.m3onSurfaceVariant
                            elide: Text.ElideRight
                        }
                    }

                    StyledRect {
                        Layout.preferredWidth: 200
                        Layout.preferredHeight: 32
                        radius: Tokens.rounding.small
                        color: Colours.layer(Colours.palette.m3surfaceVariant, 2)

                        StyledTextField {
                            id: customInput

                            anchors.fill: parent
                            anchors.leftMargin: Tokens.padding.medium
                            anchors.rightMargin: Tokens.padding.medium
                            verticalAlignment: TextInput.AlignVCenter
                            placeholderText: "^steam_app_.*$"
                            onAccepted: root.addTarget(text)
                        }
                    }

                    IconButton {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        icon: "add"
                        onClicked: root.addTarget(customInput.text)
                    }
                }
            }

            WindowPickerRow {
                Layout.fillWidth: true
                last: true
                keepPopupAsChild: true
                icon: "touch_app"
                label: qsTr("Pick from running windows")
                status: qsTr("Select an open window to add it automatically")
                onSelected: windowClass => root.addTarget(windowClass)
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.preferredHeight: 260
                color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
                radius: Tokens.rounding.large

                ListView {
                    id: targetList

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    orientation: ListView.Vertical
                    spacing: Tokens.spacing.small
                    model: GlobalConfig.utilities.gameMode.autoEnableRegexes
                    clip: true
                    interactive: contentHeight > height

                    move: Transition {
                        Anim {
                            properties: "y"
                            type: Anim.FastSpatial
                        }
                    }
                    moveDisplaced: Transition {
                        Anim {
                            properties: "y"
                            type: Anim.FastSpatial
                        }
                    }

                    delegate: StyledRect {
                        id: delegateRect

                        required property string modelData
                        required property int index

                        width: ListView.view.width
                        height: 40
                        color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
                        radius: Tokens.rounding.medium

                        RowLayout {
                            id: itemLayout

                            property bool isRegex: delegateRect.modelData.startsWith("^") && delegateRect.modelData.endsWith("$")

                            anchors.fill: parent
                            anchors.leftMargin: Tokens.padding.medium
                            anchors.rightMargin: Tokens.padding.medium
                            spacing: Tokens.spacing.medium

                            IconImage {
                                visible: !itemLayout.isRegex
                                Layout.alignment: Qt.AlignVCenter
                                implicitSize: Math.round(Tokens.font.icon.large.pointSize * 1.5)
                                source: itemLayout.isRegex ? "" : Quickshell.iconPath(delegateRect.modelData, "image-missing")
                            }

                            MaterialIcon {
                                visible: itemLayout.isRegex
                                Layout.alignment: Qt.AlignVCenter
                                text: "code"
                                font: Tokens.font.icon.large
                            }

                            StyledText {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                text: delegateRect.modelData
                                font: Tokens.font.body.small
                                elide: Text.ElideRight
                            }

                            Item {
                                Layout.alignment: Qt.AlignVCenter
                                implicitWidth: 28
                                implicitHeight: 28

                                StateLayer {
                                    anchors.fill: parent
                                    radius: Tokens.rounding.full
                                    onClicked: root.removeTarget(delegateRect.index)
                                }

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    text: "close"
                                    font: Tokens.font.icon.small
                                }
                            }
                        }
                    }
                }

                StyledText {
                    anchors.centerIn: parent
                    visible: targetList.count === 0
                    text: qsTr("No target windows yet")
                    font: NexusStyle.secondaryFont
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }
    }
}
