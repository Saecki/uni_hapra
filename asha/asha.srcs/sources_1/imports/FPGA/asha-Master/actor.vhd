library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.AshaTypes.ALL;

entity actor is
    Port (
        Clock               : in  std_logic;                      --! Taktsignal
        Reset               : in  std_logic;                      --! Resetsignal
        Switches            : in  std_logic_vector(3 downto 0);   --! Die acht Schalter
        ButtonsIn           : in  std_logic_vector(3 downto 0);   --! Die vier Taster
        SensorVibe          : in  std_logic;                      --! Eingang: Virbationssensor
        SensorDoor          : in  std_logic;                      --! Eingang: Tuersensor
        ADCRegister         : in  ADCRegisterType;                --! Datenregister aller ADC-Werte
        LEDsOut             : out std_logic_vector(5 downto 0);   --! Die acht LEDs
        SevenSegmentValue   : out std_logic_vector(15 downto 0); --! treibt die 7-Segment-Anzeigen
        PWM1FanInsideValue  : out std_logic_vector(7 downto 0);   --! Signalquellwert Luefter innen
        PWM2FanOutsideValue : out std_logic_vector(7 downto 0);   --! Signalquellwert Luefter aussen
        PWM3LightValue      : out std_logic_vector(7 downto 0);   --! Signalquellwert Licht
        PWM4PeltierValue    : out std_logic_vector(7 downto 0);   --! Signalquellwert Peltier
        PeltierDirection    : out std_logic;                      --! Signalquellwert Peltier Richtung
        -- Bluetooth
        LEDsBT                : in std_logic_vector(5 downto 0);   --! Die acht LEDs
        SevenSegmentValueBT   : in std_logic_vector (15 downto 0); --! 7SegmentEingang von BT
        PWM1FanInsideValueBT  : in std_logic_vector(7 downto 0);   --! Signalquellwert Luefter innen, von Bt
        PWM2FanOutsideValueBT : in std_logic_vector(7 downto 0);   --! Signalquellwert Luefter aussen, von Bt
        PWM3LightValueBT      : in std_logic_vector(7 downto 0);   --! Signalquellwert Licht, von Bt
        PWM4PeltierValueBT    : in std_logic_vector(7 downto 0);   --! Signalquellwert Peltier, von Bt
        PeltierDirectionBT    : in std_logic;                      --! Signalquellwert Peltier Richtung, von Bt
        -- Regelung
        PWM1FanInsideValueControl  : in std_logic_vector(7 downto 0); --! Signalquellwert Luefter innen, von Regelung
        PWM2FanOutsideValueControl : in std_logic_vector(7 downto 0); --! Signalquellwert Luefter aussen, von Regelung
        PWM3LightValueControl      : in std_logic_vector(7 downto 0); --! Signalquellwert Licht, von Regelung
        PWM4PeltierValueControl    : in std_logic_vector(7 downto 0); --! Signalquellwert Peltier, von Regelung
        PeltierDirectionControl    : in std_logic;                    --! Signalquellwert Peltier Richtung, von Regelung
        ControlLightDiffOut        : in unsigned(12 downto 0);        --! Aktuelle Regeldifferenz Licht
        ControlTempDiffOut         : in unsigned(12 downto 0)         --! Aktuelle Regeldifferenz Temperatur
    );
end actor;

architecture Behavioral of actor is
    -- Zustandsautomat für Modus Auswahl
    -- type of state machine(M for Modus).
    type state_typeM is (
        Asha1,Asha2,Asha3,
        SensorRead1,SensorRead2,SensorRead3,
        ManualActor1,ManualActor2,ManualActor3,
        AutoActor1,AutoActor2,AutoActor3,
        Bluetooth1,Bluetooth2,Bluetooth3
    );
    --current and next state declaration.
    signal current_m: state_typeM := Asha2;
    signal next_m: state_typeM := Asha2;

    -- Zustandsautomat für Sensor Zustaende.
    -- type of state machine(S for Sensor).
    type state_typeS is (
        Init, Init2,
        Light, Light2,
        TempIn, TempIn2,
        TempOut, TempOut2,
        Vibe, Vibe2,
        Door, Door2
    );
    -- current and next state declaration.
    signal current_s: state_typeS := Init;
    signal next_s: state_typeS := Init;
