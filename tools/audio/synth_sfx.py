# Synthesizes the game's sound effects from scratch (no samples, so no licensing questions) and writes
# assets/audio/Sfx_<Key>.wav (mono, 44.1 kHz, 16-bit). Keys match Config/Sounds.luau.
#
#   "C:\Program Files\Blender Foundation\Blender 5.2\5.2\python\bin\python.exe" -I tools/audio/synth_sfx.py [Key ...]
#
# Then upload with: powershell -ExecutionPolicy Bypass -File tools/upload_assets.ps1 Audio Sfx_Explosion ...
import os
import sys
import wave

import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "assets", "audio")
rng = np.random.default_rng(7)


# --- building blocks -------------------------------------------------------------------------------------

def t_axis(seconds):
    return np.arange(int(seconds * SR)) / SR


def noise(seconds):
    return rng.uniform(-1, 1, int(seconds * SR))


def env(seconds, attack, release, curve=3.0):
    """Attack ramp then exponential-ish decay over the rest."""
    t = t_axis(seconds)
    a = np.clip(t / max(attack, 1e-4), 0, 1)
    r = np.clip((seconds - t) / max(release, 1e-4), 0, 1) ** curve
    return a * r


def decay(seconds, rate):
    return np.exp(-t_axis(seconds) * rate)


