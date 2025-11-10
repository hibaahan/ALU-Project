library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Registered apply-sign for quotient:
--  - On i_load='1', takes |Q| (4-bit) and i_neg, computes 4-bit two's-comp, and latches it.
entity sign_applyQ4 is
  port(
    i_clock        : in  std_logic;
    i_resetBar      : in  std_logic;                     -- async active-low reset
    i_load       : in  std_logic;                     -- latch new value when '1'
    i_Q4_mag     : in  std_logic_vector(3 downto 0);  -- |Q| (4-bit magnitude)
    i_neg        : in  std_logic;                     -- 1 => negative quotient
    o_Q4_signed  : out std_logic_vector(3 downto 0)   -- 4-bit two's-comp quotient
  );
end entity;

architecture rtl of sign_applyQ4 is
  signal r_out : std_logic_vector(3 downto 0) := (others => '0');
begin
  process(i_clock, i_resetBar)
    variable m   : unsigned(3 downto 0);
    variable sgn : signed(3 downto 0);
  begin
    if i_resetBar = '0' then
      r_out <= (others => '0');
    elsif rising_edge(i_clock) then
      if i_load = '1' then
        m   := unsigned(i_Q4_mag);
        sgn := signed(std_logic_vector(m));
        if i_neg = '1' then
          sgn := -sgn;
        end if;
        r_out <= std_logic_vector(sgn);
      end if;
    end if;
  end process;

  o_Q4_signed <= r_out;
end architecture;

