library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lfsr_core is
  port (
    clk       : in  std_logic;
    rst_n     : in  std_logic;
    enable    : in  std_logic;
    q         : out std_logic_vector(15 downto 0)
  );
end entity;

architecture rtl of lfsr_core is
  signal r : std_logic_vector(15 downto 0) := (others => '1'); 
begin
  q <= r;

  process(clk)
    variable feedback : std_logic;
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        r <= (others => '1');
      elsif enable = '1' then
        -- taps: 16,14,13,11 (primitive poly x^16+x^14+x^13+x^11+1)
        feedback := r(15);
        r(15 downto 1) <= r(14 downto 0);
        r(0) <= feedback xor r(2) xor r(3) xor r(5);  
      end if;
    end if;
  end process;
end architecture;

