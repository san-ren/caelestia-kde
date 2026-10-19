pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Utilities")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Quick controls")
        }

        NavRow {
            first: true
            last: true
            icon: "volume_up"
            label: qsTr("On-screen sliders")
            status: qsTr("Volume, microphone, brightness, and edge triggers")
            onClicked: root.nState.openSubPage(1)
        }
    }
}
