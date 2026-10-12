%% Combined Feedback Plot - Revised Y-Coords & Spacing
clc; clear; close all;
projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = load_project_config();
satisfactionOutputDir = fullfile(cfg.outputDir, 'Satisfaction_Survey_Analysis');
if ~isfolder(satisfactionOutputDir), mkdir(satisfactionOutputDir); end

% 1. Ayarlar ve Dosya Bilgileri
filename = fullfile(cfg.satisfactionDataDir, ...
    'SATISFACTION_QUESTIONARY_withExcluded.xlsx');
sheet_activ = 'Sayfa4'; 
sheet_ae = 'Sayfa5';    

% Sorular
cog_questions = {'Did you think there was a variety of cognitive training tasks?', ...
                 'Were the objectives of the tasks clear?', ...
                 'Did you feel motivated when carrying out the tasks?', ...
                 'Did you find the tasks challenging?', '-', '-'};
prog_questions = {'Did you find variety in the aerobic exercises?', ...
                  'Did you feel motivated to do the exercises?', ...
                  'Did you find the exercises challenging?'};
als_questions = {'Did you find the intensity of the exercise adequate?', ...
                 'Did you find the duration of the program adequate?'};

% 2. Verileri Oku
try
    data_cog = readmatrix(filename, 'Sheet', sheet_activ, 'Range', 'X9:AC10'); 
    data_prog_activ = readmatrix(filename, 'Sheet', sheet_activ, 'Range', 'AD9:AF10'); 
    data_prog_ae = readmatrix(filename, 'Sheet', sheet_ae, 'Range', 'G7:I8');          
    data_als_activ = readmatrix(filename, 'Sheet', sheet_activ, 'Range', 'AG11:AH13'); 
    data_als_ae = readmatrix(filename, 'Sheet', sheet_ae, 'Range', 'J9:K11');          
catch
    error('Excel verileri okunamadı. Hücre aralıklarını kontrol edin.');
end

% 3. Yüzdelik Hesaplamalar
perc_cog = (data_cog ./ sum(data_cog, 1)) * 100;
perc_prog_activ = (data_prog_activ ./ sum(data_prog_activ, 1)) * 100;
perc_prog_ae = (data_prog_ae ./ sum(data_prog_ae, 1)) * 100;
perc_als_activ = (data_als_activ ./ sum(data_als_activ, 1)) * 100;
perc_als_ae = (data_als_ae ./ sum(data_als_ae, 1)) * 100;

% 4. Matris ve Revize Edilmiş Y-Koordinatları
n_total = 16; 
plot_data = zeros(n_total, 5);
y_group_names = cell(n_total, 1);
row_questions = cell(n_total, 1);

% İSTEDİĞİNİZ REVİZYON: 2, 4, 6, 8, 10'dan sonra birer boşluk (atlama)
% 1,2 (boş:3) 4,5 (boş:6) 7,8 (boş:9) 10,11 (boş:12) 13,14 (boş:15) ...
y_coords = [1 2, 4 5, 7 8, 10 11, 13 14, 16 17 18 19 20 21];

% ALS Verilerini Yerleştir (1-4. barlar)
plot_data(1, 3:5) = perc_als_ae(:, 2)';    y_group_names{1} = 'AE';          row_questions{1} = als_questions{2};
plot_data(2, 3:5) = perc_als_activ(:, 2)'; y_group_names{2} = 'Activ4Brain'; 
plot_data(3, 3:5) = perc_als_ae(:, 1)';    y_group_names{3} = 'AE';          row_questions{3} = als_questions{1};
plot_data(4, 3:5) = perc_als_activ(:, 1)'; y_group_names{4} = 'Activ4Brain';

% Program Verilerini Yerleştir (5-10. barlar)
for q = 1:3
    idx = 4 + (3-q)*2;
    plot_data(idx+1, 1:2) = perc_prog_ae(:, q)';    y_group_names{idx+1} = 'AE';          row_questions{idx+1} = prog_questions{q};
    plot_data(idx+2, 1:2) = perc_prog_activ(:, q)'; y_group_names{idx+2} = 'Activ4Brain';
end

% Cog Verilerini Yerleştir (11-16. barlar)
for q = 1:6
    idx = 10 + (7-q);
    plot_data(idx, 1:2) = perc_cog(:, q)';
    y_group_names{idx} = 'Activ4Brain';
    row_questions{idx} = cog_questions{q};
end

