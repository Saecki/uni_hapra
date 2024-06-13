library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.ALL;

--! eigene Typdefinitionen

library work;
    use work.AshaTypes.ALL;

entity asha is
    Port (
        ClockIn : in    std_logic; --! Taktsignal direkt vom Quarz des Digilent Starterboards.

        -- Auf dem digilent Starterboard vorhandene Elemente
        --              AN : out std_logic_vector(3 downto 0); --! Enable-Signale der einzelnen Siebensegmentanzeigen
        ButtonsIn : in    std_logic_vector(3 downto 0); --! Die vier Taster
        LEDsOut   : out   std_logic_vector(5 downto 0); --! Die acht LEDs
        Switches  : in    std_logic_vector(3 downto 0); --! Die acht Schalter

        -- Bluetooth
        BTRXD : in    std_logic; --! Eingang vom Bluetooth-Adapter
        BTTXD : out   std_logic; --! Ausgang zum Bluetooth-Adapter

        -- Analog Digital Converter
        ADCClock      : out   std_logic; --! Taktsignal des ADC
        ADCReceive    : in    std_logic; --! SPI-Signal vom ADC
        ADCSend       : out   std_logic; --! SPI-Signal zum ADC
        ADCChipSelect : out   std_logic; --! Enable-Signal fuer den ADC

        -- digitale Sensoren
        SensorVibe : in    std_logic; --! Eingang: Virbationssensor
        SensorDoor : in    std_logic; --! Eingang: Tuersensor

        -- Haus-Aktoren
        PWM1FanInsideSignal  : out   std_logic; --! Signalausgang (PWM) des inneren Luefters
        PWM2FanOutsideSignal : out   std_logic; --! Signalausgang (PWM) des aeusseren Luefters
        PWM3LightSignal      : out   std_logic; --! Signalausgang (PWM) der LED (Hausbelaeuchtung)
        PWM4PeltierSignal    : out   std_logic; --! Signalausgang (PWM) des Peltiers
        PeltierDirectionOut  : out   std_logic; --! Steuerung der Richtung des Peltiers (Heizen/Kuehlen)
        HouseOnOff           : out   std_logic; --! Haus-Aktoren komplett an oder aus schalten

        -- IIC
        O_scl  : out   std_logic; -- Taktsignal des TM1637
        IO_dio : inout std_logic  -- IIC signal vom or zum TM1637(SevenSegment)
    );
end entity asha;

