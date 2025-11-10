LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY Mux2_1 IS 
PORT(
i_val_0, i_val_1 : IN STD_LOGIC;
i_sel: IN STD_LOGIC;
o_val: OUT STD_LOGIC);
 END Mux2_1 ;

 ARCHITECTURE rtl OF Mux2_1 IS
 SIGNAL int_not_sel  : STD_LOGIC;
 SIGNAL int_and1,int_and2  : STD_LOGIC;
 SIGNAL int_final_o  : STD_LOGIC;
 
 
 BEGIN
 -- Concurrent Signal Assignment
int_not_sel <= not(i_sel);
int_and1<=i_val_0 and int_not_sel;
int_and2<=i_val_1 and i_sel;
int_final_o <=int_and1 or int_and2;

-- Output Driver
o_val <= int_final_o;

END rtl;

