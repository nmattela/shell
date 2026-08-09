pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    required property var bar
    required property Brightness.Monitor monitor
    property color colour: Colours.palette.m3primary

    readonly property string windowTitle: {
        const title = Hypr.activeToplevel?.title;
        if (!title)
            return qsTr("Desktop");
        if (Config.bar.activeWindow.compact) {
            // " - " (standard hyphen), " — " (em dash), " – " (en dash)
            const parts = title.split(/\s+[\-\u2013\u2014]\s+/);
            if (parts.length > 1)
                return parts[parts.length - 1].trim();
        }
        return title;
    }

    readonly property int maxHeight: {
        const otherModules = bar.children.filter(c => c.entryId && c.item !== this && c.entryId !== "spacer");
        const otherHeight = otherModules.reduce((acc, curr) => acc + (curr.item.nonAnimHeight ?? curr.height), 0);
        // Length - 2 cause repeater counts as a child
        return bar.height - otherHeight - bar.spacing * (bar.children.length - 1) - bar.vPadding * 2;
    }
    property Title current: text1

    clip: true
    implicitWidth: Math.max((Config.bar.workspaces.windowIconType === "category" ? categoryIcon.implicitWidth : appIcon.implicitWidth), current.implicitHeight)
    implicitHeight: (Config.bar.workspaces.windowIconType === "category" ? categoryIcon.implicitHeight : appIcon.implicitHeight) + current.implicitWidth + current.anchors.topMargin

    Loader {
        asynchronous: true
        anchors.fill: parent
        active: !Config.bar.activeWindow.showOnHover

        sourceComponent: MouseArea {
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onPositionChanged: {
                const popouts = root.bar.popouts;
                if (popouts.hasCurrent && popouts.currentName !== "activewindow")
                    popouts.hasCurrent = false;
            }
            onClicked: {
                const popouts = root.bar.popouts;
                if (popouts.hasCurrent) {
                    popouts.hasCurrent = false;
                } else {
                    popouts.currentName = "activewindow";
                    popouts.currentCenter = root.mapToItem(root.bar, 0, root.implicitHeight / 2).y;
                    popouts.hasCurrent = true;
                }
            }
        }
    }

    MaterialIcon {
        id: categoryIcon
        visible: Config.bar.workspaces.windowIconType === "category"

        anchors.horizontalCenter: parent.horizontalCenter

        animate: true
        text: Icons.getAppCategoryIcon(Hypr.activeToplevel?.lastIpcObject.class, "desktop_windows")
        color: root.colour
    }

    IconImage {
        id: appIcon
        visible: Config.bar.workspaces.windowIconType === "app"

        asynchronous: true
        anchors.horizontalCenter: parent.horizontalCenter
        implicitSize: parent.implicitWidth
        source: Icons.getAppIcon(Hypr.activeToplevel?.lastIpcObject.class ?? "", "image-missing")
    }


    Title {
        id: text1
    }

    Title {
        id: text2
    }

    TextMetrics {
        id: metrics

        text: root.windowTitle
        font: root.Tokens.font.body.builders.small.letterSpacing(1.4).build()
        elide: Qt.ElideRight
        elideWidth: root.maxHeight - (Config.bar.workspaces.windowIconType === "category" ? categoryIcon.height : appIcon.height)

        onTextChanged: {
            const next = root.current === text1 ? text2 : text1;
            next.text = elidedText;
            root.current = next;
        }
        onElideWidthChanged: root.current.text = elidedText
    }

    Behavior on implicitHeight {
        Anim {}
    }

    component Title: StyledText {
        id: text

        anchors.horizontalCenter: (Config.bar.workspaces.windowIconType === "category" ? categoryIcon.horizontalCenter : appIcon.horizontalCenter)
        anchors.top: (Config.bar.workspaces.windowIconType === "category" ? categoryIcon.bottom : appIcon.bottom)
        anchors.topMargin: Tokens.spacing.small

        font: metrics.font
        color: root.colour
        opacity: root.current === this ? 1 : 0
        horizontalAlignment: Text.AlignLeft

        transform: [
            Translate {
                x: root.Config.bar.activeWindow.inverted ? -text.implicitWidth + text.implicitHeight : 0
            },
            Rotation {
                angle: root.Config.bar.activeWindow.inverted ? 270 : 90
                origin.x: text.implicitHeight / 2
                origin.y: text.implicitHeight / 2
            }
        ]

        width: implicitHeight
        height: implicitWidth

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
