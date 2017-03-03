function [ pl,ps,outcome,CHN_sta_f,Succ_TX_ind,E_ex,E_nodebuf,B_nodebuf,statelast,isgood] = pktsendTDMA_unsat_hybird( CHNbefore_leng,CHNafter_leng,CHN_sta_ini,slotNO,Pu,Pd,statelast,isgood,badstatelast,goodstatelast,E_nodebuf,B_nodebuf,resource)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Input:
%   1.CHNbefore_leng : the former slots length.
%   2.CHNafter_leng : the latter slots length.
%   3.slotNO : NO. of allocated slots of the node.
%   4.CHN_sta_ini : temperal variable to record every INITIAL state in a superframe
%   5.Pu : the  transition probability from the bad state to the good state.(up:0->1)
%   6.Pd : the  transition probability from the good state to the bad state.(down:1->0)
%   7.E_nodebuf: energy buff of node n
%   8.B_nodebuf: data buff of node n
%Output:
%   1.CHN_sta_f : the  INITIAL state  after the pktsend.
%   2.ps : the NO. of successful packets
%   3.pl : the NO. of lossed packets.
%   4.outcome :  last slot state of current node
%   5.CHN_sta_f : the last state after the superframe.
%   6.E_ex: energy exhost totaly
%   7.Succ_TX_ind： record the time when node send pkt successfully after
%   thie superframe
% 	8.E_nodebuf：energy buff of node n
%   9.B_nodebuf:packet buff of node n
%   10.E_overflow_t:能量溢出
%   11.E_EH：能量采集
%*******与pktsend的区别是多返回一个平均成功发包间隔Interval_avg***********
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global  E_TX Emax
%--------------------initialize parameter--------------------------------
ps = 0;
pl = 0;
E_ex = 0;
E_overflow_t = 0;
E_EH = 0;
Succ_TX_ind = [];
% CHN_sta = CHN_sta_ini; % CHN_sta is a temperal variable updating every loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% channel state is updating
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% the channel state before current transmission，使用马尔科夫链来计算当前信道状态

% for c = 1:CHNbefore_leng 
%         if CHN_sta == 1
%             CHN_sta = randsrc(1,1,[0 1;Pd 1-Pd]); %%%%%% channel model
%         else
%             CHN_sta = randsrc(1,1,[0 1;1-Pu Pu]); %%%%%% using Markov chain
%         end
% end
for c = 1:CHNbefore_leng
    statelast = statelast + 1;
    if isgood == 1
        if statelast >= goodstatelast
            isgood = 0;
            statelast = 0;
        end
    else
        if statelast >= badstatelast
            isgood = 1;
            statelast = 0;
        end
    end
end

% transmitting  slotNO packets
% for d = 1:slotNO  % each node i transmit slotNO slots
%         if CHN_sta == 1
%             CHN_sta = randsrc(1,1,[0 1;Pd 1-Pd]); %%%%%% channel model
%         else
%             CHN_sta = randsrc(1,1,[0 1;1-Pu Pu]); %%%%%% using Markov chain
%         end
%         if ( CHN_sta==0 )
%             pl = pl+1; %%%%% calculate the NO. of lossed packets
%         else
%             if( E_nodebuf>=E_TX &&B_nodebuf>=1 ) %%%%%energy is enough and there has packets in buff
%                 ps = ps+1; %%%%% calculate the NO. of successful packets
%                 E_nodebuf = E_nodebuf - E_TX;   %消耗掉能量发送数据
%                 B_nodebuf = B_nodebuf - 1;  %缓存区数据包减少
%                 E_ex = E_ex + E_TX;     %记录消耗的能力总和
%                 Succ_TX_ind = [Succ_TX_ind d];  %对成功发包的时隙进行标记               
%             end
%         end
% %         %------energy buffer update---------
% %         [e_overflow,e,E_nodebuf] = E_update(1,E_nodebuf,1,Emax,lambdaE);
% %         E_overflow_t = E_overflow_t + e_overflow;
% %         E_EH = E_EH + e;
% end
for d = 1:slotNO  % each node i transmit slotNO slots
    statelast = statelast + 1;
    if isgood == 1
        if statelast >= goodstatelast
            isgood = 0;
            statelast = 0;
        end
    else
        if statelast >= badstatelast
            isgood = 1;
            statelast = 0;
        end
    end
    
    if ( isgood==0 )
        pl = pl+1; %%%%% calculate the NO. of lossed packets
    else
        if( E_nodebuf>=E_TX &&B_nodebuf>=1 ) %%%%%energy is enough and there has packets in buff
            ps = ps+1; %%%%% calculate the NO. of successful packets
            E_nodebuf = E_nodebuf - E_TX;   %消耗掉能量发送数据
            B_nodebuf = B_nodebuf - 1;  %缓存区数据包减少
            E_ex = E_ex + E_TX;     %记录消耗的能力总和
            Succ_TX_ind = [Succ_TX_ind d];  %对成功发包的时隙进行标记               
        end
    end
end
% not use
% outcome of last slot of current node,记录发送包时的信道状态（0：不好；1：好）
% outcome = CHN_sta;
outcome = 1;
% % update the channel state after transmission
% for e = 1:CHNafter_leng 
%         if CHN_sta == 1
%             CHN_sta = randsrc(1,1,[0 1;Pd 1-Pd]); %%%%%% channel model
%         else
%             CHN_sta = randsrc(1,1,[0 1;1-Pu Pu]); %%%%%% using Markov chain
%         end
% end
% % the final channel state of current node
% CHN_sta_f = CHN_sta;
CHN_sta_f = 1;
end
