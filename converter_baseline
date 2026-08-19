%% 01 - Converter baseline (NO input filter)
% Act 1, Scene 1: "the converter alone is stable"
%
% Builds the synchronous buck + PID voltage loop, checks GM/PM with
% margin(), and plots the converter's own CLOSED-LOOP INPUT IMPEDANCE Zi.
% Zi going negative at low frequency (negative incremental resistance of
% a regulated converter, i.e. constant-power-load behavior) is shown here
% BEFORE any filter exists in the story, so it's clearly established as a
% converter property -- this is the seed that scripts 04/05 pay off.
%


close all; clear;
if ~exist('figures','dir'); mkdir('figures'); end

%% ---------------- Synchronous Buck converter parameters ----------------
L    = 1e-6;    % inductance
Rs   = 30e-3;   % series resistance RL + Ron
C    = 200e-6;  % output filter capacitance
Resr = 0.8e-3;  % capacitor ESR
Vg   = 5;       % input voltage
VM   = 1;       % PWM saw-tooth amplitude
Vref = 1.8;     % reference voltage
H    = 1;       % sensing gain
fs   = 1e6;     % switching frequency
Vout = Vref;
D    = Vout/Vg; % ideal duty cycle
Iout = 5;       % load current
R    = Vout/Iout;

s = tf('s');

%% ---------------- Control-to-output Gvdold (no filter) ------------------
wesr  = 1/(C*Resr);
wo    = 1/sqrt(C*L);
Qload = R/sqrt(L/C);
Qloss = sqrt(L/C)/(Resr+Rs);
Q     = Qload*Qloss/(Qload+Qloss);
Gvdold = Vg*(1+s/wesr)/(1+(1/Q)*(s/wo)+(s/wo)^2);

%% ---------------- Converter ZN, ZD (no filter, uses (1-D)^2 form) -------
ZC = 1/(s*C) + Resr;
ZL = Rs + s*L;
ZD = minreal((ZL + ZC)/(1-D)^2);
ZN = tf(-(Rs + R)/(1-D)^2);   % steady-state Vout = (R/(R+Rs))*Vg

%% ---------------- PID compensator ---------------------------------------
Gcm = 5.45;
wL  = 2*pi*8e3;
wz  = 2*pi*33e3;
wp1 = 2*pi*300e3;
wp2 = 2*pi*1e6;
Gc  = Gcm*(1+wL/s)*(1+s/wz)/(1+s/wp1)/(1+s/wp2);

%% ---------------- Loop gain and GM/PM -----------------------------------
T = H*(1/VM)*Gvdold*Gc;

[Gm,Pm,Wcg,Wcp] = margin(T);
GmdB = 20*log10(Gm);

fprintf('=====================================================\n');
fprintf('CONVERTER BASELINE (no filter)\n');
fprintf('  Gain margin   = %6.2f dB  at f = %8.1f Hz\n', GmdB, Wcg/2/pi);
fprintf('  Phase margin  = %6.2f deg at f = %8.1f Hz (crossover)\n', Pm, Wcp/2/pi);
if Pm > 0 && GmdB > 0
    fprintf('  --> STABLE (this is our "before" baseline)\n');
else
    fprintf('  --> UNSTABLE -- fix the compensator before going further!\n');
end
fprintf('=====================================================\n\n');

figure(1);
margin(T);
title('Converter alone: loop gain T, margin plot (baseline)');
grid on;
saveas(gcf,'figures/01_baseline_margin.png');

%% ---------------- Closed-loop input impedance Zi -------------------------
% This is what an input filter's output impedance Zo will eventually have
% to "fight" -- computed here with NO filter present, purely a converter
% property. Watch the low-frequency region: Zi goes NEGATIVE. A regulated
% converter draws MORE input current as Vin drops (constant power load),
% which looks like negative incremental resistance to anything upstream.
Yi = (1/ZN)*(T/(1+T)) + (1/ZD)/(1+T);
Zi = minreal(1/Yi);

fmin = 100; fmax = 1e6;
BodeOptions = bodeoptions;
BodeOptions.FreqUnits = 'Hz';
BodeOptions.Xlim = [fmin fmax];
BodeOptions.Grid = 'on';
BodeOptions.PhaseMatching = 'on';
BodeOptions.PhaseMatchingFreq = 1;
BodeOptions.PhaseMatchingValue = -180;
BodeOptions.Ylim = {[-60,40];[-270,540]};
BodeOptions.Title.String = 'Converter closed-loop input impedance Zi (no filter yet)';

figure(2);
bode(Zi,BodeOptions,'b');
h = findobj(gcf,'type','line'); set(h,'LineWidth',2);
saveas(gcf,'figures/01_Zi_baseline.png');

fprintf('Note: Zi has negative real part / a phase jump at low frequency.\n');
fprintf('That negative incremental resistance is a converter property that\n');
fprintf('exists whether or not a filter is ever added -- keep it in mind for\n');
fprintf('script 05 (Middlebrook criterion), where it becomes the "Zin" that\n');
fprintf('the filter''s output impedance Zo has to stay well below.\n');
