%function Result=mian(FileName)
function model=constraints_produce_DC(dataUC,FileName)

Alpha = dataUC.units.alpha;                           %���鷢�纯��ϵ��Alpha--N*1����
Beta = dataUC.units.beta;                             %���鷢�纯��ϵ��Beta--N*1����
Gama = dataUC.units.gamma;                            %���鷢�纯��ϵ��Gama--N*1����
ThPimin = dataUC.units.PG_low;                         %���鷢�繦���½�--N*1����
ThPimax = dataUC.units.PG_up;                          %���鷢�繦���Ͻ�--N*1����
Piup = dataUC.units.ramp;                         %�������¹����Ͻ�--N*1����
Pidown = dataUC.units.ramp;                     %�������¹����Ͻ�--N*1����
Pt = dataUC.totalLoad.PD_T;                       %�й�����--T*1����
Qt=dataUC.totalLoad.QD_T;                       %�޹�����--T*1
Bus_G=dataUC.units.bus_G;                           %����ڵ��
Bus_D=dataUC.busLoad.bus_PDQR;
N = dataUC.baseparameters.unitN;                 %��������--1*1����
T = dataUC.totalLoad.T;                          %ʱ�����--1*1����
Dt = dataUC.totalLoad.PD_T;                                 %��������--T*1����
bus_P=dataUC.busLoad.node_P;
Spin = dataUC.totalLoad.R_T;                     %��ת�ȱ���--T*1����
ThTime_on_off_init = dataUC.units.U_ini;        %�����ڳ�ʼ״̬ǰ�Ѿ�����/ͣ����ʱ��--N*1����
Thon_off_init = dataUC.units.PG_up*0.7;               %��������ʼ����--N*1����
ThTime_on_min = dataUC.units.T_on;             %������С����ʱ��--N*1����
ThTime_off_min = dataUC.units.T_off;           %������Сͣ��ʱ��--N*1����
ThCold_cost_start = dataUC.units.start_cost*2;           %���������������--N*1����
ThHot_cost_start = dataUC.units.start_cost;             %���������������--N*1����
Pistartup = dataUC.units.PG_low;      %����鿪������--N*1����
Pishutdown = dataUC.units.PG_low;      %�����ػ�����--N*1����
ThCold_time_start=randi([1,4],N,1);
E0=dataUC.E0;
a=dataUC.a;
b=dataUC.b;
c=dataUC.c;
price_buy=dataUC.price_buy;
price_sell=dataUC.price_sell;
emmission_buy_max=dataUC.emmission_buy_max;
emmission_sell_max=dataUC.emmission_sell_max;
NodeNum=dataUC.baseparameters.busN;
branchI=dataUC.branch.I;
branchJ=dataUC.branch.J;
branchX=dataUC.branch.X;
branchP=dataUC.branch.P;
B=DCOPFNodeY(dataUC);

Uit=sparse(1,N*T);
PitWan=sparse(1,N*T);
Sit=sparse(1,N*T);
SitWan=sparse(1,N*T);
Eb=sparse(1,1);
Es=sparse(1,1);
pai_b=sparse(1,1);
pai_s=sparse(1,1);
seita=sparse(1,NodeNum*T);

x=[Uit,PitWan,Sit,SitWan,Eb,Es,pai_b,pai_s,seita];
Value_num=length(x);
uit_location=1:N*T;
%Zit=[];


