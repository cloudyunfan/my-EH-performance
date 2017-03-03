%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         基于多个因素的超帧中CSMA阶段长度调整函数
%         Author:yf
%         Date:2016/10/23
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [CSMALen, TDMALen, aCLI] = CSMALength_update(numOfConLoss, totalCollision, E_buff, oldCSMALen, oldACLI)
% Input:
%     numOfConLoss: continuous packet loss of nodes
%     totalCollision: total count of collisions
%     E_buff: energy buffer of nodes
%     oldCSMALen: new length of CSMA phase (slot)
%     oldACLI: old ACLI
% Output:
%     CSMALen: new length of CSMA phase (slot)
%     TDMALen: new length of TDMA phase (slot)
%     aCLI: new ACLI
%% 初始化变量，两个变量等
global Emax CSMALenMax CSMALenMin TB 
a = 2;
b = 0.5;
delta = 15;
%% 计算CSMA阶段长度调整因子
CLI = (numOfConLoss / totalCollision).*(E_buff / Emax);
aCLI = mean(CLI);
if isnan(aCLI)
    aCLI = 10000;
end
%% 长度调整算法
if aCLI > a*oldACLI
    CSMALen = min(CSMALenMax, oldCSMALen + delta);
else
    if aCLI < b*oldACLI
        CSMALen = max(CSMALenMin, oldCSMALen - delta);
    else
        CSMALen = oldCSMALen;
    end
end

TDMALen = TB - CSMALen;





