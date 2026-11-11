library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pkg_system.all;

entity tb_top_system is
end entity tb_top_system;

architecture sim of tb_top_system is

    constant T_CLK    : time     := 20 ns; -- Establece el periodo de la señal de reloj.         
    constant N_FILTRO : positive := 4; -- Define los ciclos necesarios para validar una señal del sensor PIR.

    signal clk  : std_logic := '0';
    signal key0 : std_logic := '0';  -- Señal utilizada para reiniciar el sistema.            
    signal pir  : std_logic := '1';  -- Entrada del sensor PIR, inicialmente en estado alto.              
    signal hex0, hex1, hex2, hex3 : std_logic_vector(6 downto 0); -- Salidas que controlan los cuatro displays de 7 segmentos.
    signal ledg : std_logic_vector(2 downto 0); -- Salidas de los LED indicadores del sistema.
    signal fin  : boolean := false; -- Controla la finalización del generador de reloj.

    type tabla_t is array (0 to 15) of natural; -- Define una tabla con 16 posiciones para almacenar valores esperados.
    constant ROM_ESPERADA : tabla_t :=
        (16#AA#, 16#55#, 16#F0#, 16#0F#, 16#FF#, 16#00#,
         0, 0, 0, 0, 0, 0, 0, 0, 0, 0);  -- Datos que se utilizarán para comprobar las lecturas de la memoria ROM.

    function seg2int (s : std_logic_vector(6 downto 0)) return integer is
    begin
        for i in 0 to 15 loop
            if s = hex_to_7seg(std_logic_vector(to_unsigned(i, 4))) then -- Busca qué valor hexadecimal corresponde a la combinación recibida.
                return i; -- Entrega el número identificado en el display.
            end if;
        end loop;
        return -1; -- Retorna -1 cuando no encuentra una representación válida.
    end function seg2int;

