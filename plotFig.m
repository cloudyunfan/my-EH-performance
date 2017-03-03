load('VarE_MAC(UP0)(N10)(Pgb0.2)(Pbg0.2)(EH3)(Emax2000)(stl100)(sf1000)revise.mat');
sum(Colli_RAP_sp)
sum(PL_RAP_sp)
index = (0.01:0.01:0.1)*1000*40;
figure(1);
plot(index, Pkt_len*PS_MAP_total(1,:)./(ELE_MAP_t(1,:)*0.04), index, Pkt_len*PS_RAP_total(1,:)./(ELE_RAP_t(1,:)*0.04), '--');
grid;
% axis([4, 40, 0, 0.08]);
title('energy efficiency of CSMA/CA and TDMA');
xlabel('energy harvesting rate (uJ/s)');
ylabel('energy efficiency (bits/uJ)');
legend('TDMA', 'CSMA/CA');

figure(2);
plot(index, Pktloss_rate_MAP(1,:), index, Pktloss_rate_RAP(1,:), '--');
grid;
% axis([4, 40, 0.3, 1]);
title('packet loss rate of CSMA/CA and TDMA');
xlabel('energy harvesting rate (uJ/s)');
ylabel('packet loss rate (%)');
legend('TDMA', 'CSMA/CA');

figure(3);
plot(index, Pkt_len*PS_MAP_total(1,:)/(TB*Tsim), index, Pkt_len*PS_RAP_total(1,:)/(TB*Tsim), '--');
grid;
title('Throughput of CSMA/CA and TDMA');
xlabel('energy harvesting rate (uJ/s)');
ylabel('Throughput (kb/s)');
legend('TDMA', 'CSMA/CA');
