%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         基于多个因素分配超帧中TDMA阶段
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
TDMAalloc = zeros(1, N); % N个节点
%计算每个节点的需求，一个时隙发一个包，使用一个单位的能量（后期再设计这个函数）
request = min(E_buff, B_buff);
isSatisfy = zeros(1, N);
%归一化参数
UPnodeO = (UPnode + 1) / 8;
E_buffO = E_buff / Emax;
% B_buffO = B_buff / Bmax;
numOfConLossO = ( numOfConLoss - min(numOfConLoss) ) / ( max(numOfConLoss) - min(numOfConLoss) );

%计算节点对应参数
weight = UPnodeO.*(E_buffO - lambda*numOfConLossO);

%求解优化函数：利用贪心算法（暂时不考虑可传输函数的约束）
%降序排序
[~, index] = sort(weight, 'descend');

%调整tdma的需求
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



