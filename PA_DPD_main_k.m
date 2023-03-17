%% 
% PA1, 2021-05-27
% 
% PA2, 2021-06-15
% 
% PA3, 2021-10-18
% 
% PA4, 2021-10-22, Add Ripple to ORX
% 
% PB1, 2022-05-11, Add AWGN
% 
% PC1, 2023-02-23, Add flag_Check_Psat
% Initialization

% clear all
% close all
% clc

if 0
    if 1
        fileName = fullfile(pwd,'NRTestModelWaveformGeneration_main_k3.mlx');
    else
        fileName = fullfile(pwd,'MIXER_main_k.mlx');
    end
    run(fileName)
end

if 1
    carrierName
    carrierNameTitle = strrep(carrierName,'_',' ');
end

flag_orx_ripple = 0
flag_orx_impair = 1
flag_pa_awgn = 0
flag_pa_combine = 0
flag_pa_product = '20W'
flag_pa_Nstages = 1
% Power assignment

flag_fullscale = 1
if flag_fullscale
    switch flag_pa_product
        case '4W'
            pwrdBm_In_target = -20 + 2 % input
        case '20W'
            pwrdBm_In_target = 2.5 + 0.5*2 + +0 % input
        case '40W'
            pwrdBm_In_target = 2.5 + 0.5*2 + 3 % input
    end
    x = pwrdB_adj(x, pwrdBm_In_target,'dBm', [], fs, bwInband);
end
% AWGN, 2022-09-26

flag_pa_awgn
if flag_pa_awgn
    try
        x = x_org;
    end
    pwrNoise_dBmHz = -174+20*4

    % noise generator
    noise = noiseGenerator(pwrNoise_dBmHz, Nsamps, fs, []);
    x_org = x;
    x = x+noise;
end
% Signal settings 

condSig.aclr = 1;
condSig.aclr_fs = fs;
condSig.aclr_bwInband = bwInband;
condSig.aclr_foffset = foffset;
condSig.ccdf = 1;
condSig.ccdf_Nsamps = numel(x);
condSig.pwr = 1;
condSig.pwr_fs = fs;
condSig.pwr_bwInband = bwInband;
% PA Model: Memoryless/am2pm/noise ...

flag_pa_Nstages
flag_pa_model = 'Memoryless'
switch flag_pa_model
    case 'Memoryless'
        switch flag_pa_Nstages
            case 1
                switch flag_pa_product
                    case '4W'
                        pa = [];
                        pa.model = "Cubic polynomial"; % model of am/am and am/pm
                        pa.gain_dB = 17.5-3.5*1 + 32.5 + 0; % Input gain_dB
                        pa.am2pm = 0; % Input am/pm
                        pa.oip3_dBm = 30; % Input oip3
                        pa.opsat_W = 4;
                        pa.opsat_dBm = 10*log10(1000*pa.opsat_W);
                        pa.TOISpecification = 'OPsat';
                    case {'20W', '40W'}
                        pa = [];
                        pa.model = "Cubic polynomial"; % model of am/am and am/pm
                        pa.gain_dB = 32; % Input gain_dB
                        pa.am2pm = []; % Input am/pm
                        pa.oip3_dBm = []; % Input oip3pa_cmb_Mstages
                        pa.opsat_W = 20;
                        pa.opsat_dBm = 10*log10(1000*pa.opsat_W);
                        if 1
                            pa.opsat_dBm = pa.opsat_dBm + (0)*(-0.5)
                        end
                        pa.TOISpecification = 'OPsat';
                        if strcmpi(flag_pa_product, '40W')
                            if ~flag_pa_combine
                                error('flag_pa_model.flag_pa_product.pa.opsat_W: check the setting of pa.opsat_W ?!')
                            end
                        end
                end

            case 2
                pa = [];
                pa.model = "Cubic polynomial"; % model of am/am and am/pm
                pa.gain_dB = 17.5-3.5*1; % Input gain_dB
                pa.am2pm = 0; % Input am/pm
                pa.oip3_dBm = 30; % Input oip3
                pa.TOISpecification = 'OIP3';

                pa2 = [];
                pa2.model = "Cubic polynomial"; % model of am/am and am/pm
                pa2.gain_dB = 32.5; % Input gain_dB
                pa2.am2pm = 0; % Input am/pm
                pa2.oip3_dBm = []; % Input oip3
                pa2.opsat_W = 4;
                pa2.opsat_dBm = 10*log10(1000*pa2.opsat_W);
                pa2.TOISpecification = 'OPSat';
        end
