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
part = "Cuff"; // [Forearm:Forearm Only,Cuff:Cuff Only,Jig:Jig Only,Palm:Palm Only,Fingers:Fingers Only,Phalanx: Phalanx Only,Pins: Pins Only]
// - Choose Left or Right Arm
LeftRight = "Left"; // [Left,Right]
// - Wrist Joint to Fingertip (mm)
HandLen = 135; //[135:230]
// - Wrist Joint to Elbow Crease (mm)
ForearmLen = 140; //[120:315]
// - Bicep Circumference (mm)
BicepCircum = 160; //[110:350]
// - Cuff Support Length (mm)
CuffLength = 65; //[65:90]
// - Tension Pin Bolt Hole Diameter (mm)
PinHoleDia = 3; //[3:6]

/* [Hidden] */
ArmVersion = "V2.1/";
HandPerc = round((HandLen / 135) * 100);
WristWidth = 0.72 * HandPerc;
Thickness = HandPerc * 0.02;
JointRadius = HandPerc * 0.16 /2;
JointOffset = HandPerc * 0.18 / 2;
JointOffset2 = HandPerc * 0.21 / 2;
ElbowWidth = (JointOffset / 2) + (BicepCircum / 2) + (HandPerc * 0.1); 
//elbowwidth has to account for raised arms on cuff, added to forearm at elbow. 
//Correct size should be Handperc * 0.2, but is too loose, feedback suggests this is a nice compromise.
ElbowWidthCuff = (BicepCircum / 2) + (JointOffset2 / 2); //joint offset added here*******
ArmLength = HandPerc * 0.40; //40 default
LevArmLen = HandPerc * 0.26;
CuffRadius = (BicepCircum / 3.1415926535897) /2;
$fn = 50;
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

//CUFF CODE
//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//joint module for drawing wrist and elbow joints
module Arm(x,y,r){
    translate ([x,y,0])
	difference (){
		union (){
			translate ([0,0,HandPerc * 0.1]) cylinder (r = r, h = Thickness*3.5);
			translate ([r * -1,((ArmLength + CuffLength) * -1) + r, 0]) cube ([r*2,CuffLength-r, Thickness*2]);
            translate ([r * -1,(ArmLength * -1) + Thickness * 1, -Thickness]) rotate ([45,0,0]) cube ([r*2,ArmLength *0.435, Thickness*4]);
            translate ([r * -1,ArmLength * -0.75, HandPerc * 0.1]) cube ([r*2,ArmLength*0.75, Thickness*2.2]);
            translate ([0,((ArmLength + CuffLength) * -1) + r, 0]) cylinder (r = r, h = Thickness*2);
		}
		translate ([0,0,HandPerc * 0.1]) cylinder (r = JointRadius + 0.5, h = Thickness * 1.4);
		translate ([0,0,HandPerc * 0.1]) cylinder (r = HandPerc * 0.03, h = Thickness * 4);
        //trim 45 angle piece underneath
        translate ([r * -1,ArmLength * -1, Thickness * -1 ]) cube ([r*2,ArmLength, Thickness*1]);
        //trim 45 angle piece ontop
        translate ([r * -1,ArmLength * -1, (HandPerc * 0.1) + (Thickness * 2.2)]) cube ([r*2,ArmLength *0.5, Thickness*2]);
	}
}

//Cuff module for drawing general forearm shape    
module CuffBody(){
    translate ([0,0,Thickness / 2]) linear_extrude(height = Thickness, center = true, convexity = 10, twist = 0) 
    polygon(points=[
	[ElbowWidthCuff / 2,0],
	[ElbowWidthCuff / 2* -1,0],
	[ElbowWidthCuff / 2* -1,CuffLength],
	[ElbowWidthCuff / 2,CuffLength],
	]);
}

module CuffSlot(){
	union(){
        cube ([5,15,Thickness + 30]);
        translate ([2.5,0,0]) cylinder (r = 2.5, h = Thickness + 30);
        translate ([2.5,15,0]) cylinder (r = 2.5, h = Thickness + 30);
		
	}
}

module TensionBlock()
{
	BlockX = JointRadius * 1.6;
	BlockY = HandPerc * 0.3;
	BlockZ = HandPerc * 0.12;
	PinXY = HandPerc * 0.05;
	PinLen = HandPerc * 0.4;
    
