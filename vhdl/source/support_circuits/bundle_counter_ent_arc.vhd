-------------------------------------------------------------------------------
-- Title      : Bundle Counter
-- Project    : Semester Thesis I
-------------------------------------------------------------------------------
-- File       : bundle_counter_ent_arc.vhd
-- Author     : Manuel Schmuck <schmucma@student.ethz.ch>
-- Company    : Integrated Systems Laboratory, ETH Zurich
-- Created    : 2017-09-30
-- Last update: 2018-06-15
-- Platform   : ModelSim (simulation), Vivado (synthesis)
-------------------------------------------------------------------------------
-- Description: Entity and architecture of the bundle counter used in the
--              baseline and enhanced architecture.
-------------------------------------------------------------------------------
-- Copyright (c) 2017 Integrated Systems Laboratory, ETH Zurich
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author    Description
-- 2018        1.0      schmucma  Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.hdc_pkg.all;

-------------------------------------------------------------------------------

entity bundle_counter is
  generic (
    WIDTH : integer := BUNDLE_NGRAMS_WIDTH
    );

  port (
    Clk_CI   : in std_logic;
    Reset_RI : in std_logic;

    Enable_SI : in std_logic;

    FirstHypervector_SI : in std_logic;

    HypervectorIn_DI  : in  hypervector(0 to HV_DIMENSION-1);
    HypervectorOut_DO : out hypervector(0 to HV_DIMENSION-1)
    );
end bundle_counter;

-------------------------------------------------------------------------------

architecture behavioral of bundle_counter is
  -- Constants
  constant MAX_VALUE : signed(WIDTH-1 downto 0) := to_signed(2**(WIDTH-1)-1, WIDTH);
  constant MIN_VALUE : signed(WIDTH-1 downto 0) := to_signed(-2**(WIDTH-1), WIDTH);

  -- Signals
  signal BundleCounter_DP, BundleCounter_DN : signed_array(0 to HV_DIMENSION-1)(WIDTH-1 downto 0);
  signal CounterSEN_S                       : std_logic_vector(0 to HV_DIMENSION-1);

begin

  -----------------------------------------------------------------------------
  -- Datapath
  -----------------------------------------------------------------------------
  -- Next State
  comb_bundle_counter : process (BundleCounter_DP, FirstHypervector_SI, HypervectorIn_DI)
  begin  -- process comb_bundle_counter
    for i in 0 to HV_DIMENSION-1 loop
      if FirstHypervector_SI = '1' then
        BundleCounter_DN(i) <= (others => HypervectorIn_DI(i));
        CounterSEN_S(i)     <= '1';
      else
        if HypervectorIn_DI(i) = '1' then
          BundleCounter_DN(i) <= BundleCounter_DP(i)-1;
          CounterSEN_S(i)     <= '0' when BundleCounter_DP(i) = MIN_VALUE else '1';
        else
          BundleCounter_DN(i) <= BundleCounter_DP(i)+1;
          CounterSEN_S(i)     <= '0' when BundleCounter_DP(i) = MAX_VALUE else '1';
        end if;
      end if;
    end loop;  -- i
  end process comb_bundle_counter;

  -- Output
  asgn_output : process (BundleCounter_DP) is
  begin  -- process asgn_output
    for i in 0 to HV_DIMENSION-1 loop
      HypervectorOut_DO(i) <= BundleCounter_DP(i)(BundleCounter_DP(i)'high);
    end loop;  -- i
  end process asgn_output;

  -----------------------------------------------------------------------------
  -- Registers
  -----------------------------------------------------------------------------
  -- Bundle NGrams Counter
  -- Both Enable and Self Enable have to be set to trigger flip-flop
  gen_seq_bundle_counter : for i in 0 to HV_DIMENSION-1 generate
    seq_bundle_counter : process (Clk_CI)
    begin  -- process seq_bundle_ngrams_cntr
      if (rising_edge(Clk_CI)) then     -- rising clock edge
        if Reset_RI = '1' then
          BundleCounter_DP(i) <= (others => '0');
        elsif (Enable_SI and CounterSEN_S(i)) = '1' then
          BundleCounter_DP(i) <= BundleCounter_DN(i);
        end if;
      end if;
    end process seq_bundle_counter;
  end generate gen_seq_bundle_counter;


end behavioral;
