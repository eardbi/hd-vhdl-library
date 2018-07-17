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
-- Title      : Associative Memory
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

architecture bs of associative_memory is

  -----------------------------------------------------------------------------
  -- Constants
  -----------------------------------------------------------------------------
  constant SHIFT_CNTR_WIDTH : integer := num2bits(HV_DIMENSION+1);

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------
  -- Output Buffers
  signal LabelOut_DP, LabelOut_DN       : std_logic_vector(LABEL_WIDTH-1 downto 0);
  signal DistanceOut_DP, DistanceOut_DN : std_logic_vector(DISTANCE_WIDTH-1 downto 0);

  -- Data Registers
  signal TrainedMemory_DP, TrainedMemory_DN       : hypervector_array(0 to CLASSES-1)(0 to HV_DIMENSION-1);
  signal QueryHypervector_DP, QueryHypervector_DN : Hypervector(0 to HV_DIMENSION-1);
  signal DistanceCntrs_DP, DistanceCntrs_DN       : unsigned_array(0 to CLASSES-1)(DISTANCE_WIDTH-1 downto 0);

  -- Control Registers
  type fsm_states is (idle, data_received, output_stable);
  signal FSM_SP, FSM_SN             : fsm_states;
  signal ShiftCntr_SP, ShiftCntr_SN : unsigned(SHIFT_CNTR_WIDTH-1 downto 0);

  -- Datapath Signals
  signal SimilarityOut_D         : std_logic_vector(0 to CLASSES-1);
  signal ComparatorLabelOut_D    : unsigned(LABEL_WIDTH-1 downto 0);
  signal ComparatorDistanceOut_D : unsigned(DISTANCE_WIDTH-1 downto 0);

  -- Datapath Self-Control Signals
  signal DistanceCntrsSEN_S : std_logic_vector(0 to CLASSES-1);

  -- Status Signals
  signal ShiftComplete_S : std_logic;
  signal IdentifyLabel_S : std_logic_vector(0 to CLASSES-1);

  -- Control Signals
  signal OutputBuffersEN_S    : std_logic;
  signal TrainedMemoryEN_S    : std_logic_vector(0 to CLASSES-1);
  signal QueryHypervectorEN_S : std_logic;
  signal ShiftCntrEN_S        : std_logic;
  signal ShiftCntrCLR_S       : std_logic;
  signal DistanceCntrsEN_S    : std_logic;
  signal DistanceCntrsCLR_S   : std_logic;
  signal RotateMemories_S     : std_logic;


  -----------------------------------------------------------------------------
  -- Components
  -----------------------------------------------------------------------------

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
    TrainedMemory_DN(i) <= HypervectorIn_DI when RotateMemories_S = '0' else
                           TrainedMemory_DP(i) rol 1;
  end generate gen_asgn_trained_memory1;

  -- Query Hypervector Memory
  QueryHypervector_DN <= HypervectorIn_DI when RotateMemories_S = '0' else
                         QueryHypervector_DP rol 1;

  -----------------------------------------------------------------------------
  -- Distance Calculation
  -----------------------------------------------------------------------------
  -- Similarity
  gen_similarity : for i in 0 to CLASSES-1 generate
    SimilarityOut_D(i) <= TrainedMemory_DP(i)(TrainedMemory_DP(i)'low) xor
                          QueryHypervector_DP(QueryHypervector_DP'low);
  end generate gen_similarity;

  -- Counters
  gen_counters : for i in 0 to CLASSES-1 generate
    DistanceCntrs_DN(i)   <= DistanceCntrs_DP(i) + 1;
    DistanceCntrsSEN_S(i) <= SimilarityOut_D(i);
  end generate gen_counters;

  -----------------------------------------------------------------------------
  -- Comparison
  -----------------------------------------------------------------------------
  -- Comparators
  comb_comparators : process (DistanceCntrs_DP)
    variable min_temp   : integer := 0;
    variable label_temp : integer := 0;
  begin  -- process comb_comparators
    min_temp   := to_integer(DistanceCntrs_DP(0));
    label_temp := 0;
    for i in 1 to CLASSES-1 loop
      if to_integer(DistanceCntrs_DP(i)) < min_temp then
        min_temp   := to_integer(DistanceCntrs_DP(i));
        label_temp := i;
      end if;
    end loop;  -- i
    ComparatorLabelOut_D    <= to_unsigned(label_temp, LABEL_WIDTH);
    ComparatorDistanceOut_D <= to_unsigned(min_temp, DISTANCE_WIDTH);
  end process comb_comparators;

  LabelOut_DN    <= std_logic_vector(ComparatorLabelOut_D);
  DistanceOut_DN <= std_logic_vector(ComparatorDistanceOut_D);

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

  -- Shift Counter Comparison
  ShiftComplete_S <= nor(ShiftCntr_SP);

  -- Shift Counter
  ShiftCntr_SN <= ShiftCntr_SP - 1;

  -----------------------------------------------------------------------------
  -- Finite State Machine
  -----------------------------------------------------------------------------
  comb_fsm : process (FSM_SP, IdentifyLabel_S, ModeIn_SI, ReadyIn_SI,
                      ShiftComplete_S, ValidIn_SI) is
  begin  -- process comb_fsm
    -- Default Assignments
    FSM_SN <= idle;

    ReadyOut_SO <= '0';
    ValidOut_SO <= '0';

    OutputBuffersEN_S    <= '0';
    TrainedMemoryEN_S    <= (others => '0');
    QueryHypervectorEN_S <= '0';
    DistanceCntrsEN_S    <= '0';
    DistanceCntrsCLR_S   <= '0';
    ShiftCntrEN_S        <= '0';
    ShiftCntrCLR_S       <= '0';
    RotateMemories_S     <= '0';

    -- Trainsitions and Output
    case FSM_SP is
      when idle =>
        ReadyOut_SO <= '1';
        if ValidIn_SI = '0' then
          FSM_SN <= idle;
        else
          if ModeIn_SI = mode_predict then
            FSM_SN               <= data_received;
            QueryHypervectorEN_S <= '1';
          else
            FSM_SN            <= idle;
            TrainedMemoryEN_S <= IdentifyLabel_S;
          end if;
        end if;
      when data_received =>
        if ShiftComplete_S = '0' then
          FSM_SN               <= data_received;
          TrainedMemoryEN_S    <= (others => '1');
          QueryHypervectorEN_S <= '1';
          DistanceCntrsEN_S    <= '1';
          ShiftCntrEN_S        <= '1';
          RotateMemories_S     <= '1';
        else
          FSM_SN             <= output_stable;
          OutputBuffersEN_S  <= '1';
          DistanceCntrsCLR_S <= '1';
          ShiftCntrCLR_S     <= '1';
        end if;
      when output_stable =>
        FSM_SN      <= idle when ReadyIn_SI = '1' else output_stable;
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

  -- Distance Counters
  gen_seq_distance_counters : for i in 0 to CLASSES-1 generate
    seq_distance_counters : process (Clk_CI)
    begin  -- process seq_distance_counters
      if (rising_edge(Clk_CI)) then     -- rising clock edge
        if (Reset_RI or DistanceCntrsCLR_S) = '1' then
          DistanceCntrs_DP(i) <= (others => '0');
        elsif (DistanceCntrsEN_S and DistanceCntrsSEN_S(i)) = '1' then
          DistanceCntrs_DP(i) <= DistanceCntrs_DN(i);
        end if;
      end if;
    end process seq_distance_counters;
  end generate gen_seq_distance_counters;

  -----------------------------------------------------------------------------
  -- Control Registers
  -----------------------------------------------------------------------------
  -- Shift Counter
  seq_shift_cntr : process (Clk_CI)
  begin  -- process seq_shift_cntr
    if (rising_edge(Clk_CI)) then       -- rising clock edge
      if (Reset_RI or ShiftCntrCLR_S) = '1' then
        ShiftCntr_SP <= to_unsigned(HV_DIMENSION, SHIFT_CNTR_WIDTH);  -- TODO: make sure this is the correct number to load
      elsif ShiftCntrEN_S = '1' then
        ShiftCntr_SP <= ShiftCntr_SN;
      end if;
    end if;
  end process seq_shift_cntr;

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

end bs;
