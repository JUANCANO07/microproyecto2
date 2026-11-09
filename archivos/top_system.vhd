
-- Top-Level: Integracion de controlador PIR, Unidad de Control (FSM) y memorias.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pkg_system.all;

entity top_system is
    generic (
        FILTER_CYCLES : positive := FILTER_CYCLES_HW
    );
    port (
        CLOCK_50 : in  std_logic;
        KEY0     : in  std_logic;                       -- Reset (activo en bajo)
        PIR_IN   : in  std_logic;
        SW       : in  std_logic_vector(4 downto 0);
        HEX0     : out std_logic_vector(6 downto 0);
        HEX1     : out std_logic_vector(6 downto 0);
        HEX2     : out std_logic_vector(6 downto 0);
        HEX3     : out std_logic_vector(6 downto 0);
        LEDG     : out std_logic_vector(3 downto 0)
    );
end entity top_system;

architecture rtl of top_system is

    -- Sincronizadores para entradas asincronas
    signal rst_meta : std_logic := '1';
    signal rst      : std_logic := '1';

    signal sw_meta : std_logic_vector(4 downto 0) := (others => '0');
    signal sw_s    : std_logic_vector(4 downto 0) := (others => '0');

    signal pir_pulse : std_logic;

    signal rom_addr  : tipo_direccion;
    signal rom_data  : tipo_dato;

    signal ram_write_addr : tipo_direccion;
    signal ram_read_addr  : tipo_direccion;     
    signal ram_addr_sel   : tipo_direccion;     -- Bus de direcciones multiplexado
    signal ram_data_out   : tipo_dato;
    signal ram_we         : std_logic;
    signal ram_rd_en      : std_logic;

    signal last_addr : tipo_direccion;
    signal rec_count : std_logic_vector(ADDR_WIDTH downto 0);
    signal lleno     : std_logic;
    signal estado    : std_logic_vector(1 downto 0);

    -- Senales de control para el pipeline de lectura de RAM
    signal lectura_pend : std_logic := '0';     
    signal vista_valida : std_logic := '0';     
    signal vista_ahora  : std_logic;
    signal dato_visualizar : tipo_dato := (others => '0');

begin

    -- Sincronizacion de reset y switches
    p_sync_entradas : process (CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            rst_meta <= not KEY0;
            rst      <= rst_meta;
            sw_meta  <= SW;
            sw_s     <= sw_meta;
        end if;
    end process p_sync_entradas;

    -- Instanciacion de modulos
    u_pir : entity work.pir_controller
        generic map (FILTER_CYCLES => FILTER_CYCLES)
        port map (
            clk       => CLOCK_50,
            rst       => rst,
            pir_in    => PIR_IN,
            pir_pulse => pir_pulse
        );

    u_fsm : entity work.control_unit
        port map (
            clk       => CLOCK_50,
            rst       => rst,
            pir_pulse => pir_pulse,
            rom_addr  => rom_addr,
            ram_addr  => ram_write_addr,
            last_addr => last_addr,
            ram_we    => ram_we,
            rec_count => rec_count,
            full      => lleno,
            estado_o  => estado
        );

    u_rom : entity work.rom_sync
        generic map (DATA_WIDTH => DATA_WIDTH, ADDR_WIDTH => ADDR_WIDTH)
        port map (
            clk      => CLOCK_50,
            addr     => rom_addr,
            data_out => rom_data
        );

    u_ram : entity work.ram_sincrona
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            ADDR_WIDTH => ADDR_WIDTH,
            RDW_MODE   => "READ_FIRST"
        )
        port map (
            clk      => CLOCK_50,
            rd_en    => ram_rd_en,
            wr_en    => ram_we,
            addr     => ram_addr_sel,
            data_in  => rom_data,
            data_out => ram_data_out
        );

    -- Multiplexor de direccionamiento de RAM
    -- Prioridad estricta al ciclo de escritura FSM)
    ram_read_addr <= sw_s(3 downto 0) when sw_s(4) = '1' else last_addr;
    ram_addr_sel  <= ram_write_addr   when ram_we = '1'  else ram_read_addr;
    ram_rd_en     <= not ram_we;

    -- Validacion de la direccion de lectura contra el contador de registros
    vista_ahora <= '1' when to_integer(unsigned(ram_read_addr)) <
                            to_integer(unsigned(rec_count)) else '0';

    -- Pipeline de visualizacion
    -- Alinea los datos capturados con la latencia de lectura de la RAM (1 ciclo)
    p_visualizacion : process (CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            if rst = '1' then
                lectura_pend    <= '0';
                vista_valida    <= '0';
                dato_visualizar <= (others => '0');
            else
                lectura_pend <= ram_rd_en;
                vista_valida <= vista_ahora;
                
                if lectura_pend = '1' then
                    if vista_valida = '1' then
                        dato_visualizar <= ram_data_out;
                    else
                        dato_visualizar <= (others => '0');
                    end if;
                end if;
            end if;
        end if;
    end process p_visualizacion;

    -- Asignacion de displays 7 segmentos
    HEX0 <= hex_to_7seg(dato_visualizar(3 downto 0));
    HEX1 <= hex_to_7seg(dato_visualizar(7 downto 4));
    HEX2 <= hex_to_7seg(rec_count(3 downto 0));
    HEX3 <= hex_to_7seg("000" & rec_count(4));

    -- Indicadores LED
    LEDG(1 downto 0) <= estado;
    LEDG(2)          <= lleno;
    LEDG(3)          <= PIR_IN;

end architecture rtl;
