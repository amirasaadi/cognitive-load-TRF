function dpr = calculate_dprime(x,y)
% Calculate the d-prime value between x & y. Ignore NaN values.
% Nate Zuk (2021)
% I Generalize this function instead of one channel now it support more 
% than one channel
x=mean(x,2);
y=mean(y,2);
mn = mean(x,'omitnan')-mean(y,'omitnan');
st = sqrt(0.5*(var(x,'omitnan') + var(y,'omitnan')));
dpr = mn./st;