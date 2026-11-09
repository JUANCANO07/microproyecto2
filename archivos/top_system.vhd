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
        KEY0     : in  std_logic;                       
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

    -- reset sincronizado (polaridad: KEY0 = 0 -> reset interno = 1)
    signal rst_meta : std_logic := '1';
    signal rst      : std_logic := '1';

    -- switches sincronizados
    signal sw_meta : std_logic_vector(4 downto 0) := (others => '0');
    signal sw_s    : std_logic_vector(4 downto 0) := (others => '0');

    signal pir_pulse : std_logic;

    signal rom_addr  : tipo_direccion;
    signal rom_data  : tipo_dato;

    signal ram_write_addr : tipo_direccion;
    signal ram_read_addr  : tipo_direccion;     -- direccion de visualizacion
    signal ram_addr_sel   : tipo_direccion;     -- la unica que ve la RAM
    signal ram_data_out   : tipo_dato;
    signal ram_we         : std_logic;
    signal ram_rd_en      : std_logic;

