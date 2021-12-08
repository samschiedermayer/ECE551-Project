
all: comm physical intf motion tour top
	

top:
	vlog top/*.sv
 
comm:
	vlog comm/*.sv

physical:
	vlog physical/*.sv

intf:
	vlog intf/*.sv

motion:
	vlog motion/*.sv

tour:
	vlog tour/*.sv

synth:
	cd synthesis && design_vision -shell dc_shell -f KnightsTour.dc

clean:
	rm -rf work
	rm -f synthesis/*.syn
	rm -f synthesis/*.pvl
	rm -f synthesis/*.mr
	rm -f synthesis/*.svf

