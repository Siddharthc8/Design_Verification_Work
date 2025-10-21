typedef enum logic [1:0] { 
  ZERO  = 2'b00,
  ONE   = 2'b01,
  TWO   = 2'b10,
  THREE = 2'b11
} state_t;

state_t current_state;

—----------------------------------------------------------
property p;
  @(posedge clk) disable iff (!rst_n)
    (current_state == ZERO) |=> 
    (current_state == TWO) ##1
    (current_state == ONE) ##1
    (current_state == THREE);
endproperty
assert property (p);

—----------------------------------------------------------
// Define sequence for state progression
sequence state_progression_seq;
  (current_state == TWO)  ##1
  (current_state == ONE)  ##1
  (current_state == THREE);
endsequence


// Use in property
property check_state_progression_clockwise;
  @(posedge clk) disable iff (!rst_n)
    (current_state == ZERO) |=> state_progression_seq;
endproperty


assert property (check_state_progression_clockwise)
  else $error("State progression clockwise sequence violated");

assert property (check_state_progression_anticlockwise)
  else $error("State progression anti clockwise sequence violated");

—----------------------------------------------------------
property valid_transitions;
  @(posedge clk) disable iff (!rst_n)
    (current_state == ZERO)  |=> (current_state inside {ZERO, TWO}) ##0
    (current_state == TWO)   |=> (current_state inside {TWO, ONE}) ##0
    (current_state == ONE)   |=> (current_state inside {ONE, THREE}) ##0
    (current_state == THREE) |=> (current_state == THREE); // Terminal state
endproperty
assert property (valid_transitions);






