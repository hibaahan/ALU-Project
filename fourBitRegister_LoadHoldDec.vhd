LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY fourBitRegister_LoadHoldDec IS
  PORT (
    i_resetBar : IN  STD_LOGIC;                       -- async reset, active low
    i_clock    : IN  STD_LOGIC;
    i_sel_0    : IN  STD_LOGIC;                       -- control select (LSB)
    i_sel_1    : IN  STD_LOGIC;                       -- control select (MSB)
    i_Value    : IN  STD_LOGIC_VECTOR(3 downto 0);    -- parallel load value
    o_Value    : OUT STD_LOGIC_VECTOR(3 downto 0);    -- register contents
    o_zero     : OUT STD_LOGIC                        -- flag when value=0000
  );
END fourBitRegister_LoadHoldDec;

ARCHITECTURE rtl OF fourBitRegister_LoadHoldDec IS
  SIGNAL int_Value : STD_LOGIC_VECTOR(3 downto 0);  -- Q (current)
  SIGNAL dec_Value : STD_LOGIC_VECTOR(3 downto 0);  -- (Q - 1)
  SIGNAL nxt_Value : STD_LOGIC_VECTOR(3 downto 0);  -- D (next)

  COMPONENT enARdFF_2
    PORT(
      i_resetBar : IN  STD_LOGIC;
      i_d        : IN  STD_LOGIC;
      i_enable   : IN  STD_LOGIC;
      i_clock    : IN  STD_LOGIC;
      o_q        : OUT STD_LOGIC
    );
  END COMPONENT;

  COMPONENT Mux4_1 IS
    PORT(
      i_val_0, i_val_1, i_val_2, i_val_3 : IN STD_LOGIC;
      i_sel_0, i_sel_1 : IN STD_LOGIC;
      o_val : OUT STD_LOGIC
    );
  END COMPONENT;

  SIGNAL b1, b2, b3 : STD_LOGIC; -- borrow chain
BEGIN
  -------------------------------------------------------------------
  -- Ripple-borrow decrementer
  -------------------------------------------------------------------
  dec_Value(0) <= NOT int_Value(0);
  b1           <= NOT int_Value(0);

  dec_Value(1) <= int_Value(1) XOR b1;
  b2           <= (NOT int_Value(1)) AND b1;

  dec_Value(2) <= int_Value(2) XOR b2;
  b3           <= (NOT int_Value(2)) AND b2;

  dec_Value(3) <= int_Value(3) XOR b3;

  -------------------------------------------------------------------
  -- MUX + FF for each bit
  -------------------------------------------------------------------
  bit3MUX : Mux4_1 PORT MAP(
    i_val_0 => int_Value(3),   -- Hold
    i_val_1 => i_Value(3),     -- Load
    i_val_2 => dec_Value(3),   -- Decrement
    i_val_3 => dec_Value(3),   -- Decrement (1X)
    i_sel_0 => i_sel_0, i_sel_1 => i_sel_1,
    o_val   => nxt_Value(3)
  );
  bit3FF : enARdFF_2 PORT MAP(i_resetBar=>i_resetBar, i_d=>nxt_Value(3), i_enable=>'1', i_clock=>i_clock, o_q=>int_Value(3));

  bit2MUX : Mux4_1 PORT MAP(
    i_val_0 => int_Value(2),
    i_val_1 => i_Value(2),
    i_val_2 => dec_Value(2),
    i_val_3 => dec_Value(2),
    i_sel_0 => i_sel_0, i_sel_1 => i_sel_1,
    o_val   => nxt_Value(2)
  );
  bit2FF : enARdFF_2 PORT MAP(i_resetBar=>i_resetBar, i_d=>nxt_Value(2), i_enable=>'1', i_clock=>i_clock, o_q=>int_Value(2));

  bit1MUX : Mux4_1 PORT MAP(
    i_val_0 => int_Value(1),
    i_val_1 => i_Value(1),
    i_val_2 => dec_Value(1),
    i_val_3 => dec_Value(1),
    i_sel_0 => i_sel_0, i_sel_1 => i_sel_1,
    o_val   => nxt_Value(1)
  );
  bit1FF : enARdFF_2 PORT MAP(i_resetBar=>i_resetBar, i_d=>nxt_Value(1), i_enable=>'1', i_clock=>i_clock, o_q=>int_Value(1));

  bit0MUX : Mux4_1 PORT MAP(
    i_val_0 => int_Value(0),
    i_val_1 => i_Value(0),
    i_val_2 => dec_Value(0),
    i_val_3 => dec_Value(0),
    i_sel_0 => i_sel_0, i_sel_1 => i_sel_1,
    o_val   => nxt_Value(0)
  );
  bit0FF : enARdFF_2 PORT MAP(i_resetBar=>i_resetBar, i_d=>nxt_Value(0), i_enable=>'1', i_clock=>i_clock, o_q=>int_Value(0));

  -------------------------------------------------------------------
  -- Outputs
  -------------------------------------------------------------------
  o_Value <= int_Value;
  o_zero  <= '1' WHEN int_Value="0000" ELSE '0';
END rtl;
