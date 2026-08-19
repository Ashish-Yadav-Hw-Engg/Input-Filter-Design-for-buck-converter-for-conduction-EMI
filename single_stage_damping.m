%% 06 - Single-stage input filter damping (parallel Rd-Cb branch)
% Act 3, Scene 1: fix the Act-1 instability by damping the filter's
% resonant peak, WITHOUT quoting textbook "optimum damping" constants --
% instead, start from a reasonable rule-of-thumb branch and let a MATLAB
% sweep (re-running the actual EET + margin() calculation from script 04)
% find the Rd that maximizes phase margin for THIS converter/compensator.
%
% Topology: Rd in series with a DC-blocking cap Cb, the whole branch
% placed in PARALLEL with the filter capacitor Cf. Cb blocks DC so Rd
% carries no steady-state current -> no continuous power loss, only damps
% the resonant peak. This is the standard "parallel damping" approach.
%


close all; clear;
if ~exist('figures','dir'); mkdir('figures'); end

%% ---------------- Synchronous Buck converter parameters ----------------
L    = 1e-6; Rs = 30e-3; C = 200e-6; Resr = 0.8e-3;
Vg = 5; VM = 1; Vref = 1.8; H = 1; fs = 1e6;
Vout = Vref; D = Vout/Vg; Iout = 5; R = Vout/Iout;

s = tf('s');

wesr = 1/(C*Resr); wo = 1/sqrt(C*L);
Qload = R/sqrt(L/C); Qloss = sqrt(L/C)/(Resr+Rs);
Q = Qload*Qloss/(Qload+Qloss);
Gvdold = Vg*(1+s/wesr)/(1+(1/Q)*(s/wo)+(s/wo)^2);

ZC  = 1/(s*C) + Resr;
ZRC = minreal(ZC*R/(ZC+R));
ZL  = Rs + s*L;
ZD  = minreal((ZL + ZRC)/(D^2));
ZN  = tf(-(Rs + R)/(D)^2);

Gcm = 5.45; wL = 2*pi*8e3; wz = 2*pi*33e3; wp1 = 2*pi*300e3; wp2 = 2*pi*1e6;
Gc  = Gcm*(1+wL/s)*(1+s/wz)/(1+s/wp1)/(1+s/wp2);

%% ---------------- Undamped filter (baseline, from script 02/04) --------
Cf  = 47e-6; Lf = 10e-6; RLf = 10e-3;
ZCf_und = 1/(s*Cf);
ZLf     = s*Lf + RLf;
Zo_und  = minreal(ZCf_und*ZLf/(ZCf_und + ZLf));

Gvd_und = minreal(Gvdold*(1+Zo_und/ZN)/(1+Zo_und/ZD));
T_und   = H*(1/VM)*Gvd_und*Gc;
[Gm_u,Pm_u,~,~] = margin(T_und);
fprintf('Undamped:  GM = %5.2f dB, PM = %5.2f deg\n', 20*log10(Gm_u), Pm_u);

%% ---------------- Rule-of-thumb starting point --------------------------
R0 = sqrt(Lf/Cf);      % filter characteristic impedance
Cb = 4*Cf;              % common rule-of-thumb: blocking cap 3-4x Cf
Rd0 = R0;               % starting guess for the damping resistor
fprintf('Rule-of-thumb starting point: R0 = %5.3f ohm, Cb = %5.1f uF, Rd0 = %5.3f ohm\n', ...
    R0, Cb*1e6, Rd0);

%% ================= SWEEP Rd, evaluate closed-loop margin for each ========
Rd_vec = logspace(log10(0.02),log10(5),60);   % sweep ~20 mOhm to 5 ohm
PM_vec = zeros(size(Rd_vec));
GMdB_vec = zeros(size(Rd_vec));

for k = 1:length(Rd_vec)
    Rd = Rd_vec(k);
    Zdamp = Rd + 1/(s*Cb);              % Rd-Cb branch
    Zo_k  = minreal( (ZCf_und*ZLf*Zdamp) / (ZCf_und*ZLf + ZLf*Zdamp + ZCf_und*Zdamp) );
    Gvd_k = minreal(Gvdold*(1+Zo_k/ZN)/(1+Zo_k/ZD));
    T_k   = H*(1/VM)*Gvd_k*Gc;
    try
        [Gm_k,Pm_k,~,~] = margin(T_k);
        PM_vec(k) = Pm_k;
        GMdB_vec(k) = 20*log10(Gm_k);
    catch
        PM_vec(k) = NaN; GMdB_vec(k) = NaN;
    end
