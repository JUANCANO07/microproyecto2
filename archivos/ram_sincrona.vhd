library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram_sincrona is
  generic (
    DATA_WIDTH : positive := 8;
    ADDR_WIDTH : positive := 4;
    RDW_MODE   : string   := "READ_FIRST"  -- "READ_FIRST" | "WRITE_FIRST" | "NO_CHANGE"
  );
  port (
    clk      : in  std_logic;
    rd_en    : in  std_logic := '1';
    wr_en    : in  std_logic;
    addr     : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    data_in  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    data_out : out std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end entity;

architecture rtl of ram_sincrona is
  type ram_type is array (0 to 2**ADDR_WIDTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
  signal mem      : ram_type;
  signal q_reg    : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal addr_i   : integer range 0 to 2**ADDR_WIDTH-1;

  attribute ramstyle : string;
  attribute ramstyle of mem : signal is "M9K";
begin
  addr_i <= to_integer(unsigned(addr));

  process(clk)
  begin
    if rising_edge(clk) then
      if wr_en = '1' then
        mem(addr_i) <= data_in;
        if RDW_MODE = "WRITE_FIRST" then
          q_reg <= data_in;
        elsif RDW_MODE = "READ_FIRST" then
          q_reg <= mem(addr_i);
        else
          null; -- NO_CHANGE
        end if;
      else
        if rd_en = '1' then
          q_reg <= mem(addr_i);
        end if;
      end if;
    end if;
  end process;

  data_out <= q_reg;
end architecture;
