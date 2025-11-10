library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Arithmetic_Left_Shift_Q_four_bit_register is
  port(
    i_resetBar : in  std_logic;
    i_clock    : in  std_logic;

    -- 00 = hold, 01 = load, 1x = left shift (fill '0')
    i_sel_0    : in  std_logic;     -- LSB of select
    i_sel_1    : in  std_logic;     -- MSB of select

    -- Controls
    i_to_mag   : in  std_logic;     -- when '1': convert current Q to magnitude (abs)
    i_set_lsb  : in  std_logic;     -- when '1': force LSB = i_lsb_in on this cycle
    i_lsb_in   : in  std_logic;     -- bit to write into Q(0) when i_set_lsb='1'

    -- Data
    i_Value    : in  std_logic_vector(3 downto 0); -- parallel load
    o_Value    : out std_logic_vector(3 downto 0); -- current Q
    o_msb_tap  : out std_logic                      -- MSB before shift (feed R(0))
  );
end Arithmetic_Left_Shift_Q_four_bit_register;

architecture rtl of Arithmetic_Left_Shift_Q_four_bit_register is
  signal int_Value : std_logic_vector(3 downto 0); -- current Q
  signal nxt_Value : std_logic_vector(3 downto 0); -- next Q
  signal sl        : std_logic_vector(3 downto 0); -- left-shifted value
begin
  -- Left shift network (fill LSB with '0')
  sl(3) <= int_Value(2);
  sl(2) <= int_Value(1);
  sl(1) <= int_Value(0);
  sl(0) <= '0';

  -- Combinational next-state logic
  process(int_Value, i_to_mag, i_sel_1, i_sel_0, i_Value, sl, i_set_lsb, i_lsb_in)
  begin
    -- default
    nxt_Value <= int_Value;

    if i_to_mag = '1' then
      -- make magnitude
      if int_Value(3) = '1' then
        nxt_Value <= std_logic_vector(unsigned(not int_Value) + 1);
      else
        nxt_Value <= int_Value;
      end if;

    elsif (i_sel_1 = '0' and i_sel_0 = '0') then
      -- hold

    elsif (i_sel_1 = '0' and i_sel_0 = '1') then
      -- load
      nxt_Value <= i_Value;

    else
      -- shift left (10 or 11)
      nxt_Value <= sl;
    end if;

    -- Optional LSB override (used to set Q0 after decision)
    if i_set_lsb = '1' then
      nxt_Value(0) <= i_lsb_in;
    end if;
  end process;

  -- Registers
  process(i_clock, i_resetBar)
  begin
    if i_resetBar = '0' then
      int_Value <= (others => '0');
    elsif rising_edge(i_clock) then
      int_Value <= nxt_Value;  -- single write; LSB override already applied
    end if;
  end process;

  -- Outputs
  o_Value   <= int_Value;
  o_msb_tap <= int_Value(3);
end rtl;
