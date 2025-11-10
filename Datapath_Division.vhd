library ieee;
use ieee.std_logic_1164.all;

entity Datapath_Division is
  port (
    -- global
    i_clock     : in  std_logic;
    i_resetBar  : in  std_logic;

    -- external operands
    i_Dividend : in  std_logic_vector(3 downto 0); -- will be the quotient
    i_Divisor   : in  std_logic_vector(3 downto 0); -- D

    -- control from controller
    -- Q register(Arithmetic left shift) 4 bit
    ctrl_loadQ       : in  std_logic;                   -- 1=load M from i_Dividend
    ctrl_selQ_1      : in  std_logic;                   -- Q: 00 hold, 01 load, 1X shift
    ctrl_selQ_0      : in  std_logic;
    ctrl_absQ        : in  std_logic;                   -- 1: change it to magnitude pulse
	 ctrl_setQlsb : in std_logic;                        --change the lsb corresponding the sign of R pulse
	 i_Qlsb_in : in std_logic;                           -- serial lsbQ pulse
	 
    -- D register (Right_Shift) 4 bit
    ctrl_selD_1      : in  std_logic;                   -- D: 00 hold, 01 load, 1X shift
    ctrl_selD_0      : in  std_logic;
	 ctrl_absD        : in  std_logic;                   -- 1: change it to magnitude pulse
	 
	 -- R register 5 bit
	 ctrl_selR_1      : in  std_logic;                   -- R: 00 hold, 01 load, 1X shift
    ctrl_selR_0      : in  std_logic;
    ctrl_R_load_zero : in  std_logic;                   -- 1: load 0000 into A (clear R), 0: load adder result
	 
	 -- Sign of Q Flip Flop to keep teh sign of Q
    ctrl_enSignQ        : in  std_logic;                   -- usually '1'; can gate if desired
	 
	  -- Sign of R Flip Flop to keep teh sign of R
    ctrl_enSignR        : in  std_logic;                   -- usually '1'; can gate if desired
	 
    -- Add/Sub
    ctrl_sub         : in  std_logic;                   -- 0:add (R+D), 1:sub (R-D) -> maps to adder carry_in_fivebits
	 
    -- Counter N (load then decrement)
    ctrl_selN_1      : in  std_logic;                   -- N: 00 hold, 01 load, 1X decrement
    ctrl_selN_0      : in  std_logic;
    i_N_init         : in  std_logic_vector(3 downto 0);-- will "0100" for 4 iterations
	 
	 --Register Q for handling Q sign 4 bit
    ctrl_Load_Q_mag   :in std_logic;
	 ctrl_Handle_Q_Sign :in std_logic;
	 
	  --Register R for handling R sign 5 bit
    ctrl_Load_R_mag   :in std_logic;
	 ctrl_Handle_R_Sign :in std_logic;
	 
	 -- status back to controller
                  
    o_N_is_zero      : out std_logic;                   -- loop is done when counter is zero
    o_msb_R        : out std_logic;                     -- to know the sign of R
    o_overflow       : out std_logic;                   -- from adder/sub (for debug)
	 
    -- Quotient & Remainder
    o_Q_signed             : out std_logic_vector(3 downto 0);
    o_R_signed            : out std_logic_vector(3 downto 0)

	 --o_Done           : out std_logic
  );
end Datapath_Division;

architecture rtl of Datapath_Division is

---------------------------------------------------------------------------
  -- Components 
---------------------------------------------------------------------------
component  Arithmetic_Left_Shift_Q_four_bit_register is
  port(
    i_resetBar : in  std_logic;
    i_clock    : in  std_logic;
    i_sel_0    : in  std_logic;     
    i_sel_1    : in  std_logic;     
    i_to_mag   : in  std_logic;    
    i_set_lsb  : in  std_logic;     
    i_lsb_in   : in  std_logic;     
    i_Value    : in  std_logic_vector(3 downto 0); 
    o_Value    : out std_logic_vector(3 downto 0); 
    o_msb_tap  : out std_logic);
