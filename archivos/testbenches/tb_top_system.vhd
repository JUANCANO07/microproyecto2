library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pkg_system.all;

entity tb_top_system is
end entity tb_top_system;

architecture sim of tb_top_system is

    constant T_CLK    : time     := 20 ns;          -- 50 MHz
    constant N_FILTRO : positive := 4;

    signal clk  : std_logic := '0';
    signal key0 : std_logic := '0';                 -- reset presionado
    signal pir  : std_logic := '0';
    signal sw   : std_logic_vector(4 downto 0) := (others => '0');
    signal hex0, hex1, hex2, hex3 : std_logic_vector(6 downto 0);
    signal ledg : std_logic_vector(3 downto 0);
    signal fin  : boolean := false;

    type tabla_t is array (0 to 15) of natural;
    constant ROM_ESPERADA : tabla_t :=
        (16#AA#, 16#55#, 16#F0#, 16#0F#, 16#FF#, 16#00#,
         0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    function seg2int (s : std_logic_vector(7 downto 0)) return integer is
    begin
        for i in 0 to 15 loop
            if s = hex_to_7seg(std_logic_vector(to_unsigned(i, 4))) then
                return i;
            end if;
        end loop;
        return -1;
    end function seg2int;
begin

    clk_gen : process
    begin
        while not fin loop
            clk <= '0'; wait for T_CLK / 2;
            clk <= '1'; wait for T_CLK / 2;
        end loop;
        wait;
    end process clk_gen;

