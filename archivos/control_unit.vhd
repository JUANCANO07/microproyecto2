-- Unidad de Control: Máquina de estados finitos (FSM) de Moore para coordinar 
-- la lectura de la ROM y la escritura en la RAM tras la llegada de un pulso del sensor PIR.
-- FSM: S0 (Espera) -> S1 (Lee ROM) -> S2 (Escribe RAM) -> S3 (Actualiza punteros) -> S0
-- Nota: En S2 se habilita la escritura y se actualizan punteros.
-- Si la memoria se llena (MEM_DEPTH), la bandera 'lleno' se activa y bloquea la escritura.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pkg_system.all;

entity control_unit is
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;                       -- activo en alto
        pir_pulse : in  std_logic;
        rom_addr  : out tipo_direccion;
        ram_addr  : out tipo_direccion;                  -- direccion de escritura
        last_addr : out tipo_direccion;                  -- ultimo registro valido
        ram_we    : out std_logic;
        rec_count : out std_logic_vector(ADDR_WIDTH downto 0);  -- 0..16
        full      : out std_logic;
        estado_o  : out std_logic_vector(1 downto 0)     -- S0=00 S1=01 S2=10 S3=11
    );
end entity control_unit;

architecture rtl of control_unit is

    -- Tipo enumerado para definir los 4 estados de la FSM de Moore
    type estado_t is (S0, S1, S2, S3);
    signal estado_actual    : estado_t := S0;
    signal estado_siguiente : estado_t;

    -- Registros internos para almacenar y mantener las direcciones y el contador
    signal rom_addr_r  : tipo_direccion := (others => '0');
    signal ram_addr_r  : tipo_direccion := (others => '0');
    signal last_addr_r : tipo_direccion := (others => '0');
    signal contador    : integer range 0 to MEM_DEPTH := 0;

    signal lleno    : std_logic;
    signal ram_we_i : std_logic;

begin

    -- Comparador combinacional que se activa si el contador alcanza el límite MEM_DEPTH
    lleno <= '1' when contador = MEM_DEPTH else '0';

    -- Registro de estado síncrono
    -- rising_edge(clk) evalúa la transición del flanco de subida del reloj (0 a 1)
    p_registro_estados : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                estado_actual <= S0;
            else
                estado_actual <= estado_siguiente;
            end if;
        end if;
    end process p_registro_estados;

    -- Lógica combinacional para determinar las transiciones del siguiente estado
    -- Asignar estado_siguiente por defecto al inicio previene la inferencia no deseada de latches
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

    -- Lógica de salidas (Moore: depende únicamente de estado_actual)
    -- Activa la señal interna de escritura (ram_we_i) en S2 si la RAM aún no está llena
    p_salidas : process (estado_actual, lleno)
    begin
        ram_we_i <= '0';
        case estado_actual is
            when S2 =>
                if lleno = '0' then
                    ram_we_i <= '1';
                end if;
            when others =>
                null;   -- S0, S1, S3: sin escritura
        end case;
    end process p_salidas;

    -- Proceso secuencial para actualización de punteros de dirección y del contador de eventos
    p_direcciones : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                rom_addr_r  <= (others => '0');
                ram_addr_r  <= (others => '0');
                last_addr_r <= (others => '0');
                contador    <= 0;
            else
                if ram_we_i = '1' then
                    last_addr_r <= ram_addr_r;
                    contador    <= contador + 1;
                    if contador < MEM_DEPTH - 1 then
                        -- unsigned(vector) interpreta los bits del vector como número sin signo para sumar 1
                        -- std_logic_vector(...) vuelve a castear el resultado al tipo de salida
                        rom_addr_r <= std_logic_vector(unsigned(rom_addr_r) + 1);
                        ram_addr_r <= std_logic_vector(unsigned(ram_addr_r) + 1);
                    end if;
                end if;
            end if;
        end if;
    end process p_direcciones;

    -- Asignación de salidas físicas y banderas internas
    rom_addr  <= rom_addr_r;
    ram_addr  <= ram_addr_r;
    last_addr <= last_addr_r;
    ram_we    <= ram_we_i;
    full      <= lleno;

    -- to_unsigned(contador, tamaño) convierte el número entero 'contador' a un tipo unsigned de (ADDR_WIDTH + 1) bits,
    -- y std_logic_vector(...) lo convierte al tipo estándar del puerto rec_count
    rec_count <= std_logic_vector(to_unsigned(contador, ADDR_WIDTH + 1));

    -- Multiplexor/decodificador de estado a 2 bits para monitoreo en LEDs o testbench
    with estado_actual select
        estado_o <= "00" when S0,
                    "01" when S1,
                    "10" when S2,
                    "11" when S3;

end architecture rtl;
