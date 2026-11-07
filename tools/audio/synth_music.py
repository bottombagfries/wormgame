# Composes the lobby music from scratch (no samples): a slow, seamless 48 s western loop in A minor —
# fingerpicked guitar (Karplus-Strong plucks) over Am-G-F-E, a soft bass, and a whistled melody in the
# second half. Writes assets/audio/Music_Lobby.wav (mono, 44.1 kHz, 16-bit).
#
#   "C:\Program Files\Blender Foundation\Blender 5.2\5.2\python\bin\python.exe" -I tools/audio/synth_music.py
#
# Upload: powershell -File tools/upload_asset.ps1 -File assets/audio/Music_Lobby.wav -Type Audio -Name Music_Lobby
import os
import wave

import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "assets", "audio")
rng = np.random.default_rng(3)

BPM = 80
BEAT = 60 / BPM
BAR = BEAT * 4
BARS = 16
LOOP = BAR * BARS  # 48 s
TAIL = 4.0  # reverb / ringing past the loop end, folded back onto the start so the loop is seamless

# Guitar voicings (low to high) and the bass root, two bars each.
CHORDS = {
    "Am": [110.00, 164.81, 220.00, 261.63, 329.63],
    "G": [98.00, 146.83, 196.00, 246.94, 293.66],
    "F": [87.31, 130.81, 174.61, 220.00, 261.63],
    "E": [82.41, 123.47, 164.81, 207.65, 246.94],
}
PROGRESSION = ["Am", "G", "F", "E"] * 2  # 8 blocks x 2 bars = 16 bars
ARP = [0, 2, 3, 4, 1, 3, 2, 4]  # string order for the eight eighth notes of a bar

# Whistle melody, bars 9-16: per chord block, (beat offset, length in beats, Hz).
MELODY = {
    "Am": [(0, 1.5, 659.25), (1.5, 0.5, 587.33), (2, 1, 523.25), (3, 1, 440.00), (4, 3, 329.63)],
    "G": [(0, 1.5, 587.33), (1.5, 0.5, 523.25), (2, 1, 493.88), (3, 1, 392.00), (4, 3, 293.66)],
    "F": [(0, 1.5, 523.25), (1.5, 0.5, 440.00), (2, 1, 349.23), (3, 1, 440.00), (4, 3, 523.25)],
    "E": [(0, 1, 493.88), (1, 1, 415.30), (2, 2, 329.63), (4, 3, 493.88)],
}


def pluck(freq, seconds, decay=0.996, brightness=0.5):
    """Karplus-Strong plucked string."""
    n = int(seconds * SR)
    period = max(2, int(round(SR / freq)))
    buf = rng.uniform(-1, 1, period)
    # soften the attack a little
    for _ in range(int(brightness * 3)):
        buf = 0.5 * (buf + np.roll(buf, 1))
    out = np.empty(n)
    for i in range(n):
        j = i % period
        out[i] = buf[j]
        buf[j] = decay * 0.5 * (buf[j] + buf[(j + 1) % period])
    return out


def bass(freq, seconds):
    t = np.arange(int(seconds * SR)) / SR
    tone = np.sin(2 * np.pi * freq * t) + 0.35 * np.sin(2 * np.pi * 2 * freq * t)
    return tone * np.exp(-t * 2.2) * np.clip(t / 0.01, 0, 1)


def whistle(freq, seconds):
    t = np.arange(int(seconds * SR)) / SR
    vib = 1 + 0.006 * np.sin(2 * np.pi * 5.5 * t) * np.clip((t - 0.15) / 0.3, 0, 1)
    phase = 2 * np.pi * np.cumsum(freq * vib) / SR
    tone = np.sin(phase) + 0.08 * np.sin(2 * phase)
    breath = np.convolve(rng.uniform(-1, 1, len(t)), np.ones(12) / 12, mode="same") * 0.05
    env = np.clip(t / 0.06, 0, 1) * np.clip((seconds - t) / 0.18, 0, 1)
    return (tone + breath) * env


def place(track, sound, start):
    s = int(start * SR)
    end = min(len(track), s + len(sound))
    track[s:end] += sound[: end - s]


def reverb(x, mix=0.28):
    out = np.copy(x)
    for delay_ms, gain in ((29.7, 0.8), (37.1, 0.78), (41.1, 0.76), (43.7, 0.74), (53.3, 0.7)):
        d = int(SR * delay_ms / 1000)
        y = np.copy(x)
        for i in range(d, len(y)):
            y[i] += gain * y[i - d]
        out += mix * y / 5
    return out


def compose():
    total = LOOP + TAIL
    guitar = np.zeros(int(total * SR))
    low = np.zeros_like(guitar)
    lead = np.zeros_like(guitar)
    for block, chord in enumerate(PROGRESSION):
        voicing = CHORDS[chord]
        block_start = block * 2 * BAR
        for bar in range(2):
            bar_start = block_start + bar * BAR
            for step, string in enumerate(ARP):
                accent = 1.0 if step % 4 == 0 else 0.7
                swing = 0.03 if step % 2 == 1 else 0.0  # a lazy swing on the off-beats
                place(guitar, pluck(voicing[string], 2.2) * accent, bar_start + step * BEAT / 2 + swing)
            for beat in (0, 2):
                place(low, bass(voicing[0] / 2, 1.4), bar_start + beat * BEAT)
        if block >= 4:  # whistle in the second half
            for offset, length, freq in MELODY[chord]:
                place(lead, whistle(freq, length * BEAT), block_start + offset * BEAT)
    mixed = guitar * 0.55 + low * 0.45 + lead * 0.32
    mixed = reverb(mixed)
    # Fold the tail back onto the start so the loop has no seam.
    n, m = int(LOOP * SR), int(TAIL * SR)
    loop = mixed[:n].copy()
    loop[:m] += mixed[n : n + m]
    return loop


if __name__ == "__main__":
    x = compose()
    x = x - np.mean(x)
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.8
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, "Music_Lobby.wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())
    print(f"lobby music: {len(x) / SR:.1f}s -> {path}")