def lowpass(x, cutoff):
    """One-pole lowpass; `cutoff` is Hz or an array of Hz per sample."""
    cutoff = np.maximum(np.broadcast_to(np.asarray(cutoff, dtype=float), x.shape), 20.0)  # <= 0 Hz blows up
    alpha = 1 - np.exp(-2 * np.pi * cutoff / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc += alpha[i] * (x[i] - acc)
        y[i] = acc
    return y


def highpass(x, cutoff):
    return x - lowpass(x, cutoff)


def bandpass(x, low, high):
    return highpass(lowpass(x, high), low)


def sine_sweep(seconds, f0, f1, curve=1.0):
    t = t_axis(seconds)
    f = f0 + (f1 - f0) * (t / seconds) ** curve
    return np.sin(2 * np.pi * np.cumsum(f) / SR)


def tone(seconds, freq, partials=((1, 1.0),), vibrato=0.0, vib_rate=5.0):
    t = t_axis(seconds)
    f = freq * (1 + vibrato * np.sin(2 * np.pi * vib_rate * t))
    phase = 2 * np.pi * np.cumsum(f) / SR
    return sum(a * np.sin(phase * m) for m, a in partials)


def bell(seconds, freq, rate=3.0):
    partials = ((1, 1.0), (2.76, 0.5), (5.4, 0.25), (8.93, 0.12))
    t = t_axis(seconds)
    return sum(a * np.sin(2 * np.pi * freq * m * t) * np.exp(-t * rate * m ** 0.5) for m, a in partials)


def reverb(x, mix=0.3, decay_s=1.2):
    """A few feedback combs: cheap room tail."""
    out = np.copy(x)
    for delay_ms, gain in ((29.7, 0.77), (37.1, 0.74), (41.1, 0.71), (43.7, 0.69)):
        d = int(SR * delay_ms / 1000)
        g = gain ** (1.2 / decay_s)
        y = np.copy(x)
        for i in range(d, len(y)):
            y[i] += g * y[i - d]
        out += mix * y / 4
    return out


def pad(x, seconds):
    return np.concatenate([x, np.zeros(int(seconds * SR))])


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[: len(p)] += p
    return out


def at(x, start_s, total_s):
    out = np.zeros(int(total_s * SR))
    s = int(start_s * SR)
    out[s : s + len(x)] += x[: len(out) - s]
    return out


def write(name, x, peak=0.89):
    x = x - np.mean(x)
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    fade = min(len(x) // 10, int(0.01 * SR))
    x[:fade] *= np.linspace(0, 1, fade)
    x[-fade:] *= np.linspace(1, 0, fade)
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, f"Sfx_{name}.wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())
    print(f"{name}: {len(x) / SR:.2f}s -> {path}")


# --- the sounds -------------------------------------------------------------------------------------------

def explosion():
    s = 2.4
    boom = lowpass(noise(s), 2500 * decay(s, 2.5) + 80) * env(s, 0.005, s, 2.5)
    thump = sine_sweep(0.8, 90, 35) * decay(0.8, 4)
    crackle = (rng.uniform(0, 1, int(s * SR)) > 0.9985) * rng.uniform(-1, 1, int(s * SR))
    crackle = lowpass(crackle, 3000) * decay(s, 1.5) * 6
    return reverb(mix(boom * 1.4, thump * 1.2, crackle), 0.35, 1.8)


def train_horn():
    s = 2.6
    chord = sum(tone(s, f, ((1, 1), (2, 0.35), (3, 0.15)), vibrato=0.004, vib_rate=6) for f in (311, 392, 466))
    breath = bandpass(noise(s), 300, 2500) * 0.25
    return reverb((chord + breath) * env(s, 0.12, 0.7, 1.5), 0.3, 1.5)


def lever_pulled():
    s = 0.7
    ratchet = sum(at(bandpass(noise(0.02), 1500, 6000) * decay(0.02, 150), k * 0.045, s) for k in range(6))
    clunk = at((tone(0.5, 180, ((1, 1), (2.7, 0.5))) + lowpass(noise(0.5), 600) * 0.6) * decay(0.5, 14), 0.3, s)
    return mix(ratchet * 0.6, clunk)


def furnace_burn():
    s = 1.8
    sweep = np.linspace(0, 1, int(s * SR))
    whoosh = bandpass(noise(s), 120, 400 + 2600 * np.sin(np.pi * sweep)) * env(s, 0.25, 1.2, 1.5)
    crackle = (rng.uniform(0, 1, int(s * SR)) > 0.997) * rng.uniform(-1, 1, int(s * SR))
    return mix(whoosh * 1.3, lowpass(crackle, 4000) * env(s, 0.2, 1.4) * 3)


def pounce():
    s = 0.9
    burst = bandpass(noise(s), 150, 3500 * decay(s, 3) + 300) * env(s, 0.03, 0.8, 2)
    thump = sine_sweep(0.4, 120, 45) * decay(0.4, 9)
    return mix(burst * 1.2, thump)


def grab():
    s = 0.8
    growl = tone(s, 70, ((1, 1), (2, 0.6), (3, 0.4), (5, 0.2)), vibrato=0.08, vib_rate=23) * env(s, 0.04, 0.6)
    chomps = sum(at(lowpass(noise(0.08), 1800) * decay(0.08, 40), k * 0.14, s) for k in range(3))
    return mix(np.tanh(growl * 2) * 0.7, chomps * 1.4)


def mouth_escape():
    s = 1.0
    squelch = lowpass(noise(0.25), 900) * tone(0.25, 60, ((1, 1),), vibrato=0.3, vib_rate=30) * decay(0.25, 12)
    pop = sine_sweep(0.12, 200, 900) * decay(0.12, 25)
    whoosh = at(bandpass(noise(0.7), 400, 4000) * env(0.7, 0.1, 0.5), 0.15, s)
    return mix(squelch * 1.5, at(pop, 0.2, s) * 0.8, whoosh * 0.8)


def sonar_scream():
    s = 2.6
    t = t_axis(s)
    f = 260 + 700 * np.sin(np.pi * np.clip(t / 1.4, 0, 1)) ** 2
    f *= 1 + 0.03 * np.sin(2 * np.pi * 9 * t)
    phase = 2 * np.pi * np.cumsum(f) / SR
    voice = np.sin(phase + 2.5 * np.sin(phase * 1.5)) * env(s, 0.15, 1.6, 1.5)
    rasp = bandpass(noise(s), 800, 5000) * env(s, 0.1, 1.5) * 0.3
    return reverb(np.tanh((voice + rasp) * 2.2), 0.45, 2.2)


def chest_open():
    s = 0.9
    t = t_axis(0.6)
    creak_f = 110 + 40 * np.sin(2 * np.pi * 3 * t) + 25 * rng.standard_normal(len(t)).cumsum() / 400
    saw = (2 * ((np.cumsum(creak_f) / SR) % 1) - 1)
    creak = bandpass(saw, 300, 2200) * env(0.6, 0.05, 0.3)
    latch = bandpass(noise(0.03), 2000, 8000) * decay(0.03, 120)
    return mix(at(latch, 0.0, s) * 0.8, at(creak, 0.08, s))


def dig():
    s = 0.55
    grain = bandpass(noise(s), 600, 5000) * (0.6 + 0.4 * (rng.uniform(0, 1, int(s * SR)) > 0.5))
    thud = lowpass(noise(0.15), 400) * decay(0.15, 25)
    return mix(grain * env(s, 0.02, 0.4) * 0.8, at(thud, 0.32, s) * 1.2)


def revive():
    s = 2.4
    notes = (523.25, 659.25, 783.99, 1046.5)
    chime = sum(at(bell(1.8, f, 2.2), k * 0.13, s) for k, f in enumerate(notes))
    shimmer = bandpass(noise(s), 4000, 9000) * env(s, 0.3, 1.8) * 0.08
    return reverb(chime + shimmer, 0.45, 2.0)


def airdrop():
    s = 1.2
    thud = sine_sweep(0.5, 80, 30) * decay(0.5, 7)
    crunch = bandpass(noise(0.4), 200, 2500) * decay(0.4, 10)
    dust = lowpass(noise(s), 900) * env(s, 0.05, 1.0) * 0.4
    return mix(thud * 1.3, crunch, dust)


def balloon_arrives():
    s = 2.4
    t = t_axis(s)
    roar = lowpass(noise(s), 700 + 300 * np.sin(2 * np.pi * 11 * t)) * env(s, 0.2, 1.2) * 1.4
    ding = at(bell(1.4, 1318.5, 2.5), 1.0, s) * 0.35
    return reverb(mix(roar, ding), 0.25, 1.2)


def sundown():
    s = 4.0
    gong = bell(s, 98.0, 0.7) + 0.5 * bell(s, 146.8, 0.8)
    wind = lowpass(noise(s), 300 + 500 * env(s, 1.5, 2.5)) * env(s, 1.2, 2.5, 1.2) * 0.8
    return reverb(mix(gong, wind), 0.4, 2.5)


def pickup():
    s = 0.18
    return sine_sweep(s, 600, 1100) * env(s, 0.005, 0.15) + bandpass(noise(s), 2000, 6000) * decay(s, 60) * 0.2


def throw():
    s = 0.4
    sweep = np.linspace(0, 1, int(s * SR))
    return bandpass(noise(s), 300, 1200 + 3500 * np.sin(np.pi * sweep)) * env(s, 0.08, 0.25, 1.5)


def ambience():
    """20 s of desert wind, crossfaded onto itself so it loops without a seam."""
    s, xf = 20.0, 3.0
    total = s + xf
    t = t_axis(total)
    cutoff = 380 + 180 * np.sin(2 * np.pi * t / 7.3) + 120 * np.sin(2 * np.pi * t / 3.1 + 1)
    wind = lowpass(noise(total), cutoff) * (0.7 + 0.3 * np.sin(2 * np.pi * t / 5.7))
    gust = bandpass(noise(total), 500, 1500) * (np.sin(2 * np.pi * t / 9.1) ** 8) * 0.25
    x = wind + gust
    n, m = int(s * SR), int(xf * SR)
    head, tail = x[:m], x[n : n + m]
    fade = np.linspace(0, 1, m)
    out = x[:n].copy()
    out[:m] = head * fade + tail * (1 - fade)
    return out


# --- UI sounds (Config/Sounds Ui*; the Theme's buttons, toasts and role card play them) -------------------

def ui_click():
    s = 0.09
    return tone(s, 880, ((1, 1), (2, 0.3))) * decay(s, 55) + bandpass(noise(s), 2000, 7000) * decay(s, 120) * 0.3


def ui_hover():
    s = 0.06
    return tone(s, 1320) * env(s, 0.005, 0.05) * 0.6


def ui_error():
    s = 0.32
    buzz = tone(s, 140, ((1, 1), (2, 0.6), (3, 0.4), (4, 0.2)))
    return np.concatenate([buzz[: int(0.13 * SR)] * env(0.13, 0.005, 0.08), np.zeros(int(0.05 * SR)),
                           buzz[: int(0.14 * SR)] * env(0.14, 0.005, 0.1)])


def ui_objective():
    s = 1.3
    notes = (659.25, 783.99, 1046.5)
    return reverb(sum(at(bell(0.9, f, 3.0), k * 0.09, s) for k, f in enumerate(notes)), 0.3, 1.0)


def ui_reveal():
    s = 1.8
    hit = sine_sweep(0.6, 70, 40) * decay(0.6, 5)
    swell = bandpass(noise(s), 200, 2500 * env(s, 0.6, 1.0) + 300) * env(s, 0.5, 1.1, 1.5) * 0.6
    chord = sum(tone(s, f, ((1, 1), (2, 0.3))) for f in (196, 247, 294)) * env(s, 0.15, 1.3, 2) * 0.5
    return reverb(mix(hit * 1.3, swell, chord), 0.35, 1.6)


def ui_kill():
    s = 0.7
    return reverb(mix(sine_sweep(s, 520, 160, 0.6) * env(s, 0.01, 0.6), lowpass(noise(0.2), 900) * decay(0.2, 18) * 0.6),
                  0.25, 0.8)


SOUNDS = {
    "UiClick": ui_click,
    "UiHover": ui_hover,
    "UiError": ui_error,
    "UiObjective": ui_objective,
    "UiReveal": ui_reveal,
    "UiKill": ui_kill,
    "Explosion": explosion,
    "TrainHorn": train_horn,
    "LeverPulled": lever_pulled,
    "FurnaceBurn": furnace_burn,
    "Pounce": pounce,
    "Grab": grab,
    "MouthEscape": mouth_escape,
    "SonarScream": sonar_scream,
    "ChestOpen": chest_open,
    "Dig": dig,
    "Revive": revive,
    "Airdrop": airdrop,
    "BalloonArrives": balloon_arrives,
    "Sundown": sundown,
    "Pickup": pickup,
    "Throw": throw,
    "Ambience": ambience,
}

if __name__ == "__main__":
    wanted = sys.argv[1:] or list(SOUNDS)
    for key in wanted:
        x = SOUNDS[key]()
        if key == "Ambience":
            # No fades on a loop: write it raw-normalized.
            x = x / (np.max(np.abs(x)) + 1e-9) * 0.7
            os.makedirs(OUT, exist_ok=True)
            path = os.path.join(OUT, f"Sfx_{key}.wav")
            with wave.open(path, "wb") as w:
                w.setnchannels(1)
                w.setsampwidth(2)
                w.setframerate(SR)
                w.writeframes((x * 32767).astype(np.int16).tobytes())
            print(f"{key}: {len(x) / SR:.2f}s (loop) -> {path}")
        else:
            write(key, x)
