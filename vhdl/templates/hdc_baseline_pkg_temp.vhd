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
-- Title      : HDC Baseline Package
-- Project    : Semester Thesis I
-------------------------------------------------------------------------------
-- File       : hdc_baseline_pkg.vhd
-- Author     : Manuel Schmuck <schmucma@student.ethz.ch>
-- Company    : Integrated Systems Laboratory, ETH Zurich
-- Created    : 2017-09-30
-- Last update: 2018-01-02
-- Platform   : ModelSim (simulation), Vivado (synthesis)
-------------------------------------------------------------------------------
-- Description: Provides the memories and functions required by the
--              baseline architecture.
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

package hdc_baseline_pkg is

  -----------------------------------------------------------------------------
  -- Function Declarations
  -----------------------------------------------------------------------------
  function majority (hvarray : hypervector_array) return hypervector;

  -----------------------------------------------------------------------------
  -- Constant Declarations
  -----------------------------------------------------------------------------
  constant ITEM_MEMORY : hypervector_array(0 to INPUT_CHANNELS-1)(0 to HV_DIMENSION-1) := (
   -- This line will be overwritten by MATLAB
    );

  constant CONTINUOUS_ITEM_MEMORY : hypervector_array(0 to INPUT_QUANTIZATION-1)(0 to HV_DIMENSION-1) := (
   -- This line will be overwritten by MATLAB
    );

end hdc_baseline_pkg;

-------------------------------------------------------------------------------

package body hdc_baseline_pkg is

  -----------------------------------------------------------------------------
  -- Function Definitions
  -----------------------------------------------------------------------------

  function majority (hvarray : hypervector_array) return hypervector is
    variable sum    : integer                          := 0;
    variable result : hypervector(0 to HV_DIMENSION-1) := (others => '0');
  begin
    sum := 0;
    for i in 0 to HV_DIMENSION-1 loop
      sum := logic_to_integer(hvarray(0)(i));
      for j in 1 to hvarray'high loop
        if hvarray(j)(i) = '1' then
          sum := sum + 1;
        else
          sum := sum - 1;
        end if;
      end loop;  -- j
      if sum > 0 then
        result(i) := '1';
      else
        result(i) := '0';
      end if;
    end loop;  -- i
    return result;
  end majority;

end hdc_baseline_pkg;
