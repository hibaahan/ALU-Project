library ieee;
use ieee.std_logic_1164.all;

entity Multiplication_Control_Logic_One_Hot is
   port(
	 -- global
    i_clock     : in  std_logic;
    i_resetBar  : in  std_logic;

	-- inputs from Data paths 
	 i_q0        : in   std_logic; --Least significant Bit of Q(Multiplier)
	 i_q1        : in   std_logic;-- holds the previous Least signifivant Bit
	 i_Zero_Flag : in   std_logic;
	  
	 --Output to Control the signals in Data Path / datapath controls
    o_loadM             : out std_logic;          -- load M
    o_selQ_1, o_selQ_0  : out std_logic;          -- Q: 00 hold, 01 load, 1X shift
    o_selA_1, o_selA_0  : out std_logic;          -- A: 00 hold, 01 load, 1X shift (arith)
    o_A_load_zero       : out std_logic;          -- clear A in LOAD
    o_sub               : out std_logic;          -- 1=SUB, 0=ADD
    o_selN_1, o_selN_0  : out std_logic;          -- N: 00 hold, 01 load, 1X dec
    o_enQ1              : out std_logic;          -- enable Q1 FF
    ctrl_latchProduct   : out std_logic;
	 o_done              : out std_logic
	 );
	 end Multiplication_Control_Logic_One_Hot;
	
ARCHITECTURE rtl OF Multiplication_Control_Logic_One_Hot IS

---------------------------------------------------------------------------
  -- Components (only use FlipFlop)
  ---------------------------------------------------------------------------
	
component enARdFF_2 is
    port(i_resetBar : in std_logic;
         i_d        : in std_logic;
         i_enable   : in std_logic;
         i_clock    : in std_logic;
         o_q        : out std_logic;
         o_qBar     : out std_logic);
  end component;
	
---------------------------------------------------------------------------
  -- Internal state
  ---------------------------------------------------------------------------
   signal int_G_loop       : std_logic  ;
	signal S0,S1,S2,S3,S4   : std_logic;
	signal int_Condition_S1,int_Condition_S2,int_Condition_S3,int_Condition_S4:std_logic;
	signal int_state_for_s3 :std_logic;
	begin 
	-- assigning 
	int_G_loop      <= S0 or ( S3 and not(i_Zero_Flag));
	int_Condition_S1<=int_G_loop and  (  i_q0) and  (not i_q1);
	int_Condition_S2<=int_G_loop and  (not i_q0) and  ( i_q1);
	int_state_for_s3<=(i_q1 xnor i_q0) and int_G_loop;
	int_Condition_S3<=int_state_for_s3 or S1 or S2;
	int_Condition_S4<=S3 and i_zero_Flag;
	
	 ----------------------------------------------------------------------------
  -- Initial State (S0
  ----------------------------------------------------------------------------
	S0_init: enARdFF_2 
    port map(
	      i_resetBar => i_resetBar,
         i_d       => '1',--S0 becomes 0 permanetely 
         i_enable  => '1',--alaways enabled in this case
         i_clock   =>i_clock,
         o_q       =>open,
         o_qBar     =>S0);-- will be 1 in i_reset_bar=1

 S1_sub: enARdFF_2 
    port map(
	      i_resetBar => i_resetBar,
         i_d       =>int_Condition_S1 ,
         i_enable  => '1',
         i_clock   =>i_clock,
         o_q       =>S1,
         o_qBar     =>open);

 S2_add: enARdFF_2 
    port map(
	      i_resetBar => i_resetBar,
         i_d       =>int_Condition_S2 ,
         i_enable  => '1',
         i_clock   =>i_clock,
         o_q       =>S2,
         o_qBar     =>open);

S3_shift: enARdFF_2 
    port map(
	      i_resetBar => i_resetBar,
         i_d       =>int_Condition_S3 ,
         i_enable  => '1',
         i_clock   =>i_clock,
         o_q       =>S3,
         o_qBar     =>open); 
	
S4_done: enARdFF_2 
    port map(
	      i_resetBar => i_resetBar,
         i_d       =>int_Condition_S4,
         i_enable  => '1',
         i_clock   =>i_clock,
         o_q       =>S4,
         o_qBar     =>open); 
			
	 ----------------------------------------------------------------------------
  -- assigning values to control signals
  ----------------------------------------------------------------------------		
--Assigning control for S0
o_loadM<=S0;
o_A_load_zero<=S0 ;
o_selQ_0<=S0;
o_selN_0<=S0;
--Assigning S1			
o_sub<=S1;

--Assigning control for S3

o_selA_1<=S3;
o_selQ_1<=S3;
o_selN_1<=S3;

--assigning control Signals

o_done<=S4;
ctrl_latchProduct<=S4;
 --multiple states 
o_selA_0<=S0 or S1 or S2;
o_enQ1<=S0 or S3;
end rtl;
			