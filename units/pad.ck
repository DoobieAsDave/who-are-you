BPM tempo;

Gain master;

SawOsc voice1 => master;
SawOsc voice2 => master;
SawOsc voice3 => master;
SawOsc voice4 => master;
SawOsc voice5 => master;

master => ADSR adsr => LPF filter => NRev reverb => Dyno dyno => Pan2 stereo => dac;

///

Std.mtof(52) => filter.freq;
2 => filter.Q;

.1 => reverb.mix;

dyno.compress();

///

1.0 / 5.0 => float maxVolume;
maxVolume => master.gain;

42 => int key;
tempo.note * 2 => dur chordDuration;

dur attack, decay, release, riseDuration, fallDuration;
float sustain;

float filterCutOff;
float filterQ;
float reverbMix;
float stereoMix;
float masterVolume;

///

function void runPad(int sequence[], int harmony[], dur durations[]) {
    while(true) {        
        for (0 => int step; step < sequence.cap(); step++) {
            setEnvelope(durations[step]);

            key + sequence[step] => int baseNote;

            Std.mtof(baseNote) => voice1.freq;            
            Std.mtof(baseNote + 7) => voice3.freq;                        

            if (harmony[step]) {
                Std.mtof(baseNote + 4) => voice2.freq;
                Std.mtof(baseNote + 11) => voice4.freq;
                Std.mtof(baseNote + 16) => voice5.freq;
            }
            else {
                Std.mtof(baseNote + 3) => voice2.freq;
                Std.mtof(baseNote + 10) => voice4.freq;
                Std.mtof(baseNote + 15) => voice5.freq;
            }

            adsr.keyOn();                    
            durations[step] - release => now;
            adsr.keyOff();
            release => now;
        }
    }
}
function void setEnvelope(dur currentDuration) {
    currentDuration * .5 => riseDuration;
    currentDuration * .25 => fallDuration;

    riseDuration * .75 => attack;
    riseDuration * .25 => decay;
    .8 => sustain;
    fallDuration => release;

    adsr.set(attack, decay, sustain, release);
}

///

function void modulateFilterCutOff(LPF filter, dur modTime, float min, float max, float aps) {
    aps => float step;
    max - min => float range;
    (range - aps) * 2 => float stepNumbers;

    max => filterCutOff;

    while(true) {
        filterCutOff => filter.freq;
        step +=> filterCutOff;

        if (filterCutOff >= max) {
            aps => step;
        }
        else if (filterCutOff <= min) {
            aps * -1 => step;
        }        

        modTime / stepNumbers => now;
    }

}
function void modulateFilterQ(LPF filter, dur modTime, float min, float max, float aps) {
    aps => float step;
    max - min => float range;
    (range / aps) * 2 => float stepNumbers;

    min => filterQ;

    while(true) {
        filterQ => filter.Q;
        step +=> filterQ;

        if (filterQ >= max) {
            aps * -1 => step;
        }
        else if (filterQ <= min) {
            aps => step;
        }        

        modTime / stepNumbers => now;
    }
}
function void modulateReverbMix(NRev reverb, dur modTime, float min, float max, float aps) {
    aps => float step;
    max - min => float range;
    (range / aps) * 2 => float stepNumbers;

    min => reverbMix;

    while(true) {
        reverbMix => reverb.mix;
        step +=> reverbMix;

        if (reverbMix >= max) {
            aps * -1 => step;
        }
        else if (reverbMix <= min) {
            aps => step;
        }        

        modTime / stepNumbers => now;
    }
}
function void modulateStereoPan(Pan2 stereo, dur modTime, float min, float max, float aps) {
    aps => float step;
    max - min => float range;
    (range / aps) * 2 => float stepNumbers;

    min => stereoMix;

    while(true) {
        stereoMix => stereo.pan;
        step +=> stereoMix;

        if (stereoMix >= max) {
            aps * -1 => step;
        }
        else if (stereoMix <= min) {
            aps => step;
        }

        modTime / stepNumbers => now;
    }
}
function void modulateVolume(Gain master, dur modTime, float min, float max, float aps, int riseVolume) {
    aps => float step;
    max - min => float range;
    (range / aps) => float stepNumbers;

    if (riseVolume) {
        min => masterVolume;
    }
    else {
        max => masterVolume;
    }

    while(true) {
        masterVolume => master.gain;
        step +=> masterVolume;

        if (riseVolume) {
            if (masterVolume <= max) {
                aps => step;
            }
            else {
                0 => step;
            }
        }
        else {
            if (masterVolume >= min) {
                aps * -1 => step;
            }
            else {
                0 => step;
            }
        }

        <<< masterVolume >>>;
        
        modTime / stepNumbers => now;
    }
}

