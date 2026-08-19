%% 04 - THE REVEAL: closed-loop stability WITHOUT vs WITH input filter
% Act 1, Scene 4 (climax): converter alone = stable (script 01), filter
% alone = fine (script 02), Gvd visibly perturbed (script 03) -- now close
% the loop both ways and watch the margin collapse / step response ring.
%


close all; clear;
if ~exist('figures','dir'); mkdir('figures'); end

%% ---------------- Synchronous Buck converter parameters ----------------
L    = 1e-6;
Rs   = 30e-3;
C    = 200e-6;
Resr = 0.8e-3;
Vg   = 5;
VM   = 1;
Vref = 1.8;
H    = 1;
fs   = 1e6;
Vout = Vref;
D    = Vout/Vg;
Iout = 5;
R    = Vout/Iout;

s = tf('s');

%% ---------------- Converter control-to-output Gvdold (no filter) -------
wesr  = 1/(C*Resr);
wo    = 1/sqrt(C*L);
Qload = R/sqrt(L/C);
Qloss = sqrt(L/C)/(Resr+Rs);
Q     = Qload*Qloss/(Qload+Qloss);
Gvdold = Vg*(1+s/wesr)/(1+(1/Q)*(s/wo)+(s/wo)^2);   % <-- CASE 1 plant

%% ---------------- PID compensator (same for both cases) ----------------
Gcm = 5.45;
wL  = 2*pi*8e3;
wz  = 2*pi*33e3;
wp1 = 2*pi*300e3;
wp2 = 2*pi*1e6;
Gc  = Gcm*(1+wL/s)*(1+s/wz)/(1+s/wp1)/(1+s/wp2);

%% ================= CASE 1: NO INPUT FILTER ==============================
T_nofilter = H*(1/VM)*Gvdold*Gc;

[Gm1,Pm1,Wcg1,Wcp1] = margin(T_nofilter);
GmdB1 = 20*log10(Gm1);

fprintf('=====================================================\n');
fprintf('CASE 1: Converter WITHOUT input filter\n');
fprintf('  Gain margin   = %6.2f dB  at f = %8.1f Hz\n', GmdB1, Wcg1/2/pi);
fprintf('  Phase margin  = %6.2f deg at f = %8.1f Hz (crossover)\n', Pm1, Wcp1/2/pi);
if Pm1 > 0 && GmdB1 > 0
    fprintf('  --> STABLE\n');
else
    fprintf('  --> UNSTABLE (negative margin)\n');
end
fprintf('=====================================================\n\n');

%% ================= Build Lf-Cf input filter ==============================
Cf  = 47e-6;
Lf  = 10e-6;
RLf = 10e-3;
ZCf = 1/(s*Cf);
ZLf = s*Lf + RLf;
Zo  = minreal(ZCf*ZLf/(ZCf + ZLf));

%% ================= Converter ZN, ZD WITH filter (EET) ====================
ZC  = 1/(s*C) + Resr;
ZRC = minreal(ZC*R/(ZC+R));
ZL  = Rs + s*L;
ZD  = minreal((ZL + ZRC)/(D^2));
ZN  = tf(-(Rs + R)/(D)^2);

Gvd_filter = minreal(Gvdold*(1+Zo/ZN)/(1+Zo/ZD));   % <-- CASE 2 plant

%% ================= CASE 2: WITH INPUT FILTER ==============================
T_filter = H*(1/VM)*Gvd_filter*Gc;

[Gm2,Pm2,Wcg2,Wcp2] = margin(T_filter);
GmdB2 = 20*log10(Gm2);

fprintf('=====================================================\n');
fprintf('CASE 2: Converter WITH Lf-Cf input filter\n');
fprintf('  Gain margin   = %6.2f dB  at f = %8.1f Hz\n', GmdB2, Wcg2/2/pi);
fprintf('  Phase margin  = %6.2f deg at f = %8.1f Hz (crossover)\n', Pm2, Wcp2/2/pi);
if Pm2 > 0 && GmdB2 > 0
    fprintf('  --> STABLE\n');
else
    fprintf('  --> UNSTABLE (negative margin)\n');
end
fprintf('=====================================================\n\n');

%% ================= Bode plot: overlay T_nofilter vs T_filter =============
fmin = 100; fmax = 1e6;
BodeOptions = bodeoptions;
BodeOptions.FreqUnits = 'Hz';
BodeOptions.Xlim = [fmin fmax];
BodeOptions.Grid = 'on';
BodeOptions.PhaseMatching = 'on';
BodeOptions.PhaseMatchingFreq = 1;
BodeOptions.PhaseMatchingValue = -180;
BodeOptions.Ylim = {[-40,60];[-270,90]};
BodeOptions.Title.String = 'Loop gain T: no filter (blue) vs with input filter (red)';

figure(1);
bode(T_nofilter,BodeOptions,'b'); hold on;
bode(T_filter,BodeOptions,'r');
legend('T no filter','T with filter','Location','best');
h = findobj(gcf,'type','line'); set(h,'LineWidth',2);
saveas(gcf,'figures/04_T_overlay.png');

%% ================= margin() plots (auto GM/PM markers) ===================
figure(2);
margin(T_nofilter);
title('CASE 1: Loop gain margin plot - NO input filter');
grid on;
saveas(gcf,'figures/04_margin_case1.png');

figure(3);
margin(T_filter);
title('CASE 2: Loop gain margin plot - WITH input filter');
grid on;
saveas(gcf,'figures/04_margin_case2.png');

%% ================= Closed-loop step response comparison ==================
CL_nofilter = feedback(T_nofilter,1);
CL_filter   = feedback(T_filter,1);

figure(4);
step(CL_nofilter,'b',CL_filter,'r',5e-4);
legend('Closed loop, no filter','Closed loop, with filter','Location','best');
title('Closed-loop step response: no filter (blue) vs with filter (red)');
grid on;
saveas(gcf,'figures/04_step_response.png');

fprintf('If CASE 2 shows a much lower/negative phase margin than CASE 1,\n');
fprintf('and/or the red step response rings or diverges, the input filter\n');
fprintf('is under-damped and interacting with the regulator loop.\n');
fprintf('Next: script 05 shows how to PREDICT this from Zo vs Zi before\n');
fprintf('ever running margin() on the combined loop; scripts 06-07 fix it.\n');
