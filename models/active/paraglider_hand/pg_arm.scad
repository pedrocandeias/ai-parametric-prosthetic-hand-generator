// ===== namespaced bundle: paraglider/UnLimbited_Arm_paraglider_v2.1.scad (prefix ARM_) =====
//The UnLimbited Arm v2.1
//By Stephen Robert Davies & Drew Murray / Team UnLimbited
//Parametric multi-part 3d printable arm.
//
//The UnLimbited Arm by Team UnLimited is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
//www.teamunlimbited.org
//www.facebook.com/teamunlimbited
//email: hello@teamunlimbited.org

//updated 14/03/2017

// adjusted by Marcus Mendenhall, December 2020,
// to use 3mm screws for pins and to match the paraglider (a.k.a. flexible flyer) hand

//Parameters
//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

// - Preview Each Part
// [dispatcher-driven] part
// - Choose Left or Right Arm
// [dispatcher-driven] LeftRight
// - Wrist Joint to Fingertip (mm)
// [dispatcher-driven] HandLen
// - Wrist Joint to Elbow Crease (mm)
// [dispatcher-driven] ForearmLen
// - Bicep Circumference (mm)
// [dispatcher-driven] BicepCircum
// - Cuff Support Length (mm)
// [dispatcher-driven] CuffLength
// - Tension Pin Bolt Hole Diameter (mm)
// [dispatcher-driven] PinHoleDia


ARM_ArmVersion = "V2.1/";
ARM_HandPerc = round((ARM_HandLen / 135) * 100);
ARM_WristWidth = 0.72 * ARM_HandPerc;
ARM_Thickness = ARM_HandPerc * 0.02;
ARM_JointRadius = ARM_HandPerc * 0.16 /2;
ARM_JointOffset = ARM_HandPerc * 0.18 / 2;
ARM_JointOffset2 = ARM_HandPerc * 0.21 / 2;
ARM_ElbowWidth = (ARM_JointOffset / 2) + (ARM_BicepCircum / 2) + (ARM_HandPerc * 0.1); 
//elbowwidth has to account for raised arms on cuff, added to forearm at elbow. 
//Correct size should be Handperc * 0.2, but is too loose, feedback suggests this is a nice compromise.
ARM_ElbowWidthCuff = (ARM_BicepCircum / 2) + (ARM_JointOffset2 / 2); //joint offset added here*******
ARM_ArmLength = ARM_HandPerc * 0.40; //40 default
ARM_LevArmLen = ARM_HandPerc * 0.26;
ARM_CuffRadius = (ARM_BicepCircum / 3.1415926535897) /2;
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

//CUFF CODE
//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//joint module for drawing wrist and elbow joints
module ARM_Arm(x,y,r){
    translate ([x,y,0])
	difference (){
		union (){
			translate ([0,0,ARM_HandPerc * 0.1]) cylinder (r = r, h = ARM_Thickness*3.5);
			translate ([r * -1,((ARM_ArmLength + ARM_CuffLength) * -1) + r, 0]) cube ([r*2,ARM_CuffLength-r, ARM_Thickness*2]);
            translate ([r * -1,(ARM_ArmLength * -1) + ARM_Thickness * 1, -ARM_Thickness]) rotate ([45,0,0]) cube ([r*2,ARM_ArmLength *0.435, ARM_Thickness*4]);
            translate ([r * -1,ARM_ArmLength * -0.75, ARM_HandPerc * 0.1]) cube ([r*2,ARM_ArmLength*0.75, ARM_Thickness*2.2]);
            translate ([0,((ARM_ArmLength + ARM_CuffLength) * -1) + r, 0]) cylinder (r = r, h = ARM_Thickness*2);
		}
		translate ([0,0,ARM_HandPerc * 0.1]) cylinder (r = ARM_JointRadius + 0.5, h = ARM_Thickness * 1.4);
		translate ([0,0,ARM_HandPerc * 0.1]) cylinder (r = ARM_HandPerc * 0.03, h = ARM_Thickness * 4);
        //trim 45 angle piece underneath
        translate ([r * -1,ARM_ArmLength * -1, ARM_Thickness * -1 ]) cube ([r*2,ARM_ArmLength, ARM_Thickness*1]);
        //trim 45 angle piece ontop
        translate ([r * -1,ARM_ArmLength * -1, (ARM_HandPerc * 0.1) + (ARM_Thickness * 2.2)]) cube ([r*2,ARM_ArmLength *0.5, ARM_Thickness*2]);
	}
}

