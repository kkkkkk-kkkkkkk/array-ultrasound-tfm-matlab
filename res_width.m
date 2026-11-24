function [axial_mm, lateral_mm] = res_width(env, x, z, px, pz)
%RES_WIDTH 点目标 -6 dB 分辨力（轴向 / 横向，单位 mm）
%   env : 包络矩阵 [NZ x NX]
%   x,z : 网格坐标向量（m）
%   px,pz : 目标位置（m）

kx = find(abs(x - px) == min(abs(x - px)), 1);
kz = find(abs(z - pz) == min(abs(z - pz)), 1);

e = env / max(env(:));
half = 0.5;    % -6 dB 即半幅

% 轴向剖面
a1 = max(1, kz - 15); a2 = min(numel(z), kz + 15);
pa = e(a1:a2, kx);
idx = find(pa >= half);
if isempty(idx)
    axial_mm = 0;
else
    axial_mm = (idx(end) - idx(1)) * (z(2) - z(1)) * 1e3;
end

% 横向剖面
b1 = max(1, kx - 15); b2 = min(numel(x), kx + 15);
pb = e(kz, b1:b2);
idx = find(pb >= half);
if isempty(idx)
    lateral_mm = 0;
else
    lateral_mm = (idx(end) - idx(1)) * (x(2) - x(1)) * 1e3;
end
end
