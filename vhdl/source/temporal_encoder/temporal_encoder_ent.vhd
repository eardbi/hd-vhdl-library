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

entity temporal_encoder is
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
    ModeIn_SI        : in std_logic;
    LabelIn_DI       : in std_logic_vector(LABEL_WIDTH-1 downto 0);
    HypervectorIn_DI : in hypervector(0 to HV_DIMENSION-1);

    -- Output Ports
    ModeOut_SO        : out std_logic;
    LabelOut_DO       : out std_logic_vector(LABEL_WIDTH-1 downto 0);
    HypervectorOut_DO : out hypervector(0 to HV_DIMENSION-1)
    );
end temporal_encoder;
