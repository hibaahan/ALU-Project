LIBRARY ieee;
USE ieee.std_logic_1164.ALL;


ENTITY Mux4_1 IS 
PORT(
i_val_0, i_val_1,i_val_2,i_val_3 : IN STD_LOGIC;
i_sel_0,i_sel_1: IN STD_LOGIC;
o_val: OUT STD_LOGIC);
 END Mux4_1 ;
 
 
 ARCHITECTURE rtl OF Mux4_1 IS
 SIGNAL int_o_Sel1,int_o_not_Sel1: STD_LOGIC;
 SIGNAL int_final_o  : STD_LOGIC;
 
 COMPONENT Mux2_1
   PORT(
	i_val_0, i_val_1 : IN STD_LOGIC;
   i_sel: IN STD_LOGIC;
   o_val: OUT STD_LOGIC);
   END COMPONENT;
	
	 BEGIN
 Mux2_1_1:Mux2_1
 
  PORT MAP(
  i_val_0 => i_val_0,
  i_val_1 => i_val_1,
  i_sel => i_sel_0,
  o_val => int_o_not_Sel1);
  
  
  
  Mux2_1_2:Mux2_1
 
  PORT MAP(
  i_val_0 => i_val_2,
  i_val_1 => i_val_3,
  i_sel => i_sel_0,
  o_val => int_o_Sel1);
  
  
  Mux2_1_3:Mux2_1
 
  PORT MAP(
  i_val_0 =>int_o_not_Sel1,
  i_val_1 =>int_o_Sel1,
  i_sel => i_sel_1,
  o_val => int_final_o);
  
  -- Output Driver
  o_val <= int_final_o;
  
  END rtl;
 
  
 