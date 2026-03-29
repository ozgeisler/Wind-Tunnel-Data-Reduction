clear
clc
close all

%Variables to be loaded by datafile
qi = 25.5;                      %indicated dynamic pressure (N/m^2);

xR = [9;0.1;1.1;-1388;5;65];    %data point of raw balance forces/moments [L;D;Y;P;N;R] (N & Nm)

alpha = 13*pi/180;
psi = -5*pi/180;

%------------------Constants defined by UWAL-------------------------------
%A. Indicated to actual q
qa_over_qi = 1.0125;

%B. Balance interactions
A1 = blkdiag(1.1, 1.2, 0.9, 1, 1.2, 1.3);

A1(2,1) = 0.2;
A1(3,4) = 0.001;
A1(3,6) = 0.1;
A1(4,1) = 0.1;
A1(5,1) = 0.05;
A1(6,2) = -0.2;

A2 = zeros(6,6);

%C. Tares
xTare = zeros(size(xR))
%D. Weight tares
W       = 2000;         %weight of model (N)
xm      = 0.75;         %x position of cg w.r.t. BMC (m)
ym      = 0.1;          %y position of cg w.r.t. BMC (m)
zm      = -0.2;         %z position of cg w.r.t. BMC (m)

%E. Moment transfers
s = 0.2;
t = -0.1;
u = 0;

%F. Blockage corrections
CA      = 8.6;          %actual test section cross section area
KA      = 0.7;
VA      = 0.5;
KB      = 0.2;
VB      = 0.25;

%G. Initial coefficients
S_W     = 0.25;         %reference area (m^2)
cbar    = 0.1;          %reference chord (m)
b_ref   = 0.75;         %reference span (m)

%H. Flow angularity
alpha_upflow = -0.012*pi/180;

%I. Wall corrections
del_w   = 0.4;      
C       = 8.92;     %test section cross section area not accounting for fillets (m^2)
del_As  = 0.3;
dCMdds  = -0.2;     %change in pitching moment with a change in stabilizer angle


%----------------------------Data Reduction--------------------------------
%A. Indicated to actual q
qa = qa_over_qi*qi;
fprintf('A. Actual dynamic pressure: qa = %.4f N/m^2\n', qa)
%B. Balance interactions
xB = A1*xR + A2 * (xR).^2;
fprintf('\nB. After balance interactions:\n');
fprintf('   L=%.3f N, D=%.3f N, Y=%.3f N\n',   xB(1), xB(2), xB(3));
fprintf('   P=%.3f Nm, N=%.3f Nm, R=%.3f Nm\n', xB(4), xB(5), xB(6));

%C. Tares
xC = xB - xTare;
fprintf('\nC. After tare removal (no change, tares = 0)\n');

%D. Weight tares

% Gravity acting on CG offset from BMC creates spurious moments
% Weight vector in body frame (pitched by alpha,yawed by psi);
Wx = W * sin(alpha)*cos(psi); %longitudinal component
Wy = -W * sin(psi);
Wz = -W * cos(alpha) * cos(psi);
% Cross Product r x W
P_wtare = zm*Wx - xm*Wz; % Pitching moment weight tare
N_wtare = xm*Wy - ym*Wx; % Yawing moment weight tare
R_wtare = ym*Wz - zm*Wy; % Rolling moment wight tate

L_wtare = 0;  % weight has no lift tare (force only)
D_wtare = 0;  % weight has no drag tare
Y_wtare = 0;  % weight has no sideforce tare

xWtare = [L_wtare;D_wtare;Y_wtare;P_wtare;N_wtare;R_wtare];
xD     = xC - xWtare;% Subtract weight tare from mesurements
fprintf('\nD. Weight tares:\n');
fprintf('   P_tare=%.3f Nm, N_tare=%.3f Nm, R_tare=%.3f Nm\n',...
        P_wtare, N_wtare, R_wtare);
fprintf('   After weight tare removal:\n');
fprintf('   L=%.3f N, D=%.3f N, P=%.3f Nm\n', xD(1), xD(2), xD(4));

%E. Moment transfers

% left handed sign convention
%M _MMC = M_BMC = moment arm effects
%
%   Roll_MMC  = Roll_BMC  + u*L - t*Y
%   Pitch_MMC = Pitch_BMC + s*L + t*D
%   Yaw_MMC   = Yaw_BMC   - s*Y - u*D

L_E = xD(1); D_E = xD(2); Y_E = xD(3);

R_MMC = xD(6) + u*L_E - t*Y_E;
P_MMC = xD(4) + s*L_E + t*D_E;
N_MMC = xD(5) - s*Y_E - u*D_E; 

xE = [L_E; D_E; Y_E; P_MMC; N_MMC; R_MMC];
fprintf('\nE. After moment transfer to MMC:\n');
fprintf('   P_MMC=%.3f Nm, N_MMC=%.3f Nm, R_MMC=%.3f Nm\n',...
        P_MMC, N_MMC, R_MMC);


%F. Blockage corrections

% Solid blockage: model volume displaces tunnel flow -> speeds it up
% epsilon_sb = KA * VA / CA^(3/2)   (solid blockage factor)
% Wake blockage assumed negligible per problem statement

epsilon_sb = KA * VA / CA^(3/2);   % solid blockage factor
epsilon_wb = KB * VB / CA^(3/2);   % wake blockage (kept for completeness)
epsilon    = epsilon_sb;            % total blockage (wake negligible)

% Corrected dynamic pressure:
% q_corrected = qa * (1 + epsilon)^2 ≈ qa*(1 + 2*epsilon) for small epsilon
q_corr = qa * (1 + epsilon)^2;

