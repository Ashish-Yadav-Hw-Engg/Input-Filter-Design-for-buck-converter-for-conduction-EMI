%% 05 - Middlebrook design criterion: |Zo(filter)| vs |Zi(converter)|
% Act 2: predict the script-04 failure from impedances alone, BEFORE
% closing the combined loop.
%
% Rule (R.D. Middlebrook, 1976): the filter's output impedance Zo must
% stay well below the converter's input impedance Zin across all
% frequencies where the converter's loop gain is significant, i.e.
%       |Zo(jw)| << |Zi_closed_loop(jw)|      (commonly 6-20 dB margin)
% Near the filter's own LC resonance, |Zo| peaks -- that peak is exactly
% where interaction shows up, which is why undamped filters are
% dangerous even though they attenuate ripple beautifully.
%


close all; clear;
if ~exist('figures','dir'); mkdir('figures'); end

%% ---------------- Synchronous Buck converter parameters ----------------
L    = 1e-6; Rs = 30e-3; C = 200e-6; Resr = 0.8e-3;
Vg = 5; VM = 1; Vref = 1.8; H = 1; fs = 1e6;
Vout = Vref; D = Vout/Vg; Iout = 5; R = Vout/Iout;

s = tf('s');

%% ---------------- Converter Gvdold, ZN, ZD (1-D form, as in script 01) --
wesr = 1/(C*Resr); wo = 1/sqrt(C*L);
Qload = R/sqrt(L/C); Qloss = sqrt(L/C)/(Resr+Rs);
Q = Qload*Qloss/(Qload+Qloss);
Gvdold = Vg*(1+s/wesr)/(1+(1/Q)*(s/wo)+(s/wo)^2);

ZC = 1/(s*C) + Resr;
ZL = Rs + s*L;
ZD = minreal((ZL + ZC)/(1-D)^2);
ZN = tf(-(Rs + R)/(1-D)^2);

%% ---------------- Compensator + loop gain + closed-loop Zi --------------
Gcm = 5.45; wL = 2*pi*8e3; wz = 2*pi*33e3; wp1 = 2*pi*300e3; wp2 = 2*pi*1e6;
Gc  = Gcm*(1+wL/s)*(1+s/wz)/(1+s/wp1)/(1+s/wp2);
T   = H*(1/VM)*Gvdold*Gc;

Yi = (1/ZN)*(T/(1+T)) + (1/ZD)/(1+T);
Zi = minreal(1/Yi);

%% ---------------- Filter output impedance Zo -----------------------------
Cf = 47e-6; Lf = 10e-6; RLf = 10e-3;
ZCf = 1/(s*Cf); ZLf = s*Lf + RLf;
Zo  = minreal(ZCf*ZLf/(ZCf + ZLf));

%% ================= THE CRITERION PLOT: |Zo| vs |Zi| =======================
fmin = 100; fmax = 1e6;
w = 2*pi*logspace(log10(fmin),log10(fmax),2000);

[magZo,~]  = bode(Zo,w); magZo = squeeze(magZo);
[magZi,~]  = bode(Zi,w); magZi = squeeze(magZi);
magZo_dB = 20*log10(magZo);
magZi_dB = 20*log10(magZi);
f = w/2/pi;

figure(1);
semilogx(f,magZo_dB,'r','LineWidth',2); hold on;
semilogx(f,magZi_dB,'b','LineWidth',2);
grid on;
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB\Omega)');
legend('|Zo| (filter output impedance)','|Zi| (converter closed-loop input impedance)', ...
    'Location','best');
title('Middlebrook criterion: |Zo| should stay well below |Zi|');
xlim([fmin fmax]);
saveas(gcf,'figures/05_Zo_vs_Zi.png');

%% ---------------- Report the margin (in dB) between them ----------------
sep_dB = magZi_dB - magZo_dB;
[worst_sep, idx] = min(sep_dB);
fprintf('=====================================================\n');
fprintf('MIDDLEBROOK CRITERION CHECK\n');
fprintf('  Worst-case |Zi|-|Zo| separation = %5.1f dB at f = %8.1f Hz\n', ...
    worst_sep, f(idx));
if worst_sep > 6
    fprintf('  --> Looks OK by a >6 dB rule of thumb, but check margin() too.\n');
elseif worst_sep > 0
    fprintf('  --> MARGINAL (<6 dB separation): expect real degradation in\n');
    fprintf('      loop GM/PM, matches script 04''s Case-2 result.\n');
else
    fprintf('  --> VIOLATED (|Zo| exceeds |Zi|): strong interaction expected,\n');
    fprintf('      matches script 04''s Case-2 instability/ringing.\n');
end
fprintf('=====================================================\n\n');

%% ================= Minor-loop gain Tm = Zo/Zi (diagnostic) ================
% This ratio is the quantity whose Nyquist behavior formally underlies the
% EET correction term (1+Zo/ZN)/(1+Zo/ZD). Zi is NOT a simple minimum-phase
% loop gain (it goes negative / has RHP-like phase behavior at low
% frequency, by construction -- see script 01), so treat this as a
% diagnostic overlay rather than a strict margin() GM/PM call; the
% magnitude-separation plot above is the practical, actionable criterion.
Tm = minreal(Zo/Zi);

figure(2);
bodeoptions_Tm = bodeoptions;
bodeoptions_Tm.FreqUnits = 'Hz';
bodeoptions_Tm.Xlim = [fmin fmax];
bodeoptions_Tm.Grid = 'on';
bodeoptions_Tm.Title.String = 'Minor-loop gain Tm = Zo/Zi (diagnostic only)';
bode(Tm,bodeoptions_Tm,'m');
h = findobj(gcf,'type','line'); set(h,'LineWidth',2);
saveas(gcf,'figures/05_minor_loop_gain.png');

fprintf('Where |Tm| = |Zo/Zi| approaches or crosses 0 dB, expect interaction.\n');
fprintf('Next: scripts 06-07 push |Zo| down (damping / multi-stage design)\n');
fprintf('to re-open that separation margin without giving up EMI attenuation.\n');
