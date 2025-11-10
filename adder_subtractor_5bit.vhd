LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
ENTITY adder_subtractor_5bit IS
PORT(
i_A_v,i_B_v: IN STD_LOGIC_VECTOR(4 downto 0);
i_Carry_in:IN STD_LOGIC;
o_Carry_out:OUT STD_LOGIC;
o_Zero,o_overFlow:OUT STD_LOGIC;
o_Sum_vect:OUT STD_LOGIC_VECTOR(4 downto 0));

END adder_subtractor_5bit;

ARCHITECTURE rtl OF adder_subtractor_5bit IS

SIGNAL int_B_xor:STD_LOGIC_VECTOR(4 downto 0);
SIGNAL int_Sum_v:STD_LOGIC_VECTOR(4 downto 0);
SIGNAL int_Carryout,int_overFlow:STD_LOGIC;
COMPONENT RippleAdder_Fivebit
PORT(
i_A_vect,i_B_vect: IN STD_LOGIC_VECTOR(4 downto 0);
i_Cin:IN STD_LOGIC;
o_Sum_vect:OUT STD_LOGIC_VECTOR(4 downto 0);
o_Cout:OUT STD_LOGIC;
o_overFlow:OUT STD_LOGIC);
END COMPONENT;

BEGIN
-- Concurrent Signal Assignment

int_B_xor(0)<=i_B_v(0) xor i_Carry_in;
int_B_xor(1)<=i_B_v(1) xor i_Carry_in;
int_B_xor(2)<=i_B_v(2) xor i_Carry_in;
int_B_xor(3)<=i_B_v(3) xor i_Carry_in;
int_B_xor(4)<=i_B_v(4) xor i_Carry_in;

RP:RippleAdder_Fivebit
PORT MAP(
i_A_vect=>i_A_v,
i_B_vect=>int_B_xor,
i_Cin=>i_Carry_in,
o_Sum_vect=>int_Sum_v,
o_Cout=>int_Carryout,
o_overFlow=>int_overFlow);
-- Output Driver

o_Sum_vect<=int_Sum_v;
o_Carry_out<=int_Carryout;
o_zero<=not (int_Sum_v(0) or int_Sum_v(1) or int_Sum_v(2) or int_Sum_v(3) or int_Sum_v(4));
o_overFlow<=int_overFlow;

END rtl;