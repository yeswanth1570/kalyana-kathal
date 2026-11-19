"""Reproducible original sound assets, using only Python's standard library."""
from pathlib import Path
import math, random, struct, wave

ROOT = Path(__file__).parent / 'audio'
RATE = 22050

def write(name, samples, folder='sfx'):
    destination = ROOT / folder
    destination.mkdir(parents=True, exist_ok=True)
    with wave.open(str(destination / (name + '.wav')), 'wb') as out:
        out.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        out.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, n)) * 24000)) for n in samples))

def tone(hz, t):
    return math.sin(2*math.pi*hz*t) + .18*math.sin(4*math.pi*hz*t)

for name, seconds, start, end in [('letter', .09, 650, 950), ('hit', .16, 180, 65), ('parry', .27, 530, 1300), ('win', .8, 360, 900)]:
    signal=[]
    for n in range(int(seconds*RATE)):
        t=n/RATE
        f=start+(end-start)*t/seconds
        signal.append(.35 * tone(f,t) * (1-t/seconds)**2)
    write(name,signal)

# A 16-bar, pentatonic cinema waltz; no sampled or copyrighted recordings.
beat=.30
length=beat*48
data=[0.0]*int(length*RATE)
notes=[0,4,7,9,7,4,2,4,7,12,9,7,4,2,0,2,4,7,9,12,14,12,9,7]
random.seed(28)
def add(start,duration,hz,amp):
    for i in range(int(duration*RATE)):
        p=int(start*RATE)+i
        if p >= len(data):break
        t=i/RATE
        envelope=min(1,t/.008)*math.exp(-t*5/max(duration,.1))
        data[p]+=tone(hz,t)*amp*envelope
for b in range(48):
    if b%2==0:
        note=notes[(b//2)%len(notes)]
        add(b*beat,beat*1.7,220*2**(note/12),.14)
    root=[110,130.8128,146.8324,110][(b//12)%4]
    if b%3==0:add(b*beat,beat*1.4,root,.16)
    else:
        for ratio in [2,2.5,3]:add(b*beat,beat*.55,root*ratio,.035)
    for i in range(int(.035*RATE)):
        p=int(b*beat*RATE)+i
        if p<len(data):data[p]+=random.uniform(-1,1)*.03*math.exp(-i/(RATE*.009))
write('cinema',data,folder='music')
print('Created 5 original WAV assets')
