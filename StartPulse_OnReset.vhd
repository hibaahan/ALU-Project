library ieee;
use ieee.std_logic_1164.all;

entity StartPulse_OnReset is
    port(
        i_clock     : in  std_logic;
        i_resetBar  : in  std_logic;     -- your global async reset
        o_start_pulse : out std_logic    -- 1-clock-wide pulse
    );
end StartPulse_OnReset;

architecture rtl of StartPulse_OnReset is
    signal resetBar_d : std_logic := '0';
begin

    -- Register to capture previous value of resetBar
    process(i_clock, i_resetBar)
    begin
        if i_resetBar = '0' then
            resetBar_d <= '0';              -- when held in reset, clear memory
        elsif rising_edge(i_clock) then
            resetBar_d <= i_resetBar;       -- latch previous resetBar state
        end if;
    end process;

    -- Start pulse: HIGH only on 0→1 transition of resetBar
    o_start_pulse <= i_resetBar and (not resetBar_d);

end rtl;
