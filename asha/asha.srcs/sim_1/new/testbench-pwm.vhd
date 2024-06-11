library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;

entity TestbenchPWM is
--  Port ( );
end entity TestbenchPWM;

architecture Behavioral of TestbenchPWM is

    component AshaPWM is
        port (
            Clock                : in    std_logic;
            Reset                : in    std_logic;
            EnPWMClock           : in    std_logic;
            PWM1FanInsideValue   : in    std_logic_vector(7 downto 0);
            PWM2FanOutsideValue  : in    std_logic_vector(7 downto 0);
            PWM3LightValue       : in    std_logic_vector(7 downto 0);
            PWM4PeltierValue     : in    std_logic_vector(7 downto 0);
            PWM1FanInsideSignal  : out   std_logic;
            PWM2FanOutsideSignal : out   std_logic;
            PWM3LightSignal      : out   std_logic;
            PWM4PeltierSignal    : out   std_logic
        );
    end component;

    signal Clock                : std_logic;
    signal Reset                : std_logic;
    signal EnPWMClock           : std_logic;
    signal PWM1FanInsideSignal  : std_logic;
    signal PWM2FanOutsideSignal : std_logic;
    signal PWM3LightSignal      : std_logic;
    signal PWM4PeltierSignal    : std_logic;
    signal PWM1FanInsideValue   : std_logic_vector(7 downto 0);
    signal PWM2FanOutsideValue  : std_logic_vector(7 downto 0);
    signal PWM3LightValue       : std_logic_vector(7 downto 0);
    signal PWM4PeltierValue     : std_logic_vector(7 downto 0);

begin

    UUT : component AshaPWM
        port map (
            Clock                => Clock,
            Reset                => Reset,
            EnPWMClock           => EnPWMClock,
            PWM1FanInsideSignal  => PWM1FanInsideSignal,
            PWM2FanOutsideSignal => PWM2FanOutsideSignal,
            PWM3LightSignal      => PWM3LightSignal,
            PWM4PeltierSignal    => PWM4PeltierSignal,
            PWM1FanInsideValue   => PWM1FanInsideValue,
            PWM2FanOutsideValue  => PWM2FanOutsideValue,
            PWM3LightValue       => PWM3LightValue,
            PWM4PeltierValue     => PWM4PeltierValue
        );

    -- Clock mit  MHz
    clk : process is
    begin

        while true loop

            Clock <= '0';
            wait for 500 ps;
            Clock <= '1';
            wait for 500 ps;

        end loop;

    end process clk;

    -- Clock mit MHz
    enClk : process is
    begin

        while true loop

            EnPWMClock <= '0';
            wait for 1 ns;
            EnPWMClock <= '1';
            wait for 1 ns;

        end loop;

    end process enClk;

    stim_proc : process is
    begin

        -- PWM1 mit voll
        PWM1FanInsideValue <= "11111111";
        -- PWM2 nie
        PWM2FanOutsideValue <= "00000000";
        -- PWM3 mit 1/8
        PWM3LightValue <= "00100000";
        -- PWM4 mit 1/4
        PWM4PeltierValue <= "01000000";
        wait;

    end process stim_proc;

    Reset <= '0';

end architecture Behavioral;