//Cuff module for drawing general forearm shape    
module ARM_CuffBody(){
    translate ([0,0,ARM_Thickness / 2]) linear_extrude(height = ARM_Thickness, center = true, convexity = 10, twist = 0) 
    polygon(points=[
	[ARM_ElbowWidthCuff / 2,0],
	[ARM_ElbowWidthCuff / 2* -1,0],
	[ARM_ElbowWidthCuff / 2* -1,ARM_CuffLength],
	[ARM_ElbowWidthCuff / 2,ARM_CuffLength],
	]);
}

module ARM_CuffSlot(){
	union(){
        cube ([5,15,ARM_Thickness + 30]);
        translate ([2.5,0,0]) cylinder (r = 2.5, h = ARM_Thickness + 30);
        translate ([2.5,15,0]) cylinder (r = 2.5, h = ARM_Thickness + 30);
		
	}
}

module ARM_TensionBlock()
{
	BlockX = ARM_JointRadius * 1.6;
	BlockY = ARM_HandPerc * 0.3;
	BlockZ = ARM_HandPerc * 0.12;
	PinXY = ARM_HandPerc * 0.05;
	PinLen = ARM_HandPerc * 0.4;
    
	difference()
	{
		union()
		{
			translate ([BlockX /2,BlockY,BlockZ]) rotate ([90,0,0]) cylinder (r = (BlockX) / 2, h = BlockY);
			cube([BlockX,BlockY,BlockZ]);
		}
		//TENSION BLOCK PIN CUT OUTS
		translate ([0,BlockY+(ARM_HandPerc*0.19),0])rotate ([125,0,0]) cube ([BlockX,BlockY+(ARM_HandPerc * 0.1),BlockZ]);
		translate ([(BlockX / 2) - (PinXY / 2), ARM_HandPerc * 0.02, BlockZ - (PinXY / 5)]) cube ([PinXY,PinLen,PinXY]); //Top Pin Hole
		translate ([(BlockX - PinXY) - (ARM_HandPerc * 0.01), ARM_HandPerc * 0.02, ARM_Thickness*2 + (ARM_HandPerc * 0.01)]) cube ([PinXY,PinLen,PinXY]); //Bottom Right Hole
		translate ([(BlockX - (PinXY * 2)) - (ARM_HandPerc * 0.02), ARM_HandPerc * 0.02, ARM_Thickness*2 + (ARM_HandPerc * 0.01)]) cube ([PinXY,PinLen,PinXY]); //Bottom Left Hole
		//TENSION BLOCK BOLT CUTOUTS
		translate ([(BlockX / 2) , 0, BlockZ - (PinXY / 5) + (PinXY / 2)]) rotate ([-90,90,0]) cylinder (r = (ARM_PinHoleDia / 2) + 0.2, h = PinLen - 8);
		translate ([(BlockX / 2) - (ARM_HandPerc * 0.005) - (PinXY / 2) , 0, ARM_Thickness*2 + (ARM_HandPerc * 0.01) + PinXY /2]) rotate ([-90,90,0]) cylinder (r = (ARM_PinHoleDia / 2) + 0.2, h = PinLen - 8);
		translate ([(BlockX / 2) + (ARM_HandPerc * 0.005) + (PinXY / 2) , 0, ARM_Thickness*2 + (ARM_HandPerc * 0.01) + PinXY /2]) rotate ([-90,90,0]) cylinder (r = (ARM_PinHoleDia / 2) + 0.2, h = PinLen - 8);
		
	}
}

