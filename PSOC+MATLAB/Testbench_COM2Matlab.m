close all;
clear all;
clc;

% Define the number of bytes to be received for ADC and FFT data
ADC_bytes = 1024 * 2;    % 1024 samples, 2 bytes per sample
FFT_Bytes = 2048 * 4;    % 2048 samples (real and imaginary), 4 bytes per sample

% Clean up any prior ports and set up the serial port
priorPorts = instrfind;
delete(priorPorts);
PSoC = serial('COM8', 'BaudRate', 115200, 'InputBufferSize', 40480);
fopen(PSoC);

% Initialize figures and counters
f1 = figure;
count = 1;
flg_data_avai = 0;

% Send initial ready signal to PSoC
fwrite(PSoC, 's', 'uchar'); % means send, I am ready to receive

while (flg_data_avai == 0)
    % Check if the required amount of data is available
    if PSoC.BytesAvailable >= ADC_bytes + FFT_Bytes
        fwrite(PSoC, 'o', 'uchar'); % means I received all expected data
        
        % Read ADC data and FFT data from the serial port
        rx_data_adc = fread(PSoC, 1024, 'uint16');
        rx_data_fft = fread(PSoC, 2048, 'int32');
        
        fprintf("Transfer %i DONE \n", count);
        
        % Split FFT data into real and imaginary parts
        fft_real = rx_data_fft(1:2:end);
        fft_imag = rx_data_fft(2:2:end);
        
        % Compute the magnitude of the FFT
        fft_mag = sqrt(fft_real.^2 + fft_imag.^2);
        
        % Plotting the received data
        figure(1)
        subplot(3,1,1)
        plot([0:(length(rx_data_adc)-1)], rx_data_adc(1:length(rx_data_adc)));
        title(['Received Time Domain Data No.:', num2str(count)]);
        
        subplot(3,1,2)
        plot([0:1023], 1/length(rx_data_adc) * 20 * log10(abs(fft(rx_data_adc))));
        title('FFT - Array - Matlab');
        
        subplot(3,1,3)
        plot([0:1023], 1/length(rx_data_adc) * 2 * 20 * log10(fft_mag));
        title('FFT - Array - PSoC');
        
        % Save the received data
        save(strcat('CW_rx_data_adc_', int2str(count), '.mat'), 'rx_data_adc');
        
        % Increment the count
        count = count + 1;
    end

    % Stop after 10 transfers
    if count == 11
        break;
    end

    % Send ready signal to PSoC for the next transfer
    fwrite(PSoC, 's', 'uchar'); % means send, I am ready to receive
end

% Close the serial port
fclose(PSoC);

fprintf("Script End \n");
