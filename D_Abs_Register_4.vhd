library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity D_Abs_Register_4 is
  port(
    i_resetBar : in  std_logic;
    i_clock    : in  std_logic;

    i_load     : in  std_logic;                     -- load |i_Divisor|
    i_to_mag   : in  std_logic;                     -- optional: abs current D

    i_Divisor  : in  std_logic_vector(3 downto 0);  -- signed 4-bit
    o_D_abs    : out std_logic_vector(3 downto 0)   -- stored |Divisor|
  );
end D_Abs_Register_4 ;

architecture rtl of D_Abs_Register_4 is
  signal dreg : std_logic_vector(3 downto 0);

  function abs4(x: std_logic_vector(3 downto 0)) return std_logic_vector is
  begin
    if x(3)='1' then
      return std_logic_vector(unsigned(not x) + 1); -- two's complement
    else
      return x;
    end if;
  end function;
begin
  process(i_clock, i_resetBar)
  begin
    if i_resetBar='0' then
      dreg <= (others=>'0');
    elsif rising_edge(i_clock) then
      if i_load='1' then
        dreg <= abs4(i_Divisor);    -- convert to |Divisor| on load
      elsif i_to_mag='1' then
        dreg <= abs4(dreg);          -- (optional) re-abs current content
      end if;
    end if;
  end process;

  o_D_abs <= dreg;
end rtl;
