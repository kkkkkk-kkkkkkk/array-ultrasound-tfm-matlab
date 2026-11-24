# Array Ultrasound — Total Focusing Method (TFM) in MATLAB

Full imaging chain in plain MATLAB (no toolboxes required): **synthetic FMC acquisition → per-pixel Total Focusing Method beamforming → analytic-signal envelope → log compression → B-mode image → −6 dB resolution measurement**.

`main_tfm.m` runs everything in one click and saves `tfm_bmode_matlab.png`. Everything else is a small, individually readable function.

| File | What it does |
|---|---|
| `main_tfm.m` | one-click script: parameters → phantom → FMC → TFM → figure → resolution printout |
| `make_fmc.m` | forward-synthesises full-matrix-capture data (`nel × nel × ns`) |
| `tfm_beamform.m` | TFM core: two-way travel time per pixel + linear interpolation + coherent sum over all transmit–receive pairs |
| `hilbert_env.m` | FFT-based analytic signal envelope, self-implemented |
| `to_db.m` | log compression to [0,1], 50 dB dynamic range by default |
| `res_width.m` | −6 dB axial / lateral resolution measurement |

Demo parameters: 64-element linear array, f0 = 5 MHz, fs = 40 MHz, c = 1540 m/s, pitch = 154 µm (9.7 mm aperture), grid step 0.12 mm, 5 point targets.

## Measured results (not estimates)

| Target (x, z) mm | Imaged peak (mm) | Axial −6 dB | Lateral −6 dB |
|---|---|---|---|
| (0, 10) | (−0.04, 10.00) | 0.24 mm | 0.60 mm |
| (0, 20) | (−0.04, 20.08) | 0.24 mm | 1.08 mm |
| (0, 30) | (−0.04, 29.92) | 0.24 mm | 1.56 mm |
| (−3, 25) | (−3.04, 25.00) | 0.24 mm | 0.84 mm |
| (+3, 25) | (+2.96, 25.00) | 0.24 mm | 0.84 mm |

Peak-position error ≤ 0.08 mm, i.e. below one grid step (0.12 mm). Axial resolution is sampling-limited at 0.24 mm; lateral width widens with depth as expected from a fixed aperture. `tfm_bmode.png` is the rendered output.

## Plugging in real data

Only the acquisition step changes; the beamformer stays identical:

```matlab
% FMC data: nel(transmit) x nel(receive) x ns(samples), volts, DC removed
data = your_fmc;
el   = (0:nel-1)' * pitch;         % element positions in metres
c    = 5900;                        % steel 5900 / aluminium 6300 / water-tissue 1540
xs   = -7e-3 : 0.1e-3 : 7e-3;
zs   =  4e-3 : 0.1e-3 : zmax;
env  = tfm_beamform(data, el, xs, zs, c, fs);
imagesc(xs*1e3, zs*1e3, to_db(env, 50)); colormap(gray); axis image;
```

Three things that bite people: (1) keep element coordinates, sound speed and sampling rate in the same units (metres and seconds); (2) feed raw RF, not an envelope — `hilbert_env` handles that; (3) keep the grid step at λ/4 or finer, finer than that only costs time.

## 中文说明

本仓库是阵列超声 **全聚焦成像（TFM）** 的完整 MATLAB 实现：合成 FMC 全矩阵数据 → 逐像素双程延时叠加（TFM）→ 解析信号包络 → 对数压缩 → B 模式图 → −6 dB 分辨力。只依赖 MATLAB 基础功能（FFT、矩阵运算），**不需要 Signal Processing / Image Processing 工具箱**，R2016b 以上直接运行。运行 `main_tfm` 一键出图并打印指标。

改用真实数据只需把 `make_fmc` 一行换掉，`tfm_beamform` 不用改（示例见上文）。附带的 `main_us_array.m` / `make_rf.m` / `das_beamform.m` 提供平面波 DAS 三角度相干复合的对照结果。

如需把自适应加权（相干因子 CF、幅度相干 ACF）加进来压旁瓣、或做扇形/凸阵坐标映射、批量目录处理，可直接在 `tfm_beamform` 的累加环节扩展。

---
Maintained by [kkkkkk-kkkkkkk](https://github.com/kkkkkk-kkkkkkk).
