function [9:0] get_offset_x;
	input [6:0] panning_x_ctrl_2d;
	case (panning_x_ctrl_2d)
		0: get_offset_x = 10'd0;
		1: get_offset_x = 10'd20;
		2: get_offset_x = 10'd40;
		3: get_offset_x = 10'd60;
		4: get_offset_x = 10'd80;
		5: get_offset_x = 10'd100;
		6: get_offset_x = 10'd120;
		7: get_offset_x = 10'd140;
		8: get_offset_x = 10'd160;
		9: get_offset_x = 10'd180;
		10: get_offset_x = 10'd200;
		11: get_offset_x = 10'd220;
		12: get_offset_x = 10'd240;
		13: get_offset_x = 10'd260;
		14: get_offset_x = 10'd280;
		15: get_offset_x = 10'd300;
		16: get_offset_x = 10'd320;
		17: get_offset_x = 10'd340;
		18: get_offset_x = 10'd360;
		19: get_offset_x = 10'd380;
		20: get_offset_x = 10'd400;
		21: get_offset_x = 10'd420;
		22: get_offset_x = 10'd440;
		23: get_offset_x = 10'd460;
		24: get_offset_x = 10'd480;
		25: get_offset_x = 10'd500;
		26: get_offset_x = 10'd520;
		27: get_offset_x = 10'd540;
		28: get_offset_x = 10'd560;
		29: get_offset_x = 10'd580;
		30: get_offset_x = 10'd600;
		31: get_offset_x = 10'd620;
		32: get_offset_x = 10'd640;
		33: get_offset_x = 10'd620;
		34: get_offset_x = 10'd600;
		35: get_offset_x = 10'd580;
		36: get_offset_x = 10'd560;
		37: get_offset_x = 10'd540;
		38: get_offset_x = 10'd520;
		39: get_offset_x = 10'd500;
		40: get_offset_x = 10'd480;
		41: get_offset_x = 10'd460;
		42: get_offset_x = 10'd440;
		43: get_offset_x = 10'd420;
		44: get_offset_x = 10'd400;
		45: get_offset_x = 10'd380;
		46: get_offset_x = 10'd360;
		47: get_offset_x = 10'd340;
		48: get_offset_x = 10'd320;
		49: get_offset_x = 10'd300;
		50: get_offset_x = 10'd280;
		51: get_offset_x = 10'd260;
		52: get_offset_x = 10'd240;
		53: get_offset_x = 10'd220;
		54: get_offset_x = 10'd200;
		55: get_offset_x = 10'd180;
		56: get_offset_x = 10'd160;
		57: get_offset_x = 10'd140;
		58: get_offset_x = 10'd120;
		59: get_offset_x = 10'd100;
		60: get_offset_x = 10'd80;
		61: get_offset_x = 10'd60;
		62: get_offset_x = 10'd40;
		63: get_offset_x = 10'd20;
		64: get_offset_x = 10'd0;
	endcase
endfunction