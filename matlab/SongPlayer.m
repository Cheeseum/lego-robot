classdef SongPlayer < handle
    properties (Access=private)
        robot;
        brick;
    end
    
    methods
        function obj = SongPlayer(robot)
            obj.robot = robot;
            obj.brick = robot.getBrick();
        end
        
        function playSongInput(obj, notes, durations, bpm)
            %playSong plays a song
            %   notes: array of notes, integers as half-steps away from A4
            %   durations: duration of each note in beats
            %   bpm: tempo, beats per minute
            
            % reference frequencies from A4 = 440Hz
            ref_freq = 440;
            fconst = 2^(1/12);
            beat = 1 / (bpm / 60); % length of beat
            
            for i=1:1:length(notes)
                % magic: see www.phy.mtu.edu/~suits/NoteFreqCalcs.html
                note_freq = ref_freq * fconst^(notes(i));
                
                % number of beats by dre * length of beat
                duration = durations(i) * beat;
                
                % play note at note_freq
                obj.brick.playTone(note_freq, duration * 1000);
                
                pause(beat * duration + 0.2);
                
                % not sure if needed
                %if (beat-duration > 0) pause(beat-duration); end
            end
        end
        
        function [ steps ] = notesToHalfSteps( obj, notes )
            %NOTESTOHALFSTEPS converts letter notes to halfsteps from A4
            %   rests MUST have some octave specified even though it's useless
            
            % letter to half-step offsets (see below in loop)
            letter_note_offset = containers.Map(...
                {'R', 'B', 'A#', 'A', 'G#', 'G', 'F#', 'F', 'E', 'D#', 'D', 'C#', 'C'}, ...
                {-Inf, 2, 1, 0, -1, -2, -3, -4, -5, -6, -7, -8, -9} ...
                );
            
            j = 1;
            for i=2:2:length(notes)
                % "arrays of strings" are just giant 1xlength character matricies
                % ours are in the form 'A4C#4G6', [NOTE][OPT.SHARP][OCTAVE][NOTE]...
                % puke
                % CONSIDER: nx2 char matrix, possibly annoying to use function
                note = notes(i-1);
                   
                % on a sharp, notes(i) will be '#', must move our iteration pointer to
                % the next char (the octave)
                if notes(i) == '#'
                    note = [note, '#'];
                    i = i + 1;
                end
                
                octave = str2num(notes(i));
                
                % half-steps are calculated relative to A and octave 4
                steps(j) = ((octave * 12) - 48) + letter_note_offset(note);
                j = j + 1;
            end
            
        end
        
    end
end