% 5. Görselleştirme
fig = figure('Units', 'pixels', 'Position', [50, 50, 1200, 950], 'Color', 'w');
yyaxis left
hBar = barh(y_coords, plot_data, 'stacked', 'BarWidth', 0.85);

% Renk Tanımlamaları
colors = [0 0.447 0.698; 0.835 0.368 0; 0.337 0.706 0.914; 0 0.62 0.451; 0.902 0.623 0];
for k = 1:5, set(hBar(k), 'FaceColor', colors(k, :)); end

% Sol Eksen Ayarları
ax = gca;
ax.YAxis(1).Color = 'k';
ax.YAxis(1).TickValues = y_coords;
ax.YAxis(1).TickLabels = {}; 
ax.YLim = [0 22]; % Koordinatlara göre sınır güncellendi
ax.XLim = [0 100];
xlabel('Percentage (%)', 'FontWeight', 'bold');

% Sağ Eksen Ayarları (Grup İsimleri)
yyaxis right
ax.YAxis(2).Color = 'k';
ax.YAxis(2).TickValues = y_coords;
ax.YAxis(2).TickLabels = y_group_names;
ax.YLim = [0 22];

% 6. Grafik Alanı ve Soru Metinleri
ax.Position = [0.45 0.15 0.42 0.78]; 

for i = 1:n_total
    if ~isempty(row_questions{i})
        curr_y = y_coords(i);
        if i <= 10
            if mod(i,2) == 1
                % İkili grupların (AE & Activ4Brain) ortasına soru metnini yaz
                mid_y = (y_coords(i) + y_coords(i+1))/2;
                text(-3, mid_y, row_questions{i}, 'HorizontalAlignment', 'right', ...
                    'FontSize', 10, 'FontWeight', 'bold');
            end
        else
            % Tekli Cog barları için
            text(-3, curr_y, row_questions{i}, 'HorizontalAlignment', 'right', ...
                'FontSize', 10, 'FontWeight', 'bold');
        end
    end
end

% Bar Üzerine Yüzdelik Değerlerin Yazılması
for i = 1:n_total
    acc_x = 0;
    for j = 1:5
        val = plot_data(i, j);
        if val > 3
            text(acc_x + val/2, y_coords(i), [num2str(round(val)) '%'], 'HorizontalAlignment', 'center', ...
                'Color', 'w', 'FontWeight', 'bold', 'FontSize', 8);
        end
        acc_x = acc_x + val;
    end
end

% 7. Legend ve Görünüm
lgd = legend(hBar, {'Yes', 'No', 'Short/Low', 'Adequate', 'Long/High'}, ...
    'Location', 'southoutside', 'Orientation', 'horizontal');
lgd.Position = [0.55 0.04 0.2 0.03]; 

grid on; ax.XGrid = 'off'; ax.YGrid = 'off'; box off;

%% without cognitive training questions

%% Combined Feedback Plot - Revised (Cognitive Questions Removed)
clc; clear; close all;
projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = load_project_config();
satisfactionOutputDir = fullfile(cfg.outputDir, 'Satisfaction_Survey_Analysis');
if ~isfolder(satisfactionOutputDir), mkdir(satisfactionOutputDir); end

set(groot, 'defaultAxesFontName', 'Arial');
set(groot, 'defaultTextFontName', 'Arial');

% 1. Ayarlar ve Dosya Bilgileri
filename = fullfile(cfg.satisfactionDataDir, ...
    'SATISFACTION_QUESTIONARY_withExcluded.xlsx');
sheet_activ = 'Sayfa4'; 
sheet_ae = 'Sayfa5';    

% Sorular (Sadece Program ve ALS soruları kaldı)
prog_questions = {'Did you find variety in the aerobic exercises?', ...
                  'Did you feel motivated to do the exercises?', ...
                  'Did you find the exercises challenging?'};
als_questions = {'Did you find the intensity of the exercise adequate?', ...
                 'Did you find the duration of the program adequate?'};

% 2. Verileri Oku
try
    data_prog_activ = readmatrix(filename, 'Sheet', sheet_activ, 'Range', 'AD9:AF10'); 
    data_prog_ae = readmatrix(filename, 'Sheet', sheet_ae, 'Range', 'G7:I8');          
    data_als_activ = readmatrix(filename, 'Sheet', sheet_activ, 'Range', 'AG11:AH13'); 
    data_als_ae = readmatrix(filename, 'Sheet', sheet_ae, 'Range', 'J9:K11');          