architecture Behavioral of asha is

    ------------------------
    -- Signal-Deklaration --
    ------------------------

    -- General Signals
    signal Reset        : std_logic;
    signal InitialReset : std_logic := '1';

    --  Clock Divider
    signal En3Hz      : std_logic; --! 3Hz-Enable
    signal En195Hz    : std_logic; --! 195Hz-Enable
    signal En6kHz     : std_logic; --! 6kHz-Enable
    signal EnPWMClock : std_logic; --! PWMClock-Enable
    signal EnADCClock : std_logic; --! ADCClock-Enable

    --  Debounce
    signal Buttons : std_logic_vector(3 downto 0); --! debounced buttons

    -- ADC
    signal ADCRegister : ADCRegisterType; --! Datenregister aller ADC-Werte

    --  SevenSegment
    signal SevenSegmentValue   : std_logic_vector(15 downto 0); -- Eingang der 7SegAnzeige
    signal SevenSegmentValueBT : std_logic_vector(15 downto 0); -- 7Segment von BT
    signal SevenSegmentOut     : std_logic_vector(31 downto 0); --! Das Signal aller acht Siebensignemtanzeigen

    -- IIC
    signal I_write_data : std_logic_vector(31 downto 0); -- Das Data vom SevenSegment zum TM1637

    -- Einsynchronisation fuer UART
    signal BTRXDInternal,        BTRXDsync2 : std_logic;
    signal BTTXDInternal                    : std_logic;

    -- Memory Access - DI=DeviceInfo DN=DeviceName
    signal DIMemAddr : std_logic_vector(5 downto 0);  -- Adresse ganzes Payload
    signal DIMemData : std_logic_vector(82 downto 0); -- Payload 5-13 + 11 i2c-Addr.bits
    signal DNMemAddr : std_logic_vector(11 downto 0); -- 64 Bytes pro Sensor (4bit Offset plus 8Bit Sensoren)
    signal DNMemData : std_logic_vector(7 downto 0);  -- Ein Byte des Namens
    --  Bluetooth
    signal Ready2Send : std_logic; -- ready to send new char
    signal DoWrite    : std_logic; -- set to send new char

    signal RxFin  : std_logic;                    -- char received
    signal RXData : std_logic_vector(7 downto 0); -- received char
    signal TXData : std_logic_vector(7 downto 0); -- char to send

    -- CRC Generierung
    signal DoCRCIn,              DoCRCOut    : std_logic;
    signal CRCInReset,           CRCOutReset : std_logic;
    signal CRCIn,                CRCOut      : std_logic_vector(15 downto 0);
    signal CRCValueReceived                  : std_logic_vector(15 downto 0);

    -- Actors
    signal PWM1FanInsideValue         : std_logic_vector(7 downto 0); --! Signalquellwert Luefter innen
    signal PWM2FanOutsideValue        : std_logic_vector(7 downto 0); --! Signalquellwert Luefter aussen
    signal PWM3LightValue             : std_logic_vector(7 downto 0); --! Signalquellwert Licht
    signal PWM4PeltierValue           : std_logic_vector(7 downto 0); --! Signalquellwert Peltier
    signal PeltierDirection           : std_logic;
    signal PWM1FanInsideValueBT       : std_logic_vector(7 downto 0); --! Signalquellwert Luefter innen
    signal PWM2FanOutsideValueBT      : std_logic_vector(7 downto 0); --! Signalquellwert Luefter aussen
    signal PWM3LightValueBT           : std_logic_vector(7 downto 0); --! Signalquellwert Licht
    signal PWM4PeltierValueBT         : std_logic_vector(7 downto 0); --! Signalquellwert Peltier
    signal PeltierDirectionBT         : std_logic;
    signal PWM1FanInsideValueControl  : std_logic_vector(7 downto 0); --! Signalquellwert Luefter innen
    signal PWM2FanOutsideValueControl : std_logic_vector(7 downto 0); --! Signalquellwert Luefter aussen
    signal PWM3LightValueControl      : std_logic_vector(7 downto 0); --! Signalquellwert Licht
    signal PWM4PeltierValueControl    : std_logic_vector(7 downto 0); --! Signalquellwert Peltier
    signal PeltierDirectionControl    : std_logic;
    signal LEDs                       : std_logic_vector(5 downto 0); --! Die acht LEDs
    signal BTHouseOn                  : std_logic;
    signal SensorHouseOnOff           : std_logic;

    -- Regelungswerte
    signal ControlTempDiff,      ControlLightDiff      : unsigned(12 downto 0);
    signal ControlTempTarget,    ControlLightTarget    : unsigned(11 downto 0);
    signal ControlTemp,          ControlLight          : std_logic;
    signal ControlTempTargetAct, ControlLightTargetAct : unsigned(11 downto 0);
    signal ControlTempAct,       ControlLightAct       : std_logic;
    signal ControlTempTargetBT,  ControlLightTargetBT  : unsigned(11 downto 0);
    signal ControlTempBT,        ControlLightBT        : std_logic;

    -- Clock50MHZ
    signal Clock : std_logic;

    ---------------------------
    -- Komponenten-Deklaration--
    ---------------------------
    component clk_wiz is
        port (
            clk_out : out   std_logic;
            clk_in  : in    std_logic
        );
    end component;

    --  Clock Divider
    component clockdiv is
        Port (
            Clock      : in    std_logic;
            Reset      : in    std_logic;
            En3Hz      : out   std_logic;
            En195Hz    : out   std_logic;
            En6kHz     : out   std_logic;
            EnPWMClock : out   std_logic;
            EnADCClock : out   std_logic
        );
    end component;

    --  Entprellung
    component Debounce is
        Port (
            clk    : in    std_logic;
            keyin  : in    std_logic_vector(3 downto 0);
            keyout : out   std_logic_vector(3 downto 0)
        );
    end component;

    --  ADC
    component AshaADC is
        Port (
            Clock         : in    std_logic;
            Reset         : in    std_logic;
            ADCClockIn    : in    std_logic;
            ADCReceive    : in    std_logic;
            ADCSend       : out   std_logic;
            ADCChipSelect : out   std_logic;
            ADCRegister   : out   ADCRegisterType;
            ADCClockOut   : out   std_logic
        );
    end component;

    -- 7Segment
    component AshaSiebensegment is
        Port (
            Clock                   : in    std_logic;
            Reset                   : in    std_logic;
            EnSevenSegmentClock     : in    std_logic;
            EnSevenSegmentSlowClock : in    std_logic;
            SevenSegmentValue       : in    std_logic_vector(15 downto 0);
            SevenSegment            : out   std_logic_vector(31 downto 0)
        );
    end component;

    -- mit 2 pins zu zybo
    component iic_send is
        Port (
            Clock        : in    std_logic;
            Reset        : in    std_logic;
            I_write_data : in    std_logic_vector(31 downto 0);
            O_scl        : out   std_logic;
            IO_dio       : inout std_logic
        );
    end component;

    -- Actor Module for 7Segment, LEDs and others actors
    component actor is
        Port (
            Clock               : in    std_logic;
            Reset               : in    std_logic;
            Switches            : in    std_logic_vector(3 downto 0);
            ButtonsIn           : in    std_logic_vector(3 downto 0);
            SensorVibe          : in    std_logic;
            SensorDoor          : in    std_logic;
            ADCRegister         : in    ADCRegisterType;
            LEDsOut             : out   std_logic_vector(5 downto 0);
            SevenSegmentValue   : out   std_logic_vector(15 downto 0);
            PWM1FanInsideValue  : out   std_logic_vector(7 downto 0);
            PWM2FanOutsideValue : out   std_logic_vector(7 downto 0);
            PWM3LightValue      : out   std_logic_vector(7 downto 0);
            PWM4PeltierValue    : out   std_logic_vector(7 downto 0);
            PeltierDirection    : out   std_logic;
            ----- Werte von Bluetooth
            LEDsBT                : in    std_logic_vector(5 downto 0);
            SevenSegmentValueBT   : in    std_logic_vector(15 downto 0);
            PWM1FanInsideValueBT  : in    std_logic_vector(7 downto 0);
            PWM2FanOutsideValueBT : in    std_logic_vector(7 downto 0);
            PWM3LightValueBT      : in    std_logic_vector(7 downto 0);
            PWM4PeltierValueBT    : in    std_logic_vector(7 downto 0);
            PeltierDirectionBT    : in    std_logic;
            ----- Werte von Regelung
            PWM1FanInsideValueControl  : in    std_logic_vector(7 downto 0);
            PWM2FanOutsideValueControl : in    std_logic_vector(7 downto 0);
            PWM3LightValueControl      : in    std_logic_vector(7 downto 0);
            PWM4PeltierValueControl    : in    std_logic_vector(7 downto 0);
            PeltierDirectionControl    : in    std_logic;
            ControlLightDiffOut        : in    unsigned(12 downto 0);
            ControlTempDiffOut         : in    unsigned(12 downto 0)
        );
    end component;

    -- UART Module for Bluetooth
    component AshaUART is
        Port (
            Clock      : in    std_logic;
            Reset      : in    std_logic;
            DataIn     : in    std_logic_vector(7 downto 0);
            DataOut    : out   std_logic_vector(7 downto 0);
            RXD        : in    std_logic;
            TXD        : out   std_logic;
            DoWrite    : in    std_logic;
            Ready2Send : out   std_logic;
            RxFin      : out   std_logic
        );
    end component;

    -- bluetooth Paketverwaltung
    component bluetooth is
        Port (
            -- Memory Access - DI=DeviceInfo DN=DeviceName
            RXData                 : in    std_logic_vector(7 downto 0);
            TXData                 : out   std_logic_vector(7 downto 0);
            Ready2Send             : in    std_logic;
            DoWrite                : out   std_logic;
            DIMemAddr              : out   std_logic_vector(5 downto 0);
            DIMemData              : in    std_logic_vector(82 downto 0);
            DNMemAddr              : out   std_logic_vector(11 downto 0);
            DNMemData              : in    std_logic_vector(7 downto 0);
            ClockIn                : in    std_logic;
            RxFin                  : in    std_logic;
            Reset                  : in    std_logic;
            CRCInReset             : out   std_logic;
            CRCOutReset            : out   std_logic;
            DoCRCIn                : out   std_logic;
            DoCRCOut               : out   std_logic;
            LEDsOut                : out   std_logic_vector(5 downto 0);
            Buttons                : in    std_logic_vector(3 downto 0);
            Switches               : in    std_logic_vector(3 downto 0);
            SevenSegmentValueOut   : out   std_logic_vector(15 downto 0);
            ADCRegister            : in    ADCRegisterType;
            SensorDoor             : in    std_logic;
            PWM1FanInsideValue     : in    std_logic_vector(7 downto 0);
            PWM2FanOutsideValue    : in    std_logic_vector(7 downto 0);
            PWM3LightValue         : in    std_logic_vector(7 downto 0);
            PWM4PeltierValue       : in    std_logic_vector(7 downto 0);
            PeltierDirection       : in    std_logic;
            PWM1FanInsideValueOut  : out   std_logic_vector(7 downto 0);
            PWM2FanOutsideValueOut : out   std_logic_vector(7 downto 0);
            PWM3LightValueOut      : out   std_logic_vector(7 downto 0);
            PWM4PeltierValueOut    : out   std_logic_vector(7 downto 0);
            PeltierDirectionOut    : out   std_logic;
            BTHouseOn              : out   std_logic;
            ControlTempDiff        : in    unsigned(12 downto 0);
            ControlLightDiff       : in    unsigned(12 downto 0);
            ControlTempTargetOut   : out   unsigned(11 downto 0);
            ControlLightTargetOut  : out   unsigned(11 downto 0);
            ControlTemp            : out   std_logic;
            ControlLight           : out   std_logic;
            CRCIn                  : std_logic_vector(15 downto 0);
            CRCOut                 : std_logic_vector(15 downto 0)
        );
    end component;

    -- CRC-Modul
    component AshaCRC16 is
        Port (
            Clock    : in    std_logic;
            Reset    : in    std_logic;
            NextData : in    std_logic;
            InByte   : in    std_logic_vector(7 downto 0);
            CRCOut   : out   std_logic_vector(15 downto 0)
        );
    end component;

    -- Das deviceinfo enthaelt moch Platz fuer die angedachte i2c-Adresse (11 bit)
    -- der wird aber zurzeit nicht genutzt und produziert eine compiler-warnung.
    component deviceinfo is
        port (
            clka  : IN    std_logic;
            addra : IN    std_logic_vector(5 downto 0);
            douta : OUT   std_logic_vector(82 downto 0)
        );
    end component;

    component devicename is
        port (
            clka  : IN    std_logic;
            addra : IN    std_logic_vector(11 downto 0);
            douta : OUT   std_logic_vector(7 downto 0)
        );
    end component;

    component AshaPWM is
        Port (
            Clock                : in    std_logic;
            Reset                : in    std_logic;
            EnPWMClock           : in    std_logic;
            PWM1FanInsideValue   : in    std_logic_vector(7 downto 0);
            PWM2FanOutsideValue  : in    std_logic_vector(7 downto 0);
            PWM3LightValue       : in    std_logic_vector(7 downto 0);
            PWM4PeltierValue     : in    std_logic_vector(7 downto 0);
            PWM1FanInsideSignal  : out   std_logic;
            PWM2FanOutsideSignal : out   std_logic;
            PWM3LightSignal      : out   std_logic;
            PWM4PeltierSignal    : out   std_logic
        );
    end component;

    -- Vibrationssensor
    component AshaVibe is
        Port (
            Clock             : in    std_logic;
            Reset             : in    std_logic;
            SensorVibe        : in    std_logic;
            SensorVibeHouseOn : out   std_logic
        );
    end component;

    -- Regelung
    component AshaRegelung is
        Port (
            Clock                      : in    std_logic;
            Reset                      : in    std_logic;
            EnClockLight               : in    std_logic;
            EnClockTemp                : in    std_logic;
            SensordataLight            : in    std_logic_vector(11 downto 0);
            SensordataTempIn           : in    std_logic_vector(11 downto 0);
            SensordataTempOut          : in    std_logic_vector(11 downto 0);
            PWM1FanInsideValueControl  : out   std_logic_vector(7 downto 0);
            PWM2FanOutsideValueControl : out   std_logic_vector(7 downto 0);
            PWM3LightValueControl      : out   std_logic_vector(7 downto 0);
            PWM4PeltierValueControl    : out   std_logic_vector(7 downto 0);
            PeltierDirectionControl    : out   std_logic;
            ControlLightDiffOut        : out   unsigned(12 downto 0);
            ControlTempDiffOut         : out   unsigned(12 downto 0)
        );
    end component;

