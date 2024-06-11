library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TestbenchVibe is
--  Port ( );
end TestbenchVibe;

architecture Behavioral of TestbenchVibe is
    component AshaVibe
    port (Clock, Reset, SensorVibe: in std_logic;
            SensorVibeHouseOn: out std_logic);
    end component;
    signal Clock, Reset, SensorVibe: std_logic;
    signal SensorVibeHouseOn: std_logic;
begin
    UUT: AshaVibe port map ( Clock => Clock, Reset => Reset, SensorVibe => SensorVibe, SensorVibeHouseOn => SensorVibeHouseOn);

    clk: process begin
        while true loop
            Clock <= '0';
            wait for 20 ns;
            Clock <= '1';
            wait for 20 ns;
        end loop;
    end process;
    
    stim_proc: process begin
        Reset <= '0';
        SensorVibe <= '0';    
        wait for 100 ns;
        SensorVibe <= '1';
        wait for 100 ns;
        SensorVibe <= '0';
        wait for 50 ns;
        SensorVibe <= '1';
        wait for 50 ns;
        Reset <= '1';
        wait for 50 ns;
        SensorVibe <= '1';
        wait;
    end process;
end Behavioral;
