library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lava_core is
  port (
    clk      : in  std_logic;
    rst_n    : in  std_logic;
    mode_sel : in  std_logic_vector(1 downto 0);
    auto_en  : in  std_logic;
    rev      : in  std_logic;                 -- SW3: reverse sweep
    led_out  : out std_logic_vector(7 downto 0)
  );
end entity lava_core;

architecture rtl of lava_core is

  constant NLEDS    : integer := 8;
  constant PW       : integer := 8;

  constant TICK_MAX : unsigned(23 downto 0) := to_unsigned(10_000_000, 24);

  constant AUTO_MAX : unsigned(15 downto 0) := to_unsigned(80, 16);

  -- ember decay step (brightness drop per tick)
  constant DECAY_STEP : unsigned(PW-1 downto 0) := to_unsigned(16, PW);  -- faster decay

  -- sweep brightness levels
  constant DUTY_FULL  : unsigned(PW-1 downto 0) := (others => '1');       -- 255
  constant DUTY_HALF  : unsigned(PW-1 downto 0) := to_unsigned(128, PW);  -- ~50%
  constant DUTY_QUART : unsigned(PW-1 downto 0) := to_unsigned(64,  PW);  -- ~25%

  --------------------------------------------------------------------------
  -- Fade limits + sine LUT (for mode "10")
  --------------------------------------------------------------------------
  constant FADE_MIN      : unsigned(PW-1 downto 0) := (others => '0');  -- 0% (used for Ember)

  constant FADE_LUT_SIZE : integer := 32;

  type fade_lut_t is array (0 to FADE_LUT_SIZE-1) of unsigned(PW-1 downto 0);

  constant fade_lut : fade_lut_t := (
    0  => to_unsigned( 77, PW),
    1  => to_unsigned( 79, PW),
    2  => to_unsigned( 84, PW),
    3  => to_unsigned( 92, PW),
    4  => to_unsigned(103, PW),
    5  => to_unsigned(117, PW),
    6  => to_unsigned(132, PW),
    7  => to_unsigned(149, PW),
    8  => to_unsigned(166, PW),
    9  => to_unsigned(183, PW),
    10 => to_unsigned(200, PW),
    11 => to_unsigned(215, PW),
    12 => to_unsigned(229, PW),
    13 => to_unsigned(240, PW),
    14 => to_unsigned(248, PW),
    15 => to_unsigned(253, PW),
    16 => to_unsigned(255, PW),
    17 => to_unsigned(253, PW),
    18 => to_unsigned(248, PW),
    19 => to_unsigned(240, PW),
    20 => to_unsigned(229, PW),
    21 => to_unsigned(215, PW),
    22 => to_unsigned(200, PW),
    23 => to_unsigned(183, PW),
    24 => to_unsigned(166, PW),
    25 => to_unsigned(149, PW),
    26 => to_unsigned(132, PW),
    27 => to_unsigned(117, PW),
    28 => to_unsigned(103, PW),
    29 => to_unsigned( 92, PW),
    30 => to_unsigned( 84, PW),
    31 => to_unsigned( 79, PW)
  );

  -- animation tick
  signal tick_ctr : unsigned(23 downto 0) := (others => '0');
  signal tick     : std_logic := '0';

  -- LFSR output
  signal rnd      : std_logic_vector(15 downto 0);

  -- mode control
  signal mode_cur : std_logic_vector(1 downto 0) := "00";
  signal auto_ctr : unsigned(15 downto 0) := (others => '0');

  -- sweep mode
  signal head     : integer range 0 to NLEDS-1 := 0;

  -- fade mode (sine LUT)
  signal fade_idx : unsigned(4 downto 0) := (others => '0');  -- 0..31
  signal fade_val : unsigned(PW-1 downto 0) := fade_lut(0);

  -- ember mode persistent duties
  signal duty_ember : std_logic_vector(NLEDS*PW-1 downto 0) := (others => '0');

  -- duties for all LEDs (packed)
  signal duty_bus : std_logic_vector(NLEDS*PW-1 downto 0) := (others => '0');

