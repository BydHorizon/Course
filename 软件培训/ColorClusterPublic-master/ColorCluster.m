% ͳ��ͼ����������ɫ���е�ֱ��ͼ��ȡֱ��ͼ�����ļ���Ϊ��ʼ��������
% ��ԭͼ���о��࣬�����ÿ�ε���ʱ���µľ���������������ɫ����ѡ��
% License
% This software is made publicly for research use only. It may be modified 
% and redistributed under the terms of the GNU General Public License. 
%
% Author: hujiagao@gmail.com
% 

addpath(genpath('./GCO'));
%matlabpool('open','local',3); 
clear;
tic;

img_dir = './data/';
img_name = 'timg.jpg';
K = 3;
lamdaWeight = 8;   % ��������ƽ�����Ȩ�����ӣ�Խ��Խƽ��

%% Read the color list
filename = 'threadcolor.txt';
delimiter = '\t';
startRow = 2;
fileID = fopen(filename,'r');
formatSpec = '%f%f%f%[^\n\r]';
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'HeaderLines' ,startRow-1, 'ReturnOnError', false);
fclose(fileID);
threadcolor = [dataArray{1:end-1}];
threadcolor = unique(threadcolor, 'rows');  % ɾ���ظ�����ɫ
clearvars filename delimiter startRow formatSpec fileID dataArray ans;

%% read the image and calculating the histogram
disp('calculating the histogram of the image...');
img = imread([img_dir img_name]);
figure('Name','The Source Image');
imshow(img);
[imgRow, imgCol, ~] = size(img);
h = fspecial('gaussian', [7 7], 0.5);  % ��ԭͼ����ƽ������Ϊ����������ɫ��Ӱ������ع۸���ɫ
imgSmooth = imfilter(img, h, 'replicate', 'conv');
imgDataSmooth = reshape(imgSmooth, imgRow*imgCol, 3);
% ��RGB����ת��Ϊ��������������ɫ��������ݣ�Lab��
imgDataCalDis = myColorDisMeasures(imgDataSmooth);%imgData;
threadColorDis = myColorDisMeasures(threadcolor);%threadcolor;
% ͳ����ɫֱ��ͼ������ÿ��������������ɫ������Ǹ�
[~, minIndex] = pdist2(threadColorDis, imgDataCalDis, 'euclidean', 'smallest', 1);
figure('Name','The quantized Image');
imshow(uint8(reshape(threadcolor(minIndex,:), imgRow, imgCol, 3)));
histogram = tabulate(minIndex); % histogram�в�һ���������е���ɫ����Щû������ԭͼ�е���ɫ���ܲ���������
[sorted, sInx] = sort(histogram(:,3), 'descend'); 
iniColorIndex = histogram(sInx(1:4*K), 1);   % ѡȡǰ4K����ɫ
CenterColorCalDis = threadColorDis(iniColorIndex, :);
Z = linkage(CenterColorCalDis, 'complete', 'euclidean');
C = cluster(Z, 'maxclust', K);  % ����'cutoff',sigma��sigmaΪ��ɫ�Ƿ����Ƶ���ֵ������Զ�ȷ��������
color = zeros(K, size(threadColorDis, 2));  % ��������ÿ�������ɫ�����ø���������������ɫ���棬
for i=1:K                                   % �򰴸���ɫ���ر�����������ɫ                
	color(i,:) = mean(CenterColorCalDis(C==i, :), 1); 
end
CenterCalDis = color;   % ��ֱ��ͼ��������ɫ��Ϊԭͼ����ĳ�ʼ��������ɫ
% clearvars h imgSmooth imgDataSmooth minIndex histogram iniColorIndex CenterColor ...
%     Z C i color dis indexmin;
toc;

