%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         ����802.15.6����µĶ�̬MACʱ϶���䣬���ѡ��ڵ����
%         Author:Ljg
%         Date:2015/03/18
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all
clc

%yf energy threshold,energy for transmission and CCA
global E_th
global N Tslot Data_rate TB Pbg Pgb CW CWmin CWmax UP UPnode Pkt_len Emax Bmax lambdaE lambdaB E_TX E_CCA Tsim stateLast isGood %isMAP lambdaE Emax Bmax isRAP
% global channelslot statelast
%yf probability of arrive one unit energy in each slot
%global P1_x
%------------802.15.6��ص�ȫ�ֲ���---------
UP = 0:7;  %8�����ȼ�
CWmin = [16,16,8,8,4,4,2,1];
CWmax = [64,32,32,16,16,8,8,4];

%----------------------���ò���-----------------------------------------------------
Tsim = 200; %NO. of superframes simulated
Tslot = 1;  % slot length (ms)
Pkt_len = 512; %packet length, unit is bit
Data_rate = 51.2; % transmission rate (kilo bits per second)
% yf initialize energy
E_th = 10; %40nJ
E_CCA = E_th/10;   %�ŵ�������ĵ�����,���͡����ܡ���������1:1:0.1%*******************************%
E_TX = E_th;       %�������ݰ���Ҫ������
%P1_x = 0.6;
Emax = 200;%
Bmax = 200;%
UPclass = 0;
NL = 16; %3:3:18 ֻ�й̶���Ŀ�Ľڵ�
%-----------���ݵ�����ת�Ƹ��ʣ�ά���������Ʒ�����-------------
isNormal = ones(1,NL); %���ݵ�����normal״̬
Pna = [0.4 0.4 0.4 0.4 0.3 0.3 0.3 0.3 0.2 0.2 0.2 0.2 0.1 0.1 0.1 0.1];
Pan = [0.2 0.2 0.2 0.2 0.3 0.3 0.3 0.3 0.4 0.4 0.4 0.4 0.1 0.1 0.1 0.1];
lambdaBNormal = [0.05 0.05 0.05 0.05 0.03 0.03 0.03 0.03 0.08 0.08 0.08 0.08 0.06 0.06 0.06 0.06]*10;   %���ݰ�ÿ�뵽���� /slot normal״̬
lambdaBAbnormal = [0.1 0.1 0.1 0.1 0.2 0.2 0.2 0.2 0.1 0.1 0.1 0.1 0.2 0.2 0.2 0.2]*10;   %���ݰ�ÿ�뵽���� /slot normal״̬
lambdaB = lambdaBNormal;
%--------------����ת�Ƹ��ʣ�sitting and walking��ά��һ������Ʒ�����----------------
isChange = 0; %�ж϶����Ƿ�ı�
isWalk = 1;
Pws = 0.2;
Psw = 0.2;
% walking and sitting state (slots)
% badStateLastWalk = [12 12 12 12 32 32 32 32 32 32 32 32 25 25 25 25];
% goodStateLastWalk = [52 52 52 52 72 72 72 72 72 72 72 72 77 77 77 77];
% badStateLastSit = [28 28 28 28 84 84 84 84 84 84 84 84 65 65 65 65];
% goodStateLastSit = [124 124 124 124 57 57 57 57 57 57 57 57 151 151 151 151];
badStateLastWalk = [10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10];
goodStateLastWalk = [10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10];
badStateLastSit = [10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10];
goodStateLastSit = [10 10 10 10 10 10 10 10 10 10 10 10 10 10 10 10];
badStateLast = badStateLastWalk;
goodStateLast = goodStateLastWalk;

TB = 200; %len_TDMA + len_RAP
%act = 2;
%yf omit the MAP
M = 10;   %MAP��ѯ�ʵ�ʱ϶���� M = 7;
T_block = 10;  %MAP��ÿһ�����ʱ϶��
% ELE_MAP = T_block*E_TX;
len_MAP = M*T_block;  %��ʼMAP�ĳ���%*******************************%
len_RAP = TB-len_MAP; %��ʼRAP�׶ι̶���100��ʱ϶%*******************************%
% UPH = 6;
% UPN = 0; 
%     lambdaE = E_rate(indE);   
    
%   -------------���ýڵ�����ȼ�----------------------------
    NLnode = NL/length(UPclass);
%     UPclass = [UPH,UPN];
%     NH = NL(indE)-NLnode;
    N_UP = NLnode*ones( 1,length(UPclass) );  %ÿһ�����ȼ��ڵ�ĸ���
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

