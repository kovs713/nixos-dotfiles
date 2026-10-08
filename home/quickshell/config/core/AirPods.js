// Parsing and naming for the librepods status line. A .js rather than a core/
// singleton so `node airpods.test.mjs` can assert it without a QML host.
//
// The line is one line of compact JSON from $XDG_STATE_HOME/librepods/status.json,
// keys sorted by QJsonObject rather than by the daemon's insert order. Thirteen
// *_total counters and model_int/model_number are daemon telemetry and are not
// read here. Taken from the omarchy-pods panel (MIT), which read the same daemon.

var NOISE_OFF = 0;
var NOISE_ANC = 1;
var NOISE_TRANSPARENCY = 2;
var NOISE_ADAPTIVE = 3;

// noise_mode before the daemon has identified the device.
var NOISE_UNKNOWN = -1;

// lid_state: 0 open, 1 closed, 2 unknown.
var LID_UNKNOWN = 2;

var EAR_PAUSE_ONE_OUT = 0;
var EAR_PAUSE_BOTH_OUT = 1;
var EAR_DISABLED = 2;
var EAR_BEHAVIOR_COUNT = 3;

// The level for a pod or a case nobody has heard from.
var LEVEL_UNKNOWN = -1;

// Highest schema_version this shell knows how to read.
var SUPPORTED_SCHEMA = 1;

function defaultPod() {
    return { level: LEVEL_UNKNOWN, charging: false, inEar: false };
}

function defaultStatus() {
    return {
        ok: false,
        error: "",
        schemaTooNew: false,
        connected: false,
        deviceName: "",
        modelName: "",
        isProSeries: false,
        isHeadset: false,
        supportsNoiseOff: true,
        supportsNoiseControl: true,
        supportsAdaptive: false,
        supportsConversationalAwareness: false,
        supportsOneBudANC: false,
        noiseMode: NOISE_UNKNOWN,
        adaptiveNoiseLevel: 0,
        oneBudANC: false,
        conversationalAwareness: false,
        earDetectionBehavior: EAR_PAUSE_ONE_OUT,
        lidState: LID_UNKNOWN,
        left: defaultPod(),
        right: defaultPod(),
        caseBattery: defaultPod(),
        headset: defaultPod()
    };
}

function intOr(value, fallback) {
    const n = parseInt(value, 10);

    return isFinite(n) ? n : fallback;
}

// A daemon older than the capability keys sends nothing, and that is not false:
// reading it as false would strip Adaptive off a Pro 2 on any daemon predating it.
function boolOr(value, fallback) {
    return value === undefined ? fallback : value === true;
}

// left, right, case and headset are absent entirely until a battery packet
// arrives, and available:false means the daemon has stopped hearing from that
// unit, so its charging and in_ear flags are stale alongside the level.
function podFrom(raw) {
    const pod = defaultPod();

    if (!raw || typeof raw !== "object" || raw.available !== true)
        return pod;

    pod.level = intOr(raw.level, LEVEL_UNKNOWN);
    pod.charging = raw.charging === true;
    pod.inEar = raw.in_ear === true;

    return pod;
}

