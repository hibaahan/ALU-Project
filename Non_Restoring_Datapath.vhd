library ieee;
use ieee.std_logic_1164.all;

entity Non_Restoring_Datapath is
  port (
    -- global
    i_clock     : in  std_logic;
    i_resetBar  : in  std_logic;

    -- external operands
    i_Dividend  : in  std_logic_vector(3 downto 0); -- Q source (dividend)
    i_Divisor   : in  std_logic_vector(3 downto 0); -- D source

    -- control from controller
    -- D register 4 bit
    ctrl_loadD       : in  std_logic;  -- 1=load D (store magnitude)
    -- Q register 4 bit (Arithmetic Left Shift )
    ctrl_loadQ       : in  std_logic;  -- 1=load dividend (store magnitude)
    ctrl_shiftQ      : in  std_logic;  -- 1=left shift Q
    ctrl_setlsb      : in  std_logic;  -- 1=force Q[0]
    ctrl_inlsb       : in  std_logic;  -- value to force into Q[0]

    -- R register 5 bit (Logical Left Shift)
    ctrl_clearR      : in  std_logic;  -- clear R (init)
    ctrl_loadR       : in  std_logic;  -- load ALU result into R
    ctrl_shiftR      : in  std_logic;  -- logical left shift R (serial in from Q.MSB)

    -- Add/Sub
    ctrl_sub         : in  std_logic;  -- 0:add (R+D), 1:sub (R-D)

    -- Counter N (load then decrement)
    ctrl_loadN       : in  std_logic;
    ctrl_decN        : in  std_logic;
    i_N_init         : in  std_logic_vector(3 downto 0); -- "0100" for 4 iterations

    -- Q signed output register
    ctrl_LoadQ_S     : in  std_logic;
    ctrl_isQneg      : in  std_logic;  -- (not used here; we compute from signs)

    -- R signed output register
    ctrl_LoadR_S     : in  std_logic;
    ctrl_isRneg      : in  std_logic;  -- (not used here; we use dividend sign)

    -- status back to controller
    o_msb_R          : out std_logic;
    o_N_is_zero      : out std_logic;

    -- Quotient & Remainder view (optional)
    o_Q_signed       : out std_logic_vector(3 downto 0);
    o_R_signed       : out std_logic_vector(3 downto 0);
    o_overflow       : out std_logic
  );
end Non_Restoring_Datapath;

architecture rtl of Non_Restoring_Datapath is

  ---------------------------------------------------------------------------
  -- Components
  ---------------------------------------------------------------------------
  component reg4_divisor_mag is
    port(
      i_clock    : in  std_logic;
      i_resetBar : in  std_logic;
      i_load     : in  std_logic;
      i_D_signed : in  std_logic_vector(3 downto 0);
      o_D_mag    : out std_logic_vector(3 downto 0);
      o_D_sign   : out std_logic
    );
  end component;

  component reg4_Q_shift_setlsb is
    port(
      i_clock    : in  std_logic;
      i_resetBar : in  std_logic;
      i_clear    : in  std_logic;
      i_load     : in  std_logic;
      i_shift    : in  std_logic;
      i_setlsb   : in  std_logic;
      i_lsb      : in  std_logic;
      i_Q_signed : in  std_logic_vector(3 downto 0);
      o_Q_mag    : out std_logic_vector(3 downto 0);
      o_Q_sign   : out std_logic
    );
  end component;

  component reg5_R_shift is
    port(
      i_clock   : in  std_logic;
      i_resetBar: in  std_logic;
      i_clear   : in  std_logic;
      i_load    : in  std_logic;
      i_shift   : in  std_logic;
      i_sin     : in  std_logic;
      i_D       : in  std_logic_vector(4 downto 0);
      o_Q       : out std_logic_vector(4 downto 0);
      o_msb     : out std_logic
    );
  end component;

  component adder_subtractor_5bit is
    port(
      i_A_v       : in  std_logic_vector(4 downto 0);
      i_B_v       : in  std_logic_vector(4 downto 0);
      i_Carry_in  : in  std_logic;
      o_Carry_out : out std_logic;
      o_Zero      : out std_logic;
      o_overFlow  : out std_logic;
      o_Sum_vect  : out std_logic_vector(4 downto 0)
    );
  end component;

  component dec_counter4 is
    port(
      i_clock    : in  std_logic;
      i_resetBar : in  std_logic;
      i_load     : in  std_logic;
      i_dec      : in  std_logic;
      i_din      : in  std_logic_vector(3 downto 0);
      o_q        : out std_logic_vector(3 downto 0);
      o_zero     : out std_logic
    );
  end component;

  component sign_applyQ4 is
    port(
      i_clock      : in  std_logic;
      i_resetBar   : in  std_logic;
      i_load       : in  std_logic;
      i_Q4_mag     : in  std_logic_vector(3 downto 0);
      i_neg        : in  std_logic;
      o_Q4_signed  : out std_logic_vector(3 downto 0)
    );
  end component;

  component sign_applyR5_to4 is
    port(
      i_clock      : in  std_logic;
      i_resetBar   : in  std_logic;
      i_load       : in  std_logic;
      i_R5_mag     : in  std_logic_vector(4 downto 0);
      i_neg        : in  std_logic;
      o_R4_signed  : out std_logic_vector(3 downto 0)
    );
  end component;

  ---------------------------------------------------------------------------
  -- Internal
  ---------------------------------------------------------------------------
  signal D_val        : std_logic_vector(3 downto 0);
  signal R_val        : std_logic_vector(4 downto 0);
  signal Q_val        : std_logic_vector(3 downto 0);
  signal Q_signed_val : std_logic_vector(3 downto 0);
  signal R_signed_val : std_logic_vector(3 downto 0);

  signal Q0_sign      : std_logic;  -- sign of dividend (from Q loader)
  signal D_sign       : std_logic;

  signal add_sum      : std_logic_vector(4 downto 0);
  signal add_co       : std_logic;
  signal add_zero     : std_logic;

  signal N_val        : std_logic_vector(3 downto 0);
  signal N_zero       : std_logic;

  signal Q_msb        : std_logic;
  signal R_msb        : std_logic;