%% ------------------------------------------------------------------------
for indE = 1:10     %�������ȼ������
    lambdaE = 2*(indE/100)*ones(1,N);   %������ÿ�뵽���� /slot
    isChange = 0; %�ж϶����Ƿ�ı�
    isWalk = 1;
    badStateLast = badStateLastWalk;
    goodStateLast = goodStateLastWalk;
    isNormal = ones(1,NL); %���ݵ�����normal״̬
    lambdaB = lambdaBNormal;   %���ݰ�ÿslot��������������N����
    %-----�ŵ�ģ��ʹ�ð�����Ʒ������ŵ�״̬��ģ�������ŵ�״̬ת�Ƹ���---------
    Pbg = 0.4*ones(1,N);   %û���õ�����ʱ���ܣ�
    Pgb = 0.4*ones(1,N);   %����ÿ���ڵ��ת�Ƹ���
    stateLast = 10*ones(1,N);   %����ÿ���ڵ���ŵ�����ʱ��
    isGood = randint(1,N);   %�������ÿ���ڵ�ĳ�ʼ�ŵ�״̬
    
    %------------------��ʼ����غͻ���������----------------
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
    ELE_RAP_sp = zeros(Tsim,N);%��¼�ܺ�
    ELE_MAP_sp = zeros(Tsim,N);
    ELE_RAP_tx = zeros(Tsim,N);%��¼�����ܺ�
    Count_sp = zeros(Tsim,N);  %������
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
%     actTime_sp = zeros(Tsim,1); %*******************************%
    
    Swait = waitbar(0,'�������');   %���ý�����
    last_TX_time_RAP = ones(1,N);
    
    %********************************************************%
    %
    %                    �Գ�֡Ϊ��λ����
    %
    %********************************************************%
    %-------------������ͨ�ڵ��������ֵ��ʼbuffer------------------
%     [~,~,~,~,E_buff,B_buff] = buff_update(TB,E_buff,B_buff);
%     [~,~,~,~,E_buff,B_buff] = buff_update(TB,E_buff,B_buff);

    for j = 1: Tsim
         %----������Ʒ���ģ�⶯��ת�ƣ�sitting and walking----
         if isWalk == 1
            isWalk = randsrc(1,1,[0 1;Pws 1-Pws]);
            if isWalk == 0
                isChange = 1; %�ж϶����ı���
            end
         else
            isWalk = randsrc(1,1,[0 1;1-Psw Psw]);
            if isWalk == 1
                isChange = 1; %�ж϶����ı���
            end
         end         
         %----������Ʒ���ģ�����ݵ�����ת�ƣ�normal and abnormal----
         for n = 1 : N
            if isNormal(n) == 1
                isNormal(n) = randsrc(1,1,[0 1;Pna(n) 1-Pna(n)]);
            else
                isNormal(n) = randsrc(1,1,[0 1;1-Pan(n) Pan(n)]);
            end
         end
         
         %********************************************************%
         %
         %                    �����׶ο�ʼ
         %
         %********************************************************%
         %--------------MAP �׶Σ�ʹ��TDMA��ʽ����ʱ϶--------------;               
         start = (j-1)*TB + 1; 
         TDMA_sift = 0;   %ƫ����  
         indMAP = find(ones(1,N)==1); %���нڵ㶼����MAP,���нڵ��index
         indPoll = getPollNode(indMAP,M);  %ȷ������poll�Ľڵ�
         %hist_MAP(j,1:length(indPoll))=indPoll;
         for poll =1:length(indPoll)   %�������и����ȼ��ڵ�ľ�����Ϊ     
            ind_node_poll = indPoll(poll); %ȡ�±�
            %----------scheduled slots---------------
            CHNafter_leng = 0;
            CHNbefore_leng = start + TDMA_sift - last_TX_time(ind_node_poll);
            %some errors
            %last_TX_time_MAP = last_TX_time(ind_node_poll) - CHNbefore_leng - TDMA_sift;
            [PL_td,PS_td,lastout(ind_node_poll),TDMA_CHN_Sta(ind_node_poll),Succ_TX_time_td,ELE_MAP,E_buff(ind_node_poll),B_buff(ind_node_poll),stateLast(ind_node_poll),isGood(ind_node_poll)] = pktsendTDMA_unsat( CHNbefore_leng,CHNafter_leng,TDMA_CHN_Sta((ind_node_poll)),T_block,Pbg((ind_node_poll)),Pgb((ind_node_poll)),stateLast(ind_node_poll),isGood(ind_node_poll),badStateLast(ind_node_poll),goodStateLast(ind_node_poll),E_buff((ind_node_poll)),B_buff((ind_node_poll)));
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
         
        %--------------------RAP�׶�ʹ��ʱ϶CSMA/CAʱ϶���䷽ʽ,���нڵ��������׶�------
        last_TX_time_RAP = last_TX_time - (j-1)*TB - len_MAP;
%         tic
        %yf Act(action),ignore the act ,always RAP %TDMA_CHN_Sta,
        [ReTX_time_pre,Def_Time_Pre,CSMA_Sta_Pre,PL_RAP,PS_RAP,Colli_RAP,ELE_RAP,Succ_TX_time_RAP,E_buff,B_buff,Count,ELE_tx] = slotCSMACA_unsat_new00(len_RAP,CSMA_Sta_Pre,Def_Time_Pre,RAP_CHN_Sta,ReTX_time_pre,CW,last_TX_time_RAP,E_buff,B_buff,badStateLast,goodStateLast, issatisfy);%ELE_RAP,���������ģ�,E_buff,E_flow�������������һ�¸� CW����ȫ�ִ���ȥ
