LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
ENTITY full_adder IS
PORT(
 i_A,i_B : IN STD_LOGIC;
 i_Carry_in:IN STD_LOGIC;
 o_Sum,O_Carry_out:OUT STD_LOGIC);
 
END full_adder;

ARCHITECTURE rtl OF full_adder IS
 SIGNAL int_C1,int_C2,int_C3:STD_LOGIC;
 SIGNAL int_Carry_out,int_Sum:STD_LOGIC;
 
 BEGIN
 
 -- Concurrent Signal Assignment
 
 int_C1 <= i_A and i_Carry_in;
 int_C2<= i_B and i_Carry_in;
 int_C3<= i_A and i_B;
 int_Carry_out<=int_C1 or int_C2 or int_C3;
 int_Sum<= i_A xor i_B xor i_Carry_in;
 
 
 -- Output Driver
 
 o_Sum<= int_Sum;
 o_Carry_out<=int_Carry_out;
 
 END rtl ;