library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_lava_lamp is
  port (
    clk : in  std_logic;
    sw  : in  std_logic_vector(7 downto 0);
    led : out std_logic_vector(7 downto 0)
  );
end entity top_lava_lamp;

architecture rtl of top_lava_lamp is

  signal rst_n    : std_logic;
  signal mode_sel : std_logic_vector(1 downto 0);
  signal auto_en  : std_logic;
  signal rev_dir  : std_logic;

  signal led_core : std_logic_vector(7 downto 0);

begin

  -- Switch mapping
  rst_n    <= sw(7);             -- SW7: 1=run, 0=reset
  mode_sel <= sw(1 downto 0);    -- SW1..SW0: 00,01,10,11
  auto_en  <= sw(2);             -- SW2: auto-mode
  rev_dir  <= sw(3);             -- SW3: 0=normal, 1=reversed sweep

  lava: entity work.lava_core
    port map (
      clk      => clk,
      rst_n    => rst_n,
      mode_sel => mode_sel,
      auto_en  => auto_en,
      rev      => rev_dir,
      led_out  => led_core
    );

  led <= led_core;

end architecture rtl;

