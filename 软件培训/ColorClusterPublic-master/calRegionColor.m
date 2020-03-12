function resultColor = calRegionColor( threadcolor, regionColor )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
% ��������ƽ��ɫ��ѡȡ���ߣ����Կ��ǵ����㷨��
% 1��	��������ƽ��ɫ
% 2��	����������ÿ��������ƽ��ɫ֮��Ĳ��
% 3��	������һ������Ĳ�࣬ȷ�������ض�ƽ��ɫ��Ȩ�أ�����Խ��Ȩ��Խ��
% 4��	����������ɫ��Ȩ������ƽ��ɫ��������ƽ��ɫ�仯������ѡ���߲��䣩��ֹͣ�����򣬷��ز���2.

    threadcolorlab = myColorDisMeasures(threadcolor);
    resultColor = mean(regionColor, 1);
    [~, indexmin] = pdist2(threadcolorlab, resultColor, 'euclidean', 'smallest', 1);
    iterator = 0;
    while iterator < 0    % ������100��  
        dis = pdist2(threadcolorlab, resultColor);

        weight = exp(-dis); % ����ԽԶ��Ȩ��ԽС
        weight = weight / sum(weight);
        resultColor = sum(regionColor .* weight(:,ones(1, size(regionColor, 2))), 1);
        
        dis = pdist2(threadcolorlab, resultColor);
        [~,indexmin2] = min(dis);
        if indexmin == indexmin2    % ��ѡ������ɫ����
            break;
        end
        indexmin = indexmin2;
        iterator = iterator + 1;
    end
    if iterator > 0
        disp(['  calRegionColor: iterator:' num2str(iterator)]);
    end
    resultColor = threadcolor(indexmin, :);     % ����������ɫ
end

