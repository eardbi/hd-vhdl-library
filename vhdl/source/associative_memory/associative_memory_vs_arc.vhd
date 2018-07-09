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

architecture vs of associative_memory is

  -----------------------------------------------------------------------------
  -- Constants
  -----------------------------------------------------------------------------
  constant SHIFT_CNTR_WIDTH : integer := num2bits(CLASSES+1);

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------
  -- Output Buffers
  signal LabelOut_DP, LabelOut_DN       : std_logic_vector(LABEL_WIDTH-1 downto 0);
  signal DistanceOut_DP, DistanceOut_DN : std_logic_vector(DISTANCE_WIDTH-1 downto 0);

  -- Data Registers
  signal TrainedMemory_DP, TrainedMemory_DN       : hypervector_array(0 to CLASSES-1)(0 to HV_DIMENSION-1);
  signal LabelMemory_DP, LabelMemory_DN           : std_logic_vector_array(0 to CLASSES-1)(LABEL_WIDTH-1 downto 0);
  signal QueryHypervector_DP, QueryHypervector_DN : hypervector(0 to HV_DIMENSION-1);
  signal CompDistance_DP, CompDistance_DN         : unsigned(DISTANCE_WIDTH-1 downto 0);
  signal CompLabel_DP, CompLabel_DN               : std_logic_vector(LABEL_WIDTH-1 downto 0);

  -- Control Registers
  type fsm_states is (idle, find_min_dist, output_stable);
  signal FSM_SP, FSM_SN             : fsm_states;
  signal ShiftCntr_SP, ShiftCntr_SN : unsigned(SHIFT_CNTR_WIDTH-1 downto 0);

  -- Datapath Signals
  signal SimilarityOut_D : std_logic_vector(0 to HV_DIMENSION-1);
  signal AdderOut_D      : unsigned(DISTANCE_WIDTH-1 downto 0);

  -- Datapath Self-Control Signals
  signal CompRegisterSEN_S : std_logic;

  -- Status Signals
  signal ShiftComplete_S : std_logic;

  -- Control Signals
  signal OutputBuffersEN_S    : std_logic;
  signal ShiftMemoryEN_S      : std_logic;
  signal QueryHypervectorEN_S : std_logic;
  signal CompRegisterEN_S     : std_logic;
  signal CompRegisterCLR_S    : std_logic;
  signal ShiftCntrEN_S        : std_logic;
  signal ShiftCntrCLR_S       : std_logic;
  signal RotateMemories_S     : std_logic;

