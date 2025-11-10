library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Left_Shift_Q_four_bit_register is
  port(
    i_resetBar : in  std_logic;
    i_clock    : in  std_logic;
    i_sel_0    : in  std_logic;  -- LSB of select
    i_sel_1    : in  std_logic;  -- MSB of select
    i_to_mag   : in  std_logic;  -- when '1': convert current Q to magnitude
    i_Value    : in  std_logic_vector(3 downto 0);
    o_Value    : out std_logic_vector(3 downto 0);
    o_msb_tap  : out std_logic
  );
end Left_Shift_Q_four_bit_register;

architecture rtl of Left_Shift_Q_four_bit_register is
  signal int_Value : std_logic_vector(3 downto 0); -- current Q
  signal nxt_Value : std_logic_vector(3 downto 0); -- next Q
  signal sl        : std_logic_vector(3 downto 0); -- left-shifted value
begin
  -- Left shift network (fill LSB with '0')
  sl(3) <= int_Value(2);
  sl(2) <= int_Value(1);
  sl(1) <= int_Value(0);
  sl(0) <= '0';

  -- Combinational next-state logic (if/elsif)
  process(int_Value, i_to_mag, i_sel_1, i_sel_0, i_Value, sl)
  begin
    -- default
    nxt_Value <= int_Value;

    if i_to_mag = '1' then
      -- make magnitude: if negative, two's complement; else keep
      if int_Value(3) = '1' then
        nxt_Value <= std_logic_vector(unsigned(not int_Value) + 1);
      else
        nxt_Value <= int_Value;
      end if;

    elsif (i_sel_1 = '0' and i_sel_0 = '0') then
      -- hold: nxt_Value already = int_Valuei

    elsif (i_sel_1 = '0' and i_sel_0 = '1') then
      -- parallel load
      nxt_Value <= i_Value;

    else
      -- i_sel_1 = '1' (10 or 11): shift left
      nxt_Value <= sl;
    end if;
  end process;

  -- Registers
  process(i_clock, i_resetBar)
  begin
    if i_resetBar = '0' then
      int_Value <= (others => '0');
    elsif rising_edge(i_clock) then
      int_Value <= nxt_Value;
    end if;
  end process;

  -- Outputs
  o_Value   <= int_Value;
  o_msb_tap <= int_Value(3);  -- MSB before next shift
end rtl;
