
all:
	vlog comm/*.sv
	vlog individual_tb/*.sv
	vlog intf/*.sv
	vlog motion/*.sv
	vlog physical/*.sv
	vlog tour/*.sv
	vlog tb_support/*.sv
	vlog top/*.sv

test:
	vlog tb_support/*.sv
	vlog top/*.sv
	vsim -c -do "run -all;exit" KnightsTour_tb

synth:
	cd synthesis && design_vision -shell dc_shell -f KnightsTour.dc

clean:
	rm -rf work
	rm -f synthesis/*.syn
	rm -f synthesis/*.pvl
	rm -f synthesis/*.mr
	rm -f synthesis/*.svf

