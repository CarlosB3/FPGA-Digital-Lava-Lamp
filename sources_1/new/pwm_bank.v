library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pwm_bank is
  generic (
    NLEDS : integer := 8;
    PW    : integer := 8      -- duty width
  );
  port (
    clk, rst_n : in  std_logic;
    duty       : in  std_logic_vector(NLEDS*PW-1 downto 0); 
    led_out    : out std_logic_vector(NLEDS-1 downto 0)
  );
end entity;

architecture rtl of pwm_bank is
  signal ctr : unsigned(PW-1 downto 0) := (others => '0');
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        ctr <= (others => '0');
      else
        ctr <= ctr + 1;
      end if;
    end if;
  end process;

  gen_leds: for i in 0 to NLEDS-1 generate
    signal d_i : unsigned(PW-1 downto 0);
  begin
    d_i <= unsigned(duty((i+1)*PW-1 downto i*PW));
    led_out(i) <= '1' when ctr < d_i else '0';
  end generate;
end architecture;

