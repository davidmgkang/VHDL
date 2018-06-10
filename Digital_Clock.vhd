Library ieee;
Use ieee.std_logic_1164.all;
Use ieee.std_logic_unsigned.all;
Use ieee.numeric_std.all;

entity Digital_Clock is
	Port(
			SEG0 : out std_logic_vector(7 downto 0);
			SEG1 : out std_logic_vector(7 downto 0);
			SEG2 : out std_logic_vector(7 downto 0);
			SEG3 : out std_logic_vector(7 downto 0);
			clk : in std_logic;										--CLK:50Mhz
			sw_12_24 : in std_logic;
			sw_alarm	: in std_logic; --sw8
			sw_setting: in std_logic; --sw7
			sw_stop: in std_logic;	--sw6
			
			sw_ma_btn	: in std_logic;
			sw_pl_btn	: in std_logic;
			
			sw_stop_lap	: in std_logic; -- lap_switch
		--	sw_plma_btn:	in std_logic;
			Btn : in std_logic_vector(2 downto 0);
			sw_year_set : in std_logic;	
			sw_day_set	: in std_logic;	 
			sw_stop_start : in std_logic;
			sw_time_set : in std_logic
	);
end Digital_Clock;

architecture arc of Digital_Clock is

	signal ck10ms : integer range 0 to 250001;				--0.01sec
	signal ck100ms : integer range 0 to 2500001;				--0.1sec
	signal ck1s : integer range 0 to 25000001;				--1sec
	signal mingu				  : std_logic_vector(2 downto 0);
	signal ck1ms	:	integer range 0 to 25001;
	signal Chk_Btn0	: integer range 0 to 5;			--Check for Btn0 at '0'
	
	signal	btn_ck1	: std_logic_vector(2 downto 0) := "000";
	signal	btn_ck2	: std_logic_vector(2 downto 0) := "000";
	signal	btn_ck3	: std_logic_vector(2 downto 0) := "000";
	signal	btn_ck4	: std_logic_vector(2 downto 0) := "000";
	signal	btn_ck5	: std_logic_vector(2 downto 0) := "000";
	signal	btn_ck6	: std_logic_vector(2 downto 0) := "000";
	signal	btn_ck7	: std_logic_vector(2 downto 0) := "000";
	
	signal	bagic_pulse : std_logic;
	
	--------------일반 시계 모드 정의------------ 
	signal	mm_second:	integer range 0 to 9 := 0;
	signal	m_second	:	integer range 0 to 9 := 0;
	signal	half_sec_flag : integer range 0 to 1 := 0;
	signal	second	:	integer range 0 to 59 := 0;
	signal	minute	:	integer range 0 to 59 := 59;
	signal	hour		:	integer range 0 to 23 := 23;
	signal	hour_ch	:	integer range 0 to 23;
	signal	day		:	integer range 1 to 31 := 27;
	signal	month		:	integer range 1 to 12 := 02;
	signal	year		:	integer range 1 to 9999 := 2012;
	-------------시계 설정 모드 정의---------- 
	signal	minute_set	:	integer range 0 to 59 := 59;
	signal	hour_set		:	integer range 0 to 23 := 23;
	signal	day_set		:	integer range 0 to 31 := 27;
	signal	month_set	:	integer range 0 to 12 := 02;
	signal	year_set		:	integer range 1 to 9999 := 2012;
	
	signal	day_set_constant	:	integer range 28 to 31;	
	signal	month_temp	:	integer range 0 to 12;
	signal	day_temp :integer range 0 to 31;	
	-------------알람 정의------------
	signal	alarm_minute_set	:	integer range 0 to 59 := 01;
	signal	alarm_hour_set		:	integer range 0 to 23 := 00;
	--------------스탑워치-------------
	signal 	stwa_sec		:	integer range 0 to 99;
	signal	stwa_100ms		:	integer range 0 to 9;
	signal	stwa_10ms		:	integer range 0 to 9;
	
	signal	stwa_100ms_lap	:	integer range 0 to 99;
	signal	stwa_10ms_lap	:	integer range 0 to 9;
	signal	stwa_sec_lap	:	integer range 0 to 9;
	
	---------------------Segment Array---------------------
	type segment_dec is array (0 to 10) of std_logic_vector(7 downto 0);		--7segment(0~9) and no_display
	constant dis_number : segment_dec
	:=("11000000","11111001","10100100","10110000","10011001",
		"10010010","10000010","11011000","10000000","10010000","11111111");
		
	signal	display_fg : integer range 0 to 1 := 0;
	---------------------state-------------------------------
		type state_sel is (clock, setting, alarm, stop, ch12to24);
		signal current_state : state_sel;
		