end

flag_pa_check_Psat = 1
if flag_pa_check_Psat && flag_pa_Nstages==1
    [PwrdBm_x_avg,~,~,~,PwrdBm_x_peak] = pwrdB(x,[],[],[],'dBm');
    marginDbPsat = pa.opsat_dBm - (PwrdBm_x_peak + pa.gain_dB);
    if marginDbPsat < 0
        disp(['PindBm peak is ',num2str(PwrdBm_x_peak),', marginDb of Psat is ',num2str(marginDbPsat)])
    end
end

% pa ampm
flag_pa_ampm = 1
if flag_pa_ampm
    if 1
        switch flag_pa_product
            case '4W'
                pa_ampm_pwr = [8 12 16 20 24 32 36]
                pa_ampm_shifter = [0 1 2 3.2 5 6 5 ]*2
                %         pa_ampm_shifter = [0 2 3 1.2 2 1 3 ]
                %         pa_ampm_shifter = [0 2 3 1.2 2 1 0 ]
                pa_ampm_pwrIn = pa_ampm_pwr - pa.gain_dB
            case {'20W', '40W'}
                pa_ampm_pwr = [10 15 20 25 30 35 38 40]
                if 1
                    pscale = 1
                    pa_ampm_shifter = [0 1 2 4.5 9 15 19.5 19.5]*pscale;
                    pvar = 1
                    pa_ampm_shifter = [0 1 2 4.5 9 15 19.5 19.5]*1 + pvar*[0 1 -1 1 -1 -1 1 1];
                else
                    pscale = 1
                    pa_ampm_shifter = [0 1 2 3 5 6 5 5]*pscale;
                end
                pa_ampm_pwrIn = pa_ampm_pwr - pa.gain_dB
        end
        if 0
            pa_ampm = [pa_ampm_pwr', pa_ampm_shifter']
        else
            pa_ampm = [pa_ampm_pwrIn', pa_ampm_shifter']
        end
    else
        pa_ampm = [0 2]
        pa_ampm = [2]
    end
else
    pa_ampm = []
end

% pa noise
flag_pa_noise = 1
if flag_pa_noise
    pwrNoisedBmHz = -150
else
    pwrNoisedBmHz = []
end
if 0
    pa2.am2pmDeg = pa_ampm;
    pa2.noisedBmHz = pwrNoisedBmHz;
else
    pa.am2pm = pa_ampm;
    pa.noisedBmHz = pwrNoisedBmHz;
end

flag_pa_flatness = 1
if flag_pa_flatness
    pa_flatdB = -0;
end

% pa combination and phaseShift
flag_pa_combine
if flag_pa_combine
    pa.pa_cmb_Mstages = 2;
    if 0
        pa.pa_cmb_Pshifts = [0, 12]
    else
        pa.pa_cmb_Pshifts = [0, 0]
    end
else
    pa.pa_cmb_Mstages = 0;
end
% PA output

if 0
    if flag_pa_Nstages == 1
        [y, output_paModel] = paModel(x, pa, pa_ampm, pwrNoisedBmHz, 9270, condSig);
    else
        [y, output_paModel] = paModel(x, {pa, pa2}, pa_ampm, pwrNoisedBmHz, 9270, condSig);
    end
