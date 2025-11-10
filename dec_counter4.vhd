library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dec_counter4 is
  port(
    i_clock    : in  std_logic;
    i_resetBar : in  std_logic;                        -- async active-low reset
    i_load   : in  std_logic;                        -- load enable
    i_dec    : in  std_logic;                        -- decrement enable
    i_din    : in  std_logic_vector(3 downto 0);     -- load value
    o_q      : out std_logic_vector(3 downto 0);     -- current count
    o_zero   : out std_logic                         -- '1' when count = 0
  );
end entity;

architecture rtl of dec_counter4 is
  signal r_cnt : unsigned(3 downto 0) := (others => '0');
begin

  process(i_clock, i_resetBar)
  begin
    if i_resetBar = '0' then
      r_cnt <= (others => '0');

    elsif rising_edge(i_clock) then
      if i_load = '1' then
        -- Load new value
        r_cnt <= unsigned(i_din);

      elsif i_dec = '1' then
        -- Decrement but don’t wrap below 0
        if r_cnt > 0 then
          r_cnt <= r_cnt - 1;
        else
          r_cnt <= r_cnt;   -- stay at 0
        end if;
      end if;
    end if;
  end process;

  o_q    <= std_logic_vector(r_cnt);
  o_zero <= '1' when r_cnt = 0 else '0';

end architecture;
