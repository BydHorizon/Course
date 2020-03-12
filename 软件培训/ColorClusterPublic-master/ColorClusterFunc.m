function [ imgSmoothShow, newLabel, smoothChoosedColor, runTime ] = ColorClusterFunc( img, threadcolor, K )
%COLORCLUSTERFUNC Summary of this function goes here
%   Detailed explanation goes here
%   ���룺
%   img��            imread�õ�������ͼ��
%   threadcolor:     ������ɫ��
%   K��              ���������
%   
%   �����
%       ƽ����������ӽ���������ɫ�滻�Ľ��imgSmoothShow��
%       ƽ��������صı��newLabel
%       ƽ�������������ѡ������ɫsmoothChoosedColor
%       ���׶�����ʱ��
%
% License
% This software is made publicly for research use only. It may be modified 
% and redistributed under the terms of the GNU General Public License. 
%
% Author: hujiagao@gmail.com
% 
    tic;
    lamdaWeight = 8;   % ��������ƽ�����Ȩ�����ӣ�Խ��Խƽ��
    %% calculating the histogram
    disp('calculating the histogram of the image...');
    [imgRow, imgCol, ~] = size(img);
    h = fspecial('gaussian', [7 7], 0.5);  % ��ԭͼ����ƽ������Ϊ����������ɫ��Ӱ������ع۸���ɫ
    imgSmooth = imfilter(img, h, 'replicate', 'conv');%img;%        % �Ƿ������ͼ����г�ʼƽ�������Ƿ����������ض����ع۸���ɫ��Ӱ��
    imgDataSmooth = reshape(imgSmooth, imgRow*imgCol, 3);
    % ��RGB����ת��Ϊ��������������ɫ��������ݣ�Lab��
    imgDataCalDis = myColorDisMeasures(imgDataSmooth);%imgData;
    threadColorDis = myColorDisMeasures(threadcolor);%threadcolor;
    % ͳ����ɫֱ��ͼ������ÿ��������������ɫ������Ǹ�
    [~, minIndex] = pdist2(threadColorDis, imgDataCalDis, 'euclidean', 'smallest', 1);
    histogram = tabulate(minIndex); % histogram�в�һ���������е���ɫ����Щû������ԭͼ�е���ɫ���ܲ���������
    [~, sInx] = sort(histogram(:,3), 'descend');
    iniColorIndex = histogram(sInx(1:4*K), 1);  
    CenterColorCalDis = threadColorDis(iniColorIndex, :);
    Z = linkage(CenterColorCalDis, 'complete', 'euclidean');
    C = cluster(Z, 'maxclust', K);  % ����'cutoff',sigma��sigmaΪ��ɫ�Ƿ����Ƶ���ֵ������Զ�ȷ��������
    color = zeros(K, size(threadColorDis, 2));  % ��������ÿ�������ɫ�����ø���������������ɫ���棬
    for i=1:K                                   % �򰴸���ɫ���ر�����������ɫ                
        color(i,:) = mean(CenterColorCalDis(C==i, :), 1); 
    end
    CenterCalDis = color;  
    t1=toc;
    
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
    disp(['  cluster: total iterators:' num2str(iterator)]);
    t2=toc;

    %% smooth
    disp('smooth ...');
    h = GCO_Create(imgRow*imgCol, K);
    dataDis = pdist2(CenterCalDis, imgDataCalDis);
    dataDis = 1./(dataDis+0.0000001);   % ����ԽԶ������ԽС
    dataSum = sum(dataDis, 1);
    dataProb = dataDis ./ dataSum(ones(K,1),:);    % �����dataProbΪÿ���������ڸ���ĸ���
    GCO_SetDataCost(h, int32(-log(dataProb)));
    smoothCost = ones(K, K);
    smoothCost(1:(K+1):K*K) = 0;
    GCO_SetSmoothCost(h, int32(smoothCost));
    neighbors = myGetNeighbors(imgDataCalDis, imgRow, imgCol);
    GCO_SetNeighbors(h, lamdaWeight*neighbors);
    t3 = toc;
    
    GCO_Expansion(h);
    newLabel = GCO_GetLabeling(h);
    newColorTable = tabulate(newLabel);
    t4 = toc;

    imgSmoothShow = zeros(imgRow*imgCol, 3);
    smoothChoosedColor = zeros(K, 3);   % ��ѡ������ɫ
    for i=1:size(newColorTable, 1)
        index = find(newLabel==newColorTable(i,1));
        color = calRegionColor(threadcolor, imgDataCalDis(index, :));   % ���õ�������������ɫ
        smoothChoosedColor(i, :) = color;
        imgSmoothShow(index, :) = color(ones(size(index,1), 1), :); 
    end
    imgSmoothShow = reshape(uint8(imgSmoothShow), size(img));
    GCO_Delete(h);
    t5=toc;
    
    % ����ʱ�䣬����Ϊ����ɫ�����ʱ���趨datacost��smoothcost��ʱ������neighbors��ʱ
    % ����ͼ���ʱ���ܺ�ʱ
    runTime = [t1, t2-t1, t3-t2, t4-t3, t5];
    
    disp('Finish!');

end

