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
-- Title      : Block Shift Memory
-- Project    : Semester Thesis I
-------------------------------------------------------------------------------
-- File       : block_shift_memory_ent_arc.vhd
-- Author     : Manuel Schmuck <schmucma@student.ethz.ch>
-- Company    : Integrated Systems Laboratory, ETH Zurich
-- Created    : 2017-09-30
-- Last update: 2018-06-15
-- Last update: 2018-01-02
-- Platform   : ModelSim (simulation), Vivado (synthesis)
-------------------------------------------------------------------------------
-- Description: Entity and architecture of the block shift memory used in
--              the associative memory.
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

entity block_shift_memory is
  generic (
    WIDTH  : integer := HV_DIMENSION;
    BLOCKS : integer := HV_DIMENSION/2
    );

  port (
    Clk_CI   : in std_logic;
    Reset_RI : in std_logic;

    Enable_SI : in std_logic;
    Mode_SI   : in std_logic;

    CellsIn_DI      : in  std_logic_vector(0 to WIDTH-1);
    BlockBitsOut_DO : out std_logic_vector(0 to BLOCKS-1)
    );
end block_shift_memory;

-------------------------------------------------------------------------------

architecture behavioral of block_shift_memory is

  -----------------------------------------------------------------------------
  -- Constants
  -----------------------------------------------------------------------------
  constant BLOCK_WIDTH : integer := WIDTH / BLOCKS;

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------
  -- Data Registers
  signal CellMemory_DP, CellMemory_DN : std_logic_vector(0 to WIDTH-1);

begin

  -----------------------------------------------------------------------------
  -- Datapath
  -----------------------------------------------------------------------------
  -- Cell Memory Next State
  comb_cell_memory : process (CellMemory_DP, CellsIn_DI, Mode_SI) is
  begin  -- process comb_cell_memory
    if Mode_SI = mode_store then
      CellMemory_DN <= CellsIn_DI;
    else
      for j in 0 to BLOCKS-1 loop
        CellMemory_DN(j * BLOCK_WIDTH to (j+1) * BLOCK_WIDTH - 1)
          <= CellMemory_DP(j * BLOCK_WIDTH to (j+1) * BLOCK_WIDTH - 1) rol 1;
      end loop;  -- j
    end if;
  end process comb_cell_memory;

  -- Outputs
  asgn_outputs : process (CellMemory_DP) is
  begin  -- process asgn_outputs
    for j in 0 to BLOCKS-1 loop
      BlockBitsOut_DO(j) <= CellMemory_DP(j * BLOCK_WIDTH);
    end loop;  -- j
  end process asgn_outputs;

  -----------------------------------------------------------------------------
  -- Registers
  -----------------------------------------------------------------------------
  -- Cell Memory
  seq_cell_memory : process (Clk_CI)
  begin  -- process seq_cell_memory
    if (rising_edge(Clk_CI)) then       -- rising clock edge
      if Reset_RI = '1' then
        CellMemory_DP <= (others => '0');
      elsif Enable_SI = '1' then
        CellMemory_DP <= CellMemory_DN;
      end if;
    end if;
  end process seq_cell_memory;


end behavioral;
