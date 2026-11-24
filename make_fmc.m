function [data, el, t] = make_fmc(c, f0, fs, nel, pitch, cycles, targets, zmax, speckleN, speckleAmp)
% MAKE_FMC  全矩阵捕获（Full Matrix Capture）数据合成
%   阵元逐个发射球面波，全阵元并行接收，得到 nel x nel x ns 的三维全矩阵数据。
%
%   data(i, j, :)  = 第 i 个阵元发射、第 j 个阵元接收的 A-scan
%
%   输入（均为可选，默认值见 main_tfm.m 调用处）：
%     c        声速 m/s         f0 中心频率 Hz      fs 采样率 Hz
%     nel      阵元数           pitch 阵元间距 m    cycles 脉冲周数
%     targets  Nx3 点散射体 [x(m) z(m) 幅度]
%     zmax     最大成像深度 m
%     speckleN 散斑数量         speckleAmp [min max] 散斑幅度范围
%
%   输出：
%     data  nel x nel x ns single
%     el    1 x nel 阵元横向坐标 m
%     t     1 x ns 时间轴 s

if nargin < 4,  nel = 64;            end
if nargin < 5,  pitch = 0.154e-3;    end
if nargin < 6,  cycles = 2.5;        end
if nargin < 8,  zmax = 0.042;        end
if nargin < 9,  speckleN = 320;      end
if nargin < 10, speckleAmp = [0.02 0.06]; end

el = ((0:nel-1) - (nel-1)/2) * pitch;            % 阵元位置
tmax = 2 * zmax / c;
ns = floor(fs * tmax);
t = (0:ns-1) / fs;

% ---- 散射体集合：点目标 + 随机散斑 ----
sc = targets;                                     % [x z amp]
if speckleN > 0
    rng(11);
    sx = -7e-3 + 14e-3 * rand(speckleN, 1);
    sz = 4e-3 + (zmax - 4e-3) * rand(speckleN, 1);
    sa = speckleAmp(1) + (speckleAmp(2) - speckleAmp(1)) * rand(speckleN, 1);
    sc = [sc; sx sz sa];
end

sigma = cycles / (2 * f0) * 0.55;
d = zeros(nel, size(sc, 1));
for k = 1:size(sc, 1)
    d(:, k) = sqrt((el - sc(k, 1)).^2 + sc(k, 2)^2);   % 阵元到散射体距离
end

data = zeros(nel, nel, ns, 'single');
for i = 1:nel
    tij = (d(i, :) + d) / c;                          % nel x K 到达时刻
    for j = 1:nel
        acc = zeros(1, ns);
        for k = 1:size(sc, 1)
            tau = t - tij(j, k);
            acc = acc + sc(k, 3) * exp(-(tau.^2) / (2 * sigma^2)) .* cos(2 * pi * f0 * tau);
        end
        data(i, j, :) = single(acc + 0.004 * randn(1, ns));
    end
end
end
