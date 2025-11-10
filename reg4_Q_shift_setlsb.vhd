library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- 4-bit Q (quotient builder):
-- - loads signed input but stores magnitude (abs) and exposes original sign
-- - supports left shift (logical; arithmetic left = logical left)
-- - can force the LSB to a control-provided bit in one cycle (ctrl for Q[0] during Decide step)
entity reg4_Q_shift_setlsb is
  port(
    i_clock      : in  std_logic;
    i_resetBar   : in  std_logic;                      -- async active-low reset
    i_clear     : in  std_logic;                      -- sync clear
    i_load     : in  std_logic;                      -- sync load (converts to |Q|)
    i_shift    : in  std_logic;                      -- left shift enable
    i_setlsb   : in  std_logic;                      -- when '1', write i_lsb into bit0 this cycle
    i_lsb      : in  std_logic;                      -- value to force into bit0
    i_Q_signed : in  std_logic_vector(3 downto 0);   -- signed input (two's comp)
    o_Q_mag    : out std_logic_vector(3 downto 0);   -- stored magnitude (used in core algo)
    o_Q_sign   : out std_logic                       -- original sign of loaded Q
  );
end entity;

architecture rtl of reg4_Q_shift_setlsb is
  signal r_mag  : std_logic_vector(3 downto 0) := (others => '0');
  signal r_sign : std_logic := '0';
begin
  process(i_clock , i_resetBar  )
    variable s : signed(3 downto 0);
    variable m : unsigned(3 downto 0);
    variable nxt : std_logic_vector(3 downto 0);
  begin
    if i_resetBar   = '0' then
      r_mag  <= (others => '0');
      r_sign <= '0';
    elsif rising_edge(i_clock) then
      if i_clear= '1' then
        r_mag  <= (others => '0');
        r_sign <= '0';
      elsif i_load = '1' then
        s := signed(i_Q_signed);
        r_sign <= s(3);
        if s(3) = '1' then
          m := unsigned(-s);     -- |Q|
        else
          m := unsigned(s);
        end if;
        r_mag <= std_logic_vector(m);
      elsif i_shift = '1' then
        -- left shift logical; bring in 0 at LSB (Decide step can override via i_setlsb)
        nxt := r_mag(2 downto 0) & '0';
        if i_setlsb = '1' then
          nxt(0) := i_lsb;
        end if;
        r_mag <= nxt;
      elsif i_setlsb = '1' then
        -- no shift this cycle, only force LSB
        r_mag(0) <= i_lsb;
      end if;
    end if;
  end process;

  o_Q_mag  <= r_mag;
  o_Q_sign <= r_sign;
end architecture;
