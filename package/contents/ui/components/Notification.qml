/*
    SPDX-FileCopyrightText: 2024 Evgeny Kazantsev <exequtic@gmail.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import org.kde.notification
import "../../tools/tools.js" as JS

Item {
    Component {
        id: notifyComponent
        Notification {
            componentName: "apdatifier"
            flags: cfg.notifyPersistent ? Notification.Persistent : Notification.CloseOnTimeout
        }
    }

    Component {
        id: actionComponent
        NotificationAction {
            label: i18n("Upgrade system")
            onActivated: JS.upgradeSystem()
        }
    }

    function send(event, title, body) {
        const params = {
            news: { icon: "news-subscribe", urgency: "HighUrgency" },
            error: { icon: "error", urgency: "HighUrgency" },
            updates: { icon: "apdatifier-packages", urgency: "DefaultUrgency" }
        }

        const { icon, urgency } = params[event]

        const action = (event === "updates" && cfg.notifyAction) ? actionComponent.createObject(root) : []

        if (cfg.notifySound) event += "Sound"

        notifyComponent.createObject(root, {
            eventId: event,
            iconName: icon,
            title: title,
            text: body,
            actions: action
        })?.sendEvent()
    }
}
