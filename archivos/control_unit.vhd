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
    end process p_registro_estados
    p_transiciones : process (estado_actual, pir_pulse)
    begin
        estado_siguiente <= estado_actual;
        case estado_actual is
            when S0 =>
                if pir_pulse = '1' then
                    estado_siguiente <= S1;
                else
                    estado_siguiente <= S0;
                end if;
            when S1 =>
                estado_siguiente <= S2;
            when S2 =>
                estado_siguiente <= S3;
            when S3 =>
                estado_siguiente <= S0;
        end case;
    end process p_transiciones;
         
    p_salidas : process (estado_actual, lleno)
    begin
        ram_we_i <= '0';
        case estado_actual is
            when S2 =>
                if lleno = '0' then
                    ram_we_i <= '1';
                end if;
            when others =>
                0;   
        end case;
    end process p_salidas;    
    p_direcciones : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                ram_addr_r  <= (others => '0');
                ram_addr_r  <= (others => '0');
                last_addr_r <= (others => '0');
                contador    <= 0;
    rom_addr  <= rom_addr_r;
    ram_addr  <= ram_addr_r;
    last_addr <= last_addr_r;
    ram_we    <= ram_we_i;
    full      <= lleno;
    rec_count <= std_logic_vector(unsigned(contador, ADDR_WIDTH + 1));

    with estado_actual select
        estado_o <= "00" when S0,
                    "01" when S1,
                    "10" when S2,
                    "11" when S3;

end architecture rtl;

 
