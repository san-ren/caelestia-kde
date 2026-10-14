pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.modules.launcher.items

Item {
    id: root

    required property var controller
    required property var browser
    required property int currentIndex

    function itemAt(index: int): Item {
        return entryRepeater.itemAt(index) ?? null;
    }

    implicitWidth: root.controller.columns * root.controller.cellWidth
    implicitHeight: root.controller.rows * root.controller.cellHeight

    Repeater {
        id: entryRepeater

        model: root.controller.entries

        delegate: FavouriteEntry {
            id: entry

            readonly property int slot: root.controller.slotOf(entry.key)

            controller: root.controller
            browser: root.browser
            selected: root.currentIndex === slot
            flatIndex: slot
            x: root.controller.slotX(slot)
            y: root.controller.slotY(slot)
            z: entry.isMergeTarget ? 3 : (entry.isDragged ? 0 : 1)
            onDragRequested: (key, x, y) => root.controller.beginDrag(key, entry, x, y)

            Behavior on x {
                Anim {}
            }

            Behavior on y {
                Anim {}
            }
        }
    }
}
