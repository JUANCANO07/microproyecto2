library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
package pkg_system is

    constant DATA_WIDTH : natural := 8; -- Define el ancho de los datos utilizados en el sistema.
    constant ADDR_WIDTH : natural := 4; -- Define el ancho de las direcciones de memoria.
    constant MEM_DEPTH  : natural := 2 ** ADDR_WIDTH; -- Calcula la cantidad de posiciones disponibles en memoria.   
    constant CLK_FREQ   : natural := 50_000_000; -- Define la frecuencia del reloj del sistema en Hz.
    constant FILTER_CYCLES_HW : positive := CLK_FREQ / 100; -- Establece los ciclos necesarios para filtrar la señal PIR, equivalentes a 10 ms.	 
	 
    subtype tipo_dato      is std_logic_vector(DATA_WIDTH - 1 downto 0); -- Define un tipo de dato de 8 bits.
    subtype tipo_direccion is std_logic_vector(ADDR_WIDTH - 1 downto 0); -- Define un tipo de dirección de 4 bits.
    type    tipo_memoria   is array (0 to MEM_DEPTH - 1) of tipo_dato; -- Define un arreglo de memoria con 16 posiciones de 8 bits.

    function hex_to_7seg (nibble : std_logic_vector(3 downto 0))
        return std_logic_vector;-- Declara una función que convierte un valor hexadecimal en su representación para un display de 7 segmentos.
 
end package pkg_system;

package body pkg_system is
 
    function hex_to_7seg (nibble : std_logic_vector(3 downto 0))
        return std_logic_vector is
        variable seg : std_logic_vector(6 downto 0); -- Almacena los 7 bits correspondientes a los segmentos del display.
    begin
        case nibble is                      
            when "0000" => seg := "1000000"; -- Representa el número hexadecimal 0. 
            when "0001" => seg := "1111001"; -- Representa el número hexadecimal 1.
            when "0010" => seg := "0100100"; -- Representa el número hexadecimal 2.
            when "0011" => seg := "0110000"; -- Representa el número hexadecimal 3.
            when "0100" => seg := "0011001"; -- Representa el número hexadecimal 4.
            when "0101" => seg := "0010010"; -- Representa el número hexadecimal 5.
            when "0110" => seg := "0000010"; -- Representa el número hexadecimal 6.
            when "0111" => seg := "1111000"; -- Representa el número hexadecimal 7.
            when "1000" => seg := "0000000"; -- Representa el número hexadecimal 8.
            when "1001" => seg := "0010000"; -- Representa el número hexadecimal 9.
            when "1010" => seg := "0001000"; -- Representa la letra A.
            when "1011" => seg := "0000011"; -- Representa la letra B.
            when "1100" => seg := "1000110"; -- Representa la letra C.
            when "1101" => seg := "0100001"; -- Representa la letra D.
            when "1110" => seg := "0000110"; -- Representa la letra E.
            when "1111" => seg := "0001110"; -- Representa la letra F.
            when others => seg := "1111111"; -- Apaga todos los segmentos para valores no contemplados.
        end case;
        return seg; -- Devuelve la combinación de bits correspondiente al display.
    end function hex_to_7seg;
 
end package body pkg_system;


