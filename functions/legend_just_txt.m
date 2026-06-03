function[varargout] = legend_just_txt(varargin)
%labels the lines in a graph (instead of using legend) as suggested by Tufte
%legend_just_txt(labels)
%legend_just_txt(h,labels)
%legend_just_txt(labels,OPTIONS)
%legend_just_txt(h,labels,OPTIONS)
%
%h      = the handles for each line - numeric (if not entered, default is
%         get(gca,'Children')
%       labels = the labels to output - cell of strings.  it must be entered

% position of text =  
% X=o.Xoffset + o.relX *(range(Xlim))
% Y=o.Yoffset + o.relY *(range(Ylim))
%Default Parameters
%TextProperties = [];
o.Yoffset        = 0;
o.Xoffset        = 0;
o.relY           =.05;       %minimum spacing as a fraction of the Y-size of the axis
o.relX           = 0;         %X offset as a fraction of the size of the X axis
o.XLimTweak      = 1; %Tweak the XLim a bit so text is more likely to be in plot
o.XLimTweakPct   =.1;
o.type='line'
%parse the inputs
%line handles
switch varargin{12}
    case 'line'
h = findobj(gca,'Type','Line');
h = flipud(fliplr(h));
if ~isempty(varargin)
    if ishandle(varargin{1})
        haxes = varargin{1};
        h = findobj(haxes,'Type','Line','-not',{'Tag','y=0'});
        h = flipud(fliplr(h));
        varargin(1) = [];
    end
end

    case 'bar'
h = findobj(gca,'Type','bar');
h = flipud(fliplr(h));
if ~isempty(varargin)
    if ishandle(varargin{1})
        haxes = varargin{1};
        h = findobj(haxes,'Type','bar','-not',{'Tag','y=0'});
        h = flipud(fliplr(h));
        varargin(1) = [];
    end
end
end
%line labels
labels = get(h,'DisplayName');
if ~isempty(varargin)
    if iscell(varargin{1})
        labels = varargin{1};
        varargin(1) = [];
    end
end

%Put default parameter names into a variable and setup input parser
if ~isempty(varargin)
    p = inputParser;
    fo = fieldnames(o);
    for i=1:length(fo)
        p.addOptional(fo{i},o.(fo{i}))
    end
    if length(varargin)==1 %the options are a structure
        p.parse(varargin{1});
    else
        p.parse(varargin{:})
    end
    o = p.Results;
end

%check if we're in linear space or logspace
%calculate the minimum Y spacing between each label
YScale = get(haxes,'YScale');
XLim   = get(haxes,'XLim');
YLim   = get(haxes,'YLim');

switch YScale
    case {'linear'}
        dY = o.relY*(YLim(2)-YLim(1));
    case {'log'}
        dY = o.relY*(log10(YLim(2)) - log10(YLim(1)));
end
dX = o.relX*(XLim(2)-XLim(1));

%first get the y position of each line
xpos  = zeros(size(h));
ypos  = zeros(size(h));
col   = cell(size(h));
DY=dY;
for i=1:length(h)
    x = get(h(i),'XData');
    y = get(h(i),'YData');

    switch varargin{10}
    case 'line'
    col{i} = get(h(i),'Color');
        case 'bar'
    col{i} = get(h(i),'faceColor');
    end

    [xpos(i), ind]= max(x);
    xpos(i)       = o.Xoffset+dX;
    ypos(i)       = o.Yoffset-DY;
    DY=DY+dY;
end

if strcmp(YScale,'log')
    ypos = log10(ypos);
end



%put the labels in the graph
htxt = zeros(size(h));
for i=1:length(labels)
    htxt(i) = text(haxes,xpos(i),ypos(i),labels{i},'Color',col{i});
end

%outputs
varargout{1} = htxt;
