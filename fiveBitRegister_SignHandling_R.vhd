library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- 5-bit internal R with sign handling; exposes a 4-bit public remainder.
entity fiveBitRegister_SignHandling_R is
  port(
    i_resetBar       : in  std_logic;                       -- active-low async reset
    i_clock          : in  std_logic;
    i_load           : in  std_logic;                       -- load 5-bit magnitude
    i_handling_Sign  : in  std_logic;                       -- when '1': two's complement current value (one-cycle pulse)
    i_Value5         : in  std_logic_vector(4 downto 0);    -- 5-bit magnitude input
    o_Value5_dbg     : out std_logic_vector(4 downto 0);    -- optional: internal 5-bit (for debug/wiring)
    o_Value4         : out std_logic_vector(3 downto 0)     -- published 4-bit remainder
  );
end fiveBitRegister_SignHandling_R;

architecture rtl of fiveBitRegister_SignHandling_R is
  signal int_value : unsigned(4 downto 0);
begin
  process(i_clock, i_resetBar)
  begin
    if i_resetBar = '0' then
      int_value <= (others => '0');
    elsif rising_edge(i_clock) then
      -- Priority: load magnitude first, then optional sign handling
      if i_load = '1' then
        int_value <= unsigned(i_Value5);
      elsif i_handling_Sign = '1' then
        int_value <= (not int_value) + 1;   -- 5-bit two's complement
      end if;
    end if;
  end process;

  -- Expose internal (useful in sim/debug; ignore if not needed)
  o_Value5_dbg <= std_logic_vector(int_value);

  -- Publish only 4 LSBs after final state (safe: |R| ≤ 7)
  o_Value4 <= std_logic_vector(int_value(3 downto 0));
end rtl;
