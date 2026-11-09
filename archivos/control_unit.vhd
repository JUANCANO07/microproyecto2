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
end entity control_unit;architecture rtl of control_unit is

    type estado_t is (S0, S1, S2, S3);
    signal estado_actual    : estado_t := S0;
    signal estado_siguiente : estado_t;
    signal rom_addr_r  
    signal ram_addr_r  
    signal last_addr_r 
    signal contador    : integer range 0 to 126;
begin

    lleno <= '1' when contador = MEM_DEPTH else '0';

    p_registro_estados : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                estado_actual <= S0;
            else
                estado_actual <= estado_siguiente;
            end if;
        end if;

 