begin

  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- DATAPATH
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- Input Signals
  -----------------------------------------------------------------------------
  -- Trained & Label Memory
  TrainedMemory_DN(0) <= HypervectorIn_DI when RotateMemories_S = '0' else
                         TrainedMemory_DP(TrainedMemory_DP'high);
  LabelMemory_DN(0) <= LabelIn_DI when RotateMemories_S = '0' else
                       LabelMemory_DP(LabelMemory_DP'high);

  -- Query Hypervector Memory
  QueryHypervector_DN <= HypervectorIn_DI;

  -----------------------------------------------------------------------------
  -- Trained & Label Memory Shift Register
  -----------------------------------------------------------------------------
  -- Shift Register
  gen_asgn_trained_memory : for i in 1 to CLASSES-1 generate
    TrainedMemory_DN(i) <= TrainedMemory_DP(i-1);
    LabelMemory_DN(i)   <= LabelMemory_DP(i-1);
  end generate gen_asgn_trained_memory;

  -----------------------------------------------------------------------------
  -- Distance Calculation
  -----------------------------------------------------------------------------
  -- Similarity
  SimilarityOut_D <= TrainedMemory_DP(TrainedMemory_DP'high) xor QueryHypervector_DP;

  -- Adders
  comb_adders : process (SimilarityOut_D) is
    variable sum : integer := 0;
  begin  -- process comb_adders
    sum := 0;
    for i in 0 to HV_DIMENSION-1 loop
      sum := sum + logic_to_integer(SimilarityOut_D(i));
    end loop;  -- i
    AdderOut_D <= to_unsigned(sum, DISTANCE_WIDTH);
  end process comb_adders;

  -----------------------------------------------------------------------------
  -- Comparison
  -----------------------------------------------------------------------------
  -- Comparator Registers
  CompLabel_DN    <= LabelMemory_DP(LabelMemory_DP'high);
  CompDistance_DN <= AdderOut_D;

  -- Comparison
  CompRegisterSEN_S <= CompDistance_DN ?< CompDistance_DP;

  -- Output Buffers
  LabelOut_DN    <= std_logic_vector(CompLabel_DP);
  DistanceOut_DN <= std_logic_vector(CompDistance_DP);

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
  -- Shift Counter
  ShiftCntr_SN <= ShiftCntr_SP - 1;

  -- Shift Counter Comparison
  ShiftComplete_S <= nor(ShiftCntr_SP);

  -----------------------------------------------------------------------------
  -- Finite State Machine
  -----------------------------------------------------------------------------
  comb_fsm : process (FSM_SP, ModeIn_SI, ReadyIn_SI, ShiftComplete_S,
                      ValidIn_SI) is
  begin  -- process comb_fsm
    -- Default Assignments
    FSM_SN <= idle;

    ReadyOut_SO <= '0';
    ValidOut_SO <= '0';

    OutputBuffersEN_S    <= '0';
    ShiftMemoryEN_S      <= '0';
    QueryHypervectorEN_S <= '0';
    CompRegisterEN_S     <= '0';
    CompRegisterCLR_S    <= '0';
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
          FSM_SN               <= find_min_dist when ModeIn_SI = mode_predict else idle;
          ShiftMemoryEN_S      <= '1'           when ModeIn_SI = mode_train   else '0';
          QueryHypervectorEN_S <= '1'           when ModeIn_SI = mode_predict else '0';
        end if;
      when find_min_dist =>
        if ShiftComplete_S = '0' then
          FSM_SN           <= find_min_dist;
          ShiftMemoryEN_S  <= '1';
          CompRegisterEN_S <= '1';
          ShiftCntrEN_S    <= '1';
          RotateMemories_S <= '1';
        else
          FSM_SN            <= output_stable;
          OutputBuffersEN_S <= '1';
          CompRegisterCLR_S <= '1';
          ShiftCntrCLR_S    <= '1';
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
  -- Trained & Label Memory
  seq_trained_label_memory : process (Clk_CI)
  begin  -- process seq_trained_label_memory
    if (rising_edge(Clk_CI)) then       -- rising clock edge
      if Reset_RI = '1' then
        TrainedMemory_DP <= (others => (others => '0'));
        LabelMemory_DP   <= (others => (others => '0'));
      elsif ShiftMemoryEN_S = '1' then
        TrainedMemory_DP <= TrainedMemory_DN;
        LabelMemory_DP   <= LabelMemory_DN;
      end if;
    end if;
  end process seq_trained_label_memory;

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

  -- Comparator Registers
  seq_comp_registers : process (Clk_CI)
  begin  -- process seq_comp_registers
    if (rising_edge(Clk_CI)) then       -- rising clock edge
      if (Reset_RI or CompRegisterCLR_S) = '1' then
        CompDistance_DP <= (others => '1');
        CompLabel_DP    <= (others => '0');
      elsif (CompRegisterEN_S and CompRegisterSEN_S) = '1' then
        CompDistance_DP <= CompDistance_DN;
        CompLabel_DP    <= CompLabel_DN;
      end if;
    end if;
  end process seq_comp_registers;

  -----------------------------------------------------------------------------
  -- Control Registers
  -----------------------------------------------------------------------------
  -- Shift Counter
  seq_shift_cntr : process (Clk_CI)
  begin  -- process seq_shift_cntr
    if (rising_edge(Clk_CI)) then       -- rising clock edge
      if (Reset_RI or ShiftCntrCLR_S) = '1' then
        ShiftCntr_SP <= to_unsigned(CLASSES, SHIFT_CNTR_WIDTH);
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

end vs;
