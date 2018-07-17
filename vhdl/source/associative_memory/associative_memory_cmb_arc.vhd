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
-- Title      : Associative Memory Optimised
-- Project    : Semester Thesis I
-------------------------------------------------------------------------------
-- File       : associative_memory_ent_arc.vhd
-- Author     : Manuel Schmuck <schmucma@student.ethz.ch>
-- Company    : Integrated Systems Laboratory, ETH Zurich
-- Created    : 2017-09-30
-- Last update: 2018-06-15
-- Platform   : ModelSim (simulation), Vivado (synthesis)
-------------------------------------------------------------------------------
-- Description: Entity and architecture of the associative memory
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

architecture cmb of associative_memory is

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------
  -- Output Buffers
  signal LabelOut_DP, LabelOut_DN       : std_logic_vector(LABEL_WIDTH-1 downto 0);
  signal DistanceOut_DP, DistanceOut_DN : std_logic_vector(DISTANCE_WIDTH-1 downto 0);

  -- Data Registers
  signal TrainedMemory_DP, TrainedMemory_DN       : hypervector_array(0 to CLASSES-1)(0 to HV_DIMENSION-1);
  signal QueryHypervector_DP, QueryHypervector_DN : Hypervector(0 to HV_DIMENSION-1);

  -- Control Registers
  type fsm_states is (idle, distance_calculated, output_stable);
  signal FSM_SP, FSM_SN : fsm_states;

  -- Datapath Signals
  signal SimilarityOut_D : std_logic_vector_array(0 to CLASSES-1)(0 to HV_DIMENSION-1);
  signal AdderOut_D      : unsigned_array(0 to CLASSES-1)(DISTANCE_WIDTH-1 downto 0);

  -- Datapath Self-Control Signals

  -- Status Signals
  signal IdentifyLabel_S : std_logic_vector(0 to CLASSES-1);

  -- Control Signals
  signal OutputBuffersEN_S    : std_logic;
  signal TrainedMemoryEN_S    : std_logic_vector(0 to CLASSES-1);
  signal QueryHypervectorEN_S : std_logic;

