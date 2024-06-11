--! Standardbibliothek benutzen

library IEEE;
    --! Logikelemente verwenden
    use IEEE.std_logic_1164.ALL;
    --! Numerisches Rechnen ermoeglichen
    use IEEE.NUMERIC_STD.ALL;

--! @brief Ansteuerung der Siebensegmentanzeige
--! @details Dieses Modul uebernimmt Daten in Form eines 16-bit Wortes und
--! zeigt dieses in Form des Hex-Wertes auf der Siebensegmentanzeige an

entity AshaSiebensegment is
    --! treibt die 7-Segment-Anzeigen; alle, bei denen AN aktiviert ist
    Port (
        Clock                   : in    std_logic;                     --! Taktsignal
        Reset                   : in    std_logic;                     --! Resetsignal
        EnSevenSegmentClock     : in    std_logic;                     --! 6kHz Enable-Signal des Treiberprozesses
        EnSevenSegmentSlowClock : in    std_logic;                     --! 3Hz  Enable-Signal fr Aktualisierung der Anzeige
        SevenSegmentValue       : in    std_logic_vector(15 downto 0); --! der Wert, der auf der Anzeige erscheinen soll
        SevenSegment            : out   std_logic_vector(31 downto 0)
    );
end entity AshaSiebensegment;

--! Ansteuerung der Siebensegmentanzeige

architecture Behavioral of AshaSiebensegment is

    -- Ziffer nach SevenSegment Konvertierung
    -- Die Eingaenge der Siegensegmentanzeige sind low-active

    type SevenSegmentset_type is array (0 to 15) of std_logic_vector(7 downto 0);

    -- 7-Segment Anzeige Anordnung
    --      A
    --     ---
    --  F |   | B
    --     -G-
    --  E |   | C
    --     ---
    --      D
    -- Versuch 6:
    -- Die Zeichen 2 bis F muessen hier noch richtig definert werden, in dem die entsprechenden Bits für die oben gezeichnete 7 Segment Anzeige gesetzt werden.
    -- Wenn Sie weitere Unterlagen benötigen, benötigen, schauen Sie sich die Library für Arduino unter dieser Adresse an: https://github.com/avishorp/TM1637
    -- XGFEDCBA
    constant SevenSegmentset : SevenSegmentset_type :=
    (
        b"00111111", -- 0
        b"00000110", -- 1
        b"01011011", -- 2
        b"01001111", -- 3
        b"01100110", -- 4
        b"01101101", -- 5
        b"01111101", -- 6
        b"00000111", -- 7
        b"01111111", -- 8
        b"01100111", -- 9
        b"01110111", -- A
        b"01111100", -- b
        b"00111001", -- C
        b"01011110", -- d
        b"01111001", -- E
        b"01110001"  -- F
    );

begin

    SetSevenSegment : Process (Clock, Reset) is -- 7-Segment-Prozess

        variable SevenSegmentValueSlow : std_logic_vector(15 downto 0);

    begin

        -- Bei der SlowClock werden die zu schreibenden Daten gelesen und in eine Variable geschrieben
        if rising_edge(EnSevenSegmentSlowClock) then
            SevenSegmentValueSlow := SevenSegmentValue;
        end if;

        if (Reset = '1') then
            SevenSegment <= x"00000000";
        elsif rising_edge(Clock) then
            if (EnSevenSegmentClock = '1') then
                if (SevenSegmentValue = x"FFFF") then                                                                         -- Zur Darstellung "ASHA" bei dem eigentlichen Wert von "FFFF"
                    SevenSegment(15 downto 8)  <= b"01101101";                                                                -- S
                    SevenSegment(23 downto 16) <= b"01110110";                                                                -- H
                    SevenSegment(31 downto 24) <= b"01110111";                                                                -- A
                    SevenSegment(7 downto 0)   <= b"01110111";                                                                -- A
                else                                                                                                          -- Darstellung der Zeichen
                    -- Hier wird nicht mehr die anliegenden Daten angezeigt, sondern die oben definierten variablen geschrieben. So aktualisiert die anzeige 3 mal pro sekunde
                    SevenSegment(23 downto 16) <= SevenSegmentset(to_integer(unsigned(SevenSegmentValueSlow(7 downto 4))));
                    SevenSegment(15 downto 8)  <= SevenSegmentset(to_integer(unsigned(SevenSegmentValueSlow(11 downto 8))));
                    SevenSegment(7 downto 0)   <= SevenSegmentset(to_integer(unsigned(SevenSegmentValueSlow(15 downto 12))));
                    SevenSegment(31 downto 24) <= SevenSegmentset(to_integer(unsigned(SevenSegmentValueSlow(3 downto 0))));
                end if;
            end if;                                                                                                           -- EnSevenSegmentClock
        end if;                                                                                                               -- Clock

    end Process SetSevenSegment;

end architecture Behavioral;


