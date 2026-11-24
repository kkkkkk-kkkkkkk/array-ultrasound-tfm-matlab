%% main_tfm.m —— 阵列超声 全聚焦成像（TFM）完整链路，一键出图
%  流程：FMC 全矩阵采集 → 逐像素 TFM 全聚焦 → 包络 → 对数压缩 → B 模式图 → 分辨力测量
%
%  只依赖 MATLAB 基础功能（FFT、矩阵运算），不需要 Image Processing / Signal Processing 工具箱。
%  在 MATLAB R2016b 及以上可直接运行。
%
%  使用真实数据：把 make_fmc 那一步换成读你的 FMC 数据
%      data = 你的FMC数据;   % 需要是 nel x nel x ns，对应 发射/接收/采样
%  后面 tfm_beamform 不用改。

clear; clc; close all;
addpath(fileparts(mfilename('fullpath')));

%% 1. 参数
c      = 1540;        % 声速 m/s
f0     = 5e6;         % 中心频率 5 MHz（水中/软组织 λ ≈ 0.308 mm）
fs     = 40e6;        % 采样率 40 MHz
nel    = 64;          % 阵元数
pitch  = 0.154e-3;    % 阵元间距 ≈ λ/2，总孔径 9.7 mm
cycles = 2.5;         % 激励脉冲周数
zmax   = 0.042;       % 最大深度 42 mm
dyn    = 50;          % 对数压缩动态范围 dB

% 体模：5 个点目标（中心轴 10/20/30 mm，±3 mm @ 25 mm）
targets = [ 0.0e-3  10e-3  1.0
            0.0e-3  20e-3  1.0
            0.0e-3  30e-3  1.0
           -3.0e-3  25e-3  1.0
            3.0e-3  25e-3  1.0 ];

%% 2. FMC 全矩阵采集
fprintf('FMC 采集：%d 阵元，%d x %d 条 A-scan ...\n', nel, nel, nel);
tic;
[data, el, t] = make_fmc(c, f0, fs, nel, pitch, cycles, targets, zmax, 320, [0.02 0.06]);
fprintf('  完成，用时 %.1f s，数据 %.1f MB\n', toc, numel(data) * 4 / 1e6);

%% 3. TFM 逐点全聚焦成像
xs = -7e-3 : 0.12e-3 : 7e-3;
zs =  4e-3 : 0.12e-3 : zmax;
fprintf('TFM 成像：%d x %d = %d 像素 ...\n', numel(xs), numel(zs), numel(xs) * numel(zs));
tic;
env = tfm_beamform(data, el, xs, zs, c, fs);
fprintf('  完成，用时 %.1f s\n', toc);

%% 4. 对数压缩 + B 模式图
dbimg = to_db(env, dyn);            % 0~1，1 = 最强

figure('Color', 'w', 'Position', [80 80 620 760]);
imagesc(xs * 1e3, zs * 1e3, dbimg);
colormap(gray); caxis([0 1]);
axis image; set(gca, 'YDir', 'normal', 'FontSize', 11);
xlabel('横向 x (mm)'); ylabel('深度 z (mm)');
title(sprintf('TFM 全聚焦成像 B 模式（%d 阵元，f0 = %.1f MHz，动态范围 %d dB）', nel, f0 / 1e6, dyn));
cb = colorbar; cb.Label.String = 'dB'; cb.Ticks = 0:0.2:1;
cb.TickLabels = arrayfun(@(v) sprintf('%d', round(20 * log10(max(v, 1e-6)))), cb.Ticks, 'UniformOutput', false);
print(gcf, '-dpng', '-r150', 'tfm_bmode_matlab.png');

%% 5. 分辨力测量（-6 dB 宽度）
fprintf('\n== -6 dB 分辨力 ==\n');
for k = 1:size(targets, 1)
    x0 = targets(k, 1); z0 = targets(k, 2);
    [ax, lat] = res_width(env, xs, zs, x0, z0);
    fprintf('  (%5.1f, %5.1f) mm → 轴向 %.2f mm，横向 %.2f mm\n', x0 * 1e3, z0 * 1e3, ax * 1e3, lat * 1e3);
end

%% 6. 与平面波 DAS 三角度复合对比（可选，需同目录有 das_beamform.m）
try
    fprintf('\n== 对照：平面波 DAS 三角度相干复合 ==\n');
    fb = figure('Color', 'w', 'Position', [720 80 620 760]);
    idx = 1;
    comp = 0; n = 0;
    for ang = [-8 0 8]
        tic;
        rf = make_rf(c, f0, fs, nel, pitch, cycles, targets, zmax, 900, [0.04 0.10], ang);
        img = das_beamform(rf, el, xs, zs, c, fs, ang);
        comp = comp + hilbert_env(img);
        n = n + 1;
        subplot(1, 2, idx); imagesc(xs * 1e3, zs * 1e3, to_db(hilbert_env(img), dyn));
        axis image; set(gca, 'YDir', 'normal'); colormap(gray); caxis([0 1]);
        title(sprintf('单角度 %d°', ang)); xlabel('x (mm)'); ylabel('z (mm)');
        idx = idx + 1; fprintf('  角度 %+d° 用时 %.1f s\n', ang, toc);
    end
    compdb = to_db(comp / n, dyn);
    figure('Color', 'w', 'Position', [80 80 620 760]);
    imagesc(xs * 1e3, zs * 1e3, compdb); axis image; set(gca, 'YDir', 'normal');
    colormap(gray); caxis([0 1]); colorbar;
    title('三角度相干复合'); xlabel('x (mm)'); ylabel('z (mm)');
    print(gcf, '-dpng', '-r150', 'das_comp_matlab.png');
catch ME
    fprintf('  （跳过 DAS 对比：%s）\n', ME.message);
end

fprintf('\n全部完成。\n');
