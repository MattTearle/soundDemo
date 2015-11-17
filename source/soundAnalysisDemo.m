classdef soundAnalysisDemo < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        fig
        ax
        ottxt
        kbax
        keypatches
        keymap
        keynum
        freqRef
        notenames
        overtones
        waveform
        tm
        recorder
        Fs
        N
    end
    
    methods
        function app = soundAnalysisDemo
            r = groot;
            ws = r.ScreenSize;
            w = ws(3) - ws(1);
            xoff = round(0.1*w);
            yoff = round(0.2*(ws(4)-ws(2)));
            w = round(0.75*w);
            h = round(0.5*w);
            app.fig = figure('Position',[xoff yoff w h],...
                'CloseRequestFcn',@app.quit);
            app.ax = axes('Parent',app.fig,...
                'Units','normalized','Position',[0.05 0.1 0.9 0.3]);
            app.kbax = axes('Parent',app.fig,...
                'Units','normalized','Position',[0.05 0.5 0.9 0.4]);
            
            app.Fs = 44100;
            app.N = floor(0.25*app.Fs);
            numocts = 7;
            notes = repmat({'C','C#','D','Eb','E','F','F#','G','G#','A','Bb','B'}',1,numocts);
            octs = repmat(1+(1:numocts),12,1);
            octs = cellstr(num2str(octs(:)));
            app.notenames = strcat(notes(:),octs);
            app.freqRef = 440*pow2((-34+(1:12*numocts))/12);
            app.overtones = round(12*log2([0.5 1:7]));
            app.ottxt = gobjects(length(app.overtones),1);
            ot = ['1/2';'base';cellstr(num2str((2:7)'))];
            for k = 1:length(app.overtones)
                app.ottxt(k) = uicontrol(app.fig,'Style','text',...
                    'String',ot{k},'Visible','off',...
                    'Units','normalized','Position',[0.5 0.902 0.03 0.04],...
                    'HorizontalAlignment','center','FontSize',10);
            end
            
            [app.keypatches,app.keymap,app.keynum] = makekeyboard(12*numocts,app.kbax);
            try
                app.recorder = audiorecorder(app.Fs,8,1);
            catch mexc
                if strcmp(mexc.identifier,'MATLAB:audiovideo:audiorecorder:noAudioInputDevice')
                    errordlg(mexc.message,'No recording device');
                    close(app.fig);
                    return
                end
            end
            x = 0:app.N;
            app.waveform = plot(app.ax,x,NaN*x);
            app.ax.XLim = [0 app.N];
            app.ax.XTick = [];
            app.ax.YLim = [-1 1];
            app.tm = timer('TimerFcn',@app.hearsound,'Period',0.1,'ExecutionMode','FixedRate');
            start(app.tm)
            record(app.recorder)
        end
        
        function hearsound(app,~,~)
            if app.recorder.TotalSamples > 0
                if app.recorder.TotalSamples > app.N
                    y = getaudiodata(app.recorder);
                else
                    y = [app.waveform.YData(:);getaudiodata(app.recorder)];
                end
                n = length(y);
                app.waveform.YData = y(n-app.N:n);
                if ~any(isnan(app.waveform.YData))
                    spectralcolor(app)
                end
                if app.recorder.TotalSamples >= 5*app.Fs
                    stop(app.recorder)
                    record(app.recorder);
                end
            end
        end
        
        function spectralcolor(app)
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
            
            noteidx = round(12*log2(f/261.6255653006)) + 25;
            idx = (noteidx<=0) | (noteidx>84);
            P(idx) = [];
            noteidx(idx) = [];
            peakPow = accumarray(noteidx(:),P(:),[n,1],@max);
            
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
        
        function quit(app,~,~)
            stop(app.tm)
            stop(app.recorder)
            delete(app.tm)
            delete(app.fig)
        end
        
    end
    
end
        

