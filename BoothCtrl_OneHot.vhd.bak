library ieee;
use ieee.std_logic_1164.all;

entity BoothCtrl_OneHot is
  port (
    i_clock, i_resetBar : in  std_logic;
    i_start             : in  std_logic;

    -- status from datapath
    i_Q1, i_Q0          : in  std_logic;    -- current Q1 and Q0
    i_N_zero            : in  std_logic;    -- counter zero flag

    -- one-hot state taps (for your notes / LEDs)
    S0_LOAD             : out std_logic;
    S1_SUB              : out std_logic;
    S2_ADD              : out std_logic;
    S3_SHIFT            : out std_logic;
    S4_DONE             : out std_logic;

    -- datapath controls (match your modules)
    o_loadM             : out std_logic;            -- fourBitRegister M
    o_selQ_1, o_selQ_0  : out std_logic;            -- Right_Shift Q
    o_selA_1, o_selA_0  : out std_logic;            -- Right_Shift A
    o_A_load_zero       : out std_logic;            -- A load ZERO when 1
    o_sub               : out std_logic;            -- adder_subtractor: 1=SUB, 0=ADD
    o_selN_1, o_selN_0  : out std_logic;            -- N: 00 hold, 01 load, 1X dec
    o_enQ1              : out std_logic;            -- enable Q1 FF
    o_done              : out std_logic
  );
end BoothCtrl_OneHot;

architecture rtl of BoothCtrl_OneHot is
  -- one-hot internal state register
  type oh_t is record
    s0, s1, s2, s3, s4 : std_logic;
  end record;
  signal st, nx : oh_t;

  -- Q-bit conditions
  signal cond_sub, cond_add, cond_shft : std_logic;
begin
  ---------------------------------------------------------------------------
  -- Q-pair decode:  S1 when 10, S2 when 01, S3 when 00 or 11 (XNOR)
  ---------------------------------------------------------------------------
  cond_sub  <= i_Q1 and (not i_Q0);          -- 10
  cond_add  <= (not i_Q1) and i_Q0;          -- 01
  cond_shft <= not (i_Q1 xor i_Q0);          -- 00 or 11 (XNOR)

  ---------------------------------------------------------------------------
  -- State register
  ---------------------------------------------------------------------------
  process(i_clock, i_resetBar)
  begin
    if i_resetBar = '0' then
      st.s0 <= '1'; st.s1 <= '0'; st.s2 <= '0'; st.s3 <= '0'; st.s4 <= '0';
    elsif rising_edge(i_clock) then
      st <= nx;
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- Next-state logic (one-hot)
  -- S0 -> (load all) -> branch by Q-pair
  -- S1 (SUB) -> S3
  -- S2 (ADD) -> S3
  -- S3 (SHIFT/DEC) -> S4 when zeroFlag=1 else branch again by Q-pair
  -- S4 holds done; restart on i_start
  ---------------------------------------------------------------------------
  process(st, cond_sub, cond_add, cond_shft, i_N_zero, i_start)
  begin
    -- defaults
    nx.s0 <= '0'; nx.s1 <= '0'; nx.s2 <= '0'; nx.s3 <= '0'; nx.s4 <= '0';

    if st.s0 = '1' then
      -- after load/clear, pick path for first arithmetic step
      if    cond_sub  = '1' then nx.s1 <= '1';
      elsif cond_add  = '1' then nx.s2 <= '1';
      else                       nx.s3 <= '1';  -- cond_shft
      end if;

    elsif st.s1 = '1' then
      nx.s3 <= '1';                              -- SUB then SHIFT

    elsif st.s2 = '1' then
      nx.s3 <= '1';                              -- ADD then SHIFT

    elsif st.s3 = '1' then                       -- SHIFT/DEC
      if i_N_zero = '1' then
        nx.s4 <= '1';
      else
        -- branch again for next arithmetic decision
        if    cond_sub = '1' then nx.s1 <= '1';
        elsif cond_add = '1' then nx.s2 <= '1';
        else                       nx.s3 <= '1'; -- consecutive shifts allowed
        end if;
      end if;

    else  -- st.s4 = DONE or any illegal
      if i_start = '1' then
        nx.s0 <= '1';
      else
        nx.s4 <= '1';
      end if;
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- Moore outputs per state (datapath control)
  ---------------------------------------------------------------------------
  -- Defaults (HOLD)
  o_loadM        <= st.s0;                  -- pulse in S0
  o_selQ_1       <= (st.s3);                -- 1X shift in S3
  o_selQ_0       <= '0';
  o_selA_1       <= (st.s3);                -- 1X shift in S3
  o_selA_0       <= (st.s0 or st.s1 or st.s2);   -- 01 load in S0/S1/S2
  o_A_load_zero  <= st.s0;                  -- clear A only in S0
  o_selN_1       <= (st.s3);                -- 1X decrement in S3
  o_selN_0       <= (st.s0);                -- 01 load N in S0
  o_enQ1         <= '1';                    -- always enabled

  -- adder mode: S1=sub, S2=add
  o_sub          <= st.s1;                  -- 1 when SUB, 0 when ADD/HOLD

  -- one-hot taps / done
  S0_LOAD  <= st.s0;  S1_SUB <= st.s1;  S2_ADD <= st.s2;  S3_SHIFT <= st.s3;  S4_DONE <= st.s4;
  o_done   <= st.s4;
end rtl;
