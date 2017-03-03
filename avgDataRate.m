%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         计算不同节点数据包到达的平均速率
%         Author:yf
%         Date:2016/10/28
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [rate] = avgDataRate(Pna, Pan, lambdaBNormal, lambdaBAbnormal)

%计算马尔科夫链的稳态概率
abnormal = Pna ./ (Pna + Pan);
normal = Pan ./ (Pna + Pan);

%计算平均速率
rate = abnormal.*lambdaBAbnormal + normal.*lambdaBNormal;