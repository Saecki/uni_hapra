library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;

entity led_controller is
    Port (
        LEDClock : in    std_logic;
        Switch   : in    std_logic;
        Button   : in    std_logic;
        LED      : out   std_logic
    );
end entity led_controller;

architecture Behavioral of led_controller is

begin

    LED <= Switch and (not Button or LEDClock);

end architecture Behavioral;
