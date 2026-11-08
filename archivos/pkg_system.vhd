library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
package pkg_system is

    constant DATA_WIDTH : natural := 8;
    constant ADDR_WIDTH : natural := 4;
    constant MEM_DEPTH  : natural := 2 ** ADDR_WIDTH;   
    constant CLK_FREQ   : natural := 50_000_000;
    constant FILTER_CYCLES_HW : positive := CLK_FREQ / 100;	 
	 
    subtype tipo_dato      is std_logic_vector(DATA_WIDTH - 1 downto 0);
    subtype tipo_direccion is std_logic_vector(ADDR_WIDTH - 1 downto 0);
    type    tipo_memoria   is array (0 to MEM_DEPTH - 1) of tipo_dato;

    function hex_to_7seg (nibble : std_logic_vector(3 downto 0))
        return std_logic_vector;
 
end package pkg_system;

package body pkg_system is
 
    function hex_to_7seg (nibble : std_logic_vector(3 downto 0))
        return std_logic_vector is
        variable seg : std_logic_vector(6 downto 0);
    begin
        case nibble is                      
            when "0000" => seg := "1000000"; 
            when "0001" => seg := "1111001"; 
            when "0010" => seg := "0100100"; 
            when "0011" => seg := "0110000"; 
            when "0100" => seg := "0011001"; 
            when "0101" => seg := "0010010"; 
            when "0110" => seg := "0000010"; 
            when "0111" => seg := "1111000"; 
            when "1000" => seg := "0000000"; 
            when "1001" => seg := "0010000"; 
            when "1010" => seg := "0001000"; 
            when "1011" => seg := "0000011"; 
            when "1100" => seg := "1000110"; 
            when "1101" => seg := "0100001"; 
            when "1110" => seg := "0000110"; 
            when "1111" => seg := "0001110"; 
            when others => seg := "1111111"; 
        end case;
        return seg;
    end function hex_to_7seg;
 
end package body pkg_system;