--		type arith_state is (plus, minus);
--		signal current_arith_state	:	arith_state	:= plus;

		type set_state is (yearr, monthh, dayy, hourr, minutee);
		signal current_set_state, next_state	:	set_state;
		
		
		
begin
--------------STATE_Define--------------
 process(mingu(0), mingu(1), current_state, second, minute, hour, month, hour_ch, display_fg, day_set_constant, day_set)
	begin
		if(display_fg = 1) then
			SEG0	<= "11111111";
			SEG1	<= "11111111";
			SEG2	<= "11111111";
			SEG3 	<= "11111111";
		elsif(mingu(0)'event and mingu(0) ='0' and (display_fg = 0) ) then
			case current_state is
				when clock 	 =>
					SEG0	<= dis_number(minute rem 10);
					SEG1	<= dis_number(minute/10);
					SEG2 	<= dis_number(hour rem 10);
					if((second rem 2)=0) then				--flash hour dot
						SEG2(7) <='1';
					else
						SEG2(7) <='0';
					end if;
					
					SEG3	<= dis_number(hour/10);
					
					if(btn(0)='0') then			--Date Display
						SEG0	<= dis_number(day rem 10);
						SEG1	<= dis_number(day/10);
						SEG2	<= dis_number(month rem 10);
						SEG3	<= dis_number(month/10);
					elsif(btn(2)='0') then		--Year Display
						SEG0	<= dis_number(year rem 10);
						SEG1	<= dis_number((year/10) rem 10);
						SEG2	<= dis_number((year/100) rem 10);
						SEG3	<= dis_number(year/1000);					
					
					elsif(btn(1)='0') then	--sec display				
						SEG0	<= dis_number(second rem 10);
						SEG1	<= dis_number(second/10);
						SEG2	<= "01111111";
						SEG3 	<= "11111111";
					else
						
					end if;	
				
				when ch12to24=>
					case hour is
						when 13 => hour_ch <= 1;
						when 14 => hour_ch <= 2;
						when 15 => hour_ch <= 3;
						when 16 => hour_ch <= 4;
						when 17 => hour_ch <= 5;
						when 18 => hour_ch <= 6;
						when 19 => hour_ch <= 7;
						when 20 => hour_ch <= 8;
						when 21 => hour_ch <= 9;
						when 22 => hour_ch <= 10;
						when 23 => hour_ch <= 11;
					--	when 24 => hour_ch <= 0;
						when others => hour_ch<= hour;
					end case;
					
					SEG0	<= dis_number(minute rem 10);
					SEG1	<= dis_number(minute/10);
					SEG2 	<= dis_number(hour_ch rem 10);
					if((second rem 2)=0) then				--flash hour dot
						SEG2(7) <='1';
					else
						SEG2(7) <='0';
					end if;
					
					SEG3	<= dis_number(hour_ch/10);
					
					if(btn(1)='0') then			--Date Display
						SEG0	<= dis_number(day rem 10);
						SEG1	<= dis_number(day/10);
						SEG2	<= dis_number(month rem 10);
						SEG3	<= dis_number(month/10);
					elsif(btn(2)='0') then		--Year Display
						SEG0	<= dis_number(year rem 10);
						SEG1	<= dis_number((year/10) rem 10);
						SEG2	<= dis_number((year/100) rem 10);
						SEG3	<= dis_number(year/1000);					
					
					elsif(btn(0)='0') then	--sec display				
						SEG0	<= dis_number(second rem 10);
						SEG1	<= dis_number(second/10);
						SEG2	<= "01111111";
						SEG3 	<= "11111111";
					else
						
					end if;	
					
				when Setting =>
				
					if(current_set_state = yearr) then
						SEG0	<= dis_number(year rem 10);
						SEG1	<= dis_number((year/10) rem 10);
						SEG2	<= dis_number((year/100) rem 10);
						SEG3	<= dis_number(year/1000);
						
					elsif(current_set_state = monthh) then												
								
						SEG0	<= dis_number(10);--dis_number(day rem 10);
						SEG1	<= dis_number(10);--dis_number(day/10);
						SEG2	<= dis_number(month rem 10);
						SEG3	<= dis_number(month/10);
						
					elsif(current_set_state = dayy)then
						SEG0	<= dis_number(day rem 10);
						SEG1	<= dis_number(day/10);
						SEG2 	<= dis_number(10);--dis_number(hour rem 10);
						SEG3	<= dis_number(10);--dis_number(hour/10);
						
					elsif(current_set_state = hourr)then
						SEG0	<= dis_number(10);--dis_number(minute rem 10);
						SEG1	<= dis_number(10);--dis_number(minute/10);
						SEG2 	<= dis_number(hour rem 10);
						SEG3	<= dis_number(hour/10);
						
					elsif(current_set_state = minutee)then
						SEG0	<= dis_number(minute rem 10);
						SEG1	<= dis_number(minute/10);
						SEG2 	<= dis_number(10);--dis_number(hour rem 10);
						SEG3	<= dis_number(10);--dis_number(hour/10);
					end if;
					
				when Alarm 	 => 
					SEG0	<=	dis_number(alarm_minute_set rem 10);
					SEG1 	<= dis_number(alarm_minute_set/10);
					SEG2	<= dis_number(alarm_hour_set rem 10);
					SEG3	<= dis_number(alarm_hour_set/10);
					
				when Stop  =>
					if(sw_stop_lap='1') then
						SEG0	<=	dis_number(stwa_10ms_lap);
						SEG1 	<= dis_number(stwa_100ms_lap);
						if((second rem 2)=0) then				--flash hour dot
							SEG2(7) <='1';
						else
							SEG2(7) <='0';
						end if;
						SEG2	<= dis_number(stwa_sec_lap rem 10);
						SEG3	<= dis_number(stwa_sec_lap/10);
						
					else
						SEG0	<=	dis_number(stwa_10ms);
						SEG1 	<= dis_number(stwa_100ms);
						if((second rem 2)=0) then				--flash hour dot
							SEG2(7) <='1';
						else
							SEG2(7) <='0';
						end if;
						SEG2	<= dis_number(stwa_sec rem 10);
						SEG3	<= dis_number(stwa_sec/10);
					end if;
			end case;
		else
		end if;
	end process;
	
--------------STATE_Transition Condition--------------
	seq : process(mingu(2), btn, sw_alarm,sw_stop,sw_setting)
	begin
		if(mingu(2)'event and mingu(2)='1') then
			if(sw_alarm ='1') then
				current_state <= alarm;
			elsif(sw_12_24 = '1') then
				current_state <= ch12to24;
			elsif(sw_setting ='1') then
				current_state <= setting;
			elsif(sw_stop ='1') then
				current_state <= stop;
			else
				current_state <= clock;
			end if;
		end if;
		
		
	end process;
	
	
	process(mingu(2), btn, sw_alarm,sw_stop,sw_setting)
	begin
		if(mingu(2)'event and mingu(2)='1') then
			case current_set_state is
				when yearr =>
					next_state<= monthh;
				when monthh =>
					next_state<= dayy;
				when dayy =>
					next_state<= hourr;
				when hourr=>
					next_state<= minutee;
				when minutee=>
					next_state<= yearr;
			end case;
		end if;
	end process;

process(mingu(2), btn, sw_alarm,sw_stop,sw_setting)
	begin
		if(sw_setting='1')then
			if(mingu(2)'event and mingu(2)='1') then
				if(sw_year_set = '1') then
					current_set_state <= yearr;
				elsif(sw_year_set ='0' and btn(0)='0') then
					current_set_state <= next_state;
				end if;
			end if;
		end if;
	end process;
	
----------------소스 클럭에 대한 정의----------------
	process(clk)
	begin
		if(clk'event and clk = '1') then
			ck10ms <= ck10ms + 1;
			ck100ms <= ck100ms + 1;
			ck1s <= ck1s + 1;
			ck1ms <= ck1s+1;
		
			if(ck1ms >= 25000) then
				ck1ms <= 0;
				bagic_pulse <= not bagic_pulse;				--0.001sec clock
			end if;
			
			if(ck10ms >= 250000) then							--0.01Sec Clock
				ck10ms <= 0;
				mingu(0) <= not mingu(0);
			end if;

			if(ck100ms >= 2500000) then						--0.1Sec Clock
				ck100ms <= 0;
				mingu(1) <= not mingu(1);
			end if;
			
			if(ck1s >= 25000000) then						--1Sec Clock
				ck1s <= 0;
				mingu(2) <= not mingu(2);
			end if;
		end if;
	end process;
-------------------일반 시계 모드 -------------------
	process
	(mingu(0), second, minute, hour, day, month, month_set, year, year_set, current_state, day_set, day_set_constant,btn)
	begin
		if(mingu(0)'event and mingu(0)='1') then
			mm_second <= mm_second +1;
			if(mm_second =9) then
				m_second <= m_second + 1; 
				mm_second <= 0;
				if(m_second=4) then
					half_sec_flag <= 1;
				end if;
				if(m_second=9) then
					half_sec_flag <= 0;
					m_second <=0;
					second <= second +1;
					if(second=59) then
						second <= 0;
						minute <= minute +1;
						if(minute=59) then
							minute <= 0;
							hour <= hour +1;
							if(hour=23) then
								hour <= 0;
								day <= day + 1;
								if( month = 1 ) then				--January
									if(day = 31) then
										month 	<= month + 1;
										day		<= 1;
									end if;
								elsif( month = 2) then				--February
									if( year rem 4 = 0 ) then
										if( day = 29 ) then
											month 	<= month + 1;
											day		<= 1;
										end if;
									else
										if( day = 28 ) then
											month 	<= month + 1;
											day		<= 1;
										end if;
									end if;
								elsif( month = 3) then				--March
									if(day = 31) then
										month 	<= month + 1;
										day		<= 1;
									end if;
								elsif( month = 4) then				--April
									if(day = 30) then
										month 	<= month + 1;
										day		<= 1;
									end if;
								elsif( month = 5 ) then				--May
									if(day = 31) then
										month 	<= month + 1;
										day		<= 1;
									end if;
								elsif( month = 6 ) then				--June
									if(day = 30) then
										month 	<= month + 1;
										day		<= 1;
									end if;
								elsif( month = 7 ) then				--July
									if(day = 31) then
										month 	<= month + 1;
										day		<= 1;
									end if;
								elsif( month = 8 ) then				--August
									if(day = 31) then
										month 	<= month + 1;
										day		<= 1;
									end if;
								elsif( month = 9 ) then				--September
									if(day = 30) then
										month 	<= month + 1;
										day		<= 1;
									end if;
								elsif( month = 10 ) then			--October 
									if(day = 31) then
										month 	<= month + 1;
										day		<= 1;
									end if;
								elsif( month = 11 ) then			--November
									if(day = 30) then
										month 	<= month + 1;
										day		<= 1;
									end if;
								elsif( month > 12 ) then			--December 
									if(day = 31) then
										month 	<= 1;
										day		<= 1;
										year	<= year +1;
									end if;
								end if;
							end if;
						end if;
					end if;
				end if;
			end if;
			
			if(current_state = setting) then
				
				case current_set_state is
					when yearr=>	
						if(btn(2) = '0' and btn_ck1(2)='0') then
							btn_ck1(2) <= '1';
							year_set	<= year_set - 1 ;
						end if;
							
						if(btn(1) = '0' and btn_ck1(1)='0') then
							btn_ck1(1) <= '1';
							year_set	<= year_set + 1 ;
						end if;	
					
						if(year_set = 0) then
							year_set <= 1;
						end if;
						
						if(year_set = 9999) then
								year_set <= 9999;
						end if;
						
						year	<= year_set;
						
				
						if(btn_ck1(2)='1' and btn(2)='1') then
							btn_ck1(2)<='0';
						end if;

						if(btn_ck1(1)='1' and btn(1)='1') then
							btn_ck1(1)<='0';
						end if;
					
					when monthh =>
					
						if(btn(2) = '0' and btn_ck2(2)='0') then
							btn_ck2(2)<= '1';
							month_set <= month_set - 1;
						end if;
						
						if(btn(1) = '0' and btn_ck2(1)='0') then
							btn_ck2(1)<='1';
							month_set	<= month_set + 1;
						end if;
						
						if(month_set = 12) then
							month_set <= 0;
						end if;
					
							
						month		<= month_set+1;
						
						if(btn_ck2(2)='1' and btn(2)='1') then
							btn_ck2(2)<='0';
						end if;
				
					
						if(btn_ck2(1)='1' and btn(1)='1') then
							btn_ck2(1)<='0';
						end if;
						
					when dayy=>
					
						if(btn(2) = '0' and btn_ck3(2)='0') then
							btn_ck3(2)<='1';
							day_set	<= day_set - 1;
						end if;
						
						if(btn(1) = '0' and btn_ck3(1)='0') then
							btn_ck3(1)<='1';
							day_set	<= day_set + 1;
						end if;
						
						if(btn_ck3(2)='1' and btn(2)='1') then
							btn_ck3(2)<='0';
						end if;				
					
						if(btn_ck3(1)='1' and btn(1)='1') then
							btn_ck3(1)<='0';
						end if;				
					
						case month is
							when 1 => day_set_constant <= 31;
							when 2 =>
								if(year rem 4 =0) then
									day_set_constant <= 29;
								else
									day_set_constant <= 28;
								end if;
							when 3 => day_set_constant <= 31;
							when 4 => day_set_constant <= 30;
							when 5 => day_set_constant <= 31;
							when 6 => day_set_constant <= 30;
							when 7 => day_set_constant <= 31;
							when 8 => day_set_constant <= 31;
							when 9 => day_set_constant <= 30;
							when 10 => day_set_constant <= 31;
							when 11 => day_set_constant <= 30;
							when 12 => day_set_constant <= 31;
						end case;
						
						if(day_set = (day_set_constant-1)) then
							day_set <= 0;
						end if;
						
						day	<= day_set+1;
				
				when hourr =>
					
					if(btn(2) = '0' and btn_ck4(2)='0') then
						btn_ck4(2)<='1';
						hour_set <= hour_set - 1;
					end if;
				
					if(btn(1) = '0' and btn_ck4(1) ='0') then
						btn_ck4(1)<='1';
						hour_set	<= hour_set + 1;
					end if;
				
					if(btn_ck4(2)='1' and btn(2)='1') then
						btn_ck4(2)<='0';
					end if;
					
					if(btn_ck4(1)='1' and btn(1)='1') then
						btn_ck4(1)<='0';
					end if;
				
					if(hour_set = 23) then
						hour_set <= 0;
					end if;
					
					hour	<= hour_set+1;
				
				when minutee =>
					
					if(btn(2) = '0' and btn_ck5(2)='0') then
						btn_ck5(2)<='1';
						minute_set <= minute_set - 1;
					end if;
				
					if(btn(1) = '0' and btn_ck5(1) ='0') then
						btn_ck5(1)<='1';
						minute_set	<= minute_set + 1;
					end if;
				
					if(btn_ck5(2)='1' and btn(2)='1') then
						btn_ck5(2)<='0';
					end if;
					
					if(btn_ck5(1)='1' and btn(1)='1') then
						btn_ck5(1)<='0';
					end if;
				
					if(minute_set = 59) then
						minute_set <= 0;
					end if;
					
					minute	<= minute_set+1;
				
				end case;
			end if;
			
			
			
			if(current_state = alarm) then
				if(btn(2) = '0' and btn_ck4(2)='0') then
					alarm_hour_set <= alarm_hour_set + 1;
					btn_ck4(2)<='1';
					if(alarm_hour_set = 23) then
						alarm_hour_set <= 0;
					end if;
				elsif(btn(1) = '0' and btn_ck4(1)='0') then
					alarm_minute_set <= alarm_minute_set + 1;
					btn_ck4(1)<='1';
					if(alarm_minute_set = 59) then
						alarm_minute_set <= 0;
					end if;
				end if;
				
				if(btn(2)='1' and btn_ck4(2)='1') then
					btn_ck4(2)<='0';
				end if;
			
				if(btn(1)='1' and btn_ck4(1)='1') then
					btn_ck4(1)<='0';
				end if;	
				
			end if;

			if((hour = alarm_hour_set) and (minute = alarm_minute_set)) then
				if(half_sec_flag = 0) then
					display_fg <= 1;
				else
					display_fg <= 0;
				end if;
			end if;
		end if;
	end process;
	
-----------------스탑 워치---------------
	process(mingu(0))
	begin
		if(mingu(0)'event and mingu(0) ='1') then
		
			if(current_state = stop) then
			
				if(sw_stop_start= '1' and (btn(1)='1')and (btn(2)='1')) then
					stwa_10ms	<=	stwa_10ms + 1;
					if(stwa_10ms = 9) then
						stwa_10ms <= 0;
						stwa_100ms <= stwa_100ms + 1;
						if(stwa_100ms = 9) then
							stwa_sec	<=	stwa_sec + 1;
							stwa_100ms <= 0;
							if(stwa_sec = 99) then
								stwa_sec <= 0;
							end if;
						end if;
					end if;
				
				elsif((sw_stop_start='1') and btn(1)='0') then
					stwa_100ms	<=	stwa_100ms;
					stwa_10ms	<=	stwa_10ms;
					stwa_sec		<= stwa_sec;
					
				elsif((sw_stop_start='1') and (btn(2)='0')) then
					stwa_100ms_lap	<=	stwa_100ms;
					stwa_10ms_lap	<=	stwa_10ms;
					stwa_sec_lap	<= stwa_sec;
					
				end if;
				
				if(sw_stop_start ='0') then
					stwa_100ms	<=	0;
					stwa_10ms	<=	0;
					stwa_sec		<= 0;
				end if;
				
				
			end if;
		end if;
	end process;
	
end arc;