%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         ���ڶ�����ط��䳬֡��TDMA�׶�
%         Author:yf
%         Date:2016/10/27
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [TDMAalloc, isSatisfy, len_MAP, nodesPredictLast] = TDMA_allocation(numOfConLoss, UPnode, E_buff, B_buff, TDMAlen, lambda, nodesPredictLast)
% Input:
%     numOfConLoss: continuous packet loss of nodes
%     UPnode: different UP of nodes
%     E_buff: energy buffer of nodes (unit)
%     B_buff: data buffer of nodes (unit)
%     TDMAlen: length of TDMA phase in this superframe
%     nodesPredictLast: Predict last time of nodes
% Output:
%     TDMAalloc: resource allocation of TDMA phase (slot)
%     isSatisfy: whether the meet of nodes is satisfied
%     len_MAP: new length of tdma
%     nodesPredictLast: Predict last time of nodes

global Emax 
N = length(E_buff);
TDMAalloc = zeros(1, N); % N���ڵ�
%����ÿ���ڵ������һ��ʱ϶��һ������ʹ��һ����λ��������������������������
request = min(E_buff, B_buff);
isSatisfy = zeros(1, N);
%��һ������
UPnodeO = (UPnode + 1) / 8;
E_buffO = E_buff / Emax;
% B_buffO = B_buff / Bmax;
numOfConLossO = ( numOfConLoss - min(numOfConLoss) ) / ( max(numOfConLoss) - min(numOfConLoss) );

%����ڵ��Ӧ����
weight = UPnodeO.*(E_buffO - lambda*numOfConLossO);

%����Ż�����������̰���㷨����ʱ�����ǿɴ��亯����Լ����
%��������
[~, index] = sort(weight, 'descend');

%����tdma������
TDMAlen = min(sum(request), TDMAlen);
len_MAP = TDMAlen;

for i = 1 : length(index)
    TDMAalloc(i) = min(request(i), TDMAlen);
    TDMAlen = TDMAlen - TDMAalloc(i);
end

for i = 1 : N
    if (TDMAalloc(i) >= request(i))
        isSatisfy(i) = 1;
    end
    if (TDMAalloc(i) > 0)
        nodesPredictLast(i) = 1;
    else
        nodesPredictLast(i) = nodesPredictLast(i) + 1;
    end
end



