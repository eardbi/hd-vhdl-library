-- Copyright 2018 ETH Zurich
-- Copyright and related rights are licensed under the Solderpad Hardware
-- License, Version 0.51 (the “License”); you may not use this file except in
-- compliance with the License.  You may obtain a copy of the License at
-- http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
-- or agreed to in writing, software, hardware and materials distributed under
-- this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
-- CONDITIONS OF ANY KIND, either express or implied. See the License for the
-- specific language governing permissions and limitations under the License.

------------------------------------------------------------------------------
-- Title      : HDC Enhanced Package
-- Project    : Semester Thesis I
-------------------------------------------------------------------------------
-- File       : hdc_enhanced_pkg.vhd
-- Author     : Manuel Schmuck <schmucma@student.ethz.ch>
-- Company    : Integrated Systems Laboratory, ETH Zurich
-- Created    : 2017-09-30
-- Last update: 2018-01-02
-- Platform   : ModelSim (simulation), Vivado (synthesis)
-------------------------------------------------------------------------------
-- Description: Provides seed vectors and connectivity matrices for the
--              enhanced architecture.
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
use ieee.math_real.all;
use work.hdc_pkg.all;

-------------------------------------------------------------------------------

package hdc_enhanced_pkg is

  -----------------------------------------------------------------------------
  -- Function Declarations
  -----------------------------------------------------------------------------
  

  -----------------------------------------------------------------------------
  -- Constant Declarations
  -----------------------------------------------------------------------------
  constant NHOT_LUT : std_logic_vector_array(0 to INPUT_QUANTIZATION-1)(0 to INPUT_QUANTIZATION-2) := (
   -- This line will be overwritten by MATLAB
    );

  constant IM_SEED : hypervector(0 to HV_DIMENSION-1) := (
   -- This line will be overwritten by MATLAB
    );

  constant CIM_SEED : hypervector(0 to HV_DIMENSION-1) := (
   -- This line will be overwritten by MATLAB
    );

  constant IM_CONNECTIVITY_MATRIX : hypervector_array(0 to INPUT_CHANNELS-1)(0 to HV_DIMENSION-1) := (
   -- This line will be overwritten by MATLAB
    );

  constant CIM_CONNECTIVITY_MATRIX : hypervector_array(0 to INPUT_QUANTIZATION-2)(0 to HV_DIMENSION-1) := (
   -- This line will be overwritten by MATLAB
    );

  constant BUNDLE_CONNECTIVITY_MATRIX : hypervector_array(0 to MAX_BUNDLE_CYCLES-1)(0 to HV_DIMENSION-1) := (
   -- This line will be overwritten by MATLAB
    );

end hdc_enhanced_pkg;

-------------------------------------------------------------------------------

package body hdc_enhanced_pkg is

  

end hdc_enhanced_pkg;
