library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_lava_core is
end entity tb_lava_core;

architecture sim of tb_lava_core is

  -- DUT ports
  signal clk      : std_logic := '0';
  signal rst_n    : std_logic := '0';
  signal mode_sel : std_logic_vector(1 downto 0) := "00";
  signal auto_en  : std_logic := '0';
  signal rev      : std_logic := '0';
  signal led_out  : std_logic_vector(7 downto 0);

begin

  --------------------------------------------------------------------------
  -- Clock generation: 100 MHz (10 ns period)
  --------------------------------------------------------------------------
  clk <= not clk after 5 ns;

  --------------------------------------------------------------------------
  -- DUT instantiation
  --------------------------------------------------------------------------
  dut: entity work.lava_core
    port map (
      clk      => clk,
      rst_n    => rst_n,
      mode_sel => mode_sel,
      auto_en  => auto_en,
      rev      => rev,
      led_out  => led_out
    );

  --------------------------------------------------------------------------
  -- Stimulus process
  --------------------------------------------------------------------------
  stim_proc : process
  begin

    ------------------------------------------------------------------
    -- Global reset
    ------------------------------------------------------------------
    rst_n    <= '0';
    auto_en  <= '0';
    rev      <= '0';
    mode_sel <= "00";  -- sparkle
    wait for 200 ns;

    rst_n <= '1';
    wait for 1 us;

    ------------------------------------------------------------------
    -- 1) Manual: Sparkle (00)
    ------------------------------------------------------------------
    mode_sel <= "00";  -- sparkle
    auto_en  <= '0';
    rev      <= '0';
    wait for 5 ms;

    ------------------------------------------------------------------
    -- 2) Manual: Sweep forward (01, rev=0)
    ------------------------------------------------------------------
    mode_sel <= "01";  -- sweep
    rev      <= '0';
    wait for 5 ms;

    ------------------------------------------------------------------
    -- 3) Manual: Sweep reverse (01, rev=1)
    ------------------------------------------------------------------
    rev <= '1';
    wait for 5 ms;

    ------------------------------------------------------------------
    -- 4) Manual: Fade (10)
    ------------------------------------------------------------------
    mode_sel <= "10";  -- fade
    rev      <= '0';
    wait for 20 ms;

    ------------------------------------------------------------------
    -- 5) Manual: Ember (11)
    ------------------------------------------------------------------
    mode_sel <= "11";  -- ember
    wait for 30 ms;

    ------------------------------------------------------------------
    -- 6) Auto mode cycling
    ------------------------------------------------------------------
    auto_en  <= '1';   -- enable auto FSM
    mode_sel <= "00";  -- ignored in auto
    wait for 100 ms;

    ------------------------------------------------------------------
    -- Finish simulation
    ------------------------------------------------------------------
    assert false report "Simulation finished" severity failure;

  end process;

end architecture sim;