module ARM_TensionPins()
{
	PinXY = (ARM_HandPerc * 0.046) - 0.4;
	PinLen = ARM_HandPerc * 0.35;
    difference(){
		union()
		{
			translate ([0,ARM_CuffLength + 4,0]) rotate ([0,0,0]) cube ([PinXY, PinLen, PinXY]);
			translate ([-PinXY - 4,ARM_CuffLength + 4,0]) rotate ([0,0,0]) cube ([PinXY, PinLen, PinXY]);
			translate ([(-PinXY * 2) - 8,ARM_CuffLength + 4,0]) rotate ([0,0,0]) cube ([PinXY, PinLen, PinXY]);
		}
		//string holes
		translate ([(-PinXY * 2) - 9,ARM_CuffLength + PinLen,PinXY / 2]) rotate ([0,90,0]) cylinder (r = PinXY / 3.5, h = ARM_Thickness * PinXY * 2 + 9);
		//Bolt holes
		translate ([PinXY / 2,ARM_CuffLength+4,PinXY / 2]) rotate ([-90,90,0]) cylinder (r = ARM_PinHoleDia / 2, h = PinLen - 8);
		translate ([(-PinXY - 4) + (PinXY / 2),ARM_CuffLength+4,PinXY / 2]) rotate ([-90,90,0]) cylinder (r = ARM_PinHoleDia / 2, h = PinLen - 8);
		translate ([(-PinXY * 2) - 8 + (PinXY / 2),ARM_CuffLength+4,PinXY / 2]) rotate ([-90,90,0]) cylinder (r = ARM_PinHoleDia / 2, h = PinLen - 8);
	}
}             

module ARM_LeverageArm (x,y,r)
{
	difference (){
		union()
		{
			translate ([x,y,0]) cylinder (r = r, h = ARM_Thickness*3.5);
			translate ([x,y - r,0]) cube ([ARM_LevArmLen, r*2,ARM_Thickness*3.5]);
		}
		translate ([ARM_LevArmLen +x,y,0]) cylinder (r = ARM_HandPerc * 0.03, h = ARM_Thickness * 3.5);
		translate ([x,y,0]) cylinder (r = ARM_HandPerc * 0.03, h = ARM_Thickness * 3.5);
	    translate ([ARM_LevArmLen +x,y,0]) cylinder (r = ARM_JointRadius + 0.5, h = ARM_Thickness * 1.4);
        translate ([(ARM_ElbowWidthCuff / 2) - ARM_LevArmLen - ARM_HandPerc * 0.03,y ,ARM_Thickness*1.5]) cube ([ARM_HandPerc * 0.06, ARM_JointOffset2,ARM_Thickness*2]);
        translate ([(ARM_ElbowWidthCuff / 2) - ARM_LevArmLen - ARM_HandPerc * 0.03,y + ARM_JointOffset2 * 0.5,ARM_Thickness*1.5]) cube ([ARM_JointOffset2,ARM_HandPerc * 0.06, ARM_Thickness*2]);
	}
	translate ([x + ARM_HandPerc * 0.08,y + ARM_HandPerc * 0.055,0]) cylinder (r = ARM_HandPerc * 0.05, h = ARM_Thickness*3.5);
}

module ARM_Curver (x, y, t, rot){
    rotate ([0,0,rot])
    difference (){
		cube ([x, y, t]);    
		cylinder (r = x, h = t);
	}
}

