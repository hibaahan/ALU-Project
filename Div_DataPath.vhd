library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--======================================================================
-- Datapath: Non-Restoring Division (4-bit) with sign handling
-- - Latch signs from inputs first
-- - Convert ONLY Q (Dividend) and D (Divisor) to magnitude
-- - Keep R signed during iterations (no abs on R)
-- - Final sign application done by Q_OUT / R_OUT registers
--======================================================================
entity Div_DataPath is
  port (
    -- global
    i_clock     : in  std_logic;
    i_resetBar  : in  std_logic;

    -- external operands
    i_Dividend  : in  std_logic_vector(3 downto 0); -- will be the quotient (Q)
    i_Divisor   : in  std_logic_vector(3 downto 0); -- D

    -- control from controller
    -- Q register (Arithmetic left shift) 4-bit
    ctrl_loadQ       : in  std_logic;                   -- (optional) not used internally
    ctrl_selQ_1      : in  std_logic;                   -- Q: 00 hold, 01 load, 1X shift
    ctrl_selQ_0      : in  std_logic;
    ctrl_absQ        : in  std_logic;                   -- 1: change Q to magnitude (pulse)
    ctrl_setQlsb     : in  std_logic;                   -- set LSB of Q after decision (pulse)
    i_Qlsb_in        : in  std_logic;                   -- serial bit to inject into Q LSB

    -- D register (Right-Shift block with abs) 4-bit
    ctrl_selD_1      : in  std_logic;                   -- D: 00 hold, 01 load, 1X shift
    ctrl_selD_0      : in  std_logic;
    ctrl_absD        : in  std_logic;                   -- 1: change D to magnitude (pulse)

    -- R register 5-bit
    ctrl_selR_1      : in  std_logic;                   -- R: 00 hold, 01 load, 1X shift
    ctrl_selR_0      : in  std_logic;
    ctrl_R_load_zero : in  std_logic;                   -- 1: load 00000 into R, 0: load adder result

    -- Sign flip-flops
    ctrl_enSignQ     : in  std_logic;                   -- enable FF that latches sign of Q
    ctrl_enSignR     : in  std_logic;                   -- enable FF that latches sign of R

    -- Add/Sub
    ctrl_sub         : in  std_logic;                   -- 0:add (R+D), 1:sub (R-D)

    -- Counter N (load then decrement)
    ctrl_selN_1      : in  std_logic;                   -- N: 00 hold, 01 load, 1X decrement
    ctrl_selN_0      : in  std_logic;
    i_N_init         : in  std_logic_vector(3 downto 0);-- "0100" for 4 iterations

    -- Registers to publish signed outputs at the end
    ctrl_Load_Q_mag      : in std_logic;                -- load Q_val into output reg
    ctrl_Handle_Q_Sign   : in std_logic;                -- apply sign to Q_out
    ctrl_Load_R_mag      : in std_logic;                -- load R_val into output reg
    ctrl_Handle_R_Sign   : in std_logic;                -- apply sign to R_out

    -- status back to controller
    o_N_is_zero      : out std_logic;                   -- loop is done when counter is zero
    o_msb_R          : out std_logic;                   -- sign of R for decision
    o_overflow       : out std_logic;                   -- from adder/sub (debug)

    -- NEW: expose the latched signs
    o_signQ_lat      : out std_logic;                   -- latched sign of Q (Dividend ⊕ Divisor)
    o_signR_lat      : out std_logic;                   -- latched sign of R (Dividend sign)

    -- Quotient & Remainder (signed, published)
    o_Q_signed       : out std_logic_vector(3 downto 0);
    o_R_signed       : out std_logic_vector(3 downto 0)
  );
end Div_DataPath;

