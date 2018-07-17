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
-- Title      : Hypervector Manipulator
-- Project    : Semester Thesis I
-------------------------------------------------------------------------------
-- File       : hypervector_manipulator_ent_arc.vhd
-- Author     : Manuel Schmuck <schmucma@student.ethz.ch>
-- Company    : Integrated Systems Laboratory, ETH Zurich
-- Created    : 2017-09-30
-- Last update: 2018-06-15
-- Platform   : ModelSim (simulation), Vivado (synthesis)
-------------------------------------------------------------------------------
-- Description: Entity and architecture of the hypervector manipulator.
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

entity hypervector_manipulator is
  generic (
    WIDTH               : integer := HV_DIMENSION;
    DEPTH               : integer;
    CONNECTIVITY_MATRIX : std_logic_vector_array(0 to DEPTH-1)(0 to WIDTH-1)
    );

  port (
    HypervectorIn_DI : in std_logic_vector(0 to WIDTH-1);
    ManipulatorIn_DI : in std_logic_vector(0 to DEPTH-1);

    HypervectorOut_DO : out std_logic_vector(0 to WIDTH-1)
    );
end hypervector_manipulator;

-------------------------------------------------------------------------------

architecture behavioral of hypervector_manipulator is

begin

  -- Manipulate Hypervector
  comb_manipulate_hypervector : process (HypervectorIn_DI, ManipulatorIn_DI) is
    variable or_column : std_logic := '0';
  begin  -- process comb_manipulate_hypervector
    for i in 0 to WIDTH-1 loop
      or_column := '0';
      for j in 0 to DEPTH-1 loop
        if CONNECTIVITY_MATRIX(j)(i) = '1' then
          or_column := or_column or ManipulatorIn_DI(j);
        end if;
      end loop;  -- j
      HypervectorOut_DO(i) <= HypervectorIn_DI(i) xor or_column;
    end loop;  -- i
  end process comb_manipulate_hypervector;

end behavioral;
