pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../core" as Core

QtObject {
    id: root

    readonly property string statePath: Core.Paths.shell + "/reminders.json"
    property var reminders: []
    property int clockTick: 0

    readonly property FileView stateFile: FileView {
        path: root.statePath

        watchChanges: false
        blockLoading: true
        printErrors: false
    }

    readonly property var activeReminders: {
        root.clockTick;
        const now = Date.now();
        return root.reminders.filter(function (reminder) {
            return reminder && reminder.at > now;
        });
    }

    function load() {
        const raw = root.stateFile.text();
        if (!raw) {
            root.reminders = [];
            return;
        }

        let parsed;

        try {
            parsed = JSON.parse(raw);
        } catch (e) {
            root.reminders = [];
            return;
        }

        root.reminders = (Array.isArray(parsed) ? parsed : []).filter(function (reminder) {
            return reminder
                && typeof reminder === "object"
                && typeof reminder.id === "string"
                && reminder.id !== ""
                && Number.isFinite(Number(reminder.minutes))
                && Number(reminder.minutes) > 0
                && typeof reminder.message === "string"
                && Number.isFinite(Number(reminder.at));
        });
    }

    function save() {
        root.stateFile.setText(JSON.stringify(root.reminders));
    }

    function cleanup() {
        const now = Date.now();
        const next = root.reminders.filter(function (reminder) {
            return reminder && reminder.at > now;
        });

        if (next.length !== root.reminders.length) {
            root.reminders = next;
            root.save();
        }
    }

    function formatTime(at) {
        const date = new Date(at);
        const hours = ("0" + date.getHours()).slice(-2);
        const minutes = ("0" + date.getMinutes()).slice(-2);
        return hours + ":" + minutes;
    }

    function add(minutes, message) {
        const amount = Number(minutes);
        if (!isFinite(amount) || amount <= 0)
            return false;

        const text = String(message || "Reminder").trim() || "Reminder";
        const id = String(Date.now()) + "-" + Math.floor(Math.random() * 1000);
        const reminder = {
            "id": id,
            "minutes": amount,
            "message": text,
            "at": Date.now() + amount * 60 * 1000
        };

        root.reminders = root.reminders.concat([reminder]);
        root.save();
        root.startTimer(reminder);
        return true;
    }

    function clear() {
        const units = root.reminders.map(function (reminder) {
            return "shell-reminder-" + reminder.id;
        });

        if (units.length > 0) {
            Core.Util.restart(root.clearProc, ["systemctl", "--user", "stop"].concat(units));
        }

        root.reminders = [];
        root.save();
    }

    function startTimer(reminder) {
        timerProc.running = false;
        timerProc.command = [
            "systemd-run",
            "--user",
            "--quiet",
            "--collect",
            "--on-active=" + reminder.minutes + "m",
            "--unit=shell-reminder-" + reminder.id,
            "notify-send",
            "-a",
            "Reminder",
            "-u",
            "normal",
            "Reminder",
            reminder.message
        ];
        timerProc.running = true;
    }

    function search(rawQuery) {
        const query = String(rawQuery || "").trim();
        const lower = query.toLowerCase();

        if (lower.length === 0) {
            return [
                {
                    "kind": "reminder-set-prompt",
                    "title": "Set a reminder",
                    "subtitle": "Type: set 10 drink water"
                },
                {
                    "kind": "reminder-list-prompt",
                    "title": "Show reminders",
                    "subtitle": "Type: list"
                },
                {
                    "kind": "reminder-clear",
                    "title": "Clear all reminders",
                    "subtitle": "Stop and remove every active reminder"
                }
            ];
        }

        const setMatch = query.match(/^set\s+(\d+)\s*(.*)$/i);
        if (setMatch) {
            const minutes = parseInt(setMatch[1], 10);
            const message = setMatch[2].trim() || "Reminder";
            return [{
                "kind": "reminder-set",
                "minutes": minutes,
                "message": message,
                "title": "Set reminder",
                "subtitle": "In " + minutes + " min — " + message
            }];
        }

        if (lower === "set") {
            return [{
                "kind": "reminder-set-prompt",
                "title": "Set a reminder",
                "subtitle": "Type: set 10 drink water"
            }];
        }

        if (lower === "clear") {
            return [{
                "kind": "reminder-clear",
                "title": "Clear all reminders",
                "subtitle": "Stop and remove every active reminder"
            }];
        }

        if (lower === "list") {
            const reminders = root.activeReminders;
            if (reminders.length === 0) {
                return [{
                    "kind": "reminder-empty",
                    "title": "No active reminders",
                    "subtitle": ""
                }];
            }

            return reminders.map(function (reminder) {
                return {
                    "kind": "reminder-item",
                    "title": reminder.message,
                    "subtitle": "Reminder",
                    "trailing": root.formatTime(reminder.at)
                };
            });
        }

        return root.activeReminders.filter(function (reminder) {
            return reminder.message.toLowerCase().indexOf(lower) >= 0;
        }).map(function (reminder) {
            return {
                "kind": "reminder-item",
                "title": reminder.message,
                "subtitle": "Reminder",
                "trailing": root.formatTime(reminder.at)
            };
        });
    }

    function refresh() {
        root.cleanup();
        root.load();
    }

    readonly property Process timerProc: Process {
    }

    readonly property Process clearProc: Process {
    }

    readonly property Timer tickTimer: Timer {
        interval: Core.Theme.slowPollMs
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            root.clockTick++;
            root.cleanup();
        }
    }

    Component.onCompleted: root.refresh()
}