	difference()
	{
		union()
		{
			translate ([BlockX /2,BlockY,BlockZ]) rotate ([90,0,0]) cylinder (r = (BlockX) / 2, h = BlockY);
			cube([BlockX,BlockY,BlockZ]);
		}
		//TENSION BLOCK PIN CUT OUTS
		translate ([0,BlockY+(HandPerc*0.19),0])rotate ([125,0,0]) cube ([BlockX,BlockY+(HandPerc * 0.1),BlockZ]);
		translate ([(BlockX / 2) - (PinXY / 2), HandPerc * 0.02, BlockZ - (PinXY / 5)]) cube ([PinXY,PinLen,PinXY]); //Top Pin Hole
		translate ([(BlockX - PinXY) - (HandPerc * 0.01), HandPerc * 0.02, Thickness*2 + (HandPerc * 0.01)]) cube ([PinXY,PinLen,PinXY]); //Bottom Right Hole
		translate ([(BlockX - (PinXY * 2)) - (HandPerc * 0.02), HandPerc * 0.02, Thickness*2 + (HandPerc * 0.01)]) cube ([PinXY,PinLen,PinXY]); //Bottom Left Hole
		//TENSION BLOCK BOLT CUTOUTS
		translate ([(BlockX / 2) , 0, BlockZ - (PinXY / 5) + (PinXY / 2)]) rotate ([-90,90,0]) cylinder (r = (PinHoleDia / 2) + 0.2, h = PinLen - 8);
		translate ([(BlockX / 2) - (HandPerc * 0.005) - (PinXY / 2) , 0, Thickness*2 + (HandPerc * 0.01) + PinXY /2]) rotate ([-90,90,0]) cylinder (r = (PinHoleDia / 2) + 0.2, h = PinLen - 8);
		translate ([(BlockX / 2) + (HandPerc * 0.005) + (PinXY / 2) , 0, Thickness*2 + (HandPerc * 0.01) + PinXY /2]) rotate ([-90,90,0]) cylinder (r = (PinHoleDia / 2) + 0.2, h = PinLen - 8);
		
	}
}

module TensionPins()
{
	PinXY = (HandPerc * 0.046) - 0.4;
	PinLen = HandPerc * 0.35;
    difference(){
		union()
		{
			translate ([0,CuffLength + 4,0]) rotate ([0,0,0]) cube ([PinXY, PinLen, PinXY]);
			translate ([-PinXY - 4,CuffLength + 4,0]) rotate ([0,0,0]) cube ([PinXY, PinLen, PinXY]);
			translate ([(-PinXY * 2) - 8,CuffLength + 4,0]) rotate ([0,0,0]) cube ([PinXY, PinLen, PinXY]);
		}
		//string holes
		translate ([(-PinXY * 2) - 9,CuffLength + PinLen,PinXY / 2]) rotate ([0,90,0]) cylinder (r = PinXY / 3.5, h = Thickness * PinXY * 2 + 9);
		//Bolt holes
		translate ([PinXY / 2,CuffLength+4,PinXY / 2]) rotate ([-90,90,0]) cylinder (r = PinHoleDia / 2, h = PinLen - 8);
		translate ([(-PinXY - 4) + (PinXY / 2),CuffLength+4,PinXY / 2]) rotate ([-90,90,0]) cylinder (r = PinHoleDia / 2, h = PinLen - 8);
		translate ([(-PinXY * 2) - 8 + (PinXY / 2),CuffLength+4,PinXY / 2]) rotate ([-90,90,0]) cylinder (r = PinHoleDia / 2, h = PinLen - 8);
	}
}             

module LeverageArm (x,y,r)
{
	difference (){
		union()
		{
			translate ([x,y,0]) cylinder (r = r, h = Thickness*3.5);
			translate ([x,y - r,0]) cube ([LevArmLen, r*2,Thickness*3.5]);
		}
		translate ([LevArmLen +x,y,0]) cylinder (r = HandPerc * 0.03, h = Thickness * 3.5);
		translate ([x,y,0]) cylinder (r = HandPerc * 0.03, h = Thickness * 3.5);
	    translate ([LevArmLen +x,y,0]) cylinder (r = JointRadius + 0.5, h = Thickness * 1.4);
        translate ([(ElbowWidthCuff / 2) - LevArmLen - HandPerc * 0.03,y ,Thickness*1.5]) cube ([HandPerc * 0.06, JointOffset2,Thickness*2]);
        translate ([(ElbowWidthCuff / 2) - LevArmLen - HandPerc * 0.03,y + JointOffset2 * 0.5,Thickness*1.5]) cube ([JointOffset2,HandPerc * 0.06, Thickness*2]);
	}
	translate ([x + HandPerc * 0.08,y + HandPerc * 0.055,0]) cylinder (r = HandPerc * 0.05, h = Thickness*3.5);
}

