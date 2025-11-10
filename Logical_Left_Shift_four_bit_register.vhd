library ieee;
use ieee.std_logic_1164.all;

entity Logical_Left_Shift_four_bit_register is
  port(
    i_resetBar  : in  std_logic;
    i_clock     : in  std_logic;
    i_sel_0     : in  std_logic;  -- LSB of select
    i_sel_1     : in  std_logic;  -- MSB of select
    i_shift_in  : in  std_logic;  -- bit entering LSB on shift
    i_Value     : in  std_logic_vector(3 downto 0); -- parallel load
    o_Value     : out std_logic_vector(3 downto 0);
    o_value_msb : out std_logic
  );
end Logical_Left_Shift_four_bit_register;

architecture rtl of Logical_Left_Shift_four_bit_register is
  signal int_Value  : std_logic_vector(3 downto 0); -- current state
  signal nxt_Value  : std_logic_vector(3 downto 0); -- next state
  signal sl         : std_logic_vector(3 downto 0); -- left-shifted value

  component enARdFF_2 is
    port(
      i_resetBar : in  std_logic;
      i_d        : in  std_logic;
      i_enable   : in  std_logic;
      i_clock    : in  std_logic;
      o_q        : out std_logic
    );
  end component;

  component Mux4_1 is
    port(
      i_val_0 : in  std_logic; -- hold
      i_val_1 : in  std_logic; -- load
      i_val_2 : in  std_logic; -- shift (10)
      i_val_3 : in  std_logic; -- shift (11)
      i_sel_0 : in  std_logic;
      i_sel_1 : in  std_logic;
      o_val   : out std_logic
    );
  end component;
begin
  -------------------------------------------------------------------
  -- Logical LEFT shift network (no sign extension)
  -- New LSB comes from i_shift_in; others shift left by one.
  -------------------------------------------------------------------
  sl(3) <= int_Value(2);
  sl(2) <= int_Value(1);
  sl(1) <= int_Value(0);
  sl(0) <= i_shift_in;

  -- Bit 3 (MSB)
  b3MUX : Mux4_1
    port map(
      i_val_0 => int_Value(3),  -- hold
      i_val_1 => i_Value(3),    -- load
      i_val_2 => sl(3),         -- shift (10)
      i_val_3 => sl(3),         -- shift (11)
      i_sel_0 => i_sel_0,
      i_sel_1 => i_sel_1,
      o_val   => nxt_Value(3)
    );
  b3FF : enARdFF_2
    port map(
      i_resetBar => i_resetBar,
      i_d        => nxt_Value(3),
      i_enable   => '1',
      i_clock    => i_clock,
      o_q        => int_Value(3)
    );

  -- Bit 2
  b2MUX : Mux4_1
    port map(
      i_val_0 => int_Value(2),
      i_val_1 => i_Value(2),
      i_val_2 => sl(2),
      i_val_3 => sl(2),
      i_sel_0 => i_sel_0,
      i_sel_1 => i_sel_1,
      o_val   => nxt_Value(2)
    );
  b2FF : enARdFF_2
    port map(
      i_resetBar => i_resetBar,
      i_d        => nxt_Value(2),
      i_enable   => '1',
      i_clock    => i_clock,
      o_q        => int_Value(2)
    );

  -- Bit 1
  b1MUX : Mux4_1
    port map(
      i_val_0 => int_Value(1),
      i_val_1 => i_Value(1),
      i_val_2 => sl(1),
      i_val_3 => sl(1),
      i_sel_0 => i_sel_0,
      i_sel_1 => i_sel_1,
      o_val   => nxt_Value(1)
    );
  b1FF : enARdFF_2
    port map(
      i_resetBar => i_resetBar,
      i_d        => nxt_Value(1),
      i_enable   => '1',
      i_clock    => i_clock,
      o_q        => int_Value(1)
    );

  -- Bit 0 (LSB)
  b0MUX : Mux4_1
    port map(
      i_val_0 => int_Value(0),
      i_val_1 => i_Value(0),
      i_val_2 => sl(0),
      i_val_3 => sl(0),
      i_sel_0 => i_sel_0,
      i_sel_1 => i_sel_1,
      o_val   => nxt_Value(0)
    );
  b0FF : enARdFF_2
    port map(
      i_resetBar => i_resetBar,
      i_d        => nxt_Value(0),
      i_enable   => '1',
      i_clock    => i_clock,
      o_q        => int_Value(0)
    );

  -- Outputs
  o_Value      <= int_Value;
  o_value_msb  <= int_Value(3);
end rtl;
