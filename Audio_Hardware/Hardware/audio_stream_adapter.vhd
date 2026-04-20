--------------------------------------------------------------------------------
-- audio_stream_adapter.vhd
--
-- Purpose:
--   Accepts signed 16-bit audio samples on an AXI-Stream slave interface
--   (coming from axi_dma_0.M_AXIS_MM2S, typically through an AXI-Stream
--   data FIFO), adds a +2048 bias to map signed -2047..+2047 into unsigned
--   0..4095, and drives a 12-bit unsigned duty_cycle output to feed
--   pwm_modulator (Case's existing IP, pwm_bits=12).
--
--   Also handles sample-rate pacing: we target ~48 kHz, and drive the
--   pwm_modulator.duty_cycle at that rate. TREADY is held high when the
--   internal hold register is available to be updated by the next sample
--   time; between sample ticks TREADY is low so the upstream FIFO
--   backpressures cleanly and the DMA cyclic BDs meter out at the right rate.
--
--   Sample-rate generation: clk = 100 MHz, divide by 2083 => 48.00 kHz
--   (100_000_000 / 48_000 = 2083.33; 2083 gives 48.00 kHz +/- 0.02%).
--
-- Interface (AXI-Stream slave):
--   s_axis_tdata : signed 16-bit, little-endian, lower 12 bits carry the
--                  ADC sample (sign-extended), upper 4 bits zero for
--                  positive or 1 for negative (i.e. true signed 16-bit)
--   s_axis_tvalid, s_axis_tready, s_axis_tlast, s_axis_tkeep[1:0]
--
-- Output:
--   duty_cycle[11:0] : unsigned, held between sample updates
--   sample_tick      : single-cycle pulse at the sample rate (debug)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity audio_stream_adapter is
    generic (
        -- clk_100MHz / SAMPLE_RATE_DIV = sample rate
        -- Default 2083 => 48.00 kHz at 100 MHz input clock
        SAMPLE_RATE_DIV : integer := 2083
    );
    port (
        clk               : in  std_logic;
        rstn              : in  std_logic;

        -- AXI-Stream slave: 16-bit signed samples from DMA MM2S
        s_axis_tdata      : in  std_logic_vector(15 downto 0);
        s_axis_tvalid     : in  std_logic;
        s_axis_tready     : out std_logic;
        s_axis_tlast      : in  std_logic;
        s_axis_tkeep      : in  std_logic_vector(1 downto 0);

        -- To pwm_modulator.duty_cycle (12-bit unsigned)
        duty_cycle        : out std_logic_vector(11 downto 0);

        -- Debug / sim aid: pulses every sample tick
        sample_tick       : out std_logic
    );
end entity audio_stream_adapter;

architecture rtl of audio_stream_adapter is

    signal sample_cnt   : unsigned(15 downto 0) := (others => '0');
    signal tick         : std_logic := '0';
    signal hold         : unsigned(11 downto 0) := to_unsigned(2048, 12);
    signal sample_s     : signed(15 downto 0);
    signal biased       : signed(16 downto 0);
    signal saturated    : unsigned(11 downto 0);
    signal ready_int    : std_logic;

begin

    ---------------------------------------------------------------------------
    -- Sample-rate clock enable.
    -- Counts clk_100MHz cycles; 'tick' pulses high for exactly one cycle
    -- every SAMPLE_RATE_DIV cycles. On that cycle we present TREADY=1 so
    -- the upstream FIFO hands us one sample, which we latch into 'hold'.
    ---------------------------------------------------------------------------
    sample_tick_gen : process(clk)
    begin
        if rising_edge(clk) then
            if rstn = '0' then
                sample_cnt <= (others => '0');
                tick       <= '0';
            else
                if sample_cnt = to_unsigned(SAMPLE_RATE_DIV - 1, 16) then
                    sample_cnt <= (others => '0');
                    tick       <= '1';
                else
                    sample_cnt <= sample_cnt + 1;
                    tick       <= '0';
                end if;
            end if;
        end if;
    end process;

    -- TREADY only asserted on the tick cycle. This backpressures the DMA
    -- to exactly the sample rate - the cyclic SG ring self-meters.
    ready_int     <= tick;
    s_axis_tready <= ready_int;

    ---------------------------------------------------------------------------
    -- Bias: signed -2047..+2047 (sign-extended into 16-bit) + 2048
    --       -> 17-bit signed intermediate, then saturate to unsigned 0..4095
    -- Even with a well-behaved source, saturate to be safe against clipping.
    ---------------------------------------------------------------------------
    sample_s <= signed(s_axis_tdata);
    biased   <= resize(sample_s, 17) + to_signed(2048, 17);

    saturate : process(biased)
    begin
        if biased < to_signed(0, 17) then
            saturated <= (others => '0');
        elsif biased > to_signed(4095, 17) then
            saturated <= (others => '1');
        else
            saturated <= unsigned(biased(11 downto 0));
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Latch one sample per tick (if the upstream has valid data). If not,
    -- hold the previous value (graceful stall behavior; on Cyclic SG this
    -- should never happen in steady state, but it keeps the PWM from glitching
    -- on bring-up before the DMA is armed).
    ---------------------------------------------------------------------------
    latch_proc : process(clk)
    begin
        if rising_edge(clk) then
            if rstn = '0' then
                hold <= to_unsigned(2048, 12);  -- silence = mid-rail
            elsif (tick = '1') and (s_axis_tvalid = '1') then
                hold <= saturated;
            end if;
        end if;
    end process;

    duty_cycle  <= std_logic_vector(hold);
    sample_tick <= tick;

end architecture rtl;
