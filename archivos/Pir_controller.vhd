library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pkg_system.all;
 
entity pir_controller is
	generic (
        FILTER_CYCLES : positive := FILTER_CYCLES_HW
    );

    port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        pir_in    : in  std_logic;
        pir_pulse : out std_logic
    );
end entity pir_controller;
 
architecture rtl of pir_controller is
 
    signal sync_1, sync_2 : std_logic := '0';
    signal filtrada       : std_logic := '0';
    signal anterior       : std_logic := '0';
    signal pulso          : std_logic := '0';
	 signal cont_filtro    : integer range 0 to FILTER_CYCLES - 1 := 0;

	
begin

    p_sincronizacion : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                sync_1 <= '0';
                sync_2 <= '0';
            else
                sync_1 <= pir_in;
                sync_2 <= sync_1;
            end if;
        end if;
    end process p_sincronizacion;
	     p_filtrado : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                cont_filtro <= 0;
                filtrada    <= '0';
            else
                if sync_2 = filtrada then
                    cont_filtro <= 0;
                else
                    if cont_filtro = FILTER_CYCLES - 1 then
                        filtrada    <= sync_2;
                        cont_filtro <= 0;
                    else
                        cont_filtro <= cont_filtro + 1;
                    end if;
                end if;
            end if;
        end if;
    end process p_filtrado;
	     p_deteccion_flanco : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                anterior <= '0';
                pulso    <= '0';
            else
                pulso <= '0';
                if filtrada = '1' and anterior = '0' then
                    pulso <= '1';
                end if;
                anterior <= filtrada;
            end if;
        end if;
    end process p_deteccion_flanco;
 
    pir_pulse <= pulso;
 
end architecture rtl;