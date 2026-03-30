module checkers
  #(
    parameter int pA = 10 ,
    parameter int fA = 32 ,
    parameter int cA = 4
    )
    (
     input  logic [pA-1:0] pix_x ,
    input  logic [pA-1:0] pix_y ,
     input  logic          pix_v,
     input  logic [fA-1:0] frame_id,
     output logic [cA-1:0] color[2:0],
     input  logic clk,
     input  logic rst,
     input logic button,
	  input logic SW0, 
	  input logic SW9,
	  output logic [6:0] HEX0 

 
     );

///////////character walks to middle of screen and stops

logic [25:0] OneSec ;
logic [25:0] cnt ;
logic [25:0] square_x_right ;
logic [25:0] square_x_left ;
logic [pA-1:0] middle_x ;
logic move_enable;
logic eye_left ;
logic eye_right ;
logic smile ;
logic open_mouth ;
logic closed_mouth ; 
logic face_feature ;
logic square_face ;

assign middle_x = 270 ; //270 (640/2 - 100/2, middle of screen - middle of square), 10 b/c pA
assign move_enable = (OneSec < middle_x); //can only move if it hasn't reached the middle of the screen
	
counter #( .b(20), .m(800_000) ) oneSec_cnt( .inc( move_enable ), .dec(1'b0), .clk, .rst, .cnt(cnt) ) ; // m controls speed, b is 20 b/c 2^20 = 1048576 and can store m
	
my_dff #(20) oneSec_ff( .din(OneSec + 1), .q(OneSec), .clk, .rst, .en( cnt == 1 && move_enable ) ) ;
	
assign square_x_right = OneSec ;
assign square_x_left = OneSec + 100 ; //100 is width of square, also how far on x-axis it starts moving at

assign eye_left  = (pix_x >= square_x_right + 20) && (pix_x <= square_x_right + 30) && (pix_y >= 220) && (pix_y <= 230) ; //starts 20 pixels from the right edge of the square, width 10
assign eye_right = (pix_x >= square_x_right + 70) && (pix_x <= square_x_right + 80) && (pix_y >= 220) && (pix_y <= 230) ;

assign face_feature = eye_left || eye_right || smile ;                         //if the pixel is in eye_left or eye_right or smile then face_feature is 1
assign square_face = (pix_x >= square_x_right) && (pix_x <= square_x_left) && (pix_y >= 190) && (pix_y <= 290); //x values = one sec to make it move

assign open_mouth = ((pix_x >= square_x_right + 30) && (pix_x <= square_x_right + 70) && (pix_y >= 260) && (pix_y <= 285)) ;
assign closed_mouth = ((pix_x >= square_x_right + 30) && (pix_x <= square_x_right + 70) && (pix_y >= 260) && (pix_y <= 265)) ;
assign smile = button ? closed_mouth : open_mouth ;  //active low, not pressed = small mouth, pressed = large mouth
assign color[0] = pix_v ? ( dies ? 4'hf :  ( square_face ? (face_feature ? 4'h0 : 4'hf) : 4'h0 ) ) : 4'h0 ; //in square and is a face feature then draw black, otherwise red, outside of square is black ; if dies, screen is all red

//assign color[0] = pix_v?( ( (pix_x > square_x_right) && (pix_x < square_x_left) && (pix_y >= 190) && (pix_y <= 290) )? 4'hf: 4'h0 ) :4'h0 ; // solid red moving square


///////////everytime KEY0 is pressed food eaten by character increments and value displays on HEX display

logic [3:0] eating_count ;
logic button_prev ;
logic button_next ;

