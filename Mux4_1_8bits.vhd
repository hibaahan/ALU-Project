library ieee;
use ieee.std_logic_1164.all;

entity Mux4_1_8bits is
  port (
    -- 8-bit data inputs
    i_val_0 : in std_logic_vector(7 downto 0);
    i_val_1 : in std_logic_vector(7 downto 0);
    i_val_2 : in std_logic_vector(7 downto 0);
    i_val_3 : in std_logic_vector(7 downto 0);

    -- select bits (LSB = i_sel_0, MSB = i_sel_1)
    i_sel_0 : in std_logic;
    i_sel_1 : in std_logic;

    -- 8-bit output
    o_val   : out std_logic_vector(7 downto 0)
  );
end Mux4_1_8bits;

architecture rtl of Mux4_1_8bits is
  signal int_o_Sel1      : std_logic_vector(7 downto 0);
  signal int_o_not_Sel1  : std_logic_vector(7 downto 0);

  component Mux2_1
    port(
      i_val_0 : in  std_logic;
      i_val_1 : in  std_logic;
      i_sel   : in  std_logic;
      o_val   : out std_logic
    );
  end component;
begin

  gen_bits : for k in 7 downto 0 generate
    -- Lower stage: selects between (0,1) and (2,3) bit-by-bit using i_sel_0
    Mux2_1_1k : Mux2_1
      port map (
        i_val_0 => i_val_0(k),
        i_val_1 => i_val_1(k),
        i_sel   => i_sel_0,
        o_val   => int_o_not_Sel1(k)
      );

    Mux2_1_2k : Mux2_1
      port map (
        i_val_0 => i_val_2(k),
        i_val_1 => i_val_3(k),
        i_sel   => i_sel_0,
        o_val   => int_o_Sel1(k)
      );

    -- Upper stage: selects between results using i_sel_1
    Mux2_1_3k : Mux2_1
      port map (
        i_val_0 => int_o_not_Sel1(k),
        i_val_1 => int_o_Sel1(k),
        i_sel   => i_sel_1,
        o_val   => o_val(k)
      );
  end generate;

end rtl;
