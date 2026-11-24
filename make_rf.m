function rf = make_rf(scat, angle_deg, P)
%MAKE_RF 平面波发射、全阵元接收的射频通道数据合成
%   scat      : N x 3，每行 [x, z, 幅值]，单位 m
%   angle_deg : 平面波发射倾角（度），0 为垂直发射
%   P         : 参数结构体（见 main_us_array.m）
%   rf        : [采样点 x 阵元] 的射频数据

th    = deg2rad(angle_deg);
t_max = 2 * P.ZMAX / P.C + 4 / P.F0;
ns    = ceil(t_max * P.FS) + 40;
t     = (0:ns-1).' / P.FS;

rf = zeros(ns, P.NE);
for k = 1:size(scat, 1)
    x0 = scat(k,1); z0 = scat(k,2); a = scat(k,3);
    % 发射波前到达散射体的时间（倾斜平面波 = z*cosθ + x*sinθ）
    t_tx = (z0 * cos(th) + x0 * sin(th)) / P.C;
    % 各阵元接收传播时间
    t_rx = sqrt((P.XE - x0).^2 + z0^2) / P.C;
    for n = 1:P.NE
        tau = t_tx + t_rx(n);
        env = exp(-((t - tau).^2) / (2 * (0.6 / P.F0).^2));   % 高斯包络（约 2.5 周期）
        rf(:, n) = rf(:, n) + a * env .* cos(2 * pi * P.F0 * (t - tau));
    end
end

% 接收噪声（相对最大幅值 2%）
rf = rf + 0.02 * randn(size(rf)) * max(abs(rf(:)));
end
