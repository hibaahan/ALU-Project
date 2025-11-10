library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Logical_Left_Shift_FiveBit_withMag is
  port(
    i_resetBar   : in  std_logic;                        -- active-low async reset
    i_clock      : in  std_logic;

    -- 00 = hold, 01 = load, 1x = logical left shift
    i_sel_0      : in  std_logic;                        -- LSB of select
    i_sel_1      : in  std_logic;                        -- MSB of select

    i_shift_in   : in  std_logic;                        -- bit entering LSB on shift
    i_toMag      : in  std_logic;                        -- when '1': convert contents to magnitude

    i_Value      : in  std_logic_vector(4 downto 0);     -- parallel load value (5-bit)
    o_Value      : out std_logic_vector(4 downto 0);     -- register contents (5-bit)
    o_value_msb  : out std_logic                         -- current MSB tap (bit 4)
  );
end entity;

architecture rtl of Logical_Left_Shift_FiveBit_withMag is
  signal int_Value : std_logic_vector(4 downto 0);       -- current state
  signal sl        : std_logic_vector(4 downto 0);       -- left-shifted value
begin
  -- Logical LEFT shift network (no sign extension)
  sl(4) <= int_Value(3);
  sl(3) <= int_Value(2);
  sl(2) <= int_Value(1);
  sl(1) <= int_Value(0);
  sl(0) <= i_shift_in;                                   -- new LSB on shift

  process(i_clock, i_resetBar)
  begin
    if i_resetBar = '0' then
      int_Value <= (others => '0');
    elsif rising_edge(i_clock) then
      -- hold / load / shift-left (10 or 11 both shift)
      if    (i_sel_1 = '0' and i_sel_0 = '0') then
        -- hold
      elsif (i_sel_1 = '0' and i_sel_0 = '1') then
        int_Value <= i_Value;                            -- parallel load
      else
        int_Value <= sl;                                 -- shift left
      end if;

      -- Convert to magnitude after load/shift in this cycle
      if i_toMag = '1' then
        if int_Value(4) = '1' then                       -- MSB (bit 4)
          int_Value <= std_logic_vector(unsigned(not int_Value) + 1);
        end if;
      end if;
    end if;
  end process;

  -- Outputs
  o_Value      <= int_Value;
  o_value_msb  <= int_Value(4);
end architecture;
