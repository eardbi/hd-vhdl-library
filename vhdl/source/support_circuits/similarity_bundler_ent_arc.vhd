-------------------------------------------------------------------------------
-- Title      : Similarity Bundler
-- Project    : Semester Thesis I
-------------------------------------------------------------------------------
-- File       : similarity_bundler_ent_arc.vhd
-- Author     : Manuel Schmuck <schmucma@student.ethz.ch>
-- Company    : Integrated Systems Laboratory, ETH Zurich
-- Created    : 2017-09-30
-- Last update: 2018-06-15
-- Platform   : ModelSim (simulation), Vivado (synthesis)
-------------------------------------------------------------------------------
-- Description: Entity and architecture of the similarity bundler used in the
--              enhanced architecture.
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
use work.hdc_enhanced_pkg.all;

-------------------------------------------------------------------------------

entity similarity_bundler is
  generic (
    MAX_BUNDLE_CYCLES : integer := MAX_BUNDLE_CYCLES
    );

  port (
    Clk_CI   : in std_logic;
    Reset_RI : in std_logic;

    BundledHypervectorEN_SI : in std_logic;

    CycleShiftRegEN_SI  : in std_logic;
    CycleShiftRegCLR_SI : in std_logic;

    HypervectorIn_DI  : in  hypervector(0 to HV_DIMENSION-1);
    HypervectorOut_DO : out hypervector(0 to HV_DIMENSION-1)
    );
end similarity_bundler;

-------------------------------------------------------------------------------

architecture behavioral of similarity_bundler is

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------
  -- Data Registers
  signal BundledHypervector_DP, BundledHypervector_DN : hypervector(0 to HV_DIMENSION-1);

  -- Control Registers
  signal CycleShiftReg_SP, CycleShiftReg_SN : std_logic_vector(0 to MAX_BUNDLE_CYCLES-1);

  -- Datapath Signals
  signal SimilarHypervector_D : hypervector(0 to HV_DIMENSION-1);

  -----------------------------------------------------------------------------
  -- Components
  -----------------------------------------------------------------------------
  -- Hypervector Manipulator
  component hypervector_manipulator is
    generic (
      WIDTH               : integer;
      DEPTH               : integer;
      CONNECTIVITY_MATRIX : std_logic_vector_array(0 to DEPTH-1)(0 to WIDTH-1));
    port (
      HypervectorIn_DI  : in  std_logic_vector(0 to WIDTH-1);
      ManipulatorIn_DI  : in  std_logic_vector(0 to DEPTH-1);
      HypervectorOut_DO : out std_logic_vector(0 to HV_DIMENSION-1));
  end component hypervector_manipulator;

begin

  -----------------------------------------------------------------------------
  -- Datapath
  -----------------------------------------------------------------------------
  -- Cycle Shift Register
  CycleShiftReg_SN <= CycleShiftReg_SP srl 1;

  -- Similar Hypervector
  i_hypervector_manipulator_1 : hypervector_manipulator
    generic map (
      WIDTH               => HV_DIMENSION,
      DEPTH               => MAX_BUNDLE_CYCLES,
      CONNECTIVITY_MATRIX => BUNDLE_CONNECTIVITY_MATRIX)
    port map (
      HypervectorIn_DI  => BundledHypervector_DP,
      ManipulatorIn_DI  => CycleShiftReg_SP,
      HypervectorOut_DO => SimilarHypervector_D);

  -- Majority
  comb_majority : process (BundledHypervector_DP, HypervectorIn_DI, SimilarHypervector_D) is
    variable sum : integer := 0;
  begin  -- process comb_majority
    for i in 0 to HV_DIMENSION-1 loop
--       sum := logic_to_integer(BundledHypervector_DP(i))
--              + logic_to_integer(HypervectorIn_DI(i))
--              + logic_to_integer(SimilarHypervector_D(i));
--       BundledHypervector_DN(i) <= '1' when sum > 1 else '0';
      BundledHypervector_DN(i) <=
        (BundledHypervector_DP(i) and HypervectorIn_DI(i)) or
        (BundledHypervector_DP(i) and SimilarHypervector_D(i)) or
        (HypervectorIn_DI(i) and SimilarHypervector_D(i));
    end loop;  -- i
  end process comb_majority;

  -- Output
  HypervectorOut_DO <= BundledHypervector_DP;

  -----------------------------------------------------------------------------
  -- Registers
  -----------------------------------------------------------------------------
  -- Cycle Shift Register
  seq_cycle_shift_register : process (Clk_CI)
  begin  -- process seq_cycle_shift_register
    if (rising_edge(Clk_CI)) then       -- rising clock edge
      if (Reset_RI or CycleShiftRegCLR_SI) = '1' then
        CycleShiftReg_SP <= (0 => '1', others => '0');
      elsif CycleShiftRegEN_SI = '1' then
        CycleShiftReg_SP <= CycleShiftReg_SN;
      end if;
    end if;
  end process seq_cycle_shift_register;

  -- Bundled Hypervector
  seq_bundled_hypervector : process (Clk_CI)
  begin  -- process seq_bundled_hypervector
    if (rising_edge(Clk_CI)) then       -- rising clock edge
      if Reset_RI = '1' then
        BundledHypervector_DP <= (others => '0');
      elsif BundledHypervectorEN_SI = '1' then
        BundledHypervector_DP <= BundledHypervector_DN;
      end if;
    end if;
  end process seq_bundled_hypervector;


end behavioral;
