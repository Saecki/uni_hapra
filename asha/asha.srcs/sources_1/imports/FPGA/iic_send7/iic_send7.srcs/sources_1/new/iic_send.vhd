library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.ALL;

--!@brief  steuert den externen TM1637.
--!@details
--!Interface interpretation
--!Microprocessor data realize the communication with TM1637 by means of two¨Cwire bus interface 
--!(Note: The communication method is not equal to 12C bus protocol totally 
--!because there is no slave address). 
--!When data is input, DIO signal should not change for high level CLK 
--!and DIO signal should change for low level CLK signal. 
--!When CLK is a high level and DIO changes from high to low level,
--!data input starts. 
--!When CLK is a high level and DIO changesfrom low level to high level, data input ends.
--!TM1637 data transfer carries with answering signal ACK. 
--!For a right data transfer, 
--!an answering signal ACK is generated inside the chip to lower the DIO pin at the failing edge of the 8th clock.
--!DIO interface wire is released at the end of the 9th clock. 
--!Dokument:https://github.com/avishorp/TM1637/blob/master/docs/TM1637_V2.4_EN.pdf
entity iic_send is
  Port ( 
    Clock       :   in std_logic;
    Reset       :   in std_logic; 
    I_write_data:  in std_logic_vector(31 downto 0);
    O_scl        :  out std_logic;
    IO_dio       :  inout std_logic
    );
end iic_send;

architecture Behavioral of iic_send is

constant I_data_cmd : std_logic_vector(7 downto 0) :="01000000"; --Data command
constant I_reg_cmd : std_logic_vector(7 downto 0) :="11000000";  -- Address command setting  
constant I_display_cmd : std_logic_vector(7 downto 0) :="10001111"; --Display control     

signal R_scl_cnt       :std_logic_vector(9 downto 0);--Counter for output clock(SCL)
signal R_scl_en        :std_logic;--enable to count
signal R_sda_mode      :std_logic;--Statemachine for the main Loop
signal R_sda_reg       :std_logic;--register for the output Data
signal R_load_data     :std_logic_vector(7 downto 0);--Numbers to be sent
signal R_bit_cnt       :std_logic_vector(3 downto 0);--8bit Data
signal R_ack_flag      :std_logic;--used to save the ACK signal
signal scl_low_mid   :std_logic;--Low-level middle flag 
signal scl_high_mid  :std_logic;--High-level middle flag
signal scl_neg       :std_logic;--falling edge


type state is (IDLE,START,Data_cmd_load,Reg_cmd_load,Display_cmd_load,Data1_load,Data2_load,Data3_load,Data4_load,SEND,ACK,CHECK,STOP,DONE);
signal R_state,R_jump_state,R_inner_state: state;

begin
IO_port:process (IO_dio, R_sda_mode,R_sda_reg)
begin
    if(R_sda_mode = '1') then
        IO_dio <= R_sda_reg;
    else
        IO_dio <= 'Z';
    end if;
end process;
	
