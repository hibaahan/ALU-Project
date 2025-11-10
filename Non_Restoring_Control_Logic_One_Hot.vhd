library ieee;
use ieee.std_logic_1164.all;

entity Non_Restoring_Control_Logic_One_Hot is
  port(
    -- global
    i_clock      : in  std_logic;
    i_resetBar   : in  std_logic;

    -- status from datapath
    i_msb_R      : in  std_logic;  -- 0 => R >= 0 ; 1 => R < 0
    i_N_is_zero  : in  std_logic;  -- loop counter done

    -- controls to datapath
    ctrl_loadD   : out std_logic;
    ctrl_loadQ   : out std_logic;
    ctrl_loadN   : out std_logic;
    ctrl_clearR  : out std_logic;

    ctrl_shiftR  : out std_logic;
    ctrl_shiftQ  : out std_logic;

    ctrl_loadR   : out std_logic;  -- write ALU result into R
    ctrl_sub     : out std_logic;  -- 1 = R - D, 0 = R + D

    ctrl_setlsb  : out std_logic;  -- write Q(0)
    ctrl_inlsb   : out std_logic;  -- value for Q(0)

    ctrl_decN    : out std_logic;

    ctrl_LoadQ_S : out std_logic;  -- latch signed Q (final)
    ctrl_LoadR_S : out std_logic;  -- latch signed R (final)

    o_done       : out std_logic   -- 1 in S5 (results ready)
  );
end Non_Restoring_Control_Logic_One_Hot;

architecture rtl of Non_Restoring_Control_Logic_One_Hot is

  ---------------------------------------------------------------------------
  -- D-FF primitive (same as your style)
  ---------------------------------------------------------------------------
  component enARdFF_2 is
    port(
      i_resetBar : in  std_logic;
      i_d        : in  std_logic;
      i_enable   : in  std_logic;
      i_clock    : in  std_logic;
      o_q        : out std_logic;
      o_qBar     : out std_logic
    );
  end component;

  ---------------------------------------------------------------------------
  -- One-hot states
  ---------------------------------------------------------------------------
  signal S0, S1, S2, S3, S4, S5 : std_logic;
  -- next-state drive signals (combinational)
  signal d_S1, d_S2, d_S3, d_S4, d_S5 : std_logic;

  -- helper: R >= 0 ?
  signal r_nonneg : std_logic;
begin
  r_nonneg <= not i_msb_R;

  ----------------------------------------------------------------------------
  -- Next-state equations (pure combinational)
  -- S0 is generated as a one-shot using qBar trick (see flip-flop below)
  ----------------------------------------------------------------------------
  d_S1 <= S0 or (S3  and (not i_N_is_zero));  -- start loop or keep looping
  d_S2 <= S1;                                 -- compute after shift
  d_S3 <= S2;                                 -- then decrement
  d_S4 <= S3 and i_N_is_zero;                 -- when counter just finished
  d_S5 <= S4;                                 -- latch outputs one cycle

  ----------------------------------------------------------------------------
  -- State flip-flops (exact same style as your multiplier controller)
  ----------------------------------------------------------------------------

  -- S0: INIT one-shot. qBar gives a single '1' pulse for S0 after reset.
  S0_init : enARdFF_2
    port map(
      i_resetBar => i_resetBar,
      i_d        => '1',      -- o_q becomes '1' after first clock
      i_enable   => '1',
      i_clock    => i_clock,
      o_q        => open,
      o_qBar     => S0        -- S0 is high only directly after reset release
    );

  S1_shift : enARdFF_2
    port map(
      i_resetBar => i_resetBar,
      i_d        => d_S1,
      i_enable   => '1',
      i_clock    => i_clock,
      o_q        => S1,
      o_qBar     => open
    );

  S2_decide : enARdFF_2
    port map(
      i_resetBar => i_resetBar,
      i_d        => d_S2,
      i_enable   => '1',
      i_clock    => i_clock,
      o_q        => S2,
      o_qBar     => open
    );

  S3_decn : enARdFF_2
    port map(
      i_resetBar => i_resetBar,
      i_d        => d_S3,
      i_enable   => '1',
      i_clock    => i_clock,
      o_q        => S3,
      o_qBar     => open
    );

  S4_fix : enARdFF_2
    port map(
      i_resetBar => i_resetBar,
      i_d        => d_S4,
      i_enable   => '1',
      i_clock    => i_clock,
      o_q        => S4,
      o_qBar     => open
    );

  S5_latch : enARdFF_2
    port map(
      i_resetBar => i_resetBar,
      i_d        => d_S5,
      i_enable   => '1',
      i_clock    => i_clock,
      o_q        => S5,
      o_qBar     => open
    );

  ----------------------------------------------------------------------------
  -- Control signal equations (concurrent assigns) — same “OR states” style
  ----------------------------------------------------------------------------

  -- S0: load operands & counter; clear R
  ctrl_loadD   <= S0;
  ctrl_loadQ   <= S0;
  ctrl_loadN   <= S0;
  ctrl_clearR  <= S0;

  -- S1: coupled shift
  ctrl_shiftR  <= S1;
  ctrl_shiftQ  <= S1;

  -- S2: decide and write back into R; set Q(0)
  ctrl_loadR   <= S2 or (S4 and i_msb_R);      -- also load in S4 only if R<0
  ctrl_setlsb  <= S2;
  ctrl_inlsb   <= S2 and r_nonneg;             -- 1 when R>=0
  ctrl_sub     <= S2 and r_nonneg;             -- subtract when R>=0; add otherwise

  -- S3: decrement loop counter
  ctrl_decN    <= S3;

  -- S4: final correction uses add; we already gate ctrl_loadR above
  --     (ctrl_sub = '0' in S4 by default)

  -- S5: latch signed outputs and pulse done
  ctrl_LoadQ_S <= S5;
  ctrl_LoadR_S <= S5;
  o_done       <= S5;

end architecture;
