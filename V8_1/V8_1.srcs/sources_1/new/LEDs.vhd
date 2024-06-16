library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.ALL;

entity leds is
    port (
        Clock    : in    std_logic;
        Switches : in    std_logic_vector(3 downto 0);
        Buttons  : in    std_logic_vector(3 downto 0);
        LEDs     : out   std_logic_vector(3 downto 0)
    );
end entity leds;

architecture Behavioral of leds is

    signal ClockCounter : integer range 0 to 625 := 0;
    signal LEDCounter   : integer range 0 to 3   := 0;

    procedure Increment is
    begin

        if ClockCounter = 625 then
            ClockCounter <= 0;

            if LEDCounter = 3 then
                LEDCounter <= 0;
            else
                LEDCounter <= LEDCounter + 1;
            end if;
        else
            ClockCounter <= ClockCounter + 1;
        end if;

    end procedure;

begin

    -- Use 125 MHz Clock to generate LedCounter that counts from 0 to 3 with 200 KHz
    LEDClockRising : process (Clock) is
    begin

        if rising_edge(Clock) then
            Increment;
        end if;

    end process LEDClockRising;

    LEDClockFalling : process (Clock) is
    begin

        if falling_edge(Clock) then
            Increment;
        end if;

    end process LEDClockFalling;

    LEDDriver : process (LEDCounter) is
    -- Drive LEDs with 25% Duty cycle
    begin

        for i in 0 to 3 loop

            if LEDCounter = i then
                LEDs(i) <= Switches(i);
            else
                LEDs(i) <= '0';
            end if;

        end loop;

    end process LEDDriver;

end architecture Behavioral;