module Curver (x, y, t, rot){
    rotate ([0,0,rot])
    difference (){
		cube ([x, y, t]);    
		cylinder (r = x, h = t);
	}
}

module DrawCuff(){
	difference(){

		//join the forearm shape and the joints    
		union()
		{
			//GENERATE CUFF SHAPE
			CuffBody();
			
			translate ([0,0,HandPerc * 0.1]) LeverageArm((ElbowWidthCuff / 2) - LevArmLen,CuffLength + ArmLength,JointOffset2);
			Arm(ElbowWidthCuff / 2,CuffLength + ArmLength,JointOffset2); //Arm Right
			Arm((ElbowWidthCuff / 2) * -1,CuffLength + ArmLength,JointOffset2); //Arm Left
			translate ([(ElbowWidthCuff / 2) - JointOffset2 *2,CuffLength + ArmLength - (JointOffset2 * 2),HandPerc * 0.1]) Curver(JointOffset2,JointOffset2, Thickness * 2.2, 360);
			translate ([(ElbowWidthCuff / 2) - JointOffset2,0,0]) TensionBlock();
			TensionPins();
			
		}
		translate ([((ElbowWidthCuff / 2) + 2.5 + (JointOffset2 / 2)) * -1,HandPerc * 0.1,0]) CuffSlot();
		translate ([((ElbowWidthCuff / 2) - 2.5 + (JointOffset2 / 2)),HandPerc * 0.1,0]) CuffSlot();
		translate ([((ElbowWidthCuff / 2) + 2.5 + (JointOffset2 / 2)) * -1,CuffLength - (HandPerc * 0.01) - 20,0]) CuffSlot();
		translate ([((ElbowWidthCuff / 2) - 2.5 + (JointOffset2 / 2)),CuffLength - (HandPerc * 0.01) - 20,0]) CuffSlot();
		//tenson hole through arm
		translate ([(ElbowWidthCuff / 2) - (JointOffset2 / 3), CuffLength + (Thickness * 2), HandPerc * 0.1]) rotate ([45,0,0])  cylinder (r = HandPerc * 0.02, h = Thickness * 10, center = true);
		
	}
}
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

//FOREARM CODE
//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//joint module for drawing wrist and elbow joints
module joint(x,y,r,t,o){
    translate ([x,y,0])
	union(){
        cylinder (r = r, h = t + t);
        cylinder (r = o, h = Thickness);
	}
}

//forearm module for drawing general forearm shape    
module forearm(){
    translate ([0,0,Thickness / 2]) linear_extrude(height = Thickness, center = true, convexity = 10, twist = 0) 
    polygon(points=[
	[((ElbowWidth * 0.5) + JointRadius) ,JointOffset / -2],  //bottom right
	[(((ElbowWidth * 0.5) + JointRadius) * -1) ,JointOffset / -2], //bottom left
	[JointRadius * -0.5,ForearmLen + (HandPerc * 0.08)],//top left
	[WristWidth + JointOffset,ForearmLen + (HandPerc * 0.13)], //top right top
	[WristWidth + JointOffset,ForearmLen - (HandPerc * 0.04)], //top right bot 
	[(WristWidth / 2) * 1.45 , ForearmLen * 0.958],
	]);
}

//add tendon path
module tendonpath(){  
	translate ([BicepCircum / 8,(HandPerc * 0.2),HandPerc * 0.02]) 
    rotate(a=[-90,0,0]){
		difference(){
			union(){
				cylinder (r = (HandPerc * 0.05), h = ForearmLen - (HandPerc * 0.3));
				//give the tendon guide a sloping edge
				translate ([HandPerc * 0.026,HandPerc * 0.01,0]) rotate(a=[0,0,-45]){ cube([HandPerc * 0.03,HandPerc * 0.03,ForearmLen - (HandPerc * 0.3)]);}
					translate ([HandPerc * -0.07,HandPerc * 0.001,0]) rotate(a=[0,0,-45]){ cube([HandPerc * 0.05,HandPerc * 0.05,ForearmLen - (HandPerc * 0.3)]);}
					}
					cylinder (r = (HandPerc * 0.03), h = ForearmLen);
					translate ([HandPerc * (- 0.08),HandPerc * 0.01,0]) cube([HandPerc * 0.2,HandPerc * 0.19,ForearmLen]);        
				}
			}
			
}
		