%Ŀ�꺯����Ҫ�ı���--start--
Alpha_wan = Alpha + Beta .* ThPimin + Gama .* ThPimin .* ThPimin;           %Alpha����--N*1����
Beta_wan = (ThPimax - ThPimin) .* (Beta + 2 * Gama .* ThPimin);             %Beta����--N*1����
Gama_wan = Gama .* (ThPimax - ThPimin) .* (ThPimax - ThPimin);              %Gama����--N*1����
% Alpha_wan = Alpha + Beta .* ThPimin + Gama .* ThPimin .* ThPimin + deta .* ThPimin .* ThPimin .* ThPimin;           %Alpha����--N*1����
% Beta_wan = (ThPimax - ThPimin) .* (Beta + 2 * Gama .* ThPimin + 3 .* deta .* ThPimin .* ThPimin);             %Beta����--N*1����
% Gama_wan = (Gama + 3 .* deta .* ThPimin) .* (ThPimax - ThPimin) .* (ThPimax - ThPimin);              %Gama����--N*1����
% Deta_wan = deta .* (ThPimax - ThPimin) .* (ThPimax - ThPimin) .* (ThPimax - ThPimin);  %Derta����--N*1����
% Ŀ�꺯����Ҫ�ı���--end--

% ���������Լ����Ҫ�ı���--start--
Piup_wan = Piup ./ (ThPimax - ThPimin);                                     %Piup����--N*1����
Pidown_wan = Pidown ./ (ThPimax - ThPimin);                                 %Pidown����--N*1����
Pistartup_wan = (Pistartup - ThPimin) ./ (ThPimax - ThPimin);               %Pistartup����--N*1����
Pishutdown_wan = (Pishutdown - ThPimin) ./ (ThPimax - ThPimin);             %Pishutdown����--N*1����
% ���������Լ����Ҫ�ı���--end--
Ui0 = full(spones(Thon_off_init));                                   %����������ʼ��/ͣ��״̬
ThPit_wani0 = (Thon_off_init - Ui0 .* ThPimin) ./ (ThPimax - ThPimin);      %���Pit�����ʼֵ
%�������С��/ͣ��Լ����Ҫ�ı���--start--
Ui = max(0,min(ones(N,1) * T,Ui0 .* (ThTime_on_min - ThTime_on_off_init)));                    %--N*1����
Li = max(0,min(ones(N,1) * T,(ones(N,1) - Ui0) .*  (ThTime_off_min + ThTime_on_off_init)));     %--N*1����



%Zit=[];

%--Լ������---
%��ʽԼ��

%������ʼ״̬
Uit_state=[];
Aeq_UC_init=[];
beq_UC_init=[];
for i=1:N
    if(Ui(i) + Li(i) >= 1)
        for t=1:Ui(i)+Li(i)
            Uit_state=sparse(N,T);
            Uit_state(i,t)=1;
            
            cons_UC_init=sparse(1,Value_num);
            cons_UC_init(1,1:N*T)=reshape(Uit_state',1,N*T);
            
            Aeq_UC_init=[Aeq_UC_init;cons_UC_init];
            beq_UC_init=[beq_UC_init;Ui0(i)];
        end
    end
end

Uit=[];
PitWan=[];
Sit=[];
SitWan=[];


%����ƽ��Լ��
Aeq_Power_balance=[];
beq_Power_balance=[];
% cons_Power_balance=sparse(T,Value_num);
% for i=1:N
%     Uit=[Uit,eye(T)*ThPimin(i)];
% end
% for i=1:N
%     PitWan=[PitWan,eye(T)*(ThPimax(i) - ThPimin(i))];
% end
% cons_Power_balance(1:T,1:N*T)=Uit;
% cons_Power_balance(1:T,N*T+1:2*N*T)=PitWan;
% 
% Aeq_Power_balance=cons_Power_balance;
% beq_Power_balance=Dt;
% 
% Uit=[];
% PitWan=[];
% Sit=[];
% SitWan=[];

%ֱ������
Aeq_DCPowerFlow=[];
beq_DCPowerFlow=[];
PG=sparse(1,NodeNum);
PD=sparse(1,NodeNum);
PG(1,Bus_G)=1;
PD(1,Bus_D)=1;

P_index=1;
D_index=1;
for i=1:NodeNum
    if(PG(i)==1&&PD(i)==1)
        uit=sparse(T,N*T);
        PitWan=sparse(T,N*T);
        Seita=sparse(T,NodeNum*T);
        
        uit(1:T,(P_index-1)*T+1:P_index*T)=diag(ThPimin(P_index)*ones(1,T));
        PitWan(1:T,(P_index-1)*T+1:P_index*T)=diag((ThPimax(P_index)-ThPimin(P_index))*ones(1,T));
        coefficient=[];
        for j=1:NodeNum
            coefficient=sparse([coefficient,diag(B(i,j)*ones(1,T))]);
        end
        Seita=-1*coefficient;
        
        Aeq_DCPowerFlow=[Aeq_DCPowerFlow;uit,PitWan,sparse(T,2*N*T+4),Seita];
        beq_DCPowerFlow=[beq_DCPowerFlow;bus_P(:,D_index)];
        P_index=P_index+1;
        D_index=D_index+1;
    end
    if(PG(i)==1&&PD(i)==0)
         uit=sparse(T,N*T);
        PitWan=sparse(T,N*T);
        Seita=sparse(T,NodeNum*T);
        
        uit(1:T,(P_index-1)*T+1:P_index*T)=diag(ThPimin(P_index)*ones(1,T));
        PitWan(1:T,(P_index-1)*T+1:P_index*T)=diag((ThPimax(P_index)-ThPimin(P_index))*ones(1,T));
        coefficient=[];
        for j=1:NodeNum
            coefficient=sparse([coefficient,diag(B(i,j)*ones(1,T))]);
        end
        Seita=-1*coefficient;
        
        Aeq_DCPowerFlow=[Aeq_DCPowerFlow;uit,PitWan,sparse(T,2*N*T+4),Seita];
        beq_DCPowerFlow=[beq_DCPowerFlow;sparse(T,1)];
         P_index=P_index+1;
    end
    if(PG(i)==0&&PD(i)==1)
        Seita=sparse(T,NodeNum*T);
        coefficient=[];
        for j=1:NodeNum
            coefficient=sparse([coefficient,diag(B(i,j)*ones(1,T))]);
        end
        Seita=-1*coefficient;
        
        Aeq_DCPowerFlow=[Aeq_DCPowerFlow;sparse(T,4*N*T+4),Seita];
        beq_DCPowerFlow=[beq_DCPowerFlow;bus_P(:,D_index)];
        D_index=D_index+1;
    end
    if(PG(i)==0&&PD(i)==0)
                Seita=sparse(T,NodeNum*T);
        coefficient=[];
        for j=1:NodeNum
            coefficient=sparse([coefficient,diag(B(i,j)*ones(1,T))]);
        end
        Seita=coefficient;
        
        Aeq_DCPowerFlow=[Aeq_DCPowerFlow;sparse(T,4*N*T+4),Seita];
        beq_DCPowerFlow=[beq_DCPowerFlow;sparse(T,1)];
    end

end

%����ʽԼ��

%����״̬Լ��
Aineq_state_init=[];

for i=1:N
    cons_state_init=sparse(1,Value_num);
    Uit_state=sparse(N,T);
    Sit_state=sparse(N,T);
    
    Uit_state(i,1)=1;
    Sit_state(i,1)=-1;
    
    cons_state_init(1,1:N*T)=reshape(Uit_state',1,N*T);
    cons_state_init(1,2*N*T+1:3*N*T)=reshape(Sit_state',1,N*T);
    
    
    
    Aineq_state_init=[Aineq_state_init;cons_state_init];
end

bineq_state_init=Ui0;

Uit=[];
PitWan=[];
Sit=[];
SitWan=[];


Aineq_state=Aineq_state_init;
for i=1:N
    for t=2:T
        
        Uit_state=sparse(N,T);
        Sit_state=sparse(N,T);
        
        Uit_state(i,t-1)=-1;
        Uit_state(i,t)=1;
        Sit_state(i,t)=-1;
        
        cons_state_init=sparse(1,Value_num);
        cons_state_init(1,1:N*T)=reshape(Uit_state',1,N*T);
        cons_state_init(1,2*N*T+1:3*N*T)=reshape(Sit_state',1,N*T);
        Aineq_state=[Aineq_state;cons_state_init];
    end
end
bineq_state=[bineq_state_init;sparse(N*(T-1),1)];

Uit=[];
PitWan=[];
Sit=[];
SitWan=[];


%Sit����Լ��
bineq_startup_cost=[];
Aineq_startup_cost=[];

for i = 1:N
    for t = 1:T
        Uit_state=sparse(N,T);
        Sit_state=sparse(N,T);
        SitWan_state=sparse(N,T);
        
        Uit_state(i,max(t - ThTime_off_min(i) - ThCold_time_start(i) - 1,1):t - 1)=1;
        Sit_state(i,t)=1;
        SitWan_state(i,t)=-1;
        
        cons_startup_cost=sparse(1,Value_num);
        cons_startup_cost(1,1:N*T)=-1*(ThCold_cost_start(i) - ThHot_cost_start(i))*reshape(Uit_state',1,N*T);
        cons_startup_cost(1,2*N*T+1:3*N*T)=(ThCold_cost_start(i) - ThHot_cost_start(i))*reshape(Sit_state',1,N*T);
        cons_startup_cost(1,3*N*T+1:4*N*T)=reshape(SitWan_state',1,N*T);
        
        
        Aineq_startup_cost=[Aineq_startup_cost;cons_startup_cost];
        
        if t - ThTime_off_min(i) - ThCold_time_start(i) - 1 <= 0 && max(0,-ThTime_on_off_init(i)) < ...
                abs(t - ThTime_off_min(i) - ThCold_time_start(i) - 1) + 1
            
            bineq_startup_cost=[bineq_startup_cost;(ThCold_cost_start(i) - ThHot_cost_start(i))*1];
        else
            bineq_startup_cost=[bineq_startup_cost;(ThCold_cost_start(i) - ThHot_cost_start(i))*0];
            
        end
    end
end

for i = 1:N
    for t = 1:T
        SitWan_state=sparse(N,T);
        
        SitWan_state(i,t)=-1;
        
        cons_startup_cost=sparse(1,Value_num);
        cons_startup_cost(1,3*N*T+1:4*N*T)=reshape(SitWan_state',1,N*T);
        
        
        Aineq_startup_cost=[Aineq_startup_cost;cons_startup_cost];
        bineq_startup_cost=[bineq_startup_cost;0];
    end
end

Uit=[];
PitWan=[];
Sit=[];
SitWan=[];


%���������Լ��
% 0 <= ThPit_wan
% Aineq_Pwan=[zeros(N*T,N*T),-1*eye(N*T),zeros(N*T,2*N*T)];
% bineq_Pwan=zeros(N*T,1);
%ThPit_wan <= Uit
Aineq_Pwan=[];
bineq_Pwan=[];
cons_Pwan=sparse(N*T,Value_num);
cons_Pwan(1:N*T,1:N*T)=-1*eye(N*T);
cons_Pwan(1:N*T,N*T+1:2*N*T)=eye(N*T);



Aineq_Pwan=[Aineq_Pwan;cons_Pwan];
bineq_Pwan=[bineq_Pwan;sparse(N*T,1)];

Uit=[];
PitWan=[];
Sit=[];
SitWan=[];


%ֱ������
Aineq_DCPowerFlow=[];
bineq_DCPowerFlow=[];
for index=1:length(branchI)
    Seita_i=branchI(index);
    Seita_j=branchJ(index);
    Seita=sparse(T,NodeNum*T);
    
    Seita(1:T,(Seita_i-1)*T+1:Seita_i*T)=diag((1/branchX(index))*ones(1,T));
    Seita(1:T,(Seita_j-1)*T+1:Seita_j*T)=diag(-1*(1/branchX(index))*ones(1,T));
    
    Aineq_DCPowerFlow=sparse([Aineq_DCPowerFlow;sparse(T,4*N*T+4),Seita]);
    bineq_DCPowerFlow=[bineq_DCPowerFlow;branchP(index)*ones(T,1)];
    
    Aineq_DCPowerFlow=sparse([Aineq_DCPowerFlow;sparse(T,4*N*T+4),-1*Seita]);
    bineq_DCPowerFlow=[bineq_DCPowerFlow;branchP(index)*ones(T,1)];
    
end

%���������Լ��
%ThPit_wan(:,1) - ThPit_wani0 <= Uit(:,1) .* Piup_wan + Sit(:,1) .* (Pistartup_wan - Piup_wan)
Aineq_ramp_up=[];

for i=1:N
    Ui1_state=sparse(N,T);
    Si1_state=sparse(N,T);
    Pi1Wan=sparse(N,T);
    
    Ui1_state(i,1)=-1;
    Si1_state(i,1)=-1;
    Pi1Wan(i,1)=1;
    
    cons_ramp_up=sparse(1,Value_num);
    cons_ramp_up(1,1:N*T)=Piup_wan(i)*reshape(Ui1_state',1,N*T);
    cons_ramp_up(1,N*T+1:2*N*T)=reshape(Pi1Wan',1,N*T);
    cons_ramp_up(1,2*N*T+1:3*N*T)=(Pistartup_wan(i) - Piup_wan(i))*reshape(Si1_state',1,N*T);
    
    
    Aineq_ramp_up=[Aineq_ramp_up;cons_ramp_up];
end
bineq_ramp_up=ThPit_wani0;


%ThPit_wan(:,2:T) - ThPit_wan(:,1:T-1) <= Uit(:,2:T) .* (Piup_wan * ones(1,T-1)) + Sit(:,2:T) .* ((Pistartup_wan - Piup_wan) * ones(1,T-1))
Uit_state=[];
Uit=[];
for i=1:N
    for t=2:T
        Uit_state=sparse(N,T);
        Uit_state(i,t)=-1;
        Uit=[Uit;Piup_wan(i)*reshape(Uit_state',1,N*T)];
        
    end
end

PitWan=[];
PitWan_part=[];
for i=1:N
    for t=2:T
        PitWan_part=sparse(N,T);
        PitWan_part(i,t-1)=-1;
        PitWan_part(i,t)=1;
        PitWan=[PitWan;reshape(PitWan_part',1,N*T)];
    end
end

Sit_state=[];
Sit=[];
for i=1:N
    for t=2:T
        Sit_state=sparse(N,T);
        Sit_state(i,t)=-1;
        Sit=[Sit;(Pistartup_wan(i) - Piup_wan(i))*reshape(Sit_state',1,N*T)];
    end
end
cons_ramp_up=sparse(N*(T-1),Value_num);
cons_ramp_up(1:N*(T-1),1:N*T)=Uit;
cons_ramp_up(1:N*(T-1),N*T+1:2*N*T)=PitWan;
cons_ramp_up(1:N*(T-1),2*N*T+1:3*N*T)=Sit;



Aineq_ramp_up=[Aineq_ramp_up;cons_ramp_up];
bineq_ramp_up=[bineq_ramp_up;sparse(N*(T-1),1)];

Uit=[];
PitWan=[];
Sit=[];
SitWan=[];


%���������Լ��
%ThPit_wani0 - ThPit_wan(:,1) <= Ui0 .* Pishutdown_wan + (Sit(:,1) - Uit(:,1)) .*
Aineq_ramp_down=[];
for i=1:N
    Ui1_state=sparse(N,T);
    Si1_state=sparse(N,T);
    Pi1Wan=sparse(N,T);
    
    
    Ui1_state(i,1)=1;
    Si1_state(i,1)=-1;
    Pi1Wan(i,1)=-1;
    
    cons_ramp_down=sparse(1,Value_num);
    cons_ramp_down(1,1:N*T)=(Pishutdown_wan(i) - Pidown_wan(i))*reshape(Ui1_state',1,N*T);
    cons_ramp_down(1,N*T+1:2*N*T)=reshape(Pi1Wan',1,N*T);
    cons_ramp_down(1,2*N*T+1:3*N*T)=(Pishutdown_wan(i) - Pidown_wan(i))*reshape(Si1_state',1,N*T);
    
    Aineq_ramp_down=[Aineq_ramp_down;cons_ramp_down];
end
bineq_ramp_down=Pishutdown_wan.*Ui0-ThPit_wani0;
%ThPit_wan(:,1:T-1) - ThPit_wan(:,2:T) <= Uit(:,1:T-1) .* (Pishutdown_wan * ones(1,T-1)) + (Sit(:,2:T) - Uit(:,2:T)) .* ((Pishutdown_wan - Pidown_wan) * ones(1,T-1))
Uit_state=[];
Uit_part=[];
for i=1:N
    for t=2:T
        Uit_state=sparse(N,T);
        Uit_state(i,t-1)=Pishutdown_wan(i)*-1;
        Uit_state(i,t)=(Pishutdown_wan(i) - Pidown_wan(i))*1;
        Uit_part=[Uit_part;reshape(Uit_state',1,N*T)];
        
    end
end

PitWan=[];
PitWan_part=[];
for i=1:N
    for t=2:T
        PitWan=sparse(N,T);
        PitWan(i,t-1)=1;
        PitWan(i,t)=-1;
        PitWan_part=[PitWan_part;reshape(PitWan',1,N*T)];
    end
end

Sit_state=[];
Sit_part=[];
for i=1:N
    for t=2:T
        Sit_state=sparse(N,T);
        Sit_state(i,t)=(Pishutdown_wan(i) - Pidown_wan(i))*-1;
        Sit_part=[Sit_part;reshape(Sit_state',1,N*T)];
    end
end
cons_ramp_down=sparse(N*(T-1),Value_num);
cons_ramp_down(1:N*(T-1),1:N*T)=Uit_part;
cons_ramp_down(1:N*(T-1),N*T+1:2*N*T)=PitWan_part;
cons_ramp_down(1:N*(T-1),2*N*T+1:3*N*T)=Sit_part;
Aineq_ramp_down=[Aineq_ramp_down;cons_ramp_down];


bineq_ramp_down=[bineq_ramp_down;sparse(N*(T-1),1)];

Uit=[];
PitWan=[];
Sit=[];
SitWan=[];


%�������С����/ͣ��ʱ��
Aineq_upORdowm=[];
bineq_upORdowm=[];
for i = 1:N
    for t = Ui(i) + 1:T
        Uit_state=sparse(N,T);
        Sit_state=sparse(N,T);
        
        Uit_state(i,t)=-1;
        Sit_state(i,max(0,t - ThTime_on_min(i)) + 1:t)=1;
        cons_upORdowm=sparse(1,Value_num);
        cons_upORdowm(1,1:N*T)=reshape(Uit_state',1,N*T);
        cons_upORdowm(1,2*N*T+1:3*N*T)=reshape(Sit_state',1,N*T);
        
        Aineq_upORdowm=[Aineq_upORdowm;cons_upORdowm];
        bineq_upORdowm=[bineq_upORdowm;0];
    end
end

Uit=[];
PitWan=[];
Sit=[];
SitWan=[];

for i = 1:N
    for t = Li(i) + 1:T
        if t - ThTime_off_min(i) <= 0
            Sit_state=sparse(N,T);
            Sit_state(i,max(0,t - ThTime_off_min(i)) + 1:t)=1;
            cons_upORdowm=sparse(1,Value_num);
            cons_upORdowm(1,2*N*T+1:3*N*T)=reshape(Sit_state',1,N*T);
            
            
            
            Aineq_upORdowm=[Aineq_upORdowm;cons_upORdowm];
            bineq_upORdowm=[bineq_upORdowm;1 - Ui0(i)];
        else
            Uit_state=sparse(N,T);
            Sit_state=sparse(N,T);
            Uit_state(i,max(0,t - ThTime_off_min(i)))=1;
            Sit_state(i,max(0,t - ThTime_off_min(i)) + 1:t)=1;
            cons_upORdowm=sparse(1,Value_num);
            cons_upORdowm(1,1:N*T)=reshape(Uit_state',1,N*T);
            cons_upORdowm(1,2*N*T+1:3*N*T)=reshape(Sit_state',1,N*T);
            
            Aineq_upORdowm=[Aineq_upORdowm;cons_upORdowm];
            bineq_upORdowm=[bineq_upORdowm;1];
        end
    end
end

Uit=[];
PitWan=[];
Sit=[];
SitWan=[];


% ��ת�ȱ���Լ��
Uit_state=[];
for i=1:N
    Uit_state=[Uit_state,-1*eye(T)*ThPimax(i)];
end
cons_spinning_reserve_require=sparse(T,Value_num);
cons_spinning_reserve_require(1:T,1:N*T)=Uit_state;

Aineq_spinning_reserve_require=cons_spinning_reserve_require;
bineq_spinning_reserve_require=-1*(Dt + Spin);


%̼��������Լ��
Aineq_trade_constraint=[];
bineq_trade_constraint=[];

Aineq_emission_buy_up=sparse(1,Value_num);
Aineq_emission_buy_up(1,4*N*T+1)=1;
Aineq_emission_buy_up(1,4*N*T+3)=-1*emmission_buy_max;
bineq_emission_buy_up=0;

Aineq_emission_sell_up=sparse(1,Value_num);
Aineq_emission_sell_up(1,4*N*T+2)=1;
Aineq_emission_sell_up(1,4*N*T+4)=-1*emmission_sell_max;
bineq_emission_sell_up=0;

Aineq_sell_buy_constraint=sparse(1,Value_num);
Aineq_sell_buy_constraint(1,4*N*T+3)=1;
Aineq_sell_buy_constraint(1,4*N*T+4)=1;
bineq_sell_buy_constraint=1;

Aineq_trade_constraint=[Aineq_emission_sell_up;Aineq_emission_buy_up;Aineq_sell_buy_constraint];
bineq_trade_constraint=[bineq_emission_sell_up;bineq_emission_buy_up;bineq_sell_buy_constraint];

%̼�ŷ�
Q_emission=sparse(Value_num,Value_num);
l_emission=sparse(1,Value_num);
r_emission=E0;

Pwan_emission=sparse(N*T,Value_num);
Pwan_emission(1:N*T,N*T+1:2*N*T)=diag(reshape(repmat(c,1,T)',N*T,1));
Q_emission=sparse(Value_num,Value_num);
Q_emission(N*T+1:2*N*T,:)=Pwan_emission;

l_emission=sparse(Value_num,1);
l_emission(1:N*T,1)=reshape(repmat(a,1,T)',N*T,1);
l_emission(N*T+1:2*N*T,1)=reshape(repmat(b,1,T)',N*T,1);
l_emission(4*N*T+1,1)=-1;
l_emission(4*N*T+2,1)=1;





%Ŀ�꺯��Լ��--start--
%���Pit����Լ��

%Ŀ�꺯��Լ��--end--

%Ŀ�꺯��--start--
% Pwan_tripple_coefficent=sparse(N*T,Value_num);
% Pwan_tripple_coefficent(1:N*T,N*T+1:2*N*T)=diag(reshape(repmat(Deta_wan,1,T)',N*T,1));
% D=sparse(Value_num,Value_num);
% D(N*T+1:2*N*T,:)=Pwan_tripple_coefficent;
Pwan_coefficient=sparse(N*T,Value_num);
Pwan_coefficient(1:N*T,N*T+1:2*N*T)=2*diag(reshape(repmat(Gama_wan,1,T)',N*T,1));
H=sparse(Value_num,Value_num);
H(N*T+1:2*N*T,:)=Pwan_coefficient;
f=sparse(Value_num,1);
f(1:N*T,1)=reshape(repmat(Alpha_wan,1,T)',N*T,1);
f(N*T+1:2*N*T,1)=reshape(repmat(Beta_wan,1,T)',N*T,1);
f(2*N*T+1:3*N*T,1)=reshape(repmat(ThHot_cost_start,1,T)',N*T,1);
f(3*N*T+1:4*N*T,1)=ones(N*T,1);
f(4*N*T+1,1)=price_buy;
f(4*N*T+2,1)=-1*price_sell;
location_Eb=4*N*T+1;
location_Es=4*N*T+2;


Aineq=[Aineq_state;Aineq_startup_cost;Aineq_Pwan;Aineq_ramp_up;Aineq_ramp_down;Aineq_upORdowm;Aineq_spinning_reserve_require;Aineq_DCPowerFlow;Aineq_trade_constraint];
bineq=[bineq_state;bineq_startup_cost;bineq_Pwan;bineq_ramp_up;bineq_ramp_down;bineq_upORdowm;bineq_spinning_reserve_require;bineq_DCPowerFlow;bineq_trade_constraint];
Aeq=[Aeq_UC_init;Aeq_Power_balance;Aeq_DCPowerFlow];
beq=[beq_UC_init;beq_Power_balance;beq_DCPowerFlow];
Q=Q_emission;
l=l_emission;
r=r_emission;
lb=sparse(Value_num-T*NodeNum,1);
lb=[lb;-inf*ones(T*NodeNum,1)];
ub=inf*ones(Value_num,1);
ub(1:N*T,1)=ones(N*T,1);
ub(N*T+1:2*N*T,1)=ones(N*T,1);
ub(2*N*T+1:3*N*T,1)=ones(N*T,1);
ub(4*N*T+1,1)=inf;
ub(4*N*T+2,1)=inf;
ub(4*N*T+3,1)=1;
ub(4*N*T+4,1)=1;

ctype='';
ctype(1,1:Value_num)='C';
ctype(1,1:N*T)='B';
ctype(1,2*N*T+1:3*N*T)='B';
ctype(1,4*N*T+3:4*N*T+4)='B';

% obj_function='';
% for i=1:size(ctype,2)
%     str_function=strcat(num2str(f(i)),'*x(',num2str(i),')');
%     obj_function=strcat(obj_function,str_function,'+');
% end
% for i=1:size(ctype,2)
%     str_function=strcat(num2str(H(i,i)),'*x(',num2str(i),')^2');
%     obj_function=strcat(obj_function,str_function,'+');
% end
% for i=1:size(ctype,2)
%     str_function=strcat(num2str(D(i,i)),'*x(',num2str(i),')^3');
%     if(i==size(ctype,2))
%         obj_function=strcat(obj_function,str_function);
%     else
%         obj_function=strcat(obj_function,str_function,'+');
%     end
% end
% eval(strcat('obj_function=@(x)',obj_function));
% 
% CET_function='';
% for i=1:size(ctype,2)
%     str_function=strcat(num2str(l(i)),'*x(',num2str(i),')');
%     CET_function=strcat(CET_function,str_function,'+');
% end
% for i=1:size(ctype,2)
%     str_function=strcat(num2str(Q(i,i)),'*x(',num2str(i),')^2');
%      if(i==size(ctype,2))
%         CET_function=strcat(CET_function,str_function);
%     else
%         CET_function=strcat(CET_function,str_function,'+');
%      end
% end
% eval(strcat('CET_function=@(x)',CET_function));

% model.D=D;
model.H=H;
model.f=f;
model.Aineq=Aineq;
model.bineq=bineq;
model.Aeq=Aeq;
model.beq=beq;
model.l=l;
model.Q=Q;
model.r=r;
model.lb=lb;
model.ub=ub;
model.ctype=ctype;
model.location_Eb=location_Eb;
model.location_Es=location_Es;
model.location_uit=uit_location;
model.SR_Aineq=Aineq_spinning_reserve_require;
model.SR_bineq=bineq_spinning_reserve_require;
model.minOnorOff_Aineq=Aineq_upORdowm;
model.minOnorOff_bineq=bineq_upORdowm;
% model.f_funtion=obj_function;
% model.cet_function=CET_function;
end




