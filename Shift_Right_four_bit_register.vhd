LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY Shift_Right_four_bit_register IS
	PORT(
		i_resetBar, i_load	: IN	STD_LOGIC;
		i_clock			: IN	STD_LOGIC;
		i_Value			: IN	STD_LOGIC_VECTOR(3 downto 0);
		o_Value			: OUT	STD_LOGIC_VECTOR(3 downto 0);
		o_value_lsb     :OUT STD_LOGIC);
END Shift_Right_four_bit_register ;

ARCHITECTURE rtl OF Shift_Right_four_bit_register  IS
	SIGNAL int_Value : STD_LOGIC_VECTOR(3 downto 0);--current state
	--SIGNAL d_next     :STD_LOGIC_VECTOR(3 downto 0);--next state
	SIGNAL int_oval    :STD_LOGIC_VECTOR(3 downto 0);


	COMPONENT enARdFF_2
		PORT(
			i_resetBar	: IN	STD_LOGIC;
			i_d		: IN	STD_LOGIC;
			i_enable	: IN	STD_LOGIC;
			i_clock		: IN	STD_LOGIC;
			o_q	: OUT	STD_LOGIC);
	END COMPONENT;

 COMPONENT Mux4_1 IS 
PORT(
i_val_0, i_val_1,i_val_2,i_val_3 : IN STD_LOGIC;
i_sel_0,i_sel_1: IN STD_LOGIC;
o_val: OUT STD_LOGIC);
 END COMPONENT ;
 
 
BEGIN

msbMUX:Mux4_1
PORT MAP(
i_val_0=>int_Value(3),
i_val_1=>i_Value(3),
i_sel=>i_load,
o_val=>int_oval(3));
 PORT MAP (
 
 )

msbFF: enARdFF_2
	PORT MAP (i_resetBar => i_resetBar,
			  i_d => int_oval(3), --output of the mux
			  i_enable => i_load,
			  i_clock => i_clock,
			  o_q =>int_Value(3));--current state

			  
			  
tsbMUX:Mux4_1
PORT MAP(
i_val_0=>int_Value(3),--shift arithmetic
i_val_1=>i_Value(2),
i_sel=>i_load,
o_val=>int_oval(2));
			  
tsbFF: enARdFF_2
	PORT MAP (i_resetBar => i_resetBar,
			  i_d => int_oval(2), 
			  i_enable => i_load,
			  i_clock => i_clock,
			  o_q => int_Value(2));		--current state		
			  
			  
ssbMUX:Mux4_1
PORT MAP(
i_val_0=>int_Value(2),--shift arithmetic
i_val_1=>i_Value(1),
i_sel=>i_load,
o_val=>int_oval(1));
ssbFF: enARdFF_2
	PORT MAP (i_resetBar => i_resetBar,
			  i_d => int_oval(1),
			  i_enable => i_load, 
			  i_clock => i_clock,
			  o_q => int_Value(1));
	        

			  

			  
			  
			  
lsbMUX:Mux4_1
PORT MAP(
i_val_0=>int_Value(1),--shift arithmetic
i_val_1=>i_Value(0),
i_sel=>i_load,
o_val=>int_oval(0));
lsbFF: enARdFF_2
	PORT MAP (i_resetBar => i_resetBar,
			  i_d => int_oval(0), 
			  i_enable => i_load,
			  i_clock => i_clock,
			  o_q => int_Value(0));--current state



			  
	-- Output Driver
	o_Value		<= int_Value;
	o_value_lsb<=int_Value(0);
   
END rtl;
