%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         基于802.15.6框架下的动态MAC时隙分配，随机选择节点个数
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
%------------802.15.6相关的全局参数---------
UP = 0:7;  %8个优先级
CWmin = [16,16,8,8,4,4,2,1];
CWmax = [64,32,32,16,16,8,8,4];

%----------------------设置参数-----------------------------------------------------
Tsim = 200; %NO. of superframes simulated
Tslot = 1;  % slot length (ms)
Pkt_len = 512; %packet length, unit is bit
Data_rate = 51.2; % transmission rate (kilo bits per second)
% yf initialize energy
E_th = 10; %40nJ
E_CCA = E_th/10;   %信道检测消耗的能量,发送、接受、侦听比例1:1:0.1%*******************************%
E_TX = E_th;       %发送数据包需要的能量
%P1_x = 0.6;
Emax = 200;%
Bmax = 200;%
UPclass = 0;
NL = 16; %3:3:18 只有固定数目的节点
%-----------数据到达率转移概率（维护多个马尔科夫链）-------------
isNormal = ones(1,NL); %数据到达是normal状态
Pna = [0.4 0.4 0.4 0.4 0.3 0.3 0.3 0.3 0.2 0.2 0.2 0.2 0.1 0.1 0.1 0.1];
Pan = [0.2 0.2 0.2 0.2 0.3 0.3 0.3 0.3 0.4 0.4 0.4 0.4 0.1 0.1 0.1 0.1];
lambdaBNormal = [0.05 0.05 0.05 0.05 0.03 0.03 0.03 0.03 0.08 0.08 0.08 0.08 0.06 0.06 0.06 0.06]*10;   %数据包每秒到达数 /slot normal状态
lambdaBAbnormal = [0.1 0.1 0.1 0.1 0.2 0.2 0.2 0.2 0.1 0.1 0.1 0.1 0.2 0.2 0.2 0.2]*10;   %数据包每秒到达数 /slot normal状态
lambdaB = lambdaBNormal;
%--------------动作转移概率：sitting and walking（维护一个马尔科夫链）----------------
isChange = 0; %判断动作是否改变
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
M = 10;   %MAP中询问的时隙块数 M = 7;
T_block = 10;  %MAP中每一个块的时隙数
% ELE_MAP = T_block*E_TX;
len_MAP = M*T_block;  %初始MAP的长度%*******************************%
len_RAP = TB-len_MAP; %初始RAP阶段固定有100个时隙%*******************************%
% UPH = 6;
% UPN = 0; 
%     lambdaE = E_rate(indE);   
    
%   -------------设置节点的优先级----------------------------
    NLnode = NL/length(UPclass);
%     UPclass = [UPH,UPN];
%     NH = NL(indE)-NLnode;
    N_UP = NLnode*ones( 1,length(UPclass) );  %每一种优先级节点的个数
    UPnode = [];
    for up=1:length(UPclass)
       node = UPclass(up)*ones(1,N_UP(up)); 
       UPnode = [UPnode node];
    end
    N = length(UPnode);
    %初始化竞争窗口
    for n=1:N
        CW(n) = CWmin(find(UP==UPnode(n)));  %初始化CW为节点对应优先级的CWmin
    end

