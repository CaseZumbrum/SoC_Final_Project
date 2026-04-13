----------------------------------------------------------------------------------
-- Original File: https://github.com/YetAnotherElectronicsChannel/FPGA-Class-D-Amplifier/blob/master/PWM_Modulator.vhd
-- Engineer: github.com/YetAnotherElectronicsChannel
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity pwm_modulator is
  generic (
    pwm_bits : integer;
    clk_cnt_len : positive := 1
  );
  port (
    clk : in std_logic;
    rstn : in std_logic;
    duty_cycle : in unsigned(pwm_bits - 1 downto 0);
    pwm_out : out std_logic
  );
end pwm_modulator;

architecture Behavioral of pwm_modulator is

    signal pwm_cnt : unsigned(pwm_bits - 1 downto 0);
    signal clk_cnt : integer range 0 to clk_cnt_len - 1;

begin

    CLK_CNT_PROC : process(clk)
    begin
      if rising_edge(clk) then
        if rstn = '0' then
          clk_cnt <= 0;
            
        else
          if clk_cnt < clk_cnt_len - 1 then
            clk_cnt <= clk_cnt + 1;
          else
            clk_cnt <= 0;
          end if;
            
        end if;
      end if;
    end process;
    
    PWM_PROC : process(clk)
    begin
      if rising_edge(clk) then
        if rstn = '0' then
          pwm_cnt <= (others => '0');
          pwm_out <= '0';
      
        else
          if clk_cnt_len = 1 or clk_cnt = 0 then
      
            pwm_cnt <= pwm_cnt + 1;
            pwm_out <= '0';
      
            if pwm_cnt = unsigned(to_signed(-2, pwm_cnt'length)) then
              pwm_cnt <= (others => '0');
            end if;
      
            if pwm_cnt < duty_cycle then
              pwm_out <= '1';
            end if;
      
          end if;
        end if;
      end if;
    end process;

end Behavioral;