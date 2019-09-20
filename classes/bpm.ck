public class BPM
{
    static dur note, halfNote, quarterNote, eighthNote, sixteenthNote, thirtiethNote;

    function void setBPM(float bpm) {
        60.0 / bpm => float spb;

        spb :: second => quarterNote;
        quarterNote * 2 => halfNote;
        halfNote * 2 => note;

        quarterNote * .5 => eighthNote;
        eighthNote * .5 => sixteenthNote;
        sixteenthNote * .5 => thirtiethNote;
    }
}