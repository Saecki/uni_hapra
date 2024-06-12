library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.ALL;

library work;
    use work.AshaTypes.ALL;

entity actor is
    Port (
        Clock               : in    std_logic;                     --! Taktsignal
        Reset               : in    std_logic;                     --! Resetsignal
        Switches            : in    std_logic_vector(3 downto 0);  --! Die acht Schalter
        ButtonsIn           : in    std_logic_vector(3 downto 0);  --! Die vier Taster
        SensorVibe          : in    std_logic;                     --! Eingang: Virbationssensor
        SensorDoor          : in    std_logic;                     --! Eingang: Tuersensor
        ADCRegister         : in    ADCRegisterType;               --! Datenregister aller ADC-Werte
        LEDsOut             : out   std_logic_vector(5 downto 0);  --! Die acht LEDs
        SevenSegmentValue   : out   std_logic_vector(15 downto 0); --! treibt die 7-Segment-Anzeigen
        PWM1FanInsideValue  : out   std_logic_vector(7 downto 0);  --! Signalquellwert Luefter innen
        PWM2FanOutsideValue : out   std_logic_vector(7 downto 0);  --! Signalquellwert Luefter aussen
        PWM3LightValue      : out   std_logic_vector(7 downto 0);  --! Signalquellwert Licht
        PWM4PeltierValue    : out   std_logic_vector(7 downto 0);  --! Signalquellwert Peltier
        PeltierDirection    : out   std_logic;                     --! Signalquellwert Peltier Richtung
        -- Bluetooth
        LEDsBT                : in    std_logic_vector(5 downto 0);  --! Die acht LEDs
        SevenSegmentValueBT   : in    std_logic_vector(15 downto 0); --! 7SegmentEingang von BT
        PWM1FanInsideValueBT  : in    std_logic_vector(7 downto 0);  --! Signalquellwert Luefter innen, von Bt
        PWM2FanOutsideValueBT : in    std_logic_vector(7 downto 0);  --! Signalquellwert Luefter aussen, von Bt
        PWM3LightValueBT      : in    std_logic_vector(7 downto 0);  --! Signalquellwert Licht, von Bt
        PWM4PeltierValueBT    : in    std_logic_vector(7 downto 0);  --! Signalquellwert Peltier, von Bt
        PeltierDirectionBT    : in    std_logic;                     --! Signalquellwert Peltier Richtung, von Bt
        -- Regelung
        PWM1FanInsideValueControl  : in    std_logic_vector(7 downto 0); --! Signalquellwert Luefter innen, von Regelung
        PWM2FanOutsideValueControl : in    std_logic_vector(7 downto 0); --! Signalquellwert Luefter aussen, von Regelung
        PWM3LightValueControl      : in    std_logic_vector(7 downto 0); --! Signalquellwert Licht, von Regelung
        PWM4PeltierValueControl    : in    std_logic_vector(7 downto 0); --! Signalquellwert Peltier, von Regelung
        PeltierDirectionControl    : in    std_logic;                    --! Signalquellwert Peltier Richtung, von Regelung
        ControlLightDiffOut        : in    unsigned(12 downto 0);        --! Aktuelle Regeldifferenz Licht
        ControlTempDiffOut         : in    unsigned(12 downto 0)         --! Aktuelle Regeldifferenz Temperatur
    );
end entity actor;

architecture Behavioral of actor is

    -- Zustandsautomat für Modus Auswahl
    -- type of state machine(M for Modus).
    type state_typeM is (
        Asha,
        SensorRead,
        ManualActor,
        AutoActor,
        Bluetooth
    );

    -- current and next state declaration.
    signal current_m : state_typeM := Asha;
    signal next_m    : state_typeM := Asha;
    signal button_m  : state_typeM := Asha;

    -- Zustandsautomat für Sensor Zustaende.
    -- type of state machine(S for Sensor).
    type state_typeS is (
        Init,
        Light,
        TempIn,
        TempOut,
        Vibe,
        Door
    );

    -- current and next state declaration.
    signal current_s : state_typeS := Init;
    signal next_s    : state_typeS := Init;
    signal button_s  : state_typeS := Init;

