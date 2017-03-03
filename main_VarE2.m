%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         ����802.15.6����µĶ�̬MACʱ϶���䣬���ѡ��ڵ����
%         Author:Ljg
%         Date:2015/03/18
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all
clc

%yf energy threshold,energy for transmission and CCA
global E_th
global N Tslot Data_rate TB Pbg Pgb CW CWmin CWmax UP UPnode Pkt_len E_TX E_CCA Tsim %isMAP lambdaE  isRAP
global channelslot statelast lambdaE lambdaB Emax Bmax
%% ����MDP���
% load MDP_result(UP0-6,NH4)(Em20-Bm20,B0.05-E0.05)(NL3-3-18).mat %*******************************%
%------------802.15.6��ص�ȫ�ֲ���---------
UP = 0:7;  %8�����ȼ�
CWmin = [16,16,8,8,4,4,2,1];
CWmax = [64,32,32,16,16,8,8,4];

%----------------------���ò���-----------------------------------------------------
Tsim = 2000; %NO. of superframes simulated
Tslot = 1;  % slot length (ms)
Pkt_len = 607; %packet length, unit is bit
Data_rate = 607.1; % transmission rate (kilo bits per second)
% yf initialize energy
E_th = 10; % 1 unit is 0.04uJ
E_CCA = E_th / 10;   %�ŵ�������ĵ�����,���͡����ܡ���������1:1:1%*******************************%
E_TX = E_th;       %�������ݰ���Ҫ������:400uW * 1ms = 0.4uJ
Emax = 2000;
Bmax = 200;

TB = 200; %len_TDMA + len_RAP <=255
statelast = 100;

%yf omit the MAP
M = 10;   %MAP��ѯ�ʵ�ʱ϶���� M = 10;
T_block = 10;  %MAP��ÿһ�����ʱ϶��
% ELE_MAP = T_block*E_TX;
len_MAP = M*T_block;  %MAP�ĳ���%*******************************%
len_RAP = TB-len_MAP; %RAP�׶ι̶���100��ʱ϶%*******************************%
% UPH = 6;
UPN = 0;
NL = 10; %3:3:18
NLnode = NL;
lambdaB = 0.5*ones(1, NL);
%   -------------���ýڵ�����ȼ�----------------------------
UPclass = UPN;%0,,6,7
%     NH = NL(indE)-NLnode;
N_UP = NLnode;  %ÿһ�����ȼ��ڵ�ĸ���
UPnode = [];
for up=1:length(UPclass)
   node = UPclass(up)*ones(1,N_UP(up)); 
   UPnode = [UPnode node];
end
N = length(UPnode);
%��ʼ����������
for n=1:N
    CW(n) = CWmin(find(UP==UPnode(n)));  %��ʼ��CWΪ�ڵ��Ӧ���ȼ���CWmin
end
    lambdaE = 3*(1/100)*ones(1,N);   %������ÿ�뵽���� /slot
%% ------------------------------------------------------------------------
for indE = 1:10%   �������ȼ������
    lambdaE = lambdaE + 6*(indE/100)*ones(1,N);   %������ÿ�뵽���� /slot
    %-----�ŵ�ģ��ʹ������Ʒ������ŵ�״̬��ģ�������ŵ�״̬ת�Ƹ���---------
    Pbg = 0.2*ones(1,N);
    Pgb = 0.2*ones(1,N);   %Ϊ0Ϊ�����ŵ��������ŵ��㶨ΪGOOD����
    channelslot = zeros(1, N);
    %------------------��ʼ����غ����ݻ�����----------------
    E_buff = zeros(1,N); % ��ʼ�����ڵ�����״̬Ϊ0 
    B_buff = zeros(1,N);
    issatisfy = zeros(1,N); %���μ�CSMA/CA�׶�
    %----------------�������-----------------------------
    RAP_CHN_Sta = ones(1,N); % initial channel assumed to be GOOD. temperal variable to record every INITIAL state in a superframe
    TDMA_CHN_Sta = ones(1,N);    % initial channel assumed to be GOOD
    last_TX_time = ones(1,N); 
    CSMA_Sta_Pre = zeros(1,N);   % initial CSMA state assumed to be all 0 (0:initialization;1:backoff counter;2:sending packets)
    Def_Time_Pre = (-1)*ones(1,N); % initial deferred time -1
    ReTX_time_pre = zeros(1,N);  % ��ǽڵ��ش�����
    Succ_TX_time = zeros(Tsim*TB,N);   %��¼�ɹ������ʱ��
    Req = zeros(1,N); %�Ƿ��ڷ����������ݰ�����ʼ��Ϊ0���������������ݰ�    

    %--------------һ��Ҫͳ�ƵĽ��-------------------------------
    PL_RAP_sp = zeros(Tsim,N);  %������
    PL_MAP_sp = zeros(Tsim,N);    
    Colli_RAP_sp = zeros(Tsim,N);
    PS_RAP_sp = zeros(Tsim,N);   %�ɹ�����İ���
    PS_MAP_sp = zeros(Tsim,N);
    ELE_RAP_sp = zeros(Tsim,N);
    ELE_MAP_sp = zeros(Tsim,N);
    %*******************************%
    %����״̬���Բ�����
    %*******************************%
    B_of_sp = zeros(Tsim,N);%��¼���������
    B_sp = zeros(Tsim,N);
    EH_of_sp = zeros(Tsim,N);%��¼���������
    EH_sp = zeros(Tsim,N);
