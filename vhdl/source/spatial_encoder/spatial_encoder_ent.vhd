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

entity spatial_encoder is
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
    ModeOut_SO        : out std_logic;
    LabelOut_DO       : out std_logic_vector(LABEL_WIDTH-1 downto 0);
    HypervectorOut_DO : out hypervector(0 to HV_DIMENSION-1)
    );
end spatial_encoder;
