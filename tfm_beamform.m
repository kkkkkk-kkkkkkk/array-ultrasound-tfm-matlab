function img = tfm_beamform(data, el, xs, zs, c, fs)
% TFM_BEAMFORM  全聚焦成像（Total Focusing Method）
%   对成像网格上每个像素 P(x,z)，把全矩阵数据里每一对 (发射 i, 接收 j)
%   A-scan 在双程时刻
%       tau(i,j,P) = ( |P - Xi| + |P - Xj| ) / c
%   处取包络值并相干累加：
%       I(x,z) = sum_i sum_j A_ij( tau(i,j,P) )
%   最后按收发对数 (nel^2) 归一。
%
%   这就是 TFM 的"逐点聚焦"：任意一个像素都用了全部 64x64 个收发组合的信号，
%   等效合成孔径 = 阵元总孔径，因此横向分辨率优于单一平面波发射的 DAS。
%
%   输入：
%     data  nel x nel x ns   全矩阵数据
%     el    1 x nel          阵元横向坐标 m
%     xs, zs                 成像网格（m，1-D）
%     c     声速 m/s
%     fs    采样率 Hz
%   输出：
%     img   numel(zs) x numel(xs) 复包络幅度（未做对数压缩）

[nel, ~, ns] = size(data);
[X, Z] = meshgrid(xs(:).', zs(:));          % nz x nx
I = zeros(size(X));

for i = 1:nel
    di = sqrt((X - el(i)).^2 + Z.^2);
    for j = 1:nel
        dj = sqrt((X - el(j)).^2 + Z.^2);
        idx = (di + dj) / c * fs;                       % 采样点索引
        idx = min(max(idx, 1), ns - 1.001);
        i0 = floor(idx);
        frac = idx - i0;
        a0 = double(data(i, j, i0(:)));
        a1 = double(data(i, j, i0(:) + 1));
        a0 = reshape(a0, size(X));
        a1 = reshape(a1, size(X));
        I = I + a0 .* (1 - frac) + a1 .* frac;          % 线性插值
    end
end

img = hilbert_env(I.') .';        % 每行做解析信号，取包络（横/纵都做一次希尔伯特）
img = img / (nel * nel);          % 按收发对数归一
end
