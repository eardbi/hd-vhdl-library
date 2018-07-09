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
use work.hdc_baseline_pkg.all;

-------------------------------------------------------------------------------

architecture lut of spatial_encoder is

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------
  -- Input Buffers
  signal ModeIn_SP, ModeIn_SN         : std_logic;
  signal LabelIn_DP, LabelIn_DN       : std_logic_vector(LABEL_WIDTH-1 downto 0);
  signal ChannelsIn_DP, ChannelsIn_DN : std_logic_vector_array(0 to INPUT_CHANNELS-1)(CHANNEL_WIDTH-1 downto 0);

  -- Data Registers
  signal BundleChannelsOut_DP, BundleChannelsOut_DN : hypervector(0 to HV_DIMENSION-1);

  -- Control Registers
  type fsm_states is (idle, data_received, channels_mapped);
  signal FSM_SP, FSM_SN : fsm_states;

  -- Datapath Signals
  signal MapChannelsOut_D   : hypervector_array(0 to INPUT_CHANNELS-1)(0 to HV_DIMENSION-1);
  signal BindChannelsOut_D  : hypervector_array(0 to INPUT_CHANNELS-1)(0 to HV_DIMENSION-1);
  signal BundleChannelsIn_D : hypervector_array(0 to INPUT_CHANNELS-(INPUT_CHANNELS mod 2))(0 to HV_DIMENSION-1);

  -- Status Signals

  -- Control Signals
  signal InputBuffersEN_S      : std_logic;
  signal BundleChannelsOutEN_S : std_logic;

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
  gen_map_cim : for i in 0 to INPUT_CHANNELS-1 generate
    MapChannelsOut_D(i) <= CONTINUOUS_ITEM_MEMORY(to_integer(unsigned(ChannelsIn_DP(i))));
  end generate gen_map_cim;

  -----------------------------------------------------------------------------
  -- Channel Binding
  -----------------------------------------------------------------------------
  gen_bind_cim_im : for i in 0 to INPUT_CHANNELS-1 generate
    BindChannelsOut_D(i) <= MapChannelsOut_D(i) xor ITEM_MEMORY(i);
  end generate gen_bind_cim_im;

  -----------------------------------------------------------------------------
  -- Channel Bundling
  -----------------------------------------------------------------------------
  -- Additional Feature
  gen_combine_channels : if (INPUT_CHANNELS mod 2) = 0 generate
    BundleChannelsIn_D(BundleChannelsIn_D'high(1)) <= BindChannelsOut_D(0) xor BindChannelsOut_D(BindChannelsOut_D'high);
  end generate gen_combine_channels;
  BundleChannelsIn_D(0 to INPUT_CHANNELS-1) <= BindChannelsOut_D;

  -- Bundling
  BundleChannelsOut_DN <= majority(BundleChannelsIn_D);

  -----------------------------------------------------------------------------
  -- Output Signals
  -----------------------------------------------------------------------------
  ModeOut_SO        <= ModeIn_SP;
  LabelOut_DO       <= LabelIn_DP;
  HypervectorOut_DO <= BundleChannelsOut_DP;

  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- CONTROLLER
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- Controller Support Circuits
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Finite State Machine
  -----------------------------------------------------------------------------
  comb_fsm : process (FSM_SP, ReadyIn_SI, ValidIn_SI) is
  begin  -- process comb_fsm
    -- Default Assignments
    FSM_SN <= idle;

    ReadyOut_SO <= '0';
    ValidOut_SO <= '0';

    InputBuffersEN_S      <= '0';
    BundleChannelsOutEN_S <= '0';

    -- Trainsitions and Output
    case FSM_SP is
      when idle =>
        FSM_SN           <= idle when ValidIn_SI = '0' else data_received;
        ReadyOut_SO      <= '1';
        InputBuffersEN_S <= '1'  when ValidIn_SI = '1' else '0';
      when data_received =>
        FSM_SN                <= channels_mapped;
        BundleChannelsOutEN_S <= '1';
      when channels_mapped =>
        FSM_SN      <= channels_mapped when ReadyIn_SI = '0' else idle;
        ValidOut_SO <= '1';
    end case;

  end process comb_fsm;

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
  -- Bundled Channels Register
  seq_bundle_channels : process (Clk_CI)
  begin  -- process seq_bundle_channels
    if (rising_edge(Clk_CI)) then       -- rising clock edge
      if Reset_RI = '1' then
        BundleChannelsOut_DP <= (others => '0');
      elsif BundleChannelsOutEN_S = '1' then
        BundleChannelsOut_DP <= BundleChannelsOut_DN;
      end if;
    end if;
  end process seq_bundle_channels;

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

end lut;
