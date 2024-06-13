library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.ALL;

library work;
    use work.AshaTypes.ALL;

entity TestbenchActor is
--  Port ( );
end entity TestbenchActor;

architecture Behavioral of TestbenchActor is

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
            -- Bluetooth
            LEDsBT                : in    std_logic_vector(5 downto 0);
            SevenSegmentValueBT   : in    std_logic_vector(15 downto 0);
            PWM1FanInsideValueBT  : in    std_logic_vector(7 downto 0);
            PWM2FanOutsideValueBT : in    std_logic_vector(7 downto 0);
            PWM3LightValueBT      : in    std_logic_vector(7 downto 0);
            PWM4PeltierValueBT    : in    std_logic_vector(7 downto 0);
            PeltierDirectionBT    : in    std_logic;
            -- Regelung
            PWM1FanInsideValueControl  : in    std_logic_vector(7 downto 0);
            PWM2FanOutsideValueControl : in    std_logic_vector(7 downto 0);
            PWM3LightValueControl      : in    std_logic_vector(7 downto 0);
            PWM4PeltierValueControl    : in    std_logic_vector(7 downto 0);
            PeltierDirectionControl    : in    std_logic;
            ControlLightDiffOut        : in    unsigned(12 downto 0);
            ControlTempDiffOut         : in    unsigned(12 downto 0)
        );
    end component;

    signal Clock               : std_logic;
    signal Reset               : std_logic;
    signal Switches            : std_logic_vector(3 downto 0);
    signal ButtonsIn           : std_logic_vector(3 downto 0);
    signal SensorVibe          : std_logic;
    signal SensorDoor          : std_logic;
    signal ADCRegister         : ADCRegisterType;
    signal LEDsOut             : std_logic_vector(5 downto 0);
    signal SevenSegmentValue   : std_logic_vector(15 downto 0);
    signal PWM1FanInsideValue  : std_logic_vector(7 downto 0);
    signal PWM2FanOutsideValue : std_logic_vector(7 downto 0);
    signal PWM3LightValue      : std_logic_vector(7 downto 0);
    signal PWM4PeltierValue    : std_logic_vector(7 downto 0);
    signal PeltierDirection    : std_logic;
    -- Bluetooth
    signal LEDsBT                : std_logic_vector(5 downto 0);
    signal SevenSegmentValueBT   : std_logic_vector(15 downto 0);
    signal PWM1FanInsideValueBT  : std_logic_vector(7 downto 0);
    signal PWM2FanOutsideValueBT : std_logic_vector(7 downto 0);
    signal PWM3LightValueBT      : std_logic_vector(7 downto 0);
    signal PWM4PeltierValueBT    : std_logic_vector(7 downto 0);
    signal PeltierDirectionBT    : std_logic;
    -- Regelung
    signal PWM1FanInsideValueControl  : std_logic_vector(7 downto 0);
    signal PWM2FanOutsideValueControl : std_logic_vector(7 downto 0);
    signal PWM3LightValueControl      : std_logic_vector(7 downto 0);
    signal PWM4PeltierValueControl    : std_logic_vector(7 downto 0);
    signal PeltierDirectionControl    : std_logic;
    signal ControlLightDiffOut        : unsigned(12 downto 0);
    signal ControlTempDiffOut         : unsigned(12 downto 0);

begin

    UUT : component actor
        port map (
            Clock               => Clock,
            Reset               => Reset,
            Switches            => Switches,
            ButtonsIn           => ButtonsIn,
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
            -- Bluetooth
            LEDsBT                => LEDsBT,
            SevenSegmentValueBT   => SevenSegmentValueBT,
            PWM1FanInsideValueBT  => PWM1FanInsideValueBT,
            PWM2FanOutsideValueBT => PWM2FanOutsideValueBT,
            PWM3LightValueBT      => PWM3LightValueBT,
            PWM4PeltierValueBT    => PWM4PeltierValueBT,
            PeltierDirectionBT    => PeltierDirectionBT,
            -- Regelung
            PWM1FanInsideValueControl  => PWM1FanInsideValueControl,
            PWM2FanOutsideValueControl => PWM2FanOutsideValueControl,
            PWM3LightValueControl      => PWM3LightValueControl,
            PWM4PeltierValueControl    => PWM4PeltierValueControl,
            PeltierDirectionControl    => PeltierDirectionControl,
            ControlLightDiffOut        => ControlLightDiffOut,
            ControlTempDiffOut         => ControlTempDiffOut
        );

    LEDsBT                <= "000000";
    SevenSegmentValueBT   <= x"0000";
    PWM1FanInsideValueBT  <= x"00";
    PWM2FanOutsideValueBT <= x"00";
    PWM3LightValueBT      <= x"00";
    PWM4PeltierValueBT    <= x"00";
    PeltierDirectionBT    <= '0';

    PWM1FanInsideValueControl  <= x"00";
    PWM2FanOutsideValueControl <= x"00";
    PWM3LightValueControl      <= x"00";
    PWM4PeltierValueControl    <= x"00";
    PeltierDirectionControl    <= '0';
    ControlLightDiffOut        <= "0000000000000";
    ControlTempDiffOut         <= "0000000000000";

    process is
    begin

        Clock <= '1';
        wait for 1ns;
        Clock <= '0';
        wait for 1ns;

    end process;

    process is

        procedure PressButton0 is
        begin

            wait for 25ns;
            ButtonsIn <= "0001";
            wait for 25ns;
            ButtonsIn <= "0000";

        end procedure;

        procedure PressButton1 is
        begin

            wait for 25ns;
            ButtonsIn <= "0010";
            wait for 25ns;
            ButtonsIn <= "0000";

        end procedure;

        procedure PressButton2 is
        begin

            wait for 25ns;
            ButtonsIn <= "0100";
            wait for 25ns;
            ButtonsIn <= "0000";

        end procedure;

    begin

        Reset      <= '1';
        Switches   <= "0000";
        ButtonsIn  <= "0000";
        SensorVibe <= '0';
        SensorDoor <= '0';

        ADCRegister(0) <= x"000";
        ADCRegister(1) <= x"000";
        ADCRegister(2) <= x"000";
        ADCRegister(3) <= x"000";
        ADCRegister(4) <= x"000";
        ADCRegister(5) <= x"000";
        ADCRegister(6) <= x"000";
        ADCRegister(7) <= x"000";

        wait for 20ns;
        Reset <= '0';

        PressButton1;
        PressButton2;
        PressButton2;
        PressButton2;

        PressButton1;
        PressButton2;
        PressButton2;
        PressButton2;

        PressButton0;
        PressButton2;
        PressButton2;

        PressButton1;
        PressButton1;
        PressButton1;
        PressButton1;
        PressButton1;
        PressButton1;

        wait for 20ns;

    end process;

end architecture Behavioral;