--======================================================================
-- Architecture
--======================================================================
architecture rtl of Div_DataPath is

  --------------------------------------------------------------------
  -- Component declarations (as you provided)
  --------------------------------------------------------------------
  component Arithmetic_Left_Shift_Q_four_bit_register is
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
      o_msb_tap  : out std_logic
    );
  end component;

  component Logical_Left_Shift_FiveBit_withMag is
    port(
      i_resetBar   : in  std_logic;
      i_clock      : in  std_logic;
      -- 00 = hold, 01 = load, 1x = logical left shift
      i_sel_0      : in  std_logic;
      i_sel_1      : in  std_logic;
      i_shift_in   : in  std_logic;
      i_toMag      : in  std_logic;
      i_Value      : in  std_logic_vector(4 downto 0);
      o_Value      : out std_logic_vector(4 downto 0);
      o_value_msb  : out std_logic
    );
  end component;

  component adder_subtractor_5bit is
    port(
      i_A_v, i_B_v  : in  std_logic_vector(4 downto 0);
      i_Carry_in    : in  std_logic;
      o_Carry_out   : out std_logic;
      o_Zero        : out std_logic;
      o_overFlow    : out std_logic;
      o_Sum_vect    : out std_logic_vector(4 downto 0)
    );
  end component;

  component fourBitRegister_SignHandling is
    port(
      i_resetBar       : in  std_logic;
      i_clock          : in  std_logic;
      i_load           : in  std_logic;
      i_handling_Sign  : in  std_logic;
      i_Value          : in  std_logic_vector(3 downto 0);
      o_Value          : out std_logic_vector(3 downto 0)
    );
  end component;

  component fiveBitRegister_SignHandling_R is
    port(
      i_resetBar       : in  std_logic;
      i_clock          : in  std_logic;
      i_load           : in  std_logic;
      i_handling_Sign  : in  std_logic;
      i_Value5         : in  std_logic_vector(4 downto 0);
      o_Value5_dbg     : out std_logic_vector(4 downto 0);
      o_Value4         : out std_logic_vector(3 downto 0)
    );
  end component;

  component D_Abs_Register_4 is
    port(
      i_resetBar : in  std_logic;
      i_clock    : in  std_logic;
      i_load     : in  std_logic;
      i_to_mag   : in  std_logic;
      i_Divisor  : in  std_logic_vector(3 downto 0);
      o_D_abs    : out std_logic_vector(3 downto 0)
    );
  end component;

  component enARdFF_2 is
    port(
      i_resetBar : in std_logic;
      i_d        : in std_logic;
      i_enable   : in std_logic;
      i_clock    : in std_logic;
      o_q        : out std_logic;
      o_qBar     : out std_logic
    );
  end component;

  component fourBitRegister_LoadHoldDec is
    port(
      i_resetBar : in  std_logic;
      i_clock    : in  std_logic;
      i_sel_0    : in  std_logic;
      i_sel_1    : in  std_logic;
      i_Value    : in  std_logic_vector(3 downto 0);
      o_Value    : out std_logic_vector(3 downto 0);
      o_zero     : out std_logic
    );
  end component;

  --------------------------------------------------------------------
  -- Internal signals
  --------------------------------------------------------------------
  signal D_val       : std_logic_vector(3 downto 0);  -- |Divisor|
  signal Q_val       : std_logic_vector(3 downto 0);  -- Q (loop)
  signal R_val       : std_logic_vector(4 downto 0);  -- R (loop)

  signal SignOfQ     : std_logic;
  signal SignOfR     : std_logic;

  -- adder/subtractor wiring (R ± |D|)
  signal add_A       : std_logic_vector(4 downto 0);  -- R
  signal add_B       : std_logic_vector(4 downto 0);  -- '0' & |D| (invert if subtract)
  signal add_sum     : std_logic_vector(4 downto 0);
  signal add_co      : std_logic;
  signal add_zero    : std_logic;
  signal add_of      : std_logic;

  -- R load bus (either add_sum or zero)
  signal R_load_bus  : std_logic_vector(4 downto 0);

  -- |Dividend| for Q’s initial load
  function abs4(x: std_logic_vector(3 downto 0)) return std_logic_vector is
  begin
    if x(3) = '1' then
      return std_logic_vector(unsigned(not x) + 1);
    else
      return x;
    end if;
  end function;

  signal Q_load_bus  : std_logic_vector(3 downto 0);

  -- Counter
  signal N_val       : std_logic_vector(3 downto 0);
  signal N_zero      : std_logic;

  -- Published results (after sign handling registers)
  signal Q_out_mag   : std_logic_vector(3 downto 0);
  signal R_out_mag   : std_logic_vector(3 downto 0);