begin

    -- FSM Prozess zur Realisierung der Speicherelemente - Abhängig vom Takt den nächsten Zustand setzen
    FSM_seq : process (Clock, Reset) is
    begin

        -- Beim Reset die current Zustände auf die initialen Zustände setzen
        if (Reset = '1') then
            current_s <= Init;
            current_m <= Asha;
        elsif rising_edge(Clock) then
            current_s <= next_s;
            current_m <= next_m;
        end if;

    end process FSM_seq;

    -- FSM Prozess (kombinatorisch) zur Realisierung der Modul Zustände aus den Typen per Switch Case:  state_typeM
    -- Setzt sich aus aktuellem Zustand und folgendem Zustand zusammen: current_m,next_m
    -- > In Versuch 6-10 zu implementieren
    FSM_modul : process (current_m, ButtonsIn(0), ButtonsIn(1)) is
    begin

        if (ButtonsIn(0) = '0' and ButtonsIn(1) = '0') then
            next_m <= button_m;
        end if;

        case current_m is

            -- Asha 2 ist der Basiszustand des Modus
            when Asha =>

                -- drückt man Button 0, beginnen wir den Vorgang des Zurückschaltens,
                -- indem in `button_m` der Zustand vorgemerkt wird
                if (ButtonsIn(0) = '1') then
                    button_m <= Bluetooth;
                -- drückt man Button 0, beginnen wir den Vorgang des Vorwärtsschaltens,
                -- indem in `button_m` der Zustand vorgemerkt wird
                elsif (ButtonsIn(1) = '1') then
                    button_m <= SensorRead;
                else
                    button_m <= Asha;
                end if;

            -- Analog zum Init Zustand "Asha" sind die weiteren Zustände programmiert.
            when SensorRead =>

                if (ButtonsIn(0) = '1') then
                    button_m <= Asha;
                elsif (ButtonsIn(1) = '1') then
                    button_m <= ManualActor;
                else
                    button_m <= SensorRead;
                end if;

            when ManualActor =>

                if (ButtonsIn(0) = '1') then
                    button_m <= SensorRead;
                elsif (ButtonsIn(1) = '1') then
                    button_m <= AutoActor;
                else
                    button_m <= ManualActor;
                end if;

            when AutoActor =>

                if (ButtonsIn(0) = '1') then
                    button_m <= ManualActor;
                elsif (ButtonsIn(1) = '1') then
                    button_m <= Bluetooth;
                else
                    button_m <= AutoActor;
                end if;

            when Bluetooth =>

                if (ButtonsIn(0) = '1') then
                    button_m <= AutoActor;
                elsif (ButtonsIn(1) = '1') then
                    button_m <= SensorRead;
                else
                    button_m <= Bluetooth;
                end if;

        end case;

    end process FSM_modul;

    -- FSM Prozess (kombinatorisch) zur Realisierung der Ausgangs- und Übergangsfunktionen
    -- Hinweis: 12 Bit ADC-Sensorwert für Lichtsensor:       ADCRegister(3),
    --             12 Bit ADC-Sensorwert für Temp. (außen):  ADCRegister(1),
    --             12 Bit ADC-Sensorwert für Temp. (innen):  ADCRegister(0),
    -- > In Versuch 6-10 zu implementieren!-
    FSM_comb : process (current_s, current_m, ButtonsIn(2), ADCRegister, SensorVibe, SensorDoor) is
    begin

        if (ButtonsIn(2) = '0') then
            next_s <= button_s;
        end if;

        -- Hier wird der Sensor Zustand abhängig von den Buttons gesetzt
        -- Modus 0: "ASHA" Auf 7 Segment Anzeige
        case current_m is

            when Asha => -- ASHA state

                LEDsOut           <= b"111111";
                SevenSegmentValue <= x"FFFF";

            when SensorRead =>

                SevenSegmentValue(15 downto 12) <= x"A";

                case current_s is

                    -- init ist der Basiszustand. von hier kannn man button 2 drücken, um den nächsten Zustand vorzumerken.
                    -- Lässt man den Button los wechselt man in den nächsten Zustand. Analog dazu sind die weitern Zustände programmiert
                    when Init =>

                        LEDsOut                        <= b"100000";
                        SevenSegmentValue(11 downto 0) <= x"FFF";

                        if (ButtonsIn(2) = '1') then
                            button_s <= Light;
                        else
                            button_s <= Init;
                        end if;

                    when Light =>

                        LEDsOut <= b"010000";
                        -- Hier müssen die relevanten Sensordaten auf das SevenSegment geschrieben
                        SevenSegmentValue(11 downto 0) <= ADCRegister(3);

                        if (ButtonsIn(2) = '1') then
                            button_s <= TempIn;
                        else
                            button_s <= Light;
                        end if;

                    when TempIn =>

                        LEDsOut                        <= b"001000";
                        SevenSegmentValue(11 downto 0) <= ADCRegister(0);

                        if (ButtonsIn(2) = '1') then
                            button_s <= TempOut;
                        else
                            button_s <= TempIn;
                        end if;

                    when TempOut =>

                        LEDsOut                        <= b"000100";
                        SevenSegmentValue(11 downto 0) <= ADCRegister(1);

                        if (ButtonsIn(2) = '1') then
                            button_s <= Vibe;
                        else
                            button_s <= TempOut;
                        end if;

                    when Vibe =>

                        LEDsOut                        <= b"000010";
                        SevenSegmentValue(11 downto 1) <= b"00000000000";
                        SevenSegmentValue(0)           <= SensorVibe;

                        if (ButtonsIn(2) = '1') then
                            button_s <= Door;
                        else
                            button_s <= Vibe;
                        end if;

                    when Door =>

                        LEDsOut                         <= b"000001";
                        SevenSegmentValue(15 downto 12) <= x"E";
                        SevenSegmentValue(11 downto 1)  <= b"00000000000";
                        SevenSegmentValue(0)            <= SensorDoor;

                        if (ButtonsIn(2) = '1') then
                            button_s <= Light;
                        else
                            button_s <= Door;
                        end if;

                end case;

            -- Versuch 7
            -- Modus 2: Manuelle Aktorsteuerung
            -- nur erlauben, wenn keine Regelung aktiv ist!
            -- Ansteuerung der Actoren mittels Switches. Seven Segment Value wird je nach zustand geändert und dient ausschließlich als test
            when ManualActor =>

                SevenSegmentValue(15 downto 12) <= x"B";

                if (Switches(0) = '1') then
                    PWM1FanInsideValue              <= x"FF";
                    SevenSegmentValue(11 downto 10) <= x"1";
                else
                    PWM1FanInsideValue              <= x"00";
                    SevenSegmentValue(11 downto 10) <= x"0";
                end if;

                if (Switches(1) = '1') then
                    PWM2FanOutsideValue           <= x"FF";
                    SevenSegmentValue(9 downto 8) <= x"1";
                else
                    PWM2FanOutsideValue           <= x"00";
                    SevenSegmentValue(9 downto 8) <= x"0";
                end if;

                if (Switches(2) = '1') then
                    PWM3LightValue                <= x"FF";
                    SevenSegmentValue(7 downto 4) <= x"1";
                else
                    PWM3LightValue                <= x"00";
                    SevenSegmentValue(7 downto 4) <= x"0";
                end if;

                PeltierDirection <= '1';

                if (Switches(3) = '1') then
                    PWM4PeltierValue              <= x"FF";
                    SevenSegmentValue(3 downto 0) <= x"1";
                else
                    PWM4PeltierValue              <= x"00";
                    SevenSegmentValue(3 downto 0) <= x"0";
                end if;

            -- Versuch 9
            -- TODO: Modus 3, geregelte Aktorsteuerung
            when ManualActor =>

                LEDsOut           <= b"000000";
                SevenSegmentValue <= x"C000";

            -- Versuch 10
            -- TODO: Modus 4, Steuerung ueber Smartphone-App
            when Bluetooth =>

                LEDsOut           <= b"000000";
                SevenSegmentValue <= x"D000";

        -- DEFAULT Werte setzen TODO

        end case;

    end process FSM_comb;

end architecture Behavioral;
