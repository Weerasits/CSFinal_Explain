%% ==============================================================
% Industrial Furnace — Manual PI Control + Bode + Step Response
% ==============================================================
clear; clc; close all;

%% ---- Process Parameters ----
K     = 4.59;      % degC per percent fuel
tau1  = 34.20;     % min
tau2  = 26.29;     % min
tau3  = 19.77;     % min
tau4  =  4.22;     % min
theta = 19.46;     % min (time delay)

s = tf('s');
Gnd = K / ((tau1*s+1)*(tau2*s+1)*(tau3*s+1)*(tau4*s+1));  % without delay
G   = Gnd; 
G.InputDelay = theta;   % include exact delay

%% ---- Controller: PI (Manual Tune) ----
% ปรับค่า Kp และ Ti เองได้ตรงนี้
Kp = 0.039456;      % Proportional gain
Ti = 30.30880319557536;       % Integral time constant (min)

Ki = Kp / Ti;
C = pid(Kp, Ki, 0);     % PI controller (no derivative)

fprintf('\n=== Controller Parameters ===\n');
fprintf('Kp = %.3f\n', Kp);
fprintf('Ti = %.3f min (Ki = %.4f)\n', Ti, Ki);

%% ---- Open-loop and Closed-loop ----
L   = C * G;             % open-loop transfer function
Tcl = feedback(L, 1);    % closed-loop (unity feedback)

%% ---- Frequency Domain: Bode Plot ----
figure('Name','Bode Plot (Open-loop)','Color','w');
margin(L);
grid on;
title('Bode Plot with Gain and Phase Margins (Open-loop)');

% ดึงค่าจาก margin
[Gm, Pm, Wcg, Wcp] = margin(L);
GMdB = 20*log10(Gm);

fprintf('\n=== Frequency-Domain Analysis ===\n');
if isfinite(GMdB)
    fprintf('Gain Margin  = %.2f dB at ωcg = %.4f rad/min\n', GMdB, Wcg);
else
    fprintf('Gain Margin  = Infinite (no gain crossover)\n');
end
if ~isnan(Pm)
    fprintf('Phase Margin = %.2f deg at ωcp = %.4f rad/min\n', Pm, Wcp);
else
    fprintf('Phase Margin = NaN (no phase crossover)\n');
end

%% ---- Time-Domain: Step Response ----
figure('Name','Step Response (Closed-loop)','Color','w');
t_final = 5*(tau1 + tau2 + tau3 + tau4 + theta);
step(Tcl, t_final);
grid on;
title('Closed-loop Step Response (r → y)');

S = stepinfo(Tcl);   % คำนวณ Rise Time, Settling Time, Overshoot

fprintf('\n=== Time-Domain Performance ===\n');
fprintf('Rise Time (10-90%%)  = %.2f min\n', S.RiseTime);
fprintf('Settling Time (2%%)  = %.2f min\n', S.SettlingTime);
fprintf('Overshoot (%%)       = %.2f %%\n', S.Overshoot);

%% ---- Optional: Pade Approximation for Visualization ----
% ถ้า MATLAB มีปัญหากับ delay ใน margin() ให้เปิดส่วนนี้แทน
use_pade_for_plot = false;
if use_pade_for_plot
    Np = 6; % Pade order
    [numD, denD] = pade(theta, Np);
    Gp = Gnd * tf(numD, denD);
    Lp = C * Gp;

    figure('Name','Bode Plot with Pade Approximation','Color','w');
    margin(Lp);
    grid on;
    title(sprintf('Bode Plot (Pade Approx, N=%d)', Np));
end
