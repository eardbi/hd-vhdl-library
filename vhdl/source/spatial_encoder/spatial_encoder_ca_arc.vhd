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
-- Title      : Spatial Encoder
-- Project    : Semester Thesis I
-------------------------------------------------------------------------------
-- File       : spatial_encoder_ent_arc.vhd
-- Author     : Manuel Schmuck <schmucma@student.ethz.ch>
-- Company    : Integrated Systems Laboratory, ETH Zurich
-- Created    : 2017-09-30
-- Last update: 2018-06-15
-- Platform   : ModelSim (simulation), Vivado (synthesis)
-------------------------------------------------------------------------------
-- Description: Entity and architecture of the spatial encode.
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

architecture ca of spatial_encoder is

  -----------------------------------------------------------------------------
  -- Constants
  -----------------------------------------------------------------------------
  constant CYCLE_CNTR_WIDTH    : integer := num2bits(INPUT_CHANNELS);
  constant INPUT_CHANNELS_EVEN : boolean := (INPUT_CHANNELS mod 2) = 0;

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------
  -- Input Buffers
  signal ModeIn_SP, ModeIn_SN         : std_logic;
  signal LabelIn_DP, LabelIn_DN       : std_logic_vector(LABEL_WIDTH-1 downto 0);
  signal ChannelsIn_DP, ChannelsIn_DN : std_logic_vector_array(0 to INPUT_CHANNELS-1)(CHANNEL_WIDTH-1 downto 0);

  -- Data Registers
  signal AdditionalFeature_DP, AdditionalFeature_DN : hypervector(0 to HV_DIMENSION-1);

  -- Control Registers
  type fsm_states is (idle, data_received, bundle_cntr_fed, channels_mapped, feature_added);
  signal FSM_SP, FSM_SN             : fsm_states;
  signal CycleCntr_SP, CycleCntr_SN : unsigned(CYCLE_CNTR_WIDTH-1 downto 0);

  -- Datapath Signals
  signal SelectedChannel_D  : std_logic_vector(CHANNEL_WIDTH-1 downto 0);
  signal ChannelNHot_D      : std_logic_vector(0 to INPUT_QUANTIZATION-2);
  signal CIMOut_D           : hypervector(0 to HV_DIMENSION-1);
  signal IMOut_D            : hypervector(0 to HV_DIMENSION-1);
  signal BindChannelOut_D   : hypervector(0 to HV_DIMENSION-1);
  signal SelectFeatureOut_D : hypervector(0 to HV_DIMENSION-1);

  -- Status Signals
  signal LastChannel_S : std_logic;

  -- Control Signals
  signal InputBuffersEN_S       : std_logic;
  signal BundleCntrEN_S         : std_logic;
  signal CellularAutomatonEN_S  : std_logic;
  signal CellularAutomatonCLR_S : std_logic;
  signal AdditionalFeatureEN_S  : std_logic;
  signal AdditionalFeatureCLR_S : std_logic;
  signal CycleCntrEN_S          : std_logic;
  signal CycleCntrCLR_S         : std_logic;

  signal FirstHypervector_S        : std_logic;
  signal SelectAdditionalFeature_S : std_logic;


  -----------------------------------------------------------------------------
  -- Components
  -----------------------------------------------------------------------------
  component cellular_automaton is
    generic (
      WIDTH                   : integer;
      RULE                    : integer;
      CELLULAR_AUTOMATON_SEED : std_logic_vector(0 to WIDTH-1));
    port (
      Clk_CI          : in  std_logic;
      Reset_RI        : in  std_logic;
      Enable_SI       : in  std_logic;
      Clear_SI        : in  std_logic;
      CellValueOut_DO : out std_logic_vector(0 to WIDTH-1));
  end component cellular_automaton;

  component bundle_counter is
    generic (
      WIDTH : integer);
    port (
      Clk_CI              : in  std_logic;
      Reset_RI            : in  std_logic;
      Enable_SI           : in  std_logic;
      FirstHypervector_SI : in  std_logic;
      HypervectorIn_DI    : in  hypervector(0 to HV_DIMENSION-1);
      HypervectorOut_DO   : out hypervector(0 to HV_DIMENSION-1));
  end component bundle_counter;