%     %��ʷ״̬��¼
% %     hist_Act = zeros(Tsim,N);
    hist_E = zeros(Tsim,N);
    hist_B = zeros(Tsim,N);    
    
    Swait = waitbar(0,'�������');   %���ý�����
    last_TX_time_RAP = last_TX_time;
    
    for j = 1: Tsim
        %--------------------RAP�׶�ʹ��ʱ϶CSMA/CAʱ϶���䷽ʽ,���нڵ��������׶�------
        last_TX_time_RAP = last_TX_time-(j-1)*TB; % ʵ������Ҫ�ں��������м���һ��(j-1)*TB���ɶ��Բ���
%         tic
        [ReTX_time_pre,Def_Time_Pre,CSMA_Sta_Pre,PL_RAP,PS_RAP,Colli_RAP,ELE_RAP,Succ_TX_time_RAP,E_buff,B_buff,~,~] = slotCSMACA_unsat_newnoE(len_RAP,CSMA_Sta_Pre,Def_Time_Pre,RAP_CHN_Sta,ReTX_time_pre,CW,last_TX_time_RAP,E_buff,B_buff);%ELE_RAP,���������ģ�,E_buff,E_flow�������������һ�¸� CW����ȫ�ִ���ȥ
%         toc
        
        PL_RAP_sp(j,:) = PL_RAP;
        PS_RAP_sp(j,:) = PS_RAP;
        Colli_RAP_sp(j,:) = Colli_RAP;
        ELE_RAP_sp(j,:) = ELE_RAP;
        for n=1:N
            %�������һ�γɹ�������ʱ��
            if( ~isempty(Succ_TX_time_RAP{n}) )
                %���³ɹ�����ʱ���¼
                ind_TX_RAP = Succ_TX_time_RAP{n} + (j-1)*TB;  %recover the real index
                last_TX_time(n) =  ind_TX_RAP(end);
                Succ_TX_time(ind_TX_RAP,n) = 1;
                last_TX_time_RAP(n) = last_TX_time(n)-(j-1)*TB;
            end  
        end
        
        %--------------MAP �׶Σ�ʹ��TDMA��ʽ����ʱ϶--------------;               
         start = (j-1)*TB + len_RAP + 1; 
         TDMA_sift = 0;   %ƫ����  
         indMAP = find(ones(1,N)==1); %���нڵ㶼����MAP
         indPoll = getPollNode(indMAP,M);  %ȷ������poll�Ľڵ�
         %hist_MAP(j,1:length(indPoll))=indPoll;
         for poll =1:length(indPoll)   %�������и����ȼ��ڵ�ľ�����Ϊ     
             ind_node_poll = indPoll(poll); %ȡ�±�
            %----------scheduled slots---------------
            CHNafter_leng = 0;
            CHNbefore_leng = start + TDMA_sift - last_TX_time(ind_node_poll);
            last_TX_time_MAP = last_TX_time(n) - CHNbefore_leng - TDMA_sift;
            [PL_td,PS_td,lastout(ind_node_poll),TDMA_CHN_Sta(ind_node_poll),Succ_TX_time_td,channelslot(ind_node_poll),ELE_MAP,E_buff(ind_node_poll),B_buff(ind_node_poll)] = pktsendTDMA_sat( CHNbefore_leng,CHNafter_leng,TDMA_CHN_Sta((ind_node_poll)),T_block,Pbg((ind_node_poll)),Pgb((ind_node_poll)),channelslot(ind_node_poll),E_buff(ind_node_poll),B_buff(ind_node_poll));
            if(~isempty(Succ_TX_time_td))
                %recover the real index                        
                ind_TX_MAP = Succ_TX_time_td + start + TDMA_sift;
                last_TX_time(ind_node_poll) = ind_TX_MAP(end);
                Succ_TX_time(ind_TX_MAP,ind_node_poll) = 1;
            end
           %---------------------����ͳ�Ʊ���------------------------
            TDMA_sift = TDMA_sift + T_block; %����ÿ���ڵ���䵽��ʱ϶������ƫ����                    
            ELE_MAP_sp(j,ind_node_poll) = ELE_MAP_sp(j,ind_node_poll) + ELE_MAP;  %���ĵ��������� 
            PL_MAP_sp(j,ind_node_poll) = PL_MAP_sp(j,ind_node_poll) + PL_td;
            PS_MAP_sp(j,ind_node_poll) = PS_MAP_sp(j,ind_node_poll) + PS_td;                                              
         end 
         
           %-------------������ͨ�ڵ������buffer------------------
        [E_overflow,B_overflow,E_flow,b_flow,E_buff,B_buff] = buff_update(TB,E_buff,B_buff);
        B_of_sp(j,:) = B_overflow;
        B_sp(j,:) = b_flow;  
        EH_of_sp(j,:) = E_overflow;
        EH_sp(j,:) = E_flow;  %yf һ������ģ���e_flow��E_buff�ŵ�slotCSMACA_unsat_new ���ȴ�Tsim�����rap_length
        hist_E(j,:) = E_buff;
        hist_B(j,:) = B_buff;
        %--------------������ʾ-------------------------------
        str = ['�������', num2str(j*100/Tsim), '%'];     
        waitbar(j/Tsim,Swait,str);
    end
    close(Swait);

        %--------------yf���ŵ�������-------------------------------

    for n=1:N
        ind_Intv = find(Succ_TX_time(:,n)==1);
        Intv(n) = mean( diff(ind_Intv) );
        Slot_ulti(n) = length(ind_Intv)*100/length(Succ_TX_time(:,n));  %�ŵ�������
    end
    
    %-------------ͳ��ͨ�Ų�����Ҫ�Ľ��-------------------------------
    
    for up=1:length(UPclass)
        indUP = find(UPnode==UPclass(up));
        
        %EH_total(up,indE) = mean( sum( EH_sp(:,indUP) ) );  %�ܲɼ���������      
        ELE_RAP_t(up,indE) = mean( sum( ELE_RAP_sp(:,indUP) ) );
        ELE_MAP_t(up,indE) = mean( sum( ELE_MAP_sp(:,indUP) ) );
        PS_RAP_total(up,indE) = mean( sum( PS_RAP_sp(:,indUP) ) );      %�ܵ�RAP�׶η��͵ĳ�֡����ȡ���нڵ��ƽ����   
        PS_MAP_total(up,indE) = mean( sum( PS_MAP_sp(:,indUP) ) );
        PL_RAP_total(up,indE) = mean( sum( PL_RAP_sp(:,indUP) ) );      %�ܵ�RAP�׶η��͵ĳ�֡����ȡ���нڵ��ƽ����   
        PL_MAP_total(up,indE) = mean( sum( PL_MAP_sp(:,indUP) ) );
        
        Colli_t(up,indE) = mean( sum( Colli_RAP_sp(:,indUP) ) );  %�ܳ�ͻ����ȡ���нڵ��ƽ����                
        Interval_avg(up,indE) = mean( Intv(indUP) );  %ƽ���ɹ�������� ,ȥ���ڵ��ƽ����
        Ulit_rate(up,indE) = mean( Slot_ulti(indUP) ); %ƽ���ŵ�������
