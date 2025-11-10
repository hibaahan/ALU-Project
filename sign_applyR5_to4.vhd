library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Registered "apply sign" for remainder:
--  - Inputs: |R| (5 bits), i_neg (desired sign)
--  - On i_load='1', computes 4-bit two's-complement with sign applied and latches it
--  - Output holds its value until next load or reset
entity sign_applyR5_to4 is
  port(
    i_clock        : in  std_logic;
    i_resetBar      : in  std_logic;                     -- async active-low reset
    i_load       : in  std_logic;                     -- latch new value when '1'
    i_R5_mag     : in  std_logic_vector(4 downto 0);  -- |R| (5-bit internal)
    i_neg        : in  std_logic;                     -- 1 => negative remainder
    o_R4_signed  : out std_logic_vector(3 downto 0)   -- 4-bit two's-comp remainder
  );
end entity;

architecture rtl of sign_applyR5_to4 is
  signal r_out : std_logic_vector(3 downto 0) := (others => '0');
begin
  process(i_clock, i_resetBar)
    variable m5  : unsigned(4 downto 0);
    variable m4s : signed(3 downto 0);
    variable res : signed(3 downto 0);
  begin
    if i_resetBar = '0' then
      r_out <= (others => '0');
    elsif rising_edge(i_clock) then
      if i_load = '1' then
        -- convert 5-bit magnitude to 4-bit signed (drop MSB), then apply sign
        m5  := unsigned(i_R5_mag);
        m4s := signed(std_logic_vector(m5(3 downto 0)));
        if i_neg = '1' then
          res := -m4s;
        else
          res := m4s;
        end if;
        r_out <= std_logic_vector(res);
      end if;
      -- else: hold previous value
    end if;
  end process;

  o_R4_signed <= r_out;
end architecture;
