function d = to_db(env, dr)
%TO_DB 对数压缩到 [0,1]：以最大值为 0 dB，动态范围 dr（dB）
%   env : 包络幅度
%   dr  : 动态范围，默认 50 dB
%   d   : [0,1] 灰度矩阵（0 = 最暗，1 = 最强）

if nargin < 2, dr = 50; end

e = env / max(env(:));
d = 20 * log10(e + 1e-12) + dr;    % 归一到 [0, dr]
d = max(min(d, dr), 0) / dr;
end
