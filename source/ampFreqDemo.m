classdef ampFreqDemo < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        fig
        axphys
        axplot
        bar
        plot
        marker
        freq
        amp
        freqtxt
        amptxt
        startstop
        playing
        icons
        t
        tplot
        y
        nplt
        fs
        tm
        lastplayed
    end
    
    methods
        function app = ampFreqDemo
            r = groot;
            ws = r.ScreenSize;
            w = ws(3) - ws(1);
            xoff = round(0.1*w);
            yoff = round(0.15*(ws(4)-ws(2)));
            w = round(0.75*w);
            h = round(0.5*w);
            app.fig = figure('Position',[xoff yoff w h],'CloseRequestFcn',@app.done,...
                'Toolbar','none','MenuBar','none',...
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
            
            app.icons = load('icons');
            app.startstop = uicontrol(app.fig,'Style','togglebutton',...
                'Units','normalized','Position',[0.05 0.15 0.075 0.15],...
                'Value',1,'Callback',@app.runbutton,'CData',app.icons.pause);
            
            app.playing = uicontrol(app.fig,'Style','togglebutton',...
                'Units','normalized','Position',[0.175 0.15 0.075 0.15],...
                'Value',0,'Callback',@app.playbutton,'CData',app.icons.spkroff);
            
%             f = @(h,e) app.repositionbuttons(h,e,[app.startstop,app.playing]);
            app.fig.SizeChangedFcn = @app.repositionbuttons; %f([],[]);
            app.repositionbuttons([],[]);
            
            app.fs = 50000;
            app.t = linspace(0,1,app.fs+1);
            app.nplt = 1 + app.fs/50;
            app.tplot = 1000*app.t(1:app.nplt);
            app.y = app.amp.Value*sin(2*pi*app.t*app.freq.Value);
            app.plot = plot(app.axplot,app.tplot,app.y(1:app.nplt));
            app.axplot.YLim = [-1.2 1.2];
            xlabel(app.axplot,'Time [ms]')
            ylabel(app.axplot,'Displacement')
            hold(app.axplot,'on')
            app.marker = plot(app.axplot,0,0,'o');
            
            app.bar = plot(app.axphys,[-1 1],[0 0],'k','LineWidth',8);
            app.axphys.XLim = [-1.2 1.2];
            app.axphys.YLim = [-1.2 1.2];
            app.axphys.XTick = [];
            app.axphys.YTick = [];
            app.axphys.Box = 'on';
            
            app.lastplayed = Inf;
            
            app.tm = timer('ExecutionMode','fixedRate','Period',10/(app.nplt-1),...
                'TimerFcn',@app.update);
            
            app.tm.Running
            start(app.tm)
            app.tm.Running
        end
        
        function afchange(app,~,~)
            isrunning = strcmp(app.tm.Running,'on');
            if isrunning
                stop(app.tm);
            end
            app.freqtxt.String = num2str(app.freq.Value);
            app.amptxt.String = num2str(app.amp.Value);
            app.y = app.amp.Value*sin(2*pi*app.t*app.freq.Value);
            app.plot.YData = app.y(1:app.nplt);
            update(app,[],[])
            if app.playing.Value
                app.lastplayed = 0;
            end
            % if timer was already running, let it run and set the run
            % button state
            if isrunning
                start(app.tm);  % force an update
                app.startstop.Value = 1;
            else
                % if not, stop it
%                 stop(app.tm);
                app.startstop.Value = 0;
            end
        end
        
        function update(app,~,~)
            %             app.tm.TasksExecuted
            idx = mod(app.tm.TasksExecuted-1,app.nplt) + 1;
            app.marker.XData = app.tplot(idx);
            app.marker.YData = app.y(idx);
            app.bar.YData = app.y(idx)*[1 1];
            
            if app.startstop.Value && ((app.tm.TasksExecuted - app.lastplayed)*app.tm.Period > 1)
                sound(app.amp.Value*app.y,app.fs)
                app.lastplayed = app.tm.TasksExecuted;
            end
        end
        
        function runbutton(app,obj,~)
            if obj.Value
                start(app.tm);
                if app.playing.Value
                    app.lastplayed = 0;
                end
                obj.CData = app.icons.pause;
            else
                stop(app.tm);
                app.lastplayed = Inf;
                obj.CData = app.icons.play;
            end
        end
        
        function playbutton(app,obj,~)
            if obj.Value
                app.lastplayed = 0;
                obj.CData = app.icons.spkr;
            else
                app.lastplayed = Inf;
                obj.CData = app.icons.spkroff;
            end
        end
        
        function repositionbuttons(app,~,~)%,buttons)
            app.startstop.Units = 'pixels';
            p = app.startstop.Position;
            app.startstop.Position = [p(1)+p(3)/2-26,p(2)+p(4)/2-26,52,52];
            app.startstop.Units = 'normalized';
            app.playing.Units = 'pixels';
            p = app.playing.Position;
            app.playing.Position = [p(1)+p(3)/2-26,p(2)+p(4)/2-26,52,52];
            app.playing.Units = 'normalized';
%             for k = 1:length(buttons)
%                 buttons(k).Units = 'pixels';
%                 p = buttons(k).Position;
%                 buttons(k).Position = [p(1)+p(3)/2-26,p(2)+p(4)/2-26,52,52];
%                 buttons(k).Units = 'normalized';
%             end
        end
        
        function done(app,~,~)
            stop(app.tm)
            delete(app.tm)
            delete(app.fig)
        end
    end
    
end

