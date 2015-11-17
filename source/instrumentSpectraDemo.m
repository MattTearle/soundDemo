classdef instrumentSpectraDemo < handle
    %Demo app that compares spectra of different instrument note samples
    
    properties
        % Graphics objects
        fig
        ax
        instrselect
        noteselect
        keypatches
        % Application data
        keyidx      % Mapping of key indices to the patches
        soundbites  % Sound clips
        spectra     % Power spectra (corresponding to the sound clips)
        notes       % Note names (corresponding to the sound clips)
        instruments % Instrument names (corresponding to the sound clips)
        noteNames   % List of unique note names
        instNames   % List of unique instrument names
        idx         % Indices of sound clips currently selected
    end
    
    methods
        % Make interface
        function app = instrumentSpectraDemo
            % Get data from file
            instdat = load('instrumentspectra');
            app.soundbites = instdat.soundclips;
            app.spectra = instdat.spec;
            app.notes = instdat.note;
            app.instruments = instdat.instrument;
            app.noteNames = categories(app.notes);
            app.instNames = categories(app.instruments);
            % Make app window
            r = groot;
            ws = r.ScreenSize;
            w = ws(3) - ws(1);
            xoff = round(0.05*w);
            yoff = round(0.1*(ws(4)-ws(2)));
            w = round(0.9*w);
            h = round(0.5*w);
            app.fig = figure('Position',[xoff yoff w h],...
                'Toolbar','none','MenuBar','none',...
                'NumberTitle','off','Name','Instrument Spectra');
            % Add user controls
            uicontrol(app.fig,...
                'Style','pushbutton','String','Shuffle',...
                'Units','normalized','Position',[0.05 0.05 0.15 0.05],...
                'Callback',@app.shuffle);
            app.instrselect = uicontrol(app.fig,'Style','listbox',...
                'Value',[],'Min',0,'Max',2,'String',app.instNames,...
                'Units','normalized','Position',[0.05 0.575 0.15 0.375]);
            app.noteselect = uicontrol(app.fig,'Style','listbox',...
                'Value',[],'Min',0,'Max',2,'String',app.noteNames,...
                'Units','normalized','Position',[0.05 0.15 0.15 0.375]);
            % Add keyboard images
            app.ax = gobjects(15,1);
            app.keypatches = gobjects(132,12);
            for k = 1:15
                [r,c] = ind2sub([5 3],k);
                app.ax(k) = axes('Parent',app.fig,...
                    'Units','normalized','Position',[0.25*c 1-0.19*r 0.2 0.14]);
                [app.keypatches(:,k),keybdmap] = makekeyboard(132,app.ax(k));
            end
            app.keyidx = keybdmap;
            [app.keypatches.PickableParts] = deal('none');
            % No samples selected yet
            app.idx = [];
            % So select some (randomly)
            shuffle(app,[],[])
        end
        
        % Select sound samples
        function shuffle(app,~,~)
            % Get instruments selected by the user
            idxInst = ismember(app.instruments,app.instNames(app.instrselect.Value));
            % If no instruments are selected, then all are possible
            if ~any(idxInst)
                idxInst = ~idxInst;
            end
            % Same again with notes
            idxNote = ismember(app.notes,app.noteNames(app.noteselect.Value));
            if ~any(idxNote)
                idxNote = ~idxNote;
            end
            % Get the indices of possible sound samples
            app.idx = find(idxNote & idxInst);
            % Take a random sample of 15
            if length(app.idx) > 15
                app.idx = randsample(app.idx,15);
            end
            % Visualize the spectra
            colorkeys(app)
        end
        
        % Visualize the power spectra by coloring the keyboard keys
        function colorkeys(app)
            % Get the total number of keys and the number of black keys
            % (The keys are organized black [5/12 of the total number],
            % then white [7/12])
            n = size(app.keypatches,1);
            kblk = (5*n/12);
            % Loop over each keyboard/sound sample
            for i = 1:length(app.idx)
                % Get the index of the current sound sample
                inst = app.idx(i);
                % Make the callback to play the sound
                y = app.soundbites(:,inst);
                playfunc = @(h,e) soundsc(y,8820);
                % Get the spectrum
                mx = app.spectra(:,inst);
                mx = sqrt(mx/max(mx)); % normalize
                % Loop over the keys in the current keyboard
                for k = 1:length(mx)
                    % Get the index of the key (not in sequential order)
                    j = app.keyidx(k);
                    % Color according to spectrum value
                    if (j > kblk)
                        % white key -> reduce G&B to make R
                        app.keypatches(j,i).FaceColor = [1 1-mx(k) 1-mx(k)];
                    else
                        % black key -> increase R
                        app.keypatches(j,i).FaceColor = [mx(k) 0 0];
                    end
                end
                app.ax(i).ButtonDownFcn = playfunc;
                % Title axis with instrument and note
                app.ax(i).Title.String = [char(app.instruments(inst)),'  ',char(app.notes(inst))];
%                 drawnow
            end
            
            % Reset any unused keyboards
            % (if there are fewer than 15 sound samples selected)
            for j = (length(app.idx)+1):15
                % Black keys
                for k = 1:kblk
                    app.keypatches(k,j).FaceColor = [0 0 0];
                end
                % White keys
                for k = (kblk+1):n
                    app.keypatches(k,j).FaceColor = [1 1 1];
                end
                app.ax(j).ButtonDownFcn = [];
                % Blank title
                app.ax(j).Title.String = '';
            end
        end
        
    end % methods
    
end
