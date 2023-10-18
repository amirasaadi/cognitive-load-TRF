function plot_trf(model,chan_to_plot)
% Plot the TRFs for all channels specified (if chan_to_plot is an empty
% array, plot all channels. Default: plot all channels)
% Nate Zuk (2021)
% Modified by Amir Asadi 
% added option to plot mean of more than one channel

if nargin<2
    chan_to_plot = []; 
end


selected_chan = model.w(:,:,chan_to_plot);
selected_chan = mean(selected_chan,3);

figure
if ~isempty(chan_to_plot)
    plot(model.t,squeeze(selected_chan),'LineWidth',2);
else
    plot(model.t,squeeze(model.w),'LineWidth',1);
end
set(gca,'FontSize',14);
xlabel('Delay (ms)');
ylabel('Model weight');