begin

    -- FSM Prozess zur Realisierung der Speicherelemente - Abhängig vom Takt den nächsten Zustand setzen
    FSM_seq: process (Clock,Reset)
    begin
        -- Beim Reset die current Zustände auf die initialen Zustände setzen
        if Reset = '1' then
           current_s <= Init;
           current_m <= Asha2;
        elsif rising_edge(Clock) then
            current_s <= next_s;
            current_m <= next_m;
        end if;
    end process FSM_seq;
    

    -- FSM Prozess (kombinatorisch) zur Realisierung der Modul Zustände aus den Typen per Switch Case:  state_typeM
    -- Setzt sich aus aktuellem Zustand und folgendem Zustand zusammen: current_m,next_m
    --> In Versuch 6-10 zu implementieren
    FSM_modul:process(current_m, ButtonsIn(0),ButtonsIn(1))
    begin
        case current_m is
            -- Zustand 1 ist der Zustand der beim loslassen des Button 0 einen Modus zurück schaltet
            when Asha1 =>
                if (ButtonsIn(0) = '0') then
                    next_m <= Bluetooth2;
                else
                    next_m <= Asha1;
                end if;
            -- Asha 2 ist der Basiszustand des Modus
            when Asha2 =>
            -- drückt man Button 0, beginnen wir den Vorgang des zurück Schaltens, indem wir in Zustand 1 wechseln
                if (ButtonsIn(0) = '1') then
                    next_m <= Asha1;
                    -- drückt man Button 0, beginnen wir den Vorgang des vorwärts Schaltens, indem wir in Zustand 3 wechseln
                elsif (ButtonsIn(1) = '1') then
                    next_m <= Asha3;
                else
                    next_m <= Asha2;
                end if;
            -- Asha3 ist der Zustand, der beim Loslassen des Buttons 1 einen Modus vorwärts schaltet
            when Asha3 =>
                if (ButtonsIn(1) = '0') then
                    next_m <= SensorRead2;
                else
                    next_m <= Asha3;
                end if;
            -- Analog zum Init Zustand "Asha" sind die weiteren Zustände programmiert.    
            when SensorRead1 =>
                if (ButtonsIn(0) = '0') then
                    next_m <= Bluetooth2;
                else
                    next_m <= SensorRead1;
                end if;
            when SensorRead2 =>
                if (ButtonsIn(0) = '1') then
                    next_m <= SensorRead1;
                elsif (ButtonsIn(1) = '1') then
                    next_m <= SensorRead3;
                else
                    next_m <= SensorRead2;
                end if;
            when SensorRead3 =>
                if (ButtonsIn(1) = '0') then
                    next_m <= ManualActor2;
                else
                    next_m <= SensorRead3;
                end if;
                
            when ManualActor1 =>
                if (ButtonsIn(0) = '0') then
                    next_m <= SensorRead2;
                else
                    next_m <= ManualActor1;
                end if;
            when ManualActor2 =>
                if (ButtonsIn(0) = '1') then
                    next_m <= ManualActor1;
                elsif (ButtonsIn(1) = '1') then
                    next_m <= ManualActor3;
                else
                    next_m <= ManualActor2;
                end if;
            when ManualActor3 =>
                if (ButtonsIn(1) = '0') then
                    next_m <= AutoActor2;
                else
                    next_m <= ManualActor3;
                end if;
            
            when AutoActor1 =>
                if (ButtonsIn(0) = '0') then
                    next_m <= ManualActor2;
                else
                    next_m <= AutoActor1;
                end if;
            when AutoActor2 =>
                if (ButtonsIn(0) = '1') then
                    next_m <= AutoActor1;
                elsif (ButtonsIn(1) = '1') then
                    next_m <= AutoActor3;
                else
                    next_m <= AutoActor2;
                end if;
            when AutoActor3 =>
                if (ButtonsIn(1) = '0') then
                    next_m <= Bluetooth2;
                else
                    next_m <= AutoActor3;
                end if;
                
            when Bluetooth1 =>
                if (ButtonsIn(0) = '0') then
                    next_m <= AutoActor2;
                else
                    next_m <= Bluetooth1;
                end if;
            when Bluetooth2 =>
                if (ButtonsIn(0) = '1') then
                    next_m <= Bluetooth1;
                elsif (ButtonsIn(1) = '1') then
                    next_m <= Bluetooth3;
                else
                    next_m <= Bluetooth2;
                end if;
            when Bluetooth3 =>
                if (ButtonsIn(1) = '0') then
                    next_m <= SensorRead2;
                else
                    next_m <= Bluetooth3;
                end if;
        end case;
    end process;


    -- FSM Prozess (kombinatorisch) zur Realisierung der Ausgangs- und Übergangsfunktionen
        -- Hinweis: 12 Bit ADC-Sensorwert für Lichtsensor:       ADCRegister(3),
        --             12 Bit ADC-Sensorwert für Temp. (außen):  ADCRegister(1),
        --             12 Bit ADC-Sensorwert für Temp. (innen):  ADCRegister(0),
    --> In Versuch 6-10 zu implementieren!-
    FSM_comb:process (current_s,current_m, ButtonsIn(2) , ADCRegister, SensorVibe, SensorDoor)
    begin
        -- Hier wird der Sensor Zustand abhängig von den Buttons gesetzt
        -- Modus 0: "ASHA" Auf 7 Segment Anzeige
        case current_m is
            when Asha1|Asha2|Asha3 => --ASHA state
                LEDsOut<= b"111111";
                SevenSegmentValue <= x"FFFF";
            when SensorRead1|SensorRead2|SensorRead3 =>
                case current_s is
                -- init ist der Basiszustand. von hier kannn man button 2 drücken, um in Init2 zu wechseln. Lässt man den Button los wechselt man von Init2 in den nächsten Zustand. Analog dazu sind die weitern Zustände programmiert
                    when Init =>
                        LEDsOut<= b"100000";
                        SevenSegmentValue <= x"FFFF";
                        if (ButtonsIn(2) = '1') then 
                            next_s <= Init2;
                        else 
                            next_s <= Init;
                        end if;
                    when Init2 =>
                        LEDsOut<= b"000000";
                        if (ButtonsIn(2) = '0') then
                            next_s <= Light;
                        else 
                            next_s <= Init2;
                        end if;
                        
                    when Light =>
                        LEDsOut<= b"010000";
                        SevenSegmentValue(15 downto 12) <= x"A";
                        -- Hier müssen die relevanten Sensordaten auf das SevenSegment geschrieben
                        SevenSegmentValue(11 downto 0) <= ADCRegister(3);
                        if (ButtonsIn(2) = '1') then 
                            next_s <= Light2;
                        else 
                            next_s <= Light;
                        end if;
                    when Light2 =>
                        LEDsOut<= b"000000";
                        if (ButtonsIn(2) = '0') then
                            next_s <= TempIn;
                        else 
                            next_s <= Light2;
                        end if;
                        
                    when TempIn =>
                        LEDsOut<= b"001000";
                        SevenSegmentValue(15 downto 12) <= x"B";
                        SevenSegmentValue(11 downto 0) <= ADCRegister(0);
                        if (ButtonsIn(2) = '1') then 
                            next_s <= TempIn2;
                        else 
                            next_s <= TempIn;
                        end if;
                    when TempIn2 =>
                        LEDsOut<= b"000000";
                        if (ButtonsIn(2) = '0') then
                            next_s <= TempOut;
                        else 
                            next_s <= TempIn2;
                        end if;
                        
                    when TempOut =>
                        LEDsOut<= b"000100";
                        SevenSegmentValue(15 downto 12) <= x"C";
                        SevenSegmentValue(11 downto 0) <= ADCRegister(1);
                        if (ButtonsIn(2) = '1') then 
                            next_s <= TempOut2;
                        else 
                            next_s <= TempOut;
                        end if;
                    when TempOut2 =>
                        LEDsOut<= b"000000";
                        if (ButtonsIn(2) = '0') then
                            next_s <= Vibe;
                        else 
                            next_s <= TempOut2;
                        end if;
                    
                    when Vibe =>
                        LEDsOut<= b"000010";
                        SevenSegmentValue(15 downto 12) <= x"D";
                        SevenSegmentValue(11 downto 1) <= b"00000000000";
                        SevenSegmentValue(0) <= SensorVibe;
                        if (ButtonsIn(2) = '1') then 
                            next_s <= Vibe2;
                        else 
                            next_s <= Vibe;
                        end if;
                    when Vibe2 =>
                        LEDsOut<= b"000000";
                        if (ButtonsIn(2) = '0') then
                            next_s <= Door;
                        else 
                            next_s <= Vibe2;
                        end if;
                        
                    when Door =>
                        LEDsOut<= b"000001";
                        SevenSegmentValue(15 downto 12) <= x"E";
                        SevenSegmentValue(11 downto 1) <= b"00000000000";
                        SevenSegmentValue(0) <= SensorDoor;
                        if (ButtonsIn(2) = '1') then 
                            next_s <= Door2;
                        else 
                            next_s <= Door;
                        end if;
                    when Door2 =>
                        LEDsOut<= b"000000";
                        if (ButtonsIn(2) = '0') then
                            next_s <= Light;
                        else 
                            next_s <= Door2;
                        end if;
                end case;      

            -- Versuch 7
            -- Modus 2: Manuelle Aktorsteuerung    
            -- nur erlauben, wenn keine Regelung aktiv ist!
            -- Ansteuerung der Actoren mittels Switches. Seven Segment Value wird je nach zustand geändert und dient ausschließlich als test
            when ManualActor1|ManualActor2|ManualActor3 =>
                SevenSegmentValue(15 downto 0) <= b"1111111111111110";
                if Switches(0) = '1' then
                    PWM1FanInsideValue <= "11111111";
                    SevenSegmentValue(15 downto 0) <= b"1111111111111111";
                else
                    PWM1FanInsideValue <= "00000000";
                end if;

                if Switches(1) = '1' then
                    PWM2FanOutsideValue <= "11111111";
                    SevenSegmentValue(15 downto 0) <= b"1111111111111100";
                else
                    PWM2FanOutsideValue <= "00000000";
                end if;

                if Switches(2) = '1' then
                    PWM3LightValue <= "11111111";
                    SevenSegmentValue(15 downto 0) <= b"1111111111111000";
                else
                    PWM3LightValue <= "00000000";
                end if;

                PeltierDirection <= '1';
                if Switches(3) = '1' then
                    PWM4PeltierValue <= "11111111";
                    SevenSegmentValue(15 downto 0) <= b"1111111111110000";
                else
                    PWM4PeltierValue <= "00000000";
                end if;

            -- Versuch 9
            -- Modus 3: geregelte Aktorsteuerung
                -- when ... TODO

            -- Versuch 10
            -- Modus 4: Steuerung ueber Smartphone-App
                    -- when ... TODO
            when others =>
            -- DEFAULT Werte setzen TODO
        end case;
    end process;

end Behavioral;