module ARM_DrawCuff(){
	difference(){

		//join the forearm shape and the joints    
		union()
		{
			//GENERATE CUFF SHAPE
			ARM_CuffBody();
			
			translate ([0,0,ARM_HandPerc * 0.1]) ARM_LeverageArm((ARM_ElbowWidthCuff / 2) - ARM_LevArmLen,ARM_CuffLength + ARM_ArmLength,ARM_JointOffset2);
			ARM_Arm(ARM_ElbowWidthCuff / 2,ARM_CuffLength + ARM_ArmLength,ARM_JointOffset2); //Arm Right
			ARM_Arm((ARM_ElbowWidthCuff / 2) * -1,ARM_CuffLength + ARM_ArmLength,ARM_JointOffset2); //Arm Left
			translate ([(ARM_ElbowWidthCuff / 2) - ARM_JointOffset2 *2,ARM_CuffLength + ARM_ArmLength - (ARM_JointOffset2 * 2),ARM_HandPerc * 0.1]) ARM_Curver(ARM_JointOffset2,ARM_JointOffset2, ARM_Thickness * 2.2, 360);
			translate ([(ARM_ElbowWidthCuff / 2) - ARM_JointOffset2,0,0]) ARM_TensionBlock();
			ARM_TensionPins();
			
		}
		translate ([((ARM_ElbowWidthCuff / 2) + 2.5 + (ARM_JointOffset2 / 2)) * -1,ARM_HandPerc * 0.1,0]) ARM_CuffSlot();
		translate ([((ARM_ElbowWidthCuff / 2) - 2.5 + (ARM_JointOffset2 / 2)),ARM_HandPerc * 0.1,0]) ARM_CuffSlot();
		translate ([((ARM_ElbowWidthCuff / 2) + 2.5 + (ARM_JointOffset2 / 2)) * -1,ARM_CuffLength - (ARM_HandPerc * 0.01) - 20,0]) ARM_CuffSlot();
		translate ([((ARM_ElbowWidthCuff / 2) - 2.5 + (ARM_JointOffset2 / 2)),ARM_CuffLength - (ARM_HandPerc * 0.01) - 20,0]) ARM_CuffSlot();
		//tenson hole through arm
		translate ([(ARM_ElbowWidthCuff / 2) - (ARM_JointOffset2 / 3), ARM_CuffLength + (ARM_Thickness * 2), ARM_HandPerc * 0.1]) rotate ([45,0,0])  cylinder (r = ARM_HandPerc * 0.02, h = ARM_Thickness * 10, center = true);
		
	}
}
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

//FOREARM CODE
//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//joint module for drawing wrist and elbow joints
module ARM_joint(x,y,r,t,o){
    translate ([x,y,0])
	union(){
        cylinder (r = r, h = t + t);
        cylinder (r = o, h = ARM_Thickness);
	}
}

//forearm module for drawing general forearm shape    
module ARM_forearm(){
    translate ([0,0,ARM_Thickness / 2]) linear_extrude(height = ARM_Thickness, center = true, convexity = 10, twist = 0) 
    polygon(points=[
	[((ARM_ElbowWidth * 0.5) + ARM_JointRadius) ,ARM_JointOffset / -2],  //bottom right
	[(((ARM_ElbowWidth * 0.5) + ARM_JointRadius) * -1) ,ARM_JointOffset / -2], //bottom left
	[ARM_JointRadius * -0.5,ARM_ForearmLen + (ARM_HandPerc * 0.08)],//top left
	[ARM_WristWidth + ARM_JointOffset,ARM_ForearmLen + (ARM_HandPerc * 0.13)], //top right top
	[ARM_WristWidth + ARM_JointOffset,ARM_ForearmLen - (ARM_HandPerc * 0.04)], //top right bot 
	[(ARM_WristWidth / 2) * 1.45 , ARM_ForearmLen * 0.958],
	]);
}

