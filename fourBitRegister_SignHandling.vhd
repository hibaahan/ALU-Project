library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fourBitRegister_SignHandling is
  port(
    i_resetBar       : in  std_logic;                  -- active-low async reset
    i_clock          : in  std_logic;
    i_load           : in  std_logic;                  -- load magnitude
    i_handling_Sign  : in  std_logic;                  -- when '1': twos-complement current value
    i_Value          : in  std_logic_vector(3 downto 0);
    o_Value          : out std_logic_vector(3 downto 0)
  );
end fourBitRegister_SignHandling;

architecture rtl of fourBitRegister_SignHandling is
  signal int_value : unsigned(3 downto 0);
begin
  process(i_clock, i_resetBar)
  begin
    if i_resetBar = '0' then
      int_value <= (others => '0');
    elsif rising_edge(i_clock) then
      -- Priority: load magnitude first, else (optionally) apply sign handling
      if i_load = '1' then
        int_value <= unsigned(i_Value);
      elsif i_handling_Sign = '1' then
        int_value <= (not int_value) + 1;   -- two's complement
      end if;
    end if;
  end process;

  o_Value <= std_logic_vector(int_value);
end rtl;