counter:process(Clock,Reset)	
begin
    if rising_edge(Clock)then
        if (Reset = '1') then	
        R_scl_cnt <= "00"& x"00";
        elsif(R_scl_en ='1') then
	       if(R_scl_cnt = 10#499#) then
	           R_scl_cnt <= "00" & x"00";
	       else
	           R_scl_cnt <= R_scl_cnt+'1';
	       end if;
	   else
            R_scl_cnt <= "00" & x"00";	   
	   end if;
    end if;
end process;

O_CLK:process(Clock,Reset)	
begin
    if rising_edge(Clock) then	
        if (Reset = '1') then	
	       O_scl <= '1';
	   elsif(R_scl_cnt <= 10#249#) then
	       O_scl <= '1';
	   else
	       O_scl <= '0';
	   end if;
	end if;
end process;

LM_flag:process(Clock,Reset)	
begin
    if rising_edge(Clock) then	
        if (Reset = '1') then	
	       scl_low_mid <= '0';
	    elsif(R_scl_cnt = 10#374#) then
	       scl_low_mid <= '1';
	    else
	       scl_low_mid <= '0';
	   end if;
	end if;
end process;

HM_flag:process(Clock,Reset)	
begin
    if rising_edge(Clock) then	
        if (Reset = '1') then	
	       scl_high_mid <= '0';
	   elsif(R_scl_cnt = 10#124#) then
	       scl_high_mid <= '1';
	   else
	       scl_high_mid <= '0';
	   end if;
	end if;
end process;

N_flag:process(Clock,Reset)	
begin
    if rising_edge(Clock) then
        if (Reset = '1') then	
	       scl_neg <= '0';
	   elsif(R_scl_cnt = 10#251#) then
	       scl_neg <= '1';
	   else
	       scl_neg <= '0';
	   end if;
	end if;
end process;
	
process(Clock,Reset)
begin
    if rising_edge(Clock) then
        if (Reset = '1') then	
	       R_state         <=  IDLE ;
           R_sda_mode      <=  '1' ;
           R_sda_reg       <=  '1' ;
           R_bit_cnt       <=  x"0" ;
           R_jump_state    <=  IDLE ;
           R_inner_state   <=  IDLE;
           R_ack_flag      <=  '1' ;
           R_load_data     <=  x"00";          
	   else
           case R_state is
                when IDLE =>
                    R_state         <=  Data_cmd_load ;
                    R_sda_mode      <=  '1' ;
                    R_sda_reg       <=  '1' ;
                    R_scl_en        <=  '0' ; -- close the SCL line
                    R_bit_cnt       <=  x"0" ;
                    R_jump_state    <=  IDLE ;
                    R_inner_state   <=  IDLE;
                    R_ack_flag      <=  '1' ;
                    R_load_data     <=  x"00";
                when Data_cmd_load =>
                    R_load_data     <=  I_data_cmd  ;
                    R_state         <=  START       ;
                    R_jump_state    <=  Reg_cmd_load;
                    R_inner_state   <=  STOP; 
                when Reg_cmd_load =>
                    R_load_data     <=  I_reg_cmd  ;
                    R_state         <=  START       ;
                    R_jump_state    <=  IDLE;
                    R_inner_state   <=  Data1_load;  
                when Data1_load =>
                    R_load_data     <=  I_write_data(7 downto 0)  ;
                    R_state         <=  SEND       ;
                    R_jump_state    <=  Data1_load;
                    R_inner_state   <=  Data2_load;   
               when Data2_load =>
                    R_load_data     <=  I_write_data(15 downto 8)  ;
                    R_state         <=  SEND       ;
                    R_jump_state    <=  Data3_load;
                    R_inner_state   <=  Data3_load;
               when Data3_load =>
                    R_load_data     <=  I_write_data(23 downto 16)  ;
                    R_state         <=  SEND       ;
                    R_jump_state    <=  Data4_load;
                    R_inner_state   <=  Data4_load;
               when Data4_load =>
                    R_load_data     <=  I_write_data(31 downto 24)  ;
                    R_state         <=  SEND       ;
                    R_jump_state    <=  Display_cmd_load;
                    R_inner_state   <=  STOP;  
              when Display_cmd_load =>
                    R_load_data     <=  I_display_cmd  ;
                    R_state         <=  START       ;
                    R_jump_state    <=  IDLE;
                    R_inner_state   <=  STOP;
              when START =>   -- send the start-flag                   
                    R_scl_en    <=  '1'                ; -- open the SCL line
                    R_sda_mode  <=  '1'                ; -- set the DIO ouput
                    If(scl_high_mid = '1')then                  
                        R_sda_reg   <=  '0'        ; -- Pull the SDA signal low in the middle of SCL high level to generate the start signal
                        R_state     <=  SEND        ; 
                    else
                        R_state <=  START                ;                   
                    end if;                                                           
              when SEND =>      
                    R_scl_en    <=  '1'                ; -- open the SCL line
                    R_sda_mode  <=  '1'                ; -- set the DIO ouput
                    if(scl_low_mid = '1') then
                        if(R_bit_cnt =x"8") then
                            R_bit_cnt   <=  x"0"            ;
                            R_state     <=  ACK            ; -- Enter the ACK state after the byte is sent
                        else                               
                            R_sda_reg   <=  R_load_data(CONV_INTEGER (R_bit_cnt)) ; -- starting from the LSB
							R_bit_cnt   <=  R_bit_cnt + 1         ; 
                        end if;
                    else
                        R_state <=  SEND ; 
                    end if;
              when ACK =>         
                    R_scl_en    <=  '1'  ; 
                    R_sda_mode  <=  '0'  ; 
                    if(scl_high_mid ='1')then
                        R_ack_flag  <=  IO_dio  ; 
                        R_state     <=  CHECK    ; 
                     else
                        R_state <=  ACK  ;     
                    end if;
              when CHECK  =>  
                    R_scl_en    <=  '1'  ;                
                    if(R_ack_flag = '0') then   -- Check passed
                        if(scl_neg ='1') then
                            R_state <=  R_inner_state ;
                            R_sda_mode  <=  '1' ; 
                            R_sda_reg   <=  '0' ; -- After reading the response signal, set the SDA signal to output and pull it low,
                                                  -- because if this state is followed by a stop state, 
                                                  --the rising edge of the SDA signal is required, 
                                                  --so pull it low here in advance
                        else
                            R_state <= CHECK    ;
                        end if;
                   else
                        R_state <=  IDLE ;      
                   end if;
              when STOP => 
                    R_scl_en    <=  '1'        ; 
                    R_sda_mode  <=  '1'        ; 
                    if(scl_high_mid = '1')then
                        R_sda_reg   <=  '1' ;
                        R_state     <=  DONE ;
                    else
                        R_state <=STOP;
                    end if;
              when DONE =>   
                    R_scl_en    <=  '0' ; 
                    R_sda_mode  <=  '1' ; 
                    R_sda_reg   <=  '1' ; 
                    R_state     <=  R_jump_state ; 
                    R_ack_flag  <=  '1' ;
              when others => NULL;      
        end case;
        end if;
end if;        
end process;    	
end Behavioral;
