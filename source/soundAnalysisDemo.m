classdef soundAnalysisDemo < handle
    % App to show sound wave and spectrum of sound recorded through the
    % computer microphone (in real time)
    
    properties (Access = private)
        fig         % figure window
        ax          % axes for sound wave
        kbax        % axes for keyboard
        keypatches  % graphics patches for keys
        keymap      % mapping of keys to patch objects
        waveform    % plot of sound wave (line object)
        tm          % timer for updating recording and animation
        recorder    % audio recorder to record sound
        Fs          % sampling frequency
        N           % number of sample points to show in plot
    end
    
    methods
        % constructor
        function app = soundAnalysisDemo
            % get screen geometry & determine app position
            r = groot;
            ws = r.ScreenSize;
            w = ws(3) - ws(1);
            xoff = round(0.1*w);
            yoff = round(0.2*(ws(4)-ws(2)));
            w = round(0.75*w);
            h = round(0.5*w);
            % build figure window
            app.fig = figure('Position',[xoff yoff w h],...
                'CloseRequestFcn',@app.quit,...
                'Toolbar','none','MenuBar','none',...
                'IntegerHandle','off',...
                'NumberTitle','off','Name','Sound Recording and Visualization');
            app.ax = axes('Parent',app.fig,...
                'Units','normalized','Position',[0.05 0.1 0.9 0.3]);
            app.kbax = axes('Parent',app.fig,...
                'Units','normalized','Position',[0.05 0.5 0.9 0.4]);
            
            % Set recording sampling frequency
            app.Fs = 44100;
            % Number of waveform points to plot
            app.N = floor(0.25*app.Fs);
            % Size of keyboard
            numocts = 7;
            
            % Create the keyboard
            [app.keypatches,app.keymap] = makekeyboard(12*numocts,app.kbax);
            % Make figure hidden to other plotting (otherwise plots go into
            % app). Had to wait so makekeyboard had access to axes
            app.fig.HandleVisibility = 'callback';
            
            % Start the mic recorder
            try
                app.recorder = audiorecorder(app.Fs,8,1);
            catch mexc
                if strcmp(mexc.identifier,'MATLAB:audiovideo:audiorecorder:noAudioInputDevice')
                    errordlg(mexc.message,'No recording device');
                    close(app.fig);
                    return
                end
            end
            % Create the plot (initially blank)
            x = 0:app.N;
            app.waveform = plot(app.ax,x,NaN*x);
            app.ax.XLim = [0 app.N];
            app.ax.XTick = [];
            app.ax.YLim = [-1 1];
            % Start the timer running to plot the wave recorded by the
            % sound recorder
            app.tm = timer('TimerFcn',@app.hearsound,'Period',0.1,'ExecutionMode','FixedRate');
            start(app.tm)
            % Start recording
            record(app.recorder)
        end
        
        % Timer function to plot the recorded sound wave
        function hearsound(app,~,~)
            % Don't do anything until something has been recorded
            if app.recorder.TotalSamples > 0
                % Get the sound recorded; append the current data in the
                % plot if there are currently not enough samples to plot
                if app.recorder.TotalSamples > app.N
                    y = getaudiodata(app.recorder);
                else
                    y = [app.waveform.YData(:);getaudiodata(app.recorder)];
                end
                % Take the last N samples of the sound
                n = length(y);
                app.waveform.YData = y(n-app.N:n);
                % Color the keys (assuming we have a wave to work with)
                if ~any(isnan(app.waveform.YData))
                    spectralcolor(app)
                end
                % Restart the recorder periodically (so we don't accumulate
                % too much data)
                if app.recorder.TotalSamples >= 5*app.Fs
                    stop(app.recorder)
                    record(app.recorder);
                end
            end
        end
        
        % Color the keys according to the power spectrum
        function spectralcolor(app)
            % Get the spectrum
            Y = fft(app.waveform.YData); % Take the FFT
            n = length(Y); % FFT length
            range = ceil((n+1)/2);
            P = Y.*conj(Y)/n; % Compute the power
            P = P(1:range);
            Nyq = app.Fs/2; % Nyquist frequency
            f = (0:range-1)*Nyq/range; % Frequency scale
            
            % Get the total number of keys and the number of black keys
            % (The keys are organized black [5/12 of the total number],
            % then white [7/12])
            n = size(app.keypatches,1);
            kblk = (5*n/12);
            
            % Convert frequencies into keyboard notes
            noteidx = round(12*log2(f/261.6255653006)) + 25;
            % Throw away anything out of range of the keyboard
            idx = (noteidx<=0) | (noteidx>length(app.keypatches));
            P(idx) = [];
            noteidx(idx) = [];
            % Discretize power spectrum to keys (taking max over all
            % frequencies in the range of a given key)
            peakPow = accumarray(noteidx(:),P(:),[n,1],@max);
            
            % Make sure there's enough input to make the visualization
            % meaningful. If so, normalize the spectrum.
            mx = max(peakPow);
            if (mx > 0) && (max(abs(app.waveform.YData)) > 0.2)
                mx = sqrt(peakPow/max(peakPow));
            else
                mx = 0*peakPow;
            end

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
        
        % callback for closing app
        function quit(app,~,~)
            % kill timer -- just closing the window leaves a zombie timer
            stop(app.tm)
            delete(app.tm)
            % kill recorder (ditto)
            stop(app.recorder)
            delete(app.recorder)
            % close window
            delete(app.fig)
        end
        
        % no need to display anything about the app to the command window
        function display(app) %#ok<MANU,DISPLAY>
        end
        
    end
    
end