else
    pa.fs = fs;
    % generate pa model class
    if flag_pa_Nstages == 2
        pa1cell = {pa, 0, -174, 0};
        pa2cell = {pa2, pa_ampm, pwrNoisedBmHz, pa_flatdB};
        [paCls,paStruct] = powerAmp([pa1cell; pa2cell]);

    elseif flag_pa_Nstages == 1
        [paCls,paStruct] = powerAmp(pa, pa_ampm, pwrNoisedBmHz, pa_flatdB);
    end

    % plot
    Nfft = 4096
    paCls.plt.fnum = 1;
    paCls.plt.flag = 'aclr';
    paCls.plt.fs = fs;
    paCls.plt.bwInband = bwInband;
    paCls.plt.foffset = foffset;
    paCls.plt.Nfft = Nfft;
    if 1
        paCls.plt.legend = ['case ',num2str(pscale)]
        paCls.plt.legend = ['signal CFR ', num2str(cfrdB),'dB']
        paCls.plt.legend = convertStringsToChars(dlnrref)
        paCls.plt.legend = convertStringsToChars(join([dlnrref,'/',bw,'/',scs]))
        paCls.plt.legend = dsipLegend_nco
        paCls.plt.legend = ['PA Psat: ',num2str(round(0.001*10^(pa.opsat_dBm/10),2)), 'W']
        paCls.plt.legend = ['AM/PM, p:', num2str(pscale)]
        paCls.plt.legend = ['AM/PM, pvar:', num2str(pvar)]

    else
        paCls.plt.legend = [flag_pa_product, ', power combine = ',num2str(flag_pa_combine)];
    end
    paCls.plt.title = 'PA, ACLR';
    % output
    y = paCls.pa(x);
end
% am2pm compensation

flag_pa_ampm_comp = 0
if flag_pa_ampm && flag_pa_ampm_comp
    phaseShift = angle(x./y);
    y_pm_compensate = y.*exp(1i*phaseShift);
end
% plot: AM/AM, AM/PM

plt_ampm.Rohm = 1;
plt_ampm.unit = 'dBm';
plt_ampm.xlim = [0, 40]
if flag_pa_Nstages==1
    pa_gaindB = pa.gain_dB
elseif flag_pa_Nstages==2
    pa_gaindB = pa.gain_dB + pa2.gain_dB;
end

if 1
    plt_ampm.type = 'amgain';
    fnum_pa_amgain = [0223 1, 2, 1];
    plt_ampm.xlim = [0, pa.opsat_dBm]
    PLOT_AMPM(x,y,plt_ampm, fnum_pa_amgain, {[paCls.plt.legend, ', PA wo DPD'], 'Gain Compression'});
end

if 1
    plt_ampm.type = 'ampm';
    fnum_pa_ampm = [0223 1, 2, 2];
    PLOT_AMPM(x,y,plt_ampm, fnum_pa_ampm, {[paCls.plt.legend, ', PA wo DPD'], 'AM/PM'});
end

if 0
    plt_ampm.type = 'amam';
    fnum_pa_amam = [0223 1, 3, 2];
    plt_ampm.xlim = [0, 50] - pa_gaindB
    PLOT_AMPM(x,y,plt_ampm, fnum_pa_amam, {[paCls.plt.legend, ', PA wo DPD'], 'AM/AM'});
end
% TEST, PA Memory effect, 2022-09-14

flag_pa_test_PAMemoryEffect = 0
if flag_pa_test_PAMemoryEffect
    dpd = DPD_g(DPM);
    x_Mem = dpd.DPD_poly_memory_matrix(x);
    coef_Mem = x_Mem\y;
    y_Mem_Est = x_Mem*coef_Mem;

    PLOT_ACLR_dB(y_Mem_Est, fs, bwInband, foffset, fnum_pa_aclr, 'y (Estimation)', 4096*1, 'dBm');
    PLOT_ACLR_dB(y_Mem_Est, fs, bwInband, foffset, fnum_pa_aclr, 'y', 4096*1, 'dBm');
    if 0
        ind = 1e6
        ind = numel(y)/2
        coef_Mem_ind = x_Mem(1:ind,:)\y(1:ind);
        y_Mem_Est_ind = x_Mem*coef_Mem_ind;
        PLOT_ACLR_dB(y_Mem_Est_ind, fs, bwInband, foffset, fnum_pa_aclr, 'y Mem. Estimation', 4096*1, 'dBm');
    end
end
% Pwr calculation

method_PwrCal = 'freq'
switch method_PwrCal
    case 'time'
        PdBm_x = 10*log10(mean(abs(x).^2))+30
        PdBm_y = 10*log10(mean(abs(y).^2))+30
    case 'freq'
        PdBm_x = pwrdB(x, fs, bwInband, [], 'dBm')
        PdBm_y = pwrdB(y, fs, bwInband, [], 'dBm')
end
% CCDF

