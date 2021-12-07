
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

clean:
	rm -rf work
	
