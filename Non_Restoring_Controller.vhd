library ieee;
use ieee.std_logic_1164.all;

entity Non_Restoring_Controller is
  port(
    i_clock       : in  std_logic;
    i_resetBar    : in  std_logic;   -- async active-low reset
    i_start       : in  std_logic;   -- pulse/high to kick off one division

    -- status from datapath
    i_msb_R       : in  std_logic;   -- 0=>R>=0, 1=>R<0  (after shift)
    i_N_is_zero   : in  std_logic;   -- loop counter finished

    -- controls to datapath
    ctrl_loadD    : out std_logic;
    ctrl_loadQ    : out std_logic;
    ctrl_loadN    : out std_logic;
    ctrl_clearR   : out std_logic;

    ctrl_shiftR   : out std_logic;
    ctrl_shiftQ   : out std_logic;

    ctrl_loadR    : out std_logic;   -- write ALU result into R
    ctrl_sub      : out std_logic;   -- 1: R-D, 0: R+D

    ctrl_setlsb   : out std_logic;   -- write Q(0)
    ctrl_inlsb    : out std_logic;   -- value for Q(0)

    ctrl_decN     : out std_logic;

    ctrl_LoadQ_S  : out std_logic;   -- latch signed Q (final)
    ctrl_LoadR_S  : out std_logic;   -- latch signed R (final)

    o_done        : out std_logic    -- 1 for one cycle when results latched
  );
end entity;

architecture rtl of Non_Restoring_Controller is
  type state_t is (IDLE, S0_INIT, S1_SHIFT, S2_DECIDE, S3_DEC, S4_FIX, S5_LATCH);
  signal cur, nxt : state_t;

  -- local shortcuts for “R>=0 ?”
  signal r_nonneg : std_logic;
begin
  r_nonneg <= not i_msb_R;

  --------------------------------------------------------------------------
  -- State register
  --------------------------------------------------------------------------
  process(i_clock, i_resetBar)
  begin
    if i_resetBar = '0' then
      cur <= IDLE;
    elsif rising_edge(i_clock) then
      cur <= nxt;
    end if;
  end process;

  --------------------------------------------------------------------------
  -- Next-state logic
  --------------------------------------------------------------------------
  process(cur, i_start, i_N_is_zero)
  begin
    nxt <= cur;
    case cur is
      when IDLE     =>
        if i_start = '1' then
          nxt <= S0_INIT;
        end if;

      when S0_INIT  =>
        nxt <= S1_SHIFT;

      when S1_SHIFT =>
        nxt <= S2_DECIDE;

      when S2_DECIDE=>
        nxt <= S3_DEC;

      when S3_DEC   =>
        if i_N_is_zero = '1' then
          nxt <= S4_FIX;
        else
          nxt <= S1_SHIFT;
        end if;

      when S4_FIX   =>
        -- one cycle for optional correction, then latch
        nxt <= S5_LATCH;

      when S5_LATCH =>
        nxt <= IDLE;

      when others   =>
        nxt <= IDLE;
    end case;
  end process;

  --------------------------------------------------------------------------
  -- Output (control) logic — default low, assert per state
  --------------------------------------------------------------------------
  process(cur, r_nonneg, i_msb_R, i_N_is_zero)
  begin
    -- defaults
    ctrl_loadD   <= '0';
    ctrl_loadQ   <= '0';
    ctrl_loadN   <= '0';
    ctrl_clearR  <= '0';

    ctrl_shiftR  <= '0';
    ctrl_shiftQ  <= '0';

    ctrl_loadR   <= '0';
    ctrl_sub     <= '0';  -- default add (only matters when loadR=1)

    ctrl_setlsb  <= '0';
    ctrl_inlsb   <= '0';

    ctrl_decN    <= '0';

    ctrl_LoadQ_S <= '0';
    ctrl_LoadR_S <= '0';

    o_done       <= '0';

    case cur is
      ----------------------------------------------------------------------
      when S0_INIT =>
        -- Load operands & counter; clear R to 0
        ctrl_loadD  <= '1';
        ctrl_loadQ  <= '1';
        ctrl_loadN  <= '1';
        ctrl_clearR <= '1';

      ----------------------------------------------------------------------
      when S1_SHIFT =>
        -- Coupled shift so decision uses post-shift R
        ctrl_shiftR <= '1';
        ctrl_shiftQ <= '1';

      ----------------------------------------------------------------------
      when S2_DECIDE =>
        -- Decide using R after the shift:
        -- if R>=0: R := R - D ; Q0 := 1
        -- else   : R := R + D ; Q0 := 0
        ctrl_loadR  <= '1';
        ctrl_setlsb <= '1';
        ctrl_inlsb  <= r_nonneg;       -- 1 when R>=0 else 0
        ctrl_sub    <= r_nonneg;       -- 1 => subtract when R>=0

      ----------------------------------------------------------------------
      when S3_DEC =>
        ctrl_decN <= '1';              -- decrement loop counter

      ----------------------------------------------------------------------
      when S4_FIX =>
        -- Final correction: if R<0 then R := R + D
        if i_msb_R = '1' then
          ctrl_loadR <= '1';
          ctrl_sub   <= '0';           -- add D
        end if;
        -- DO NOT touch Q(0) here

      ----------------------------------------------------------------------
      when S5_LATCH =>
        -- Latch signed outputs (one cycle), signal done
        ctrl_LoadQ_S <= '1';
        ctrl_LoadR_S <= '1';
        o_done       <= '1';

      when others =>
        null;
    end case;
  end process;

end architecture;
