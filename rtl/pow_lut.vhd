---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         pow_lut.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         3/2017
--
-- DESCRIPTION:  includes look-up-table for squaring data points for power calc.
--
---------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.defs.all;

package pow_lut is

constant lut_size  : integer := 2**(define_beam_bits-1);
constant lut_range : integer := lut_size * lut_size;

--type power_lut_type is array(lut_size-1 downto 0) of integer range 0 to lut_range;
type power_lut_type is array(natural range<>) of integer;

function init_lut_positive(size: integer) return power_lut_type;
function init_lut_negative(size: integer) return power_lut_type;
constant lut_power_pos :  power_lut_type(0 to lut_size-1) := init_lut_positive(lut_size);
constant lut_power_neg :  power_lut_type(lut_size to 2*lut_size-1) := init_lut_negative(lut_size);

end pow_lut;

package body pow_lut is
--//////////////////
--//define LUT for positive samples
--//////////////////
function init_lut_positive(size : integer) return power_lut_type is
	variable j : power_lut_type(0 to size-1);
begin
	for i in j'range loop
		j(i) := i*i;
	end loop;
	return j;
end function;

--//////////////////
--//define LUT for negative samples
--//////////////////
function init_lut_negative(size : integer) return power_lut_type is
	variable j : power_lut_type(size to 2*size-1);
begin
	for i in j'range loop
		j(i) := (i-lut_size)*(i-lut_size);
	end loop;
	return j;
end function;

end package body;