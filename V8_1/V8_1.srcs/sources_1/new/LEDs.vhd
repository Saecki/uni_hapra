library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.ALL;

entity leds is
    port (
        Clock    : in    std_logic;
        Switches : in    std_logic_vector(3 downto 0);
        Buttons  : in    std_logic_vector(3 downto 0);
        Pins     : out   std_logic_vector(3 downto 0)
    );
end entity leds;

architecture Behavioral of leds is

    signal ClockCounter : integer range 0 to 625 := 0;
    signal LedPwm    : std_logic_vector(3 downto 0) := "0001";

    procedure Cycle is
    begin

        if ClockCounter = 625 then
            ClockCounter <= 0;

            -- Drive LEDs with 25% Duty cycle, by cycling through them.
            -- At most one LED is enabled at every time.
            LedPwm <= LedPwm(0) & LedPwm(3 downto 1);
        else
            ClockCounter <= ClockCounter + 1;
        end if;

    end procedure;

begin

    -- Use 125 MHz Clock to generate LedCounter that counts from 0 to 3 with 200 KHz
    LedClockRising : process (Clock) is
    begin

        if rising_edge(Clock) then
            Cycle;
        end if;

    end process LedClockRising;

    LedClockFalling : process (Clock) is
    begin

        if falling_edge(Clock) then
            Cycle;
        end if;

    end process LedClockFalling;

    -- Drive LEDs with 25% Duty cycle, by cycling through them
    Pins <= Switches and LedPwm;

end architecture Behavioral;
