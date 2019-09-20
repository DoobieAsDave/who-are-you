BPM tempo;

Gain master;

SndBuf kick => LPF kickLPF => master;
SndBuf snare => master;
SndBuf clap => master;
SndBuf openhat => master;
SndBuf crash => master;
SndBuf rim => master;

master => dac;

SndBuf hihat => Echo hihatEcho;
hihatEcho => Gain hihatFeedback => hihatEcho => dac;
SndBuf lowhat => Gain lowhatGain => Pan2 lowhatPan => dac;

/// 

me.dir(-1) + "audio/kick.wav" => kick.read;
me.dir(-1) + "audio/snare.wav" => snare.read;
me.dir(-1) + "audio/clap.wav" => clap.read;
me.dir(-1) + "audio/openhat.wav" => openhat.read;
me.dir(-1) + "audio/hihat.wav" => hihat.read;
me.dir(-1) + "audio/lowhat.wav" => lowhat.read;
me.dir(-1) + "audio/crash.wav" => crash.read;
me.dir(-1) + "audio/rim.wav" => rim.read;

kick.samples() => kick.pos;
snare.samples() => snare.pos;
clap.samples() => clap.pos;
openhat.samples() => openhat.pos;
hihat.samples() => hihat.pos;
lowhat.samples() => lowhat.pos;
crash.samples() => crash.pos;
rim.samples() => rim.pos;

///

Std.mtof(120) => kickLPF.freq;
-.3 => lowhatPan.pan;

tempo.sixteenthNote => hihatEcho.delay;
tempo.quarterNote => hihatEcho.max;

.1 => hihat.gain => hihatFeedback.gain => lowhat.gain => openhat.gain;
.5 => crash.gain;

1.0 / 2.5 => master.gain;

///

float echoMix;
float lowhatVolume;

///

function void runKick(int beatLength, int sequence[]) {
    tempo.note / sequence.cap() => dur stepDuration;   

    while(true) {
        for (0 => int beat; beat < beatLength; beat++) {
            for (0 => int step; step < sequence.cap(); step++) {                              
                if (sequence[step]) {
                    0 => kick.pos;
                }
                
                stepDuration => now;
            }
        }
    }
}
function void runSnare(int beatLength, int sequence[]) {
    tempo.note / sequence.cap() => dur stepDuration;   

    while(true) {
        for (0 => int beat; beat < beatLength; beat++) {
            for (0 => int step; step < sequence.cap(); step++) {                              
                if (sequence[step]) {
                    0 => snare.pos;
                }
                
                stepDuration => now;
            }
        }
    }
}
function void runHihat(int beatLength, int sequence[]) {
    tempo.note / sequence.cap() => dur stepDuration;   

    while(true) {
        for (0 => int beat; beat < beatLength; beat++) {
            for (0 => int step; step < sequence.cap(); step++) {                              
                if (sequence[step]) {
                    0 => hihat.pos;
                }

                if (beat % 2 == 1 && step == sequence.cap() - 1) {
                    for (0 => int repetition; repetition < 3; repetition++) {
                        Math.random2(Std.ftoi(hihat.samples() * .05), Std.ftoi(hihat.samples() * .1)) => hihat.pos;                        

                        stepDuration / 3 => now;
                    }
                    
                    continue;
                }
                
                stepDuration => now;
            }
        }
    }
}
function void runLowhat(int beatLength, int sequence[]) {
    tempo.note / sequence.cap() => dur stepDuration;   

    while(true) {
        for (0 => int beat; beat < beatLength; beat++) {
            for (0 => int step; step < sequence.cap(); step++) {                              
                if (sequence[step]) {
                    0 => lowhat.pos;
                }
                
                stepDuration => now;
            }
        }
    }
}
function void runRim(int beatLength, int sequence[]) {
    tempo.note / sequence.cap() => dur stepDuration;   

    while(true) {
        for (0 => int beat; beat < beatLength; beat++) {
            for (0 => int step; step < sequence.cap(); step++) {                              
                if (sequence[step]) {
                    0 => rim.pos;
                }

                if (beat == beatLength - 1 && sequence[step] == sequence.cap() - 2) {
                    0 => rim.pos;
                }
                
                stepDuration => now;
            }
        }
    }
}
function void runCrash(int beatLength, int sequence[]) {
    tempo.note / sequence.cap() => dur stepDuration;   

    while(true) {
        for (0 => int beat; beat < beatLength; beat++) {
            for (0 => int step; step < sequence.cap(); step++) {                              
                if (beat == 0 && sequence[step]) {
                    0 => crash.pos;
                }
                
                stepDuration => now;
            }
        }
    }
}
function void runOpenhat(int beatLength, int sequence[]) {
    tempo.note / sequence.cap() => dur stepDuration;   

    while(true) {
        for (0 => int beat; beat < beatLength; beat++) {
            for (0 => int step; step < sequence.cap(); step++) {                              
                if (sequence[step]) {
                    0 => openhat.pos;
                }
                
                stepDuration => now;
            }
        }
    }
}

///

function void modulateEchoMix(Echo echo, dur modTime, float min, float max, float aps) {    
    aps => float step;
    max - min => float range;
    (range / aps) * 2 => float stepNumbers;

    min => echoMix;

    while(true) {
        echoMix => echo.mix;
        step +=> echoMix;

        if (echoMix >= max) {
            aps * -1 => step;
        }
        else if (echoMix <= min) {
            aps => step;
        }        

        modTime / stepNumbers => now;
    }
}
function void modulateLowhatGain(Gain gain, dur modTime, float min, float max, float aps) {
    aps => float step;
    max - min => float range;
    (range / aps) * 2 => float stepNumbers;

    min => lowhatVolume;

    while(true) {
        lowhatVolume => gain.gain;
        step +=> lowhatVolume;

        if (lowhatVolume >= max) {
            aps * -1 => step;
        }
        else if (lowhatVolume <= min) {
            aps => step;
        }

        modTime / stepNumbers => now;
    }
}

/// Sporking threads


Shred kickShred, snareShred, hihatShred, lowhatShred, rimShred, crashShred;

tempo.note * 8 => now;
spork ~ runKick(4,    [1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0]) @=> kickShred;
tempo.note * 8 => now;
spork ~ runSnare(4,   [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0]) @=> snareShred;
spork ~ runHihat(4,   [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0]) @=> hihatShred;
tempo.note * 8 => now;
spork ~ runLowhat(4,  [0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1]) @=> lowhatShred;
spork ~ runRim(4,     [0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1]) @=> rimShred;
tempo.note * 8 => now;
spork ~ runCrash(4,  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]) @=> crashShred;
tempo.note * 16 => now;
Machine.remove(rimShred.id());
tempo.note * 4 => now;
Machine.remove(lowhatShred.id());
tempo.note * 4 => now;
Machine.remove(crashShred.id());
tempo.note * 4 => now;
Machine.remove(hihatShred.id());
tempo.note * 8 => now;
Machine.remove(kickShred.id());

/// 32

spork ~ runOpenhat(4, [0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0]);

spork ~ modulateEchoMix(hihatEcho, tempo.note * 2, .05, .8, .01);
spork ~ modulateLowhatGain(lowhatGain, tempo.note * 4, .05, .15, .01);

while(true)
    second => now;