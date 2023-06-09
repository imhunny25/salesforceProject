function createCommonjsModule(fn, module) {
    return (module = { exports: {} }), fn(module, module.exports), module.exports;
}

let rngBrowser = createCommonjsModule(function (module) {
    // Unique ID creation requires a high quality random # generator.  In the
    // browser this is a little complicated due to unknown quality of Math.random()
    // and inconsistent support for the `crypto` API.  We do the best we can via
    // feature-detection

    // getRandomValues needs to be invoked in a context where "this" is a Crypto
    // implementation. Also, find the complete implementation of crypto on IE11.
    let getRandomValues =
        (typeof crypto != "undefined" && crypto.getRandomValues && crypto.getRandomValues.bind(crypto)) ||
        (typeof msCrypto != "undefined" &&
            typeof window.msCrypto.getRandomValues == "function" &&
            msCrypto.getRandomValues.bind(msCrypto));

    if (getRandomValues) {
        // WHATWG crypto RNG - http://wiki.whatwg.org/wiki/Crypto
        let rnds8 = new Uint8Array(16); // eslint-disable-line no-undef

        module.exports = function whatwgRNG() {
            getRandomValues(rnds8);
            return rnds8;
        };
    } else {
        // Math.random()-based (RNG)
        //
        // If all else fails, use Math.random().  It's fast, but is of unspecified
        // quality.
        let rnds = new Array(16);

        module.exports = function mathRNG() {
            for (let i = 0, r; i < 16; i++) {
                if ((i & 0x03) === 0) r = Math.random() * 0x100000000;
                rnds[i] = (r >>> ((i & 0x03) << 3)) & 0xff;
            }

            return rnds;
        };
    }
});

/**
 * Convert array of 16 byte values to UUID string format of the form:
 * XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
 */
let byteToHex = [];
for (let i = 0; i < 256; ++i) {
    byteToHex[i] = (i + 0x100).toString(16).substr(1);
}

function bytesToUuid(buf, offset) {
    let i = offset || 0;
    let bth = byteToHex;
    // join used to fix memory issue caused by concatenation: https://bugs.chromium.org/p/v8/issues/detail?id=3175#c4
    return [
        bth[buf[i++]],
        bth[buf[i++]],
        bth[buf[i++]],
        bth[buf[i++]],
        "-",
        bth[buf[i++]],
        bth[buf[i++]],
        "-",
        bth[buf[i++]],
        bth[buf[i++]],
        "-",
        bth[buf[i++]],
        bth[buf[i++]],
        "-",
        bth[buf[i++]],
        bth[buf[i++]],
        bth[buf[i++]],
        bth[buf[i++]],
        bth[buf[i++]],
        bth[buf[i++]]
    ].join("");
}

let bytesToUuid_1 = bytesToUuid;

function v4(options, buf, offset) {
    let i = (buf && offset) || 0;

    if (typeof options == "string") {
        buf = options === "binary" ? new Array(16) : null;
        options = null;
    }
    options = options || {};

    let rnds = options.random || (options.rng || rngBrowser)();

    // Per 4.4, set bits for version and `clock_seq_hi_and_reserved`
    rnds[6] = (rnds[6] & 0x0f) | 0x40;
    rnds[8] = (rnds[8] & 0x3f) | 0x80;

    // Copy bytes to buffer, if provided
    if (buf) {
        for (let ii = 0; ii < 16; ++ii) {
            buf[i + ii] = rnds[ii];
        }
    }

    return buf || bytesToUuid_1(rnds);
}

let v4_1 = v4;
let v4_2 = v4_1.uuidv4;

export default v4_1;
export { v4_2 as uuidv4 };