%% Memnuniyet Anketi - Gruplandırılmış Yüzdelik Bar Grafiği
clc; clear; close all;
projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = load_project_config();

% 1. Ayarlar ve Dosya Bilgileri
filename = fullfile(cfg.satisfactionDataDir, ...
    'SATISFACTION_QUESTIONARY_withExcluded.xlsx');
sheet_activ = 'Sayfa4'; % Activ4Brain verisi
sheet_ae = 'Sayfa5';    % AE verisi

% Cevap Seçenekleri ve Soru Başlıkları
answers = {'Not easy at all', 'A little easy', 'Moderately easy', 'Quite easy', 'Extremely easy'};
questions = {
    '1-Was it easy to adapt to the sessions?', ...
    '2-Positive impact on well-being?', ...
    '3-Would participate again?', ...
    '4-Would you recommend to family/friends?'
};

% 2. Verileri Oku
% Not: Sizin verilerinizde Q1-Q4 arası sütunlar Excel'de 3. sütundan (C) başlar.
% 'Range', 'C2:F6' ifadesi 5 satırlık (1-5 likert) ve 4 sütunluk (Q1-Q4) veri bloğunu alır.
try
    data_activ = readmatrix(filename, 'Sheet', sheet_activ, 'Range', 'C2:F6');
    data_ae = readmatrix(filename, 'Sheet', sheet_ae, 'Range', 'C2:F6');
catch
    error('Excel dosyası veya Sayfa isimleri bulunamadı. Lütfen dosya adını kontrol edin.');
end

% 3. Yüzdelik Hesaplama
% Her sütunu (soruyu) kendi toplamına bölerek yüzdeyi buluyoruz.
perc_activ = (data_activ ./ sum(data_activ, 1)) * 100;
perc_ae = (data_ae ./ sum(data_ae, 1)) * 100;

% 4. Grafik Verisini Hazırla
% 4 soru, her biri için 2 bar (Activ ve AE) = Toplam 8 bar.
% Aralara boşluk bırakmak için bar yerleşimini manuel ayarlayacağız.
plot_data = zeros(8, 5);
y_labels = cell(8, 1);

for q = 1:4
    % Her sorunun bar çiftini yerleştiriyoruz (Q1 en üstte olacak şekilde ters dizilim)
    idx_activ = (4-q)*2 + 2; 
    idx_ae = (4-q)*2 + 1;
    
    plot_data(idx_activ, :) = perc_activ(:, q)';
    plot_data(idx_ae, :) = perc_ae(:, q)';
    
    y_labels{idx_activ} = 'Activ4Brain';
    y_labels{idx_ae} = 'AE';
end

% 5. Görselleştirme
figure('Units', 'pixels', 'Position', [100, 100, 1000, 600], 'Color', 'w');
hBar = barh(1:8, plot_data, 'stacked', 'BarWidth', 0.8);

% Likert Renk Paleti (Kırmızıdan Maviye)
% colors = [
%     0.85, 0.33, 0.10; % Not easy at all
%     0.93, 0.69, 0.13; % A little easy
%     0.80, 0.80, 0.80; % Moderately easy
%     0.47, 0.67, 0.19; % Quite easy
%     0.00, 0.45, 0.74  % Extremely easy
% ];

colors = [
0.8350, 0.3680, 0.0000; % Çok Memnuniyetsiz (Koyu Turuncu)
    0.9020, 0.6230, 0.0000; % Memnuniyetsiz (Açık Turuncu)
    0.9410, 0.8940, 0.2590; % Kararsız (Sarı)
    0.3370, 0.7060, 0.9140; % Memnun (Açık Mavi)
    0.0000, 0.4470, 0.6980  % Çok Memnun (Koyu Mavi)
];


for k = 1:5
    set(hBar(k), 'FaceColor', colors(k, :));
end

% Eksen ve Grafik Ayarları
ax = gca;
ax.YTick = 1:8;
ax.YTickLabel = y_labels;
ax.XLim = [0 100];
ax.FontSize = 10;
ax.FontName = 'Arial';
% xlabel('Percentage (%)', 'FontSize', 12, 'FontWeight', 'bold');
% X eksenini tamamen kaldır
ax.XColor = 'none';
ax.XTick = [];
xlabel('');
title('Program Satisfaction Comparison', 'FontSize', 14, 'FontWeight', 'bold');