///

Shred padShred, filterCShred, filterQShred, reverbShred, stereoShred, volumeShred;

[0, 8] @=> int melodyA[];
[0, 0] @=> int harmonyA[];
[
    chordDuration,
    chordDuration
] @=> dur durationsA[];

[0, 8, 0, 5, 7] @=> int melodyB[];
[0, 0, 0, 0, 0] @=> int harmonyB[];
[
    chordDuration,
    chordDuration,
    chordDuration,
    chordDuration / 2,
    chordDuration / 2   
] @=> dur durationsB[];

///

/* spork ~ modulateVolume(master, tempo.note * 4, .0, maxVolume, .01, 1) @=> volumeShred;
tempo.note * 4 => now;
Machine.remove(volumeShred.id()); */
spork ~ runPad(melodyA, harmonyA, durationsA) @=> padShred;
tempo.note * 8 => now;

spork ~ modulateFilterCutOff(filter, tempo.note, Std.mtof(28), Std.mtof(76), -10.0) @=> filterCShred;
tempo.note * 8 => now;

/// Intro                                       16 
<<< "intro passed" >>>;

spork ~ modulateFilterQ(filter, tempo.note * 4, .2, 1.5, .001) @=> filterQShred;
tempo.note * 8 => now;

Machine.remove(filterCShred.id());
spork ~ modulateReverbMix(reverb, tempo.note * 2, .05, .2, .01) @=> reverbShred;
tempo.note => now;
spork ~ modulateFilterCutOff(filter, tempo.note / 3, Std.mtof(28), Std.mtof(76), -10.0) @=> filterCShred;
tempo.note => now;
Machine.remove(filterCShred.id());
spork ~ modulateFilterCutOff(filter, tempo.note, Std.mtof(28), Std.mtof(76), -10.0) @=> filterCShred;
tempo.note * 6 => now;

/// First verse                                 16
<<< "first verse passed" >>>;

Machine.remove(filterCShred.id());
Machine.remove(filterQShred.id());
Machine.remove(reverbShred.id());
tempo.note * 8 => now;

/// First refrain                               8
<<< "first refrain passed" >>>;

Machine.remove(padShred.id());
spork ~ modulateFilterCutOff(filter, tempo.note, Std.mtof(28), Std.mtof(76), -10.0) @=> filterCShred;
spork ~ modulateFilterQ(filter, tempo.note * 4, .2, 1.5, .001) @=> filterQShred;
spork ~ modulateReverbMix(reverb, tempo.note * 2, .05, .2, .01) @=> reverbShred;
spork ~ modulateStereoPan(stereo, tempo.note * 8, -1, 1, .01) @=> stereoShred;
spork ~ runPad(melodyB, harmonyB, durationsB) @=> padShred;
tempo.note * 16 => now;

Machine.remove(filterCShred.id());
spork ~ modulateFilterCutOff(filter, tempo.note / 4, Std.mtof(28), Std.mtof(76), -10.0) @=> filterCShred;
tempo.note => now;
Machine.remove(filterCShred.id());
spork ~ modulateFilterCutOff(filter, tempo.note, Std.mtof(28), Std.mtof(76), -10.0) @=> filterCShred;
tempo.note => now;
tempo.note * 14 => now;

/// Second verse                                16
<<< "second verse passed" >>>;

Machine.remove(filterCShred.id());
Machine.remove(filterQShred.id());
Machine.remove(reverbShred.id());
tempo.note * 8 => now;

/// Second refrain                              8
<<< "second refrain passed" >>>;
spork ~ modulateVolume(master, tempo.note * 8, maxVolume, .0, .01, 0) @=> volumeShred;
tempo.note * 8 => now;

Machine.remove(volumeShred.id());
Machine.remove(padShred.id());

<<< "pad finished" >>>;                         // 64 bars - 8 bars (outro) = 72 bars