fnum_pa_ccdf = 8310
[PARdB_x, fig] = PLOT_CCDF(x, Nsamps, fnum_pa_ccdf, 'x');
[PARdB_y, fig] = PLOT_CCDF(y, Nsamps, fnum_pa_ccdf, 'y');
% ACLR

fnum_pa_aclr = 8312
if flag_pa_Nstages == 1 || flag_pa_combine
    PLOT_ACLR_dB(x, fs, bwInband, foffset, [fnum_pa_aclr,1,2,1], 'x', 4096*1, 'dBm');
    PLOT_ACLR_dB(y, fs, bwInband, foffset, [fnum_pa_aclr,1,2,2], 'y', 4096*1, 'dBm');
else
    PLOT_ACLR_dB(x, fs, bwInband, foffset, fnum_pa_aclr, 'x', 4096*1, 'dBm');
    PLOT_ACLR_dB(paCls.y(:,1), fs, bwInband, foffset, fnum_pa_aclr, 'y1', 4096*1, 'dBm');
    PLOT_ACLR_dB(y, fs, bwInband, foffset, fnum_pa_aclr, 'y', 4096*1, 'dBm');
end
% Learning parameters, input: dpm: dpd parameters

disp('***more orders get more mathmatic calcuate accuracy of coefficients!****')
pmscale = 3
DPM.order_poly = 3+2*pmscale;
DPM.depth_memory = 1+2*pmscale;
DPM.Niterations = 30*1/1;
DPM.flag_even_order_poly = 1;
DPM.flag_conj = 0;   % Conjugate branch. Currently only set up for MP (lag = 0)
DPM.flag_dc_term = 0; % Adds an additional term for DC
DPM.flag_LS_exclude_zero_second = 0;
if 1
    DPM.modelFit = 'WIN'; % 'GMP'/'HAM'/'WIN'
    % dpm.modelFit = 'HAM' % 'GMP'/'HAM'/'WIN'
else
    dpm.modelFit = 'GMP' % 'GMP'/'HAM'/'WIN'
    DPM.depth_lag = 2;
    DPM.depth_memory_lag = 2;
    DPM.order_poly_lag = 2;
end
if 0
    % dpm.CFR.flag = 1;
    % dpm.CFR.fs = fs;
    % dpm.CFR.bwInband = bwInband;
    % dpm.paprdB_limit = [];
    % dpm.paprdB_limit = 7.5;
end

DPM.evm = bwInband;
if 1
    DPM.learning_arc = 'DLA'; % better!
else
    dpm.learning_arc = 'ILA'; % worse!!
    DPM.learning_rate = 0.8;
    DPM.learning_method = [];
end
DPM.fnum = 0721;

if exist('fnco','var')&&~isempty(fnco)&&numel(fnco)>1
    DPM.flag_Multicarrier = '2C';
elseif exist('bwInband','var')&&~isempty(bwInband)&&numel(bwInband)==4
    DPM.flag_Multicarrier = '2C';
else
    DPM.flag_Multicarrier = '1C';
end
% ORX parameters

DPM.ORX_RippledB = 0;
DPM.ORX_SNRdB = 80;
DPM.ORX_SNRdB = [];

flag_orx_lpf = 0 % Test the ORX LPF to impact the DPD
if flag_orx_lpf
    fcutoff_ORX = 350e6
    ftrans_ORX = 5e6
    b_ORX = firGen([], fs, fcutoff_ORX, ftrans_ORX, 'LPF', 'eqrip', [0.1, 50], [11110]);
    DPM.ORX_LPF = b_ORX;
else
    DPM.ORX_LPF = [];
end
% 2023-03-01, Summary

disp('***Samples of input data will impact the DPD results, more data length results in more accuracy ?!***')
disp(['***Scs of input carrier will impact the DPD results, larger Scs results in good DPD ACLR ?',...
    newline, '-> larger Scs introduces lower Spectrum PSD ?***'])
disp('IBW ?')

% Plot parameters

plt.fs = fs;
plt.bwInband = bwInband;
plt.offset = foffset;
plt.dispTitle = [];
if 1
    plt.legend = paCls.plt.legend
else
    plt.legend = ['case ', num2str(pmscale)]