end component;
component Logical_Left_Shift_FiveBit_withMag is
  port(
    i_resetBar   : in  std_logic;                        -- active-low async reset
    i_clock      : in  std_logic;

    -- 00 = hold, 01 = load, 1x = logical left shift
    i_sel_0      : in  std_logic;                        -- LSB of select
    i_sel_1      : in  std_logic;                        -- MSB of select

    i_shift_in   : in  std_logic;                        -- bit entering LSB on shift
    i_toMag      : in  std_logic;                        -- when '1': convert contents to magnitude

    i_Value      : in  std_logic_vector(4 downto 0);     -- parallel load value (5-bit)
    o_Value      : out std_logic_vector(4 downto 0);     -- register contents (5-bit)
    o_value_msb  : out std_logic                         -- current MSB tap (bit 4)
  );
end component;
component adder_subtractor_5bit IS
PORT(
i_A_v,i_B_v: IN STD_LOGIC_VECTOR(4 downto 0);
i_Carry_in:IN STD_LOGIC;
o_Carry_out:OUT STD_LOGIC;
o_Zero,o_overFlow:OUT STD_LOGIC;
o_Sum_vect:OUT STD_LOGIC_VECTOR(4 downto 0));

END component;
component fourBitRegister_SignHandling is
  port(
    i_resetBar       : in  std_logic;                  -- active-low async reset
    i_clock          : in  std_logic;
    i_load           : in  std_logic;                  -- load magnitude
    i_handling_Sign  : in  std_logic;                  -- when '1': twos-complement current value
    i_Value          : in  std_logic_vector(3 downto 0);
    o_Value          : out std_logic_vector(3 downto 0)
  );
end component;
component fiveBitRegister_SignHandling_R is
  port(
    i_resetBar       : in  std_logic;                       -- active-low async reset
    i_clock          : in  std_logic;
    i_load           : in  std_logic;                       -- load 5-bit magnitude
    i_handling_Sign  : in  std_logic;                       -- when '1': two's complement current value (one-cycle pulse)
    i_Value5         : in  std_logic_vector(4 downto 0);    -- 5-bit magnitude input
    o_Value5_dbg     : out std_logic_vector(4 downto 0);    -- optional: internal 5-bit (for debug/wiring)
    o_Value4         : out std_logic_vector(3 downto 0)     -- published 4-bit remainder
  );
end component;

component D_Abs_Register_4 is
  port(
    i_resetBar : in  std_logic;
    i_clock    : in  std_logic;

    i_load     : in  std_logic;                     -- load |i_Divisor|
    i_to_mag   : in  std_logic;                     -- optional: abs current D

    i_Divisor  : in  std_logic_vector(3 downto 0);  -- signed 4-bit
    o_D_abs    : out std_logic_vector(3 downto 0)   -- stored |Divisor|
  );
end component;

component enARdFF_2 is
    port(i_resetBar : in std_logic;
         i_d        : in std_logic;
         i_enable   : in std_logic;
         i_clock    : in std_logic;
         o_q        : out std_logic;
         o_qBar     : out std_logic);
  end component;
  component fourBitRegister_LoadHoldDec is
    port(i_resetBar : in  std_logic;
         i_clock    : in  std_logic;
         i_sel_0    : in  std_logic;
         i_sel_1    : in  std_logic;
         i_Value    : in  std_logic_vector(3 downto 0);
         o_Value    : out std_logic_vector(3 downto 0);
         o_zero     : out std_logic);
  end component;
component Mux2_1 is
    port(i_val_0, i_val_1 : in  std_logic;
         i_sel            : in  std_logic;
         o_val            : out std_logic);
  end component;
  
   ---------------------------------------------------------------------------
  -- Internal state
  ---------------------------------------------------------------------------
  signal D_val      : std_logic_vector(3 downto 0); -- Divisor reg output
  signal Q_val      : std_logic_vector(3 downto 0); -- Quotient/ivident reg output
  signal Q_val      : std_logic_vector(3 downto 0); -- multiplier reg output
  signal Q1_bit     : std_logic;                    -- LSB of Q
  signal Q0_bit     : std_logic;                    -- FF Q0
  signal prodHigh     : std_logic_vector(3 downto 0);
  signal prodLow   : std_logic_vector(3 downto 0);
 
  signal add_sum    : std_logic_vector(3 downto 0); -- A±M result
  signal add_co     : std_logic;                    -- (unused in flow)
  signal add_zero   : std_logic;

  signal A_load_bus : std_logic_vector(3 downto 0); -- data into A.i_Value (selected)
  signal N_val      : std_logic_vector(3 downto 0);
  signal N_zero     : std_logic;
  signal int_A_lsb  :std_logic;-- value to be put in the multiplier
  