//generate center slots at 20mm x 5mm
//join circles to each end of rectangle to create slot
module CenterSlot(){
	for (i =[5:25:ForearmLen - (JointOffset* 8)]){
		translate ([2.5,i,0])
		union(){
			cube ([5,15,Thickness + 30]);
			translate ([2.5,0,0]) cylinder (r = 2.5, h = Thickness + 30, $fn=40);
			translate ([2.5,15,0]) cylinder (r = 2.5, h = Thickness + 30, $fn=40);
		}
		translate ([-7.5,i,0])
		union(){
			cube ([5,15,Thickness + 30]);
			translate ([2.5,0,0]) cylinder (r = 2.5, h = Thickness + 30, $fn=40);
			translate ([2.5,15,0]) cylinder (r = 2.5, h = Thickness + 30, $fn=40);
		}
	}
}
		
		
module RightSlots(){
	//grab angle of left edge of forearm using atan2
	x2 = (WristWidth / 2) * 1.45;
	y2 = ForearmLen * 0.958;
	x1 = (ElbowWidth * 0.575);
	y1 = JointOffset / -2;
	RightAngle = atan2(y1 - y2, x2 - x1);
	//
	rotate ([0,0,270 - RightAngle])
	for (i =[JointOffset + 5:25:ForearmLen * 0.85]){
		translate ([0,i,0])
		union(){
			cube ([5,15,Thickness + 30]);
			translate ([2.5,0,0]) cylinder (r = 2.5, h = Thickness + 30, $fn=40);
			translate ([2.5,15,0]) cylinder (r = 2.5, h = Thickness + 30, $fn=40);
		}
	}
}
		
module LeftSlots(){
	//grab angle of left edge of forearm using atan2
	x1 = ElbowWidth * -0.575;
	y1 = JointOffset / -2;
	x2 = JointRadius * -0.51;
	y2 = ForearmLen + (HandPerc * 0.08);
	LeftAngle = atan2(y1 - y2, x2 - x1);
	//
	rotate ([0,0,270 - LeftAngle])
	for (i =[JointOffset + 5:25:ForearmLen * 0.85]){
		translate ([0,i,0])
		union(){
			cube ([5,15,Thickness + 30]);
			translate ([2.5,0,0]) cylinder (r = 2.5, h = Thickness + 30, $fn=40);
			translate ([2.5,15,0]) cylinder (r = 2.5, h = Thickness + 30, $fn=40);
		}
	}
}
		
//Wrist support module
module WristSupport(){
	SupportHeight = HandPerc * 0.10;
	difference(){  
		union(){
			cylinder (r = JointOffset + (HandPerc * 0.04), SupportHeight);
			translate ([(JointOffset + (HandPerc * 0.04)) * -1,0,0]) cube ([5,JointRadius,SupportHeight]);
		}
		cylinder (r = JointOffset, SupportHeight);
		translate ([JointOffset * -1,0,0]) cube ([JointOffset * 3,JointOffset * 2,SupportHeight]);
	}
}  
		
module Curve (siz, t, rot){
	rotate ([0,0,rot])
	difference (){
		cube ([siz + 2, siz + 2, t]);    
		cylinder (r = siz, h = t);
	}
}
		
