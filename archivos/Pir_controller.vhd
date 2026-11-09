library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pkg_system.all;
 
entity pir_controller is
	generic (
        FILTER_CYCLES : positive := FILTER_CYCLES_HW -- Número de ciclos utilizados para filtrar las variaciones de la señal del sensor PIR.
    );

    port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        pir_in    : in  std_logic;
        pir_pulse : out std_logic
    );
end entity pir_controller;
 
architecture rtl of pir_controller is
 
    signal sync_1, sync_2 : std_logic := '0'; -- Registros utilizados para sincronizar la señal del sensor con el reloj del sistema.
    signal filtrada       : std_logic := '0'; -- Almacena el estado de la señal PIR después del filtrado.
    signal anterior       : std_logic := '0'; -- Guarda el estado anterior de la señal filtrada para detectar cambios.
    signal pulso          : std_logic := '0'; -- Almacena el pulso generado cuando se detecta un flanco de subida.
	 signal cont_filtro    : integer range 0 to FILTER_CYCLES - 1 := 0; -- Contador encargado de determinar cuánto tiempo debe mantenerse estable la señal para ser aceptada.

	
begin

    p_sincronizacion : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                sync_1 <= '0'; -- Primera etapa de sincronización de la señal de entrada.
                sync_2 <= '0'; -- Segunda etapa de sincronización para reducir posibles problemas de metastabilidad.
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
                if sync_2 = filtrada then -- Si la señal sincronizada coincide con la filtrada, se reinicia el contador.
                    cont_filtro <= 0;
                else
                    if cont_filtro = FILTER_CYCLES - 1 then -- Comprueba si la señal ha permanecido diferente durante el tiempo establecido.
                        filtrada    <= sync_2; -- Actualiza la señal filtrada cuando se cumple el tiempo de estabilidad.
                        cont_filtro <= 0;
                    else
                        cont_filtro <= cont_filtro + 1; -- Incrementa el contador mientras espera que la señal permanezca estable.
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
                pulso <= '0'; -- Reinicia el pulso en cada ciclo de reloj para garantizar que dure un solo ciclo.
                if filtrada = '1' and anterior = '0' then -- Detecta un flanco de subida en la señal filtrada, indicando movimiento.
                    pulso <= '1';  -- Genera un pulso cuando se detecta el inicio de la señal de movimiento.
                end if;
                anterior <= filtrada; -- Actualiza el estado anterior para permitir la detección de nuevos flancos.
            end if;
        end if;
    end process p_deteccion_flanco;
 
    pir_pulse <= pulso;
 
end architecture rtl;
