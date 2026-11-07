library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pkg_system.all;
 
entity pir_controller is

    port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        pir_in    : in  std_logic;
        pir_pulse : out std_logic
    );
end entity pir_controller;
 
architecture rtl of pir_controller is
 
    signal sync_1, sync_2 : std_logic := '0';
    signal filtrada       : std_logic := '0';
    signal anterior       : std_logic := '0';
    signal pulso          : std_logic := '0';