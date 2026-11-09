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
