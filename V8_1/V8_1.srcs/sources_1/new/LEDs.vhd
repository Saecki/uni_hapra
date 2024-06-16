library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;

entity leds is
    port (
        Clock    : in    std_logic;
        Switches : in    std_logic_vector(3 downto 0);
        Buttons  : in    std_logic_vector(3 downto 0);
        LEDs     : out   std_logic_vector(3 downto 0)
    );
end entity leds;

architecture Behavioral of leds is

    signal LEDClock : std_logic := '0';

    component led_controller is
        port (
            LEDClock : in    std_logic;
            Switch   : in    std_logic;
            Button   : in    std_logic;
            LED      : out   std_logic
        );
    end component;

begin

    -- 125 MHz to 50 KHz
    process (Clock) is

        variable ClockCounter : integer range 0 to 1250 := 0;

    begin

        if rising_edge(Clock) then
            if ClockCounter = 1250 then
                ClockCounter := 0;
                LEDClock     <= not LEDClock;
            else
                ClockCounter := ClockCounter + 1;
            end if;
        end if;

    end process;

    Controllers : for i in 0 to 3 generate

        LED_controller0 : component led_controller
            port map (
                LEDClock => LEDClock,
                Switch   => Switches(i),
                Button   => Buttons(i),
                LED      => LEDs(i)
            );

    end generate Controllers;

end architecture Behavioral;



