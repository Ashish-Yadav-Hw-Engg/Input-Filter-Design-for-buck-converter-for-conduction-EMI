%% 02 - Lf-Cf input filter, designed and evaluated IN ISOLATION
% Act 1, Scene 2: "the filter alone is fine"
%
% Designs the filter purely against an EMI attenuation spec at fs, and
% checks it as a standalone 2nd-order network (its own Q / damping ratio,
% its own Bode response). No converter is involved yet -- on its own this
% is a boring, well-behaved low-pass filter.


close all; clear;
if ~exist('figures','dir'); mkdir('figures'); end

Vg   = 5;      % input dc voltage
Vout = 1.8;    % nominal output dc voltage
fs   = 1e6;    % switching frequency
D    = Vout/Vg;
Iout = 5;      % load current

%% ---------------- Theoretical input current harmonics -------------------
nharmonics = 10;
harmonics = zeros(nharmonics,1);
for k = 1:nharmonics
    harmonics(k) = 20*log10(2*Iout/k/pi/sqrt(2));
end
fprintf('--------------------------------------\n');
fprintf('Theoretical input harmonics (in [dBA])\n');
disp(harmonics)
fprintf('--------------------------------------\n');

%% ---------------- LC input filter sizing ---------------------------------
Attenuation = 85; % desired attenuation (dB) at fs
ff = fs/(10^(Attenuation/40));      % required filter corner frequency
Cf = 47e-6;                          % selected filter capacitor
Lf_theoretical = 1/4/pi^2/ff^2/Cf;   % required filter inductor
fprintf('Filter inductance needed: %4.2f uH\n',Lf_theoretical*1e6);

s  = tf('s');
Lf  = 10e-6;   % Lf rounded value
RLf = 10e-3;   % Lf series resistance
fprintf('Filter inductance (rounded), Lf = %4.2f uH\n',Lf*1e6);
fprintf('Filter corner frequency, ff = %4.2f kHz\n',1/2/pi/sqrt(Cf*Lf)/1000);

Hfilter = 1/(s*Cf)/(1/(s*Cf) + s*Lf + RLf);

%% ---------------- Filter's own Q / damping ratio (standalone!) ----------
% Standard 2nd-order LC: wo = 1/sqrt(Lf*Cf), Q = (1/RLf)*sqrt(Lf/Cf)
wo_filt = 1/sqrt(Lf*Cf);
Q_filt  = (1/RLf)*sqrt(Lf/Cf);
zeta_filt = 1/(2*Q_filt);
fprintf('Filter standalone: fo = %4.2f kHz, Q = %4.2f, zeta = %4.3f\n', ...
    wo_filt/2/pi/1000, Q_filt, zeta_filt);
fprintf('(Q here reflects only the inductor''s winding resistance RLf --\n');
fprintf(' this is a lightly-damped, resonant-but-not-oscillatory network\n');
fprintf(' on its own. That resonance peak is exactly what interacts badly\n');
fprintf(' with the converter once the two are connected -- see script 04.)\n\n');

%% ---------------- Filter output impedance Zo (used again in script 03+) -
ZCf = 1/(s*Cf);
ZLf = s*Lf + RLf;
Zo  = minreal(ZCf*ZLf/(ZCf + ZLf));

%% ---------------- Bode: filter transfer function (standalone) -----------
fmin = 10; fmax = 10e6;
BodeOptions = bodeoptions;
BodeOptions.FreqUnits = 'Hz';
BodeOptions.Xlim = [fmin fmax];
BodeOptions.Ylim = {[-120,40];[-180,0]};
BodeOptions.Grid = 'on';
BodeOptions.Title.String = 'Filter frequency response (standalone, unloaded)';

figure(1);
bode(Hfilter,BodeOptions,'b');
h = findobj(gcf,'type','line'); set(h,'LineWidth',2);
saveas(gcf,'figures/02_filter_standalone_bode.png');

%% ---------------- Bode: filter output impedance Zo (standalone) ---------
BodeOptions2 = bodeoptions;
BodeOptions2.FreqUnits = 'Hz';
BodeOptions2.Xlim = [fmin fmax];
BodeOptions2.Grid = 'on';
BodeOptions2.Title.String = 'Filter output impedance Zo (standalone)';
figure(2);
bode(Zo,BodeOptions2,'r');
h = findobj(gcf,'type','line'); set(h,'LineWidth',2);
saveas(gcf,'figures/02_filter_Zo_standalone.png');

%% ---------------- Attenuation check at fs --------------------------------
ws = 2*pi*fs;
response_at_fs = evalfr(Hfilter,1i*ws);
magnitude_at_fs = mag2db(abs(response_at_fs));
fprintf('Filter magnitude response at fs: %4.2f dB\n',magnitude_at_fs);
fprintf('Filter attenuation at fs: %4.2f dB (spec was %d dB)\n',-magnitude_at_fs,Attenuation);
