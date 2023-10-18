function prepExport(moveTitleY, fontSize, boxOff, whiteBackground)
% This function sets some default properties that we want for the figure
% before it is exported e.g., fontName and fontSize.
%
% Author: Giovanni M. Di Liberto

    if ~exist('moveTitleY') || isempty(moveTitleY)
        moveTitleY = 0;
    end

    if ~exist('fontSize') || isempty(fontSize)
        fontSize = 14;
    end
    
    if ~exist('fontname') || isempty(fontname)
        fontname = 'arial';
    end
    
    if ~exist('boxOff') || isempty(boxOff)
        boxOff = 1;
    end
    
    if ~exist('whiteBackground') || isempty(whiteBackground)
        whiteBackground = 1;
    end

    set(findall(gcf,'-property','FontSize'),'FontSize',fontSize)
    set(findall(gcf,'-property','fontname'),'fontname',fontname)

    if moveTitleY ~= 0
        set(gca,'Units','normalized')
        titleHandle = get( gca ,'Title' );
        pos  = get( titleHandle , 'position' );
        pos1 = pos + [0 moveTitleY 0];
        set( titleHandle , 'position' , pos1 );
    end

    if whiteBackground, set(gcf,'color','w'); end
    if boxOff, box off; end
end