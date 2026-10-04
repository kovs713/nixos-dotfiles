pragma Singleton

import QtQml
import Quickshell
import Quickshell.Services.Polkit

import "../core" as Core

Singleton {
    id: root

    property alias active: agent.isActive

    readonly property var flow: agent.flow

    property bool failed: false

    readonly property string message: String(Core.Util.get(root.flow, "message", ""))
        .trim()
        .replace(/\.$/, "")

    readonly property string inputLabel: {
        const prompt = String(Core.Util.get(root.flow, "inputPrompt", "")).trim();

        if (prompt !== "")
            return prompt.replace(/:$/, "");

        return root.echo ? "Input" : "Password";
    }

    readonly property bool echo: Core.Util.flag(root.flow, "responseVisible")

    readonly property bool responseRequired: Core.Util.get(root.flow, "isResponseRequired", true) !== false

    readonly property string supplementary: String(Core.Util.get(root.flow, "supplementaryMessage", "")).trim()

    readonly property bool supplementaryIsError: Core.Util.flag(root.flow, "supplementaryIsError")

    function submit(value) {
        if (!root.flow)
            return;

        try {
            root.flow.submit(String(value));
        } catch (e) {
        }
    }

    function cancel() {
        if (!root.flow)
            return;

        try {
            root.flow.cancelAuthenticationRequest();
        } catch (e) {}
    }

    function reset() {
        root.failed = false;
    }

    PolkitAgent {
        id: agent

        onAuthenticationRequestStarted: root.failed = false
    }

    Connections {
        target: root.flow

        function onAuthenticationFailed() {
            root.failed = true;
        }

        function onAuthenticationSucceeded() {
            root.failed = false;
        }

        function onAuthenticationRequestCancelled() {
            root.failed = false;
        }
    }
}
