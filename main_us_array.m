%% main_us_array.m —— 阵列超声成像（线阵 + 平面波发射 + 延时叠加波束合成）
% 一键运行：生成点目标与散斑仿真体模，做单角度与三角度复合成像，输出 B 模式图
% 作者：TEATEA   运行环境：MATLAB R2018b 及以上

clear; clc; close all;

%% 1. 系统参数
P.C     = 1540;            % 声速 m/s
P.F0    = 5e6;             % 中心频率 5 MHz
P.FS    = 40e6;            % 采样率 40 MHz
P.NE    = 64;              % 阵元数
P.LAM   = P.C / P.F0;      % 波长 0.308 mm
P.PITCH = P.LAM / 2;       % 阵元间距 λ/2
P.XE    = ((0:P.NE-1) - (P.NE-1)/2) * P.PITCH;   % 阵元坐标
P.XMIN  = -7e-3; P.XMAX = 7e-3;                  % 成像视野
P.ZMIN  =  4e-3; P.ZMAX = 42e-3;
P.NX    = 220;   P.NZ   = 300;

%% 2. 体模：5 个点目标 + 900 个散斑
pts = [ 0e-3  10e-3  1.0;
        0e-3  20e-3  1.0;
        0e-3  30e-3  1.0;
       -3e-3  25e-3  0.7;
        3e-3  25e-3  0.7];
rng(7);
nsp = 900;
spk = [ P.XMIN + (P.XMAX-P.XMIN)*rand(nsp,1), ...
        P.ZMIN + (P.ZMAX-P.ZMIN)*rand(nsp,1), ...
        0.04 + 0.06*rand(nsp,1) ];
scat = [pts; spk];

%% 3. 三个角度成像
ang = [-8 0 8];
img = cell(1, numel(ang));
for k = 1:numel(ang)
    rf = make_rf(scat, ang(k), P);
    img{k} = das_beamform(rf, ang(k), P);
    fprintf('角度 %+d 度完成，RF 尺寸 %d x %d\n', ang(k), size(rf,1), size(rf,2));
end

% 复合（相干平均）
cmp = (img{1} + img{2} + img{3}) / 3;

%% 4. 包络 + 对数压缩（50 dB 动态范围）
env1 = hilbert_env(img{2});      d1 = to_db(env1, 50);
envc = hilbert_env(cmp);         dc = to_db(envc, 50);

%% 5. 成像质量指标（-6 dB 分辨力）
x = linspace(P.XMIN, P.XMAX, P.NX);
z = linspace(P.ZMIN, P.ZMAX, P.NZ);
for pz = [10 20 30]*1e-3
    [ax, lat]   = res_width(env1, x, z, 0, pz);
    [axc, latc] = res_width(envc, x, z, 0, pz);
    fprintf('深度 %2.0f mm：单角度 轴向 %.2f / 横向 %.2f mm；复合 轴向 %.2f / 横向 %.2f mm\n', ...
            pz*1e3, ax, lat, axc, latc);
end

%% 6. 显示
figure('Color','w','Position',[80 80 900 520]);
subplot(1,2,1); imagesc(x*1e3, z*1e3, d1); colormap(gray); caxis([0 1]);
axis image; title('单角度平面波（0 度）'); xlabel('横向 (mm)'); ylabel('深度 (mm)');
subplot(1,2,2); imagesc(x*1e3, z*1e3, dc); colormap(gray); caxis([0 1]);
axis image; title('三角度复合（-8/0/+8 度）'); xlabel('横向 (mm)'); ylabel('深度 (mm)');
print(gcf, '-dpng', '-r150', 'bmode_matlab.png');
fprintf('已输出 bmode_matlab.png\n');
