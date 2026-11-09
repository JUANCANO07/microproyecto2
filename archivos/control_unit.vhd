library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pkg_system.all;

entity control_unit is
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        pir_pulse : in  std_logic;