my_dff button_state( .din(button), .q(button_prev), .clk, .rst, .en(1'b1) ) ;

assign button_next = (button == 1'b1) && (button_prev == 1'b0) ;

counter #(.b(4), .m(4)) nomnom( .inc(button_next), .dec(1'b0), .clk, .rst, .cnt(eating_count) ) ; 

OurMux display(.SW(eating_count), .HEX0(HEX0)) ;


/////////////////////dies

logic dies;

assign dies = (eating_count == 0) ;

//when dies == 1, in section character & movement color[0] will be f, in section falling blue squares color[2] will be 0


//////////////////////falling blue squares

logic [9:0] square_y1;
logic [25:0] fall_counter1 ;      
logic [9:0] square_y_next1;
logic [9:0] square_x1;    
logic [9:0] square_x_next1;
logic in_square1;

counter #(.b(20), .m(800_000)) fall_speed( .inc(1'b1), .dec(1'b0), .clk, .rst, .cnt(fall_counter1) ) ; //higher m number = square moves slower

assign square_x_next1 = (square_x1 >= 640) ? '0 : square_x1 + 1; //travels full length of screen, if it reaches end of screen it goes back to zero otherwise it increments
assign square_y_next1 = (square_y1 >= 480) ? '0 : square_y1 + 1; 

my_dff #(10) square_x_dff1 ( .din(square_x_next1), .q(square_x1), .clk, .rst, .en(fall_counter1 == 1 && SW9 == 1 ) );  // moving in the x direction
my_dff #(10) square_y_dff1 ( .din(square_y_next1), .q(square_y1), .clk, .rst, .en(fall_counter1 == 1 && SW0 == 1 ) ); // moving in the y direction

assign in_square1 = ((pix_x >= square_x1) && (pix_x <= square_x1 + 40) && (pix_y >= square_y1) && (pix_y <= square_y1 + 40)); //+40 for size of square, checks if pixel is in the square 

//assign color[2] = pix_v ? (in_square1 ? 4'hf : 4'h0) : 4'h0 ; //for one square

// Second square
logic [9:0] square_x2;
logic [9:0] square_y2;
logic [25:0] fall_counter2 ;      
logic [9:0] square_x_next2;
logic [9:0] square_y_next2;
logic in_square2;

counter #(.b(20), .m(200_000)) fall_speed2( .inc(1'b1), .dec(1'b0), .clk, .rst, .cnt(fall_counter2) ) ;

assign square_x_next2 = (square_x2 >= 640) ? '0 : square_x2 + 1; 
assign square_y_next2 = (square_y2 >= 480) ? '0 : square_y2 + 1; 

my_dff #(10) square_x_dff2 ( .din(square_x_next2), .q(square_x2), .clk, .rst, .en(fall_counter2 == 1 && SW9 == 1 && square1_eaten) );
my_dff #(10) square_y_dff2 ( .din(square_y_next2), .q(square_y2), .clk, .rst, .en(fall_counter2 == 1 && SW0 == 1 && square1_eaten) ); 

assign in_square2 = (pix_x >= square_x2) && (pix_x <= square_x2 + 40) && (pix_y >= square_y2) && (pix_y <= square_y2 + 40);


//assign color[2] = pix_v ? ( dies  ? 4'h0 :  (in_square1 || in_square2) ? 4'hf : 4'h0 ) : 4'h0; //if pixel is in any square then it turns blue, if dies then all the squares are nonexistent


//////////////////////collision/eating

// First square
logic square1_eaten;
logic square1_eaten_next;
logic square_at_mouth;
logic [3:0] color_square1;

assign square1_eaten_next = square1_eaten || (button == '0) && in_square1 && square_at_mouth ;

assign square_at_mouth = (square_x1 + 20 >= square_x_right - 50 ) && (square_x1 + 20 <= square_x_right + 100) && (square_y1 + 20 >= 260) && (square_y1 + 20 <= 285 ) ;

my_dff #(1) square1_eaten_ff ( .din(square1_eaten_next), .q(square1_eaten), .clk, .rst, .en(1'b1) );

assign color_square1 = square1_eaten ? 4'h0 : (in_square1 ? 4'hf : 4'h0);

// Second square
logic square2_eaten;
logic square2_eaten_next;
logic square_at_mouth2;
logic [3:0] color2_square1;
logic [3:0] color2_square2;

assign square2_eaten_next = square2_eaten || (button == '0) && in_square2 && square_at_mouth2 ;

assign square_at_mouth2 = (square_x2 + 20 >= square_x_right - 50 ) && (square_x2 + 20 <= square_x_right + 100) && (square_y2 + 20 >= 260) && (square_y2 + 20 <= 285 ) ;

my_dff #(1) square2_eaten_ff ( .din(square2_eaten_next), .q(square2_eaten), .clk, .rst, .en(1'b1) );

assign color2_square2 = square2_eaten ? 4'h0 : (in_square2 ? 4'hf : 4'h0) ;

assign color[2] = pix_v ? (color_square1 | color2_square2) : 4'h0;

endmodule