function parseStatus(raw) {
    const status = defaultStatus();
    const text = String(raw === undefined || raw === null ? "" : raw).trim();

    if (text === "") {
        status.error = "The librepods status file is empty";
        return status;
    }

    let parsed;

    try {
        parsed = JSON.parse(text);
    } catch (e) {
        status.error = "Could not read the librepods status file";
        return status;
    }

    if (!parsed || typeof parsed !== "object" || parsed.schema_version === undefined) {
        status.error = "The librepods status file carried no schema_version";
        return status;
    }

    const version = intOr(parsed.schema_version, 0);

    if (version > SUPPORTED_SCHEMA) {
        status.schemaTooNew = true;
        status.error = "librepods speaks status schema " + version + ", this shell reads " + SUPPORTED_SCHEMA;
        return status;
    }

    status.ok = true;
    status.connected = parsed.connected === true;
    status.deviceName = String(parsed.device_name || "");
    status.modelName = String(parsed.model_name || "");
    status.isProSeries = parsed.is_pro_series === true;
    status.isHeadset = parsed.is_headset === true;
    // Every model before the Pro 3 had an Off mode.
    status.supportsNoiseOff = parsed.supports_noise_off !== false;
    // AirPods 1, 2, 3 and the plain AirPods 4 have no listening modes at all.
    status.supportsNoiseControl = boolOr(parsed.supports_noise_control, true);
    status.supportsAdaptive = boolOr(parsed.supports_adaptive, status.isProSeries);
    status.supportsConversationalAwareness = boolOr(parsed.supports_conversational_awareness, status.isProSeries);
    status.supportsOneBudANC = boolOr(parsed.supports_one_bud_anc, status.isProSeries);
    status.noiseMode = intOr(parsed.noise_mode, NOISE_UNKNOWN);
    status.adaptiveNoiseLevel = intOr(parsed.adaptive_noise_level, 0);
    status.oneBudANC = parsed.one_bud_anc_mode === true;
    status.conversationalAwareness = parsed.conversational_awareness === true;
    status.earDetectionBehavior = intOr(parsed.ear_detection_behavior, EAR_PAUSE_ONE_OUT);
    status.lidState = intOr(parsed.lid_state, LID_UNKNOWN);
    status.left = podFrom(parsed.left);
    status.right = podFrom(parsed.right);
    status.caseBattery = podFrom(parsed["case"]);
    status.headset = podFrom(parsed.headset);

    return status;
}

// One list for the cycle and the segmented control, in draw order.
function availableModes(hasNoiseControl, hasOff, hasAdaptive) {
    if (!hasNoiseControl)
        return [];

    const modes = [];

    if (hasOff)
        modes.push(NOISE_OFF);

    modes.push(NOISE_TRANSPARENCY);

    if (hasAdaptive)
        modes.push(NOISE_ADAPTIVE);

    modes.push(NOISE_ANC);

    return modes;
}

function noiseModeName(mode) {
    if (mode === NOISE_OFF)
        return "Off";

    if (mode === NOISE_ANC)
        return "ANC";

    if (mode === NOISE_TRANSPARENCY)
        return "Transparency";

    if (mode === NOISE_ADAPTIVE)
        return "Adaptive";

    return "";
}

function noiseModeVerb(mode) {
    const verbs = [ "noise:off", "noise:anc", "noise:transparency", "noise:adaptive" ];

    if (mode < 0 || mode >= verbs.length)
        return "";

    return verbs[mode];
}

function earDetectionVerb(behavior) {
    const verbs = [ "ear:one", "ear:both", "ear:off" ];

    if (behavior < 0 || behavior >= verbs.length)
        return "";

    return verbs[behavior];
}

function earDetectionName(behavior) {
    if (behavior === EAR_PAUSE_ONE_OUT)
        return "One pod out";

    if (behavior === EAR_PAUSE_BOTH_OUT)
        return "Both pods out";

    if (behavior === EAR_DISABLED)
        return "Never";

    return "";
}

function levelText(level) {
    return level === LEVEL_UNKNOWN ? "--" : String(level) + "%";
}

function lidText(lidState) {
    return lidState === 0 ? "Open" : lidState === 1 ? "Closed" : "";
}

function podMeta(pod) {
    if (pod.charging)
        return "Charging";

    if (pod.inEar)
        return "In ear";

    // A cell the model has but no packet has filled stays on screen with a word
    // saying so: a cell that vanished until a reading arrived reads as a missing
    // feature rather than a missing reading.
    return pod.level === LEVEL_UNKNOWN ? "Not reported yet" : "";
}

// The lowest level the bar mark worries about. Unknown pods are ignored, so a
// case nobody has heard from cannot read as 0%.
function lowestLevel(status) {
    const levels = status.isHeadset
        ? [ status.headset.level ]
        : [ status.left.level, status.right.level, status.caseBattery.level ];

    let lowest = LEVEL_UNKNOWN;

    for (const level of levels) {
        if (level === LEVEL_UNKNOWN)
            continue;

        lowest = lowest === LEVEL_UNKNOWN ? level : Math.min(lowest, level);
    }

    return lowest;
}

// librepods-ctl's stderr is a sentence or three, and a row holds one line.
function elideError(text) {
    const value = String(text === undefined || text === null ? "" : text).replace(/\s+/g, " ").trim();

    if (value.length === 0)
        return "librepods-ctl rejected the command";

    return value.length > 120 ? value.substring(0, 119) + "…" : value;
}
