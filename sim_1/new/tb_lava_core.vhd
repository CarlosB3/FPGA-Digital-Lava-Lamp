library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_lava_core is
  -- Testbench has no ports
end entity;

architecture sim of tb_lava_core is

  -- Component Declaration for the Unit Under Test (UUT)
  component lava_core
    port (
      clk      : in  std_logic;
      rst_n    : in  std_logic;
      mode_sel : in  std_logic_vector(1 downto 0);
      auto_en  : in  std_logic;
      rev      : in  std_logic;
      led_out  : out std_logic_vector(7 downto 0)
    );
  end component;

  -- Signals to connect to UUT
  signal clk      : std_logic := '0';
  signal rst_n    : std_logic := '0';
  signal mode_sel : std_logic_vector(1 downto 0) := "00";
  signal auto_en  : std_logic := '0';
  signal rev      : std_logic := '0';
  signal led_out  : std_logic_vector(7 downto 0);

  -- Clock period definition (100 MHz)
  constant CLK_PERIOD : time := 10 ns;

begin

  -- Instantiate the Unit Under Test (UUT)
  uut: lava_core
    port map (
      clk      => clk,
      rst_n    => rst_n,
      mode_sel => mode_sel,
      auto_en  => auto_en,
      rev      => rev,
      led_out  => led_out
    );

  -- Clock Process
  clk_process : process
  begin
    clk <= '0';
    wait for CLK_PERIOD/2;
    clk <= '1';
    wait for CLK_PERIOD/2;
  end process;

  -- Stimulus Process
  stim_proc: process
  begin
    -- 1. Reset the system
    rst_n <= '0';
    wait for 100 ns;
    rst_n <= '1';
    wait for 100 ns;

    -- -------------------------------------------------------
    -- Test Case A: Manual Sparkle Mode (00)
    -- -------------------------------------------------------
    report "Starting Test: Sparkle Mode";
    mode_sel <= "00"; -- Sparkle
    auto_en  <= '0';
    wait for 2000 ns; 

    -- -------------------------------------------------------
    -- Test Case B: Manual Sweep Mode (01)
    -- -------------------------------------------------------
    report "Starting Test: Sweep Mode";
    mode_sel <= "01"; -- Sweep
    rev      <= '0';  -- Forward direction
    wait for 2000 ns;    
    
    -- Test Reverse Sweep
    report "Testing Reverse Direction";
    rev      <= '1';  -- Reverse direction
    wait for 2000 ns;

    -- -------------------------------------------------------
    -- Test Case C: Manual Fade Mode (10)
    -- -------------------------------------------------------
    report "Starting Test: Fade Mode (Sine LUT)";
    mode_sel <= "10";
    wait for 5000 ns;   -- Allow time for LUT index to cycle

    -- -------------------------------------------------------
    -- Test Case D: Manual Ember Mode (11)
    -- -------------------------------------------------------
    report "Starting Test: Ember Mode (Stochastic)";
    mode_sel <= "11";
    wait for 5000 ns;   -- Allow time for decay and reignition

    -- -------------------------------------------------------
    -- Test Case E: Auto Cycle Mode
    -- -------------------------------------------------------
    report "Starting Test: Auto Mode";
    auto_en <= '1';   -- Enable auto-switching
    wait for 10000 ns; -- Wait long enough to see mode switches

    -- End Simulation
    report "Simulation Finished";
    wait;
  end process;

end architecture;