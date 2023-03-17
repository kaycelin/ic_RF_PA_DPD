# DSP of RF PA and DPD

## Summary of simulation
- Summary_PA vs DPD.md
- Summary_DPD coefs. applied vs Waveform.md
- Summary_DPD coefs. applied vs PA.md

## Main: PA_DPD_main
  - Initialization
  ```js
  flag_orx_ripple = 0   
  flag_orx_impair = 1   
  flag_pa_awgn = 0    
  flag_pa_combine = 0   
  flag_pa_product = '20W'   
  flag_pa_Nstages = 1   
  ```
  - Power assignment
  ```js
  pwrdBm_In_target = 3.5
  ```
  - AWGN
  ```js
  pwrNoise_dBmHz = -174
  ```
  - Signal settings
  ```js
  condSig.aclr = 1;   
  condSig.aclr_fs = fs;   
  condSig.aclr_bwInband = bwInband;   
  condSig.aclr_foffset = foffset;   
  condSig.ccdf = 1;   
  condSig.ccdf_Nsamps = numel(x);   
  condSig.pwr = 1;    
  condSig.pwr_fs = fs;    
  condSig.pwr_bwInband = bwInband;    
  ```
  - PA Model: Memoryless/am2pm/noise ...
  ```js
  % pa model
  pa.model = "Cubic polynomial"; % model of am/am and am/pm   
  pa.gain_dB = 32; % Input gain_dB   
  pa.am2pm = []; % Input am/pm   
  pa.oip3_dBm = []; % Input oip3    
  pa.opsat_W = 20;   
  pa.opsat_dBm = 10*log10(1000*pa.opsat_W);   
  pa.TOISpecification = 'OPsat';   
  
  % pa ampm
  pa_ampm_pwr = [10 15 20 25 30 35 38 40]   
  pa_ampm_shifter = [0 1 2 4.5 9 15 19.5 19.5]   
  pa_ampm_pwrIn = pa_ampm_pwr - pa.gain_dB     
  
  % pa noise
  pwrNoisedBmHz = -150
  
  % pa combination and phaseShift
  pa.pa_cmb_Mstages = 2;
  pa.pa_cmb_Pshifts = [0, 0]
  ``` 
  - PA output
    * generate pa model class 
  
  > paCls = 

    powerAmp with properties:

                   Method: 'paModel'
                 pa_model: "Cubic polynomial"
               pa_gain_dB: 32
             pa_am2pm_deg: 0
      pa_TOISpecification: "OPsat"
              pa_iip3_dBm: Inf
              pa_oip3_dBm: Inf
             pa_ip1dB_dBm: Inf
             pa_op1dB_dBm: Inf
             pa_ipsat_dBm: Inf
             pa_opsat_dBm: 43.0102999566398
    pa_PowerLowerLimit_In: -30
    pa_PowerUpperLimit_In: Inf
            pa_Table_cell: {[0]}
               pa_opsat_W: 20
                am2pm_deg: {[8×2 double]}
              noise_dBmHz: -150
                  flat_dB: 0
                        x: []
                        y: []
                   pwrdBm: []
                       fs: 1966080000
                  Nstages: 1
                 lna_NFdB: NaN
                 flag_lna: 'pa'
                      plt: [1×1 struct]
           pa_cmb_Mstages: 0
           pa_cmb_Pshifts: 0
           
   * plot settings    
  ```js
  paCls.plt.fnum = 1;
  paCls.plt.flag = 'aclr';
  paCls.plt.fs = fs;
  paCls.plt.bwInband = bwInband;
  paCls.plt.foffset = foffset;
  paCls.plt.Nfft = Nfft;
  paCls.plt.legend = '20W, power combine = 0'
  ```
  
  * output    
  <img src="https://user-images.githubusercontent.com/87049112/225830729-50d54980-6fb4-46db-8834-856a6134a524.png" width="50%">

  - Plot: AM/AM, AM/PM
  ```js
  plt_ampm.Rohm = 1;
  plt_ampm.unit = 'dBm';
  plt_ampm.xlim = [0, 40]
  plt_ampm.type = 'amgain';
  ```
  <img src="https://user-images.githubusercontent.com/87049112/225848941-939fee52-c0e7-44bf-bda2-ac6ec90f0fb2.png" width="50%">
  <img src="https://user-images.githubusercontent.com/87049112/225849157-c2a7014d-1f64-4df1-9e86-dc35db41a997.png" width="50%">
  <img src="https://user-images.githubusercontent.com/87049112/225849347-049df3ac-a4b4-4efa-ba94-a4e78c2177b3.png" width="50%">

  - CCDF
  <img src="https://user-images.githubusercontent.com/87049112/225835327-2ef61b33-454f-41f9-8b70-f09290c1c3dc.png" width="50%">

  - ACLR

  - Learning parameters, input: dpm: dpd parameters
  ```js
  DPM.order_poly = 9;
  DPM.depth_memory = 7;
  DPM.Niterations = 30;
  DPM.flag_even_order_poly = 1;
  DPM.flag_conj = 0;   % Conjugate branch. Currently only set up for MP (lag = 0)
  DPM.flag_dc_term = 0; % Adds an additional term for DC
  DPM.flag_LS_exclude_zero_second = 0;
  DPM.modelFit = 'WIN'; % 'GMP'/'HAM'/'WIN'
  DPM.evm = bwInband;
  DPM.learning_arc = 'DLA'; % better!
  DPM.fnum = 0721;
  DPM.flag_Multicarrier = '2C';
  ```
  - ORX parameters
  ```js
  DPM.ORX_RippledB = 0;
  DPM.ORX_SNRdB = 80;
  DPM.ORX_SNRdB = [];
  ```
  - Plot parameters
  ```js
  plt.fs = fs;
  plt.bwInband = bwInband;
  plt.offset = foffset;
  plt.dispTitle = [];
  plt.legend = paCls.plt.legend
  plt.title = 'DPD, ACLR'
  ```
  - DPD learning
    * generate dpd class
    > DPD_g with properties:
      ```
                     order_poly: 9
                   depth_memory: 7
                 order_poly_lag: 0
               depth_memory_lag: 0
                      depth_lag: 0
                    Niterations: 30
           flag_even_order_poly: 1
                      flag_conj: 0
                   flag_dc_term: 0
                   learning_arc: 'DLA'
                  learning_rate: []
                learning_method: []
    flag_LS_exclude_zero_second: 0
                       modelFit: 'WIN'
              flag_Multicarrier: '2C'
                     ORX_FlatdB: 0
                      ORX_SNRdB: []
                        ORX_LPF: []
                            CFR: []
                   paprdB_limit: []
                           fnum: []
                      coeffs_PM: [63×1 double]
                        Ncoeffs: 63
              coeffs_PM_history: []
                         paprdB: []
            sigOut_u_predistort: []
                 sigOut_y_paout: []
                            evm: [-249140000 … ]
                      ACLRdBcal: []
                         NMSEdB: []
                   ACLRdBmargin: -1
                   IpwrdBerrCal: []
                flag_Ipwr_check: 1
                flag_aclr_check: {[70]}
            DPDexpansionDBLimit: 5
             DPDexpanIterations: []
      ```
  - DPD result: ACLR
  <img src="https://user-images.githubusercontent.com/87049112/225843004-8645a179-cb8b-45b8-8863-294724daa6e5.png" width="50%">

  - DPD result: CCDF
  <img src="https://user-images.githubusercontent.com/87049112/225843679-ecea522d-abd3-42c8-a383-d16ed58199d8.png" width="50%">

  - DPD result: AM/AM, AM/PM
  <img src="https://user-images.githubusercontent.com/87049112/225846564-fc68e822-0272-48a0-85d8-3698ff13bc7c.png" width="50%">
  <img src="https://user-images.githubusercontent.com/87049112/225846702-5fdf8237-f6ae-4f9e-b430-dee3f0a30e3e.png" width="50%">
  <img src="https://user-images.githubusercontent.com/87049112/225849780-fe4a9ff3-b445-4fbe-b173-d454c0833e28.png" width="50%">
