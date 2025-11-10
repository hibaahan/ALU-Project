library ieee;
use ieee.std_logic_1164.all;

entity Booth_Datapath is
  port (
    -- global
    i_clock     : in  std_logic;
    i_resetBar  : in  std_logic;

    -- external operands
    i_Multiplicand : in  std_logic_vector(3 downto 0); -- M
    i_Multiplier   : in  std_logic_vector(3 downto 0); -- Q

    -- control from controller
    -- M register
    ctrl_loadM       : in  std_logic;                   -- 1=load M from i_Multiplicand
    -- A register (Right_Shift)
    ctrl_selA_1      : in  std_logic;                   -- A: 00 hold, 01 load, 1X shift
    ctrl_selA_0      : in  std_logic;
    ctrl_A_load_zero : in  std_logic;                   -- 1: load 0000 into A (clear A), 0: load adder result
    -- Q register (Right_Shift)
    ctrl_selQ_1      : in  std_logic;                   -- Q: 00 hold, 01 load, 1X shift
    ctrl_selQ_0      : in  std_logic;
    -- Q1 FF
    ctrl_enQ1        : in  std_logic;                   -- usually '1'; can gate if desired
    -- Add/Sub
    ctrl_sub         : in  std_logic;                   -- 0:add (A+M), 1:sub (A-M) -> maps to adder carry_in
    -- Counter N (load then decrement)
    ctrl_selN_1      : in  std_logic;                   -- N: 00 hold, 01 load, 1X decrement
    ctrl_selN_0      : in  std_logic;
    i_N_init         : in  std_logic_vector(3 downto 0);-- will "0100" for 4 iterations
    --Signal to only latch final product
	 ctrl_latchProduct :in  std_logic;
    -- status back to controller
    o_lsbQ0             : out std_logic;                   -- Lsb 
    o_FFQ1         : out std_logic;                      -- ff 
    o_N_is_zero      : out std_logic;                   -- loop is done when counter is zero
    o_A_zero         : out std_logic;                   -- optional (from A)
    o_overflow       : out std_logic;                   -- from adder/sub (for debug)
    -- product view (optional)
    o_A              : out std_logic_vector(3 downto 0);
    o_Q              : out std_logic_vector(3 downto 0);
    o_Product        : out std_logic_vector(7 downto 0) -- concat A & Q
	 --o_Done           : out std_logic
  );
end Booth_Datapath;

architecture rtl of Booth_Datapath is
  ---------------------------------------------------------------------------
  -- Components 
  ---------------------------------------------------------------------------
  component fourBitRegister is
    port(i_resetBar, i_load : in std_logic;
         i_clock            : in std_logic;
         i_Value            : in std_logic_vector(3 downto 0);
         o_Value            : out std_logic_vector(3 downto 0));
  end component;

  component Right_Shift_four_bit_register is
    port(i_resetBar : in std_logic;
         i_clock    : in std_logic;
         i_sel_0    : in std_logic;
         i_sel_1    : in std_logic;
         i_Value    : in std_logic_vector(3 downto 0);
         o_Value    : out std_logic_vector(3 downto 0);
         o_value_lsb: out std_logic);
  end component;

  component enARdFF_2 is
    port(i_resetBar : in std_logic;
         i_d        : in std_logic;
         i_enable   : in std_logic;
         i_clock    : in std_logic;
         o_q        : out std_logic;
         o_qBar     : out std_logic);
  end component;
Component Logical_Right_Shift_four_bit_register is
  port(
    i_resetBar   : in  std_logic;
    i_clock      : in  std_logic;
    -- Select: 00=hold, 01=load, 1X=logical right shift
    i_sel_0      : in  std_logic;   -- LSB of select
    i_sel_1      : in  std_logic;   -- MSB of select
    i_shift_in   : in  std_logic;   -- bit entering MSB on shift (e.g., A(0))
    i_Value      : in  std_logic_vector(3 downto 0);  -- parallel load
    o_Value      : out std_logic_vector(3 downto 0);
    o_value_lsb  : out std_logic
  );