//add tendon path
module ARM_tendonpath(){  
	translate ([ARM_BicepCircum / 8,(ARM_HandPerc * 0.2),ARM_HandPerc * 0.02]) 
    rotate(a=[-90,0,0]){
		difference(){
			union(){
				cylinder (r = (ARM_HandPerc * 0.05), h = ARM_ForearmLen - (ARM_HandPerc * 0.3));
				//give the tendon guide a sloping edge
				translate ([ARM_HandPerc * 0.026,ARM_HandPerc * 0.01,0]) rotate(a=[0,0,-45]){ cube([ARM_HandPerc * 0.03,ARM_HandPerc * 0.03,ARM_ForearmLen - (ARM_HandPerc * 0.3)]);}
					translate ([ARM_HandPerc * -0.07,ARM_HandPerc * 0.001,0]) rotate(a=[0,0,-45]){ cube([ARM_HandPerc * 0.05,ARM_HandPerc * 0.05,ARM_ForearmLen - (ARM_HandPerc * 0.3)]);}
					}
					cylinder (r = (ARM_HandPerc * 0.03), h = ARM_ForearmLen);
					translate ([ARM_HandPerc * (- 0.08),ARM_HandPerc * 0.01,0]) cube([ARM_HandPerc * 0.2,ARM_HandPerc * 0.19,ARM_ForearmLen]);        
				}
			}
			
}
		
//generate center slots at 20mm x 5mm
//join circles to each end of rectangle to create slot
module ARM_CenterSlot(){
	for (i =[5:25:ARM_ForearmLen - (ARM_JointOffset* 8)]){
		translate ([2.5,i,0])
		union(){
			cube ([5,15,ARM_Thickness + 30]);
			translate ([2.5,0,0]) cylinder (r = 2.5, h = ARM_Thickness + 30, $fn=40);
			translate ([2.5,15,0]) cylinder (r = 2.5, h = ARM_Thickness + 30, $fn=40);
		}
		translate ([-7.5,i,0])
		union(){
			cube ([5,15,ARM_Thickness + 30]);
			translate ([2.5,0,0]) cylinder (r = 2.5, h = ARM_Thickness + 30, $fn=40);
			translate ([2.5,15,0]) cylinder (r = 2.5, h = ARM_Thickness + 30, $fn=40);
		}
	}
}
		
		
module ARM_RightSlots(){
	//grab angle of left edge of forearm using atan2
	x2 = (ARM_WristWidth / 2) * 1.45;
	y2 = ARM_ForearmLen * 0.958;
	x1 = (ARM_ElbowWidth * 0.575);
	y1 = ARM_JointOffset / -2;
	RightAngle = atan2(y1 - y2, x2 - x1);
	//
	rotate ([0,0,270 - RightAngle])
	for (i =[ARM_JointOffset + 5:25:ARM_ForearmLen * 0.85]){
		translate ([0,i,0])
		union(){
			cube ([5,15,ARM_Thickness + 30]);
			translate ([2.5,0,0]) cylinder (r = 2.5, h = ARM_Thickness + 30, $fn=40);
			translate ([2.5,15,0]) cylinder (r = 2.5, h = ARM_Thickness + 30, $fn=40);
		}
	}
}
		
module ARM_LeftSlots(){
	//grab angle of left edge of forearm using atan2
	x1 = ARM_ElbowWidth * -0.575;
	y1 = ARM_JointOffset / -2;
	x2 = ARM_JointRadius * -0.51;
	y2 = ARM_ForearmLen + (ARM_HandPerc * 0.08);
	LeftAngle = atan2(y1 - y2, x2 - x1);
	//
	rotate ([0,0,270 - LeftAngle])
	for (i =[ARM_JointOffset + 5:25:ARM_ForearmLen * 0.85]){
		translate ([0,i,0])
		union(){
			cube ([5,15,ARM_Thickness + 30]);
			translate ([2.5,0,0]) cylinder (r = 2.5, h = ARM_Thickness + 30, $fn=40);
			translate ([2.5,15,0]) cylinder (r = 2.5, h = ARM_Thickness + 30, $fn=40);
		}
	}
}
		
//Wrist support module
module ARM_WristSupport(){
	SupportHeight = ARM_HandPerc * 0.10;
	difference(){  
		union(){
			cylinder (r = ARM_JointOffset + (ARM_HandPerc * 0.04), SupportHeight);
			translate ([(ARM_JointOffset + (ARM_HandPerc * 0.04)) * -1,0,0]) cube ([5,ARM_JointRadius,SupportHeight]);
		}
		cylinder (r = ARM_JointOffset, SupportHeight);
		translate ([ARM_JointOffset * -1,0,0]) cube ([ARM_JointOffset * 3,ARM_JointOffset * 2,SupportHeight]);
	}
}  
		
