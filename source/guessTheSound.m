classdef guessTheSound < handle
    %Guess which instrument produced a particular sound
    
    properties
        % Graphics objects
        fig
        kbax
        sqax
        img
        pabutt
        cgbutt
        ansbutt
        keypatches
        % application data
        keymap        % Mapping of key indices to the patches
        instnames     % Cell array of instrument names
        predictions   % Table of predictions from machine learning algorithm
        spectra       % Power spectra (corresponding to the sound clips)
        soundbites    % Sound clips
        idx           % Index of randomly chosen sound clip to identify
    end
    
    methods
        % Make interface
        function app = guessTheSound
            % Make app window
            r = groot;
            ws = r.ScreenSize;
            w = ws(3) - ws(1);
            xoff = round(0.1*w);
            yoff = round(0.15*(ws(4)-ws(2)));
            w = round(0.75*w);
            h = round(0.5*w);
            app.fig = figure('Position',[xoff yoff w h],...
                'Toolbar','none','MenuBar','none',...
                'NumberTitle','off','Name','Guess The Sound');
            % Load data from file
            instdat = load('instrumentspectra');
            preddat = load('predictiontrees');
            app.predictions = preddat.predictions;
            app.instnames = unique(app.predictions.Instrument);
            % Extract recordings and spectra that were in the test set
            app.soundbites = instdat.soundclips(:,app.predictions.Index);
            app.spectra = instdat.spec(:,app.predictions.Index);
            
            % Add controls & graphics objects
            % Three sets of axes for the instrument selection grids
            app.sqax = gobjects(3,1);
            app.img = gobjects(3,1);
            [r,c] = ind2sub([4,3],1:12); % x/y locations for text labels
            for k = 1:3
                app.sqax(k) = axes('Parent',app.fig,'Units','normalized',...
                    'Position',[(0.05*k + 8*(k-1)/30) 0.05 (8/30) 0.4]);
                % Make the grid from an image
                % (Image is blank/default -- will be reset later anyway)
                app.img(k) = image(ones(4,3,3),'Parent',app.sqax(k));
                % Use the axis grids to make the lines on the image
                app.sqax(k).XTick = [1.5 2.5];
                app.sqax(k).YTick = [1.5 2.5 3.5];
                app.sqax(k).XTickLabel = [];
                app.sqax(k).YTickLabel = [];
                app.sqax(k).GridAlpha = 1;
                app.sqax(k).GridColor = 'k';
                app.sqax(k).XGrid = 'on';
                app.sqax(k).YGrid = 'on';
                % Add instrument names
                text(c,r,app.instnames,'HorizontalAlignment','center',...
                    'FontWeight','bold','PickableParts','none')
            end
            % Axes for the keyboard visualization
            app.kbax = axes('Parent',app.fig,...
                'Units','normalized','Position',[0.05 0.5 0.9 0.4]);
            % Pushbutton controls
            app.pabutt = uicontrol(app.fig,'Style','pushbutton',...
                'Units','normalized','Position',[0.425 0.65 0.15 0.1],...
                'Callback',@app.reset,'String','Play Again',...
                'FontSize',12,'FontWeight','bold');
            app.cgbutt = uicontrol(app.fig,'Style','pushbutton',...
                'Units','normalized','Position',[0.4 0.225 0.2 0.05],...
                'Callback',@app.compguess,'String','Get Computer''s Guess',...
                'FontSize',12,'FontWeight','bold');
            app.ansbutt = uicontrol(app.fig,'Style','pushbutton',...
                'Units','normalized','Position',[(0.075 + 2/3) 0.225 0.15 0.05],...
                'Callback',@app.reveal,'String','Reveal Answer',...
                'FontSize',12,'FontWeight','bold');
            % Draw keyboard
            [app.keypatches,app.keymap] = makekeyboard(132,app.kbax);
            % Make keys invisible to mouse clicks
            [app.keypatches.PickableParts] = deal('none');
            % Start new game
            reset(app,[],[])
        end
        
        % Start a new game
        function reset(app,~,~)
            % RGB array for unselected squares
            x = ones(4,3);
            x = cat(3,0.6*x,0.8*x,x);
            % Set all squares to unselected color
            [app.img.CData] = deal(x);
            % Fade out computer guess and answer (but keep player's guess)
            app.img(1).AlphaData = 1;
            app.img(2).AlphaData = 0.25;
            app.img(3).AlphaData = 0.25;
            % Set callback for player making a guess
            app.img(1).ButtonDownFcn = @app.makeguess;
            % Choose a sound clip
            app.idx = randsample(size(app.predictions,1),1);
            % Set keyboard callback to play the sound
            y = app.soundbites(:,app.idx);
            app.kbax.ButtonDownFcn = @(h,e) soundsc(y,8820);
            % Use spectrum to color the keyboard keys
            colorkeys(app)
            % Set other pushbutton states
            % Computer guess and reveal answer buttons visible but disabled
            app.cgbutt.Enable = 'off';
            app.cgbutt.Visible = 'on';
            app.ansbutt.Enable = 'off';
            app.ansbutt.Visible = 'on';
            % Play again button gone
            app.pabutt.Enable = 'off';
            app.pabutt.Visible = 'off';
        end
        
        % Human player has selected an instrument
        function makeguess(app,~,evdata)
            % Determine which square was selected
            xy = round(evdata.IntersectionPoint(1:2));
            j = min(xy(2),4);
            k = min(xy(1),3);
            % (Re)set all squares to unselected color
            x = ones(4,3);
            app.img(1).CData = cat(3,0.6*x,0.8*x,x);
            % Change selected square to highlight color
            app.img(1).CData(j,k,:) = cat(3,1,0.8,0.4);
            % Allow revelation of computer guess
            app.cgbutt.Enable = 'on';
        end
        
        % Computer guess is revealed
        function compguess(app,~,~)
            % Human player can't change their guess
            app.img(1).ButtonDownFcn = [];
            % Unfade computer guess squares and get rid of the button
            app.img(2).AlphaData = 1;
            app.cgbutt.Visible = 'off';
            % Randomly flash squares (for dramatic effect...)
            flash(app,app.img(2))
            % Highlight the computer guess instrument
            k = find(strcmp(app.predictions.PredictedInstrument(app.idx),app.instnames));
            [r,c] = ind2sub([4,3],k);
            app.img(2).CData(r,c,:) = cat(3,1,0.8,0.4);
            % Allow revelation of the answer
            app.ansbutt.Enable = 'on';
        end
        
        % Answer is revealed
        function reveal(app,~,~)
            % Unfade answer squares and get rid of the button
            app.img(3).AlphaData = 1;
            app.ansbutt.Visible = 'off';
            % Randomly flash squares (for dramatic effect...)
            flash(app,app.img(3))
            % Highlight the computer guess instrument
            k = find(strcmp(app.predictions.Instrument(app.idx),app.instnames));
            [r,c] = ind2sub([4,3],k);
            app.img(3).CData(r,c,:) = cat(3,1,0.8,0.4);
            % Can now play again
            pause(0.5)
            app.pabutt.Visible = 'on';
            app.pabutt.Enable = 'on';
        end
        
        % Flash random squares
        function flash(~,img)
            % Make RGB arrays of colors
            resetcolor = cat(3,0.6,0.8,1); 
            flashcolor = cat(3,1,0.8,0.4);
            for k = 1:10
                % Choose a random square
                r = randi(4);
                c = randi(3);
                % Highlight it briefly then reset it
                img.CData(r,c,:) = flashcolor;
                pause(0.2)
                img.CData(r,c,:) = resetcolor;
            end
        end
        
        % Visualize the power spectra by coloring the keyboard keys
        function colorkeys(app)
            % Get the total number of keys and the number of black keys
            % (The keys are organized black [5/12 of the total number],
            % then white [7/12])
            n = size(app.keypatches,1);
            kblk = (5*n/12);
            
            % Get the spectrum
            mx = app.spectra(:,app.idx);
            mx = sqrt(mx/max(mx)); % normalize
            % Loop over the keys in the current keyboard
            for k = 1:length(mx)
                % Get the index of the key (not in sequential order)
                j = app.keymap(k);
                % Color according to spectrum value
                if (j > kblk)
                    % white key -> reduce G&B to make R
                    app.keypatches(j).FaceColor = [1 1-mx(k) 1-mx(k)];
                else
                    % black key -> increase R
                    app.keypatches(j).FaceColor = [mx(k) 0 0];
                end
            end
        end

    end
    
end

