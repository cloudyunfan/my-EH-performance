%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         ���㲻ͬ�ڵ����ݰ������ƽ������
%         Author:yf
%         Date:2016/10/28
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [rate] = avgDataRate(Pna, Pan, lambdaBNormal, lambdaBAbnormal)

%��������Ʒ�������̬����
abnormal = Pna ./ (Pna + Pan);
normal = Pan ./ (Pna + Pan);

%����ƽ������
rate = abnormal.*lambdaBAbnormal + normal.*lambdaBNormal;