begin
  --------------------------------------------------------------------
  -- Prepare |Dividend| for Q load
  --------------------------------------------------------------------
  Q_load_bus <= abs4(i_Dividend);

  --------------------------------------------------------------------
  -- D register = |Divisor| (abs only for D)
  --------------------------------------------------------------------
  DREG : D_Abs_Register_4
    port map(
      i_resetBar => i_resetBar,
      i_clock    => i_clock,
      i_load     => (not ctrl_selD_1) and ctrl_selD_0, -- "01" = load
      i_to_mag   => ctrl_absD,                         -- pulse to abs(D) if desired
      i_Divisor  => i_Divisor,
      o_D_abs    => D_val
    );

  --------------------------------------------------------------------
  -- Sign flip-flops (LATCH BEFORE abs): from raw inputs
  -- SignOfQ <= i_Dividend(3) xor i_Divisor(3)
  -- SignOfR <= i_Dividend(3)
  --------------------------------------------------------------------
  SignQ_FF : enARdFF_2
    port map(
      i_resetBar => i_resetBar,
      i_d        => i_Dividend(3) xor i_Divisor(3),
      i_enable   => ctrl_enSignQ,
      i_clock    => i_clock,
      o_q        => SignOfQ,
      o_qBar     => open
    );

  SignR_FF : enARdFF_2
    port map(
      i_resetBar => i_resetBar,
      i_d        => i_Dividend(3),
      i_enable   => ctrl_enSignR,
      i_clock    => i_clock,
      o_q        => SignOfR,
      o_qBar     => open
    );

  -- NEW: expose the latched signs to the controller
  o_signQ_lat <= SignOfQ;
  o_signR_lat <= SignOfR;

  --------------------------------------------------------------------
  -- Q register (arith left shift, force LSB after decision, abs pulse)
  -- We load Q with |Dividend| and keep it positive during iterations.
  --------------------------------------------------------------------
  QREG : Arithmetic_Left_Shift_Q_four_bit_register
    port map(
      i_resetBar => i_resetBar,
      i_clock    => i_clock,
      i_sel_0    => ctrl_selQ_0,
      i_sel_1    => ctrl_selQ_1,
      i_to_mag   => ctrl_absQ,          -- optional pulse to abs(Q)
      i_set_lsb  => ctrl_setQlsb,       -- set LSB after decision
      i_lsb_in   => i_Qlsb_in,          -- bit to write into Q(0)
      i_Value    => Q_load_bus,         -- |Dividend|
      o_Value    => Q_val,
      o_msb_tap  => open
    );

  --------------------------------------------------------------------
  -- 5-bit adder/subtractor (no aggregates in XOR)
  --------------------------------------------------------------------
  add_A <= R_val;
  add_B <= not ('0' & D_val) when ctrl_sub = '1' else ('0' & D_val);

  ADD5 : adder_subtractor_5bit
    port map(
      i_A_v       => add_A,
      i_B_v       => add_B,
      i_Carry_in  => ctrl_sub,       -- +1 when subtract (two's complement)
      o_Carry_out => add_co,
      o_Zero      => add_zero,
      o_overFlow  => add_of,
      o_Sum_vect  => add_sum
    );

  --------------------------------------------------------------------
  -- R load (vector mux): zero vs adder result
  -- NOTE: We DO NOT convert R to magnitude; keep R signed during loop.
  --------------------------------------------------------------------
  R_load_bus <= (others => '0') when ctrl_R_load_zero = '1' else add_sum;

  --------------------------------------------------------------------
  -- R register (5-bit): hold / shift / load (no abs on R)
  -- Shift-in is Q.MSB (RQ << 1 behavior)
  --------------------------------------------------------------------
  RREG : Logical_Left_Shift_FiveBit_withMag
    port map(
      i_resetBar => i_resetBar,
      i_clock    => i_clock,
      i_sel_0    => ctrl_selR_0,
      i_sel_1    => ctrl_selR_1,
      i_shift_in => Q_val(3),   -- MSB of Q enters R(0) on shift
      i_toMag    => '0',        -- keep R signed; no magnitude conversion
      i_Value    => R_load_bus,
      o_Value    => R_val,
      o_value_msb=> open
    );

  --------------------------------------------------------------------
  -- Counter N: "00" hold, "01" load i_N_init, "1x" decrement
  --------------------------------------------------------------------
  NREG : fourBitRegister_LoadHoldDec
    port map(
      i_resetBar => i_resetBar,
      i_clock    => i_clock,
      i_sel_0    => ctrl_selN_0,
      i_sel_1    => ctrl_selN_1,
      i_Value    => i_N_init,
      o_Value    => N_val,
      o_zero     => N_zero
    );

  --------------------------------------------------------------------
  -- Final sign-handling registers to publish signed Q and R
  -- Controller will pulse ctrl_Handle_*_Sign if o_sign*_lat = '1'
  --------------------------------------------------------------------
  Q_OUT : fourBitRegister_SignHandling
    port map(
      i_resetBar      => i_resetBar,
      i_clock         => i_clock,
      i_load          => ctrl_Load_Q_mag,     -- load Q_val
      i_handling_Sign => ctrl_Handle_Q_Sign,  -- controller-gated pulse
      i_Value         => Q_val,
      o_Value         => Q_out_mag
    );

  R_OUT : fiveBitRegister_SignHandling_R
    port map(
      i_resetBar      => i_resetBar,
      i_clock         => i_clock,
      i_load          => ctrl_Load_R_mag,     -- load R_val (5-bit)
      i_handling_Sign => ctrl_Handle_R_Sign,  -- controller-gated pulse
      i_Value5        => R_val,               -- 5-bit internal R
      o_Value5_dbg    => open,                -- optional debug
      o_Value4        => R_out_mag            -- trimmed/published 4-bit remainder
    );

  --------------------------------------------------------------------
  -- Status & published outputs
  --------------------------------------------------------------------
  o_msb_R     <= R_val(4);      -- sign of R for decision
  o_N_is_zero <= N_zero;

  o_Q_signed  <= Q_out_mag;
  o_R_signed  <= R_out_mag;

  -- Expose overflow from adder (or use carry if you prefer)
  o_overflow  <= add_of;

end rtl;