module ARM_Curve (siz, t, rot){
	rotate ([0,0,rot])
	difference (){
		cube ([siz + 2, siz + 2, t]);    
		cylinder (r = siz, h = t);
	}
}
		
module ARM_DrawForearm(){
//cut out the pin holes from the joints
	difference(){
		//join the forearm shape and the joints    
		union(){
			//GENERATE FOREARM SHAPE
			ARM_forearm();
			//ADD JOINTS
			*ARM_joint(0,ARM_ForearmLen,ARM_JointRadius,ARM_Thickness,ARM_JointOffset); //wrist top left
			*ARM_joint(ARM_WristWidth,ARM_ForearmLen+(ARM_HandPerc * 0.05),ARM_JointRadius,ARM_Thickness,ARM_JointRadius); //wrist top right
			ARM_joint(ARM_ElbowWidth / 2 ,0,ARM_JointRadius,ARM_Thickness,ARM_JointOffset+(ARM_HandPerc * 0.01)); //elbow bottom right
			ARM_joint((ARM_ElbowWidth / 2) - ARM_ElbowWidth ,0,ARM_JointRadius,ARM_Thickness,ARM_JointOffset+(ARM_HandPerc * 0.01)); //elbow bottom left
			
			//ADD WRIST SUPPORTS
			x1 = 0;
			y1 = ARM_ForearmLen;
			x2 = ARM_WristWidth;
			y2 = ARM_ForearmLen+(ARM_HandPerc * 0.05);
			angle = atan2(y1 - y2, x2 - x1);
			translate ([0,ARM_ForearmLen,0]) rotate ([0,0,360-angle]) ARM_WristSupport();
			translate ([ARM_WristWidth,ARM_ForearmLen+(ARM_HandPerc * 0.05),ARM_HandPerc * 0.10]) rotate ([0,180,360 - angle]) ARM_WristSupport();
			translate ([(ARM_WristWidth / 2) * 1.48 + ARM_JointRadius , (ARM_ForearmLen * 0.956) - ARM_JointRadius,0]) ARM_Curve (ARM_JointOffset, ARM_Thickness, 90);
			}
			//5x5 cut out
			//translate ([0,ForearmLen,0]) cube([HandPerc * 0.05,HandPerc * 0.05,HandPerc * 0.09], center=true);
			//translate ([WristWidth,ForearmLen+(HandPerc * 0.05),0]) cube([HandPerc * 0.05,HandPerc * 0.05,HandPerc * 0.09], center=true);
			//translate ([ElbowWidth / 2 ,0,0]) cube([HandPerc * 0.05,HandPerc * 0.05,HandPerc * 0.09], center=true);
			//translate ([(ElbowWidth / 2) - ElbowWidth ,0,0]) cube([HandPerc * 0.05,HandPerc * 0.05,HandPerc * 0.09], center=true);
			//EXPERIMENTAL, REPLACE SQUARES WITH HOLES FOR EASIER ASSEMBLY.
			translate ([0,ARM_ForearmLen,0]) cylinder (r = ARM_HandPerc * 0.03, h = ARM_Thickness * 4);
			translate ([ARM_WristWidth,ARM_ForearmLen+(ARM_HandPerc * 0.05),0]) cylinder (r = ARM_HandPerc * 0.03, h = ARM_Thickness * 4);
			translate ([ARM_ElbowWidth / 2 ,0,0]) cylinder (r = ARM_HandPerc * 0.03, h = ARM_Thickness * 4);
			translate ([(ARM_ElbowWidth / 2) - ARM_ElbowWidth ,0,0]) cylinder (r = ARM_HandPerc * 0.03, h = ARM_Thickness * 4);
			//
			//5x7.6 cut out
			translate ([0,ARM_ForearmLen,0]) cube([ARM_HandPerc * 0.076,ARM_HandPerc * 0.05,ARM_HandPerc * 0.038], center=true);
			translate ([ARM_WristWidth,ARM_ForearmLen+(ARM_HandPerc * 0.05),0]) cube([ARM_HandPerc * 0.076,ARM_HandPerc * 0.05,ARM_HandPerc * 0.038], center=true);
			translate ([ARM_ElbowWidth / 2 ,0,0]) cube([ARM_HandPerc * 0.076,ARM_HandPerc * 0.05,ARM_HandPerc * 0.038], center=true);
			translate ([(ARM_ElbowWidth / 2) - ARM_ElbowWidth ,0,0]) cube([ARM_HandPerc * 0.076,ARM_HandPerc * 0.05,ARM_HandPerc * 0.038], center=true);
			ARM_CenterSlot();
			translate([((ARM_ElbowWidth / 2) + ARM_JointRadius - 6 ) * -1,0,0]) ARM_LeftSlots();
			translate([(ARM_ElbowWidth / 2) + ARM_JointRadius - 9,0,0]) ARM_RightSlots();
			}
			//align tendon path to middle of wrist
			x1 = ARM_BicepCircum / 8;
			y1 = ARM_HandPerc * 0.1;
			x2 = ARM_WristWidth / 2;
			y2 = ARM_ForearmLen+(ARM_HandPerc * 0.05);
			angle = atan2(y1 - y2, x2 - x1);
			//echo (angle);
			rotate([0,0,270 - angle]) ARM_tendonpath();	
}
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

