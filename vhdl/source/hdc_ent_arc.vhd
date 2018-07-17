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
-- Title      : Hyperdimensional Computing Classifier Entity
-- Project    : Semester Thesis I
-------------------------------------------------------------------------------
-- File       : hdc_ent.vhd
-- Author     : Manuel Schmuck <schmucma@student.ethz.ch>
-- Company    : Integrated Systems Laboratory, ETH Zurich
-- Created    : 2017-09-30
-- Last update: 2018-06-15
-- Platform   : ModelSim (simulation), Vivado (synthesis)
-------------------------------------------------------------------------------
-- Description: Top level entity of the HDC classifier.
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

entity hdc is
  port (
    -- Global Ports
    Clk_CI   : in std_logic;
    Reset_RI : in std_logic;

    -- Handshake Ports
    ValidIn_SI  : in  std_logic;
    ReadyOut_SO : out std_logic;
    ReadyIn_SI  : in  std_logic;
    ValidOut_SO : out std_logic;

    -- Input Ports
    ModeIn_SI     : in std_logic;
    LabelIn_DI    : in std_logic_vector(LABEL_WIDTH-1 downto 0);
    ChannelsIn_DI : in std_logic_vector_array(0 to INPUT_CHANNELS-1)(CHANNEL_WIDTH-1 downto 0);

    -- Output Ports
    LabelOut_DO    : out std_logic_vector(LABEL_WIDTH-1 downto 0);
    DistanceOut_DO : out std_logic_vector(DISTANCE_WIDTH-1 downto 0)
    );
end hdc;

-------------------------------------------------------------------------------

architecture top of hdc is

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------
  -- Spatial Encoder
  signal ModeOutS_S        : std_logic;
  signal LabelOutS_D       : std_logic_vector(LABEL_WIDTH-1 downto 0);
  signal HypervectorOutS_D : hypervector(0 to HV_DIMENSION-1);

  -- Handshake
  signal ValidST_S : std_logic;
  signal ReadyST_S : std_logic;

  -- Temporal Encoder
  signal ModeOutT_S        : std_logic;
  signal LabelOutT_D       : std_logic_vector(LABEL_WIDTH-1 downto 0);
  signal HypervectorOutT_D : hypervector(0 to HV_DIMENSION-1);

  -- Handshake
  signal ValidTA_S : std_logic;
  signal ReadyTA_S : std_logic;

  -----------------------------------------------------------------------------
  -- Components
  -----------------------------------------------------------------------------
  -- Spatial Encoder
  component spatial_encoder
    port (
      Clk_CI            : in  std_logic;
      Reset_RI          : in  std_logic;
      ValidIn_SI        : in  std_logic;
      ReadyOut_SO       : out std_logic;
      ReadyIn_SI        : in  std_logic;
      ValidOut_SO       : out std_logic;
      ModeIn_SI         : in  std_logic;
      LabelIn_DI        : in  std_logic_vector(LABEL_WIDTH-1 downto 0);
      ChannelsIn_DI     : in  std_logic_vector_array(0 to INPUT_CHANNELS-1)(CHANNEL_WIDTH-1 downto 0);
      ModeOut_SO        : out std_logic;
      LabelOut_DO       : out std_logic_vector(LABEL_WIDTH-1 downto 0);
      HypervectorOut_DO : out hypervector(0 to HV_DIMENSION-1));
  end component;

  for all : spatial_encoder use entity
  work.spatial_encoder(lut);
  -- work.spatial_encoder(ca);
  -- work.spatial_encoder(man);

  -- Temporal Encoder
  component temporal_encoder
    port (
      Clk_CI            : in  std_logic;
      Reset_RI          : in  std_logic;
      ValidIn_SI        : in  std_logic;
      ReadyOut_SO       : out std_logic;
      ReadyIn_SI        : in  std_logic;
      ValidOut_SO       : out std_logic;
      ModeIn_SI         : in  std_logic;
      LabelIn_DI        : in  std_logic_vector(LABEL_WIDTH-1 downto 0);
      HypervectorIn_DI  : in  hypervector(0 to HV_DIMENSION-1);
      ModeOut_SO        : out std_logic;
      LabelOut_DO       : out std_logic_vector(LABEL_WIDTH-1 downto 0);
      HypervectorOut_DO : out hypervector(0 to HV_DIMENSION-1));
  end component;

  for all : temporal_encoder use entity
  work.temporal_encoder(b2b);
  -- work.temporal_encoder(bc);

  -- Associative Memory
  component associative_memory
    port (
      Clk_CI           : in  std_logic;
      Reset_RI         : in  std_logic;
      ValidIn_SI       : in  std_logic;
      ReadyOut_SO      : out std_logic;
      ReadyIn_SI       : in  std_logic;
      ValidOut_SO      : out std_logic;
      ModeIn_SI        : in  std_logic;
      LabelIn_DI       : in  std_logic_vector(LABEL_WIDTH-1 downto 0);
      HypervectorIn_DI : in  hypervector(0 to HV_DIMENSION-1);
      LabelOut_DO      : out std_logic_vector(LABEL_WIDTH-1 downto 0);
      DistanceOut_DO   : out std_logic_vector(DISTANCE_WIDTH-1 downto 0));
  end component;

  for all : associative_memory use entity
  work.associative_memory(cmb);
  -- work.associative_memory(vs);
  -- work.associative_memory(bs);

begin  -- top

  -----------------------------------------------------------------------------
  -- Instantiations
  -----------------------------------------------------------------------------
  -- Spatial Encoder
  i_spatial_encoder_1 : spatial_encoder
    port map (
      Clk_CI            => Clk_CI,
      Reset_RI          => Reset_RI,
      ValidIn_SI        => ValidIn_SI,
      ReadyOut_SO       => ReadyOut_SO,
      ReadyIn_SI        => ReadyST_S,
      ValidOut_SO       => ValidST_S,
      ModeIn_SI         => ModeIn_SI,
      LabelIn_DI        => LabelIn_DI,
      ChannelsIn_DI     => ChannelsIn_DI,
      ModeOut_SO        => ModeOutS_S,
      LabelOut_DO       => LabelOutS_D,
      HypervectorOut_DO => HypervectorOutS_D);

  -- Temporal Encoder
  i_temporal_encoder_1 : temporal_encoder
    port map (
      Clk_CI            => Clk_CI,
      Reset_RI          => Reset_RI,
      ValidIn_SI        => ValidST_S,
      ReadyOut_SO       => ReadyST_S,
      ReadyIn_SI        => ReadyTA_S,
      ValidOut_SO       => ValidTA_S,
      ModeIn_SI         => ModeOutS_S,
      LabelIn_DI        => LabelOutS_D,
      HypervectorIn_DI  => HypervectorOutS_D,
      ModeOut_SO        => ModeOutT_S,
      LabelOut_DO       => LabelOutT_D,
      HypervectorOut_DO => HypervectorOutT_D);

  -- Associative memory
  i_associative_memory_1 : associative_memory
    port map (
      Clk_CI           => Clk_CI,
      Reset_RI         => Reset_RI,
      ValidIn_SI       => ValidTA_S,
      ReadyOut_SO      => ReadyTA_S,
      ReadyIn_SI       => ReadyIn_SI,
      ValidOut_SO      => ValidOut_SO,
      ModeIn_SI        => ModeOutT_S,
      LabelIn_DI       => LabelOutT_D,
      HypervectorIn_DI => HypervectorOutT_D,
      LabelOut_DO      => LabelOut_DO,
      DistanceOut_DO   => DistanceOut_DO);

end top;