end
if 0
    plt.title = 'DPD, ACLR vs Coeffs. accuracy'
else
    plt.title = 'DPD, ACLR'
end
plt
% DPD learning

% generate dpd class
dpd = DPD_g(DPM);
if pa_flatdB ~= 0
    dpd.flag_Ipwr_check = 0;
end
if 0
    dpd.flag_aclr_check = 0;
    dpd.flag_Ipwr_check = 0;
else
    dpd.flag_aclr_check = 1;
    dpd.flag_Ipwr_check = 1;
end
if 0
    dpd.flag_aclr_check = {60};
    dpd.flag_Ipwr_check = {36};
else
    dpd.flag_aclr_check = {70};
    dpd.flag_Ipwr_check = 1;
    if 0
        dpd.DPDexpansionDBLimit = {1};
    else
        dpd.DPDexpansionDBLimit = [5];
    end
end

% remove dpd coefficients
dpd.coeffs_PM_history = [];
dpd.coeffs_PM = [];
paCls.plt = []; % remove debug plot

% learning
[yDPD, uDPD, u] = dpd.DPD_learning(x, paCls, plt);

% DPD result by coeff. application

fnum_dpd_ccdf = 031301
fnum_dpd_ccdf_y = 0313010
fnum_dpd_aclr = 031302

if 0
    dispTitle_coeffs = 'DPD, ACLR, dpdCoeffs vs Waveforms'
    dispTitle_ccdf_coeffs = 'dpdCoeffs vs Waveforms'
else
    dispTitle_coeffs = 'DPD, ACLR, dpdCoeffs vs PA Psat'
    dispTitle_ccdf_coeffs = 'dpdCoeffs vs PA Psat'

    dispTitle_coeffs = 'DPD, ACLR, dpdCoeffs vs PA AM/PM var.'
    dispTitle_ccdf_coeffs = 'dpdCoeffs vs PA AM/PM var.'
end
disLegend_coeffs = paCls.plt.legend
paCls.plt = []; % remove debug plot

uDPD_coeffs = dpd.DPD_predistort_transmit(x, dpd.coeffs_PM_history(:,end));
yDPD_coeffs = paCls.pa(uDPD_coeffs);

PLOT_CCDF(uDPD_coeffs, Nsamps, fnum_dpd_ccdf, {['uDPD, ',disLegend_coeffs], dispTitle_ccdf_coeffs});
PLOT_CCDF(yDPD_coeffs, Nsamps, fnum_dpd_ccdf_y, {['yDPD, ',disLegend_coeffs], dispTitle_ccdf_coeffs});
PLOT_ACLR_dB(yDPD_coeffs, fs, bwInband, foffset, fnum_dpd_aclr, {['yDPD, ',disLegend_coeffs], dispTitle_coeffs}, [Nfft], 'dBm');

% DPD result of iteration coeff. vs PAR and ACLR

fnum_dpd_ccdf_y = 030901
fnum_dpd_ccdf_u = 030601
fnum_dpd_aclr = 030602
if 0
    dispTitle = 'Coeffs. accuracy, ACLR'
else
    dispTitle = 'DPD, ACLR'
end

flag_DPDexpansionDBLimit_chk = 1
if flag_DPDexpansionDBLimit_chk
    if ~isempty(dpd.DPDexpanIterations)
        ii = dpd.DPDexpanIterations
        dispLegend_dpdIteration = ['iteration ',num2str(ii)]
    else
        ii = size(dpd.coeffs_PM_history,2);
        dispLegend_dpdIterationEnd = ['iteration ',num2str(ii)]
        dispLegend_dpdIteration = dispLegend_dpdIterationEnd
    end

    if 0
        PLOT_ACLR_dB(x, fs, bwInband, foffset, 0313, {['x'], [dispTitle]}, [], []);
    end
    uDPD_iter = dpd.DPD_predistort_transmit(x, dpd.coeffs_PM_history(:,ii));
    yDPD_iter = paCls.pa(uDPD_iter);

    if 1
        dispLegend_dpdIteration_u = ['uDPD ',dispLegend_dpdIteration]
    end
    if 1
        dispLegend_dpdIteration_y = ['yDPD by coeff. ', dispLegend_dpdIteration]
    end

    if 0
        figure(030301)
        plot(real(x)), hold on
        plot(real(uDPD_iter)), hold on
        figure(030302)
        plot(imag(x)), hold on
        plot(imag(uDPD_iter)), hold on

        PLOT_CCDF(uDPD_iter, Nsamps, fnum_dpd_ccdf_u, dispLegend_dpdIteration_u);
        PLOT_ACLR_dB(yDPD_iter, fs, bwInband, foffset, fnum_dpd_aclr, {dispLegend_dpdIteration_y, dispTitle}, 4096, 'dBm');
    end