begin

  -- Animation tick generator
  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        tick_ctr <= (others => '0');
        tick     <= '0';
      else
        if tick_ctr = TICK_MAX then
          tick_ctr <= (others => '0');
          tick     <= '1';
        else
          tick_ctr <= tick_ctr + 1;
          tick     <= '0';
        end if;
      end if;
    end if;
  end process;

  -- LFSR (runs continuously)
  lfsr0: entity work.lfsr_core
    port map (
      clk    => clk,
      rst_n  => rst_n,
      enable => '1',
      q      => rnd
    );

  -- Mode control: manual vs auto-cycle
  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        mode_cur <= "00";
        auto_ctr <= (others => '0');
      else
        if auto_en = '1' then
          -- auto: change mode every AUTO_MAX ticks
          if tick = '1' then
            if auto_ctr = AUTO_MAX then
              auto_ctr <= (others => '0');
              case mode_cur is
                when "00" => mode_cur <= "01"; -- sparkle -> sweep
                when "01" => mode_cur <= "10"; -- sweep -> fade
                when "10" => mode_cur <= "11"; -- fade -> ember
                when others => mode_cur <= "00"; -- ember -> sparkle
              end case;
            else
              auto_ctr <= auto_ctr + 1;
            end if;
          end if;
        else
          -- manual: direct from switches
          mode_cur <= mode_sel;
          auto_ctr <= (others => '0');
        end if;
      end if;
    end if;
  end process;

  process(clk)
    variable d        : unsigned(PW-1 downto 0);
    variable i_prev1  : integer;
    variable i_prev2  : integer;
    variable head_next: integer;
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        duty_bus   <= (others => '0');
        duty_ember <= (others => '0');
        head       <= 0;
        fade_idx   <= (others => '0');
        fade_val   <= fade_lut(0);
      elsif tick = '1' then
        case mode_cur is

          -- 00: Sparkle (LFSR-driven twinkle)
          when "00" =>
            duty_bus( 7 downto  0) <= rnd(7 downto 0);
            duty_bus(15 downto  8) <= rnd(15 downto 8);
            duty_bus(23 downto 16) <= rnd(7 downto 0);
            duty_bus(31 downto 24) <= rnd(15 downto 8);
            duty_bus(39 downto 32) <= rnd(7 downto 0);
            duty_bus(47 downto 40) <= rnd(15 downto 8);
            duty_bus(55 downto 48) <= rnd(7 downto 0);
            duty_bus(63 downto 56) <= rnd(15 downto 8);

          -- 01: Sweep (moving head + tail gradient; rev=1 reverses direction)
          when "01" =>
            -- compute next head based on rev
            if rev = '0' then
              if head = NLEDS-1 then
                head_next := 0;
              else
                head_next := head + 1;
              end if;
            else
              if head = 0 then
                head_next := NLEDS-1;
              else
                head_next := head - 1;
              end if;
            end if;

            head <= head_next;

            i_prev1 := (head_next - 1 + NLEDS) mod NLEDS;
            i_prev2 := (head_next - 2 + NLEDS) mod NLEDS;

            for i in 0 to NLEDS-1 loop
              if i = head_next then
                duty_bus((i+1)*PW-1 downto i*PW) <= std_logic_vector(DUTY_FULL);
              elsif i = i_prev1 then
                duty_bus((i+1)*PW-1 downto i*PW) <= std_logic_vector(DUTY_HALF);
              elsif i = i_prev2 then
                duty_bus((i+1)*PW-1 downto i*PW) <= std_logic_vector(DUTY_QUART);
              else
                duty_bus((i+1)*PW-1 downto i*PW) <= (others => '0');
              end if;
            end loop;

          -- 10: Fade (
          when "10" =>
            if fade_idx = to_unsigned(FADE_LUT_SIZE-1, fade_idx'length) then
              fade_idx <= (others => '0');
            else
              fade_idx <= fade_idx + 1;
            end if;

            fade_val <= fade_lut(to_integer(fade_idx));

            for i in 0 to NLEDS-1 loop
              duty_bus((i+1)*PW-1 downto i*PW) <= std_logic_vector(fade_val);
            end loop;

          -- 11: Ember 
          when others =>
            for i in 0 to NLEDS-1 loop
              d := unsigned(duty_ember((i+1)*PW-1 downto i*PW));

              if d = FADE_MIN then
                -- LED is fully dark: allow random ignition
                if (rnd(i mod 16) = '1') and (rnd((i+5) mod 16) = '1') then
                  d := DUTY_FULL;  -- ignite to max brightness
                end if;
              else
                -- LED is lit: only decay toward zero
                if d > DECAY_STEP then
                  d := d - DECAY_STEP;
                else
                  d := FADE_MIN;
                end if;
              end if;

              duty_ember((i+1)*PW-1 downto i*PW) <= std_logic_vector(d);
            end loop;
         
            duty_bus <= duty_ember;

        end case;
      end if;
    end if;
  end process;

  pwm0: entity work.pwm_bank
    generic map ( NLEDS => NLEDS, PW => PW )
    port map (
      clk     => clk,
      rst_n   => rst_n,
      duty    => duty_bus,
      led_out => led_out
    );

end architecture rtl;