end Component;
  component fourBitRegister_LoadHoldDec is
    port(i_resetBar : in  std_logic;
         i_clock    : in  std_logic;
         i_sel_0    : in  std_logic;
         i_sel_1    : in  std_logic;
         i_Value    : in  std_logic_vector(3 downto 0);
         o_Value    : out std_logic_vector(3 downto 0);
         o_zero     : out std_logic);
  end component;

  component adder_subtractor is
    port(i_A_v, i_B_v  : in  std_logic_vector(3 downto 0);
         i_Carry_in    : in  std_logic;                 -- 0:add, 1:sub (assumed)
         o_Carry_out   : out std_logic;
         o_Zero        : out std_logic;
         o_overFlow    : out std_logic;
         o_Sum_vect    : out std_logic_vector(3 downto 0));
  end component;

  -- 2:1 mux bit (used x4 to choose A load source: adder vs zero)
  component Mux2_1 is
    port(i_val_0, i_val_1 : in  std_logic;
         i_sel            : in  std_logic;
         o_val            : out std_logic);
  end component;

  ---------------------------------------------------------------------------
  -- Internal state
  ---------------------------------------------------------------------------
  signal M_val      : std_logic_vector(3 downto 0); -- multiplicand reg output
  signal A_val      : std_logic_vector(3 downto 0); -- accumulator reg output
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
begin
  ----------------------------------------------------------------------------
  -- M register (4-bit, parallel load)
  ----------------------------------------------------------------------------
  M_reg : fourBitRegister
    port map(
      i_resetBar => i_resetBar,
      i_load     => ctrl_loadM,
      i_clock    => i_clock,
      i_Value    => i_Multiplicand,
      o_Value    => M_val
    );

  ----------------------------------------------------------------------------
  -- Adder/Subtractor: A ± M  (ctrl_sub = '0' add, '1' subtract)
  ----------------------------------------------------------------------------
  U_ADD : adder_subtractor
    port map(
      i_A_v       => A_val,
      i_B_v       => M_val,
      i_Carry_in  => ctrl_sub,      -- convention: 0 add, 1 subtract
      o_Carry_out => add_co,
      o_Zero      => add_zero,
      o_overFlow  => o_overflow,
      o_Sum_vect  => add_sum -- TO BE LOAD IN AC
    );

  ----------------------------------------------------------------------------
  -- A load source mux: select between ZERO and adder result
  ----------------------------------------------------------------------------
  A_mux3 : Mux2_1 port map(i_val_0 => add_sum(3), i_val_1 => '0',       -- note: sel=1 => ZERO
                           i_sel   => ctrl_A_load_zero, o_val => A_load_bus(3));
  A_mux2 : Mux2_1 port map(i_val_0 => add_sum(2), i_val_1 => '0',
                           i_sel   => ctrl_A_load_zero, o_val => A_load_bus(2));
  A_mux1 : Mux2_1 port map(i_val_0 => add_sum(1), i_val_1 => '0',
                           i_sel   => ctrl_A_load_zero, o_val => A_load_bus(1));
  A_mux0 : Mux2_1 port map(i_val_0 => add_sum(0), i_val_1 => '0',
                           i_sel   => ctrl_A_load_zero, o_val => A_load_bus(0));

  ----------------------------------------------------------------------------
  -- A register (Right shift: 00 hold, 01 load A_load_bus, 1X arithmetic shift)
  ----------------------------------------------------------------------------
  A_reg : Right_Shift_four_bit_register
    port map(
      i_resetBar   => i_resetBar,
      i_clock      => i_clock,
      i_sel_0      => ctrl_selA_0,
      i_sel_1      => ctrl_selA_1,
      i_Value      => A_load_bus,
      o_Value      => A_val,
      o_value_lsb  => int_A_lsb
    );

 -- Q register: LOGICAL right shift. MSB takes A LSB (int_A_lsb) on shift.
Q_reg : Logical_Right_Shift_four_bit_register
  port map(
    i_resetBar   => i_resetBar,
    i_clock      => i_clock,
    i_sel_0      => ctrl_selQ_0,         -- 00 hold, 01 load, 1X shift
    i_sel_1      => ctrl_selQ_1,
    i_shift_in   => int_A_lsb,           -- << A(0) feeds Q(3) on shift
    i_Value      => i_Multiplier,        -- parallel load of Q
    o_Value      => Q_val,
    o_value_lsb  => Q0_bit               -- expose current Q(0)
  );


  ----------------------------------------------------------------------------
  -- Q1 flip-flop: captures previous Q1 during the shift phase
  ----------------------------------------------------------------------------
  Q1ff : enARdFF_2
    port map(
      i_resetBar => i_resetBar,   -- clears to 0 at reset
      i_d        => Q0_bit,       -- next Q0 = current Q1
      i_enable   => ctrl_enQ1,    -- usually '1'
      i_clock    => i_clock,
      o_q        => Q1_bit,       -- next state?will keep holding the previous least significant bit 
      o_qBar     => open 
    );

  ----------------------------------------------------------------------------
  -- Iteration counter N (load init value, then decrement; zero flag exported)
  ----------------------------------------------------------------------------
  N_cnt : fourBitRegister_LoadHoldDec
    port map(
      i_resetBar => i_resetBar,
      i_clock    =>  i_clock,
      i_sel_0    => ctrl_selN_0,  -- 00 hold, 01 load i_N_init, 1X decrement
      i_sel_1    => ctrl_selN_1,
      i_Value    => i_N_init,
      o_Value    => N_val,
      o_zero     => N_zero
    );
 ----------------------------------------------------------------------------
  -- Only latch the final product we use two four bit registers
  
  ----------------------------------------------------------------------------
  
  ProdHi:fourBitRegister
  PORT map(
		i_resetBar => i_resetBar,
		i_load=>ctrl_latchProduct,
		i_clock=>i_clock,
		i_Value=>A_val,
		o_Value=>prodHigh
);

 ProdLo:fourBitRegister
  PORT map(
		i_resetBar => i_resetBar,
		i_load=>ctrl_latchProduct,
		i_clock=>i_clock,
		i_Value=>Q_val,
		o_Value=>prodLow
); 
 
  ----------------------------------------------------------------------------
  -- Outputs to controller / observer
  ----------------------------------------------------------------------------
 o_lsbQ0      <= Q0_bit;
  o_FFQ1       <= Q1_bit;
  o_N_is_zero <= N_zero;
  o_A_zero    <= add_zero;           -- zero of A (before shift/load)
  o_A         <= A_val;
  o_Q        <= Q_val;
  o_Product   <= prodHigh & prodLow;   -- view of 8-bit product (valid at end)
  
 
END rtl;