%% ------------------------------------------------------------------------
for indE = 1:10     %多种优先级情况下
    lambdaE = 2*(indE/100)*ones(1,N);   %能量包每秒到达数 /slot
    isChange = 0; %判断动作是否改变
    isWalk = 1;
    badStateLast = badStateLastWalk;
    goodStateLast = goodStateLastWalk;
    isNormal = ones(1,NL); %数据到达是normal状态
    lambdaB = lambdaBNormal;   %数据包每slot到达数（包含了N个）
    %-----信道模型使用半马尔科夫链对信道状态建模，设置信道状态转移概率---------
    Pbg = 0.4*ones(1,N);   %没有用到（暂时不管）
    Pgb = 0.4*ones(1,N);   %设置每个节点的转移概率
    stateLast = 10*ones(1,N);   %设置每个节点的信道持续时间
    isGood = randint(1,N);   %随机设置每个节点的初始信道状态
    
    %------------------初始化电池和缓存数据区----------------
    E_buff = zeros(1,N); % 初始化各节点能量状态为0 
    B_buff = zeros(1,N);
    issatisfy = zeros(1,N); %都参加CSMA/CA阶段
    %----------------仿真变量-----------------------------
    RAP_CHN_Sta = ones(1,N); % initial channel assumed to be GOOD. temperal variable to record every INITIAL state in a superframe
    TDMA_CHN_Sta = ones(1,N);    % initial channel assumed to be GOOD
    last_TX_time = ones(1,N); 
    CSMA_Sta_Pre = zeros(1,N);   % initial CSMA state assumed to be all 0 (0:initialization;1:backoff counter;2:sending packets)
    Def_Time_Pre = (-1)*ones(1,N); % initial deferred time -1
    ReTX_time_pre = zeros(1,N);  % 标记节点重传次数
    Succ_TX_time = zeros(Tsim*TB,N);   %记录成功传输的时刻
    Req = zeros(1,N); %是否在发送请求数据包，初始化为0，不发送请求数据包  

    %--------------一需要统计的结果-------------------------------
    PL_RAP_sp = zeros(Tsim,N);  %丢包数
    PL_MAP_sp = zeros(Tsim,N);
    Colli_RAP_sp = zeros(Tsim,N);
    PS_RAP_sp = zeros(Tsim,N);   %成功传输的包数
    PS_MAP_sp = zeros(Tsim,N);
    ELE_RAP_sp = zeros(Tsim,N);%记录能耗
    ELE_MAP_sp = zeros(Tsim,N);
    ELE_RAP_tx = zeros(Tsim,N);%记录传输能耗
    Count_sp = zeros(Tsim,N);  %传输数
    %*******************************%
    %能量状态可以不考虑
    %*******************************%
    B_of_sp = zeros(Tsim,N);%记录溢出的能量
    B_sp = zeros(Tsim,N);
    EH_of_sp = zeros(Tsim,N);%记录溢出的能量
    EH_sp = zeros(Tsim,N);
%     %历史状态记录
% %     hist_Act = zeros(Tsim,N);
    hist_E = zeros(Tsim,N);
    hist_B = zeros(Tsim,N);
%     actTime_sp = zeros(Tsim,1); %*******************************%
    
    Swait = waitbar(0,'仿真进度');   %设置进度条
    last_TX_time_RAP = ones(1,N);
    
    %********************************************************%
    %
    %                    以超帧为单位迭代
    %
    %********************************************************%
    %-------------更新普通节点的能量数值初始buffer------------------
