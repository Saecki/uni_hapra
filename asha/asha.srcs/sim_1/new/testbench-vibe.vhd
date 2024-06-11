library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;

entity TestbenchVibe is
--  Port ( );
end entity TestbenchVibe;

architecture Behavioral of TestbenchVibe is

    component AshaVibe is
        port (
            Clock             : in    std_logic;
            Reset             : in    std_logic;
            SensorVibe        : in    std_logic;
            SensorVibeHouseOn : out   std_logic
        );
    end component;

    signal Clock             : std_logic;
    signal Reset             : std_logic;
    signal SensorVibe        : std_logic;
    signal SensorVibeHouseOn : std_logic;

begin

    UUT : component AshaVibe
        port map (
            Clock             => Clock,
            Reset             => Reset,
            SensorVibe        => SensorVibe,
            SensorVibeHouseOn => SensorVibeHouseOn
        );

    clk : process is
    begin

        while true loop

            Clock <= '0';
            wait for 20 ns;
            Clock <= '1';
            wait for 20 ns;

        end loop;

    end process clk;

    stim_proc : process is
    begin

        Reset      <= '0';
        SensorVibe <= '0';
        wait for 100 ns;
        SensorVibe <= '1';
        wait for 100 ns;
        SensorVibe <= '0';
        wait for 50 ns;
        SensorVibe <= '1';
        wait for 50 ns;
        Reset      <= '1';
        wait for 50 ns;
        SensorVibe <= '1';
        wait;

    end process stim_proc;

end architecture Behavioral;
