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
-- Title      : Temporal Encoder
-- Project    : Semester Thesis I
-------------------------------------------------------------------------------
-- File       : temporal_encoder_ent_arc.vhd
-- Author     : Manuel Schmuck <schmucma@student.ethz.ch>
-- Company    : Integrated Systems Laboratory, ETH Zurich
-- Created    : 2017-09-30
-- Last update: 2018-06-15
-- Platform   : ModelSim (simulation), Vivado (synthesis)
-------------------------------------------------------------------------------
-- Description: Entity and architecture of the spatial encoder.
-------------------------------------------------------------------------------
-- Copyright (c) 2017 Integrated Systems Laboratory, ETH Zurich
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author    Description
-- 2018        1.0      schmucma  Created
-------------------------------------------------------------------------------
-- Abbreviations:
-- *N : Only if NGRAM > 1
-- *B : Only if Bundle Counter is used
-- *S : Only if Similarity Counter is used
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.hdc_pkg.all;

-------------------------------------------------------------------------------

architecture bc of temporal_encoder is

  -----------------------------------------------------------------------------
  -- Constants
  -----------------------------------------------------------------------------
  constant FILL_NGRAM_COUNTER_WIDTH : integer := num2bits(NGRAM_SIZE);

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------
  -- Input Buffers
  signal ModeIn_SP, ModeIn_SN   : std_logic;
  signal LabelIn_DP, LabelIn_DN : std_logic_vector(LABEL_WIDTH-1 downto 0);

  -- Data Registers
  -- - Array starts at 1 to illustrate the latency (t-1, t-2, etc...)
  signal NGram_DP, NGram_DN : hypervector_array(1 to NGRAM_SIZE-1)(0 to HV_DIMENSION-1);  -- *N

  -- Control Registers
  type fsm_states is (idle, forward_training, accept_input, forward_query);
  signal FSM_SP, FSM_SN                         : fsm_states;
  signal FillNGramCntr_SP, FillNGramCntr_SN     : unsigned(FILL_NGRAM_COUNTER_WIDTH-1 downto 0);  -- *N
  signal NGramFullMemory_SP, NGramFullMemory_SN : std_logic;  -- *N

  -- Datapath Signals
  signal BindNGramOut_D : hypervector(0 to HV_DIMENSION-1);

  -- Status Signals
  signal ModeChange_S       : std_logic;
  signal LabelChange_S      : std_logic;
  signal NGramFull_S        : std_logic;  -- *N
  signal BundleCounterFed_S : std_logic;  -- *N

  -- Control Signals
  signal InputBuffersEN_S    : std_logic;
  signal NGramEN_S           : std_logic;  -- *N
  signal BundleCounterEN_S   : std_logic;
  signal FirstHypervector_S  : std_logic;
  signal FillNGramCntrEN_S   : std_logic;  -- *N
  signal FillNGramCntrCLR_S  : std_logic;  -- *N
  signal NGramFullMemoryEN_S : std_logic;  -- *N

  -----------------------------------------------------------------------------
  -- Components
  -----------------------------------------------------------------------------
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
  ModeIn_SN  <= ModeIn_SI;
  LabelIn_DN <= LabelIn_DI;

  -----------------------------------------------------------------------------
  -- NGram
  -----------------------------------------------------------------------------
  -- NGram Permutation
  gen_asgn_ngram_1 : if NGRAM_SIZE > 1 generate
    NGram_DN(1) <= HypervectorIn_DI ror 1;
    gen_asgn_ngram_2 : for i in 2 to NGRAM_SIZE-1 generate
      NGram_DN(i) <= NGram_DP(i-1) ror 1;
    end generate gen_asgn_ngram_2;
  end generate gen_asgn_ngram_1;

  -- NGram Binding
  gen_comb_bind_ngram : if NGRAM_SIZE > 1 generate
    comb_bind_ngram : process (HypervectorIn_DI, NGram_DP) is
      variable result : hypervector(0 to HV_DIMENSION-1) := (others => '0');
    begin  -- process comb_bind_ngram
      result := HypervectorIn_DI;
      for i in 1 to NGRAM_SIZE-1 loop
        result := result xor NGram_DP(i);
      end loop;  -- i
      BindNGramOut_D <= result;
    end process comb_bind_ngram;
  else generate
    BindNGramOut_D <= HypervectorIn_DI;
  end generate gen_comb_bind_ngram;

  -- NGram Bundling
  i_bundle_counter_1 : bundle_counter
    generic map (
      WIDTH => BUNDLE_NGRAMS_WIDTH)
    port map (
      Clk_CI              => Clk_CI,
      Reset_RI            => Reset_RI,
      Enable_SI           => BundleCounterEN_S,
      FirstHypervector_SI => FirstHypervector_S,
      HypervectorIn_DI    => BindNGramOut_D,
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
  -- Label Comparison
  ModeChange_S  <= '1' when ModeIn_SI /= ModeIn_SP   else '0';
  LabelChange_S <= '1' when LabelIn_DI /= LabelIn_DP else '0';

  -- NGram Filling Counter
  gen_ngram_filling_cntr : if NGRAM_SIZE > 1 generate
    NGramFull_S      <= nor(FillNGramCntr_SP);
    FillNGramCntr_SN <= FillNGramCntr_SP - 1;
  end generate gen_ngram_filling_cntr;

  -- Full NGram Memory
  gen_full_ngram_memory : if (NGRAM_SIZE > 1) generate
    BundleCounterFed_S <= '0' when NGramFull_S = '1' and NGramFullMemory_SP = '0' else '1';
    NGramFullMemory_SN <= NGramFull_S;
  end generate gen_full_ngram_memory;

  -----------------------------------------------------------------------------
  -- Finite State Machine
  -----------------------------------------------------------------------------
  -- We need two different implementations of the controller:
  -- - One for the case NGram: N = 1
  -- - One for the case N > 1

  gen_comb_fsm : if NGRAM_SIZE = 1 generate
    comb_fsm : process (FSM_SP, LabelChange_S, ModeChange_S, ModeIn_SI,
                        ReadyIn_SI, ValidIn_SI) is
    begin  -- process comb_fsm
      -- Default Assignments
      FSM_SN <= idle;

      ReadyOut_SO <= '0';
      ValidOut_SO <= '0';

      InputBuffersEN_S   <= '0';
      BundleCounterEN_S  <= '0';
      FirstHypervector_S <= '0';

      -- Trainsitions and Output
      case FSM_SP is
        when idle =>
          if ValidIn_SI = '0' then
            FSM_SN      <= idle;
            ReadyOut_SO <= '1';
          else
            if ModeIn_SI = mode_train then
              FSM_SN <= idle;
              if ModeChange_S = '0' then
                if LabelChange_S = '0' then
                  ReadyOut_SO       <= '1';
                  InputBuffersEN_S  <= '1';
                  BundleCounterEN_S <= '1';
                else
                  ValidOut_SO <= '1';
                  if ReadyIn_SI = '1' then
                    ReadyOut_SO        <= '1';
                    InputBuffersEN_S   <= '1';
                    BundleCounterEN_S  <= '1';
                    FirstHypervector_S <= '1';
                  end if;
                end if;
              else
                ReadyOut_SO        <= '1';
                InputBuffersEN_S   <= '1';
                BundleCounterEN_S  <= '1';
                FirstHypervector_S <= '1';
              end if;
            else
              if ModeChange_S = '0' then
                FSM_SN             <= forward_query;
                ReadyOut_SO        <= '1';
                InputBuffersEN_S   <= '1';
                BundleCounterEN_S  <= '1';
                FirstHypervector_S <= '1';
              else
                ValidOut_SO <= '1';
                if ReadyIn_SI = '0' then
                  FSM_SN <= idle;
                else
                  FSM_SN             <= forward_query;
                  ReadyOut_SO        <= '1';
                  InputBuffersEN_S   <= '1';
                  BundleCounterEN_S  <= '1';
                  FirstHypervector_S <= '1';
                end if;
              end if;
            end if;
          end if;

        when forward_query =>
          FSM_SN      <= forward_query when ReadyIn_SI = '0' else idle;
          ValidOut_SO <= '1';

        when others =>
          null;
      end case;
    end process comb_fsm;
  ---------------------------------------------------------------------------
  else generate
    comb_fsm : process (BundleCounterFed_S, FSM_SP, LabelChange_S,
                        ModeChange_S, ModeIn_SI, NGramFull_S, ReadyIn_SI,
                        ValidIn_SI) is
    begin  -- process comb_fsm
      -- Default Assignments
      FSM_SN <= idle;

      ReadyOut_SO <= '0';
      ValidOut_SO <= '0';

      InputBuffersEN_S    <= '0';
      NGramEN_S           <= '0';
      BundleCounterEN_S   <= '0';
      FirstHypervector_S  <= '0';
      FillNGramCntrEN_S   <= '0';
      FillNGramCntrCLR_S  <= '0';
      NGramFullMemoryEN_S <= '0';

      -- Trainsitions and Output
      case FSM_SP is
        when idle =>
          if ValidIn_SI = '0' then
            FSM_SN      <= idle;
            ReadyOut_SO <= '1';
          else
            if ModeIn_SI = mode_train then
              if ModeChange_S = '0' then
                if LabelChange_S = '0' then
                  FSM_SN              <= idle;
                  ReadyOut_SO         <= '1';
                  InputBuffersEN_S    <= '1';
                  NGramEN_S           <= '1';
                  NGramFullMemoryEN_S <= '1';
                  if NGramFull_S = '0' then
                    FillNGramCntrEN_S <= '1';
                  else
                    BundleCounterEN_S  <= '1';
                    FirstHypervector_S <= '1' when BundleCounterFed_S = '0' else '0';
                  end if;
                else
                  FSM_SN             <= forward_training when ReadyIn_SI = '0' else accept_input;
                  ValidOut_SO        <= '1';
                  FillNGramCntrCLR_S <= '1';
                end if;
              else
                FSM_SN              <= idle;
                ReadyOut_SO         <= '1';
                InputBuffersEN_S    <= '1';
                NGramEN_S           <= '1';
                FillNGramCntrEN_S   <= '1';
                NGramFullMemoryEN_S <= '1';
              end if;
            else
              if ModeChange_S = '0' then
                FSM_SN             <= forward_query;
                ReadyOut_SO        <= '1';
                InputBuffersEN_S   <= '1';
                NGramEN_S          <= '1';
                BundleCounterEN_S  <= '1';
                FirstHypervector_S <= '1';
              else
                FSM_SN      <= idle when ReadyIn_SI = '0' else forward_query;
                ValidOut_SO <= '1';
                if ReadyIn_SI = '1' then
                  ReadyOut_SO        <= '1';
                  InputBuffersEN_S   <= '1';
                  NGramEN_S          <= '1';
                  BundleCounterEN_S  <= '1';
                  FirstHypervector_S <= '1';
                  FillNGramCntrCLR_S <= '1';
                end if;
              end if;
            end if;
          end if;

        when forward_training =>
          FSM_SN      <= forward_training when ReadyIn_SI = '0' else idle;
          ValidOut_SO <= '1';
          if ReadyIn_SI = '1' then
            ReadyOut_SO         <= '1';
            InputBuffersEN_S    <= '1';
            NGramEN_S           <= '1';
            FillNGramCntrEN_S   <= '1';
            NGramFullMemoryEN_S <= '1';
          end if;

        when accept_input =>
          FSM_SN              <= idle;
          ReadyOut_SO         <= '1';
          InputBuffersEN_S    <= '1';
          NGramEN_S           <= '1';
          FillNGramCntrEN_S   <= '1';
          NGramFullMemoryEN_S <= '1';

        when forward_query =>
          FSM_SN      <= forward_query when ReadyIn_SI = '0' else idle;
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
  -- Input Buffers
  seq_input_buffers : process (Clk_CI)
  begin  -- process seq_InputBuffers
    if (rising_edge(Clk_CI)) then       -- rising clock edge
      if Reset_RI = '1' then
        ModeIn_SP  <= mode_predict;
        LabelIn_DP <= (others => '0');
      elsif InputBuffersEN_S = '1' then
        ModeIn_SP  <= ModeIn_SN;
        LabelIn_DP <= LabelIn_DN;
      end if;
    end if;
  end process seq_input_buffers;

  -----------------------------------------------------------------------------
  -- Data Registers
  -----------------------------------------------------------------------------
  -- NGram
  gen_seq_ngram : if NGRAM_SIZE > 1 generate
    seq_ngram : process (Clk_CI)
    begin  -- process seq_ngram
      if (rising_edge(Clk_CI)) then     -- rising clock edge
        if Reset_RI = '1' then
          NGram_DP <= (others => (others => '0'));
        elsif NGramEN_S = '1' then
          NGram_DP <= NGram_DN;
        end if;
      end if;
    end process seq_ngram;
  end generate gen_seq_ngram;

  -----------------------------------------------------------------------------
  -- Control Registers
  -----------------------------------------------------------------------------
  -- Fill NGram Counter
  gen_seq_fill_ngram_cntr : if NGRAM_SIZE > 1 generate
    seq_fill_ngram_cntr : process (Clk_CI)
    begin  -- process seq_fill_ngram_cntr
      if (rising_edge(Clk_CI)) then     -- rising clock edge
        if (Reset_RI or FillNGramCntrCLR_S) = '1' then
          FillNGramCntr_SP <= to_unsigned(NGRAM_SIZE-1, FILL_NGRAM_COUNTER_WIDTH);  -- TODO: make sure this is the correct number to load
        elsif FillNGramCntrEN_S = '1' then
          FillNGramCntr_SP <= FillNGramCntr_SN;
        end if;
      end if;
    end process seq_fill_ngram_cntr;
  end generate gen_seq_fill_ngram_cntr;

  -- NGram Full Memory

  gen_seq_ngram_full_memory : if (NGRAM_SIZE > 1) generate
    seq_ngram_full_memory : process (Clk_CI)
    begin  -- process seq_ngram_full_memory
      if (rising_edge(Clk_CI)) then     -- rising clock edge
        if Reset_RI = '1' then
          NGramFullMemory_SP <= '0';
        elsif NGramFullMemoryEN_S = '1' then
          NGramFullMemory_SP <= NGramFullMemory_SN;
        end if;
      end if;
    end process seq_ngram_full_memory;
  end generate gen_seq_ngram_full_memory;

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


end bc;