%         toc
        
        PL_RAP_sp(j,:) = PL_RAP;
        PS_RAP_sp(j,:) = PS_RAP;
        Colli_RAP_sp(j,:) = Colli_RAP;
        ELE_RAP_sp(j,:) = ELE_RAP;
        ELE_RAP_tx(j,:) = ELE_tx;
        Count_sp(j,:) = Count;
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
        
        %**************************************************************%
        %   �ڳ�֡��������
        %   yf
        %**************************************************************%
        %-------------������ͨ�ڵ������buffer------------------
        [E_overflow,B_overflow,E_flow,b_flow,E_buff,B_buff] = buff_update(TB,E_buff,B_buff);
        B_of_sp(j,:) = B_overflow;
        B_sp(j,:) = b_flow;  
        EH_of_sp(j,:) = E_overflow;
        EH_sp(j,:) = E_flow;  %yf һ������ģ���e_flow��E_buff�ŵ�slotCSMACA_unsat_new ���ȴ�Tsim�����rap_length
        hist_E(j,:) = E_buff;
        hist_B(j,:) = B_buff;
        
        %--------------�������ݲ����ʣ�����֮ǰmarkov���Ľ��-------------------------
        for n = 1 : N
            if isNormal(n) == 1
                lambdaB(n) = lambdaBNormal(n);
            else
                lambdaB(n) = lambdaBAbnormal(n);
            end
         end
        %------------------�����µĶ����ĺû��ŵ�����ʱ��-----------------------------
        if (isChange == 1 && isWalk == 1)
            badStateLast = badStateLastWalk;
            goodStateLast = goodStateLastWalk;
            isChange = 0;
            %���������ı��費��Ҫ����stateLast
            stateLast = zeros(1,N);   %����ÿ���ڵ���ŵ�����ʱ��
        end
        if (isChange == 1 && isWalk == 0)
            badStateLast = badStateLastSit;
            goodStateLast = goodStateLastSit;
            isChange = 0;
            %���������ı��費��Ҫ����stateLast
            stateLast = zeros(1,N);   %����ÿ���ڵ���ŵ�����ʱ��
        end
        
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
        ELE_RAP_t(up,indE) = mean( sum( ELE_RAP_sp(:,indUP) ) );
        ELE_MAP_t(up,indE) = mean( sum( ELE_MAP_sp(:,indUP) ) );
        PS_RAP_total(up,indE) = mean( sum( PS_RAP_sp(:,indUP) ) );      %�ܵ�RAP�׶η��͵ĳ�֡����ȡ���нڵ��ƽ����   
        PS_MAP_total(up,indE) = mean( sum( PS_MAP_sp(:,indUP) ) );
        PL_RAP_total(up,indE) = mean( sum( PL_RAP_sp(:,indUP) ) );      %�ܵ�RAP�׶η��͵ĳ�֡����ȡ���нڵ��ƽ����   
        PL_MAP_total(up,indE) = mean( sum( PL_MAP_sp(:,indUP) ) );
        EE_RAP_t(up,indE) = PS_RAP_total(up,indE) / ELE_RAP_t(up,indE);      %����Ч��
        EE_MAP_t(up,indE) = PS_MAP_total(up,indE) / ELE_MAP_t(up,indE);
        
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
        EH_WBAN(indE) = sum( sum(EH_sp) )/N;
        %yf
        ELE_of_WBAN(indE) = sum( sum(ELE_MAP_sp+ELE_RAP_sp) )/N;
        Interval_WBAN(indE) = mean(Intv);
        %yf
        ELE_WBAN(indE) = sum( sum(ELE_RAP_sp+ELE_MAP_sp) )/N;
        %yf
        PS_WBAN(indE) = sum( sum(PS_RAP_sp+PS_MAP_sp) )/N;       
        Colli_WBAN(indE) = sum( sum(Colli_RAP_sp) )/N;
        Pktloss_WBAN(indE) = sum(sum( PL_RAP_sp+PL_MAP_sp ))/sum(sum( PS_RAP_sp+PS_MAP_sp ));
        Pktloss_WBAN_RAP(indE) = sum(sum( PL_RAP_sp ))/sum(sum( PS_RAP_sp ));
        Pktloss_WBAN_RAP(indE) = sum(sum( PL_MAP_sp ))/sum(sum( PS_MAP_sp ));
      disp(['indE NumUP: ',num2str([indE N])]) 
end
disp('unsaturation VarE and FixLen simulation done!')
save('VarE_MAC(UP0,N16)(E_th10)(E_cca1)(EH2).mat');