end
% DPD result: ACLR

Nfft = 4096;
if 1 % w/o dpd
    PLOT_ACLR_dB(y, fs, bwInband, foffset, fnum_dpd_aclr, {'y', dispTitle}, Nfft, 'dBm');
else
    PLOT_ACLR_dB(paCls.pa(x), fs, bwInband, foffset, fnum_dpd_aclr, {'y', dispTitle}, Nfft, 'dBm');
end

if 1 % w/ dpd
    PLOT_ACLR_dB(paCls.pa(u), fs, bwInband, foffset, fnum_dpd_aclr, {'yDPD by u',dispTitle}, Nfft, 'dBm');
end

if 1 % w/ dpd by coeffs
    PLOT_ACLR_dB(paCls.pa(uDPD), fs, bwInband, foffset, fnum_dpd_aclr, {'yDPD by coeff.',dispTitle}, Nfft, 'dBm');
else
    PLOT_ACLR_dB(yDPD, fs, bwInband, foffset, fnum_dpd_aclr, {'yDPD by coeff. ',dispTitle}, Nfft, 'dBm');
end

% DPD result: CCDF

if 1 % PA input
    [PARdB_x, fig] = PLOT_CCDF(x, Nsamps, fnum_dpd_ccdf, 'x');
    [PARdB_u, fig] = PLOT_CCDF(u, Nsamps, fnum_dpd_ccdf, 'u');
    [PARdB_uDPD, fig] = PLOT_CCDF(uDPD, Nsamps, fnum_dpd_ccdf, ['uDPD ', dispLegend_dpdIterationEnd]);
end
if 1 % PA output
    [PARdB_yu, fig] = PLOT_CCDF(paCls.pa(u), Nsamps, fnum_dpd_ccdf, 'yDPD by u');
    [PARdB_yDPD, fig] = PLOT_CCDF(yDPD, Nsamps, fnum_dpd_ccdf, ['yDPD by coeffs']);
end

PdBm_xDPD = pwrdB(uDPD, fs, bwInband, [], 'dBm')
PdBm_yDPD = pwrdB(yDPD, fs, bwInband, [], 'dBm')
% DPD result: AM/AM, AM/PM

plt_ampm.Rohm = 1;
plt_ampm.unit = 'dBm';
plt_ampm.xlim = [0, pa.opsat_dBm]
if flag_pa_Nstages==1
    pa_gaindB = pa.gain_dB
elseif flag_pa_Nstages==2
    pa_gaindB = pa.gain_dB + pa2.gain_dB;
end
uDPD_Gain = uDPD.*10^(pa_gaindB/20);

if 1
    plt_ampm.type = 'amgain';
    fnum_dpd_amgain = [030701]
    PLOT_AMPM(x, uDPD_Gain, 'amgain', fnum_dpd_amgain, {'PAin+gain', 'Gain Compression'});
    PLOT_AMPM(x, y, plt_ampm, fnum_dpd_amgain, {'PAout wo DPD', 'Gain Compression'});
    PLOT_AMPM(x, yDPD, plt_ampm, fnum_dpd_amgain, {'PAout w/ DPD', 'Gain Compression'});
end

if 1
    plt_ampm.type = 'ampm';
    fnum_dpd_ampm = [030702]
    PLOT_AMPM(x, uDPD_Gain, plt_ampm, fnum_dpd_ampm, {'PAin+gain', 'AM/PM'});
    PLOT_AMPM(x, y, plt_ampm, fnum_dpd_ampm, {'PAout wo DPD', 'AM/PM'});
    PLOT_AMPM(x, yDPD, plt_ampm, fnum_dpd_ampm, {'PAout w/ DPD', 'AM/PM'});
end

