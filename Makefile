
all:
	vlog comm/*.sv
	vlog individual_tb/*.sv
	vlog intf/*.sv
	vlog motion/*.sv
	vlog physical/*.sv
	vlog tour/*.sv
	vlog top/*.sv
	vlog tests/*.sv

test:
	vlog tests/*.sv
	vsim -c -do "run -all;exit" test_base
	vsim -c -do "run -all;exit" test_moving
	vsim -c -do "run -all;exit" test_tour

synth:
	cd synthesis && design_vision -shell dc_shell -f KnightsTour.dc

post: synth
	cd postsynth &&\
	rm -rf work  &&\
	vlog *.sv    &&\
	vlog *.vg    &&\
	vsim -L SAED32_lib -voptargs="+acc -L SAED32_lib" "+notimingchecks" work.test_postsynth -c -do "run -all;exit"

clean:
	rm -rf work
	rm -f synthesis/*.syn
	rm -f synthesis/*.pvl
	rm -f synthesis/*.mr
	rm -f synthesis/*.svf

