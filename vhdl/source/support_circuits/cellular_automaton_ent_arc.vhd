-- Copyright 2018 ETH Zurich
-- Copyright and related rights are licensed under the Solderpad Hardware
-- License, Version 0.51 (the “License”); you may not use this file except in
-- compliance with the License.  You may obtain a copy of the License at
-- http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
-- or agreed to in writing, software, hardware and materials distributed under
-- this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
-- CONDITIONS OF ANY KIND, either express or implied. See the License for the
-- specific language governing permissions and limitations under the License.

-------------------------------------------------------------------------------
-- Title      : Cellular Automaton
-- Project    : Semester Thesis I
-------------------------------------------------------------------------------
-- File       : cellular_automaton_ent_arc.vhd
-- Author     : Manuel Schmuck <schmucma@student.ethz.ch>
-- Company    : Integrated Systems Laboratory, ETH Zurich
-- Created    : 2017-09-30
-- Last update: 2018-06-15
-- Platform   : ModelSim (simulation), Vivado (synthesis)
-------------------------------------------------------------------------------
-- Description: Entity and architecture of the cellular automaton. Can be used
--              to generate random hypervectors.
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

entity cellular_automaton is
  generic (
    WIDTH                   : integer := HV_DIMENSION;
    NEIGHBORHOOD_WIDTH      : integer := 3;
    RULE                    : integer := 30;
    CELLULAR_AUTOMATON_SEED : std_logic_vector(0 to WIDTH-1)
    );

  port (
    Clk_CI   : in std_logic;
    Reset_RI : in std_logic;

    Enable_SI : in std_logic;
    Clear_SI  : in std_logic;

    CellValueOut_DO : out std_logic_vector(0 to WIDTH-1)
    );
end cellular_automaton;

-------------------------------------------------------------------------------

architecture behavioral of cellular_automaton is

  -- Cellular Automaton Rule in Vector Form
  constant RULE_VECTOR : std_logic_vector(2**(2**NEIGHBORHOOD_WIDTH)-1 downto 0) :=
    std_logic_vector(to_unsigned(RULE, 2**(2**NEIGHBORHOOD_WIDTH)));

  -- Cell Registers
  signal Cells_DP, Cells_DN : std_logic_vector(0 to WIDTH-1);

begin

  -----------------------------------------------------------------------------
  -- Datapath
  -----------------------------------------------------------------------------
  -- Next State
  comb_ca : process (Cells_DP) is
    variable neighborhood : std_logic_vector(0 to NEIGHBORHOOD_WIDTH-1);
  begin  -- process comb_ca
    neighborhood := (Cells_DP(Cells_DP'high) & Cells_DP(0 to 1));
    Cells_DN(0)  <= RULE_VECTOR(to_integer(unsigned(neighborhood)));
    for i in 1 to WIDTH-2 loop
      neighborhood := Cells_DP(i-1 to i+1);
      Cells_DN(i)  <= RULE_VECTOR(to_integer(unsigned(neighborhood)));
    end loop;  -- i
    neighborhood            := (Cells_DP(Cells_DP'high-1 to Cells_DP'high) & Cells_DP(0));
    Cells_DN(Cells_DN'high) <= RULE_VECTOR(to_integer(unsigned(neighborhood)));
  end process comb_ca;

  -- Output
  CellValueOut_DO <= Cells_DP;

  -----------------------------------------------------------------------------
  -- Register
  -----------------------------------------------------------------------------
  -- Cellular Automaton
  seq_ca : process (Clk_CI)
  begin  -- process seq_ca
    if (rising_edge(Clk_CI)) then       -- rising clock edge
      if (Reset_RI or Clear_SI) = '1' then
        Cells_DP <= CELLULAR_AUTOMATON_SEED;
      elsif Enable_SI = '1' then
        Cells_DP <= Cells_DN;
      end if;
    end if;
  end process seq_ca;


end behavioral;
