BPM tempo;

Gain master;

SqrOsc bass => master;

master => ADSR adsr => LPF filter => Dyno dyno => dac;

.8  => master.gain;

1.8 => filter.Q;

dyno.compress();

///

33 => int key;
tempo.quarterNote => dur barDuration;
barDuration / 2 => dur noteDuration;

dur attack, decay, release;
float sustain;

///

function void runBass(int melody[]) {
    setEnvelope(noteDuration);       

    while(true) {
        for (0 => int step; step < melody.cap(); step++) {
            Std.mtof(melody[step]) => bass.freq;      
            Std.mtof(melody[step] + 12) => filter.freq;       
            
            if (step % 4 == 3) {
                for (0 => int repetition; repetition < 2; repetition++) {
                    if (repetition == 0) {
                        adsr.keyOn();
                        noteDuration - release => now;
                        adsr.keyOff();
                        release => now;     
                    }
                    else {
                        bass.freq() * 2 => bass.freq;

                        noteDuration / 2 => now;

                        adsr.keyOn();
                        (noteDuration / 2) - release => now;
                        adsr.keyOff();
                        release => now;     
                    }                    
                }

                continue;
            }   

            noteDuration => now;

            adsr.keyOn();
            noteDuration - release => now;
            adsr.keyOff();
            release => now;         
        }        
    }
}
function void setEnvelope(dur currentDuration) {
    currentDuration * .1 => attack;
    currentDuration * .2 => decay;
    .75 => sustain;
    currentDuration * .15 => release;

    adsr.set(attack, decay, sustain, release);
}

///

Shred bassShred;

[
    33, 33, 33, 33,
    33, 33, 33, 33,
    29, 29, 29, 29,
    29, 29, 29, 29
] @=> int melodyA[];
[
    33, 33, 33, 33,
    29, 29, 29, 29,
    35, 35, 35, 35,
    36, 36, 36, 36
] @=> int melodyB[];

///

tempo.note * 16 => now;
spork ~ runBass(melodyA) @=> bassShred;
tempo.note * 24 => now;
Machine.remove(bassShred.id());
spork ~ runBass(melodyB) @=> bassShred;
tempo.note * 40 => now;
Machine.remove(bassShred.id());

<<< "bas finished" >>>;
