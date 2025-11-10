library ieee;
use ieee.std_logic_1164.all;

entity Logical_Right_Shift_four_bit_register is
  port(
    i_resetBar   : in  std_logic;
    i_clock      : in  std_logic;
    -- Select: 00=hold, 01=load, 1X=logical right shift
    i_sel_0      : in  std_logic;   -- LSB of select
    i_sel_1      : in  std_logic;   -- MSB of select
    i_shift_in   : in  std_logic;   -- bit entering MSB on shift (e.g., A(0))
    i_Value      : in  std_logic_vector(3 downto 0);  -- parallel load
    o_Value      : out std_logic_vector(3 downto 0);
    o_value_lsb  : out std_logic
  );
end Logical_Right_Shift_four_bit_register;

architecture rtl of Logical_Right_Shift_four_bit_register is
  signal int_Value : std_logic_vector(3 downto 0); -- current state
  signal nxt_Value : std_logic_vector(3 downto 0); -- next state
  signal sr        : std_logic_vector(3 downto 0); -- shifted value

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
      i_val_0, i_val_1, i_val_2, i_val_3 : in  std_logic;
      i_sel_0, i_sel_1                   : in  std_logic;
      o_val                              : out std_logic
    );
  end component;

begin
  ---------------------------------------------------------------------------
  -- Logical right shift network (no sign extension)
  -- New MSB comes from i_shift_in; others shift right by one.
  ---------------------------------------------------------------------------
  sr(3) <= i_shift_in;
  sr(2) <= int_Value(3);
  sr(1) <= int_Value(2);
  sr(0) <= int_Value(1);

  -- Bit 3 (MSB)
  b3MUX : Mux4_1
    port map(
      i_val_0 => int_Value(3),   -- hold
      i_val_1 => i_Value(3),     -- load
      i_val_2 => sr(3),          -- shift (10)
      i_val_3 => sr(3),          -- shift (11)
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
      i_val_2 => sr(2),
      i_val_3 => sr(2),
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
      i_val_2 => sr(1),
      i_val_3 => sr(1),
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
      i_val_2 => sr(0),
      i_val_3 => sr(0),
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
  o_Value     <= int_Value;
  o_value_lsb <= int_Value(0);
end rtl;
