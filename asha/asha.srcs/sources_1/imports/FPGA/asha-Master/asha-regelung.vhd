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
        Clock                      : in    std_logic;                     --! Taktsignal
        Reset                      : in    std_logic;                     --! Resetsignal
        EnClockLight               : in    std_logic;                     --! Enable-Signal fuer die Lichtregelung
        EnClockTemp                : in    std_logic;                     --! Enable-Signal fuer die Temperaturregelung
        SensordataLight            : in    std_logic_vector(11 downto 0); --! Aktuelle Lichtwerte
        SensordataTempIn           : in    std_logic_vector(11 downto 0); --! Aktuelle Innentemperatur
        SensordataTempOut          : in    std_logic_vector(11 downto 0); --! Aktuelle Außentemperatur
        PWM1FanInsideValueControl  : out   std_logic_vector(7 downto 0);  --! PWM-Wert innerere Luefter
        PWM2FanOutsideValueControl : out   std_logic_vector(7 downto 0);  --! PWM-Wert aeusserer Luefter
        PWM3LightValueControl      : out   std_logic_vector(7 downto 0);  --! PWM-Wert Licht
        PWM4PeltierValueControl    : out   std_logic_vector(7 downto 0);  --! PWM-Wert Peltier
        PeltierDirectionControl    : out   std_logic;                     --! Pelier Richtung heizen (=1)/kuehlen(=0)
        ControlLightDiffOut        : out   unsigned(12 downto 0);         --! Aktuelle Regeldifferenz Licht
        ControlTempDiffOut         : out   unsigned(12 downto 0)          --! Aktuelle Regeldifferenz Temperatur
    );
end entity AshaRegelung;

architecture Behavioral of AshaRegelung is

begin

    -- Versuch 9: Realisierung der Lichtsteuerung
    lightControl : process (Clock) is
    begin

        if rising_edge(Clock) then
            -- TODO: insert pre-calculated light values
            if unsigned(SensordataLight) < 4058 then    -- < 10 Lux
                PWM3LightValueControl <= x"FF";
            elsif unsigned(SensordataLight) < 3912 then -- < 50 Lux
                PWM3LightValueControl <= x"40";
            elsif unsigned(SensordataLight) < 3363 then -- < 200 Lux
                PWM3LightValueControl <= x"80";
            else
                PWM3LightValueControl <= x"00";
            end if;
        end if;

    end process lightControl;

    -- Versuch 9: Realisierung der Temperatursteuerung
    -- Ziel: Innen zwei Grad waermer als draussen
    -- 2°C entsprechen einem Wert von ca. 15;
    -- um schnelles Umschalten zu verhindern, wird ein Toleranzbereich genommen
    tempControl : process (EnClockTemp) is
    variable TempDiff: unsigned(12 downto 0);
    begin

        if rising_edge(EnClockTemp) then
        -- TODO
            TempDiff := unsigned(SensorDataTempIn) - unsigned(SensorDataTempOut);
            ControlTempDiffOut <= TempDiff;
            if (TempDiff > 16) then -- k�hlen
                PeltierDirectionControl <= '0';
                PWM1FanInsideValueControl <= x"FF";
                PWM2FanOutsideValueControl <= x"FF";
                PWM4PeltierValueControl <= x"FF";
            elsif (TempDiff < 14) then -- heizen
                PeltierDirectionControl <= '1';
                PWM1FanInsideValueControl <= x"FF";
                PWM2FanOutsideValueControl <= x"FF";
                PWM4PeltierValueControl <= x"FF";
            else -- abschalten
                PeltierDirectionControl <= '1';
                PWM1FanInsideValueControl <= x"00";
                PWM2FanOutsideValueControl <= x"00";
                PWM4PeltierValueControl <= x"00";
            end if;
        end if;

    end process tempControl;

    -- Versuch 9: Ansteuerung der 7-Seg-Anzeige
    SevenSegOutput : process (Clock) is
    begin

        if rising_edge(Clock) then
        -- TODO
            ControlLightDiffOut <= unsigned(SensorDataLight);
            ControlTempDiffOut <= unsigned(SensorDataTempIn) - unsigned(SensorDataTempOut);
            if unsigned(SensorDataTempIn) < unsigned(SensorDataTempOut) then
                ControlTempDiffOut(12) <= '1';
            else
                ControlTempDiffOut(12) <= '0';
            end if;
        end if;

    end process SevenSegOutput;

end architecture Behavioral;