%         Pktloss = PL_t./(PL_t+PS_t);
        Pktloss_rate(up,indE) = mean( sum( PL_RAP_sp(:,indUP)+PL_MAP_sp(:,indUP) )./sum( PS_RAP_sp(:,indUP)+PS_MAP_sp(:,indUP) ) );   %������ͬһ���ȼ��Ľڵ�(RAP + MAP)��ƽ�������ʱ�������        
        Pktloss_rate_RAP(up,indE) = mean( sum( PL_RAP_sp(:,indUP) )./sum( PS_RAP_sp(:,indUP) + PL_RAP_sp(:,indUP) ) ) ;   %������ͬһ���ȼ��Ľڵ�RAP��ƽ�������ʱ�������
        Pktloss_rate_MAP(up,indE) = mean( sum( PL_MAP_sp(:,indUP) )./sum( PS_MAP_sp(:,indUP) + PL_MAP_sp(:,indUP) ) ) ;   %������ͬһ���ȼ��Ľڵ��ƽ�������ʱ�������
                                                           
    end
%       %-----------------ͳ������WBAN�Ľ��---------------------------   

%         Act_time(indE) = mean(actTime_sp);
        %EH_WBAN(indE) = sum( sum(EH_sp) )/N;
        %yf
        %ELE_of_WBAN(indE) = sum( sum(ELE_RAP_sp) )/N;
        
        Interval_WBAN(indE) = mean(Intv);
        %yf
        %ELE_WBAN(indE) = sum( sum(ELE_RAP_sp) )/N;
        %yf
        PS_WBAN(indE) = sum( sum(PS_RAP_sp) )/N;       
        Colli_WBAN(indE) = sum( sum(Colli_RAP_sp) )/N;
        Pktloss_WBAN(indE) = sum(sum( PL_RAP_sp+PL_MAP_sp ))/sum(sum( PS_RAP_sp+PS_MAP_sp ));
        Pktloss_WBAN_RAP(indE) = sum(sum( PL_RAP_sp ))/sum(sum( PS_RAP_sp ));
        Pktloss_WBAN_RAP(indE) = sum(sum( PL_MAP_sp ))/sum(sum( PS_MAP_sp ));
%     disp(['indE NumUP lambdaE: ',num2str([indE N lambdaE])]) ; % yf һ������ģ�ȥ��lambdaE
      disp(['indE NumUP: ',num2str([indE N])]) 
end
disp('unsaturation VaringE simulation done!')
save('VarE_MAC(UP0)(N10)(indE1-1-1)(Pgb0.2)(Pbg0.2)(EH3gap6)(Emax2000)(stl100)(sf1000).mat');