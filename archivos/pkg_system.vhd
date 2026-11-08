library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
package pkg_system is

    constant DATA_WIDTH : natural := 8;
    constant ADDR_WIDTH : natural := 4;
    constant MEM_DEPTH  : natural := 2 ** ADDR_WIDTH;   
    constant CLK_FREQ   : natural := 50_000_000;
	 
    subtype tipo_dato      is std_logic_vector(DATA_WIDTH - 1 downto 0);
    subtype tipo_direccion is std_logic_vector(ADDR_WIDTH - 1 downto 0);
    type    tipo_memoria   is array (0 to MEM_DEPTH - 1) of tipo_dato;

    function hex_to_7seg (nibble : std_logic_vector(3 downto 0))
        return std_logic_vector;
 
end package pkg_system;