%% cluster the image
disp('clustering ...');
MAXITERATOR = 100;
iterator = 0;
% ����ÿ�������������
[~, labels] = pdist2(CenterCalDis, imgDataCalDis, 'euclidean', 'smallest', 1);
labels2 = labels;
while iterator < MAXITERATOR
    % ���¼���������ģ������߿����Ҿ�������,��֤���ڷ�����С��ͨ�����ֵ��Ȼ�������߿��������ֵ��ӽ�����ɫʵ�֣���ȷ�Դ�֤����
    color = zeros(K, size(threadColorDis, 2));  % ��������ÿ�������ɫ
    for i=1:K                                              
        color(i,:) = mean(imgDataCalDis(labels2==i, :), 1); 
    end
    [~, CenterColorIndex] = pdist2(threadColorDis, color, 'euclidean', 'smallest', 1); % ����ɫ����������ƽ��ɫ��ӽ�����ɫ�滻ԭɫ
    CenterCalDis(:,:)  = threadColorDis(CenterColorIndex,:);    % ԭͼ�ĳ�ʼ����������ɫ

    % ���¼���ÿ�������������
    [~, labels2] = pdist2(CenterCalDis, imgDataCalDis, 'euclidean', 'smallest', 1);
    
    if isequal(labels2, labels)  % labels���䣬�������
        break;
    end

    labels = labels2;
    iterator = iterator+1;
end

disp(['  total iterators:' num2str(iterator)]);
CenterColor = threadcolor(CenterColorIndex, :);
imgCluster = CenterColor(labels, :);
imgCluster = int32(imgCluster);
binaryImgSmooth = bitshift(imgCluster(:,1),16)+bitshift(imgCluster(:,2),8)+imgCluster(:,3);
imgCluster = reshape(uint8(imgCluster), size(img));
figure('Name','The Cluster Result');
imshow(imgCluster);
% clearvars MAXITERATOR labels2 i indexmin color imgCluster; %iterator CenterColor
toc;

%% smooth
disp('smooth ...');
h = GCO_Create(imgRow*imgCol, K);
disp('setting data cost ...');
dataDis = pdist2(CenterCalDis, imgDataCalDis);
dataDis = 1./(dataDis+0.0000001);   % ����ԽԶ������ԽС
dataSum = sum(dataDis, 1);
dataProb = dataDis ./ dataSum(ones(K,1),:);    % �����dataProbΪÿ���������ڸ���ĸ���
GCO_SetDataCost(h, int32(-log(dataProb)));
toc;

smoothCost = int32(ones(K, K));
smoothCost(1:(K+1):K*K) = 0;
GCO_SetSmoothCost(h, int32(smoothCost));
disp('setting neighbors ...');
neighbors = myGetNeighbors(imgDataCalDis, imgRow, imgCol);
GCO_SetNeighbors(h, lamdaWeight*neighbors);
toc;

GCO_SetLabeling(h, labels);

disp('expansion ...');
GCO_SetVerbosity(h, 1);
Energy = GCO_Expansion(h);
newLabel = GCO_GetLabeling(h);
GCO_Delete(h);
newColorTable = tabulate(newLabel);
toc;

disp('display the resuslt...');
imgSmoothShow = zeros(imgRow*imgCol, 3);
smoothChoosedColor = zeros(K, 3);   % ��ѡ������ɫ
for i=1:size(newColorTable, 1)
    index = find(newLabel==newColorTable(i,1));
    color = calRegionColor(threadcolor, imgDataCalDis(index, :));   % ���õ�������������ɫ
    smoothChoosedColor(i, :) = color;
    imgSmoothShow(index, :) = color(ones(size(index,1), 1), :); 
end
imgSmoothShow = int32(imgSmoothShow);
imgSmoothShow = reshape(uint8(imgSmoothShow), size(img));
figure('Name','The Smooth Result In The ColorList');
imshow(imgSmoothShow);
imwrite(imgSmoothShow, [img_dir img_name '_result.bmp'])
dlmwrite([img_dir img_name '.txt'], [imgRow imgCol], '-append', 'delimiter', ' ')
dlmwrite([img_dir img_name '.txt'], reshape(newLabel, imgRow, imgCol) , '-append', 'delimiter', ' ')
dlmwrite([img_dir img_name '.txt'], smoothChoosedColor , '-append', 'delimiter', ' ')

toc;