//TrafficController.v -- top

module TrafficController (
    input        CLOCK_50,
    input  [1:0] KEY,        //KEY[0]=reset_n, KEY[1]=ped_btn
    output [9:0] LEDR,
    output [6:0] HEX0
);

    wire reset_n   = KEY[0];  //reset (active_low)
    wire ped_btn_n = KEY[1];  //pedestrian button (active_low)

    //1 Hz divider
    //we need 1-second timing for the FSM delays, so we divide the 50 MHz clock
    localparam [25:0] DIV_MAX = 26'd50_000_000 - 1;

    reg [25:0] div_counter;
    reg        tick_1Hz;

    always @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n) begin
            div_counter <= 0;
            tick_1Hz <= 0;
        end else begin
	    //every time we hit 50M cycles, we toggle our 1 Hz tick.
            if (div_counter == DIV_MAX) begin
                div_counter <= 0;
                tick_1Hz <= 1;	//pulse only for 1 clock cycle
            end else begin
                div_counter <= div_counter + 1;
                tick_1Hz <= 0;
            end
        end
    end

    //PEDESTRIAN BLINKER (1 Hz blink)
    reg blink;

    always @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n)
            blink <= 0;
        else if (tick_1Hz)
            blink <= ~blink;   //toggles every second
    end

    //FSM States for 3-led traffic light
    localparam [1:0]
        S_GREEN  = 2'd0,
        S_YELLOW = 2'd1,
        S_RED    = 2'd2;

    //display countdown
    localparam [3:0]
        GREEN_TIME   = 4'd5,
        YELLOW_TIME  = 4'd2,
        RED_TIME     = 4'd5,
        PED_RED_TIME = 4'd9; 	//red and pedestrain active at the same time

    reg [1:0] state;
    reg [3:0] sec_count;

    reg ped_req;	//latching pedestrain request until reaching red
    reg red_is_ped;	//switch between normal and pedastrian

    //KEY1 synchronizer + edge detection (for the push button)
    reg p0, p1, p_prev;
    wire ped_press;

    always @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n) begin
            p0 <= 0; p1 <= 0; p_prev <= 0;
        end else begin
            p0 <= ~ped_btn_n;
            p1 <= p0;
            p_prev <= p1;
        end
    end

    assign ped_press = p1 & ~p_prev;	//logic to rewrite the button so new active high is detected

    // FSM + Latch Logic (when to prioritize pedastrains)
    always @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n) begin
            state      <= S_GREEN;
            sec_count  <= 0;
            ped_req    <= 0;
            red_is_ped <= 0;
        end else begin

            if (ped_press)
                ped_req <= 1;	//track button pressed

	    //fsm 1Hz timing match for seconds
            if (tick_1Hz) begin
                case (state)

                    S_GREEN: begin
                        if (sec_count == GREEN_TIME - 1) begin
                            state <= S_YELLOW;
                            sec_count <= 0;
                        end else sec_count <= sec_count + 1;
                    end

                    S_YELLOW: begin
                        if (sec_count == YELLOW_TIME - 1) begin
                            state <= S_RED;
                            sec_count <= 0;
                            red_is_ped <= ped_req;	//if ped_req has been active only remember for this active red light
                        end else sec_count <= sec_count + 1;
                    end
		    
                    S_RED: begin
			//checking red time duration
                        if (sec_count == ((red_is_ped ? PED_RED_TIME : RED_TIME) - 1)) begin
                            state <= S_GREEN;
                            sec_count <= 0;
                            ped_req <= 0;	//reset for next cycle so doesnt repeat unless triggered again
                            red_is_ped <= 0;
                        end else sec_count <= sec_count + 1;
                    end

                endcase
            end
        end
    end

    //Output Logic (signal(car) lights solid, Pedastrain light blinks)
    reg car_green, car_yellow, car_red;
    reg ped_active;
    reg [3:0] sec_left;

    always @(*) begin
        car_green  = 0;
        car_yellow = 0;
        car_red    = 0;
        ped_active = 0;
        sec_left   = 0;

        case (state)

            S_GREEN: begin
                car_green = 1;
                sec_left  = GREEN_TIME - sec_count; //hexcountdown
            end

            S_YELLOW: begin
                car_yellow = 1;
                sec_left   = YELLOW_TIME - sec_count;
            end

           //RED stays solid, pedestrian blinks
            S_RED: begin
                car_red = 1;  // solid red

                if (red_is_ped) begin
                    ped_active = blink;  // << BLINK HERE
                    sec_left   = PED_RED_TIME - sec_count;
                end else begin
                    ped_active = 0;	//no pedastrain
                    sec_left   = RED_TIME - sec_count;
                end
            end

        endcase
    end

    //Seven Segment Decoder (0-9)
    reg [6:0] seg;

    always @(*) begin
        case (sec_left)
            4'd0: seg = 7'b1000000;
            4'd1: seg = 7'b1111001;
            4'd2: seg = 7'b0100100;
            4'd3: seg = 7'b0110000;
            4'd4: seg = 7'b0011001;
            4'd5: seg = 7'b0010010;
            4'd6: seg = 7'b0000010;
            4'd7: seg = 7'b1111000;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0010000;
            default: seg = 7'b1111111; //blank
        endcase
    end

    assign HEX0 = seg;

    //LEDR Outputs
    assign LEDR[0] = car_green;
    assign LEDR[1] = car_yellow;
    assign LEDR[2] = car_red;     //solid red
    assign LEDR[3] = ped_active;  //BLINKS during pedestrian red
    assign LEDR[9:4] = 6'b000000; //off for all other LEDR (unused)

endmodule