fprintf('\nF. Blockage corrections:\n');
fprintf('   epsilon_sb = %.6f\n', epsilon_sb);
fprintf('   q_corrected = %.4f N/m^2\n', q_corr);
%G. Initial coefficients

CL = xE(1) / (q_corr * S_W);
CD = xE(2) / (q_corr * S_W);
CY = xE(3) / (q_corr * S_W);
Cm = xE(4) / (q_corr * S_W * cbar);
Cn = xE(5) / (q_corr * S_W * b_ref);
Cl = xE(6) / (q_corr * S_W * b_ref);

fprintf('\nG. Initial coefficients (body axis):\n');
fprintf('   CL=%.4f, CD=%.4f, CY=%.4f\n', CL, CD, CY);
fprintf('   Cm=%.4f, Cn=%.4f, Cl=%.4f\n', Cm, Cn, Cl);

%H. Flow angularity

alpha_corrected = alpha + alpha_upflow;

CD_H = CD - CL * alpha_upflow;
CL_H = CL;
Cm_H = Cm;
CY_H = CY;
Cn_H = Cn;
Cl_H = Cl;

fprintf('\nH. After flow angularity correction:\n');
fprintf('   alpha_corrected = %.4f deg\n', alpha_corrected*180/pi);
fprintf('   CD_corrected = %.4f (was %.4f)\n', CD_H, CD);

%I. Wall corrections

% Induced upwash angle correction
delta_alpha_wall = del_w*CL/ (pi *C);

% Induced drag correction
delta_CD_wall    = del_w * CL^2 / (pi * C);

% Streamline curvature correction to pitching moment:
delta_Cm_wall    = del_As * dCMdds * CL / (pi * C);

alpha_final = alpha_corrected + delta_alpha_wall;
CD_I = CD_H + delta_CD_wall;
CL_I = CL_H;   % CL unchanged by wall correction at first order
Cm_I = Cm_H + delta_Cm_wall;
CY_I = CY_H;
Cn_I = Cn_H;
Cl_I = Cl_H;

fprintf('\nI. After wall corrections:\n');
fprintf('   delta_alpha_wall = %.6f deg\n', delta_alpha_wall*180/pi);
fprintf('   alpha_final = %.4f deg\n', alpha_final*180/pi);
fprintf('   CD_final = %.4f, Cm_final = %.4f\n', CD_I, Cm_I);

%J. Final coefficients & corrected angle of attack
alpha_final = alpha + alpha_upflow + delta_alpha_wall;

% Final wind-axis coefficients
CL_final = CL_I;
CD_final = CD_I;  
CY_final = CY_I;
Cm_final = Cm_I ;
Cn_final = Cn_I;
Cl_final = Cl_I;
%K. Axis transfers


CL_s = CL_final;

CD_s = CD_final*cos(psi) - CY_final*sin(psi);

CY_s = CY_final*cos(psi) + CD_final*sin(psi);

Cm_s = Cm_final*cos(psi);

Cl_s = Cl_final*cos(psi) + Cn_final*(cbar/b_ref)*sin(psi);

Cn_s = Cn_final;


fprintf('\nK. Final STABILITY-axis coefficients:\n');
fprintf('   CL = %.4f\n', CL_s);
fprintf('   CD = %.4f\n', CD_s);
fprintf('   CY = %.4f\n', CY_s);
fprintf('   Cm = %.4f\n', Cm_s);
fprintf('   Cn = %.4f\n', Cn_s);
fprintf('   Cl = %.4f\n', Cl_s);

stages = {'Initial','Upflow','Wall','Final'};
CD_vals = [CD, CD_H, CD_I, CD_final];
Cm_vals = [Cm, Cm_H, Cm_I, Cm_final];

figure;
bar(categorical(stages), CD_vals)
ylabel('C_D')
title('Drag Coefficient Through Data Reduction Stages')
grid on

figure;
bar(categorical(stages), Cm_vals)
ylabel('C_m')
title('Pitching Moment Coefficient Through Data Reduction Stages')
grid on

moments_before = [xB(4), xB(5), xB(6)];
moments_after_weight = [xD(4), xD(5), xD(6)];
moments_after_transfer = [xE(4), xE(5), xE(6)];

figure;
bar([moments_before; moments_after_weight; moments_after_transfer]')
set(gca,'XTickLabel',{'Pitch','Yaw','Roll'})
legend('After Balance Interaction','After Weight Tare','After Moment Transfer')
ylabel('Moment (Nm)')
title('Moment Corrections Through Data Reduction')
grid on

figure;
bar([P_wtare, N_wtare, R_wtare])
set(gca,'XTickLabel',{'Pitch Tare','Yaw Tare','Roll Tare'})
ylabel('Moment (Nm)')
title('Weight Tare Contributions')
grid on

coeffs = [CL_s, CD_s, CY_s, Cm_s, Cn_s, Cl_s];

figure;
bar(coeffs)
set(gca,'XTickLabel',{'C_L','C_D','C_Y','C_m','C_n','C_l'})
ylabel('Coefficient Value')
title('Final Stability-Axis Aerodynamic Coefficients')
grid on

figure;
bar([(-CL*alpha_upflow), delta_CD_wall, delta_Cm_wall])
set(gca,'XTickLabel',{'Upflow effect on C_D','Wall effect on C_D','Wall effect on C_m'})
ylabel('Correction Magnitude')
title('Magnitude of Applied Aerodynamic Corrections')
grid on

disp('DONE')