//JIG CODE
//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
module ARM_Jig(){
	difference (){
	union(){
     cylinder (r = ARM_CuffRadius, h = ARM_CuffLength); //main body
     
	 //add round bits
	 translate ([ARM_CuffRadius - (ARM_Thickness * 2),0,ARM_CuffLength + ARM_ArmLength ])
	 rotate ([0,90,0])
	 union(){
			cylinder (r = ARM_JointOffset, h = ARM_HandPerc * 0.1 + ARM_Thickness * 2);
			cylinder (r = ARM_HandPerc * 0.025, h = ARM_HandPerc * 0.18 + ARM_Thickness * 2);
	 }
	 translate ([(ARM_CuffRadius * -1) + ARM_Thickness * 2,0,ARM_CuffLength + ARM_ArmLength ]) 
	 rotate ([180,90,0]) 
	 union (){
	 cylinder (r = ARM_JointOffset, h = ARM_HandPerc * 0.1 + ARM_Thickness * 2);
	 cylinder (r = ARM_HandPerc * 0.025, h = ARM_HandPerc * 0.18 + ARM_Thickness * 2);
	 }
	}
	union(){
	cylinder (r = ARM_CuffRadius - ARM_Thickness * 2, h = ARM_CuffLength); //main body	
	translate ([ARM_CuffRadius * -1,0,0]) cube ([ARM_CuffRadius * 2,ARM_CuffRadius * 2,ARM_CuffLength]);
	}
}
}

module ARM_DrawJig(){
translate ([0,0,ARM_JointOffset])
rotate ([90,180,])
union(){
ARM_Jig();
translate ([ARM_CuffRadius - (ARM_Thickness * 2),ARM_JointOffset * -1,0]) cube ([ARM_Thickness * 2,ARM_JointOffset * 2,ARM_CuffLength + ARM_ArmLength ]); //right arm
translate ([ARM_CuffRadius * -1,ARM_JointOffset * -1,0]) cube ([ARM_Thickness * 2,ARM_JointOffset * 2,ARM_CuffLength + ARM_ArmLength ]); //left arm
translate ([ARM_CuffRadius * -1,ARM_JointOffset - ARM_Thickness * 2,0]) cube ([ARM_CuffRadius * 2,ARM_Thickness * 2,ARM_JointOffset]); //left arm
translate ([ARM_CuffRadius * -1,ARM_JointOffset - ARM_Thickness * 2,ARM_CuffLength]) cube ([ARM_CuffRadius * 2,ARM_Thickness * 2,ARM_JointOffset]); //left arm
}
}
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


