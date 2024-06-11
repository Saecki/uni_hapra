library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TestbenchPWM is
--  Port ( );
end TestbenchPWM;

architecture Behavioral of TestbenchPWM is

    component AshaPWM
    port (Clock, Reset, EnPWMClock: in std_logic;
            PWM1FanInsideValue, PWM2FanOutsideValue, PWM3LightValue, PWM4PeltierValue: in std_logic_vector(7 downto 0);
            PWM1FanInsideSignal, PWM2FanOutsideSignal, PWM3LightSignal, PWM4PeltierSignal: out std_logic);
    end component;

    signal Clock, Reset, EnPWMClock: std_logic;
    signal PWM1FanInsideSignal, PWM2FanOutsideSignal, PWM3LightSignal, PWM4PeltierSignal: std_logic;
    signal PWM1FanInsideValue, PWM2FanOutsideValue, PWM3LightValue, PWM4PeltierValue: std_logic_vector(7 downto 0);

begin
    UUT: AshaPWM port map (
        Clock => Clock,
        Reset => Reset,
        EnPWMClock => EnPWMClock,
        PWM1FanInsideSignal => PWM1FanInsideSignal,
        PWM2FanOutsideSignal => PWM2FanOutsideSignal,
        PWM3LightSignal => PWM3LightSignal,
        PWM4PeltierSignal => PWM4PeltierSignal,
        PWM1FanInsideValue => PWM1FanInsideValue,
        PWM2FanOutsideValue => PWM2FanOutsideValue,
        PWM3LightValue => PWM3LightValue,
        PWM4PeltierValue => PWM4PeltierValue
    );

    -- Clock mit  MHz
    clk: process begin
        while true loop
            Clock <= '0';
            wait for 500 ps;
            Clock <= '1';
            wait for 500 ps;
        end loop;
    end process;

    -- Clock mit MHz
    enClk: process begin
        while true loop
            EnPWMClock <= '0';
            wait for 1 ns;
            EnPWMCLock <= '1';
            wait for 1 ns;
        end loop;
    end process;

    stim_proc: process begin
        --PWM1 mit voll
        PWM1FanInsideValue <= "11111111";
        --PWM2 nie
        PWM2FanOutsideValue <= "00000000";
        --PWM3 mit 1/8
        PWM3LightValue <= "00100000";
        --PWM4 mit 1/4
        PWM4PeltierValue <= "01000000";
        wait;
    end process;

    Reset <= '0';
end Behavioral;
