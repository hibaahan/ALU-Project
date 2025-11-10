library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture rtl of Datapath_Division_non_Restoring is
  ------------------------------------------------------------------
  -- Internal state
  ------------------------------------------------------------------
  signal D_val       : std_logic_vector(3 downto 0);  -- |Divisor|
  signal Q_val       : std_logic_vector(3 downto 0);  -- Q (loop)
  signal R_val       : std_logic_vector(4 downto 0);  -- R (loop)
  signal SignOfQ     : std_logic;
  signal SignOfR     : std_logic;

  -- adder/subtractor wiring (R ± |D|)
  signal add_A       : std_logic_vector(4 downto 0);  -- R
  signal add_B       : std_logic_vector(4 downto 0);  -- '0' & D (optionally inverted)
  signal add_sum     : std_logic_vector(4 downto 0);
  signal add_co      : std_logic;
  signal add_zero    : std_logic;
  signal add_of      : std_logic;

  -- R load bus (either add_sum or zero)
  signal R_load_bus  : std_logic_vector(4 downto 0);

  -- |Dividend| for Q’s initial load
  function abs4(x: std_logic_vector(3 downto 0)) return std_logic_vector is
    variable xv : unsigned(3 downto 0) := unsigned(x);
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

  -- Final, sign-handled outputs (published)
  signal Q_out_mag   : std_logic_vector(3 downto 0);
  signal R_out_mag   : std_logic_vector(3 downto 0);
begin
  ------------------------------------------------------------------
  -- Q load uses |Dividend| (magnitude). We will apply sign at the end.
  ------------------------------------------------------------------
  Q_load_bus <= abs4(i_Dividend);

  ------------------------------------------------------------------
  -- D register = |Divisor|
  ------------------------------------------------------------------
  DREG : D_Abs_Register_4
    port map(
      i_resetBar => i_resetBar,
      i_clock    => i_clock,
      i_load     => (not ctrl_selD_1) and ctrl_selD_0, -- "01" = load
      i_to_mag   => ctrl_absD,                         -- optional pulse (ok)
      i_Divisor  => i_Divisor,
      o_D_abs    => D_val
    );

  ------------------------------------------------------------------
  -- Sign flip-flops (latch BEFORE abs)
  -- SignOfQ <= Dividend[3] xor Divisor[3]
  -- SignOfR <= Dividend[3]
  ------------------------------------------------------------------
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

  ------------------------------------------------------------------
  -- Q register (arith left shift, force LSB after decision, abs pulse)
  ------------------------------------------------------------------
  QREG : Arithmetic_Left_Shift_Q_four_bit_register
    port map(
      i_resetBar => i_resetBar,
      i_clock    => i_clock,
      i_sel_0    => ctrl_selQ_0,
      i_sel_1    => ctrl_selQ_1,
      i_to_mag   => ctrl_absQ,          -- pulse to abs(Q) if you use it
      i_set_lsb  => ctrl_setQlsb,       -- *** fixed name ***
      i_lsb_in   => i_Qlsb_in,          -- *** fixed name ***
      i_Value    => Q_load_bus,         -- |Dividend|
      o_Value    => Q_val,
      o_msb_tap  => open
    );

  ------------------------------------------------------------------
  -- 5-bit adder/subtractor: add_A = R, add_B = ('0' & D) xor (sub mask)
  ------------------------------------------------------------------
  add_A <= R_val;
  add_B <= (('0' & D_val) xor (4 downto 0 => ctrl_sub));

  ADD5 : adder_subtractor_5bit
    port map(
      i_A_v       => add_A,
      i_B_v       => add_B,
      i_Carry_in  => ctrl_sub,      -- +1 when subtract
      o_Carry_out => add_co,
      o_Zero      => add_zero,      -- *** fixed port name ***
      o_overFlow  => add_of,        -- *** fixed port name ***
      o_Sum_vect  => add_sum
    );

  ------------------------------------------------------------------
  -- R load: add result vs zero (vector mux written as a conditional)
  -- NOTE: We DO NOT take abs(R) anywhere; R is kept signed during loop.
  ------------------------------------------------------------------
  R_load_bus <= (others => '0') when ctrl_R_load_zero = '1' else add_sum;

  ------------------------------------------------------------------
  -- R register (5-bit): hold/shift/load. No "toMag" input (keep R signed).
  ------------------------------------------------------------------
  RREG : Logical_Left_Shift_FiveBit_withMag
    port map(
      i_resetBar => i_resetBar,
      i_clock    => i_clock,
      i_sel_0    => ctrl_selR_0,
      i_sel_1    => ctrl_selR_1,
      i_shift_in => Q_val(3),   -- MSB of Q enters R(0) on shift
      i_toMag    => '0',        -- *** keep R as-is (no abs on R) ***
      i_Value    => R_load_bus,
      o_Value    => R_val,
      o_value_msb=> open
    );

  ------------------------------------------------------------------
  -- Counter N: "00" hold, "01" load i_N_init, "1x" decrement
  ------------------------------------------------------------------
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

  ------------------------------------------------------------------
  -- Final sign-handling registers to publish signed results
  -- Pulse ctrl_Handle_*_Sign once at the very end, using SignOfQ/SignOfR.
  ------------------------------------------------------------------
  Q_OUT : fourBitRegister_SignHandling
    port map(
      i_resetBar      => i_resetBar,
      i_clock         => i_clock,
      i_load          => ctrl_Load_Q_mag,     -- load Q_val (magnitude path)
      i_handling_Sign => ctrl_Handle_Q_Sign,  -- two's complement when needed
      i_Value         => Q_val,
      o_Value         => Q_out_mag
    );

  R_OUT : fiveBitRegister_SignHandling_R
    port map(
      i_resetBar      => i_resetBar,
      i_clock         => i_clock,
      i_load          => ctrl_Load_R_mag,     -- load R_val (5-bit)
      i_handling_Sign => ctrl_Handle_R_Sign,  -- two's complement when needed
      i_Value5        => R_val,
      o_Value5_dbg    => open,
      o_Value4        => R_out_mag
    );

  ------------------------------------------------------------------
  -- Status & published outputs
  ------------------------------------------------------------------
  o_msb_R     <= R_val(4);      -- sign of R (decision bit)
  o_N_is_zero <= N_zero;

  o_Q_signed  <= Q_out_mag;
  o_R_signed  <= R_out_mag;

  o_overflow  <= add_co;        -- debug carry/borrow
end rtl;
