LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
ENTITY RippleAdder IS
PORT(
i_A_vect,i_B_vect: IN STD_LOGIC_VECTOR(3 downto 0);
i_Cin:IN STD_LOGIC;
o_Sum_vect:OUT STD_LOGIC_VECTOR(3 downto 0);
o_Cout:OUT STD_LOGIC;
o_overFlow:OUT STD_LOGIC);

END RippleAdder;

ARCHITECTURE rtl OF RippleAdder IS
SIGNAL int_Cin_vect: STD_LOGIC_VECTOR(3 downto 0);
SIGNAL int_Sum_vect:STD_LOGIC_VECTOR(3 downto 0);
COMPONENT full_adder 
PORT(
 i_A,i_B : IN STD_LOGIC;
 i_Carry_in:IN STD_LOGIC;
 o_Sum,O_Carry_out:OUT STD_LOGIC);
 
END COMPONENT;

BEGIN

-- Component Instantiation

FA_0:full_adder
PORT MAP(
 i_A=>i_A_vect(0),
 i_B =>i_B_vect(0),
 i_Carry_in=>i_Cin,
 o_Sum=>int_Sum_vect(0),
 O_Carry_out=>int_Cin_vect(0));
 
 
 FA_1:full_adder
PORT MAP(
 i_A=>i_A_vect(1),
 i_B =>i_B_vect(1),
 i_Carry_in=>int_Cin_vect(0),
 o_Sum=>int_Sum_vect(1),
 O_Carry_out=>int_Cin_vect(1));
 
 FA_2:full_adder
PORT MAP(
 i_A=>i_A_vect(2),
 i_B =>i_B_vect(2),
 i_Carry_in=>int_Cin_vect(1),
 o_Sum=>int_Sum_vect(2),
 O_Carry_out=>int_Cin_vect(2));
 
 
 FA_3:full_adder
PORT MAP(
 i_A=>i_A_vect(3),
 i_B =>i_B_vect(3),
 i_Carry_in=>int_Cin_vect(2),
 o_Sum=>int_Sum_vect(3),
 O_Carry_out=>int_Cin_vect(3));
 
 -- Output Driver
o_Sum_vect<=int_Sum_vect;
o_Cout<=int_Cin_vect(3);
o_overFlow<=int_Cin_vect(3) xor int_Cin_vect(2); 
 END rtl;