%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Testbench Communication from FreeSoc2 to Matlab
% Version 1.0, Bannwarth, 30.05.2020
%
% Behaviour: 
% - Everytime Matlab writes ‘s’on the UART, the PSoC sends new measurement 
%    results and Matlab writes 'o' if these data is received.
% - The Script terminates after 10 data transfers.
%
% Using:
% 1. Connect FreeSoc2 to USB (i.e. Power Up)
% 2. Check the correct serial Port Settings
% 3. Start this Matlab Script
% 4. Run this Script
% 5. Press the external Push Button to start measuring
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all;
clear all;
clc;

% Connect to PSoC
priorPorts = instrfind;
delete(priorPorts);
PSoC = serial('COM8', 'BaudRate', 115200, 'InputBufferSize', 14000);
fopen(PSoC);

f1 = figure;
count = 1;

flg_data_avai = 0;
fwrite(PSoC, 's', 'uchar'); % means send, I am ready to receive
while(flg_data_avai == 0)
   if PSoC.BytesAvailable >= 2048
       fwrite(PSoC, 'o', 'uchar'); % means I received all expected data
       rx_data_adc = fread(PSoC, 1024, 'uint16');
       fprintf(" Transfer %i DONE \n", count);
       
       % Plotting the received data
       figure(f1)
       subplot(2, 1, 1)
       plot([0:(length(rx_data_adc)-1)], rx_data_adc(1:(length(rx_data_adc))));
       title(['Received Time Domain Data No.:', num2str(count)]);
       subplot(2, 1, 2)
       plot([0:1023], 1/length(rx_data_adc) * 20 * log10(abs(fft(rx_data_adc))));
       title('FFT -  Matlab');

       % Save the received data
       save(strcat('CW_rx_data_adc_', int2str(count), '.mat'), 'rx_data_adc');

       %% Spectral Representation of the Test Signal
       N = 1024;   % Sample Size
       x = rx_data_adc;
       
       % Spectral computation
       figure(2) % plot the spectra
       dft = fft(x);
       freq = (0:N-1)*(9600/N); % Frequency axis
       plot(freq, abs(dft));
       title('Spectral Representation of the Test Signal');
       xlabel('Frequency (Hz)');
       ylabel('Magnitude');

       %% CFAR implementation
       % CA CFAR Parameters
       NG = 1;     % Number of Guard Cells
       NR = 10;    % Number of Reference Cells
       PFA = 10^-6; % Probability of False Alarm
       
       % CFAR Detection
       detection = zeros(1, N);
       for i = NG + NR + 1 : N - (NG + NR)
           referenceWindow = x(i - NR - NG : i - NG - 1);
           Navg = mean(referenceWindow);
           threshold = Navg * (PFA^(-1/NR) - 1);
           
           if x(i) > threshold
               detection(i) = 1;
           end
       end
       
       % Plotting
       figure(3);
       subplot(2, 1, 1);
       plot(0:N-1, x, 'b');
       hold on;
       plot(0:N-1, detection * max(x), 'r', 'LineWidth', 1.5);
       xlabel('Sample');
       ylabel('Amplitude');
       title('CFAR Detection');
       legend('Signal', 'Detection');
       
       subplot(2, 1, 2);
       plot(0:N-1, x, 'g');
       xlabel('Sample');
       ylabel('Amplitude');
       title('Raw ADC Data');
       
       count = count + 1;
   end
   
   if count == 11
       break;
   end
   
   fwrite(PSoC, 's', 'uchar'); % means send, I am ready to receive
end

fclose(PSoC);

fprintf("Script End \n");

% Investigate best N, NG, and NR
% Here you can manually try different values of N, NG, and NR and observe
% the results to determine the best performance. Document your observations
% for the best values.