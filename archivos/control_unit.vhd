library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pkg_system.all;
 
entity control_unit is
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;                       
        pir_pulse : in  std_logic;
        rom_addr  : out tipo_direccion;
        ram_addr  : out tipo_direccion;                  
        last_addr : out tipo_direccion;                  
        ram_we    : out std_logic;
        rec_count : out std_logic_vector(ADDR_WIDTH downto 0); 
        full      : out std_logic;
        estado_o  : out std_logic_vector(1 downto 0)    
    );
end entity control_unit;