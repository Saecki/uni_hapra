library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity led_controller is
    Port(
        LEDClock : in std_logic;
        Switch : in std_logic;
        Button : in std_logic;
        LED : out std_logic
    );
end led_controller;

architecture Behavioral of led_controller is
begin
    LED <= Switch and (not Button or LEDClock);
end Behavioral;