% Sol tarafa Soru metinlerini ekle
for q = 1:4
    y_pos = (4-q)*2 + 1.5; 
    text(-2, y_pos, questions{q}, 'HorizontalAlignment', 'right', ...
        'FontSize', 11, 'FontWeight', 'bold');
end

% Grafik alanını metinlere yer açacak şekilde kaydır
ax.Position = [0.35 0.15 0.55 0.75]; 

% 6. Bar Üzerine Yüzde Değerlerini Yazdır
for i = 1:8
    accumulated_x = 0;
    for j = 1:5
        val = plot_data(i, j);
        if val > 4 % %4'ten küçükse yazı sığmayabilir
            text(accumulated_x + val/2, i, [num2str(round(val)), '%'], ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
                'Color', 'white', 'FontWeight', 'bold', 'FontSize', 9);
        end
        accumulated_x = accumulated_x + val;
    end
end

% Legend (Alt kısım)
lgd = legend(answers, 'Location', 'southoutside', 'Orientation', 'horizontal');
lgd.FontSize = 10;

box off; grid on; ax.Layer = 'top';



%% Y/N Questions and ALS Questions

clc; clear; close all;
projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = load_project_config();

% 1. Ayarlar ve Dosya Bilgileri
filename = fullfile(cfg.satisfactionDataDir, ...
    'SATISFACTION_QUESTIONARY_withExcluded.xlsx');
sheet_activ = 'Sayfa4'; % Activ4Brain verisi
sheet_ae = 'Sayfa5';    % AE verisi

% Cevap Seçenekleri ve Soru Başlıkları
answers = {'Yes', 'No'};
questions = {
    '1-Did you find variety in the aerobic exercises?', ...
    '2-Did you feel motivated to do the exercises?', ...
    '3-Did you find the exercises challenging?'
};

% 2. Verileri Oku
try
    % AD9:AF10 -> 2 Satır (Yes/No), 3 Sütun (Q1, Q2, Q3)
    data_activ = readmatrix(filename, 'Sheet', sheet_activ, 'Range', 'AD9:AF10');
    % G7:I8 -> 2 Satır (Yes/No), 3 Sütun (Q1, Q2, Q3)
    data_ae = readmatrix(filename, 'Sheet', sheet_ae, 'Range', 'G7:I8');
catch
    error('Excel dosyası veya Sayfa isimleri bulunamadı ya da hücre aralığı hatalı.');
end

% 3. Yüzdelik Hesaplama
perc_activ = (data_activ ./ sum(data_activ, 1)) * 100;
perc_ae = (data_ae ./ sum(data_ae, 1)) * 100;

% 4. Grafik Verisini Hazırla
n_ques = numel(questions);
n_ans = numel(answers);
plot_data = zeros(n_ques * 2, n_ans);
y_labels = cell(n_ques * 2, 1);

for q = 1:n_ques
    % Bar çiftlerini yerleştir (Q1 en üstte)
    idx_activ = (n_ques - q) * 2 + 2; 
    idx_ae = (n_ques - q) * 2 + 1;
    
    plot_data(idx_activ, :) = perc_activ(:, q)';
    plot_data(idx_ae, :) = perc_ae(:, q)';
    
    y_labels{idx_activ} = 'Activ4Brain';
    y_labels{idx_ae} = 'AE';
end

% 5. Görselleştirme
figure('Units', 'pixels', 'Position', [100, 100, 1000, 500], 'Color', 'w');
hBar = barh(1:n_ques*2, plot_data, 'stacked', 'BarWidth', 0.8);