begin
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- DATAPATH
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- Input Signals
  -----------------------------------------------------------------------------
  ModeIn_SN     <= ModeIn_SI;
  LabelIn_DN    <= LabelIn_DI;
  ChannelsIn_DN <= ChannelsIn_DI;

  -----------------------------------------------------------------------------
  -- Channel Mapping
  -----------------------------------------------------------------------------
  SelectedChannel_D <= ChannelsIn_DP(to_integer(CycleCntr_SP));

  -- N-Hot LUT
  ChannelNHot_D <= NHOT_LUT(to_integer(unsigned(SelectedChannel_D)));

  -- CIM
  comb_cim : process (ChannelNHot_D)
  begin  -- process comb_cim
    for i in 0 to CIMOut_D'high loop
      CIMOut_D(i) <= CIM_SEED(i);
      for j in 0 to ChannelNHot_D'high loop
        if CIM_CONNECTIVITY_MATRIX(j)(i) = '1' then
          CIMOut_D(i) <= CIM_SEED(i) xor ChannelNHot_D(j);
        end if;
      end loop;  -- j
    end loop;  -- i
  end process comb_cim;

  -----------------------------------------------------------------------------
  -- Channel Binding
  -----------------------------------------------------------------------------
  -- Cellular Automaton
  i_cellular_automaton_1 : cellular_automaton
    generic map (
      WIDTH                   => HV_DIMENSION,
      RULE                    => 30,
      CELLULAR_AUTOMATON_SEED => IM_SEED)
    port map (
      Clk_CI          => Clk_CI,
      Reset_RI        => Reset_RI,
      Enable_SI       => CellularAutomatonEN_S,
      Clear_SI        => CellularAutomatonCLR_S,
      CellValueOut_DO => IMOut_D);

  BindChannelOut_D <= IMOut_D xor CIMOut_D;

  -----------------------------------------------------------------------------
  -- Channel Bundling
  -----------------------------------------------------------------------------
  gen_additional_feature : if INPUT_CHANNELS_EVEN generate
    AdditionalFeature_DN <= BindChannelOut_D xor AdditionalFeature_DP;
    SelectFeatureOut_D   <= AdditionalFeature_DP when SelectAdditionalFeature_S = '1' else
                          BindChannelOut_D;
  else generate
    SelectFeatureOut_D <= BindChannelOut_D;
  end generate gen_additional_feature;


  -- Bundling Counter
  i_bundle_counter_1 : bundle_counter
    generic map (
      WIDTH => BUNDLE_CHANNELS_WIDTH)
    port map (
      Clk_CI              => Clk_CI,
      Reset_RI            => Reset_RI,
      Enable_SI           => BundleCntrEN_S,
      FirstHypervector_SI => FirstHypervector_S,
      HypervectorIn_DI    => SelectFeatureOut_D,
      HypervectorOut_DO   => HypervectorOut_DO);

  -----------------------------------------------------------------------------
  -- Output Signals
  -----------------------------------------------------------------------------
  ModeOut_SO  <= ModeIn_SP;
  LabelOut_DO <= LabelIn_DP;

  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- CONTROLLER
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- Controller Support Circuits
  -----------------------------------------------------------------------------
  -- Cycle Counter
  CycleCntr_SN  <= CycleCntr_SP+1;
  LastChannel_S <= '1' when to_integer(CycleCntr_SP) = INPUT_CHANNELS-1 else '0';

  -----------------------------------------------------------------------------
  -- Finite State Machine
  -----------------------------------------------------------------------------
  -- There have to be two different implementations of the controller:
  -- - One for the case that we have an even number of channels
  -- - Another one for the case that we have an odd number of channels
  gen_comb_fsm : if INPUT_CHANNELS_EVEN generate
    comb_fsm : process (FSM_SP, LastChannel_S, ReadyIn_SI, ValidIn_SI) is
    begin  -- process comb_fsm
      -- Default Assignments
      FSM_SN <= idle;

      ReadyOut_SO <= '0';
      ValidOut_SO <= '0';

      InputBuffersEN_S       <= '0';
      BundleCntrEN_S         <= '0';
      CellularAutomatonEN_S  <= '0';
      CellularAutomatonCLR_S <= '0';
      AdditionalFeatureEN_S  <= '0';
      AdditionalFeatureCLR_S <= '0';
      CycleCntrEN_S          <= '0';
      CycleCntrCLR_S         <= '0';

      FirstHypervector_S        <= '0';
      SelectAdditionalFeature_S <= '0';

      -- Trainsitions and Output
      case FSM_SP is
        when idle =>
          FSM_SN           <= data_received when ValidIn_SI = '1' else idle;
          ReadyOut_SO      <= '1';
          InputBuffersEN_S <= '1'           when ValidIn_SI = '1' else '0';
        when data_received =>
          FSM_SN                <= bundle_cntr_fed;
          BundleCntrEN_S        <= '1';
          CellularAutomatonEN_S <= '1';
          AdditionalFeatureEN_S <= '1';
          CycleCntrEN_S         <= '1';
          FirstHypervector_S    <= '1';
        when bundle_cntr_fed =>
          FSM_SN                <= channels_mapped when LastChannel_S = '1' else bundle_cntr_fed;
          BundleCntrEN_S        <= '1';
          CellularAutomatonEN_S <= '1';
          AdditionalFeatureEN_S <= '1'             when LastChannel_S = '1' else '0';  -- erase "when ..." if additional feature should combine all channels
          CycleCntrEN_S         <= '1';
        when channels_mapped =>
          FSM_SN                    <= feature_added;
          BundleCntrEN_S            <= '1';
          CellularAutomatonCLR_S    <= '1';
          AdditionalFeatureCLR_S    <= '1';
          CycleCntrCLR_S            <= '1';
          SelectAdditionalFeature_S <= '1';
        when feature_added =>
          FSM_SN      <= idle when ReadyIn_SI = '1' else feature_added;
          ValidOut_SO <= '1';
      end case;

    end process comb_fsm;
  -----------------------------------------------------------------------------
  else generate
    comb_fsm : process (FSM_SP, LastChannel_S, ReadyIn_SI, ValidIn_SI) is
    begin  -- process comb_fsm
      -- Default Assignments
      FSM_SN <= idle;

      ReadyOut_SO <= '0';
      ValidOut_SO <= '0';

      InputBuffersEN_S       <= '0';
      BundleCntrEN_S         <= '0';
      CellularAutomatonEN_S  <= '0';
      CellularAutomatonCLR_S <= '0';
      CycleCntrEN_S          <= '0';
      CycleCntrCLR_S         <= '0';

      FirstHypervector_S <= '0';

      -- Trainsitions and Output
      case FSM_SP is
        when idle =>
          FSM_SN           <= data_received when ValidIn_SI = '1' else idle;
          ReadyOut_SO      <= '1';
          InputBuffersEN_S <= '1'           when ValidIn_SI = '1' else '0';
        when data_received =>
          FSM_SN                <= bundle_cntr_fed;
          BundleCntrEN_S        <= '1';
          CellularAutomatonEN_S <= '1';
          CycleCntrEN_S         <= '1';
          FirstHypervector_S    <= '1';
        when bundle_cntr_fed =>
          FSM_SN         <= channels_mapped when LastChannel_S = '1' else bundle_cntr_fed;
          BundleCntrEN_S <= '1';
          if LastChannel_S = '0' then
            CellularAutomatonEN_S <= '1';
            CycleCntrEN_S         <= '1';
          else
            CellularAutomatonCLR_S <= '1';
            CycleCntrCLR_S         <= '1';
          end if;
        when channels_mapped =>
          FSM_SN      <= idle when ReadyIn_SI = '1' else channels_mapped;
          ValidOut_SO <= '1';
        when others =>
          null;
      end case;

    end process comb_fsm;
  end generate gen_comb_fsm;

  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- MEMORIES
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- Input Buffers
  -----------------------------------------------------------------------------
  seq_input_buffers : process (Clk_CI)
  begin  -- process seq_InputBuffers
    if (rising_edge(Clk_CI)) then       -- rising clock edge
      if Reset_RI = '1' then
        ModeIn_SP     <= '0';
        LabelIn_DP    <= (others => '0');
        ChannelsIn_DP <= (others => (others => '0'));
      elsif InputBuffersEN_S = '1' then
        ModeIn_SP     <= ModeIn_SN;
        LabelIn_DP    <= LabelIn_DN;
        ChannelsIn_DP <= ChannelsIn_DN;
      end if;
    end if;
  end process seq_input_buffers;

  -----------------------------------------------------------------------------
  -- Data Registers
  -----------------------------------------------------------------------------
  -- Additional Feature
  gen_seq_additional_feature : if INPUT_CHANNELS_EVEN generate
    seq_additional_feature : process (Clk_CI)
    begin  -- process seq_additional_feature
      if (rising_edge(Clk_CI)) then     -- rising clock edge
        if (Reset_RI or AdditionalFeatureCLR_S) = '1' then
          AdditionalFeature_DP <= (others => '0');
        elsif AdditionalFeatureEN_S = '1' then
          AdditionalFeature_DP <= AdditionalFeature_DN;
        end if;
      end if;
    end process seq_additional_feature;
  end generate gen_seq_additional_feature;

  -----------------------------------------------------------------------------
  -- Control Registers
  -----------------------------------------------------------------------------
  -- Cycle Counter
  seq_cycle_counter : process (Clk_CI)
  begin  -- process seq_cycle_counter
    if (rising_edge(Clk_CI)) then       -- rising clock edge
      if (Reset_RI or CycleCntrCLR_S) = '1' then
        CycleCntr_SP <= (others => '0');
      elsif CycleCntrEN_S = '1' then
        CycleCntr_SP <= CycleCntr_SN;
      end if;
    end if;
  end process seq_cycle_counter;

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

end ca;
