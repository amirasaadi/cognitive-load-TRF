function plot_true_null(true_vals,null_vals)
% Plot all true values as dots, and plot the mean and 2x standard deviation
% of the null values.
% Nate Zuk (2021)
% Modified by Amir Asadi 
% added option to plot mean of more than one channel

true_vals = mean(true_vals,2);
null_vals = mean(null_vals,2);

jit = (rand(length(true_vals),1)-0.5)*0.2; % randomly jitter r values to make the easier to see
figure
hold on
plot(jit,true_vals,'k.','MarkerSize',12);
errorbar(1,mean(null_vals),2*std(null_vals),'ko','MarkerSize',10,'LineWidth',2);
set(gca,'FontSize',14,'XTick',[0 1],'XTickLabel',{'True','Null'},'XLim',[-0.5 1.5]);
ylabel('Prediction accuracy');