% Evet/Hayır için Renkler (Mavi ve Kırmızı tonları)
colors = [
    0.0000, 0.4470, 0.6980; % Yes (#0072B2)
    0.8350, 0.3680, 0.0000  % No (#D55E00)
];

for k = 1:n_ans
    set(hBar(k), 'FaceColor', colors(k, :));
end

% Eksen ve Grafik Ayarları
ax = gca;
ax.YTick = 1:n_ques*2;
ax.YTickLabel = y_labels;
ax.XLim = [0 100];
ax.FontSize = 10;
ax.FontName = 'Arial';
% xlabel('Percentage (%)', 'FontSize', 12, 'FontWeight', 'bold');

% X eksenini tamamen kaldır
ax.XColor = 'none';
ax.XTick = [];
xlabel('');
title('Program Feedback Comparison (Yes/No)', 'FontSize', 14, 'FontWeight', 'bold');

% Sol tarafa Soru metinlerini ekle
for q = 1:n_ques
    y_pos = (n_ques - q) * 2 + 1.5; 
    text(-2, y_pos, questions{q}, 'HorizontalAlignment', 'right', ...
        'FontSize', 11, 'FontWeight', 'bold');
end

% Grafik alanını metinlere yer açacak şekilde ayarla
ax.Position = [0.35 0.2 0.55 0.7]; 

% 6. Bar Üzerine Yüzde Değerlerini Yazdır
for i = 1:(n_ques * 2)
    accumulated_x = 0;
    for j = 1:n_ans
        val = plot_data(i, j);
        if val > 3 % %3'ten büyükse yazdır
            text(accumulated_x + val/2, i, [num2str(round(val)), '%'], ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
                'Color', 'white', 'FontWeight', 'bold', 'FontSize', 9);
        end
        accumulated_x = accumulated_x + val;
    end
end

% Legend
lgd = legend(answers, 'Location', 'southoutside', 'Orientation', 'horizontal');
lgd.FontSize = 10;

box off; grid on; ax.Layer = 'top';

%% ALS Questions

clc; clear; close all;
projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = load_project_config();

% 1. Ayarlar ve Dosya Bilgileri
filename = fullfile(cfg.satisfactionDataDir, ...
    'SATISFACTION_QUESTIONARY_withExcluded.xlsx');
sheet_activ = 'Sayfa4'; % Activ4Brain verisi
sheet_ae = 'Sayfa5';    % AE verisi

% Cevap Seçenekleri ve Soru Başlıkları
answers = {'Short/Low', 'Adequate', 'Long/High'};
questions = {
    '1-Did you find the intensity of the exercise adequate?', ...
    '2-Did you find the duration of the program adequate?', ...
};

% 2. Verileri Oku
try
    % AG11:AH13 -> 3 Satır (Low/Adequate/High), 2 Sütun (Q1, Q2)
    data_activ = readmatrix(filename, 'Sheet', sheet_activ, 'Range', 'AG11:AH13');
    % J9:K11 -> 3 Satır (Short/Adequate/High), 2 Sütun (Q1, Q2)
    data_ae = readmatrix(filename, 'Sheet', sheet_ae, 'Range', 'J9:K11');
catch
    error('Excel dosyası veya Sayfa isimleri bulunamadı ya da hücre aralığı hatalı.');
end

% 3. Yüzdelik Hesaplama
perc_activ = (data_activ ./ sum(data_activ, 1)) * 100;
perc_ae = (data_ae ./ sum(data_ae, 1)) * 100;

% 4. Grafik Verisini Hazırla
n_ques = numel(questions);
n_ans = numel(answers);
plot_data = zeros(n_ques * 2, n_ans); % 4 satır, 3 sütun
y_labels = cell(n_ques * 2, 1);

for q = 1:n_ques
    % Bar çiftlerini yerleştir (Q1 en üstte)
    idx_activ = (n_ques - q) * 2 + 2; 
    idx_ae = (n_ques - q) * 2 + 1;
    
    plot_data(idx_activ, :) = perc_activ(:, q)';
    plot_data(idx_ae, :) = perc_ae(:, q)';
    
    y_labels{idx_activ} = 'Activ4Brain';
    y_labels{idx_ae} = 'AE';
end

% 5. Görselleştirme
figure('Units', 'pixels', 'Position', [100, 100, 1000, 450], 'Color', 'w');
hBar = barh(1:n_ques*2, plot_data, 'stacked', 'BarWidth', 0.8);

% 3 Cevap için Renk Paleti (Adequate: Yeşil, Long: Turuncu, Short: Sarı/Mavi)
% colors = [
%     0.20, 0.60, 0.20; % Adequate (Yeşil)
%     0.85, 0.33, 0.10; % Long (Koyu Turuncu/Kırmızımsı)
%     0.93, 0.69, 0.13  % Short (Sarı/Hardal)
% ];

colors = [

    
    0.3370, 0.7060, 0.9140  % Kısa (#56B4E9)
    0.0000, 0.6200, 0.4510; % Yeterli (#009E73)
    0.9020, 0.6230, 0.0000; % Uzun (#E69F00)
];
% Renkleri barlara uygula
for k = 1:n_ans
    set(hBar(k), 'FaceColor', colors(k, :));
end

% Eksen ve Grafik Ayarları
ax = gca;
ax.YTick = 1:n_ques*2;
ax.YTickLabel = y_labels;
ax.XLim = [0 100];
ax.FontSize = 10;
ax.FontName = 'Arial';
% xlabel('Percentage (%)', 'FontSize', 12, 'FontWeight', 'bold');
% X eksenini tamamen kaldır
ax.XColor = 'none';
ax.XTick = [];
xlabel('');
title('Intensity and Duration Feedback', 'FontSize', 14, 'FontWeight', 'bold');

% Sol tarafa Soru metinlerini ekle
for q = 1:n_ques
    y_pos = (n_ques - q) * 2 + 1.5; 
    text(-2, y_pos, questions{q}, 'HorizontalAlignment', 'right', ...
        'FontSize', 11, 'FontWeight', 'bold');
end

% Grafik alanını metinlere yer açacak şekilde ayarla
ax.Position = [0.4 0.25 0.55 0.6]; 

% 6. Bar Üzerine Yüzde Değerlerini Yazdır
for i = 1:(n_ques * 2)
    accumulated_x = 0;
    for j = 1:n_ans
        val = plot_data(i, j);
        if val > 3 % %3'ten büyükse yazdır
            text(accumulated_x + val/2, i, [num2str(round(val)), '%'], ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
                'Color', 'white', 'FontWeight', 'bold', 'FontSize', 9);
        end
        accumulated_x = accumulated_x + val;
    end
end

% Legend
lgd = legend(answers, 'Location', 'southoutside', 'Orientation', 'horizontal');
lgd.FontSize = 10;

box off; grid on; ax.Layer = 'top';                 

%% yes/no questions only for cognitive training

clc; clear; close all;
projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = load_project_config();

% 1. Ayarlar ve Dosya Bilgileri
filename = fullfile(cfg.satisfactionDataDir, ...
    'SATISFACTION_QUESTIONARY_withExcluded.xlsx');
sheet_name = 'Sayfa4'; % Verinin olduğu sayfa adı

% Cevap Seçenekleri
answers = {'Yes', 'No'};

% Sorular (Son iki soru \n ile iki satıra bölündü)
questions = {
    '1-Did you think there was a variety of cognitive training tasks?', ...
    '2-Were the objectives of the tasks clear?', ...
    '3-Did you feel motivated when carrying out the tasks?', ...
    '4-Did you find the tasks challenging?', ...
    '5-', ...
    '6-'
};

% 2. Verileri Oku
try
    % Excel'deki konuma göre Range'i güncelleyin.
    % 2 satır (Yes/No sayıları) ve 6 sütun (6 soru) seçilmelidir.
    data = readmatrix(filename, 'Sheet', sheet_name, 'Range', 'X9:AC10');
catch
    error('Excel verisi okunamadı. Lütfen hücre aralığını (Range) ve sayfa adını kontrol edin.');
end

% 3. Yüzdelik Hesaplama
perc_data = (data ./ sum(data, 1)) * 100;

% Grafik yerleşimi için veriyi ve soruları hazırlıyoruz
plot_data = perc_data'; 
plot_data = flipud(plot_data); 
display_questions = flip(questions);

% 4. Görselleştirme
figure('Units', 'pixels', 'Position', [100, 100, 1100, 600], 'Color', 'w');
hBar = barh(1:numel(questions), plot_data, 'stacked', 'BarWidth', 0.6);

% Evet/Hayır için Renkler (Mavi ve Kırmızı tonları)
colors = [
    0.0000, 0.4470, 0.6980; % Yes (#0072B2)
    0.8350, 0.3680, 0.0000  % No (#D55E00)
];

for k = 1:numel(answers)
    set(hBar(k), 'FaceColor', colors(k, :));
end

% Eksen ve Grafik Ayarları
ax = gca;
ax.YTick = 1:numel(questions);
ax.YTickLabel = display_questions; 
ax.XLim = [0 100];
ax.FontSize = 10;
ax.FontName = 'Arial';
% xlabel('Percentage (%)', 'FontSize', 11, 'FontWeight', 'bold');
% X eksenini tamamen kaldır
ax.XColor = 'none';
ax.XTick = [];
xlabel('');
title('Cognitive Training Tasks Feedback', 'FontSize', 14, 'FontWeight', 'bold');

% Grafik alanını soru metinlerine göre ayarla (Sol boşluk metinler için artırıldı)
ax.Position = [0.42 0.20 0.53 0.70]; 

% 5. Bar Üzerine Yüzde Değerlerini Yazdır
for i = 1:numel(questions)
    accumulated_x = 0;
    for j = 1:numel(answers)
        val = plot_data(i, j);
        if val > 3 
            text(accumulated_x + val/2, i, [num2str(round(val)), '%'], ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
                'Color', 'white', 'FontWeight', 'bold', 'FontSize', 9);
        end
        accumulated_x = accumulated_x + val;
    end
end

% Legend (Alt kısım)
lgd = legend(answers, 'Location', 'southoutside', 'Orientation', 'horizontal');
lgd.FontSize = 10;

box off; grid on; ax.XGrid = 'on'; ax.YGrid = 'off'; ax.Layer = 'top';

%% satisfaçao questionneiries
clc; clear; close all;
projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = load_project_config();

% 1. Ayarlar ve Dosya Bilgileri
filename = fullfile(cfg.satisfactionDataDir, ...
    'SATISFACTION_QUESTIONARY_withExcluded.xlsx');
sheet_name = 'Sayfa4'; 

% Cevap Seçenekleri
answers = {'Strongly Disagree', 'Disagree', 'Slightly Disagree', ...
           'Neutral', 'Slightly Agree', 'Agree', 'Strongly Agree'};

% Soru Başlıkları
questions = {
            'I am satisfied with it.', ...
            'I would recommend it to a friend.', ...
            'It is fun to use.', ...
            'It works the way I want it to work.', ...
            'It is wonderful.', ...
            'I feel I need to have it.', ...
            'It is pleasant to use.'
            };

% 2. Verileri Oku
try
    data = readmatrix(filename, 'Sheet', sheet_name, 'Range', 'Q2:W8');
catch
    error('Excel verisi okunamadı.');
end

% 3. Yüzdelik Hesaplama
perc_data = (data ./ sum(data, 1)) * 100;
plot_data = perc_data'; 
plot_data = flipud(plot_data); 
display_questions = fliplr(questions);

% 4. Görselleştirme
figure('Units', 'pixels', 'Position', [100, 100, 1100, 600], 'Color', 'w');
hBar = barh(1:numel(questions), plot_data, 'stacked', 'BarWidth', 0.7);

% Renk Paleti
colors = [
    0.70, 0.00, 0.00; 0.90, 0.30, 0.20; 1.00, 0.70, 0.60; 
    0.90, 0.90, 0.90; 0.60, 0.85, 0.95; 0.30, 0.50, 0.80; 0.10, 0.20, 0.50
];

for k = 1:numel(answers)
    set(hBar(k), 'FaceColor', colors(k, :));
end

% Eksen Ayarları - Diğer kodla aynı yazı stili ve kalınlıkları
ax = gca;
ax.YTick = 1:numel(questions);
ax.YTickLabel = display_questions;
ax.XLim = [0 120];

% Yazı Tipi ve Boyutu Ayarları (Diğer kodla eşitlendi)
ax.FontSize = 12;
ax.FontName = 'Arial';
ax.FontWeight = 'bold'; % Eksen değerlerini kalın yaptık

% xlabel('Percentage (%)', 'FontSize', 12, 'FontWeight', 'bold', 'FontName', 'Arial');

% X eksenini tamamen kaldır
ax.XColor = 'none';
ax.XTick = [];
xlabel('');

% title('Program Evaluation with the USE Questionnaries', 'FontSize', 14, 'FontWeight', 'bold', 'FontName', 'Arial');

% Grafik alanını ayarla
ax.Position = [0.30 0.20 0.65 0.70]; 

% 5. Bar Üzerine Yüzde Değerleri - Yazı boyutu ve kalınlığı eşitlendi
for i = 1:numel(questions)
    accumulated_x = 0;
    for j = 1:numel(answers)
        val = plot_data(i, j);
        if val > 3 
            textColor = 'w';
            if j == 4, textColor = 'k'; end 
            
            % FontSize 8 ve FontWeight bold olarak güncellendi
            text(accumulated_x + val/2, i, [num2str(round(val)), '%'], ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
                'Color', textColor, 'FontWeight', 'bold', 'FontSize', 12, 'FontName', 'Arial');
        end
        accumulated_x = accumulated_x + val;
    end
end

% Legend - Yazı boyutu ve kalınlığı eşitlendi
lgd = legend(answers, 'Location', 'southoutside', 'Orientation', 'horizontal', 'NumColumns', 4);
lgd.FontSize = 11;
lgd.FontWeight = 'bold'; % Legend metinleri kalınlaştırıldı
lgd.FontName = 'Arial';

box off; grid off; ax.Layer = 'top';
