%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         可传输的判别函数
%         Author:yf
%         Date:2016/10/27
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input:
%     numofconloss: continuous packet loss of node i
%     e_buff: energy buffer of node i
%     b_buff: data buffer of node i
% Output:
%     value: return value of canTXOrNot (0: can not transmit 1: can transmit)

function [value] = canTXOrNot(numofconLoss, e_buff, b_buff)

value = 1;
th = 3;
if (e_buff*b_buff == 0 || numofconLoss > th)
    value = 0;
end