begin

  Q_msb <= Q_val(3);

  ----------------------------------------------------------------------------
  -- D register (4-bit, magnitude only)
  ----------------------------------------------------------------------------
  D_reg : reg4_divisor_mag
    port map(
      i_clock    => i_clock,
      i_resetBar => i_resetBar,
      i_load     => ctrl_loadD,
      i_D_signed => i_Divisor,
      o_D_mag    => D_val,
      o_D_sign   => D_sign
    );

  ----------------------------------------------------------------------------
  -- R register (5-bit logical shift left, parallel load)
  ----------------------------------------------------------------------------
  Remain_reg : reg5_R_shift
    port map(
      i_clock    => i_clock,
      i_resetBar => i_resetBar,
      i_clear    => ctrl_clearR,
      i_load     => ctrl_loadR,
      i_shift    => ctrl_shiftR,
      i_sin      => Q_msb,      -- couple Q.MSB into R on shift
      i_D        => add_sum,    -- ALU result when ctrl_loadR='1'
      o_Q        => R_val,
      o_msb      => R_msb
    );

  ----------------------------------------------------------------------------
  -- Q register (4-bit shift + set LSB, loads magnitude)
  ----------------------------------------------------------------------------
  Quotient_reg : reg4_Q_shift_setlsb
    port map(
      i_clock    => i_clock,
      i_resetBar => i_resetBar,
      i_clear    => '0',            -- never clear Q explicitly
      i_load     => ctrl_loadQ,
      i_shift    => ctrl_shiftQ,
      i_setlsb   => ctrl_setlsb,
      i_lsb      => ctrl_inlsb,
      i_Q_signed => i_Dividend,
      o_Q_mag    => Q_val,
      o_Q_sign   => Q0_sign
    );

  ----------------------------------------------------------------------------
  -- Adder/Subtractor: R ± D (extend D to 5 bits with leading '0')
  ----------------------------------------------------------------------------
  U_ADD : adder_subtractor_5bit
    port map(
      i_A_v       => R_val,
      i_B_v       => ('0' & D_val),
      i_Carry_in  => ctrl_sub,      -- convention: 0 add, 1 subtract (depends on your block)
      o_Carry_out => add_co,
      o_Zero      => add_zero,
      o_overFlow  => o_overflow,
      o_Sum_vect  => add_sum
    );

  ----------------------------------------------------------------------------
  -- Iteration counter N
  ----------------------------------------------------------------------------
  N_cnt : dec_counter4
    port map(
      i_clock    => i_clock,
      i_resetBar => i_resetBar,
      i_load     => ctrl_loadN,
      i_dec      => ctrl_decN,
      i_din      => i_N_init,
      o_q        => N_val,
      o_zero     => N_zero
    );

  ----------------------------------------------------------------------------
  -- Signed output latches (final state)
  ----------------------------------------------------------------------------
  Q_reg_sign : sign_applyQ4
    port map(
      i_clock      => i_clock,
      i_resetBar   => i_resetBar,
      i_load       => ctrl_LoadQ_S,
      i_Q4_mag     => Q_val,
      i_neg        => (D_sign xor Q0_sign),  -- quotient sign = dividend ^ divisor
      o_Q4_signed  => Q_signed_val
    );

  R_reg_sign : sign_applyR5_to4
    port map(
      i_clock      => i_clock,
      i_resetBar   => i_resetBar,
      i_load       => ctrl_LoadR_S,
      i_R5_mag     => R_val,
      i_neg        => Q0_sign,               -- remainder sign usually = dividend sign
      o_R4_signed  => R_signed_val
    );

  ----------------------------------------------------------------------------
  -- Outputs
  ----------------------------------------------------------------------------
  o_Q_signed  <= Q_signed_val;
  o_R_signed  <= R_signed_val;
  o_msb_R     <= R_msb;
  o_N_is_zero <= N_zero;
 
end architecture rtl;
