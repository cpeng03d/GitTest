`define NVM_DATA  "ctrl/nvm_data.txt"
`define NVM_BITFIELDS  "ctrl/nvm_bitfields.txt"
`define NVM_SIZE  64

class nvm_predictor #(type T = nvm_seq_item, type P = nvm_seq_item) extends predictor_base #(T,P);
  `uvm_component_param_utils(nvm_predictor#(T,P))
  
  bit [7:0] nvm_data[`NVM_SIZE];
  bit [7:0] nvm_bitfields[`NVM_SIZE];
  bit [7:0] spi_command;
  bit [7:0] addr;
  bit [7:0] wrdata;
  bit [7:0] rdata;
  
  extern function new(string name = "nvm_predictor", uvm_component parent = null);
  extern function void check_addr(bit [7:0] address, cmd);
  extern function void check_bitfield(bit [7:0] address, data);
  
  function P transform(input T t);
    P             transform_out;
	
	transform_out=P::type_id::create(transform_out");
	transform_out.copy(t);
	if(cmd == 8'he2 || cmd == 8'he3) begin
	  check_addr(P.address, P.cmd);
	  check_data(P.address, P.data);
	  P.address = P.address%64;
	  if(cmd == 8'he2)
	    P.data = nvm_data[P.address%64];
	  else if (cmd == 8'he3 && P.address >= 8'h14)
        nvm_data[P.address] = P.data;
	end
    else
	  data = 8'h00;

  endfunction : transform
  
endclass : nvm_predictor
  
function nvm_predictor::new(string name = "nvm_predictor", uvm_component parent = null);
  super.new(name, parent);
  $readmemh(`NVM_DATA, nvm_data);
  $readmemh(`NVM_BITFIELDS, nvm_bitfields);
endfunction : new

function nvm_predictor::check_addr(bit {7:0] address, cmd);
  if(address<=19 && cmd == 8'he3)
    `uvm_error("address_check", $sformatf("Illegal write to addresses <=x13 (these can only be modified during wafer test in production), tried to write address %X", address))
  if(address>=8'h40)
    `uvm_error("address_invalid", $sformatf("This transaction attempts to access an illegal NVM address, as addresses over 3F don't exist. Address attempted = %X", address))
endfunction : check_address

function nvm_predictor::check_bitfield(bit [7:0] address, data);
  for (int i = 0; i<7; i++) begin
    if (data[i] && !nvm_bitfields[address][i])
	  `uvm_error("bitfield_check", $sformatf("Illegal write to an unimplemented bitfield at address %X, bit %d" address, data))
  end
endfunction : check_bitfield