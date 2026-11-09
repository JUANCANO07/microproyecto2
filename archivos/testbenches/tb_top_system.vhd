
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pkg_system.all;

entity tb_top_system is
end entity tb_top_system;

architecture sim of tb_top_system is

    constant T_CLK    : time     := 20 ns;          -- Reloj 50 MHz
    constant N_FILTRO : positive := 4;

    signal clk  : std_logic := '0';
    signal key0 : std_logic := '0';                 -- Reset activo en bajo
    signal pir  : std_logic := '0';
    signal sw   : std_logic_vector(4 downto 0) := (others => '0');
    signal hex0, hex1, hex2, hex3 : std_logic_vector(6 downto 0);
    signal ledg : std_logic_vector(3 downto 0);
    signal fin  : boolean := false;

    type tabla_t is array (0 to 15) of natural;
    
    -- Patrón esperado de ROM para validación de datos
    constant ROM_ESPERADA : tabla_t :=
        (16#AA#, 16#55#, 16#F0#, 16#0F#, 16#FF#, 16#00#,
         0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

    -- Función auxiliar: Decodificador inverso 7 segmentos -> Integer
    function seg2int (s : std_logic_vector(6 downto 0)) return integer is
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

    uut : entity work.top_system
        generic map (FILTER_CYCLES => N_FILTRO)
        port map (
            CLOCK_50 => clk, KEY0 => key0, PIR_IN => pir, SW => sw,
            HEX0 => hex0, HEX1 => hex1, HEX2 => hex2, HEX3 => hex3,
            LEDG => ledg
        );

    estimulos : process

        variable errores : natural := 0;
        variable v       : integer;

        impure function estado return integer is
        begin
            return to_integer(unsigned(ledg(1 downto 0)));
        end function;

        impure function cuenta return integer is
        begin
            return 16 * seg2int(hex3) + seg2int(hex2);
        end function;

        impure function dato_vis return integer is
        begin
            return 16 * seg2int(hex1) + seg2int(hex0);
        end function;

        procedure ciclos (n : natural) is
        begin
            for i in 1 to n loop
                wait until falling_edge(clk);
            end loop;
        end procedure;

        procedure chequear (cond : boolean; msg : string) is
        begin
            if cond then
                report "OK    : " & msg severity note;
            else
                errores := errores + 1;
                report "FALLO : " & msg severity error;
            end if;
        end procedure;
        procedure esperar_estado (destino : integer; maxc : natural) is
            variable k : natural := 0;
        begin
            while estado /= destino and k < maxc loop
                wait until falling_edge(clk);
                k := k + 1;
            end loop;
            chequear(estado = destino,
                     "FSM alcanza estado S" & integer'image(destino));
        end procedure;
        procedure detectar (cnt_esp : integer; dato_esp : integer) is
        begin
            pir <= '1';
            esperar_estado(1, 40);
            ciclos(1); chequear(estado = 2, "Transicion S1 -> S2");
            ciclos(1); chequear(estado = 3, "Transicion S2 -> S3");
            ciclos(1); chequear(estado = 0, "Transicion S3 -> S0");
            ciclos(6);
            chequear(cuenta = cnt_esp,
                     "Contador de registros = " & integer'image(cnt_esp));
            chequear(dato_vis = dato_esp,
                     "Ultimo dato escrito = " & integer'image(dato_esp));
        end procedure;

        procedure soltar_pir is
        begin
            pir <= '0';
            ciclos(20);        
        end procedure;