end

figure(1);
semilogx(Rd_vec,PM_vec,'b','LineWidth',2); hold on;
semilogx(Rd_vec,GMdB_vec,'r','LineWidth',2);
grid on; xlabel('Rd (\Omega)'); ylabel('Margin');
legend('Phase margin (deg)','Gain margin (dB)','Location','best');
title('Sweep: closed-loop margin vs damping resistor Rd (Cb fixed at 4\times Cf)');
saveas(gcf,'figures/06_Rd_sweep.png');

[best_PM, ibest] = max(PM_vec);
Rd_opt = Rd_vec(ibest);
fprintf('\nSweep result: best phase margin = %5.2f deg at Rd = %5.3f ohm\n', best_PM, Rd_opt);
fprintf('(Compare to rule-of-thumb guess Rd0 = %5.3f ohm -- use the sweep\n', Rd0);
fprintf(' value; the rule of thumb is only a starting point.)\n\n');

%% ================= Build damped filter at Rd_opt, re-check everything ====
Zdamp_opt = Rd_opt + 1/(s*Cb);
Zo_damped = minreal( (ZCf_und*ZLf*Zdamp_opt) / (ZCf_und*ZLf + ZLf*Zdamp_opt + ZCf_und*Zdamp_opt) );
Gvd_damped = minreal(Gvdold*(1+Zo_damped/ZN)/(1+Zo_damped/ZD));
T_damped = H*(1/VM)*Gvd_damped*Gc;

[Gm_d,Pm_d,Wcg_d,Wcp_d] = margin(T_damped);
fprintf('Damped (Rd=%5.3f ohm, Cb=%5.1f uF): GM = %5.2f dB, PM = %5.2f deg\n', ...
    Rd_opt, Cb*1e6, 20*log10(Gm_d), Pm_d);

figure(2);
margin(T_und); hold on;
title('Undamped filter: loop gain margin');
grid on;
saveas(gcf,'figures/06_margin_undamped.png');

figure(3);
margin(T_damped);
title(sprintf('Damped filter (Rd=%.3f\\Omega): loop gain margin',Rd_opt));
grid on;
saveas(gcf,'figures/06_margin_damped.png');

figure(4);
CL_und    = feedback(T_und,1);
CL_damped = feedback(T_damped,1);
step(CL_und,'b',CL_damped,'r',5e-4);
legend('Closed loop, undamped filter','Closed loop, damped filter','Location','best');
title('Step response: undamped (blue, ringing) vs damped (red)');
grid on;
saveas(gcf,'figures/06_step_response.png');

%% ================= Trade-off: attenuation cost of damping ===============
% Damping the resonant peak costs some rolloff/attenuation. Quantify it.
Hfilter_und    = 1/(s*Cf)/(1/(s*Cf) + s*Lf + RLf);
Hfilter_damped = minreal(Zo_damped/RLf * 0 + (1/(s*Cf+1/Zdamp_opt))/((1/(s*Cf+1/Zdamp_opt))+s*Lf+RLf)); %#ok<NASGU>
% (Simplify by directly evaluating the transfer function Vout_filter/Vin
%  for the damped network: Cf parallel with (Rd+1/sCb) as the shunt element)
Yshunt = s*Cf + 1/(Rd_opt + 1/(s*Cb));
Hfilter_damped = (1/Yshunt) / ( (1/Yshunt) + s*Lf + RLf );

ws = 2*pi*fs;
att_und    = -mag2db(abs(evalfr(Hfilter_und,1i*ws)));
att_damped = -mag2db(abs(evalfr(Hfilter_damped,1i*ws)));
fprintf('\nAttenuation at fs: undamped = %5.2f dB, damped = %5.2f dB (cost = %4.2f dB)\n', ...
    att_und, att_damped, att_und-att_damped);
fprintf('That''s the honest trade-off: stability margin bought at the price\n');
fprintf('of a bit of high-frequency attenuation. If that cost is too high,\n');
fprintf('see script 07 (two-stage filter) for another way to buy margin back.\n');