%     [~,~,~,~,E_buff,B_buff] = buff_update(TB,E_buff,B_buff);
%     [~,~,~,~,E_buff,B_buff] = buff_update(TB,E_buff,B_buff);

    for j = 1: Tsim
         %----用马尔科夫链模拟动作转移：sitting and walking----
         if isWalk == 1
            isWalk = randsrc(1,1,[0 1;Pws 1-Pws]);
            if isWalk == 0
                isChange = 1; %判断动作改变了
            end
         else
            isWalk = randsrc(1,1,[0 1;1-Psw Psw]);
            if isWalk == 1
                isChange = 1; %判断动作改变了
            end
         end         
         %----用马尔科夫链模拟数据到达率转移：normal and abnormal----
         for n = 1 : N
            if isNormal(n) == 1
                isNormal(n) = randsrc(1,1,[0 1;Pna(n) 1-Pna(n)]);
            else
                isNormal(n) = randsrc(1,1,[0 1;1-Pan(n) Pan(n)]);
            end
         end
         
         %********************************************************%
         %
         %                    两个阶段开始
         %
         %********************************************************%
         %--------------MAP 阶段，使用TDMA方式分配时隙--------------;               
         start = (j-1)*TB + 1; 
         TDMA_sift = 0;   %偏移量  
         indMAP = find(ones(1,N)==1); %所有节点都参与MAP,所有节点的index
         indPoll = getPollNode(indMAP,M);  %确定将被poll的节点
         %hist_MAP(j,1:length(indPoll))=indPoll;
         for poll =1:length(indPoll)   %遍历所有高优先级节点的决策行为     
            ind_node_poll = indPoll(poll); %取下标
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
           %---------------------更新统计变量------------------------
            TDMA_sift = TDMA_sift + T_block; %根据每个节点分配到的时隙数增加偏移量                    
            ELE_MAP_sp(j,ind_node_poll) = ELE_MAP_sp(j,ind_node_poll) + ELE_MAP;  %消耗的能量增加 
            PL_MAP_sp(j,ind_node_poll) = PL_MAP_sp(j,ind_node_poll) + PL_td;
            PS_MAP_sp(j,ind_node_poll) = PS_MAP_sp(j,ind_node_poll) + PS_td;                                              
         end 
         
        %--------------------RAP阶段使用时隙CSMA/CA时隙分配方式,所有节点参与这个阶段------
        last_TX_time_RAP = last_TX_time - (j-1)*TB - len_MAP;
%         tic
        %yf Act(action),ignore the act ,always RAP %TDMA_CHN_Sta,
        [ReTX_time_pre,Def_Time_Pre,CSMA_Sta_Pre,PL_RAP,PS_RAP,Colli_RAP,ELE_RAP,Succ_TX_time_RAP,E_buff,B_buff,Count,ELE_tx] = slotCSMACA_unsat_new00(len_RAP,CSMA_Sta_Pre,Def_Time_Pre,RAP_CHN_Sta,ReTX_time_pre,CW,last_TX_time_RAP,E_buff,B_buff,badStateLast,goodStateLast, issatisfy);%ELE_RAP,（倒数第四）,E_buff,E_flow（最后两个）等一下改 CW可以全局传过去
