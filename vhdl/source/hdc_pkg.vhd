------------------------------------------------------------------------------
-- Title      : Hyperdimensional Computing Package
-- Project    : Semester Thesis I
-------------------------------------------------------------------------------
-- File       : hdc_pkg.vhd
-- Author     : Manuel Schmuck <schmucma@student.ethz.ch>
-- Company    : Integrated Systems Laboratory, ETH Zurich
-- Created    : 2017-09-30
-- Last update: 2018-01-02
-- Platform   : ModelSim (simulation), Vivado (synthesis)
-------------------------------------------------------------------------------
-- Description: Provides parameters and constants required for hyperdimensional
--              computing classifiers.
-------------------------------------------------------------------------------
-- Copyright (c) 2018 Integrated Systems Laboratory, ETH Zurich
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author    Description
-- 2018        1.0      schmucma  Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-------------------------------------------------------------------------------

package hdc_pkg is

  -----------------------------------------------------------------------------
  -- Data Type Declarations
  -----------------------------------------------------------------------------
  type std_logic_vector_array is array (integer range <>) of std_logic_vector;
  type unsigned_array is array (integer range <>) of unsigned;
  type signed_array is array (integer range <>) of signed;

  subtype hypervector is std_logic_vector;
  subtype hypervector_arith is unsigned;
  subtype hypervector_array is std_logic_vector_array;
  subtype hypervector_array_arith is unsigned_array;

  -----------------------------------------------------------------------------
  -- Function Declarations
  -----------------------------------------------------------------------------
  function num2bits (number        : integer) return integer;
  function logic_to_integer (logic : std_logic) return integer;

  -----------------------------------------------------------------------------
  -- Constant Declarations
  -----------------------------------------------------------------------------
  -- Parameters
  constant HV_DIMENSION          : integer := 1024;
  constant INPUT_CHANNELS        : integer := 4;
  constant INPUT_QUANTIZATION    : integer := 21;
  constant NGRAM_SIZE            : integer := 3;
  constant CLASSES               : integer := 5;
  constant BUNDLE_CHANNELS_WIDTH : integer := 3;
  constant BUNDLE_NGRAMS_WIDTH   : integer := 5;
  constant MAX_BUNDLE_CYCLES     : integer := 32;
  constant AM_BLOCK_WIDTH        : integer := 64;
  constant NGRAM_BUNDLER_MODE    : string  := "similarity";

  -- Deferred Parameters
  constant LABEL_WIDTH    : integer;
  constant CHANNEL_WIDTH  : integer;
  constant DISTANCE_WIDTH : integer;
  constant NGRAM_WIDTH    : integer;
  constant AM_BLOCKS      : integer;

  -- Aliases
  constant mode_train      : std_logic := '0';
  constant mode_predict    : std_logic := '1';
  constant mode_store      : std_logic := '0';
  constant mode_shift      : std_logic := '1';
  constant mode_similarity : string    := "similarity";
  constant mode_counter    : string    := "counter";

end hdc_pkg;

-------------------------------------------------------------------------------

package body hdc_pkg is

  -----------------------------------------------------------------------------
  -- Function Definitions
  -----------------------------------------------------------------------------
  function num2bits (number : integer) return integer is
  begin
    if number <= 1 then
      return 0;
    else
      return integer(ceil(log2(real(number))));
    end if;
  end num2bits;

  function logic_to_integer (logic : std_logic) return integer is
  begin
    if logic = '1' then
      return 1;
    else
      return 0;
    end if;
  end logic_to_integer;

  -----------------------------------------------------------------------------
  -- Deferred Constants
  -----------------------------------------------------------------------------
  constant LABEL_WIDTH    : integer := num2bits(CLASSES);
  constant CHANNEL_WIDTH  : integer := num2bits(INPUT_QUANTIZATION);
  constant DISTANCE_WIDTH : integer := num2bits(HV_DIMENSION);
  constant NGRAM_WIDTH    : integer := num2bits(NGRAM_SIZE);
  constant AM_BLOCKS      : integer := HV_DIMENSION / AM_BLOCK_WIDTH;


end hdc_pkg;
