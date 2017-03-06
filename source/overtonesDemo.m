classdef overtonesDemo < handle
    % App to demonstrate how overtones create different instrument sounds
    
    properties (Access = private)
        % interface graphics objects
        fig         % figure window
        ax          % axes for keyboard
        ottxt       % array of text objects to display overtone note names
        playbutt    % sound play button
        amp         % array of sliders for amplitude of each overtone
        keypatches  % graphics patches for keys
        % app data
        keymap      % mapping of keys to patch objects
        keynum      % mapping of patch objects to keys
        f0          % fundamental frequency (note clicked by user)
        overtones   % number of keys to shift for each overtone
        freqRef     % list of reference frequencies for each key
        notenames   % list of note names for each key
    end
    
    methods
        % constructor
        function app = overtonesDemo
            % get screen geometry & determine app position
            r = groot;
            ws = r.ScreenSize;
            w = ws(3) - ws(1);
            xoff = round(0.1*w);
            yoff = round(0.15*(ws(4)-ws(2)));
            w = round(0.75*w);
            h = round(0.5*w);
            % build figure window
            app.fig = figure('Position',[xoff yoff w h],...
                'Toolbar','none','MenuBar','none',...
                'IntegerHandle','off',...
                'NumberTitle','off','Name','Overtones Mixer');
            app.ax = axes('Parent',app.fig,...
                'Units','normalized','Position',[0.05 0.5 0.9 0.4]);
            
            % number of octaves in keyboard
            numocts = 7;
            % build note names
            % names in an octave
            notes = repmat({'C','C#','D','Eb','E','F','F#','G','G#','A','Bb','B'}',1,numocts);
            % octaves
            octs = repmat(1+(1:numocts),12,1);
            octs = cellstr(num2str(octs(:)));
            % join together to make individual note names
            app.notenames = strcat(notes(:),octs);
            % make reference frequencies and overtone key shifts
            app.freqRef = 440*pow2((-34+(1:12*numocts))/12);
            app.overtones = round(12*log2([0.5 1:7]));
            
            % text objects for overtones (initially invisible)
            app.ottxt = gobjects(length(app.overtones),1);
            ot = ['1/2';'base';cellstr(num2str((2:7)'))];
            for k = 1:length(app.overtones)
                app.ottxt(k) = uicontrol(app.fig,'Style','text',...
                    'String',ot{k},'Visible','off',...
                    'Units','normalized','Position',[0.5 0.902 0.03 0.04],...
                    'HorizontalAlignment','center','FontSize',10);
            end
            
            % amplitude sliders
            app.amp = gobjects(8,1);
            for k = 1:8
                r = mod(k-1,4)+1;
                c = floor((k-1)/4);
                app.amp(k) = uicontrol(app.fig,'Style','slider',...
                    'Units','normalized','Position',[0.275+c*0.375 0.475-r*0.1 0.3 0.04],...
                    'Min',0,'Max',1,'Value',0);
                uicontrol(app.fig,'Style','text','String',ot{k},...
                    'Units','normalized','Position',[0.225+c*0.375 0.475-r*0.1 0.04 0.03],...
                    'HorizontalAlignment','right','FontSize',10);
            end
            app.amp(2).Value = 1;
            
            % play button
            icon = load('icons','spkrrun');
            app.playbutt = uicontrol(app.fig,'Style','pushbutton',...
                'Units','normalized','Position',[0.075 0.25 0.1 0.1],...
                'Callback',@app.play,'CData',icon.spkrrun);
            % set (and call) callback to adjust button size/position when
            % window is resized
            app.fig.SizeChangedFcn = @app.repositionplaybutton;
            repositionplaybutton(app,[],[])
            
            % reset button (to reset sliders)
            uicontrol(app.fig,'Style','pushbutton',...
                'Units','normalized','Position',[0.075 0.15 0.1 0.05],...
                'Callback',@app.resetamps,'String','Reset');
            
            % make keyboard
            [app.keypatches,app.keymap,app.keynum] = makekeyboard(12*numocts,app.ax);
            % Make figure hidden to other plotting (otherwise plots go into
            % app). Had to wait so makekeyboard had access to axes
            
            % add callback to keys on callback
            [app.keypatches.ButtonDownFcn] = deal(@app.keypressed);
            % add callback to sliders
            [app.amp.Callback] = deal(@app.keypressed);
            % initialize f0 (just so it exists)
            app.f0 = 0;
        end
        
        % callback for any change to key or sliders
        function keypressed(app,key,~)
            % Reset keyboard (black and white) -- keys are ordered black
            % (5/12 of keys), then white (7/12)
            n = length(app.keypatches);
            for k = 1:(5*n/12)
                app.keypatches(k).FaceColor = [0 0 0];
            end
            for j = (k+1):n
                app.keypatches(j).FaceColor = [1 1 1];
            end
            % What was clicked? Patch => key
            if isequal(key.Type,'patch')
                % Find which key was pressed
                idx = app.keynum(app.keypatches == key);
                % Get the key name and frequency
                app.ottxt(2).String = app.notenames(idx);
                app.f0 = app.freqRef(idx);
            else
                % Slider
                % Make sure we have a valid frequency selected (you can
                % change sliders before ever selecting a key and that's OK)
                idx = find(app.f0 == app.freqRef);
                if isempty(idx)
                    idx = NaN;
                end
            end
            
            % Get some window layout geometry to help position text
            p = app.ax.Position;
            scl = p(3)/diff(app.ax.XLim);
            
            % Get the amplitude slider values
            A = [app.amp.Value];
            % Loop over overtones
            for k = 1:length(app.overtones)
                % Get key index
                idx2 = idx + app.overtones(k);
                % Label the key (assuming it's on the keyboard)
                if (idx2>0) && (idx2<=n)
                    % Get the key patch
                    j = app.keymap(idx2);
                    % Position the text
                    app.ottxt(k).Position(1) = p(1) - 0.015 + scl*median(app.keypatches(j).XData);
                    app.ottxt(k).Visible = 'on';
                    % Color the key according to amplitude
                    if (app.keypatches(j).FaceColor(1) == 1)
                        % white key -> reduce G&B to make R
                        app.keypatches(j).FaceColor = [1 1-A(k) 1-A(k)];
                    else
                        % black key -> increase R
                        app.keypatches(j).FaceColor = [A(k) 0 0];
                    end
                else
                    % Turn off text for any note not currently on keyboard
                    app.ottxt(k).Visible = 'off';
                end
            end
        end
        
        % callback to play sound
        function play(app,~,~)
            % Make vector for time and y (initially 0)
            t = 2*pi*linspace(0,1,44100);
            f = [1/2 1:7];
            y = 0*t;
            % Loop over overtones
            for k = 1:length(f)
                y = y + app.amp(k).Value*sin(t*f(k)*app.f0);
            end
            % Play the result
            soundsc(y,44100)
        end
        
        % callback for adjusting size/pos of button when window is resized
        function repositionplaybutton(app,~,~)
            % get position in pixels
            pb = app.playbutt;
            pb.Units = 'pixels';
            p = pb.Position;
            % adjust position & reset units
            pb.Position = [p(1)+p(3)/2-26,p(2)+p(4)/2-26,52,52];
            pb.Units = 'normalized';
        end
        
        % callback for resetting amplitude sliders
        function resetamps(app,obj,~)
            % set all to zero
            [app.amp.Value] = deal(0);
            % set f0 amplitude to 1
            app.amp(2).Value = 1;
            % update keyboard
            keypressed(app,obj,[])
        end
        
        % no need to display anything about the app to the command window
        function display(app) %#ok<MANU,DISPLAY>
        end
        
    end
    
end