%         toc
        
        PL_RAP_sp(j,:) = PL_RAP;
        PS_RAP_sp(j,:) = PS_RAP;
        Colli_RAP_sp(j,:) = Colli_RAP;
        ELE_RAP_sp(j,:) = ELE_RAP;
        ELE_RAP_tx(j,:) = ELE_tx;
        Count_sp(j,:) = Count;
        for n=1:N
            %更新最近一次成功发包的时间
            if( ~isempty(Succ_TX_time_RAP{n}) )
                %更新成功发包时间记录
                ind_TX_RAP = Succ_TX_time_RAP{n} + (j-1)*TB;  %recover the real index
                last_TX_time(n) =  ind_TX_RAP(end);
                Succ_TX_time(ind_TX_RAP,n) = 1;
                last_TX_time_RAP(n) = last_TX_time(n)-(j-1)*TB;
            end  
        end
        
        %**************************************************************%
        %   在超帧更新能量
        %   yf
        %**************************************************************%
        %-------------更新普通节点的能量buffer------------------
        [E_overflow,B_overflow,E_flow,b_flow,E_buff,B_buff] = buff_update(TB,E_buff,B_buff);
        B_of_sp(j,:) = B_overflow;
        B_sp(j,:) = b_flow;  
        EH_of_sp(j,:) = E_overflow;
        EH_sp(j,:) = E_flow;  %yf 一会儿更改，将e_flow和E_buff放到slotCSMACA_unsat_new 长度从Tsim变成了rap_length
        hist_E(j,:) = E_buff;
        hist_B(j,:) = B_buff;
        
        %--------------更新数据采样率：根据之前markov链的结果-------------------------
        for n = 1 : N
            if isNormal(n) == 1
                lambdaB(n) = lambdaBNormal(n);
            else
                lambdaB(n) = lambdaBAbnormal(n);
            end
         end
        %------------------更新新的动作的好坏信道持续时间-----------------------------
        if (isChange == 1 && isWalk == 1)
            badStateLast = badStateLastWalk;
            goodStateLast = goodStateLastWalk;
            isChange = 0;
            %动作发生改变需不需要重置stateLast
            stateLast = zeros(1,N);   %设置每个节点的信道持续时间
        end
        if (isChange == 1 && isWalk == 0)
            badStateLast = badStateLastSit;
            goodStateLast = goodStateLastSit;
            isChange = 0;
            %动作发生改变需不需要重置stateLast
            stateLast = zeros(1,N);   %设置每个节点的信道持续时间
        end
        
        %--------------进度显示-------------------------------
         str = ['仿真完成', num2str(j*100/Tsim), '%'];     
         waitbar(j/Tsim,Swait,str);
    end
    close(Swait);

        %--------------yf求信道利用率-------------------------------

    for n=1:N
        ind_Intv = find(Succ_TX_time(:,n)==1);
        Intv(n) = mean( diff(ind_Intv) );
        Slot_ulti(n) = length(ind_Intv)*100/length(Succ_TX_time(:,n));  %信道利用率
    end
    
    %-------------统计通信参数需要的结果-------------------------------
    
    for up=1:length(UPclass)
        indUP = find(UPnode==UPclass(up));
        ELE_RAP_t(up,indE) = mean( sum( ELE_RAP_sp(:,indUP) ) );
        ELE_MAP_t(up,indE) = mean( sum( ELE_MAP_sp(:,indUP) ) );
        PS_RAP_total(up,indE) = mean( sum( PS_RAP_sp(:,indUP) ) );      %总的RAP阶段发送的超帧数，取所有节点的平均数   
        PS_MAP_total(up,indE) = mean( sum( PS_MAP_sp(:,indUP) ) );
        PL_RAP_total(up,indE) = mean( sum( PL_RAP_sp(:,indUP) ) );      %总的RAP阶段发送的超帧数，取所有节点的平均数   
        PL_MAP_total(up,indE) = mean( sum( PL_MAP_sp(:,indUP) ) );
        EE_RAP_t(up,indE) = PS_RAP_total(up,indE) / ELE_RAP_t(up,indE);      %能量效率
        EE_MAP_t(up,indE) = PS_MAP_total(up,indE) / ELE_MAP_t(up,indE);
        
        Colli_t(up,indE) = mean( sum( Colli_RAP_sp(:,indUP) ) );  %总冲突数，取所有节点的平均数                
        Interval_avg(up,indE) = mean( Intv(indUP) );  %平均成功发包间隔 ,去各节点的平均数
        Ulit_rate(up,indE) = mean( Slot_ulti(indUP) ); %平均信道利用率
%         Pktloss = PL_t./(PL_t+PS_t);
        Pktloss_rate(up,indE) = mean( sum( PL_RAP_sp(:,indUP)+PL_MAP_sp(:,indUP) )./sum( PS_RAP_sp(:,indUP)+PS_MAP_sp(:,indUP) ) );   %将属于同一优先级的节点(RAP + MAP)的平均丢包率保存起来        
        Pktloss_rate_RAP(up,indE) = mean( sum( PL_RAP_sp(:,indUP) )./sum( PS_RAP_sp(:,indUP) + PL_RAP_sp(:,indUP) ) ) ;   %将属于同一优先级的节点RAP的平均丢包率保存起来
        Pktloss_rate_MAP(up,indE) = mean( sum( PL_MAP_sp(:,indUP) )./sum( PS_MAP_sp(:,indUP) + PL_MAP_sp(:,indUP) ) ) ;   %将属于同一优先级的节点的平均丢包率保存起来        
                                                           
    end
%       %-----------------统计整个WBAN的结果---------------------------   

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