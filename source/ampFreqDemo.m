classdef ampFreqDemo < handle
    % App to demonstrate the properties of amplitude and frequency, and how
    % these affect the mathematical representation of a simple sinusoidal
    % wave
    
    properties (Access = private)
        % Interface graphics objects
        fig         % figure window
        axphys      % axes for animation of physical oscillation
        axplot      % axes for sine wave plot
        bar         % line representing physical oscillation
        plot        % sine wave plot
        marker      % marker to animate sine wave
        freq        % slider for frequency value
        amp         % slider for amplitude value
        freqtxt     % text to show current value of the frequency slider
        amptxt      % text to show current value of the amplitude slider
        startstop   % button to start/stop animation
        playing     % button to start/stop sound
        % App data
        icons       % structure of icon images
        t           % vector of times for sound
        tplot       % vector of times scaled for plot
        y           % vector of sound wave displacements (for sound)
        nplt        % number of points in plot
        plotidx     % current position of marker in the plot
        fs          % sampling frequency for t & y
        tm          % timer for updating animation
        sound       % audioplayer for playing sound
    end
    
    methods
        % constructor
        function app = ampFreqDemo
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
                'CloseRequestFcn',@app.done,...
                'Toolbar','none','MenuBar','none',...
                'IntegerHandle','off','HandleVisibility','callback',...
                'NumberTitle','off','Name','Amplitude and Frequency');
            app.axphys = axes('Parent',app.fig,...
                'Units','normalized','Position',[0.05 0.45 0.2 0.4]);
            app.axplot = axes('Parent',app.fig,...
                'Units','normalized','Position',[0.35 0.45 0.6 0.4]);
            
            app.freq = uicontrol(app.fig,'Style','slider',...
                'Units','normalized','Position',[0.4 0.25 0.2 0.05],...
                'Min',200,'Max',1000,'Value',440,'Callback',@app.afchange);
            app.amp = uicontrol(app.fig,'Style','slider',...
                'Units','normalized','Position',[0.7 0.25 0.2 0.05],...
                'Min',0,'Max',1,'Value',0.5,'Callback',@app.afchange);
            
            uicontrol(app.fig,'Style','text',...
                'Units','normalized','Position',[0.4 0.05 0.2 0.1],...
                'String','Frequency [Hz]','FontSize',12,'FontWeight','bold');
            uicontrol(app.fig,'Style','text',...
                'Units','normalized','Position',[0.7 0.05 0.2 0.1],...
                'String','Amplitude','FontSize',12,'FontWeight','bold');
            
            app.freqtxt = uicontrol(app.fig,'Style','text',...
                'Units','normalized','Position',[0.4 0.18 0.2 0.05],...
                'String',num2str(app.freq.Value),'FontSize',12);
            app.amptxt = uicontrol(app.fig,'Style','text',...
                'Units','normalized','Position',[0.7 0.18 0.2 0.05],...
                'String',num2str(app.amp.Value),'FontSize',12);
            
            % load button icons from file
            app.icons = load('icons');
            app.startstop = uicontrol(app.fig,'Style','togglebutton',...
                'Units','normalized','Position',[0.05 0.15 0.075 0.15],...
                'Value',1,'Callback',@app.runbutton,'CData',app.icons.pause);
            
            app.playing = uicontrol(app.fig,'Style','togglebutton',...
                'Units','normalized','Position',[0.175 0.15 0.075 0.15],...
                'Value',0,'Callback',@app.playbutton,'CData',app.icons.spkr);
            
            % set (and call) callback to adjust button size/position when
            % window is resized
            app.fig.SizeChangedFcn = @app.repositionbuttons;
            app.repositionbuttons([],[]);
            
            % set app data
            app.fs = 25000;
            % 10 seconds of sound (one loop of animation)
            % extra point is to make spacing nice; then throw it away
            app.t = linspace(0,10,10*app.fs+1);
            app.t(end) = [];
            % 10 seconds real time = 20ms on plot => scale factor of 50
            app.nplt = app.fs/50;
            app.tplot = 1000*app.t(1:app.nplt);  % ms -> s
            % make sine wave & extract portion to plot
            app.y = app.amp.Value*sin(2*pi*app.t*app.freq.Value);
            app.plot = plot(app.axplot,app.tplot,app.y(1:app.nplt));
            % clean up plot
            app.axplot.YLim = [-1.2 1.2];
            xlabel(app.axplot,'Time [ms]')
            ylabel(app.axplot,'Displacement')
            % add marker
            hold(app.axplot,'on')
            app.marker = plot(app.axplot,0,0,'o');
            app.plotidx = 0;
            
            % make plot for physical representation
            app.bar = plot(app.axphys,[-1 1],[0 0],'k','LineWidth',8);
            app.axphys.XLim = [-1.2 1.2];
            app.axphys.YLim = [-1.2 1.2];
            app.axphys.XTick = [];
            app.axphys.YTick = [];
            app.axphys.Box = 'on';
            
            % create timer for animation
            app.tm = timer('ExecutionMode','fixedRate',...
                'Period',round(10/app.nplt,3),...
                'TimerFcn',@app.update);
            
            % create sound player. note that y is multiplied by amplitude
            % (again) => sound is actually scaled to square of amplitude.
            % this makes volume differences a bit more noticeable
            app.sound = audioplayer(app.amp.Value*app.y,app.fs);
            
            % all done. start animation
            start(app.tm)
        end
        
        % callback for any change to the sliders
        function afchange(app,~,~)
            % stop playing sound (doesn't matter if it's not playing --
            % stop doesn't complain)
            stop(app.sound);
            % update display of frequency and amplitude values
            app.freqtxt.String = num2str(app.freq.Value);
            app.amptxt.String = num2str(app.amp.Value);
            % recalculate y
            app.y = app.amp.Value*sin(2*pi*app.t*app.freq.Value);
            % update plot data
            app.plot.YData = app.y(1:app.nplt);
            % recreate audio
            app.sound = audioplayer(app.amp.Value*app.y,app.fs);
            % start playing audio if both buttons are on
            if app.playing.Value && app.startstop.Value
                play(app.sound)
            end
            % redraw
            app.plotidx = app.plotidx - 1; % gets incremented by update
            update(app,[],[])
        end
        
        % callback for animation update (invoked by timer)
        function update(app,~,~)
            % increment plot index (and wrap if necessary)
            app.plotidx = app.plotidx + 1;
            app.plotidx = mod(app.plotidx-1,app.nplt) + 1;
            % update marker
            app.marker.XData = app.tplot(app.plotidx);
            app.marker.YData = app.y(app.plotidx);
            % update position of physical oscillator
            app.bar.YData = app.y(app.plotidx)*[1 1];
            % restart sound at the beginning of each animation loop
            if (app.plotidx == 1) && app.startstop.Value && app.playing.Value
                stop(app.sound)
                % This seems to be necessary to ensure the new sound plays
                drawnow
                play(app.sound)
            end
        end
        
        % callback for clicking the play/pause button
        function runbutton(app,obj,~)
            if obj.Value
                % on -> start timer
                start(app.tm);
                % play sound, if sound button is also on
                if app.playing.Value
                    play(app.sound)
                end
                % change icon to pause
                obj.CData = app.icons.pause;
            else
                % off -> stop timer & sound
                stop(app.tm)
                stop(app.sound)
                % change icon to play
                obj.CData = app.icons.play;
            end
        end
        
        % callback for clicking the sound button
        function playbutton(app,obj,~)
            if obj.Value
                % on -> play sound if run button is also on
                if app.startstop.Value
                    play(app.sound)
                end
                % change icon to stop sound
                obj.CData = app.icons.spkroff;
            else
                % off -> stop playing
                stop(app.sound)
                % change icon to start sound
                obj.CData = app.icons.spkr;
            end
        end
        
        % callback for adjusting size/position of buttons when window is
        % resized
        function repositionbuttons(app,~,~)
            % stop/start button
            % get position in pixels
            app.startstop.Units = 'pixels';
            p = app.startstop.Position;
            % adjust position & reset units
            app.startstop.Position = [p(1)+p(3)/2-26,p(2)+p(4)/2-26,52,52];
            app.startstop.Units = 'normalized';
            % same again for sound play button
            app.playing.Units = 'pixels';
            p = app.playing.Position;
            app.playing.Position = [p(1)+p(3)/2-26,p(2)+p(4)/2-26,52,52];
            app.playing.Units = 'normalized';
        end
        
        % callback for closing app
        function done(app,~,~)
            % kill timer -- just closing the window leaves a zombie timer
            stop(app.tm)
            delete(app.tm)
            % close window
            delete(app.fig)
        end
        
        % no need to display anything about the app to the command window
        function display(app) %#ok<MANU,DISPLAY>
        end
        
    end
    
end