module ARM_add_text(){
    //add version number and measurements for reference
		MyTxt = (str(ARM_ArmVersion,ARM_BicepCircum,ARM_ForearmLen,ARM_HandLen,"/" ,ARM_HandPerc,"%"));
		translate ([(ARM_ElbowWidthCuff / 2) * -1,2,0]) mirror ([1,0,0]) rotate ([0,0,90]) #linear_extrude(height = 0.6, center = true, convexity = 10, twist = 0) 
        text(MyTxt, halign="left", size = 4, font = "Arial");
}
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

// code pulled from thermogauntlet.scad for conical bearings
ARM_bearing_washer_dia=16;
ARM_hole_clearance=1.0;

ARM_bearing_big_dia=10*ARM_HandPerc/100.;
ARM_bearing_little_dia=8*ARM_HandPerc/100.;
ARM_bearing_plastic_thickness=0.5;
ARM_bearing_screw_dia=3 + ARM_hole_clearance;  // 3mm screw with clearance
ARM_bearing_screw_head_dia=5.8 + ARM_hole_clearance; // 5.6mm screw head, 5.8mm washer, with clearance
ARM_bearing_screw_head_depth=2.5;

ARM_bearing_depth=2;

// coordinates for wrist bearings, from above
//joint(0,ForearmLen,JointRadius,Thickness,JointOffset); //wrist top left
//joint(WristWidth,ForearmLen+(HandPerc * 0.05),JointRadius,Thickness,JointRadius);

module ARM_do_wrist() {    
    pin_coordinates=[[0,ARM_ForearmLen,0], [ARM_WristWidth,ARM_ForearmLen+(ARM_HandPerc * 0.05),0]];
    sthick=ARM_bearing_plastic_thickness;
    gauntlet_thickness=ARM_Thickness+1; // from forearm() module, with extra meat for strength
    global_scale=1; // scaling handled elsewhere
    difference() {
        union() {
            children();
            for(center=pin_coordinates)
                translate(center) {
                $fn=50;
                translate([0,0,-sthick/0.5+gauntlet_thickness-0.01]) // cylinder wall slope is 0.5
                    cylinder(d1=ARM_bearing_big_dia, d2=ARM_bearing_little_dia, h=2);
                cylinder(r=ARM_JointRadius*1.125, h=gauntlet_thickness);
            }
        }
        for(center=pin_coordinates)
            translate(center) {
            $fn=20;
            cylinder(d=ARM_bearing_screw_dia, h=20);
            cylinder(d=ARM_bearing_screw_head_dia, h=ARM_bearing_screw_head_depth);
        }
    }
    // supports for flying hole
    for(center=pin_coordinates)
        translate(center) {
        $fn=20;
        cylinder(d=ARM_bearing_screw_head_dia-1, h=ARM_bearing_screw_head_depth-0.25);
    }
}

//OK LETS GENERATE PARTS
//**************************************************
//**************************************************
module ARM_print_part() {
	if (ARM_part == "Forearm") {
		if (ARM_LeftRight == "Left") {
            ARM_do_wrist() ARM_DrawForearm();} 
        else {mirror ([1,0,0]) ARM_do_wrist() ARM_DrawForearm();}
	} else if (ARM_part == "Cuff") {
		if (ARM_LeftRight == "Left") {
            difference(){
            ARM_DrawCuff();
            ARM_add_text();
            }
            } else {
              difference(){
                mirror ([1,0,0]) ARM_DrawCuff();
                ARM_add_text();
              }
        }
	} else if (ARM_part == "Jig") {
		if (ARM_LeftRight == "Left") {ARM_DrawJig();} else {mirror ([1,0,0]) ARM_DrawJig();}
	}
}
//**************************************************
//**************************************************


module ARM_main() {
$fn = 50;

ARM_print_part();
}
