library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pkg_system.all;

entity tb_top_system is
end entity tb_top_system;

architecture sim of tb_top_system is

    constant T_CLK    : time     := 20 ns;
    constant N_FILTRO : positive := 4;

    signal clk  : std_logic := '0';
    signal key0 : std_logic := '0';
    signal pir  : std_logic := '0';
    signal sw   : std_logic_vector(4 downto 0) := (others => '0');
    signal hex0, hex1, hex2, hex3 : std_logic_vector(6 downto 0);
    signal ledg : std_logic_vector(3 downto 0);
    signal fin  : boolean := false;

    type tabla_t is array (0 to 15) of natural;
    
    -- Mapa de memoria esperado para contrastar contra las lecturas de la RAM
    constant ROM_ESPERADA : tabla_t :=
        (16#AA#, 16#55#, 16#F0#, 16#0F#, 16#FF#, 16#00#,
         0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

    -- Rutina de conversion inversa: Transforma el codigo de 7 segmentos generado 
    -- por el top_system nuevamente a un valor entero para aserciones automáticas.
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

        -- Funciones auxiliares para extraccion de datos del sistema bajo prueba (UUT)
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

        -- Macro de verificacion unificada para generar reportes estructurados
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

        -- Procedimiento detectar:
        -- Emula la inyeccion de un flanco en el sensor PIR y realiza un seguimiento 
        -- estricto del recorrido de la maquina de estados de Moore (S0 -> S1 -> S2 -> S3 -> S0).
        -- Adicionalmente valida la coherencia de los punteros post-escritura.
        procedure detectar (cnt_esp : integer; dato_esp : integer) is
        begin
            pir <= '1';
            esperar_estado(1, 40);
            ciclos(1); chequear(estado = 2, "Transicion S1 -> S2 (Habilitacion RAM)");
            ciclos(1); chequear(estado = 3, "Transicion S2 -> S3 (Actualizacion punteros)");
            ciclos(1); chequear(estado = 0, "Transicion S3 -> S0 (Retorno a reposo)");
            ciclos(6);
            chequear(cuenta = cnt_esp,
                     "Contador de registros concuerda = " & integer'image(cnt_esp));
            chequear(dato_vis = dato_esp,
                     "Ultimo dato escrito concuerda = " & integer'image(dato_esp));
        end procedure;

        procedure soltar_pir is
        begin
            pir <= '0';
            ciclos(20);        
        end procedure;

        -- Procedimiento leer_ram:
        -- Activa el modo de inspeccion forzando la senal SW(4) e inyectando la direccion 
        -- a evaluar en SW(3:0). Espera la latencia inherente de la memoria antes de evaluar.
        procedure leer_ram (a : integer; r : out integer) is
        begin
            sw <= '1' & std_logic_vector(to_unsigned(a, 4));
            ciclos(10);
            r := dato_vis;
        end procedure;

    begin
        
        -- Inicializacion del sistema
        -- Se aplica un reset por hardware (activo en bajo) y se verifica el estado por defecto.
        key0 <= '0'; pir <= '0';
        ciclos(6);
        key0 <= '1';
        ciclos(8);
        chequear(estado = 0,  "Reset general: FSM inicializada en S0 (IDLE)");
        chequear(cuenta = 0,  "Reset general: Punteros y contador inicializados en 0");
        chequear(dato_vis = 0, "Reset general: Decodificadores de display apagados (00)");

        -- Prueba 1: Evaluacion de estado inactivo
        -- Verifica que ante la ausencia de pulsos del sensor PIR, el sistema permanezca en 
        -- reposo y no infiera operaciones de escritura erroneas en la memoria RAM.
        report "Iniciando Prueba 1: Evaluacion de estado inactivo";
        ciclos(60);
        chequear(cuenta = 0 and estado = 0, "Sistema inactivo: No se registran operaciones fantasma");

        -- Prueba 2: Ciclo de escritura de primer evento
        -- Inyecta el primer flanco de deteccion y confirma que la FSM recupere el primer 
        -- codigo de la ROM (0xAA) y lo ubique satisfactoriamente en la RAM[0].
        report "Iniciando Prueba 2: Ciclo de escritura de primer evento";
        detectar(1, 16#AA#);
        leer_ram(0, v);
        chequear(v = 16#AA#, "Integridad de memoria cruzada: RAM[0] = 0xAA");
        sw <= "00000"; ciclos(10);

        -- Prueba 3: Tolerancia a niveles logicos estaticos
        -- Mantiene la senal del PIR en alto constante para garantizar que el sistema 
        -- es sensible a flancos y no a niveles, evitando saturacion de escrituras repetitivas.
        report "Iniciando Prueba 3: Tolerancia a niveles logicos estaticos";
        ciclos(200);
        chequear(cuenta = 1 and estado = 0, "Tolerancia PIR: Senal alta sostenida es descartada");

        -- Prueba 4: Ciclo de escritura de segundo evento
        -- Retira el estimulo PIR y genera uno nuevo, validando que los punteros se hayan 
        -- actualizado correctamente hacia RAM[1] sin destruir la data en RAM[0].
        report "Iniciando Prueba 4: Ciclo de escritura de segundo evento";
        soltar_pir;
        detectar(2, 16#55#);
        leer_ram(1, v);
        chequear(v = 16#55#, "Integridad de memoria cruzada: RAM[1] = 0x55");
        leer_ram(0, v);
        chequear(v = 16#AA#, "Integridad historica: RAM[0] retiene dato previo (0xAA)");
        sw <= "00000"; ciclos(10);

        -- Prueba 5: Trafico denso y direccionamiento secuencial
        -- Dispara una ráfaga de detecciones consecutivas (índices 2 a 5) y corrobora 
        -- posteriormente todo el bloque de memoria contra el array constante esperado.
        report "Iniciando Prueba 5: Trafico denso y direccionamiento secuencial";
        for k in 2 to 5 loop
            soltar_pir;
            detectar(k + 1, ROM_ESPERADA(k));
        end loop;
        for k in 0 to 5 loop
            leer_ram(k, v);
            chequear(v = ROM_ESPERADA(k),
                     "Validacion de bloque: RAM[" & integer'image(k) & "] correcta");
        end loop;
        leer_ram(9, v);
        chequear(v = 0, "Proteccion de lectura: Direccion vacia reporta 0x00");
        sw <= "00000"; ciclos(10);

        -- Prueba 6: Rechazo de transitorios de ruido electromagnetico
        -- Inyecta un pulso inferior a la constante del filtro sincronizador para asegurar 
        -- que la senal ruidosa sea atenuada y descartada por la etapa de acondicionamiento.
        report "Iniciando Prueba 6: Rechazo de transitorios de ruido";
        soltar_pir;
        pir <= '1'; ciclos(1); pir <= '0';
        ciclos(40);
        chequear(cuenta = 6 and estado = 0, "Filtro digital: Pulso corto ignorado exitosamente");

        -- Prueba 7: Latencia del pipeline de visualizacion (Modo normal vs. manual)
        report "Iniciando Prueba 7: Latencia del pipeline de visualizacion";
        chequear(dato_vis = 16#00#, "Pipeline: Modo operativo recobra correctamente ultimo registro historico");
        leer_ram(4, v);
        chequear(v = 16#FF#, "Pipeline: Lectura de inspeccion sobre RAM[4] (0xFF) compensada en latencia");
        sw <= "00000"; ciclos(10);

        -- Prueba 8: Recuperacion ante interrupciones asincronas criticas (Reset)
        -- Fuerza una señal de reinicio en mitad de la secuencia para verificar que 
        -- todo el hardware retorne a los estados seguros predefinidos.
        report "Iniciando Prueba 8: Recuperacion ante interrupciones asincronas";
        key0 <= '0'; ciclos(6); key0 <= '1'; ciclos(8);
        chequear(estado = 0,   "Reinicio asincrono: Control transita a S0");
        chequear(cuenta = 0,   "Reinicio asincrono: Direccionamiento restablecido");
        chequear(dato_vis = 0, "Reinicio asincrono: Salidas a display silenciadas");

        -- Prueba 9: Saturacion de memoria y bloqueo estructural
        -- Llena por completo las direcciones de la RAM (16 registros) e inyecta pulsos 
        -- de sobreflujo. Se asegura que la escritura se bloquee protegiendo la data antigua.
        report "Iniciando Prueba 9: Saturacion de memoria y bloqueo estructural";
        for k in 0 to 15 loop
            soltar_pir;
            detectar(k + 1, ROM_ESPERADA(k));
        end loop;
        chequear(ledg(2) = '1', "Sistema de alertas: Flag hardware de memoria llena emitido (LEDG2)");
        for k in 1 to 3 loop
            soltar_pir;
            detectar(16, 0);  
        end loop;
        chequear(ledg(2) = '1', "Sistema de alertas: Flag sostenido ante pulsos de sobreflujo");
        leer_ram(0, v);
        chequear(v = 16#AA#, "Proteccion de sobreescritura: RAM[0] conservada (sin rollover)");
        leer_ram(1, v);
        chequear(v = 16#55#, "Proteccion de sobreescritura: RAM[1] conservada");
        leer_ram(15, v);
        chequear(v = 0, "Proteccion de sobreescritura: RAM[15] conservada");

 automatizada
        report "Secuencia de estimulos finalizada. Resumen de errores encontrados: " & integer'image(errores);
        assert errores = 0 report "LA VERIFICACION ESTRUCTURAL HA FALLADO. REVISAR TRANSICIONES." severity failure;
        fin <= true;
        wait;
    end process estimulos;

end architecture sim;