begin

    clk_gen : process
    begin
        while not fin loop
            clk <= '0'; wait for T_CLK / 2;
            clk <= '1'; wait for T_CLK / 2; -- Alterna entre alto y bajo para producir el reloj de simulación.
        end loop;
        wait;
    end process clk_gen;

    uut : entity work.top_system -- Conecta el módulo principal que contiene el sistema que se desea verificar.
        generic map (FILTER_CYCLES => N_FILTRO)
        port map (
            CLOCK_50 => clk, KEY0 => key0, PIR_IN => pir,
            HEX0 => hex0, HEX1 => hex1, HEX2 => hex2, HEX3 => hex3,
            LEDG => ledg
        );

    estimulos : process

        variable errores : natural := 0; -- Lleva el registro del número de comprobaciones fallidas.

        impure function estado return integer is  -- Interpreta los dos primeros LED para conocer el estado de la FSM.
        begin
            return to_integer(unsigned(ledg(1 downto 0)));
        end function;

        impure function cuenta return integer is -- Obtiene el valor numérico del contador mostrado en HEX3 y HEX2.
        begin
            return 16 * seg2int(hex3) + seg2int(hex2);
        end function;

        impure function dato_vis return integer is -- Convierte las salidas HEX1 y HEX0 en el dato hexadecimal correspondiente.
        begin
            return 16 * seg2int(hex1) + seg2int(hex0);
        end function;

        procedure ciclos (n : natural) is -- Permite avanzar la simulación una cantidad determinada de ciclos.
        begin
            for i in 1 to n loop
                wait until falling_edge(clk);
            end loop;
        end procedure;

        procedure chequear (cond : boolean; msg : string) is -- Evalúa cada resultado y muestra un mensaje indicando si la comprobación fue exitosa.
        begin
            if cond then
                report "OK    : " & msg severity note;
            else
                errores := errores + 1;
                report "FALLO : " & msg severity error;
            end if;
        end procedure;

        procedure esperar_estado (destino : integer; maxc : natural) is -- Espera la llegada de la FSM al estado solicitado, con un límite de ciclos.
            variable k : natural := 0;
        begin
            while estado /= destino and k < maxc loop
                wait until falling_edge(clk);
                k := k + 1;
            end loop;
            chequear(estado = destino,
                     "FSM alcanza estado S" & integer'image(destino));
        end procedure;

        procedure detectar (cnt_esp : integer; dato_esp : integer) is -- Simula una detección del PIR y verifica el recorrido de estados, el contador y el dato obtenido.
        begin
            pir <= '1';
            esperar_estado(1, 40);
            ciclos(1); chequear(estado = 2, "S1 -> S2");
            ciclos(1); chequear(estado = 3, "S2 -> S3");
            ciclos(1); chequear(estado = 0, "S3 -> S0");
            ciclos(6);
            chequear(cuenta = cnt_esp,
                     "contador = " & integer'image(cnt_esp));
            chequear(dato_vis = dato_esp,
                     "ultimo dato = " & integer'image(dato_esp));
        end procedure;

        procedure soltar_pir is -- Coloca el sensor en nivel bajo para permitir que posteriormente se detecte un nuevo flanco de subida.
        begin
            pir <= '0';
            ciclos(20);       
        end procedure;

        procedure presionar_reset is -- Activa el reset durante seis ciclos de reloj y después lo libera.
        begin
            key0 <= '0'; ciclos(6); key0 <= '1';
        end procedure;

    begin

        report "--- PRUEBA 0: arranque con PIR en alto ---";
        key0 <= '0'; ciclos(6);
        key0 <= '1';
        ciclos(100);
        chequear(estado = 0,    "arranque: FSM en S0");
        chequear(cuenta = 0,    "arranque: contador en 0 (HEX3:HEX2 = 00)");
        chequear(dato_vis = 0,  "arranque: HEX1:HEX0 = 00");
        chequear(ledg = "000",  "arranque: LEDs apagados");


        report "--- PRUEBA 1 ---";
        soltar_pir;
        ciclos(60);
        chequear(cuenta = 0 and estado = 0, "sin cambio del PIR no hay escrituras");

        report "--- PRUEBA 2 ---";
        detectar(1, 16#AA#);


        report "--- PRUEBA 3 ---";
        ciclos(200);
        chequear(cuenta = 1 and estado = 0, "PIR en 1: no hay escrituras repetidas");

        report "--- PRUEBA 4 ---";
        soltar_pir;
        detectar(2, 16#55#);

        report "--- PRUEBA 5 ---";
        for k in 2 to 5 loop
            soltar_pir;
            detectar(k + 1, ROM_ESPERADA(k));
        end loop;

        report "--- PRUEBA 6 ---";
        soltar_pir;
        pir <= '1'; ciclos(1); pir <= '0'; -- Introduce una variación de un ciclo para comprobar que el filtro rechaza señales demasiado cortas.
        ciclos(40);
        chequear(cuenta = 6 and estado = 0, "ruido de 1 ciclo no genera evento");

        report "--- PRUEBA 7 ---";
        ciclos(100);
        chequear(cuenta = 6 and dato_vis = 16#00#,
                 "display estable: ultimo registro (00) y contador 6");

        report "--- PRUEBA 8: reset con PIR en alto ---";
        pir <= '1';
        esperar_estado(1, 40);                 
        ciclos(10);
        chequear(cuenta = 7, "7o evento registrado");
        presionar_reset;                      
        ciclos(200);
        chequear(estado = 0,   "tras reset: FSM en S0");
        chequear(cuenta = 0,   "tras reset: contador se mantiene en 0");
        chequear(dato_vis = 0, "tras reset: display se mantiene en 0000");
        soltar_pir;                           
        ciclos(40);
        chequear(cuenta = 0,   "al bajar el PIR tampoco se escribe");
        detectar(1, 16#AA#);                  

        report "--- PRUEBA 9 ---";
        soltar_pir;
        presionar_reset;
        ciclos(40);
        chequear(cuenta = 0 and dato_vis = 0, "reset con PIR en bajo: 0000");
        for k in 0 to 15 loop
            soltar_pir;
            detectar(k + 1, ROM_ESPERADA(k)); -- Comprueba consecutivamente los datos de las 16 posiciones de la ROM.
        end loop;
        chequear(ledg(2) = '1', "RAM llena (LED)");
        for k in 1 to 3 loop
            soltar_pir;
            detectar(16, 0); -- Verifica que el sistema no intente escribir en posiciones adicionales cuando la RAM ya está llena.                  
        end loop;
        chequear(ledg(2) = '1', "RAM sigue llena, sin direcciones invalidas");

        report "FIN DE SIMULACION. Errores = " & integer'image(errores);
        assert errores = 0 report "HAY ERRORES" severity failure; -- Genera un error de simulación si alguna de las comprobaciones no se cumple.
        fin <= true; -- Activa la señal que detiene el generador de reloj.
        wait;
    end process estimulos;

end architecture sim;