catch
    error('Excel verileri okunamadı. Hücre aralıklarını kontrol edin.');
end

% 3. Yüzdelik Hesaplamalar
perc_prog_activ = (data_prog_activ ./ sum(data_prog_activ, 1)) * 100;
perc_prog_ae = (data_prog_ae ./ sum(data_prog_ae, 1)) * 100;
perc_als_activ = (data_als_activ ./ sum(data_als_activ, 1)) * 100;
perc_als_ae = (data_als_ae ./ sum(data_als_ae, 1)) * 100;

% 4. Matris ve Revize Edilmiş Y-Koordinatları
n_total = 10; % Sadece 5 soru x 2 grup = 10 bar
plot_data = zeros(n_total, 5);
y_group_names = cell(n_total, 1);
row_questions = cell(n_total, 1);

% Y Koordinatları (2, 4, 6, 8, 10'dan sonra birer boşluk)
y_coords = [1 2, 4 5, 7 8, 10 11, 13 14];

% ALS Verilerini Yerleştir (1-4. barlar)
plot_data(1, 3:5) = perc_als_ae(:, 2)';    y_group_names{1} = 'AE';          row_questions{1} = als_questions{2};
plot_data(2, 3:5) = perc_als_activ(:, 2)'; y_group_names{2} = 'Activ4Brain'; 
plot_data(3, 3:5) = perc_als_ae(:, 1)';    y_group_names{3} = 'AE';          row_questions{3} = als_questions{1};
plot_data(4, 3:5) = perc_als_activ(:, 1)'; y_group_names{4} = 'Activ4Brain';

% Program Verilerini Yerleştir (5-10. barlar)
for q = 1:3
    idx = 4 + (3-q)*2;
    plot_data(idx+1, 1:2) = perc_prog_ae(:, q)';    y_group_names{idx+1} = 'AE';          row_questions{idx+1} = prog_questions{q};
    plot_data(idx+2, 1:2) = perc_prog_activ(:, q)'; y_group_names{idx+2} = 'Activ4Brain';
end

% 5. Görselleştirme
fig = figure('Units', 'pixels', 'Position', [50, 50, 1200, 650], 'Color', 'w');
yyaxis left
hBar = barh(y_coords, plot_data, 'stacked', 'BarWidth', 0.85);

% Renk Tanımlamaları
colors = [0 0.447 0.698; 0.835 0.368 0; 0.337 0.706 0.914; 0 0.62 0.451; 0.902 0.623 0];
for k = 1:5, set(hBar(k), 'FaceColor', colors(k, :)); end

% Sol Eksen Ayarları
ax = gca;
ax.YAxis(1).Color = 'k';
ax.YAxis(1).TickValues = y_coords;
ax.YAxis(1).TickLabels = {}; 
ax.YLim = [0 15]; % Bar sayısına göre limit düşürüldü
ax.XLim = [0 100];
% xlabel('Percentage (%)', 'FontWeight', 'bold');
% X eksenini tamamen kaldır
ax.XColor = 'none';
ax.XTick = [];
xlabel('');

% Sağ Eksen Ayarları
yyaxis right
ax.YAxis(2).Color = 'k';
ax.YAxis(2).TickValues = y_coords;
ax.YAxis(2).TickLabels = y_group_names;
ax.YLim = [0 15];

% 6. Grafik Alanı ve Soru Metinleri
ax.Position = [0.45 0.20 0.35 0.70]; 

for i = 1:n_total
    if ~isempty(row_questions{i})
        if mod(i,2) == 1
            mid_y = (y_coords(i) + y_coords(i+1))/2;
            text(-3, mid_y, row_questions{i}, 'HorizontalAlignment', 'right', ...
                'FontSize', 12, 'FontWeight', 'bold', 'FontName', 'Arial');
        end
    end
end

% Bar Üzerine Yüzdelik Değerler
for i = 1:n_total
    acc_x = 0;
    for j = 1:5
        val = plot_data(i, j);
        if val > 3
            text(acc_x + val/2, y_coords(i), [num2str(round(val)) '%'], ...
                 'HorizontalAlignment', 'center', ...
                 'Color', 'w', 'FontWeight', 'bold', 'FontSize', 12, 'FontName', 'Arial');
        end
        acc_x = acc_x + val;
    end
end

% 7. Legend ve Görünüm
lgd = legend(hBar, {'Yes', 'No', 'Short/Low', 'Adequate', 'Long/High'}, ...
    'Location', 'southoutside', 'Orientation', 'horizontal');
lgd.Position = [0.50 0.10 0.2 0.03];
lgd.FontName = 'Arial';
lgd.FontSize = 11;
grid on; ax.XGrid = 'off'; ax.YGrid = 'off'; box off;

exportgraphics(gcf, fullfile(satisfactionOutputDir, ...
    'custom_made_questionnaires_commongroups.tif'), 'Resolution', 300)

%% Only for Activ4Brain group 
%% Cognitive Questions Only Plot
clc; clear; close all;
projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = load_project_config();
satisfactionOutputDir = fullfile(cfg.outputDir, 'Satisfaction_Survey_Analysis');
if ~isfolder(satisfactionOutputDir), mkdir(satisfactionOutputDir); end

% 1. Ayarlar ve Dosya Bilgileri
filename = fullfile(cfg.satisfactionDataDir, ...
    'SATISFACTION_QUESTIONARY_withExcluded.xlsx');
sheet_activ = 'Sayfa4';

% Sorular
cog_questions = { ...
    'Did you think there was a variety of cognitive training tasks?', ...
    'Were the objectives of the tasks clear?', ...
    'Did you feel motivated when carrying out the tasks?', ...
    'Did you find the tasks challenging?', ...
    '-', ...
    '-'};

% Genel font ayarı
set(groot, 'defaultAxesFontName', 'Arial');
set(groot, 'defaultTextFontName', 'Arial');

% 2. Verileri Oku
try
    data_cog = readmatrix(filename, 'Sheet', sheet_activ, 'Range', 'X9:AC10');
catch
    error('Excel verileri okunamadı. Hücre aralığını kontrol edin.');
end

% 3. Yüzdelik Hesaplama
perc_cog = (data_cog ./ sum(data_cog, 1)) * 100;

% 4. Grafik Verisini Hazırla
n_questions = numel(cog_questions);

% Her soru için tek bar olacak
plot_data = zeros(n_questions, 2);

for q = 1:n_questions
    plot_data(q, 1:2) = perc_cog(:, q)';
end

% Q1 üstte görünsün diye ters çevir
plot_data = flipud(plot_data);
display_questions = flip(cog_questions);

% Y koordinatları (sorular arasında boşluklu görünüm için)
% y_coords = [1 3 5 7 9 11];
y_coords = 1:6;

% 5. Görselleştirme
fig = figure('Units', 'pixels', 'Position', [100, 100, 1100, 700], 'Color', 'w');
hBar = barh(y_coords, plot_data, 'stacked', 'BarWidth', 0.5);

% Renkler
colors = [
    0.0000, 0.4470, 0.6980;   % Yes
    0.8350, 0.3680, 0.0000    % No
];

for k = 1:2
    set(hBar(k), 'FaceColor', colors(k, :));
end

% 6. Eksen Ayarları
ax = gca;
ax.YTick = y_coords;
ax.YTickLabel = display_questions;
ax.YLim = [0.5 6.5];
ax.XLim = [0 120];

ax.FontName = 'Arial';
ax.FontSize = 12;
ax.FontWeight = 'bold';

% xlabel('Percentage (%)', 'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold');

% X eksenini kaldırmak istersen bunu aç:
ax.XColor = 'none';
ax.XTick = [];
xlabel('');

% Sol boşluğu artır
ax.Position = [0.42 0.18 0.50 0.54];

% 7. Bar Üzerine Yüzdelik Yazıları
for i = 1:n_questions
    acc_x = 0;
    for j = 1:2
        val = plot_data(i, j);
        if val > 3
            text(acc_x + val/2, y_coords(i), [num2str(round(val)) '%'], ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', ...
                'Color', 'w', ...
                'FontWeight', 'bold', ...
                'FontSize', 12, ...
                'FontName', 'Arial');
        end
        acc_x = acc_x + val;
    end
end

% 8. Legend
lgd = legend(hBar, {'Yes', 'No'}, ...
    'Location', 'southoutside', ...
    'Orientation', 'horizontal');

lgd.FontName = 'Arial';
lgd.FontSize = 12;
lgd.FontWeight = 'bold';

% 9. Görünüm
box off;
grid on;
ax.XGrid = 'off';
ax.YGrid = 'off';
ax.Layer = 'top';

% exportgraphics(gcf, 'cognitive_questions_only.tif', 'Resolution', 300);
