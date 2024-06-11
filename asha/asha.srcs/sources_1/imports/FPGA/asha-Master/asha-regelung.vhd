--! Standardbibliothek benutzen
library IEEE;
--! Logikelemente verwenden
use IEEE.STD_LOGIC_1164.ALL;
--! Numerisches Rechnen ermoeglichen
use IEEE.NUMERIC_STD.ALL;

--! @brief ASHA-Modul - Regelung
--! @details Dieses Modul enthaelt die Regelung
entity AshaRegelung is
  Port ( 
    Clock : in std_logic; 											--! Taktsignal
    Reset : in std_logic; 											--! Resetsignal
    EnClockLight : in std_logic;									--! Enable-Signal fuer die Lichtregelung
    EnClockTemp  : in std_logic; 							   --! Enable-Signal fuer die Temperaturregelung
    SensordataLight   : in std_logic_vector(11 downto 0); 			--! Aktuelle Lichtwerte
    SensordataTempIn  : in std_logic_vector(11 downto 0); 			--! Aktuelle Innentemperatur
	 SensordataTempOut : in std_logic_vector(11 downto 0);   		--! Aktuelle Au√üentemperatur
	 PWM1FanInsideValueControl  : out std_logic_vector(7 downto 0); 	--! PWM-Wert innerere Luefter
    PWM2FanOutsideValueControl : out std_logic_vector(7 downto 0);   --! PWM-Wert aeusserer Luefter
    PWM3LightValueControl   : out std_logic_vector(7 downto 0); 	   --! PWM-Wert Licht
    PWM4PeltierValueControl : out std_logic_vector(7 downto 0); 	   --! PWM-Wert Peltier
    PeltierDirectionControl : out std_logic; 						      --! Pelier Richtung heizen (=1)/kuehlen(=0)
    ControlLightDiffOut : out unsigned(12 downto 0); 				--! Aktuelle Regeldifferenz Licht
    ControlTempDiffOut  : out unsigned(12 downto 0)            --! Aktuelle Regeldifferenz Temperatur
	 ); 				
end AshaRegelung;

architecture Behavioral of AshaRegelung is
begin

-- Versuch 9: Realisierung der Lichtsteuerung
lightControl: process (Clock)
begin
    if (rising_edge(Clock)) then
        -- TODO
    end if;
end process lightControl;

-- Versuch 9: Realisierung der Temperatursteuerung
-- Ziel: Innen zwei Grad waermer als draussen
-- 2∞C entsprechen einem Wert von ca. 15;
-- um schnelles Umschalten zu verhindern, wird ein Toleranzbereich genommen
tempControl: process (EnClockTemp)
begin
    if (rising_edge(EnClockTemp)) then
        -- TODO
    end if;
end process tempControl;
		
		
-- Versuch 9: Ansteuerung der 7-Seg-Anzeige			
SevenSegOutput: process (Clock)
begin
	if (rising_edge(Clock)) then
        -- TODO
	end if;
end process SevenSegOutput;

end Behavioral;
