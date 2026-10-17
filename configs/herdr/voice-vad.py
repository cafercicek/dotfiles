#!/usr/bin/env python3
"""Speech / hallucination guards for Herdr voice dictation.

Logic inspired by yusufipk/dikte vad.py (relative noise floor + stock phrases).
CLI:
  voice-vad.py check-raw <file.raw>   # s16le mono 16kHz; exit 0=speech, 1=silent
  voice-vad.py check-text <seconds>   # read transcript on stdin; exit 0=ok, 1=junk
"""

from __future__ import annotations

import math
import re
import struct
import sys
import unicodedata

SAMPLE_RATE = 16000
CHUNK_SECONDS = 0.05  # 50ms RMS windows
SILENCE_DB = -55.0
MARGIN_DB = 10.0
MIN_VOICED_SECONDS = 0.3

# Short-clip stock phrases Whisper invents for silence / noise.
HALLUCINATIONS = {
    "altyazi mk",
    "altyazi m k",
    "altyazi",
    "altyazilar",
    "abone olmayi unutmayin",
    "izlediginiz icin tesekkurler",
    "izlediginiz icin tesekkur ederim",
    "izlediginiz icin tesekkur ederiz",
    "kanalima abone olmayi unutmayin",
    "thanks for watching",
    "thank you for watching",
    "please subscribe",
    "subscribe to my channel",
    "you",
    "bye",
    "thank you",
    "thanks",
    "the end",
    "subtitle",
    "subtitles",
}

_PUNCTUATION = re.compile(r"[^\w\s]", re.UNICODE)
_SPACES = re.compile(r"\s+")


def to_db(value: float) -> float:
    return 20 * math.log10(value) if value > 0 else -120.0


def _percentile(values: list[float], fraction: float) -> float:
    if not values:
        return 0.0
    ordered = sorted(values)
    index = min(len(ordered) - 1, max(0, int(len(ordered) * fraction)))
    return ordered[index]


def analyse_rms(rms_values: list[float], chunk_seconds: float, margin_db: float = MARGIN_DB):
    if not rms_values:
        return {
            "noise_db": -120.0,
            "speech_db": -120.0,
            "dynamic_db": 0.0,
            "voiced_seconds": 0.0,
            "duration_seconds": 0.0,
        }
    noise = _percentile(rms_values, 0.10)
    speech = _percentile(rms_values, 0.90)
    noise_db, speech_db = to_db(noise), to_db(speech)
    gate_db = noise_db + margin_db
    voiced = sum(1 for value in rms_values if to_db(value) >= gate_db)
    return {
        "noise_db": noise_db,
        "speech_db": speech_db,
        "dynamic_db": speech_db - noise_db,
        "voiced_seconds": voiced * chunk_seconds,
        "duration_seconds": len(rms_values) * chunk_seconds,
    }


def is_silent(stats: dict, silence_db: float = SILENCE_DB, margin_db: float = MARGIN_DB,
              min_voiced_seconds: float = MIN_VOICED_SECONDS) -> bool:
    if stats["speech_db"] < silence_db:
        return True
    if stats["voiced_seconds"] < min_voiced_seconds:
        return True
    if stats["speech_db"] < silence_db + 12 and stats["dynamic_db"] < margin_db * 0.6:
        return True
    return False


def raw_s16le_stats(path: str) -> dict:
    with open(path, "rb") as f:
        data = f.read()
    if len(data) < 2:
        return analyse_rms([], CHUNK_SECONDS)
    # Trim odd trailing byte.
    n = len(data) // 2
    samples = struct.unpack("<" + "h" * n, data[: n * 2])
    chunk = max(1, int(SAMPLE_RATE * CHUNK_SECONDS))
    rms_values: list[float] = []
    for i in range(0, len(samples), chunk):
        window = samples[i : i + chunk]
        if not window:
            continue
        mean_sq = sum(s * s for s in window) / len(window)
        # Normalize to ~[-1, 1] full-scale.
        rms_values.append(math.sqrt(mean_sq) / 32768.0)
    return analyse_rms(rms_values, CHUNK_SECONDS)


def _normalise(text: str) -> str:
    folded = unicodedata.normalize("NFKD", text.lower())
    folded = "".join(c for c in folded if not unicodedata.combining(c))
    folded = folded.replace("ı", "i").replace("ş", "s").replace("ğ", "g")
    folded = folded.replace("ç", "c").replace("ö", "o").replace("ü", "u")
    return _SPACES.sub(" ", _PUNCTUATION.sub("", folded)).strip()


def looks_like_hallucination(text: str, duration_seconds: float, max_duration: float = 6.0) -> bool:
    if duration_seconds > max_duration:
        return False
    normalised = _normalise(text)
    if not normalised:
        return True
    if normalised in HALLUCINATIONS:
        return True
    words = normalised.split()
    for phrase in HALLUCINATIONS:
        parts = phrase.split()
        if len(parts) >= 2 and words and len(words) % len(parts) == 0:
            if " ".join(words) == " ".join(parts * (len(words) // len(parts))):
                return True
    return False


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print(__doc__, file=sys.stderr)
        return 2
    cmd = argv[1]
    if cmd == "check-raw":
        if len(argv) < 3:
            print("usage: voice-vad.py check-raw <file.raw>", file=sys.stderr)
            return 2
        stats = raw_s16le_stats(argv[2])
        silent = is_silent(stats)
        print(
            f"duration={stats['duration_seconds']:.2f}s "
            f"speech_db={stats['speech_db']:.1f} "
            f"voiced={stats['voiced_seconds']:.2f}s "
            f"silent={int(silent)}"
        )
        return 1 if silent else 0
    if cmd == "check-text":
        if len(argv) < 3:
            print("usage: voice-vad.py check-text <duration_seconds>", file=sys.stderr)
            return 2
        duration = float(argv[2])
        text = sys.stdin.read()
        junk = looks_like_hallucination(text, duration)
        print(f"hallucination={int(junk)}")
        return 1 if junk else 0
    print(f"unknown command: {cmd}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
