%% 03 - Gvd WITHOUT filter vs Gvd WITH filter (via Extra Element Theorem)
% Act 1, Scene 3: "here's the plot that shows the filter corrupting the
% plant the compensator thinks it's controlling."
%
% 

close all; clear;
if ~exist('figures','dir'); mkdir('figures'); end

%% ---------------- Synchronous Buck converter parameters ----------------
L    = 1e-6;
Rs   = 30e-3;
C    = 200e-6;
Resr = 0.8e-3;
Vg   = 5;
Vref = 1.8;
Vout = Vref;
D    = Vout/Vg;
Iout = 5;
R    = Vout/Iout;

s = tf('s');

%% ---------------- Lf-Cf input filter (see script 02) ---------------------
Cf  = 47e-6;
Lf  = 10e-6;
RLf = 10e-3;
ZCf = 1/(s*Cf);
ZLf = s*Lf + RLf;
Zo  = minreal(ZCf*ZLf/(ZCf + ZLf));   % filter output impedance

%% ---------------- Converter control-to-output, no filter -----------------
wesr  = 1/(C*Resr);
wo    = 1/sqrt(C*L);
Qload = R/sqrt(L/C);
Qloss = sqrt(L/C)/(Resr+Rs);
Q     = Qload*Qloss/(Qload+Qloss);
Gvdold = Vg*(1+s/wesr)/(1+(1/Q)*(s/wo)+(s/wo)^2);

%% ---------------- Converter ZN, ZD (D-form, matches EET with filter) -----
ZC  = 1/(s*C) + Resr;
ZRC = minreal(ZC*R/(ZC+R));
ZL  = Rs + s*L;
ZD  = minreal((ZL + ZRC)/(D^2));
ZN  = tf(-(Rs + R)/(D)^2);

%% ---------------- Gvd modified by the filter (Extra Element Theorem) -----
Gvd = minreal(Gvdold*(1+Zo/ZN)/(1+Zo/ZD));

%% ---------------- Overlay: Zo (red), ZN (green), ZD (blue) --------------
fmin = 100; fmax = 1e6;
BodeOptions = bodeoptions;
BodeOptions.FreqUnits = 'Hz';
BodeOptions.Xlim = [fmin fmax];
BodeOptions.Grid = 'on';
BodeOptions.Ylim = {[-60,40];[-90,90]};
BodeOptions.Title.String = 'Zo (red), ZN (green), ZD (blue) -- sets up the Act 2 criterion';

figure(1);
bode(ZD,BodeOptions,'b'); hold on;
bode(ZN,BodeOptions,'g');
bode(Zo,BodeOptions,'r');
legend('ZD','ZN','Zo','Location','best');
h = findobj(gcf,'type','line'); set(h,'LineWidth',2);
saveas(gcf,'figures/03_Zo_ZN_ZD_overlay.png');

%% ---------------- Overlay: Gvdold (blue) vs Gvd with filter (red) -------
BodeOptions.Title.String = 'Gvdold no filter (blue) vs Gvd with filter (red)';
BodeOptions.Ylim = {[-60,40];[-540,0]};
BodeOptions.PhaseMatching = 'on';
BodeOptions.PhaseMatchingFreq = 1;
BodeOptions.PhaseMatchingValue = 0;

figure(2);
bode(Gvdold,BodeOptions,'b'); hold on;
bode(Gvd,BodeOptions,'r');
legend('Gvdold (no filter)','Gvd (with filter)','Location','best');
h = findobj(gcf,'type','line'); set(h,'LineWidth',2);
saveas(gcf,'figures/03_Gvd_overlay.png');

fprintf('Look for: extra gain/phase wiggle in Gvd right around the filter''s\n');
fprintf('resonant frequency, absent in Gvdold. That perturbation is what the\n');
fprintf('compensator (designed against Gvdold) has NOT been designed to handle\n');
fprintf('-- feed this Gvd into script 04''s loop gain to see the consequence.\n');
