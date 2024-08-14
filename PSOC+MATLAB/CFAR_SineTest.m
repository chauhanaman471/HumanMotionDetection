clear all; % Clear all variables from the workspace
close all; % Close all figures
clc;       % Clear the command window

% CA-CFAR Parameters
N = 512;   % Total number of samples
NG = 1;    % Number of guard cells
NR = 10;   % Number of reference cells
PFA = 10^-6; % Desired probability of false alarm

%%%
% Test Data Generation
%%%

% Sine wave parameters
A0 = 1;               % Amplitude of the sine wave
fs = 256;             % Sampling frequency
ks1 = 20.0;           % Frequency index
phase1 = -pi/4;       % Phase of the sine wave

f1 = fs/N*ks1;        % Calculate the sine wave frequency

% Generate sampled sine wave
n = 0:(N-1);          % Sample indices
x = A0*cos(2*pi*f1/fs*n + phase1); % Sine wave signal

% Add noise to the sine wave
A0eff = A0/sqrt(2);   % Effective amplitude for noise
noise = A0eff*randn(N, 1); % Generate white Gaussian noise

% Signal with added noise
xnoise = x + noise';  % Combine signal and noise

% Plot the sine wave with noise
figure(1)
plot(n, xnoise, 'b');  % Plot noisy sine wave
hold on
plot(n, x, 'r', 'LineWidth', 1.5); % Plot original sine wave
xlabel('Sample Number')
ylabel('Amplitude')
title('Sampled Sinewave with AWGN');
legend('Sine + Noise', 'Sine')

% Compute the FFT of the noisy signal
xnoise_fft = fft(xnoise)/N; % FFT of the noisy signal and normalize
x_fft = fft(x)/N;           % FFT of the original sine wave and normalize

% Convert to single-sided spectrum
x_fft = abs(x_fft(1:N/2+1));           % Single-sided FFT of original sine wave
x_fft(2:end-1) = 2*x_fft(2:end-1);     % Adjust magnitude
xnoise_fft = abs(xnoise_fft(1:N/2+1)); % Single-sided FFT of noisy signal
xnoise_fft(2:end-1) = 2*xnoise_fft(2:end-1); % Adjust magnitude

% Compute the power spectrum
x_fft_power = x_fft.^2;           % Power spectrum of original sine wave
xnoise_fft_power = xnoise_fft.^2; % Power spectrum of noisy signal

% Frequency vector for single-sided spectrum
freq = (0:(N/2)) * (fs/N); % Frequency bins

% Plot FFT of the noisy sine wave
figure(2)
plot(freq, xnoise_fft, 'b'); % Plot FFT of noisy signal
hold on
plot(freq, x_fft, 'r', 'LineWidth', 1.5); % Plot FFT of original sine wave
xlabel('Frequency (Hz)')
ylabel('Magnitude')
title('Single-Sided FFT of Sinewave with AWGN');
legend('FFT Sine + Noise', 'FFT Sine')

% CA-CFAR Parameters
alpha = (NR + 2 * NG + 1) * (PFA^(-1/(NR + 2 * NG + 1)) - 1); % CFAR scaling factor
threshold = zeros(1, N/2+1);    % Initialize threshold array
cfar_output = zeros(1, N/2+1);  % Initialize CFAR output array

% Compute the CFAR threshold and detection
for i = (NR + NG + 2):(N/2+1 - NR - NG)
    % Define the reference window (excluding the guard cells and CUT)
    reference_window = [xnoise_fft_power(i-NR-NG:i-NG-1) xnoise_fft_power(i+NG+1:i+NG+NR)];
    
    % Calculate the average noise power level
    noise_level = mean(reference_window);
    
    % Calculate the threshold
    threshold(i) = alpha * noise_level;
    
    % Compare the CUT with the threshold
    if xnoise_fft_power(i) > threshold(i)
        cfar_output(i) = xnoise_fft_power(i); % Mark as detected target
    end
end

% Plot the power spectrum with CA-CFAR threshold and detected targets
figure(3)
plot(freq, 10*log10(xnoise_fft_power), 'b'); % Power spectrum in dB
hold on
plot(freq, 10*log10(x_fft_power), 'r'); % Original sine spectrum in dB
plot(freq, 10*log10(threshold), 'g', 'LineWidth', 1.5); % CFAR threshold in dB
plot(freq, 10*log10(cfar_output), 'ro', 'MarkerSize', 5); % Detected targets in dB

xlabel('Frequency (Hz)')
ylabel('Power (dB)')
title('Single-Sided Power Spectrum with CA-CFAR Detection')
legend('FFT Sine + Noise', 'FFT Sine', 'Threshold', 'Detected Targets')

% Display the number of detected targets
num_targets = sum(cfar_output > 0);
fprintf('Number of targets detected: %d\n', num_targets);
