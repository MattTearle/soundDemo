classdef mixingSignalsDemo < handle
    % App to demonstrate combining sine waves of different frequencies and
    % amplitudes
    
    properties (Access = private)
        % interface objects
        fig         % figure window
        ax          % array of axes for sound wave plots
        plot        % array of plots (line objects) for sound waves
        freq        % array of sliders for individual input frequencies
        freqtxt     % array of text objects to show slider values
        amp         % array of sliders for individual input amplitudes
        playbutt    % play button
        % app data
        t           % time vector for sound waves
        twopit      % 2*pi*t
        y           % matrix holding y(t) for three individual waves + total
        nplotpts    % number of points to plot (subset of total wave)
    end
    
    methods
        % constructor
        function app = mixingSignalsDemo
            % get screen geometry & determine app position
            r = groot;
            ws = r.ScreenSize;
            h = ws(4) - ws(2);
            yoff = round(0.1*h);
            xoff = round(0.1*(ws(3)-ws(1)));
            h = round(0.8*h);
            w = h;
            % build figure window
            app.fig = figure('Position',[xoff yoff w h],...
                'MenuBar','none','Toolbar','none',...
                'IntegerHandle','off','HandleVisibility','callback',...
                'Name','Signal Mixer','NumberTitle','off');
            % axes
            app.ax = gobjects(4,1);
            for k = 1:3
                app.ax(k) = axes('Parent',app.fig,...
                    'Units','normalized','Position',[0.1 (1-0.2*k) 0.6 0.15]);
            end
            app.ax(4) = axes('Parent',app.fig,...
                'Units','normalized','Position',[0.1 0.05 0.6 0.3]);
            % frequency sliders
            app.freq = gobjects(3,1);
            vals = [440 220 880];
            for k = 1:3
                app.freq(k) = uicontrol(app.fig,'Style','slider',...
                    'Units','normalized','Position',[0.75 (1.1-0.2*k) 0.15 0.02],...
                    'Min',200,'Max',1000,'Value',vals(k),'Callback',@app.updateplot);
            end
            % slider text
            app.freqtxt = gobjects(3,1);
            for k = 1:3
                app.freqtxt(k) = uicontrol(app.fig,'Style','text',...
                    'Units','normalized','Position',[0.91 (1.1-0.2*k) 0.04 0.02],...
                    'String',num2str(app.freq(k).Value),'FontSize',10);
            end
            for k = 1:3
                uicontrol(app.fig,'Style','text',...
                    'Units','normalized','Position',[0.75 (1.02-0.2*k) 0.2 0.05],...
                    'String','Frequency [Hz]','FontSize',10,...
                    'HorizontalAlignment','center');
            end
            % amplitude sliders
            app.amp = gobjects(3,1);
            for k = 1:3
                app.amp(k) = uicontrol(app.fig,'Style','slider',...
                    'Units','normalized','Position',[0.75 (0.4-0.075*k) 0.2 0.02],...
                    'Min',0,'Max',1,'Value',0,'Callback',@app.updateplot);
            end
            app.amp(1).Value = 1;
            
            % play button
            icon = load('icons','spkrrun');
            app.playbutt = uicontrol(app.fig,'Style','pushbutton',...
                'Units','normalized','Position',[0.8 0.05 0.1 0.05],...
                'Callback',@app.play,'CData',icon.spkrrun);
            % set (and call) callback to adjust button size/position when
            % window is resized
            app.fig.SizeChangedFcn = @app.repositionplaybutton;
            repositionplaybutton(app,[],[])
            
            % Make plots for individual waves
            app.nplotpts = 501;
            app.t = linspace(0,1,1 + (app.nplotpts-1)*50)';
            app.twopit = 2*pi*app.t;
            app.y = zeros(length(app.t),4);
            for k = 1:3
                app.y(:,k) = app.amp(k).Value*sin(app.twopit*app.freq(k).Value);
            end
            % Total wave
            app.y(:,4) = sum(app.y(:,1:3),2);
            % Make plots
            app.plot = gobjects(4,1);
            for k = 1:4
                app.plot(k) = plot(app.ax(k),app.t(1:app.nplotpts),app.y(1:app.nplotpts,k));
            end
            % Set axis limits
            for k = 1:3
                app.ax(k).YLim = [-1 1];
            end
        end
        
        % callback for any change to the sliders
        function updateplot(app,~,~)
            % Update individual sound waves
            for k = 1:3
                app.y(:,k) = app.amp(k).Value*sin(app.twopit*app.freq(k).Value);
                app.plot(k).YData = app.y(1:app.nplotpts,k);
                app.freqtxt(k).String = num2str(app.freq(k).Value);
            end
            % Update total
            app.y(:,4) = sum(app.y(:,1:3),2);
            app.plot(4).YData = app.y(1:app.nplotpts,4);
        end
        
        % callback for playing sound (play button pressed)
        function play(app,~,~)
            % play total wave for 1 second
            soundsc(app.y(:,4),length(app.t)-1)
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
        
        % no need to display anything about the app to the command window
        function display(app) %#ok<MANU,DISPLAY>
        end
        
    end
    
end