module DrawForearm(){
//cut out the pin holes from the joints
	difference(){
		//join the forearm shape and the joints    
		union(){
			//GENERATE FOREARM SHAPE
			forearm();
			//ADD JOINTS
			*joint(0,ForearmLen,JointRadius,Thickness,JointOffset); //wrist top left
			*joint(WristWidth,ForearmLen+(HandPerc * 0.05),JointRadius,Thickness,JointRadius); //wrist top right
			joint(ElbowWidth / 2 ,0,JointRadius,Thickness,JointOffset+(HandPerc * 0.01)); //elbow bottom right
			joint((ElbowWidth / 2) - ElbowWidth ,0,JointRadius,Thickness,JointOffset+(HandPerc * 0.01)); //elbow bottom left
			
			//ADD WRIST SUPPORTS
			x1 = 0;
			y1 = ForearmLen;
			x2 = WristWidth;
			y2 = ForearmLen+(HandPerc * 0.05);
			angle = atan2(y1 - y2, x2 - x1);
			translate ([0,ForearmLen,0]) rotate ([0,0,360-angle]) WristSupport();
			translate ([WristWidth,ForearmLen+(HandPerc * 0.05),HandPerc * 0.10]) rotate ([0,180,360 - angle]) WristSupport();
			translate ([(WristWidth / 2) * 1.48 + JointRadius , (ForearmLen * 0.956) - JointRadius,0]) Curve (JointOffset, Thickness, 90);
			}
			//5x5 cut out
			//translate ([0,ForearmLen,0]) cube([HandPerc * 0.05,HandPerc * 0.05,HandPerc * 0.09], center=true);
			//translate ([WristWidth,ForearmLen+(HandPerc * 0.05),0]) cube([HandPerc * 0.05,HandPerc * 0.05,HandPerc * 0.09], center=true);
			//translate ([ElbowWidth / 2 ,0,0]) cube([HandPerc * 0.05,HandPerc * 0.05,HandPerc * 0.09], center=true);
			//translate ([(ElbowWidth / 2) - ElbowWidth ,0,0]) cube([HandPerc * 0.05,HandPerc * 0.05,HandPerc * 0.09], center=true);
			//EXPERIMENTAL, REPLACE SQUARES WITH HOLES FOR EASIER ASSEMBLY.
			translate ([0,ForearmLen,0]) cylinder (r = HandPerc * 0.03, h = Thickness * 4);
			translate ([WristWidth,ForearmLen+(HandPerc * 0.05),0]) cylinder (r = HandPerc * 0.03, h = Thickness * 4);
			translate ([ElbowWidth / 2 ,0,0]) cylinder (r = HandPerc * 0.03, h = Thickness * 4);
			translate ([(ElbowWidth / 2) - ElbowWidth ,0,0]) cylinder (r = HandPerc * 0.03, h = Thickness * 4);
			//
			//5x7.6 cut out
			translate ([0,ForearmLen,0]) cube([HandPerc * 0.076,HandPerc * 0.05,HandPerc * 0.038], center=true);
			translate ([WristWidth,ForearmLen+(HandPerc * 0.05),0]) cube([HandPerc * 0.076,HandPerc * 0.05,HandPerc * 0.038], center=true);
			translate ([ElbowWidth / 2 ,0,0]) cube([HandPerc * 0.076,HandPerc * 0.05,HandPerc * 0.038], center=true);
			translate ([(ElbowWidth / 2) - ElbowWidth ,0,0]) cube([HandPerc * 0.076,HandPerc * 0.05,HandPerc * 0.038], center=true);
			CenterSlot();
			translate([((ElbowWidth / 2) + JointRadius - 6 ) * -1,0,0]) LeftSlots();
			translate([(ElbowWidth / 2) + JointRadius - 9,0,0]) RightSlots();
			}
			//align tendon path to middle of wrist
			x1 = BicepCircum / 8;
			y1 = HandPerc * 0.1;
			x2 = WristWidth / 2;
			y2 = ForearmLen+(HandPerc * 0.05);
			angle = atan2(y1 - y2, x2 - x1);
			//echo (angle);
			rotate([0,0,270 - angle]) tendonpath();	
}
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

//JIG CODE
//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
module Jig(){
	difference (){
	union(){
     cylinder (r = CuffRadius, h = CuffLength); //main body
     
	 //add round bits
	 translate ([CuffRadius - (Thickness * 2),0,CuffLength + ArmLength ])
	 rotate ([0,90,0])
	 union(){
			cylinder (r = JointOffset, h = HandPerc * 0.1 + Thickness * 2);
			cylinder (r = HandPerc * 0.025, h = HandPerc * 0.18 + Thickness * 2);
	 }
	 translate ([(CuffRadius * -1) + Thickness * 2,0,CuffLength + ArmLength ]) 
	 rotate ([180,90,0]) 
	 union (){
	 cylinder (r = JointOffset, h = HandPerc * 0.1 + Thickness * 2);
	 cylinder (r = HandPerc * 0.025, h = HandPerc * 0.18 + Thickness * 2);
	 }
	}
	union(){
	cylinder (r = CuffRadius - Thickness * 2, h = CuffLength); //main body	
	translate ([CuffRadius * -1,0,0]) cube ([CuffRadius * 2,CuffRadius * 2,CuffLength]);
	}
}
}

