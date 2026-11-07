library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rom_sync is
  generic (
    DATA_WIDTH : positive := 8;
    ADDR_WIDTH : positive := 4
  );
  port (
    clk      : in  std_logic;
    addr     : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    data_out : out std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end entity;

architecture rtl of rom_sync is
  type rom_type is array (0 to 2**ADDR_WIDTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
  constant mem : rom_type := (
    0 => x"AA", 1 => x"55", 2 => x"F0", 3 => x"0F",
    4 => x"FF", 5 => x"00",
    others => (others => '0')
  );
  signal q_reg : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal addr_i: integer range 0 to 2**ADDR_WIDTH-1;

  attribute romstyle : string;
  attribute romstyle of mem : constant is "M9K";
begin
  addr_i <= to_integer(unsigned(addr));

  process(clk)
  begin
    if rising_edge(clk) then
      q_reg <= mem(addr_i);
    end if;
  end process;

  data_out <= q_reg;
end architecture;
