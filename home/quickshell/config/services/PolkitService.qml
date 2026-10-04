pragma Singleton

import QtQml
import Quickshell
import Quickshell.Services.Polkit

import "../core" as Core

// The session's polkit authentication agent.
//
// polkitd is enabled in modules/networking.nix, but an agent is a separate thing:
// without one registered on the system bus every graphical authorisation fails
// with "no agent available", so a GUI `pkexec` never even reaches a password
// prompt. This singleton is the agent; the prompt that renders it is
// modules/PolkitPrompt.qml.
//
// Instantiation matters: a Quickshell singleton is only constructed once something
// reads from it, and an agent that is never constructed is not registered. The
// prompt binds to `active` unconditionally, which is what keeps this alive.
Singleton {
    id: root

    property alias active: agent.isActive

    // `var` rather than an alias: the flow is null between requests, and every
    // read below has to guard for that anyway.
    readonly property var flow: agent.flow

    // True once a wrong password came back. polkit keeps the same flow open after
    // a failure, so this is the only way the prompt can tell "try again" from
    // "type it in the first place".
    property bool failed: false

    // polkit's own prompt already reads like a sentence, and this one already
    // ends in a period, which reads wrong directly above a text field.
    readonly property string message: String(Core.Util.get(root.flow, "message", ""))
        .trim()
        .replace(/\.$/, "")

    // Where the field goes when the flow has no prompt of its own, which is the
    // usual case for a plain password authentication.
    readonly property string inputLabel: {
        const prompt = String(Core.Util.get(root.flow, "inputPrompt", "")).trim();

        if (prompt !== "")
            return prompt.replace(/:$/, "");

        return root.echo ? "Input" : "Password";
    }

    // responseVisible is what polkit uses for a question that is not a secret, so
    // the field is only masked when the answer is a password.
    readonly property bool echo: Core.Util.flag(root.flow, "responseVisible")

    readonly property bool responseRequired: Core.Util.get(root.flow, "isResponseRequired", true) !== false

    // A message polkit sends alongside the request, e.g. "You are about to run a
    // command as administrator" or a hint about typing the password wrongly.
    readonly property string supplementary: String(Core.Util.get(root.flow, "supplementaryMessage", "")).trim()

    readonly property bool supplementaryIsError: Core.Util.flag(root.flow, "supplementaryIsError")

    function submit(value) {
        if (!root.flow)
            return;

        try {
            root.flow.submit(String(value));
        } catch (e) {
            // The flow closed under us, e.g. cancelled from the other side.
        }
    }

    function cancel() {
        if (!root.flow)
            return;

        try {
            root.flow.cancelAuthenticationRequest();
        } catch (e) {}
    }

    // Start over with an empty field after a rejection. polkit keeps the flow, so
    // without this the user would be typing their next attempt into a box that
    // still holds the password that just failed.
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