begin

  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- DATAPATH
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- Input Signals
  -----------------------------------------------------------------------------
  -- Trained Hypervector Memory
  gen_asgn_trained_memory1 : for i in 0 to CLASSES-1 generate
    TrainedMemory_DN(i) <= HypervectorIn_DI;
  end generate gen_asgn_trained_memory1;

  -- Query Hypervector Memory
  QueryHypervector_DN <= HypervectorIn_DI;

  -----------------------------------------------------------------------------
  -- Distance Calculation
  -----------------------------------------------------------------------------
  -- Similarity
  gen_similarity : for i in 0 to CLASSES-1 generate
    SimilarityOut_D(i) <= TrainedMemory_DP(i) xor QueryHypervector_DP;
  end generate gen_similarity;

  -- Adders
  gen_adders : for i in 0 to CLASSES-1 generate
    comb_adders : process (SimilarityOut_D)
      variable sum : integer := 0;
    begin  -- process comb_adders
      sum := 0;
      for j in 0 to HV_DIMENSION-1 loop
        sum := sum + logic_to_integer(SimilarityOut_D(i)(j));
      end loop;  -- j
      AdderOut_D(i) <= to_unsigned(sum, DISTANCE_WIDTH);
    end process comb_adders;
  end generate gen_adders;

  -----------------------------------------------------------------------------
  -- Comparison
  -----------------------------------------------------------------------------
  comb_comparators : process (AdderOut_D)
    variable min_temp   : integer;
    variable label_temp : integer;
  begin  -- process comb_comparators
    min_temp   := to_integer(AdderOut_D(0));
    label_temp := 0;
    for i in 1 to CLASSES-1 loop
      if to_integer(AdderOut_D(i)) < min_temp then
        min_temp   := to_integer(AdderOut_D(i));
        label_temp := i;
      end if;
    end loop;  -- i
    LabelOut_DN    <= std_logic_vector(to_unsigned(label_temp, LABEL_WIDTH));
    DistanceOut_DN <= std_logic_vector(to_unsigned(min_temp, DISTANCE_WIDTH));
  end process comb_comparators;

  -----------------------------------------------------------------------------
  -- Output Signals
  -----------------------------------------------------------------------------
  LabelOut_DO    <= LabelOut_DP;
  DistanceOut_DO <= DistanceOut_DP;

  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- CONTROLLER
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- Controller Support Circuits
  -----------------------------------------------------------------------------
  -- Label Identification
  gen_label_identification : for i in 0 to CLASSES-1 generate
    IdentifyLabel_S(i) <= '1' when LabelIn_DI = std_logic_vector(to_unsigned(i, LABEL_WIDTH))
                          else '0';
  end generate gen_label_identification;

  -----------------------------------------------------------------------------
  -- Finite State Machine
  -----------------------------------------------------------------------------
  -- TODO: controller logic
  comb_fsm : process (FSM_SP, IdentifyLabel_S, ModeIn_SI, ReadyIn_SI,
                      ValidIn_SI) is
  begin  -- process comb_fsm
    -- Default Assignments
    FSM_SN <= idle;

    ReadyOut_SO <= '0';
    ValidOut_SO <= '0';

    OutputBuffersEN_S    <= '0';
    TrainedMemoryEN_S    <= (others => '0');
    QueryHypervectorEN_S <= '0';

    -- Trainsitions and Output
    case FSM_SP is
      when idle =>
        ReadyOut_SO <= '1';
        if ValidIn_SI = '0' then
          FSM_SN <= idle;
        else
          if ModeIn_SI = mode_train then
            FSM_SN            <= idle;
            TrainedMemoryEN_S <= IdentifyLabel_S;
          else
            FSM_SN               <= distance_calculated;
            QueryHypervectorEN_S <= '1';
          end if;
        end if;
      when distance_calculated =>
        FSM_SN            <= output_stable;
        OutputBuffersEN_S <= '1';
      when output_stable =>
        FSM_SN      <= output_stable when ReadyIn_SI = '0' else idle;
        ValidOut_SO <= '1';
    end case;

  end process comb_fsm;

  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- MEMORIES
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- Output Buffers
  -----------------------------------------------------------------------------
  seq_output_buffers : process (Clk_CI)
  begin  -- process seq_OutputBuffers
    if (rising_edge(Clk_CI)) then       -- rising clock edge
      if Reset_RI = '1' then
        LabelOut_DP    <= (others => '0');
        DistanceOut_DP <= (others => '0');
      elsif OutputBuffersEN_S = '1' then
        LabelOut_DP    <= LabelOut_DN;
        DistanceOut_DP <= DistanceOut_DN;
      end if;
    end if;
  end process seq_output_buffers;

  -----------------------------------------------------------------------------
  -- Data Registers
  -----------------------------------------------------------------------------
  -- Trained Memory
  gen_seq_trained_memory : for i in 0 to CLASSES-1 generate
    seq_trained_memory : process (Clk_CI)
    begin  -- process seq_trained_memory
      if (rising_edge(Clk_CI)) then     -- rising clock edge
        if Reset_RI = '1' then
          TrainedMemory_DP(i) <= (others => '0');
        elsif TrainedMemoryEN_S(i) = '1' then
          TrainedMemory_DP(i) <= TrainedMemory_DN(i);
        end if;
      end if;
    end process seq_trained_memory;
  end generate gen_seq_trained_memory;

  -- Query Hypervector
  seq_query_hypervector : process (Clk_CI)
  begin  -- process seq_query_hypervector
    if (rising_edge(Clk_CI)) then       -- rising clock edge
      if Reset_RI = '1' then
        QueryHypervector_DP <= (others => '0');
      elsif QueryHypervectorEN_S = '1' then
        QueryHypervector_DP <= QueryHypervector_DN;
      end if;
    end if;
  end process seq_query_hypervector;

  -----------------------------------------------------------------------------
  -- Control Registers
  -----------------------------------------------------------------------------
  -- Finite State Machine
  seq_fsm : process (Clk_CI)
  begin  -- process seq_fsm
    if (rising_edge(Clk_CI)) then       -- rising clock edge
      if Reset_RI = '1' then
        FSM_SP <= idle;
      else
        FSM_SP <= FSM_SN;
      end if;
    end if;
  end process seq_fsm;

end cmb;
