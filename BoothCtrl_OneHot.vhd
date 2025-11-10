library ieee;
use ieee.std_logic_1164.all;

entity BoothCtrl_OneHot is
  port (
    i_clock, i_resetBar : in  std_logic;

    -- status from datapath
    i_Q1, i_Q0          : in  std_logic;  -- Q0 = LSB of multiplier, Q1 = FF (previous Q0)
    i_N_zero            : in  std_logic;  -- '1' when registered N = 0

    -- one-hot state taps (for LEDs / debug)
    S0_LOAD             : out std_logic;
    S1_SUB              : out std_logic;
    S2_ADD              : out std_logic;
    S3_SHIFT            : out std_logic;
    S4_DONE             : out std_logic;

    -- datapath controls
    o_loadM             : out std_logic;          -- load M
    o_selQ_1, o_selQ_0  : out std_logic;          -- Q: 00 hold, 01 load, 1X shift
    o_selA_1, o_selA_0  : out std_logic;          -- A: 00 hold, 01 load, 1X shift (arith)
    o_A_load_zero       : out std_logic;          -- clear A in LOAD
    o_sub               : out std_logic;          -- 1=SUB, 0=ADD
    o_selN_1, o_selN_0  : out std_logic;          -- N: 00 hold, 01 load, 1X dec
    o_enQ1              : out std_logic;  -- enable Q1 FF
    ctrl_latchProduct   : out std_logic;
	 o_done              : out std_logic
  );
end BoothCtrl_OneHot;

architecture rtl of BoothCtrl_OneHot is
  -- One-hot record
  type oh_t is record
    s0, sT, s1, s2, s3, s4 : std_logic;
  end record;

  signal st, nx : oh_t;

  -- Booth decision
  signal cond_sub, cond_add : std_logic;
begin
  -----------------------------------------------------------------------------
  -- Booth pair decode (based on Q1,Q0 captured in datapath)
  -----------------------------------------------------------------------------
  cond_sub <= (not i_Q0) and  i_Q1;   -- 10 → subtract M
  cond_add <=  i_Q0 and (not i_Q1);   -- 01 → add M
  -- 00 or 11 → just shift

  -----------------------------------------------------------------------------
  -- State register (active-low async reset)
  -----------------------------------------------------------------------------
  state_reg : process(i_clock, i_resetBar)
  begin
    if i_resetBar = '0' then
      st.s0 <= '1'; st.sT <= '0'; st.s1 <= '0';
      st.s2 <= '0'; st.s3 <= '0'; st.s4 <= '0';
    elsif rising_edge(i_clock) then
      st <= nx;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Next-state logic
  -- S0: LOAD inputs (M,Q,A=0,N preset)
  -- S_T: Test/branch (also where we STOP if N==0 after last shift)
  -- S1: ADD (A <- A + M)
  -- S2: SUB (A <- A - M)
  -- S3: SHIFT (arith shift {A,Q,Q-1} & N := N - 1)
  -- S4: DONE (latched)
  -----------------------------------------------------------------------------
  next_state : process(st, cond_sub, cond_add, i_N_zero)
  begin
    -- defaults
    nx.s0 <= '0'; nx.sT <= '0'; nx.s1 <= '0';
    nx.s2 <= '0'; nx.s3 <= '0'; nx.s4 <= '0';

    if st.s0 = '1' then
      -- After LOAD, go test
      nx.sT <= '1';

    elsif st.sT = '1' then
      -- IMPORTANT: stop check happens here (N seen AFTER last S3 decrement)
      if i_N_zero = '1' then
        nx.s4 <= '1';                -- finished
      elsif cond_sub = '1' then
        nx.s1 <= '1';
      elsif cond_add = '1' then
        nx.s2 <= '1';
      else
        nx.s3 <= '1';                -- shift only
      end if;

    elsif st.s1 = '1' then
      nx.s3 <= '1';                  -- ADD → SHIFT

    elsif st.s2 = '1' then
      nx.s3 <= '1';                  -- SUB → SHIFT

    elsif st.s3 = '1' then
      nx.sT <= '1';                  -- SHIFT → TEST (no stop check here)

    else
      -- S4 DONE: stay done forever
      nx.s4 <= '1';
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Control outputs
  -- (Gate shifting in DONE so nothing moves after o_done=1)
  -----------------------------------------------------------------------------
  -- Handy “not done”
  -- (use simple boolean combining to stop motion in DONE)
  -- You can remove the gating if your datapath ignores selects when done.
  -- Here we keep it safe.
  --  nd = '1' when not in DONE
  --  (VHDL doesn't allow boolean signals directly here; we derive from st.s4)
  -----------------------------------------------------------------------------

  -- datapath control
  o_loadM       <= st.s0;                           -- load M in LOAD
  o_selQ_0      <= st.s0;                           -- load Q in LOAD
  o_selA_0      <= (st.s0 or st.s1 or st.s2);       -- load/acc write in LOAD/ADD/SUB
  o_A_load_zero <= st.s0;                           -- clear A in LOAD

  -- shift/dec happen only in S3 and NOT in DONE
  o_selQ_1      <= st.s3 and (not st.s4);           -- Q shift enable
  o_selA_1      <= st.s3 and (not st.s4);           -- A arith shift enable
  o_selN_1      <= st.s3 and (not st.s4);           -- N decrement
  o_selN_0      <= st.s0;                           -- N load in LOAD

  o_sub         <= st.s2;                           -- 1 only in SUB
  o_enQ1        <= '1';                             -- always enable Q1 FF (safe)

  -- state taps / done
  S0_LOAD  <= st.s0;  S1_SUB   <= st.s2;            -- note: st.s2 is SUB state
  S2_ADD   <= st.s1;                                -- (swap names if you prefer)
  S3_SHIFT <= st.s3;  S4_DONE  <= st.s4;
  o_done   <= st.s4;
  ctrl_latchProduct<= st.s4;
end rtl;
