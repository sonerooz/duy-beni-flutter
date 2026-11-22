"""Oyun seslerini üretir (assets/audio/*.wav). Ses dosyası gerekmez, saf sinüs tonlarıdır.

    python tool/make_sounds.py

Eski Godot sürümündeki sesin aynısı: tık, son, bitti ve son 5 saniye için
giderek tizleşen "kalp atışı" çift bipi.
"""
import os
import struct
import wave

import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'audio')


def tone(freq, dur, vol=0.6):
    n = int(SR * dur)
    i = np.arange(n)
    t = i / SR
    # Başta 5 ms, sonda 20 ms yumuşatma: tık sesi çıkmasın.
    env = np.minimum(1.0, (n - i) / (SR * 0.02)) * np.minimum(1.0, i / (SR * 0.005))
    return np.sin(2 * np.pi * freq * t) * vol * env


def save(name, x):
    x = np.clip(x, -1, 1)
    data = (x * 32767).astype('<i2').tobytes()
    with wave.open(os.path.join(OUT, name + '.wav'), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data)
    print(name, f'{len(x) / SR:.2f}s')


os.makedirs(OUT, exist_ok=True)
save('tik', tone(880, 0.08))
save('son', tone(1320, 0.12))
save('bitti', tone(440, 0.7, 0.8))
for kalan in range(1, 6):
    f = 660 * 1.19 ** (5 - kalan)  # 5 -> 660 Hz ... 1 -> ~1320 Hz
    gap = np.zeros(int(SR * 0.06))
    save(f'kalp{kalan}', np.concatenate([tone(f, 0.09, 0.7), gap, tone(f * 1.26, 0.11, 0.7)]))