begin

    ------------
    -- Port Map--
    ------------

    -- Da der Zybo-Takt 125 MHz betr?gt,
    -- kann das Originalprogramm nicht getrieben werden.
    -- Hier verwenden einen Clocking Wizard (IP-Core) ,
    -- um einen 50-MHz-Takt zu erhalten
    CLK_wiz_u : component clk_wiz
        port map (
            -- Clock out ports
            clk_out => Clock,
            -- Clock in ports
            clk_in => ClockIn
        );

    -- Clock Divider
    ClockDivider : component clockdiv
        port map (
            Clock      => Clock,
            Reset      => Reset,
            En3Hz      => En3Hz,
            En195Hz    => En195Hz,
            En6kHz     => En6kHz,
            EnPWMClock => EnPWMClock,
            EnADCClock => EnADCClock
        );

    -- Entprellung
    Debouncing : component Debounce
        port map (
            clk    => Clock,
            keyin  => ButtonsIn,
            keyout => Buttons
        );

    -- ADC
    ADC : component AshaADC
        port map (
            Clock         => Clock,
            Reset         => Reset,
            ADCClockIn    => EnADCClock,
            ADCReceive    => ADCReceive,
            ADCSend       => ADCSend,
            ADCChipSelect => ADCChipSelect,
            ADCRegister   => ADCRegister,
            ADCClockOut   => ADCClock
        );

    -- 7Segment
    SevenSegment : component AshaSiebensegment
        port map (
            Clock                   => Clock,
            Reset                   => Reset,
            EnSevenSegmentClock     => En6kHz,
            EnSevenSegmentSlowClock => En3Hz,
            SevenSegmentValue       => SevenSegmentValue,
            SevenSegment            => SevenSegmentOut
        );

    -- TM1637
    IIC : component iic_send
        port map (
            Clock        => Clock,
            Reset        => Reset,
            I_write_data => SevenSegmentOut,
            O_scl        => O_scl,
            IO_dio       => IO_dio
        );

    -- Actor
    ActorModule : component actor
        port map (
            Clock               => Clock,
            Reset               => Reset,
            Switches            => Switches,
            ButtonsIn           => Buttons,
            SensorVibe          => SensorVibe,
            SensorDoor          => SensorDoor,
            ADCRegister         => ADCRegister,
            LEDsOut             => LEDsOut,
            SevenSegmentValue   => SevenSegmentValue,
            PWM1FanInsideValue  => PWM1FanInsideValue,
            PWM2FanOutsideValue => PWM2FanOutsideValue,
            PWM3LightValue      => PWM3LightValue,
            PWM4PeltierValue    => PWM4PeltierValue,
            PeltierDirection    => PeltierDirection,
            ----- Werte von Bluetooth
            LEDsBT                => LEDs,
            SevenSegmentValueBT   => SevenSegmentValueBT,
            PWM1FanInsideValueBT  => PWM1FanInsideValueBT,
            PWM2FanOutsideValueBT => PWM2FanOutsideValueBT,
            PWM3LightValueBT      => PWM3LightValueBT,
            PWM4PeltierValueBT    => PWM4PeltierValueBT,
            PeltierDirectionBT    => PeltierDirectionBT,
            ----- Werte von Regelung
            PWM1FanInsideValueControl  => PWM1FanInsideValueControl,
            PWM2FanOutsideValueControl => PWM2FanOutsideValueControl,
            PWM3LightValueControl      => PWM3LightValueControl,
            PWM4PeltierValueControl    => PWM4PeltierValueControl,
            PeltierDirectionControl    => PeltierDirectionControl,
            ControlLightDiffOut        => ControlLightDiff,
            ControlTempDiffOut         => ControlTempDiff
        );

    -- UART
    UART : component AshaUART
        port map (
            Clock      => Clock,
            Reset      => Reset,
            DataIn     => TXData,
            DataOut    => RXData,
            RXD        => BTRXDInternal,
            TXD        => BTTXDInternal,
            DoWrite    => DoWrite,
            Ready2Send => Ready2Send,
            RxFin      => RxFin
        );

    -- Bluetooth Paketverwaltung
    BluetoothModule : component bluetooth
        port map (
            -- Memory Access - DI=DeviceInfo DN=DeviceName
            RXData                 => RXData,
            TXData                 => TXData,
            Ready2Send             => Ready2Send,
            DoWrite                => DoWrite,
            DIMemAddr              => DIMemAddr,
            DIMemData              => DIMemData,
            DNMemAddr              => DNMemAddr,
            DNMemData              => DNMemData,
            ClockIn                => Clock,
            RxFin                  => RxFin,
            Reset                  => Reset,
            CRCInReset             => CRCInReset,
            CRCOutReset            => CRCOutReset,
            DoCRCIn                => DoCRCIn,
            DoCRCOut               => DoCRCOut,
            LEDsOut                => LEDs,
            Buttons                => Buttons,
            Switches               => Switches,
            SevenSegmentValueOut   => SevenSegmentValueBT,
            ADCRegister            => ADCRegister,
            SensorDoor             => SensorDoor,
            PWM1FanInsideValue     => PWM1FanInsideValue,
            PWM2FanOutsideValue    => PWM2FanOutsideValue,
            PWM3LightValue         => PWM3LightValue,
            PWM4PeltierValue       => PWM4PeltierValue,
            PeltierDirection       => PeltierDirection,
            PWM1FanInsideValueOut  => PWM1FanInsideValueBT,
            PWM2FanOutsideValueOut => PWM2FanOutsideValueBT,
            PWM3LightValueOut      => PWM3LightValueBT,
            PWM4PeltierValueOut    => PWM4PeltierValueBT,
            PeltierDirectionOut    => PeltierDirectionBT,
            BTHouseOn              => BTHouseOn,
            ControlTempDiff        => ControlTempDiff,
            ControlLightDiff       => ControlLightDiff,
            ControlTempTargetOut   => ControlTempTargetBT,
            ControlLightTargetOut  => ControlLightTargetBT,
            ControlTemp            => ControlTempBT,
            ControlLight           => ControlLightBT,
            CRCIn                  => CRCIn,
            CRCOut                 => CRCOut
        );

    ModuleCRCIn : component AshaCRC16
        port map (
            Clock    => Clock,
            Reset    => CRCInReset,
            NextData => DoCRCIn,
            InByte   => RXData,
            CRCOut   => CRCIn
        );

    ModuleCRCOut : component AshaCRC16
        port map (
            Clock    => Clock,
            Reset    => CRCOutReset,
            NextData => DoCRCOut,
            InByte   => TXData,
            CRCOut   => CRCOut
        );

    CoreModuleDeviceInfo : component deviceinfo
        port map (
            clka  => Clock,
            addra => DIMemAddr,
            douta => DIMemData
        );

    CoreModuleDeviceName : component devicename
        port map (
            clka  => Clock,
            addra => DNMemAddr,
            douta => DNMemData
        );

    PWMControl : component AshaPWM
        port map (
            Clock                => Clock,
            Reset                => Reset,
            EnPWMClock           => EnPWMClock,
            PWM1FanInsideValue   => PWM1FanInsideValue,
            PWM2FanOutsideValue  => PWM2FanOutsideValue,
            PWM3LightValue       => PWM3LightValue,
            PWM4PeltierValue     => PWM4PeltierValue,
            PWM1FanInsideSignal  => PWM1FanInsideSignal,
            PWM2FanOutsideSignal => PWM2FanOutsideSignal,
            PWM3LightSignal      => PWM3LightSignal,
            PWM4PeltierSignal    => PWM4PeltierSignal
        );

    -- Vibrationssensor
    VibeSens : component AshaVibe
        port map (
            Clock             => Clock,
            Reset             => Reset,
            SensorVibe        => SensorVibe,
            SensorVibeHouseOn => SensorHouseOnOff
        );

    -- Regelung
    Regelung : component AshaRegelung
        port map (
            Clock                      => Clock,
            Reset                      => Reset,
            EnClockLight               => En195Hz,
            EnClockTemp                => En3Hz,
            SensordataLight            => ADCRegister(3),
            SensordataTempIn           => ADCRegister(0),
            SensordataTempOut          => ADCRegister(1),
            PWM1FanInsideValueControl  => PWM1FanInsideValueControl,
            PWM2FanOutsideValueControl => PWM2FanOutsideValueControl,
            PWM3LightValueControl      => PWM3LightValueControl,
            PWM4PeltierValueControl    => PWM4PeltierValueControl,
            PeltierDirectionControl    => PeltierDirectionControl,
            ControlLightDiffOut        => ControlLightDiff,
            ControlTempDiffOut         => ControlTempDiff
        );

    -- nebenlaeufige Anweisungen: Zuweisungen Reset, HouseOnOff, PeltierDirection
    Reset               <= (Buttons(3) or InitialReset);
    HouseOnOff          <= (BTHouseOn and SensorHouseOnOff);
    PeltierDirectionOut <= PeltierDirection;

    -- TXD kann so vom internen ins aeussere uebergeben werden
    BTTXD <= BTTXDInternal;

    ---------------------------------------------------------------------
    --! Initiales Reset
    -- Loest nach der Programmierung einen Reset aller Signale aus,
    -- bis er sich selber abschaltet.
    Process (Clock) is
    begin

        if rising_edge(Clock) then
            if InitialReset='1' then
                InitialReset <= '0';
            end if;
        end if;

    end Process;

    ---------------------------------------------------------------------
    --! Einsynchronisierung RXD
    Process (Clock) is
    begin

        if rising_edge(Clock) then
            BTRXDsync2    <= BTRXD;
            BTRXDInternal <= BTRXDsync2;
        end if;

    end Process;

---------------------------------------------------------------------

end architecture Behavioral;