module DrawJig(){
translate ([0,0,JointOffset])
rotate ([90,180,])
union(){
Jig();
translate ([CuffRadius - (Thickness * 2),JointOffset * -1,0]) cube ([Thickness * 2,JointOffset * 2,CuffLength + ArmLength ]); //right arm
translate ([CuffRadius * -1,JointOffset * -1,0]) cube ([Thickness * 2,JointOffset * 2,CuffLength + ArmLength ]); //left arm
translate ([CuffRadius * -1,JointOffset - Thickness * 2,0]) cube ([CuffRadius * 2,Thickness * 2,JointOffset]); //left arm
translate ([CuffRadius * -1,JointOffset - Thickness * 2,CuffLength]) cube ([CuffRadius * 2,Thickness * 2,JointOffset]); //left arm
}
}
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


module add_text(){
    //add version number and measurements for reference
		MyTxt = (str(ArmVersion,BicepCircum,ForearmLen,HandLen,"/" ,HandPerc,"%"));
		translate ([(ElbowWidthCuff / 2) * -1,2,0]) mirror ([1,0,0]) rotate ([0,0,90]) #linear_extrude(height = 0.6, center = true, convexity = 10, twist = 0) 
        text(MyTxt, halign="left", size = 4, font = "Arial");
}
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

// code pulled from thermogauntlet.scad for conical bearings
bearing_washer_dia=16;
hole_clearance=1.0;

bearing_big_dia=10*HandPerc/100.;
bearing_little_dia=8*HandPerc/100.;
bearing_plastic_thickness=0.5;
bearing_screw_dia=3 + hole_clearance;  // 3mm screw with clearance
bearing_screw_head_dia=5.8 + hole_clearance; // 5.6mm screw head, 5.8mm washer, with clearance
bearing_screw_head_depth=2.5;

bearing_depth=2;

// coordinates for wrist bearings, from above
//joint(0,ForearmLen,JointRadius,Thickness,JointOffset); //wrist top left
//joint(WristWidth,ForearmLen+(HandPerc * 0.05),JointRadius,Thickness,JointRadius);

module do_wrist() {    
    pin_coordinates=[[0,ForearmLen,0], [WristWidth,ForearmLen+(HandPerc * 0.05),0]];
    sthick=bearing_plastic_thickness;
    gauntlet_thickness=Thickness+1; // from forearm() module, with extra meat for strength
    global_scale=1; // scaling handled elsewhere
    difference() {
        union() {
            children();
            for(center=pin_coordinates)
                translate(center) {
                $fn=50;
                translate([0,0,-sthick/0.5+gauntlet_thickness-0.01]) // cylinder wall slope is 0.5
                    cylinder(d1=bearing_big_dia, d2=bearing_little_dia, h=2);
                cylinder(r=JointRadius*1.125, h=gauntlet_thickness);
            }
        }
        for(center=pin_coordinates)
            translate(center) {
            $fn=20;
            cylinder(d=bearing_screw_dia, h=20);
            cylinder(d=bearing_screw_head_dia, h=bearing_screw_head_depth);
        }
    }
    // supports for flying hole
    for(center=pin_coordinates)
        translate(center) {
        $fn=20;
        cylinder(d=bearing_screw_head_dia-1, h=bearing_screw_head_depth-0.25);
    }
}

//OK LETS GENERATE PARTS
//**************************************************
//**************************************************
module print_part() {
	if (part == "Forearm") {
		if (LeftRight == "Left") {
            do_wrist() DrawForearm();} 
        else {mirror ([1,0,0]) do_wrist() DrawForearm();}
	} else if (part == "Cuff") {
		if (LeftRight == "Left") {
            difference(){
            DrawCuff();
            add_text();
            }
            } else {
              difference(){
                mirror ([1,0,0]) DrawCuff();
                add_text();
              }
        }
	} else if (part == "Jig") {
		if (LeftRight == "Left") {DrawJig();} else {mirror ([1,0,0]) DrawJig();}
	}
}

print_part();
//**************************************************
//**************************************************

