classdef overtonesDemo < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        fig
        ax
        ottxt
        playbutt
        amp
        keypatches
        keymap
        keynum
        f0
        freqRef
        notenames
        overtones
    end
    
    methods
        function app = overtonesDemo
            r = groot;
            ws = r.ScreenSize;
            w = ws(3) - ws(1);
            xoff = round(0.1*w);
            yoff = round(0.15*(ws(4)-ws(2)));
            w = round(0.75*w);
            h = round(0.5*w);
            app.fig = figure('Position',[xoff yoff w h],...
                'Toolbar','none','MenuBar','none',...
                'NumberTitle','off','Name','Overtones Mixer');
            app.ax = axes('Parent',app.fig,...
                'Units','normalized','Position',[0.05 0.5 0.9 0.4]);
            
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
            
            icon = load('icons','spkrrun');
            app.playbutt = uicontrol(app.fig,'Style','pushbutton',...
                'Units','normalized','Position',[0.075 0.25 0.1 0.1],...
                'Callback',@app.play,'CData',icon.spkrrun);
            app.fig.SizeChangedFcn = @app.repositionplaybutton;
            repositionplaybutton(app,[],[])
            
            uicontrol(app.fig,'Style','pushbutton',...
                'Units','normalized','Position',[0.075 0.15 0.1 0.05],...
                'Callback',@app.resetamps,'String','Reset');
            
            [app.keypatches,app.keymap,app.keynum] = makekeyboard(12*numocts,app.ax);
            [app.keypatches.ButtonDownFcn] = deal(@app.keypressed);
            [app.amp.Callback] = deal(@app.keypressed);
            app.f0 = 0;
        end
        
        function keypressed(app,key,~)
            n = length(app.keypatches);
            for k = 1:(5*n/12)
                app.keypatches(k).FaceColor = [0 0 0];
            end
            for j = (k+1):n
                app.keypatches(j).FaceColor = [1 1 1];
            end
            if isequal(key.Type,'patch')
            idx = app.keynum(app.keypatches == key);
            app.ottxt(2).String = app.notenames(idx);
            app.f0 = app.freqRef(idx);
            else
                idx = find(app.f0 == app.freqRef);
                if isempty(idx)
                    idx = NaN;
                end
            end
            
            p = app.ax.Position;
            scl = p(3)/diff(app.ax.XLim);
            
            A = [app.amp.Value];
            for k = 1:length(app.overtones)
                idx2 = idx + app.overtones(k);
                if (idx2>0) && (idx2<=n)
                    j = app.keymap(idx2);
                    app.ottxt(k).Position(1) = p(1) - 0.015 + scl*median(app.keypatches(j).XData);
                    app.ottxt(k).Visible = 'on';
                    if (app.keypatches(j).FaceColor(1) == 1)
                        app.keypatches(j).FaceColor = [1 1-A(k) 1-A(k)];
                    else
                        app.keypatches(j).FaceColor = [A(k) 0 0];
                    end
                else
                    app.ottxt(k).Visible = 'off';
                end
            end
        end
        
        function play(app,~,~)
            t = 2*pi*linspace(0,1,44100);
            f = [1/2 1:7];
            y = 0*t;
            for k = 1:length(f)
                y = y + app.amp(k).Value*sin(t*f(k)*app.f0);
            end
            soundsc(y,44100)
        end
        
        function repositionplaybutton(app,~,~)
            pb = app.playbutt;
            pb.Units = 'pixels';
            p = pb.Position;
            pb.Position = [p(1)+p(3)/2-26,p(2)+p(4)/2-26,52,52];
            pb.Units = 'normalized';
        end
        
        function resetamps(app,obj,~)
            [app.amp.Value] = deal(0);
            app.amp(2).Value = 1;
            keypressed(app,obj,[])
        end
    end
    
end

