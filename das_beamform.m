function img = das_beamform(rf, angle_deg, P)
%DAS_BEAMFORM 延时叠加（Delay-and-Sum）波束合成
%   rf        : [采样点 x 阵元] 射频数据
%   angle_deg : 发射平面波角度
%   P         : 参数结构体
%   img       : [P.NZ x P.NX] 复值（实）射频图像

th = deg2rad(angle_deg);
x  = linspace(P.XMIN, P.XMAX, P.NX);
z  = linspace(P.ZMIN, P.ZMAX, P.NZ);
[Xg, Zg] = meshgrid(x, z);            % [NZ x NX]

img = zeros(P.NZ, P.NX);
dt  = 1 / P.FS;
ns  = size(rf, 1);

for n = 1:P.NE
    % 像素到发射波前 + 像素到接收阵元的总传播时间
    d_tx = Zg * cos(th) + Xg * sin(th);
    d_rx = sqrt((Xg - P.XE(n)).^2 + Zg.^2);
    tau  = (d_tx + d_rx) / P.C;

    idx  = tau / dt;
    i0   = floor(idx);
    fr   = idx - i0;
    i0   = min(max(i0, 0), ns - 2);     % 越界钳位，避免索引非法

    col  = rf(:, n);
    % 线性插值取采样值
    s = col(i0 + 1) .* (1 - fr) + col(i0 + 2) .* fr;
    img = img + s;
end

img = img / P.NE;    % 按阵元数归一，保持幅度可比
end
