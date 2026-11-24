function env = hilbert_env(img)
%HILBERT_ENV 沿深度方向求解析信号包络（自实现，不依赖 Signal Processing Toolbox）
%   img : [NZ x NX] 实值图像
%   env : 同尺寸包络（线性幅度）

n    = size(img, 1);
nfft = 2^nextpow2(n);

spec = fft(img, nfft, 1);

h = zeros(nfft, 1);
h(1) = 1;
if mod(nfft, 2) == 0
    h(2:nfft/2) = 2;      % 正频率加倍
    h(nfft/2 + 1) = 1;    % 奈奎斯特
else
    h(2:(nfft+1)/2) = 2;
end

env = abs(ifft(spec .* h, [], 1));
env = env(1:n, :);
end