if 1
    plt_ampm.type = 'amam';
    fnum_dpd_amam = [030703]
    plt_ampm.xlim = plt_ampm.xlim - pa_gaindB
    PLOT_AMPM(x, uDPD_Gain, plt_ampm, fnum_dpd_amam, {'paIn+gain', 'AM/AM'});
    PLOT_AMPM(x, y, plt_ampm, fnum_dpd_amam, {'paOut wo DPD', 'AM/AM'});
    PLOT_AMPM(x, yDPD, plt_ampm, fnum_dpd_amam, {'paOut w/ DPD', 'AM/AM'});
end

if 0
    uDPD_iter_Gain = uDPD_iter.*10^(pa_gaindB/20);
    PLOT_AMPM(x, uDPD_iter_Gain, 'amgain', fnum_dpd_amgain, {['PAin+gain, ', dispLegend_dpdIteration], 'Gain Compression'});
    PLOT_AMPM(x, yDPD_iter, 'amgain', fnum_dpd_amgain, {['PAout w/ DPD, ', dispLegend_dpdIteration], 'Gain Compression'});

    PLOT_AMPM(x, uDPD_iter_Gain, 'ampm', fnum_dpd_ampm, {['PAin+gain, ', dispLegend_dpdIteration], 'AM/PM'});
    PLOT_AMPM(x, yDPD_iter, 'ampm', fnum_dpd_ampm, {['PAout w/ DPD, ', dispLegend_dpdIteration], 'AM/PM'});

    plt_ampm.type = 'amam';
    fnum_dpd_amam = [030703]
    plt_ampm.xlim = [0, 40] - pa_gaindB
    PLOT_AMPM(x, uDPD_iter_Gain, plt_ampm, fnum_dpd_amam, {['PAin+gain, ', dispLegend_dpdIteration], 'AM/AM'});
    PLOT_AMPM(x, yDPD_iter, plt_ampm, fnum_dpd_amam, {['PAout w/ DPD, ', dispLegend_dpdIteration], 'AM/AM'});
end

% EVM check

flag_evm = 0
try
    signalInput = yDPD_iter;
    rxWaveform = yDPD_coeffs;
    signalInput = yDPD_coeffs;
catch
    signalInput = yDPD;
end
if flag_evm
    if flag_dfe_nco
        x_nco2 = zeros(Nsamps,Ncarriers);
        rxWaveform = x_nco2;
        for k = 1:Ncarriers
            x_nco2(:,k) = signalInput.*exp(-1i*2*pi*fnco(k)*[0:Nsamps-1]'/fs);
            if 1
                x_ch2(:,k) = conv(x_nco2(:,k), b(:), 'same');
            else
                x_ch2(:,k) = conv(x_nco2(:,k), 1, 'same');
            end
            PLOT_FFT_dB(x_ch2(:,k), fs, Nfft, [], 07223, {'NCO','NCO'});
            yyaxis right, PLOT_FFT_dB(b, fs, Nfft, [], 07223, {'NCO','NCO'});
            rxWaveform(:,k) = conv(x_ch2(:,k),b,'same');
        end
    else
        rxWaveform = signalInput;
    end

    if 1
        evm3GPP = false; % |evm3GPP| is disabled for PDCCH EVM measurement.
        targetRNTIs = []; % The example calculates the PDSCH EVM for the RNTIs listed above. To override the default PDSCH RNTIs, specify the |targetRNTIs| vector
        plotEVM = true;
        displayEVM = true;
    end
    cfg = struct();
    cfg.Evm3GPP = evm3GPP;
    cfg.TargetRNTIs = targetRNTIs;
    cfg.PlotEVM = plotEVM;
    cfg.DisplayEVM = displayEVM;
    cfg.Label = dlrefwavegen.ConfiguredModel{1};

    for k =1:Ncarriers
        % Compute and display EVM measurements
        [evmInfo,eqSym,refSym] = hNRDownlinkEVM_k(dlrefwavegen.Config,rxWaveform(:,k),cfg);
        evm_PDCCH_RMS(k) = 100*evmInfo.PDCCH.OverallEVM.RMS
        evm_PDSCH_RMS(k) = 100*evmInfo.PDSCH.OverallEVM.RMS
    end
end