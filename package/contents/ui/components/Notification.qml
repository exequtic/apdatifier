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
        id: upgradeAction
        NotificationAction {
            label: i18n("Upgrade system")
            onActivated: JS.upgradeSystem()
        }
    }

    Component {
        id: openArticleAction
        NotificationAction {
            property string link
            label: i18n("Read article")
            onActivated: Qt.openUrlExternally(link)
        }
    }

    function send(event, title, body, link) {
        const params = {
            updates: {
                icon: "apdatifier-packages",
                urgency: "DefaultUrgency"
            },
            news: {
                icon: "news-subscribe",
                urgency: "HighUrgency"
            },
            error: {
                icon: "error",
                urgency: "CriticalUrgency"
            }
        }

        const { icon, urgency } = params[event]

        const action = (event === "updates" && cfg.notifyAction) ? upgradeAction.createObject(root)
                     : (event === "news" && cfg.notifyAction) ? openArticleAction.createObject(root, { link: link })
                     : []

        if (cfg.notifySound) event += "Sound"

        notifyComponent.createObject(root, {
            eventId: event,
            iconName: icon,
            title: title,
            text: body,
            actions: action,
            urgency: urgency
        })?.sendEvent()
    }
}
