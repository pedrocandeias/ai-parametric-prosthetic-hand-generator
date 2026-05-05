// PeKwawu — Kwawu Arm 3.0 Wrap, adapted for the AI Parametric Prosthetic Hand platform
// Original design: Kwawu Arm 3.0 Wrap Version by Jacqun Buchanan / e-NABLE community
// Source: https://github.com/JacquinBuchanan/Kwawu3Wrap
// License: CC BY 4.0 — https://creativecommons.org/licenses/by/4.0/
// ISO thread code by Trevor Moseley

/* [Orientation] */
// Right arm (false = left arm mirror)
right_arm = true;

/* [Hand & Arm Measurements] */
// Across all four knuckles — master scale driver (mm)
palm_breadth_mm = 96; // [65:186]
// Elbow crease to wrist attachment — residual limb length (mm)
residual_length_mm = 282; // [50:500]
// Forearm circumference just below elbow crease (mm)
residual_circumference_proximal_mm = 270; // [70:542]
// Bicep / upper arm circumference (mm)
bicep_circumference_mm = 294; // [100:600]

/* [Comfort & Hardware] */
// Inner padding thickness (mm)
padding_thickness_mm = 2; // [0:10]
// Palm bolt diameter — ISO metric (mm)
palm_bolt_diameter_mm = 6; // [4,6,8]
// Elbow bolt diameter — ISO metric (mm)
elbow_bolt_diameter_mm = 8; // [4,6,8,10,12,14]
// Leather rivet shaft diameter (mm)
rivet_shaft_diameter_mm = 5; // [2.4,2.8,3.1,4,5,6]
// Velcro strap width (mm)
strap_width_mm = 25; // [10:60]

/* [Material] */
// Wrap material selection
material = "Leather"; // [Leather,Plastic]

/* [Options] */
// Include pencil holder accessory
pencil_holder = false;

/* [Part] */
// Component to render
part = "Cuff1"; // [Palm,PalmTop,WristButton,WristCover,Cuff1,Cuff2,Cuff3,CuffLeatherTemplate,UpperArm1,LowerArm1,UpperArm2,LowerArm2,UpperArm3,LowerArm3,UpperArmLeatherTemplate,LowerArmLeatherTemplate,Ratchet,Latch,LatchCover,WristAttachment,WristBolt,PalmBolt,WristBoltPin,ElbowBolt1,ElbowBolt2,IndexFingerEnd,IndexFingerPhalanx,MiddleFingerEnd,MiddleFingerPhalanx,PinkyFingerEnd,PinkyFingerPhalanx,RingFingerEnd,RingFingerPhalanx,ThumbEnd,ThumbPhalanx,Tensioner,WhippleTreePrimary,WhippleTreeSecondary,PencilHolderCover,Hinges]

/* [Hidden] */
// ── Map platform fields → original Kwawu variable names ──────────────────────
Part                 = part;
LeftRight            = right_arm ? "Right" : "Left";
LeatherOrPlastic     = material;
HandWidth            = palm_breadth_mm;
ArmLength            = residual_length_mm;
ForearmCircumference = residual_circumference_proximal_mm;
BicepCircumference   = bicep_circumference_mm;
PaddingThickness     = padding_thickness_mm;
PalmBoltDiameter     = palm_bolt_diameter_mm;
ElbowBoltDiameter    = elbow_bolt_diameter_mm;
RivetShaftDiameter   = rivet_shaft_diameter_mm;
StrapWidth           = strap_width_mm;
PencilHolder         = pencil_holder ? "Yes" : "No";
// ─────────────────────────────────────────────────────────────────────────────



SlotSize = 0.5;
SlotLength = 10;//length of the opening slot
SlotSpacing = 3;//spacing between slots
SlotWidth = 2.4;//width of slots 
//The thickness of the cuff
ShellThickness = 2;

// This is an amount added to the pencil cover length. 
// When this is zero the pencil cover is as tight as possible.
// Make it larger to fit around larger/thicker pencils
PencilCoverAddedLength = 4.0;

PI =  3.141592653589793238;
HandVersion = "V3.0";

HandScale = HandWidth / 96;
WristCircumference = HandScale * 169;
WristCircumferenceWPadding = ((WristCircumference/PI) + 2*PaddingThickness  - 2*ShellThickness)*PI;
ForearmCircumferenceWPadding = ((ForearmCircumference/PI) + 2*PaddingThickness)*PI;
ForeArmCircumferenceScale = ForearmCircumferenceWPadding/270;
ElbowPartsScale = max(0.73, ForeArmCircumferenceScale);
ForearmDiameterWPadding = ForearmCircumferenceWPadding/PI;
BicepCircumferenceWPadding = ((BicepCircumference/PI) + 2*PaddingThickness)*PI;
BicepDiameterWPadding = BicepCircumferenceWPadding/PI;
CuffScale = BicepCircumferenceWPadding/270;
CuffLength = CuffScale * 90;


WristBoltDia = 18;
$fn=30;

if(Part == "Cuff1") {
    if (LeftRight == "Left") {
        mirror([1,0,0]) MakeCuff1();
    }else {
        MakeCuff1();
    }
}

if(Part == "Cuff2") {
    if (LeftRight == "Left") {
        mirror([1,0,0]) MakeCuff2();
    } else {
        MakeCuff2();
    }
}

if(Part == "Cuff3") {
    if (LeftRight == "Left") {
        mirror([1,0,0]) MakeCuff3();
    } else {
        MakeCuff3();
    }
}

if(Part== "CuffLeatherTemplate")
    {
    if (LeftRight == "Left") {
        mirror([1,0,0]) MakeCuffLeatherTemplate();
    } else {
        MakeCuffLeatherTemplate();
    }
}

if(Part == "UpperArm1") {
    if (LeftRight == "Left") {
        mirror([1,0,0]) MakeUpperArm1();
    } else {
         MakeUpperArm1();
    }
}

if(Part == "LowerArm1") {
    if (LeftRight == "Left") {
        mirror([1,0,0]) MakeLowerArm1();
    } else {
        MakeLowerArm1();
    }
}

if(Part == "UpperArm2") {
    if (LeftRight == "Left") {
        mirror([1,0,0]) MakeUpperArm2();
    } else {
        MakeUpperArm2();
    }
}

if(Part == "LowerArm2") {
    if (LeftRight == "Left") {
        mirror([1,0,0]) MakeLowerArm2();
    } else {
        MakeLowerArm2();
    }
}


if(Part == "UpperArm3") {
    if (LeftRight == "Left") {
        mirror([1,0,0]) MakeUpperArm3();
    } else {
        MakeUpperArm3();
    }
}

if(Part == "LowerArm3") {
    if (LeftRight == "Left") {
        mirror([1,0,0]) MakeLowerArm3();
    } else {
        MakeLowerArm3();
    }
}

if(Part == "UpperArmLeatherTemplate") {
    if (LeftRight == "Left") {
        mirror([1,0,0]) MakeUpperArmLeatherTemplate();
    } else {
        MakeUpperArmLeatherTemplate();
    }
}

if(Part == "LowerArmLeatherTemplate") {
    if (LeftRight == "Left") {
        mirror([1,0,0]) MakeLowerArmLeatherTemplate();
    } else {
        MakeLowerArmLeatherTemplate();
    }
}

if(Part == "Ratchet") {
    if (LeftRight == "Left") {
        mirror([1,0,0]) MakeRatchet();
    } else {
        MakeRatchet();
    }
}

if(Part == "Tensioner")
    MakeTensioner();

if(Part == "Latch") {
    if (LeftRight == "Left") {
        mirror([1,0,0]) MakeLatch();
    } else {
        MakeLatch();
    }
}

if(Part == "LatchCover") {
    if (LeftRight == "Left") {
        mirror([1,0,0])  MakeLatchCover();
    } else {
        MakeLatchCover();
    }
}

if(Part == "WristAttachment") {
    if (LeftRight == "Left") {
        mirror([1,0,0]) rotate(a=[180,0,0])MakeWristAttachment();
    } else {
        rotate(a=[180,0,0])MakeWristAttachment();
    }
}

if(Part == "WristBolt") {
    if (LeftRight == "Left") {
        mirror([1,0,0]) rotate(a=[180,0,0])MakeWristBolt();
    } else {
        rotate(a=[180,0,0])MakeWristBolt();
    }
}

if(Part == "WristBoltPin")
{
    rotate(a=[90,0,0])MakeWristBoltPin();
}

if(Part == "ElbowBolt1"){
    if (LeftRight == "Left") {
        mirror([1,0,0]) rotate(a=[180,0,0]) MakeElbowBolt(26);
    } else {
        rotate(a=[180,0,0]) MakeElbowBolt(26);
    }
}

if(Part == "ElbowBolt2"){
    if (LeftRight == "Left") {
        mirror([1,0,0]) rotate(a=[180,0,0]) MakeElbowBolt(19);
    } else {
        rotate(a=[180,0,0]) MakeElbowBolt(19);
    }
}

if(Part == "PalmBolt"){
    if (LeftRight == "Left") {
        mirror([1,0,0]) rotate(a=[180,0,0])MakePalmBolt();
    } else {
        rotate(a=[180,0,0])MakePalmBolt();
    }
}

if (Part == "Palm") {
    if (LeftRight == "Left") {
        mirror([1,0,0]) MakePalm();
    } else {
        MakePalm();
    }
}

if(Part =="WristButton")
{
    //Rotate just to orient for printing
    if (LeftRight == "Left") {
        mirror([1,0,0]) rotate(a=[180,0,0])MakeWristButton();
    } else {
    
        rotate(a=[180,0,0])MakeWristButton();
    }
    
}

if(Part =="WristCover")
{
    MakeWristCover();
    
}

if (Part == "PalmTop") {
    //Rotate just to orient for printing
    if (LeftRight == "Left") {
        mirror([1,0,0]) rotate(a=[90,7,]) MakePalmTop();
    } else {
        rotate(a=[90,7,0])MakePalmTop();
    }
}

if(Part == "IndexFingerEnd") {  
    if (LeftRight == "Left") {
        mirror([1,0,0]) IndexFingerEnd();
       } else {
        IndexFingerEnd();
    }
}

if(Part == "IndexFingerPhalanx") { 
     if (LeftRight == "Left") {
        mirror([1,0,0]) IndexFingerPhalanx();
       } else {
        IndexFingerPhalanx();
    }
}
        
if(Part == "MiddleFingerEnd") { 
     if (LeftRight == "Left") {
        mirror([1,0,0]) MiddleFingerEnd();
       } else {
        MiddleFingerEnd();
    }
}
            
if(Part == "MiddleFingerPhalanx") { 
     if (LeftRight == "Left") {
        mirror([1,0,0]) MiddleFingerPhalanx();
       } else {
        MiddleFingerPhalanx();
    }
}
                
if(Part == "PinkyFingerEnd") { 
     if (LeftRight == "Left") {
        mirror([1,0,0]) PinkyFingerEnd();
       } else {
        PinkyFingerEnd();
    }
}

if(Part == "PinkyFingerPhalanx") { 
     if (LeftRight == "Left") {
        mirror([1,0,0]) PinkyFingerPhalanx();
       } else {
        PinkyFingerPhalanx();
    }
}

if(Part == "RingFingerEnd") { 
     if (LeftRight == "Left") {
        mirror([1,0,0]) RingFingerEnd();
       } else {
        RingFingerEnd();
    }
}

if(Part == "RingFingerPhalanx") { 
     if (LeftRight == "Left") {
        mirror([1,0,0]) RingFingerPhalanx();
       } else {
        RingFingerPhalanx();
    }
}

if(Part == "ThumbEnd") { 
     if (LeftRight == "Left") {
        mirror([1,0,0]) ThumbEnd();
       } else {
        ThumbEnd();
    }
}

if(Part == "ThumbPhalanx") { 
     if (LeftRight == "Left") {
        mirror([1,0,0]) ThumbPhalanx();
       } else {
        ThumbPhalanx();
    }
}

if(Part == "WhippleTreePrimary") { 
     if (LeftRight == "Left") {
        mirror([1,0,0]) rotate(a=[180,0,0])WhippleTreePrimary();
       } else {
        rotate(a=[180,0,0])WhippleTreePrimary();
    }
}

if(Part == "WhippleTreeSecondary") { 
     if (LeftRight == "Left") {
        mirror([1,0,0]) WhippleTreeSecondary();
       } else {
        WhippleTreeSecondary();
    }
}

if(Part == "PencilHolderCover")
{
    PencilHolderCover();
}

if(Part == "Hinges") { MakeHinges(); }
    
//***************************
// MakeHinges() 
//***************************
module MakeHinges() {
    
    // Hinge4Knuckles
   translate([0,  1* HandScale *10,0]) scale([HandScale,HandScale,HandScale]) cube([20, 2.0, 6.25]); 
    
    translate([0,  2 *HandScale *10,0]) scale([HandScale,HandScale,HandScale]) cube([20, 2.0, 6.25]); 
    
    translate([0,  3* HandScale *10,0]) scale([HandScale,HandScale,HandScale]) cube([20, 2.0, 6.25]); 
    
    translate([0,  4* HandScale *10,0]) scale([HandScale,HandScale,HandScale]) cube([20, 2.0, 6.25]); 
    
    // "HingeThumbKnuckle"
    translate([0,  5* HandScale *10,0]) scale([HandScale,HandScale,HandScale]) cube([31, 2.0, 6.25]); 
    
    // HingeIndexFinger
    translate([- HandScale *30,  1* HandScale *10,0]) scale([HandScale,HandScale,HandScale]) cube([20, 2.0, 6.25]); 
    
    //"HingeMiddleFinger"
    translate([- HandScale *30,  2* HandScale *10,0]) scale([HandScale,HandScale,HandScale]) cube([18, 2.0, 6.25]); 
    
    //"HingePinkyFinger"
    translate([- HandScale *30,  3* HandScale *10,0]) scale([HandScale,HandScale,HandScale]) cube([15.5, 2.0, 6.25]); 
    
    //"HingeRingFinger"
    translate([- HandScale *30,  4* HandScale *10,0]) scale([HandScale,HandScale,HandScale]) cube([18, 2.0, 6.25]); 
    
    //"HingeThumb"
    translate([- HandScale *30,  5* HandScale *10,0]) scale([HandScale,HandScale,HandScale]) cube([21, 2.0, 6.25]); 
    
    
}
    
//***************************
// PencilHolderCover() 
//***************************
module PencilHolderCover() {
    
    ShortestPencilCover = 27*HandScale;
    
    cube([ShortestPencilCover + PencilCoverAddedLength, 1.5*HandScale, 12*HandScale]);
    
    translate([0, -0.25 * HandScale, 6 * HandScale]) cylinder(d=3.5*HandScale, h = 12*HandScale, center=true, $fn=30);
    
    translate([ShortestPencilCover + PencilCoverAddedLength, -0.25 * HandScale, 6 * HandScale]) cylinder(d=3.5*HandScale, h = 12*HandScale, center=true, $fn=30);
    }

//***************************
// MakePalm() 
//***************************
module MakePalm() {
    
    difference(){
        Palm();
        // cut  first hole for bolt to hold palm together
        translate([HandScale * 12,0, HandScale * 84.35]) rotate([90,0,7]) cylinder(d=PalmBoltDiameter + 0.5,  h=100,center=true, $fn=20);
        translate([HandScale * 12, 0, HandScale * 84.35]) rotate([90,0,7]) translate([0, 0, -PalmBoltDiameter + 2 * HandScale])  cylinder(d=PalmBoltDiameter  + PalmBoltDiameter/2 + 1, h=100,center=false, $fn=20);
        
        // cut  second hole for bolt to hold palm together
        translate([HandScale * -32.767,0,HandScale * 76.472]) rotate([90,0,7]) cylinder(d=PalmBoltDiameter + 0.5, h=100,center=true, $fn=20);
        translate([HandScale * -32.767, 0,HandScale * 76.472]) rotate([90,0,7]) translate([0, 0, -PalmBoltDiameter + 2 * HandScale]) cylinder(d=PalmBoltDiameter + PalmBoltDiameter/2 + 1 + 0.5, h=100,center=false, $fn=20);
 
  
        // cut small hole all the way through wrist
        translate([2.513 * HandScale, 14.753 * HandScale, -(21.5* HandScale) + (-2* HandScale)/2 ]) 
        cylinder(d = 19.25, h = 36.00 * HandScale, center=true, $fn=60);
       
       //This is the thickness of the button ring that holds the teeth 
       ringthickness = max (2.0, 6 * HandScale* HandScale);
        
       // cut larger hole to hold the wrist cover
        translate([2.513 * HandScale, 14.753 * HandScale, - (21.5* HandScale) + 4.25/2 ]) 
        cylinder(r = 10+ ringthickness + 4, h = 5, center=true, $fn=30);
        
        //Cut slot for button     
        translate([2.513 * HandScale, 14.753 * HandScale, - (21.5* HandScale-4.25)]) {
            hull(){translate([0, -4.75, 0])linear_extrude(5.5) circle((20)/2 + ringthickness);
                translate([0, 2.75, 0])linear_extrude(5.5) circle((20)/2 + ringthickness);
                
            }
                //The two side square cutouts
                translate([-(6 + (3.7+ringthickness)/2), -(7.5+ringthickness/2)/2  -2.75, 2.75])cube([  3.7+ringthickness,7.5+ringthickness/2 ,5.5 ], center=true);
                
                translate([(6 + (3.7+ringthickness)/2), -(7.5+ringthickness/2)/2  -2.75, 2.75])cube([  3.7+ringthickness,7.5+ringthickness/2 ,5.5 ], center=true);
        }
            
        //Cut pin guide holes for Wrist cover
        translate([2.513 * HandScale , 14.753 * HandScale, - (21.5* HandScale-4.5)]) {
            translate([ -(10 + ringthickness +2) + 3, 0, 0]) rotate(a=[90,-90,-90]) linear_extrude(5) polygon(points=[[0,-2.5],[5,0],[0,2.5]], paths=[[0,1,2]]);
            
            translate([ (10 + ringthickness +2)+2 , 0, 0]) rotate(a=[90,-90,-90]) linear_extrude(5) polygon(points=[[0,-2.5],[5,0],[0,2.5]], paths=[[0,1,2]]);
        }
        
        // cut square for button
        translate([2.513 * HandScale, (14.753 * HandScale)+
        250, - (21.5* HandScale) + 9.75/2 -.5 ]) 
        cube([ 20.5, 500,9.75 +1], center=true);
  
        // If the pencil Holder is seelcted then cut it out
        if(PencilHolder =="Yes")
        {
            PencilHolderTool();
        }
        
    }
           
}

/***************************
// MakeWristCover() 
//***************************/
module MakeWristCover() {

       //This is the thickness of the button ring that holds the teeth 
       ringthickness = max (2.0, 6 * HandScale* HandScale);
        
difference(){
    union() {
       // make the main ring that is the cover
       translate([2.513 * HandScale, 14.753 * HandScale, - (21.5* HandScale) + 4.25/2 ]) 
        cylinder(r = 10+ ringthickness + 3.75, h = 4.25, center=true, $fn=30);
    
            //make pin guide holes
        translate([2.513 * HandScale , 14.753 * HandScale, - (21.5* HandScale-4.5)]) {
            translate([ -(10 + ringthickness +2) + 1.5, 0, 0]) rotate(a=[90,-90,-90]) linear_extrude(3) polygon(points=[[0,-2],[4,0],[0,2]], paths=[[0,1,2]]);
            
            translate([ (10 + ringthickness +2)+1.5 , 0, 0]) rotate(a=[90,-90,-90]) linear_extrude(3) polygon(points=[[0,-2],[4,0],[0,2]], paths=[[0,1,2]]);
        }
    }
    
    // cut square for button
    translate([2.513 * HandScale, (14.753 * HandScale)+
        250 +10.5, - (21.5* HandScale) + 9.75/2 -.5 ]) 
        cube([ 20.5, 500,9.75 +1], center=true);
    
    // cut small hole all the way through wrist
    translate([2.513 * HandScale, 14.753 * HandScale, -(21.5* HandScale) + (-2* HandScale)/2 ]) 
        cylinder(d = 19.25, h = 36.00 * HandScale, center=true, $fn=60);
    
    }
}

/***************************
// MakeWristButton() 
//***************************/
module MakeWristButton() {

    intersection(){
        Palm();
        //  square to cut button top out of hand piece
        translate([2.513 * HandScale, (14.753 * HandScale)+
    250+13.95, - (21.5* HandScale) + 9.5/2 ]) 
    cube([ 20, 500,9.5 ], center=true);
    }
    
    //import the teeth
    //translate([2.513 * HandScale, 14.753 * HandScale, - (21.5* HandScale)])import("o_WristButton.stl", convexity=3);
    
    //teeth
    translate([2.513 * HandScale, 14.753 * HandScale, - (21.5* HandScale)]) {
        translate([-6.8, -6.8, 14/2]) cube([ 2.6, 2.6,5], center=true);
        translate([6.8, -6.8, 14/2]) cube([ 2.6, 2.6,5], center=true);
    }
    
    //thicken the outside ring of the button
    ringthickness = max (2.0, 6 * HandScale* HandScale);
    
    translate([2.513 * HandScale, 14.753 * HandScale, - (21.5* HandScale-4.5)])
    difference(){
        
        union(){
        
        //outer rings
        hull(){linear_extrude(5) circle((19.5)/2 + 1.5);
            translate([0, 2.75, 0])linear_extrude(5) circle((19.5)/2 + ringthickness);
            }
            
        //Springy piece
        difference(){
            
            translate([2.4, -4.5, 0])linear_extrude(5) circle((20)/2 + ringthickness);
            
            translate([3.8, -3.1, -.5])linear_extrude(6) circle((20)/2 + ringthickness);
        }
        
        //  square to connect to button top
        translate([0, 7, 2.5])cube([ 20, 14,5 ], center=true);
        
        // two squares out side of ring
        translate([6 + (3.7+ringthickness)/2 -0.25, -(7.5+ringthickness/2)/2, 2.5])cube([  3.7+ringthickness,7.5+ringthickness/2 ,5 ], center=true);
        
        translate([-(6 + (3.7+ringthickness)/2)+0.25, -(7.5+ringthickness/2)/2, 2.5])cube([  3.7+ringthickness,7.5+ringthickness/2 ,5 ], center=true);
        
        }
        
        //Minus inner rings  
        hull(){translate([0, 0, -1])linear_extrude(10) circle(9.75);
            translate([0, 2.75, -1])linear_extrude(10) circle(9.75);
            }
        
    }
        
}

//***************************
// MakePalmTop() 
//***************************
module MakePalmTop() {
    difference(){
        PalmTop();
        
        //Cut hole for first bolt holder
        translate([HandScale * 12, 0, HandScale * 84.35]) rotate([90,0,7]) translate([0, 0, -34 * HandScale])  cylinder(d=PalmBoltDiameter, h=100 * HandScale,center=false, $fn=20);
        
        //Cut hole for second bolt holder
        translate([HandScale * -32.767, 0,HandScale * 76.472]) rotate([90,0,7]) translate([0, 0,  -28 * HandScale]) cylinder(d=PalmBoltDiameter , h=100 * HandScale,center=false, $fn=20);
        
        
       
    }
   
     
    //Add inner threads for first bolt holder
    translate([HandScale * 12, 0, HandScale * 84.35]) rotate([90,0,7]) translate([0, 0, -35 * HandScale]) thread_in(PalmBoltDiameter, 13 * HandScale);
    
    //Add inner threads for second bolt holder
    translate([HandScale * -32.767, 0,HandScale * 76.472]) rotate([90,0,7]) translate([0, 0,  -29.5 * HandScale])  thread_in(PalmBoltDiameter, 13 * HandScale);
   
}

//***************************
// MakeLatch() 
//***************************
module MakeLatch() {
    
    //Rotate just to orient for printing
    rotate(a=[0,-180,0])
    difference(){
        Latch();
        
        // Make hole for Latch rotation pin, note it is always a 2mm rode
        translate([-17.701*ElbowPartsScale, -4.25*ElbowPartsScale, 10*ElbowPartsScale ])cylinder(d=2.3, h=ElbowPartsScale * 20,center=true, $fn=20);
    }
}

//***************************
// MakeLatchCover() 
//***************************
module MakeLatchCover() {
    
    difference() {
        LatchCover();
        
        // Make hole for Latch rotation pin, note it is always a 2mm rode
        translate([-17.701*ElbowPartsScale, -4.25*ElbowPartsScale, 10*ElbowPartsScale +1  ])cylinder(d=2.7, h=ElbowPartsScale * 20,center=true, $fn=20);
        
        if(LeatherOrPlastic != "Leather") {
            // Make hole for Latch cover, NOTE it is always a #4 or 3mm sheet metal screw
            translate([-45*ElbowPartsScale, 0, 0  ])cylinder(d=3.5, h=ElbowPartsScale * 200,center=true, $fn=20);
            
            // recess for 3mm pan head bolt head
            translate([-45*ElbowPartsScale, 0, ElbowPartsScale * 28 - 3.5 ])cylinder(d=6.5, h=ElbowPartsScale * 10,center=true, $fn=20);
        } else {
            
            // Make hole for rivet through latch cover
           translate([-45*ElbowPartsScale, 0, 0  ])cylinder(d=RivetShaftDiameter+0.5, h=ElbowPartsScale * 200,center=true, $fn=20);
            
            // recess for rivet head. All rivet heads are 10mm. 
            translate([-45*ElbowPartsScale, 0, ElbowPartsScale * 28 - 3.5 ])cylinder(d=10, h=ElbowPartsScale * 10,center=true, $fn=20);
        }
        
    }
    
}


//***************************
// MakeTensioner() 
//***************************
module MakeTensioner(){
    
    //Rotate to put in good print orientation
    rotate(a=[90,90,0])rotate(a=[0,0,-51.5])Tensioner();

}


//***************************
// MakeRatchet() 
//***************************
module MakeRatchet() {
    
    
    difference() {
        Ratchet();
        
        // Make hole ratchet center
        cylinder(d=ElbowPartsScale*12 +0.5, h=ElbowPartsScale * 200,center=true, $fn=40);

    }

}


//***************************
// MakeWristAttachment() 
//***************************
module MakeWristAttachment() {
    
    diameter = (WristCircumferenceWPadding/PI);
    
difference(){
   union(){
   difference(){
        cylinder(d=diameter, h=15 * ForeArmCircumferenceScale,center=true);     

        // cut large hole for wrist bolt 
        // the -0.05 on bolt diamter is to make sure threads attach to walls
        cylinder(d = WristBoltDia - 0.05, h = 60.00 * HandScale + 50 * HandScale, center=true, $fn=30);

    }
    
    difference() {
            
         //Add inner threads for wrist bolt holder
        translate([0, 0, -(15* HandScale)]) thread_in(WristBoltDia, 35 * HandScale );
        
        // truncate threads length to hand end
        translate([-100, -100, (7.5* ForeArmCircumferenceScale)]) cube(200);
            
        // truncate threads length to wrist end
        translate([-100, -100, -200-(7.5* ForeArmCircumferenceScale)]) cube(200);
    }
   
    }

    // Make holes for wrist attachment screw, note it is always a #4 or 3mm sheet metal screw
    rotate(a=[0,90,0]) cylinder(d=2.5, h=ForeArmCircumferenceScale * 200,center=true, $fn=20);
    
    //Make 4  slots for the wrist attach codderpin
    for(a = [0 : 90 : 360]){
        rotate(a=[0,0,a]){
            translate([0, -WristBoltDia+10, -(7.5* ForeArmCircumferenceScale)])cube([3,8,10],center=true);
            translate([0, -WristBoltDia+10, -(7.5* ForeArmCircumferenceScale)+5])cube([4,8,1],center=true);
        }
    }
    
}
           

}

//***************************
// MakeWristBoltPin() 
//***************************
module MakeWristBoltPin(){
    
    translate([0, WristBoltDia-10, -(7.5* ForeArmCircumferenceScale)+2])cube([2.75,7.5,7],center=true);
    translate([0, WristBoltDia-10, -(7.5* ForeArmCircumferenceScale)+5.25])cube([3.0,7.5,.75],center=true);
    
    translate([0, WristBoltDia-10-2, -(7.5* ForeArmCircumferenceScale)-1])cube([6,3.5,1],center=true);
}

//***************************
// MakeWristBolt() 
//***************************
module MakeWristBolt() {
 

    //Arm bolt
    difference() {
        union() {
            // basic cyliner of bolt
            translate([0, 0, -(15* ForeArmCircumferenceScale)/2]) thread_out_centre(WristBoltDia, 15 * ForeArmCircumferenceScale +1);
            
            // round the ends to not wear the thread
            //translate([0, 0, 2 ]) rotate_extrude(convexity = 10) translate([WristBoltDia/4, 0, 0]) circle(r = WristBoltDia/5.5, $fn = 100);
            translate([0, 0, -(15* ForeArmCircumferenceScale)/2 ]) rotate_extrude(convexity = 10) translate([WristBoltDia/4, 0, 0]) circle(r = WristBoltDia/5.5, $fn = 100);
            
            difference(){
                
                //Add threads for wrist bolt i
                translate([0, 0, -(15* ForeArmCircumferenceScale)]) thread_out(WristBoltDia, 35 * ForeArmCircumferenceScale );
                
                // truncate threads length to hand end
                translate([-100, -100, (7.5* ForeArmCircumferenceScale)]) cube(200);
                    
                // truncate threads length to wrist end
                translate([-100, -100, -200-(7.5* ForeArmCircumferenceScale)]) cube(200);
            }
        }
      
        // Make hole for wrist attachment bolt, note it is always a 3mm bolt
        rotate(a=[0,90,0]) cylinder(d=3, h=ForeArmCircumferenceScale * 200,center=true, $fn=20);
            
        //Make a slot for the wrist attach codderpin
        translate([0, WristBoltDia-10, -(7.5* ForeArmCircumferenceScale)])cube([3,8,10],center=true);
        translate([0, WristBoltDia-10, -(7.5* ForeArmCircumferenceScale)+5])cube([4,8,1],center=true);
            
        //Cut a hole down middle for string
        cylinder(d = WristBoltDia/5.5, h = 35 * ForeArmCircumferenceScale , center=true, $fn=30);
        
    }
    
    handHeight = 15 * HandScale;
    
    //Hand attachemnt
    difference() {
        union() {
        // basic cyliner of bolt
        translate([0, 0, (15* ForeArmCircumferenceScale)/2+0.25]) cylinder(d = 19, h = handHeight, center=false, $fn=60);
        
        //endcap
        translate([0, 0, (15* ForeArmCircumferenceScale)/2+ (handHeight)]) cylinder(d = 24, h = 2, center=false, $fn=60);
            
        }
        
        for(i = [-8 : 8])
           rotate(i * 22.5)
            
            translate([0, 9.5, (15* ForeArmCircumferenceScale)/2+ 6]) rotate(45)cube([2.7,2.7,8], center=true);
            
        
        //Cut a hole down middle for string
        translate([0, 0, (15* ForeArmCircumferenceScale)/2-4]) cylinder(d = WristBoltDia/5.5, h = 35 * HandScale , center=false, $fn=30);
        
    }
    
}

//***************************
// MakeElbowBolt() 
//***************************
module MakeElbowBolt(length)
{
    offset = LeatherOrPlastic == "Leather" ? ShellThickness : 0;
    difference() {
        
        union(){
        // bolt
        thread_out_centre(ElbowBoltDiameter, ElbowPartsScale * length - offset);
            
        //threads
        difference() {
        translate([0, 0, -1 * ElbowPartsScale  ])thread_out(ElbowBoltDiameter, ElbowPartsScale * (length+5)- offset);
        
        translate([0, 0, ElbowPartsScale * -5]) cylinder(d=ElbowBoltDiameter + 1, h=ElbowPartsScale * 10,center=true, $fn=20);
           
    }
        
        // head
        hull() {
        
            translate([0, 0, (ElbowPartsScale * length- offset)])cylinder(d=ElbowBoltDiameter *2, h=.25,center=true, $fn=20);
            
            translate([0, 0, (ElbowPartsScale * length)- offset +ElbowBoltDiameter*.5])cylinder(d=ElbowBoltDiameter *1.5, h=.25,center=true, $fn=20);
            }
        }
 
    //slot
    translate([0, 0, (ElbowPartsScale * length)- offset +(ElbowBoltDiameter*.9)/2])cube([1.5, ElbowBoltDiameter *1.15, ElbowBoltDiameter*.75],center=true);
    }
}


//***************************
// MakePalmBolt() 
//***************************
module MakePalmBolt()
{
    difference() {
        
        union(){
        // bolt
        thread_out_centre(PalmBoltDiameter, HandScale * 23);
            
        //threads
        difference() {
        translate([0, 0, -1 * HandScale  ])thread_out(PalmBoltDiameter, HandScale * 27);
        
        translate([0, 0, HandScale * -5]) cylinder(d=PalmBoltDiameter + 1, h=HandScale * 10,center=true, $fn=20);
           
    }
        
        // head
        hull() {
        
            translate([0, 0, (HandScale * 23)])cylinder(d=PalmBoltDiameter  + PalmBoltDiameter/2, h=.25,center=true, $fn=20);
            
            translate([0, 0, (HandScale * 23)+PalmBoltDiameter*.75])cylinder(d=PalmBoltDiameter  + PalmBoltDiameter/2, h=.25,center=true, $fn=20);
            }
        }
 
    //slot
    translate([0, 0, (HandScale * 23)+(PalmBoltDiameter*.9)/2])cube([1.5, PalmBoltDiameter *1.15, PalmBoltDiameter*.75],center=true);
    }
}

 
//***************************
// MakeArmslots() 
//***************************
module MakeArmslots(startlength, stoplength) {
    
    forearmWidth2 = ForearmCircumferenceWPadding/2;
    WristWidth2 = WristCircumferenceWPadding/2;
    difWidths = forearmWidth2 - WristWidth2;
    
    AngleIncrement = 10;
    
    for(y = [-30 : (SlotWidth + SlotSize)*2 : forearmWidth2]){
        for(x = [startlength : -(SlotLength + SlotSpacing) :  stoplength - (SlotLength + SlotSpacing)]){
            // the extra thickness is because the difference is not exact
            translate([x, y, -0.5]) rotate(a=[0,0,-atan(((forearmWidth2/2 - y)*(difWidths/2)/(forearmWidth2/2) )/ArmLength)]) cube([ SlotLength,SlotSize, ShellThickness + 1]);
        }
    }
    for(y = [(SlotWidth + SlotSize)-30 : (SlotWidth + SlotSize)*2 : forearmWidth2]){
        for(x = [startlength-(SlotLength + SlotSpacing)/2 : -(SlotLength + SlotSpacing) :  stoplength - (SlotLength + SlotSpacing)]){
            // the extra thickness is because the difference is not exact
            translate([x, y, -0.5])rotate(a=[0,0,-atan(((forearmWidth2/2 - y)*(difWidths /2)/(forearmWidth2/2))/ArmLength)]) cube([SlotLength, SlotSize, ShellThickness + 1]);
        }
    }
    
}


//***************************
// MakeArmBase() 
//***************************
module MakeArmBase(liptype, polygonpoints1, startlength, stoplength) {
    
    forearmWidth2 = ForearmCircumferenceWPadding/2;
    WristWidth2 = WristCircumferenceWPadding/2;
    difWidths = forearmWidth2 - WristWidth2;
    
    difference() {
        
        union(){

        if(LeatherOrPlastic != "Leather") 
         difference() {
            union(){linear_extrude(ShellThickness)
                    polygon(polygonpoints1, paths=[[0,1,2,3]]);
                }


            MakeArmslots(startlength , stoplength);  
         
            }
        

        
        //long arm stiffener
        rotate(a=[0,0,-atan((difWidths/2)/ArmLength)]) hull() {
            
            rotate(a=[90,-90,-90]) translate([8*ForeArmCircumferenceScale,4*ForeArmCircumferenceScale, 40*ForeArmCircumferenceScale])cylinder(d=7*ForeArmCircumferenceScale, h=1);
            rotate(a=[90,-90,-90]) translate([8*ForeArmCircumferenceScale,-4*ForeArmCircumferenceScale, 40*ForeArmCircumferenceScale])cylinder(d=7*ForeArmCircumferenceScale, h=1);
            
            translate([-ArmLength + 10*ForeArmCircumferenceScale, 4*ForeArmCircumferenceScale, 8*ForeArmCircumferenceScale])sphere(d=7*ForeArmCircumferenceScale);
            translate([-ArmLength+ 10*ForeArmCircumferenceScale, -4*ForeArmCircumferenceScale, 8*ForeArmCircumferenceScale])sphere(d=7*ForeArmCircumferenceScale);
            
            
            translate([-ArmLength,-(11*ForeArmCircumferenceScale)/2,0])cube([ArmLength-40*ForeArmCircumferenceScale ,  11*ForeArmCircumferenceScale, ShellThickness]);
            
        }
        
        if(LeatherOrPlastic != "Leather") {
            if(liptype ==1)
            {
                //lip on leading edge to glue on other stiffener
                translate([0, forearmWidth2 - 5*ForeArmCircumferenceScale, 0 ])rotate(a=[0,0,atan((difWidths/2)/ArmLength)])translate([-ArmLength-2, 0  , 0]){
                        cube([ ArmLength+4, 5*ForeArmCircumferenceScale , ShellThickness]);
                    translate([ArmLength+4,  4*ForeArmCircumferenceScale, ShellThickness ])
                    rotate(a=[90,-90,-90]) linear_extrude(ArmLength+4)
                    polygon(points=[[0,-1*ForeArmCircumferenceScale],[3*ForeArmCircumferenceScale,0],[0,1*ForeArmCircumferenceScale]], paths=[[0,1,2]]);
                    }
            } else {
                
                //Lip on leading edge
                //solid on end
                translate([0, forearmWidth2-10- SlotSpacing  , 0])rotate(a=[0,0,atan((difWidths/2)/ArmLength)])translate([-ArmLength+ 10*ForeArmCircumferenceScale, 0  , 0])cube([ ArmLength+4, SlotSpacing, ShellThickness]);       
            }
        }
        
      } // end main union
      
    //we want to be sure the top slot misses the wratchet housing
    slotoffset = min (-ArmLength/4, -ElbowPartsScale* 55- (StrapWidth + 1)/2);

    //slots for strap, Arm Part 1
    rotate(a=[0,0,-atan((difWidths/2)/ArmLength)])translate([slotoffset - (StrapWidth + 1)/2, -7*ForeArmCircumferenceScale  , -ShellThickness ])cube([ StrapWidth + 1, 14*ForeArmCircumferenceScale, 30*ShellThickness]);
    
    //slots for strap, Arm Part 2
    rotate(a=[0,0,-atan((difWidths/2)/ArmLength)])translate([-3*ArmLength/4 - (StrapWidth + 1)/2, -7*ForeArmCircumferenceScale  , -ShellThickness ])cube([ StrapWidth + 1, 14*ForeArmCircumferenceScale, 30*ShellThickness]);
        
      if(liptype ==1)
        {
        //slots for strap
        translate([0,forearmWidth2 -7*ForeArmCircumferenceScale  , 0])rotate(a=[0,0,atan((difWidths/2)/ArmLength)])translate([slotoffset - (StrapWidth + 1)/2,0, ShellThickness-8 ])cube([ StrapWidth + 1, 14*ForeArmCircumferenceScale, 30*ForeArmCircumferenceScale]);
        
        //slots for strap
        translate([0,forearmWidth2 -7*ForeArmCircumferenceScale  , 0 ])rotate(a=[0,0,atan((difWidths/2)/ArmLength)])translate([-3*ArmLength/4 - (StrapWidth + 1)/2,0 , ShellThickness-8 ])cube([ StrapWidth + 1, 14*ForeArmCircumferenceScale, 30*ForeArmCircumferenceScale]);
        } else {
            
        //slots for strap
        //translate([0,forearmWidth2 -22.5  , 0])rotate(a=[0,0,atan((difWidths/2)/ArmLength)])translate([slotoffset- (StrapWidth + 1)/2,0, ShellThickness-8 ])cube([ StrapWidth + 1, 5, 30*ForeArmCircumferenceScale]);
        
        //slots for strap
        //translate([0,forearmWidth2 -22.5  , 0 ])rotate(a=[0,0,atan((difWidths/2)/ArmLength)])translate([-3*ArmLength/4 - (StrapWidth + 1)/2,0 , ShellThickness-8 ])cube([ StrapWidth + 1, 5, 30*ForeArmCircumferenceScale]);
        }
        
        // Make hole for wrist attachment bolt, note it is always a #4 or 3mm sheet metal screw
        rotate(a=[0,0,-atan((difWidths/2)/ArmLength)]) translate([-ArmLength + 7.5*ForeArmCircumferenceScale, 0, 0  ])cylinder(d=3.5, h=ForeArmCircumferenceScale * 200,center=true, $fn=20);
        rotate(a=[0,0,-atan((difWidths/2)/ArmLength)]) translate([-ArmLength + 7.5*ForeArmCircumferenceScale, 0, 10*ForeArmCircumferenceScale])cylinder(d=6.0, h=6,center=true, $fn=20);
    
    } //Difference slot holes

    
    //Put tops of slots back on
    
    rotate(a=[0,0,-atan((difWidths/2)/ArmLength)]) hull() {
        rotate(a=[90,-90,-90]) translate([8*ForeArmCircumferenceScale,4*ForeArmCircumferenceScale, 40*ForeArmCircumferenceScale])cylinder(d=7*ForeArmCircumferenceScale, h=ArmLength - 60*ForeArmCircumferenceScale);
        rotate(a=[90,-90,-90]) translate([8*ForeArmCircumferenceScale,-4*ForeArmCircumferenceScale, 40*ForeArmCircumferenceScale])cylinder(d=7*ForeArmCircumferenceScale, h=ArmLength - 60*ForeArmCircumferenceScale);
    
     }
    
}

//***************************
// MakeArmFlap() 
//***************************
module MakeArmFlap(polygonpoints1, startlength, stoplength) {
    
    forearmWidth2 = ForearmCircumferenceWPadding/2;
    WristWidth2 = WristCircumferenceWPadding/2;
    difWidths = forearmWidth2 - WristWidth2;
    
    difference() {
        
        union(){

     difference() {
        union(){linear_extrude(ShellThickness)
                polygon(polygonpoints1, paths=[[0,1,2,3]]);
            }


        MakeArmslots(startlength , stoplength);  
     
        }
        
        //lip on leading edge to glue on other stiffener
        translate([0, forearmWidth2 - 5*ForeArmCircumferenceScale, 0 ])rotate(a=[0,0,atan((difWidths/2)/ArmLength)])translate([-ArmLength-2, 0  , 0]){
                cube([ ArmLength+4, 5*ForeArmCircumferenceScale , ShellThickness]);
            translate([ArmLength+4,  4*ForeArmCircumferenceScale, ShellThickness ])
            rotate(a=[90,-90,-90]) linear_extrude(ArmLength+4)
            polygon(points=[[0,-1*ForeArmCircumferenceScale],[2*ForeArmCircumferenceScale,0],[0,1*ForeArmCircumferenceScale]], paths=[[0,1,2]]);
            }
        
        }
        
        //we want to be sure the top slot misses the wratchet housing
        slotoffset = min (-ArmLength/4, -ElbowPartsScale* 55- (StrapWidth + 1)/2);
        
        //slots for strap
        translate([0,forearmWidth2 -7*ForeArmCircumferenceScale  , 0])rotate(a=[0,0,atan((difWidths/2)/ArmLength)])translate([slotoffset - (StrapWidth + 1)/2,0, ShellThickness-8 ])cube([ StrapWidth + 1, 14*ForeArmCircumferenceScale, 30*ForeArmCircumferenceScale]);
        
        //slots for strap
        translate([0,forearmWidth2 -7*ForeArmCircumferenceScale  , 0 ])rotate(a=[0,0,atan((difWidths/2)/ArmLength)])translate([-3*ArmLength/4 - (StrapWidth + 1)/2,0 , ShellThickness-8 ])cube([ StrapWidth + 1, 14*ForeArmCircumferenceScale, 30*ForeArmCircumferenceScale]);
        
    }
}

//***************************
// MakeUpperArmLeatherTemplate() 
//***************************
module MakeUpperArmLeatherTemplate() {
    
    forearmWidth2 = ForearmCircumferenceWPadding/2;
    WristWidth2 = WristCircumferenceWPadding/2;
    difWidths = forearmWidth2 - WristWidth2;
    
    
    if(LeatherOrPlastic == "Leather") {
        
     difference() { 
     union(){
 
      difference() { 
        // the outline of UpperArm1
        polygonpoints1 = [[0,0],[-ArmLength,difWidths/2],[-ArmLength,WristWidth2 + difWidths/2],[0,forearmWidth2]];
        polygon(polygonpoints1, paths=[[0,1,2,3]]);
          
         //cut off the top flat
        translate([-15*ForeArmCircumferenceScale, -35  , -ShellThickness ])square([ 50, forearmWidth2 +50]);
    
        //Cut off bottom flat
        translate([-ArmLength - ArmLength/2 +  10* ForeArmCircumferenceScale, -35  , -ShellThickness ])square([ ArmLength, forearmWidth2 +50]);
          
      }
    
      //Note: the +0.001 is just to get the shapes to overlap
      rotate(a=[0,0,2*-atan((difWidths/2)/ArmLength)])translate([0,-forearmWidth2 +0.001]) 
      difference() {
          // the outline of UpperArm2
          polygonpoints2 = [[0,forearmWidth2/3],[-ArmLength, difWidths/2 + WristWidth2/3],[-ArmLength,WristWidth2 + difWidths/2],[0,forearmWidth2]];
      
        polygon(polygonpoints2, paths=[[0,1,2,3]]);
        
        //cut off the top flat
        translate([-15*ForeArmCircumferenceScale, -35  , -ShellThickness ])square([ 50, forearmWidth2 +50]);
    
        //Cut off bottom flat
        translate([-ArmLength - ArmLength/2 +  10* ForeArmCircumferenceScale, -35  , -ShellThickness ])square([ ArmLength, forearmWidth2 +50]);
          
      }
      
      translate([0,forearmWidth2]) rotate(a=[0,0,2*atan((difWidths/2)/ArmLength)])
      difference() {
          // the outline of UpperArm3
          polygonpoints2 = [[0,0],[-ArmLength, difWidths/2],[-ArmLength,WristWidth2 + difWidths/2 - WristWidth2/3],[0,forearmWidth2-forearmWidth2/3]];
      
        polygon(polygonpoints2, paths=[[0,1,2,3]]);
        
        //cut off the top flat
        translate([-15*ForeArmCircumferenceScale, -35  , -ShellThickness ])square([ 50, forearmWidth2 +50]);
    
        //Cut off bottom flat
        translate([-ArmLength - ArmLength/2 +  10* ForeArmCircumferenceScale, -35  , -ShellThickness ])square([ ArmLength, forearmWidth2 +50]);
          
      }
  }
      
        // Make hole for leather rivets for UpperArm1
        rotate(a=[0,0,-atan((difWidths/2)/ArmLength)]) translate([-3*ArmLength/8 , 0, 0  ])circle(d=RivetShaftDiameter+0.5, $fn=20);
        //Note: this rivet is always where the latch cover bolt is.
        rotate(a=[0,0,-atan((difWidths/2)/ArmLength)]) translate([-45*ElbowPartsScale, 0, 0  ])circle(d=RivetShaftDiameter+0.5, $fn=20);
  
         // Make hole for leather rivets for UpperArm2
         translate([0, forearmWidth2, 0  ])rotate(a=[0,0,atan((difWidths/2)/ArmLength)]) translate([-3*ArmLength/8 , 0, 0  ])circle(d=RivetShaftDiameter+0.5,  $fn=20);
        //Note: this rivet is always where the latch cover bolt is.
        translate([0, forearmWidth2, 0  ])rotate(a=[0,0,atan((difWidths/2)/ArmLength)]) translate([-45*ElbowPartsScale, 0, 0  ])circle(d=RivetShaftDiameter+0.5, $fn=20);
        
      }
        
    }
}


//***************************
// MakeLowerArmLeatherTemplate() 
//***************************
module MakeLowerArmLeatherTemplate() {
    
    forearmWidth2 = ForearmCircumferenceWPadding/2;
    WristWidth2 = WristCircumferenceWPadding/2;
    difWidths = forearmWidth2 - WristWidth2;
    
    
    if(LeatherOrPlastic == "Leather") {
        
     difference() { 
     union(){
 
      difference() { 
        // the outline of UpperArm1
        polygonpoints1 = [[0,0],[-ArmLength,difWidths/2],[-ArmLength,WristWidth2 + difWidths/2],[0,forearmWidth2]];
        polygon(polygonpoints1, paths=[[0,1,2,3]]);
         
        //cut off the top flat
        translate([-ArmLength - 50, -35  , -ShellThickness ])square([ 50, forearmWidth2 +50]);
    
        translate([ - ArmLength/2 -  10* ForeArmCircumferenceScale, -35  , -ShellThickness ])square([ ArmLength, forearmWidth2 +50]);
          
      }
    
      //Note: the +0.001 is just to get the shapes to overlap
      rotate(a=[0,0,2*-atan((difWidths/2)/ArmLength)])translate([0,-forearmWidth2 +0.001]) 
      difference() {
          // the outline of UpperArm2
          polygonpoints2 = [[0,forearmWidth2/3],[-ArmLength, difWidths/2 + WristWidth2/3],[-ArmLength,WristWidth2 + difWidths/2],[0,forearmWidth2]];
      
        polygon(polygonpoints2, paths=[[0,1,2,3]]);
        
        //cut off the top flat
        translate([-ArmLength - 50, -35  , -ShellThickness ])square([ 50, forearmWidth2 +50]);
    
        translate([ - ArmLength/2 -  10* ForeArmCircumferenceScale, -35  , -ShellThickness ])square([ ArmLength, forearmWidth2 +50]);
      }
      
      translate([0,forearmWidth2]) rotate(a=[0,0,2*atan((difWidths/2)/ArmLength)])
      difference() {
          // the outline of UpperArm3
          polygonpoints2 = [[0,0],[-ArmLength, difWidths/2],[-ArmLength,WristWidth2 + difWidths/2 - WristWidth2/3],[0,forearmWidth2-forearmWidth2/3]];
      
        polygon(polygonpoints2, paths=[[0,1,2,3]]);
        
        //cut off the top flat
        translate([-ArmLength - 50, -35  , -ShellThickness ])square([ 50, forearmWidth2 +50]);
    
        translate([ - ArmLength/2 -  10* ForeArmCircumferenceScale, -35  , -ShellThickness ])square([ ArmLength, forearmWidth2 +50]);
          
      }
  }
      
        // Make hole for leather rivets for LowerArm1
        rotate(a=[0,0,-atan((difWidths/2)/ArmLength)]) translate([- ArmLength/2 - 2.9*ArmLength/8 , 0, 0  ])circle(d=RivetShaftDiameter+0.5, $fn=20);
        
        rotate(a=[0,0,-atan((difWidths/2)/ArmLength)]) translate([- ArmLength/2 - 0.8*ArmLength/8, 0, 0  ])circle(d=RivetShaftDiameter+0.5, $fn=20);
  
        // Make hole for wrist attachment bolt, note it is always a 3mm bolt
        rotate(a=[0,0,-atan((difWidths/2)/ArmLength)])translate([-ArmLength, 0  , 0]){
            translate([7.5*ForeArmCircumferenceScale, 0 , 0  ])circle(d=3.5, $fn=20);
        }
  
         // Make holes for leather rivets for LowerArm2
          translate([0, forearmWidth2, 0  ])rotate(a=[0,0,atan((difWidths/2)/ArmLength)]) translate([- ArmLength/2 - 2.9*ArmLength/8 , 0, 0  ])circle(d=RivetShaftDiameter+0.5, $fn=20);
        
        translate([0, forearmWidth2, 0  ])rotate(a=[0,0,atan((difWidths/2)/ArmLength)]) translate([- ArmLength/2 - 0.8*ArmLength/8, 0, 0  ])circle(d=RivetShaftDiameter+0.5, $fn=20);
        
        translate([0, forearmWidth2 , 0 ])rotate(a=[0,0,atan((difWidths/2)/ArmLength)])translate([-ArmLength, 0  , 0]){
            
           // Make hole for string note always a 2 mm hole
           translate([ 20*ForeArmCircumferenceScale,0, 0  ]) circle(d=3.5,  $fn=21);    
            // Make hole for wrist attachment bolt, note it is always a 3mm bolt
            translate([7.5*ForeArmCircumferenceScale, 0 , 0  ])circle(d=3.5, $fn=20);
        }  
 
        
      }
        
    }
}

//***************************
// MakeUpperArm1() 
//***************************
module MakeUpperArm1() {
    
    forearmWidth2 = ForearmCircumferenceWPadding/2;
    WristWidth2 = WristCircumferenceWPadding/2;
    difWidths = forearmWidth2 - WristWidth2;
    
    difference() {
        union(){
        difference() {
            
            union() {
            MakeArmBase(1, 
                [[0,0],[-ArmLength,difWidths/2],[-ArmLength,WristWidth2 + difWidths/2],[0,forearmWidth2]], 0 , -ArmLength/2);
      
            
            }
            
            //cut off the top flat
            translate([-15*ForeArmCircumferenceScale, -35  , -ShellThickness ])cube([ 50, forearmWidth2 +50, 30]);
        
            //Cut off bottom flat
            translate([-ArmLength - ArmLength/2 +  10* ForeArmCircumferenceScale, -35  , -ShellThickness ])cube([ ArmLength, forearmWidth2 +50, 30]);
            
        
            // Cut arm stiffener that reached into Rachet housing
            translate([-46.5*ForeArmCircumferenceScale, -10* ForeArmCircumferenceScale  , 10* ForeArmCircumferenceScale])rotate(a=[0,0,-atan((difWidths/2)/ArmLength)])cube([ 30* ForeArmCircumferenceScale, 30 * ForeArmCircumferenceScale, 30*ForeArmCircumferenceScale]);
            
        }

        
        //add attachment to LowerArm1
        rotate(a=[0,0,-atan((difWidths/2)/ArmLength)])translate([-ArmLength/2 +10* ForeArmCircumferenceScale , -(ForeArmCircumferenceScale * 4)/2+2*ForeArmCircumferenceScale , 0 ])
        difference() {
        rotate(a=[90,0,-90]) linear_extrude(20* ForeArmCircumferenceScale )
                polygon(points=[[0 ,ForeArmCircumferenceScale * 8.5],
        [-3*ForeArmCircumferenceScale, ForeArmCircumferenceScale * 8.5 /2],
        [0,-1],
        [ 3*ForeArmCircumferenceScale, ForeArmCircumferenceScale * 8.5 /2]],
        paths=[[0,1,2,3]]);
            
            //cut the bottom of attachemnt to arm 2 flat
            translate([-20.5* ForeArmCircumferenceScale,-5* ForeArmCircumferenceScale,-10* ForeArmCircumferenceScale])cube([21* ForeArmCircumferenceScale, 10* ForeArmCircumferenceScale, 10* ForeArmCircumferenceScale ]);

        }
        
        difference() {
            //latch and hinge section
            rotate(a=[0,0,-atan((difWidths/2)/ArmLength)]) UpperArm1();
                    
            // Make hole for Elbow threads
            // the -0.05 on bolt diameter is to make sure threads attach to walls
            cylinder(d=ElbowBoltDiameter-0.05, h=ElbowPartsScale * 200,center=true, $fn=20);
            
            //Cut the top off the cuff post. We do this here because we always want a 1mm gap between the ratchet and the cuff. Normall scaling makes it too big for large arms and too small for small arms
            translate([0, 0, ElbowPartsScale * 22 +1 ]) cylinder(d=ElbowPartsScale * 12 + 1, h=ElbowPartsScale * 10,center=true, $fn=20);
        }
        
            //make  Elbow bolt threads
        difference() {
            translate([0, 0, -2 * ElbowPartsScale  ])thread_in(ElbowBoltDiameter, ElbowPartsScale * 28);
            
            translate([0, 0, ElbowPartsScale * -5]) cylinder(d=ElbowBoltDiameter + 1, h=ElbowPartsScale * 10,center=true, $fn=20);
               
            translate([0, 0, ElbowPartsScale * 22 +1 ]) cylinder(d=ElbowBoltDiameter + 1, h=ElbowPartsScale * 10,center=true, $fn=20);
        }
    }

    
    if(LeatherOrPlastic != "Leather") {
        // Make hole for Latch cover, note it is always a #4 or 3mm sheet metel screw
        rotate(a=[0,0,-atan((difWidths/2)/ArmLength)]) translate([-45*ElbowPartsScale, 0, 0  ])cylinder(d=2.5, h=ElbowPartsScale * 200,center=true, $fn=20);

    } else {
        // Make hole for leather rivets 
        rotate(a=[0,0,-atan((difWidths/2)/ArmLength)]) translate([-3*ArmLength/8 , 0, 0  ])cylinder(d=RivetShaftDiameter+0.5, h=ElbowPartsScale * 200,center=true, $fn=20);
        //Note: this rivet is always where the latch cover bolt is.
        rotate(a=[0,0,-atan((difWidths/2)/ArmLength)]) translate([-45*ElbowPartsScale, 0, 0  ])cylinder(d=RivetShaftDiameter+0.5, h=ElbowPartsScale * 200,center=true, $fn=20);
        }
        
        // Make hole for Latch rotation pin, note it is always a 2mm rode
        rotate(a=[0,0,-atan((difWidths/2)/ArmLength)]) translate([-17.701*ElbowPartsScale, -4.25*ElbowPartsScale, 10*ElbowPartsScale +ShellThickness + 1.5  ])cylinder(d=2.7, h=ElbowPartsScale * 20,center=true, $fn=20);
    
    // cut 2mm holes for metal rods
    rotate(a=[0,0,-atan((difWidths/2)/ArmLength)]){
        rotate(a=[90,-90,-90]) translate([8.5*ForeArmCircumferenceScale,4*ForeArmCircumferenceScale, 51.5*ForeArmCircumferenceScale])cylinder(d=2.4, h=ArmLength - 60*ForeArmCircumferenceScale);
        rotate(a=[90,-90,-90]) translate([8.5*ForeArmCircumferenceScale,-4*ForeArmCircumferenceScale, 51.5*ForeArmCircumferenceScale])cylinder(d=2.4, h=ArmLength - 60*ForeArmCircumferenceScale);
             }
    
         if(LeatherOrPlastic != "Leather") {
        //cut area for lip on leading edge to glue on other arm side
    translate([0,  -5*ForeArmCircumferenceScale, 0 ])rotate(a=[0,0,-atan((difWidths/2)/ArmLength)])translate([-ArmLength-2, 0  , 0]){
        difference() {
            union(){
                
           translate([-17.5*ForeArmCircumferenceScale,  -7*ForeArmCircumferenceScale, -1 ])cube([ ArmLength+4, 12*ForeArmCircumferenceScale , ShellThickness+1]);
           translate([ArmLength+4-17.5*ForeArmCircumferenceScale,  4*ForeArmCircumferenceScale, ShellThickness ])
                rotate(a=[90,-90,-90]) linear_extrude(ArmLength+4)
                polygon(points=[[-0.1,-1*ForeArmCircumferenceScale-0.2],[2*ForeArmCircumferenceScale+0.2,0],[-0.1,1*ForeArmCircumferenceScale+0.2]], paths=[[0,1,2]]);
                //} else {
                    //translate([-17.5*ForeArmCircumferenceScale,  -7*ForeArmCircumferenceScale, -1 ])cube([ ArmLength+4, 25*ForeArmCircumferenceScale , ShellThickness+1]);
                //}
            }
            
            //we want to be sure the top slot misses the wratchet housing
            slotoffset = min (-ArmLength/4, -ElbowPartsScale* 55- (StrapWidth + 1)/2);
                
            //Don't carve in slot
            translate([ArmLength+2 + slotoffset- (StrapWidth + 1)/2 + 0.2*ForeArmCircumferenceScale, -6 , -ShellThickness*2 ])cube([ StrapWidth-1, 22*ForeArmCircumferenceScale, 30*ShellThickness]);
                
            //don't carve out attachemnt to LowerArm2
            translate([ArmLength+2 - ArmLength/2 - 10* ForeArmCircumferenceScale  - 3.5* ForeArmCircumferenceScale, -6 , -ShellThickness*2 ])cube([ 20* ForeArmCircumferenceScale +1 , 22*ForeArmCircumferenceScale, 30*ShellThickness]);
            
            }
          }
        } else {
            
            //cut ShellThickness off the bottom of entire part. For this leather version the leather itself willadd that back on.
            translate([-7*ArmLength/4,-ForearmCircumferenceWPadding/2 , -1])cube([ ArmLength *2, ForearmCircumferenceWPadding*2, ShellThickness + 1]);
            
        }
    
    
    }
    

}

//***************************
// MakeUpperArm2() 
//***************************
module MakeUpperArm2() {
    
    forearmWidth2 = ForearmCircumferenceWPadding/2;
    WristWidth2 = WristCircumferenceWPadding/2;
    difWidths = forearmWidth2 - WristWidth2;
    
    difference() {
        union(){
        difference() {

            MakeArmBase(2, [[0,0],[-ArmLength,difWidths/2],[-ArmLength,WristWidth2 + difWidths/2- 10],[0,forearmWidth2-10]], 0 , -ArmLength/2);
            
            //cut off the top flat
            translate([-15*ForeArmCircumferenceScale, -35  , -ShellThickness ])cube([ 50, forearmWidth2 +50, 30]);
        
            translate([-ArmLength - ArmLength/2 +  10* ForeArmCircumferenceScale, -35  , -ShellThickness ])cube([ ArmLength, forearmWidth2 +50, 30]);
            
        }          

        difference () {
            //Hinge section
            rotate(a=[0,0,-atan((difWidths/2)/ArmLength)]) UpperArm2();
                
            // Make hole for Elbow threads
            // the -0.05 on bolt diameter is to make sure threads attach to walls
            cylinder(d=ElbowBoltDiameter-0.05, h=ElbowPartsScale * 200,center=true, $fn=20);
        }
        
        //make  Elbow bolt threads
        difference() {
            translate([0, 0, -2 * ElbowPartsScale  ])thread_in(ElbowBoltDiameter, ElbowPartsScale * 20);
            
            translate([0, 0, ElbowPartsScale * -5]) cylinder(d=ElbowBoltDiameter + 1, h=ElbowPartsScale * 10,center=true, $fn=20);
               
            translate([0, 0, ElbowPartsScale * 15]) cylinder(d=ElbowBoltDiameter + 1, h=ElbowPartsScale * 10,center=true, $fn=20);
        }
                    
        //add attachemnt to LowerArm2   
        rotate(a=[0,0,-atan((difWidths/2)/ArmLength)])translate([-ArmLength/2 +10* ForeArmCircumferenceScale , -(ForeArmCircumferenceScale * 4)/2+2*ForeArmCircumferenceScale , 0 ])
        difference(){
            rotate(a=[90,0,-90]) linear_extrude(20* ForeArmCircumferenceScale )
                polygon(points=[[0 ,ForeArmCircumferenceScale * 8.5],
        [-3*ForeArmCircumferenceScale, ForeArmCircumferenceScale * 8.5 /2],
        [0,-1],
        [ 3*ForeArmCircumferenceScale, ForeArmCircumferenceScale * 8.5 /2]],
        paths=[[0,1,2,3]]);
            
            //cut the bottom of attachement to arm 2 flat
            translate([-20.5* ForeArmCircumferenceScale,-5* ForeArmCircumferenceScale,-10* ForeArmCircumferenceScale])cube([21* ForeArmCircumferenceScale, 10* ForeArmCircumferenceScale, 10* ForeArmCircumferenceScale ]);
        }
    }
    
    
    
    if(LeatherOrPlastic == "Leather"){
        // Make hole for leather rivets 
        rotate(a=[0,0,-atan((difWidths/2)/ArmLength)]) translate([-3*ArmLength/8 , 0, 0  ])cylinder(d=RivetShaftDiameter+0.5, h=ElbowPartsScale * 200,center=true, $fn=20);
        //Note: this rivet is always where the latch cover bolt is.
        rotate(a=[0,0,-atan((difWidths/2)/ArmLength)]) translate([-45*ElbowPartsScale, 0, 0  ])cylinder(d=RivetShaftDiameter+0.5, h=ElbowPartsScale * 200,center=true, $fn=20);
        
        // recess for rivet head. All rivet heads are 10mm. 
        rotate(a=[0,0,-atan((difWidths/2)/ArmLength)]) translate([-45*ElbowPartsScale, 0, ForeArmCircumferenceScale * 21.5 ])cylinder(d=10, h=ForeArmCircumferenceScale * 20,center=true, $fn=20);
        }
    
    
       // cut 2mm holes for metal rods
    rotate(a=[0,0,-atan((difWidths/2)/ArmLength)]){
        rotate(a=[90,-90,-90]) translate([8.5*ForeArmCircumferenceScale,4*ForeArmCircumferenceScale, 51.5*ForeArmCircumferenceScale])cylinder(d=2.4, h=ArmLength - 60*ForeArmCircumferenceScale);
        rotate(a=[90,-90,-90]) translate([8.5*ForeArmCircumferenceScale,-4*ForeArmCircumferenceScale, 51.5*ForeArmCircumferenceScale])cylinder(d=2.4, h=ArmLength - 60*ForeArmCircumferenceScale);
             }
    
     if(LeatherOrPlastic != "Leather") {
    //cut area for lip on leading edge to glue on other arm side
    translate([0,  -5*ForeArmCircumferenceScale, 0 ])rotate(a=[0,0,-atan((difWidths/2)/ArmLength)])translate([-ArmLength-2, 0  , 0]){
        difference() {
            union(){
                
           translate([-17.5*ForeArmCircumferenceScale,  -10*ForeArmCircumferenceScale, -1 ])cube([ ArmLength+4, 15*ForeArmCircumferenceScale , ShellThickness+1]);
           translate([ArmLength+4-17.5*ForeArmCircumferenceScale,  4*ForeArmCircumferenceScale, ShellThickness ])
                rotate(a=[90,-90,-90]) linear_extrude(ArmLength+4)
                polygon(points=[[-0.1,-1*ForeArmCircumferenceScale-0.2],[3*ForeArmCircumferenceScale+0.2,0],[-0.1,1*ForeArmCircumferenceScale+0.2]], paths=[[0,1,2]]);
                //} else {
                    //translate([-17.5*ForeArmCircumferenceScale,  -10*ForeArmCircumferenceScale, -1 ])cube([ ArmLength+4, 35*ForeArmCircumferenceScale , ShellThickness+1]);
                //}
            }
            
            //we want to be sure the top slot misses the wratchet housing
            slotoffset = min (-ArmLength/4, -ElbowPartsScale* 55- (StrapWidth + 1)/2);
                
            //Don't carve in slot
            translate([ArmLength+2 + slotoffset- (StrapWidth + 1)/2 + 0.2*ForeArmCircumferenceScale, -6 , -ShellThickness*2 ])cube([ StrapWidth-1, 22*ForeArmCircumferenceScale, 30*ShellThickness]);
                
            //don't carve out attachemnt to LowerArm2
            translate([ArmLength+2 - ArmLength/2 - 10* ForeArmCircumferenceScale  - 3.5* ForeArmCircumferenceScale, -6 , -ShellThickness*2 ])cube([ 20* ForeArmCircumferenceScale +1 , 22*ForeArmCircumferenceScale, 30*ShellThickness]);
            
            }
          }
        } else {
            //cut ShellThickness off the bottom of entire part. For this leather version the leather itself willadd that back on.
            translate([-7*ArmLength/4,-ForearmCircumferenceWPadding/2 , -1])cube([ ArmLength *2, ForearmCircumferenceWPadding*2, ShellThickness + 1]);
        }
    }
    
}


//***************************
// MakeUpperArm3() 
//***************************
module MakeUpperArm3() {
    
    if(LeatherOrPlastic != "Leather") {
    
    forearmWidth2 = ForearmCircumferenceWPadding/2;
    WristWidth2 = WristCircumferenceWPadding/2;
    difWidths = forearmWidth2 - WristWidth2;
    

    difference() {
        
        union() {
        MakeArmFlap(
            [[0,forearmWidth2/2],[-ArmLength,forearmWidth2/2],[-ArmLength,WristWidth2 + difWidths/2],[0,forearmWidth2]], 0 , -ArmLength/2);
            
            translate([-ArmLength-2, forearmWidth2/2  , 0])cube([ ArmLength+4, SlotSpacing, ShellThickness]);
       
        }
        
        //cut off the top flat
        translate([-15*ForeArmCircumferenceScale, -35  , -ShellThickness ])cube([ 50, forearmWidth2 +50, 30]);
    
        //Cut off bottom flat
        translate([-ArmLength - ArmLength/2 +  10* ForeArmCircumferenceScale, -35  , -ShellThickness ])cube([ ArmLength, forearmWidth2 +50, 30]);
    
     translate([0, forearmWidth2 , 0 ])rotate(a=[0,0,atan((difWidths/2)/ArmLength)]) {

        //continue hole for latch cover screw, note it is always a #4 or 3mm sheet metal
        translate([-45*ElbowPartsScale, 0, 11*ElbowPartsScale-ElbowPartsScale * 100])cylinder(d=2.5, h=ElbowPartsScale * 200,center=true, $fn=30);
    }
        
    }
    }
    
}



//***************************
// MakeLowerArm1() 
//***************************
module MakeLowerArm1() {
    
    forearmWidth2 = ForearmCircumferenceWPadding/2;
    WristWidth2 = WristCircumferenceWPadding/2;
    difWidths = forearmWidth2 - WristWidth2;
    
    difference() {
        
    union(){
    difference() {

            MakeArmBase(1, [[0,-0],[-ArmLength,difWidths/2 ],[-ArmLength,WristWidth2 + difWidths/2],[0,forearmWidth2]], -ArmLength/2 , -ArmLength);

     
        //cut off the top flat
        translate([-ArmLength - 50, -35  , -ShellThickness ])cube([ 50, forearmWidth2 +50, 30]);
    
        translate([ - ArmLength/2 -  10* ForeArmCircumferenceScale, -35  , -ShellThickness ])cube([ ArmLength, forearmWidth2 +50, 30]);
            
         //Cut angle off glueable triangle end
        translate([ - ArmLength -  7*ForeArmCircumferenceScale, WristWidth2 + difWidths /2 -  ForeArmCircumferenceScale*5, ShellThickness+ 7*ForeArmCircumferenceScale ])rotate(a=[0,45,0])cube([ ForeArmCircumferenceScale*10, ForeArmCircumferenceScale*10 , ForeArmCircumferenceScale*10]);
    

         translate([0, forearmWidth2 , 0 ])rotate(a=[0,0,atan((difWidths/2)/ArmLength)])translate([-ArmLength, 0  , 0]){
        
            // Make hole for wrist attachment bolt, note it is always a 3mm bolt
            translate([7.5*ForeArmCircumferenceScale, 0 , 0  ])cylinder(d=3.5, h=ForeArmCircumferenceScale * 200,center=true, $fn=20);
        }
        
        // Make hole for string note always a 3 mm hole
        rotate(a=[0,0,-atan((difWidths/2)/ArmLength)]) translate([-ArmLength + 22*ForeArmCircumferenceScale, 0, 0  ])rotate(a=[0,20,0])cylinder(d=3, h=ForeArmCircumferenceScale * 200,center=true, $fn=20);
        
        }
        
    difference() {
        //add attachment to LowerArm1
        rotate(a=[0,0,-atan((difWidths/2)/ArmLength)]) hull() {
            rotate(a=[90,-90,-90]) translate([8*ForeArmCircumferenceScale,4*ForeArmCircumferenceScale, ArmLength/2 -12* ForeArmCircumferenceScale+1])cylinder(d=7*ForeArmCircumferenceScale, h=ForeArmCircumferenceScale * 28);
            rotate(a=[90,-90,-90]) translate([8*ForeArmCircumferenceScale,-4*ForeArmCircumferenceScale, ArmLength/2 -12* ForeArmCircumferenceScale+1])cylinder(d=7*ForeArmCircumferenceScale, h=ForeArmCircumferenceScale * 28);
            rotate(a=[90,-90,-90]) translate([2.5*ForeArmCircumferenceScale,3.5*ForeArmCircumferenceScale, ArmLength/2 -12* ForeArmCircumferenceScale+1])cylinder(d=5*ForeArmCircumferenceScale, h=ForeArmCircumferenceScale * 28);
            rotate(a=[90,-90,-90]) translate([2.5*ForeArmCircumferenceScale,-3.5*ForeArmCircumferenceScale, ArmLength/2 -12* ForeArmCircumferenceScale+1])cylinder(d=5*ForeArmCircumferenceScale, h=ForeArmCircumferenceScale * 28);
        }
        
         //remove attachment to UpperArm1        
         rotate(a=[0,0,-atan((difWidths/2)/ArmLength)])translate([-ArmLength/2 +10* ForeArmCircumferenceScale , -(ForeArmCircumferenceScale * 4)/2+2*ForeArmCircumferenceScale , 0 ])
        rotate(a=[90,0,-90]) linear_extrude(20* ForeArmCircumferenceScale +0.2)
                polygon(points=[[0 ,ForeArmCircumferenceScale * 8.5 + 0.2],
        [-3*ForeArmCircumferenceScale - 0.2, ForeArmCircumferenceScale * 8.5 /2],
        [0, -1.2],
        [ 3*ForeArmCircumferenceScale + 0.2, ForeArmCircumferenceScale * 8.5 /2]],
        paths=[[0,1,2,3]]);
        
        translate([ - ArmLength/2 +  9.75* ForeArmCircumferenceScale, -35  , -ShellThickness ])cube([ ArmLength, forearmWidth2 +50, 30]);

    }
}

    if(LeatherOrPlastic == "Leather"){
        // Make hole for leather rivets 
        rotate(a=[0,0,-atan((difWidths/2)/ArmLength)]) translate([- ArmLength/2 - 2.9*ArmLength/8 , 0, 0  ])cylinder(d=RivetShaftDiameter+0.5, h=ElbowPartsScale * 200,center=true, $fn=20);
        
        rotate(a=[0,0,-atan((difWidths/2)/ArmLength)]) translate([- ArmLength/2 - 0.8*ArmLength/8, 0, 0  ])cylinder(d=RivetShaftDiameter+0.5, h=ElbowPartsScale * 200,center=true, $fn=20);
        }

            // cut 2mm holes for metal rods
    rotate(a=[0,0,-atan((difWidths/2)/ArmLength)]){
        rotate(a=[90,-90,-90]) translate([8.5*ForeArmCircumferenceScale,4*ForeArmCircumferenceScale, 51.5*ForeArmCircumferenceScale])cylinder(d=2.4, h=ArmLength - 63*ForeArmCircumferenceScale);
        rotate(a=[90,-90,-90]) translate([8.5*ForeArmCircumferenceScale,-4*ForeArmCircumferenceScale, 51.5*ForeArmCircumferenceScale])cylinder(d=2.4, h=ArmLength - 63*ForeArmCircumferenceScale);
             }
        
             if(LeatherOrPlastic != "Leather") {
            //cut area for lip on leading edge to glue on other arm side
    translate([0,  -5*ForeArmCircumferenceScale, 0 ])rotate(a=[0,0,-atan((difWidths/2)/ArmLength)])translate([-ArmLength-2, 0  , 0]){
        difference() {
            union(){
                
           translate([-15*ForeArmCircumferenceScale,  -5*ForeArmCircumferenceScale, -1 ])cube([ ArmLength+4, 10*ForeArmCircumferenceScale , ShellThickness+1]);
           translate([ArmLength+4,  4*ForeArmCircumferenceScale, ShellThickness ])
                rotate(a=[90,-90,-90]) linear_extrude(ArmLength+4)
                polygon(points=[[-0.1,-1*ForeArmCircumferenceScale-0.2],[2*ForeArmCircumferenceScale+0.2,0],[-0.1,1*ForeArmCircumferenceScale+0.2]], paths=[[0,1,2]]);
                //} else {
                    //translate([-15*ForeArmCircumferenceScale,  -5*ForeArmCircumferenceScale, -1 ])cube([ ArmLength+4, 20*ForeArmCircumferenceScale , ShellThickness+1]);
                //}
            }
                
            //Don't carve in slot
            translate([ArmLength+2 - 3*ArmLength/4 - (StrapWidth + 1)/2 - 0.2*ForeArmCircumferenceScale, -6 , -ShellThickness*2 ])cube([ StrapWidth-1*ForeArmCircumferenceScale, 22*ForeArmCircumferenceScale, 30*ShellThickness]);
                
            //don't carve out attachemnt to UpperArm2
            translate([ArmLength+2 - ArmLength/2 - 10* ForeArmCircumferenceScale, -6 , -ShellThickness*2 ])cube([ 20* ForeArmCircumferenceScale +1 , 22*ForeArmCircumferenceScale, 30*ShellThickness]);
            
            }
          }
        } else {
            //cut ShellThickness off the bottom of entire part. For this leather version the leather itself willadd that back on.
            translate([-7*ArmLength/4,-ForearmCircumferenceWPadding/2 , -1])cube([ ArmLength *2, ForearmCircumferenceWPadding*2, ShellThickness + 1]);
        }
    }
    
}


//***************************
// MakeLowerArm2() 
//***************************
module MakeLowerArm2() {
    
    forearmWidth2 = ForearmCircumferenceWPadding/2;
    WristWidth2 = WristCircumferenceWPadding/2;
    difWidths = forearmWidth2 - WristWidth2;
    difference() {
        
    union(){
    difference() {
 
        MakeArmBase(2, [[0,0],[-ArmLength+10*ForeArmCircumferenceScale,difWidths/2],[-ArmLength+10*ForeArmCircumferenceScale,WristWidth2 + difWidths/2- 10],[0,forearmWidth2-10]], -ArmLength/2 , -ArmLength);
   
        //cut off the top flat
        //translate([-ArmLength - 50, -35  , -ShellThickness ])cube([ 50, forearmWidth2 +50, 30]);
    
        translate([ - ArmLength/2 -  10* ForeArmCircumferenceScale, -35  , -ShellThickness ])cube([ ArmLength, forearmWidth2 +50, 30]);
    
    
    }
    difference() {
        //add attachment to LowerArm2
        rotate(a=[0,0,-atan((difWidths/2)/ArmLength)]) hull() {
            rotate(a=[90,-90,-90]) translate([8*ForeArmCircumferenceScale,4*ForeArmCircumferenceScale, ArmLength/2 -12* ForeArmCircumferenceScale+1])cylinder(d=7*ForeArmCircumferenceScale, h=ForeArmCircumferenceScale * 28);
            rotate(a=[90,-90,-90]) translate([8*ForeArmCircumferenceScale,-4*ForeArmCircumferenceScale, ArmLength/2 -12* ForeArmCircumferenceScale+1])cylinder(d=7*ForeArmCircumferenceScale, h=ForeArmCircumferenceScale * 28);
            rotate(a=[90,-90,-90]) translate([2.5*ForeArmCircumferenceScale,3.5*ForeArmCircumferenceScale, ArmLength/2 -12* ForeArmCircumferenceScale+1])cylinder(d=5*ForeArmCircumferenceScale, h=ForeArmCircumferenceScale * 28);
            rotate(a=[90,-90,-90]) translate([2.5*ForeArmCircumferenceScale,-3.5*ForeArmCircumferenceScale, ArmLength/2 -12* ForeArmCircumferenceScale+1])cylinder(d=5*ForeArmCircumferenceScale, h=ForeArmCircumferenceScale * 28);
        }
        
        //remove attachment to UpperArm2       
         rotate(a=[0,0,-atan((difWidths/2)/ArmLength)])translate([-ArmLength/2 +10* ForeArmCircumferenceScale , -(ForeArmCircumferenceScale * 4)/2+2*ForeArmCircumferenceScale , 0 ])
        rotate(a=[90,0,-90]) linear_extrude(20* ForeArmCircumferenceScale +0.2)
                polygon(points=[[0 ,ForeArmCircumferenceScale * 8.5 + 0.2],
        [-3*ForeArmCircumferenceScale - 0.2, ForeArmCircumferenceScale * 8.5 /2],
        [0, -1.2],
        [ 3*ForeArmCircumferenceScale + 0.2, ForeArmCircumferenceScale * 8.5 /2]],
        paths=[[0,1,2,3]]);
        
       translate([ - ArmLength/2 +  9.75* ForeArmCircumferenceScale, -35  , -ShellThickness ])cube([ ArmLength, forearmWidth2 +50, 30]);
    }
}

    if(LeatherOrPlastic == "Leather"){
        // Make hole for leather rivets 
        rotate(a=[0,0,-atan((difWidths/2)/ArmLength)]) translate([- ArmLength/2 - 2.9*ArmLength/8 , 0, 0  ])cylinder(d=RivetShaftDiameter+0.5, h=ElbowPartsScale * 200,center=true, $fn=20);
        
        rotate(a=[0,0,-atan((difWidths/2)/ArmLength)]) translate([- ArmLength/2 - 0.8*ArmLength/8, 0, 0  ])cylinder(d=RivetShaftDiameter+0.5, h=ElbowPartsScale * 200,center=true, $fn=20);
        }

    // cut 2mm holes for metal rods
    rotate(a=[0,0,-atan((difWidths/2)/ArmLength)]){
        rotate(a=[90,-90,-90]) translate([8.5*ForeArmCircumferenceScale,4*ForeArmCircumferenceScale, 51.5*ForeArmCircumferenceScale])cylinder(d=2.4, h=ArmLength - 63*ForeArmCircumferenceScale);
        rotate(a=[90,-90,-90]) translate([8.5*ForeArmCircumferenceScale,-4*ForeArmCircumferenceScale, 51.5*ForeArmCircumferenceScale])cylinder(d=2.4, h=ArmLength - 63*ForeArmCircumferenceScale);
    }

    if(LeatherOrPlastic != "Leather") {
        //cut area for lip on leading edge to glue on other arm side
        translate([0,  -5*ForeArmCircumferenceScale, 0 ])rotate(a=[0,0,-atan((difWidths/2)/ArmLength)])translate([-ArmLength-2, 0  , 0]){
        difference() {
            union(){

           translate([-15*ForeArmCircumferenceScale,  -5*ForeArmCircumferenceScale, -1 ])cube([ ArmLength+4, 10*ForeArmCircumferenceScale , ShellThickness+1]);
           translate([ArmLength+4,  4*ForeArmCircumferenceScale, ShellThickness ])
                rotate(a=[90,-90,-90]) linear_extrude(ArmLength+4)
                polygon(points=[[-0.1,-1*ForeArmCircumferenceScale-0.2],[3*ForeArmCircumferenceScale+0.2,0],[-0.1,1*ForeArmCircumferenceScale+0.2]], paths=[[0,1,2]]);
                //} else {
                  //  translate([-15*ForeArmCircumferenceScale,  -5*ForeArmCircumferenceScale, -1 ])cube([ ArmLength+4, 20*ForeArmCircumferenceScale , ShellThickness+1]);
                //}
            }
                
            //Don't carve in slot
            translate([ArmLength+2 - 3*ArmLength/4 - (StrapWidth + 1)/2 - 0.2*ForeArmCircumferenceScale, -6 , -ShellThickness*2 ])cube([ StrapWidth-1*ForeArmCircumferenceScale, 22*ForeArmCircumferenceScale, 30*ShellThickness]);
                
            //don't carve out attachment to UpperArm2
            translate([ArmLength+2 - ArmLength/2 - 10* ForeArmCircumferenceScale, -6 , -ShellThickness*2 ])cube([ 20* ForeArmCircumferenceScale +1 , 22*ForeArmCircumferenceScale, 30*ShellThickness]);
            
            }
          }
        } else {
            //cut ShellThickness off the bottom of entire part. For this leather version the leather itself willadd that back on.
            translate([-7*ArmLength/4,-ForearmCircumferenceWPadding/2 , -1])cube([ ArmLength *2, ForearmCircumferenceWPadding*2, ShellThickness + 1]);
        }
    }
}

//***************************
// MakeLowerArm3() 
//***************************
module MakeLowerArm3() {
    
    if(LeatherOrPlastic != "Leather") {
        forearmWidth2 = ForearmCircumferenceWPadding/2;
        WristWidth2 = WristCircumferenceWPadding/2;
        difWidths = forearmWidth2 - WristWidth2;
        

        difference() {
            
            union() {
            MakeArmFlap([[0,forearmWidth2/2],[-ArmLength+10*ForeArmCircumferenceScale,forearmWidth2/2],[-ArmLength+10*ForeArmCircumferenceScale,WristWidth2 + difWidths/2],[0,forearmWidth2]], -ArmLength/2 , -ArmLength);
                
                //Add solid lip on open side
                translate([-ArmLength+10*ForeArmCircumferenceScale, forearmWidth2/2  , 0])cube([ ArmLength+4, SlotSpacing, ShellThickness]);
           
            }
                    //cut off the top flat
        translate([-ArmLength - 50, -35  , -ShellThickness ])cube([ 50, forearmWidth2 +50, 30]);

        translate([ - ArmLength/2 -  10* ForeArmCircumferenceScale, -35  , -ShellThickness ])cube([ ArmLength, forearmWidth2 +50, 30]);
            
            //Cut angle off glueable triangle end
            translate([ - ArmLength -  7*ForeArmCircumferenceScale, WristWidth2 + difWidths /2 -  ForeArmCircumferenceScale*5, ShellThickness+ 7*ForeArmCircumferenceScale ])rotate(a=[0,45,0])cube([ ForeArmCircumferenceScale*10, ForeArmCircumferenceScale*10 , ForeArmCircumferenceScale*10]);
            
                    
        translate([0, forearmWidth2 , 0 ])rotate(a=[0,0,atan((difWidths/2)/ArmLength)])translate([-ArmLength, 0  , 0]){
            
            // Make hole for string note always a 2 mm hole
            translate([ 25*ForeArmCircumferenceScale,0, 0  ]) rotate(a=[0,30,0])cylinder(d=2, h=ForeArmCircumferenceScale * 200,center=true, $fn=20);
            
            // Make hole for wrist attachment bolt, note it is always a 3mm bolt
            translate([7.5*ForeArmCircumferenceScale, 0 , 0  ])cylinder(d=3.5, h=ForeArmCircumferenceScale * 200,center=true, $fn=20);
        }  

        } 
    }

}



//***************************
// MakeCuffslots1() 
//***************************
module MakeCuffslots1() {
    
    for(y = [0 : (SlotWidth + SlotSize)*2 : BicepCircumferenceWPadding]){
        for(x = [0 : (SlotLength + SlotSpacing) :  CuffLength]){
            // the extra thickness is because the difference is not exact
            translate([x, y, -0.5])cube([ SlotLength,SlotSize, ShellThickness + 1]);
        }
    }

    for(y = [(SlotWidth + SlotSize) : (SlotWidth + SlotSize)*2 : BicepCircumferenceWPadding]){
        for(x = [-(SlotLength + SlotSpacing)/2 : (SlotLength + SlotSpacing) :  CuffLength + (SlotLength + SlotSpacing)]){
            // the extra thickness is because the difference is not exact
            translate([x, y, -0.5])cube([SlotLength, SlotSize, ShellThickness + 1]);
        }
    }
}


//***************************
// MakeCuffBase() 
//***************************
module MakeCuffBase(oneOrTwo, CuffWidth, CuffYoffset, offset) {
    
    difference() {
        union() {//91.5
            
        if(LeatherOrPlastic != "Leather")
        translate([CuffScale  * 49, CuffYoffset , 0 ])
             difference() {
                 union() {
                // the plate with slots
                difference() {
                    translate([0, 0 , 0 ]) cube([ CuffLength, CuffWidth, ShellThickness]);

                    MakeCuffslots1();
                }

                if(oneOrTwo == 1) {
                    //solid on end
                    translate([0, 0 , 0 ])cube([ CuffLength, 3*CuffScale, ShellThickness/2]);

                    //lip on leading edge to glue on other stiffener
                    translate([0, BicepCircumferenceWPadding/2 -CuffYoffset - 5.5*CuffScale- CuffScale * 0.25 , 0 ])cube([ CuffLength, 5.25*CuffScale , ShellThickness]);
                    translate([CuffLength, BicepCircumferenceWPadding/2 -CuffYoffset  - 1.25*CuffScale, ShellThickness ])
                    rotate(a=[90,-90,-90]) linear_extrude(CuffLength)
                        polygon(points=[[0,-1*CuffScale],[3*CuffScale,0],[0,1*CuffScale]], paths=[[0,1,2]]);
                    
                     
                } else {
                    
                    //Solid end
                    translate([0, BicepCircumferenceWPadding/2  -SlotSpacing - CuffScale * 8.5 - CuffScale * 4  , 0 ])cube([ CuffLength, SlotSpacing , ShellThickness]);
                }
            }
            
            if(oneOrTwo == 1){
                
                //Cut angle off glueable triangle end
                translate([CuffLength-  7*CuffScale, BicepCircumferenceWPadding/2 -CuffYoffset - 8.5*CuffScale- CuffScale * 0.25 , ShellThickness+ 7*CuffScale ])rotate(a=[0,45,0])cube([ CuffScale*10, CuffScale*10 , CuffScale*10]);
            }
            

            
        }

        // import cuff bolt holder
        if(oneOrTwo == 1) 
            MakeCuff1Imports();
        
        if(oneOrTwo == 2) 
            MakeCuff2Imports();
        
        // cuff stiffener
        hull() {

            rotate(a=[90,-90,-90]) translate([8*CuffScale,4*CuffScale, -CuffScale  * 49 -1])cylinder(d=7*CuffScale, h=1);
            rotate(a=[90,-90,-90]) translate([8*CuffScale,-4*CuffScale, -CuffScale  * 49 -1])cylinder(d=7*CuffScale, h=1);
            
            translate([CuffScale  * 49,-(11*CuffScale)/2,0])cube([CuffLength ,  11*CuffScale, ShellThickness,]);
            translate([ CuffScale  * 49 +CuffLength - 10*CuffScale, 4*CuffScale, 8*CuffScale,])sphere(d=7*CuffScale);
            translate([CuffScale  * 49 +CuffLength - 10*CuffScale, -4*CuffScale, 8*CuffScale, ])sphere(d=7*CuffScale);
            
        }
        
        
        hull() {
            rotate(a=[90,-90,-90]) translate([8*CuffScale,4*CuffScale, -CuffScale  * 49 -1])cylinder(d=7*CuffScale, h=1);
        rotate(a=[90,-90,-90]) translate([8*CuffScale,-4*CuffScale, -CuffScale  * 49 -1])cylinder(d=7*CuffScale, h=1);
        rotate(a=[90,-90,-90]) translate([2.5*CuffScale,3*CuffScale, -CuffScale  * 49-1])cylinder(d=5*CuffScale, h=1);
            rotate(a=[90,-90,-90]) translate([2.5*CuffScale,-3*CuffScale, -CuffScale  * 49-1])cylinder(d=5*CuffScale, h=1);
            
            translate([25*ElbowPartsScale - 1*ElbowPartsScale,(14*ElbowPartsScale)/2 - 1*ElbowPartsScale, offset+12*ElbowPartsScale + 1*ElbowPartsScale]) sphere(d=2*ElbowPartsScale);
           
            translate([25*ElbowPartsScale - 1*ElbowPartsScale,-(14*ElbowPartsScale)/2 + 1*ElbowPartsScale, offset+12*ElbowPartsScale + 1*ElbowPartsScale]) sphere(d=2*ElbowPartsScale);
        
         translate([25*ElbowPartsScale - 1.5*ElbowPartsScale,(14*ElbowPartsScale)/2 - 2*ElbowPartsScale, offset+26.75*ElbowPartsScale - 2*ElbowPartsScale]) sphere(d=4*ElbowPartsScale);
           
            translate([25*ElbowPartsScale - 1.5*ElbowPartsScale,-(14*ElbowPartsScale)/2 + 2*ElbowPartsScale, offset+26.75*ElbowPartsScale - 2*ElbowPartsScale]) sphere(d=4*ElbowPartsScale);
            
            }
        }

        //slots for strap
        translate([CuffScale  * 49 +CuffLength/2 - (StrapWidth + 1) /2,+ BicepCircumferenceWPadding/2 -7*CuffScale  , ShellThickness-8 ])cube([ StrapWidth + 1, 14*CuffScale, 30*ShellThickness]);
        
        //slots for strap
        translate([CuffScale  * 49 +CuffLength/2 - (StrapWidth + 1) /2, -7*CuffScale  , -ShellThickness ])cube([ StrapWidth + 1, 14*CuffScale, 30*ShellThickness]);
        
        //slots for strap
        translate([CuffScale  * 49 +CuffLength/2 - (StrapWidth + 1) /2,+ BicepCircumferenceWPadding/2 -7*CuffScale  , ShellThickness-8 ])cube([ StrapWidth + 1, 14*CuffScale, -CuffYoffset]);
        
        if(oneOrTwo == 1 || oneOrTwo == 2) {
            
            if(LeatherOrPlastic != "Leather") {
                // Cut opening for the other edge to glue in
              translate([CuffScale  * 49 -0.5,  - CuffScale * 0.25 + CuffScale  * -8.5 , -1.75 ])cube([ CuffLength +2, 8.25*CuffScale +.2, ShellThickness+2]);
                
              translate([CuffScale  * 49 + CuffLength +0.5,  +8.25*CuffScale + CuffScale  * -8.5  - 1.25*CuffScale, ShellThickness ])
                    rotate(a=[90,-90,-90]) linear_extrude(CuffLength + 2)
                    polygon(points=[[-0.1,-1*CuffScale-.2],[3*CuffScale+.2,0],[-0.1,1*CuffScale+.2]], paths=[[0,1,2]]);
            } else {
                // Cut bottom float for the leather to fit in.
              //translate([CuffScale  * 49 -0.5,  - CuffScale * 0.25 + CuffScale  * -8.5 , -1.75 ])cube([ CuffLength +2, 17*CuffScale +.2, ShellThickness+2]);
                
                //Cut the two holes for the leather rivets to go through
                translate([CuffScale  * 49 +CuffLength/5 , 0  , -ShellThickness ])
                cylinder(d=RivetShaftDiameter + 0.5, h = 200*CuffScale, center=true, $fn=30);
                
                translate([CuffScale  * 49 + 4*CuffLength/5, 0  , -ShellThickness ])
                cylinder(d=RivetShaftDiameter + 0.5, h = 200*CuffScale, center=true, $fn=30);
                
            }
        }
        
        if(LeatherOrPlastic == "Leather") {
            //cut ShellThickness off the bottom of entire part. For this leather version the leather itself willadd that back on.
            translate([0,-BicepCircumferenceWPadding/2 , -1])cube([ CuffLength *2, BicepCircumferenceWPadding*2, ShellThickness + 1]);
        }

    }

    // fill in over slots for straps with a new rounded cover
    hull() {
        rotate(a=[90,-90,-90]) translate([8*CuffScale,4*CuffScale, -CuffScale  * 49 -CuffLength/2 - (StrapWidth + 3) /2])cylinder(d=7*CuffScale, h=StrapWidth + 3);
        rotate(a=[90,-90,-90]) translate([8*CuffScale,-4*CuffScale, -CuffScale  * 49 -CuffLength/2 - (StrapWidth + 3) /2])cylinder(d=7*CuffScale, h=StrapWidth + 3);
    }
    
            
}


//***************************
// MakeCuffFlap() 
//***************************
module MakeCuffFlap( CuffWidth, CuffYoffset) {
    
    difference() {
        union() {//91.5
        translate([CuffScale  * 49, CuffYoffset , 0 ])
             difference() {
                 union() {
                // the plate with slots
                difference() {
                    translate([0, 0 , 0 ]) cube([ CuffLength, CuffWidth, ShellThickness]);
                    

                    MakeCuffslots1();
                }

                //solid on end
                translate([0, 0 , 0 ])cube([ CuffLength, 3*CuffScale, ShellThickness]);

                //lip on leading edge to glue on other stiffener
                translate([0, BicepCircumferenceWPadding/2 -CuffYoffset - 5.5*CuffScale, 0 ])cube([ CuffLength, 5.25*CuffScale , ShellThickness]);
                translate([CuffLength, BicepCircumferenceWPadding/2 -CuffYoffset  - 1.25*CuffScale, ShellThickness ])
                rotate(a=[90,-90,-90]) linear_extrude(CuffLength)
                    polygon(points=[[0,-1*CuffScale],[3*CuffScale,0],[0,1*CuffScale]], paths=[[0,1,2]]);
                    
                     
 
            }
            

            //Cut angle off glueable triangle end
            translate([CuffLength-  7*CuffScale, BicepCircumferenceWPadding/2 -CuffYoffset - 8.5*CuffScale- CuffScale * 0.25 , ShellThickness+ 7*CuffScale ])rotate(a=[0,45,0])cube([ CuffScale*10, CuffScale*10 , CuffScale*10]);
            
        }
    }
       
        //slots for strap
    translate([CuffScale  * 49 +CuffLength/2 - (StrapWidth + 1) /2,+ BicepCircumferenceWPadding/2 -7*CuffScale  , ShellThickness-8 ])cube([ StrapWidth + 1, 14*CuffScale, 30*ShellThickness]);
        
    }
   

}

//***************************
// MakeCuffLeatherTemplate() 
//***************************
module MakeCuffLeatherTemplate() {
    
    if(LeatherOrPlastic == "Leather") {
        
        // the outline of the whole cuff
        polygonpoints = [[0,-2*BicepCircumferenceWPadding/6],[CuffLength,-2*BicepCircumferenceWPadding/6],[CuffLength,5*BicepCircumferenceWPadding/6],[0,5*BicepCircumferenceWPadding/6]];
      
      difference() {  
        polygon(polygonpoints, paths=[[0,1,2,3]]);
        
        //circles for the four holes for the leather rivets to go through
        translate([CuffLength/5 , 0  ])
        circle(d=RivetShaftDiameter + 0.5, $fn=30);
        
        translate([4*CuffLength/5, 0])
        circle(d=RivetShaftDiameter + 0.5, $fn=30);
        
        translate([CuffLength/5 , BicepCircumferenceWPadding/2])
        circle(d=RivetShaftDiameter + 0.5, $fn=30);
        
        translate([4*CuffLength/5, BicepCircumferenceWPadding/2])
        circle(d=RivetShaftDiameter + 0.5, $fn=30);
          
          echo(" far hole", 4*CuffLength/5);
      }
        
    }
}

//***************************
// MakeCuff1() 
//***************************
module MakeCuff1() {

        
    //NOTE: the - 3.5 *CuffScale is becasue the Cuff 1 is 7mm thicker than the Cuff2
    
    offset = max(-10 *ForeArmCircumferenceScale,   - (  BicepDiameterWPadding- ForearmDiameterWPadding)/2 );
    
    
    MakeCuffBase(1, BicepCircumferenceWPadding/2  - CuffScale * 0.25, 0, offset);
}

//***************************
// MakeCuff2() 
//***************************
module MakeCuff2() {
    
    //NOTE: the + 3.5 *CuffScale is becasue the Cuff 1 is 7mm thicker than the Cuff2
    
    offset = max(-10 *ForeArmCircumferenceScale,  - (  BicepDiameterWPadding- ForearmDiameterWPadding)/2 - 7 *ForeArmCircumferenceScale);
  
    MakeCuffBase(2, BicepCircumferenceWPadding/2 - CuffScale * 8.5 - CuffScale * 4, CuffScale  * -5.5, offset );

}

//***************************
// MakeCuff3() 
//***************************
module MakeCuff3() {
    
    if(LeatherOrPlastic != "Leather")
        MakeCuffFlap( BicepCircumferenceWPadding/4 - CuffScale * 5.75, BicepCircumferenceWPadding/4 + CuffScale  * 5.5 );

}



//***************************
// MakeCuff1Imports() 
//***************************
module MakeCuff1Imports() {
    
    offset1 = max(-10 *ForeArmCircumferenceScale,   - (  BicepDiameterWPadding- ForearmDiameterWPadding)/2  );
    
    difference() {
        
        translate([0, 0, offset1 ]) Cuff1();
        
        //Cut a holes for elbow bolts
        cylinder(d=ElbowBoltDiameter + 0.5, h = ElbowPartsScale  * 150, center=true, $fn=30);
    } 
}

//***************************
// MakeCuff2Imports() 
//***************************
module MakeCuff2Imports() {
    
    offset2 = max(-3 *ForeArmCircumferenceScale,  - (  BicepDiameterWPadding- ForearmDiameterWPadding)/2);
    
    difference() {
        Cuff2(offset2);
        
        //Cut a holes for elbow bolts
        cylinder(d=ElbowBoltDiameter + 0.5, h = ElbowPartsScale  * 150, center=true, $fn=30);

    }
   
}



//--pitch-----------------------------------------------------------------------
// function for ISO coarse thread pitch (these are specified by ISO)
function get_coarse_pitch(dia) = lookup(dia, [
[1,0.25],[1.2,0.25],[1.4,0.3],[1.6,0.35],[1.8,0.35],[2,0.4],[2.5,0.45],[3,0.5],[3.5,0.6],[4,0.7],[5,0.8],[6,1],[7,1],[8,1.25],[10,1.5],[12,1.75],[14,2],[16,2],[18,2.5],[20,2.5],[22,2.5],[24,3],[27,3],[30,3.5],[33,3.5],[36,4],[39,4],[42,4.5],[45,4.5],[48,5],[52,5],[56,5.5],[60,5.5],[64,6],[78,5]]);


module make_bolt(dia,hi, headhi, headDiameter)
// make an ISO bolt 
//  dia=diameter, 6=M6 etc.
//  hi=length of threaded part of bolt
{
//rotate for better print orientation
rotate([-90,0,0]) 
    difference() {
        union()
        {   
            difference() {
            cylinder(d = headDiameter, h = headhi, $fn=30);
            
                // Make head rounded
                difference() {
                    
                    pad = 0.1; // Padding to maintain manifold
                    r = 1; // radius of fillet
                    cr = headDiameter/2;
                        
                    rotate_extrude(convexity=10, $fn = 30) translate([cr-r+pad, -pad, 0]) square(r+pad,r+pad);
                    rotate_extrude(convexity=10, $fn = 30) translate([cr-r, r, 0]) circle(r=r,$fn=30);
                    }
       
            }
            translate([0,0,headhi-0.1]) thread_out_centre(dia,hi+0.1);
            translate([0,0,headhi-0.1]) thread_out(dia,hi+0.1);
        }
        
        // make the hex hole
        translate([0,0,-1]) rotate([0,0,45]) cylinder(d = dia - 2 ,h = dia, $fn=4);
     
        //flatten one side to make it printable
        translate([-hi, dia/2 - dia/12, -1]) cube(hi *2);   
        
        //flatten other side to make threads not wavy on top
        translate([-hi,- (hi *2) - (dia/2 - dia/14), headhi + 0.1]) cube(hi *2);   
    }
    
         
}

module thread_out(dia,hi,thr=$fn)
// make an outside ISO thread (as used on a bolt)
//  dia=diameter, 6=M6 etc
//  hi=height, 10=make a 10mm long thread
//  thr=thread quality, 10=make a thread with 10 segments per turn
{
	p = get_coarse_pitch(dia);
    //JB: I add this mirror because the model will be mirrored at the end if it is a left
    if (LeftRight == "Left") {
        mirror([0,1,0])thread_out_pitch(dia,hi,p,thr);
    } else
        thread_out_pitch(dia,hi,p,thr);
}

module thread_in(dia,hi,thr=$fn)
// make an inside thread (as used on a nut)
//  dia = diameter, 6=M6 etc
//  hi = height, 10=make a 10mm long thread
//  thr = thread quality, 10=make a thread with 10 segments per turn
{
	p = get_coarse_pitch(dia);
    //JB: I add this mirror because the model will be mirrored at the end if it is a left
    if (LeftRight == "Left") {
            mirror([0,1,0]) thread_in_pitch(dia,hi,p,thr); 
    } else
            thread_in_pitch(dia,hi,p,thr);  
}

module thread_out_pitch(dia,hi,p,thr=$fn)
// make an outside thread (as used on a bolt) with supplied pitch
//  dia=diameter, 6=M6 etc
//  hi=height, 10=make a 10mm long thread
//  p=pitch
//  thr=thread quality, 10=make a thread with 10 segments per turn
{
	h=(cos(30)*p)/8;
	Rmin=(dia/2)-(5*h);	// as wiki Dmin
	s=360/thr;				// length of segment in degrees
	t1=(hi-p)/p;			// number of full turns
	r=t1%1.0;				// length remaining (not full turn)
	t=t1-r;					// integer number of full turns
	n=r/(p/thr);			// number of segments for remainder
	// do full turns
	for(tn=[0:t-1])
		translate([0,0,tn*p])	th_out_turn(dia,p,thr);
	// do remainder
	for(sg=[0:n])
		th_out_pt(Rmin-0.1,p,s,sg+(t*thr),thr,h,p/thr);
}

module thread_in_pitch(dia,hi,p,thr=$fn)
// make an inside thread (as used on a nut)
//  dia = diameter, 6=M6 etc
//  hi = height, 10=make a 10mm long thread
//  p=pitch
//  thr = thread quality, 10=make a thread with 10 segments per turn
{
	h=(cos(30)*p)/8;
	Rmin=(dia/2)-(5*h);	// as wiki Dmin
	s=360/thr;				// length of segment in degrees
	t1=(hi-p)/p;			// number of full turns
	r=t1%1.0;				// length remaining (not full turn)
	t=t1-r;					// integer number of turns
	n=r/(p/thr);			// number of segments for remainder
	for(tn=[0:t-1])
		translate([0,0,tn*p])	th_in_turn(dia,p,thr);
	for(sg=[0:n])
		th_in_pt(Rmin,p,s,sg+(t*thr),thr,h,p/thr);
}

module thread_out_centre(dia,hi)
{
	p = get_coarse_pitch(dia);
	thread_out_centre_pitch(dia,hi,p);
}

module thread_out_centre_pitch(dia,hi,p)
{
	h = (cos(30)*p)/8;
	Rmin = (dia/2) - (5*h);	// as wiki Dmin

	cylinder(r = Rmin, h = hi);
}

module thread_in_ring(dia,hi,thk)
{
	difference()
	{
		cylinder(d = dia,h = hi);
		translate([0,0,-1]) cylinder(d = dia - thk*2, h = hi + 1);
	}
}

//--low level bolt modules-----------------------------------------------------------

module th_out_turn(dia,p,thr=$fn)
// make a single turn of an outside thread
//  dia=diameter, 6=M6 etc
//  p=pitch
//  thr=thread quality, 10=make a thread with 10 segments per turn
{
	h = (cos(30)*p)/8;
	Rmin = (dia/2) - (5*h);	// as wiki Dmin
	s = 360/thr;
	for(sg=[0:thr-1])
		th_out_pt(Rmin-0.1,p,s,sg,thr,h,p/thr);
}

module th_out_pt(rt,p,s,sg,thr,h,sh)
// make a part of an outside thread (single segment)
//  rt = radius of thread (nearest centre)
//  p = pitch
//  s = segment length (degrees)
//  sg = segment number
//  thr = segments in circumference
//  h = ISO h of thread / 8
//  sh = segment height (z)
{
	as = (sg % thr) * s ;			// angle to start of seg
	ae = as + s  - (s/100) + 0.2;		// angle to end of seg (with overlap) JB: The 0.2 makes the segments link
	z = sh*sg;
	//pp = p/2;
	//   1,4
	//   |\
	//   | \  2,5
 	//   | / 
	//   |/
	//   0,3
	//  view from front (x & z) extruded in y by sg
	//  
	//echo(str("as=",as,", ae=",ae," z=",z));
	polyhedron(
		points = [
			[cos(as)*rt,sin(as)*rt,z],								// 0
			[cos(as)*rt,sin(as)*rt,z+(3/4*p)],						// 1
			[cos(as)*(rt+(5*h)),sin(as)*(rt+(5*h)),z+(3/8*p)],		// 2
			[cos(ae)*rt,sin(ae)*rt,z+sh],							// 3
			[cos(ae)*rt,sin(ae)*rt,z+(3/4*p)+sh],					// 4
			[cos(ae)*(rt+(5*h)),sin(ae)*(rt+(5*h)),z+sh+(3/8*p)]],	// 5
		faces = [
			[0,1,2],			// near face
			[3,5,4],			// far face
			[0,3,4],[0,4,1],	// left face
			[0,5,3],[0,2,5],	// bottom face
			[1,4,5],[1,5,2]]);	// top face
}

module th_in_turn(dia,p,thr=$fn)
// make an single turn of an inside thread
//  dia = diameter, 6=M6 etc
//  p=pitch
//  thr = thread quality, 10=make a thread with 10 segments per turn
{
	h = (cos(30)*p)/8;
	Rmin = (dia/2) - (5*h);	// as wiki Dmin
	s = 360/thr;
	for(sg=[0:thr-1])
		th_in_pt(Rmin,p,s,sg,thr,h,p/thr);
}

module th_in_pt(rt,p,s,sg,thr,h,sh)
// make a part of an inside thread (single segment)
//  rt = radius of thread (nearest centre)
//  p = pitch
//  s = segment length (degrees)
//  sg = segment number
//  thr = segments in circumference
//  h = ISO h of thread / 8
//  sh = segment height (z)
{
	as = ((sg % thr) * s - 180);	// angle to start of seg
	ae = as + s -(s/100) + 0.2;		// angle to end of seg (with overlap) JB: The 0.2 makes the segments link
	z = sh*sg;
	pp = p/2;
	//         2,5
	//          /|
	//     1,4 / | 
 	//         \ |
	//          \|
	//         0,3
	//  view from front (x & z) extruded in y by sg
	//  
	polyhedron(
		points = [
			[cos(as)*(rt+(5*h)),sin(as)*(rt+(5*h)),z],				//0
			[cos(as)*rt,sin(as)*rt,z+(3/8*p)],						//1
			[cos(as)*(rt+(5*h)),sin(as)*(rt+(5*h)),z+(3/4*p)],		//2
			[cos(ae)*(rt+(5*h)),sin(ae)*(rt+(5*h)),z+sh],			//3
			[cos(ae)*rt,sin(ae)*rt,z+(3/8*p)+sh],					//4
			[cos(ae)*(rt+(5*h)),sin(ae)*(rt+(5*h)),z+(3/4*p)+sh]],	//5
		faces = [
			[0,1,2],			// near face
			[3,5,4],			// far face
			[0,3,4],[0,4,1],	// left face
			[0,5,3],[0,2,5],	// bottom face
			[1,4,5],[1,5,2]]);	// top face
}



module Palm() {scale([HandScale,HandScale,HandScale]) import("o_Palm.stl", convexity=3);}

module PencilHolderTool() {scale([HandScale,HandScale,HandScale]) import("o_PencilHolderTool.stl", convexity=3);}

module PalmTop() {scale([HandScale,HandScale,HandScale]) import("o_PalmTop.stl", convexity=3);}

module IndexFingerEnd() {scale([HandScale,HandScale,HandScale]) import("o_IndexFingerEnd.stl", convexity=3);}

module IndexFingerPhalanx() {scale([HandScale,HandScale,HandScale]) import("o_IndexFingerPhalanx.stl", convexity=3);}

module MiddleFingerEnd() {scale([HandScale,HandScale,HandScale]) import("o_MiddleFingerEnd.stl", convexity=3);}

module MiddleFingerPhalanx() {scale([HandScale,HandScale,HandScale]) import("o_MiddleFingerPhalanx.stl", convexity=3);}

module PinkyFingerEnd() {scale([HandScale,HandScale,HandScale]) import("o_PinkyFingerEnd.stl", convexity=3);}

module PinkyFingerPhalanx() {scale([HandScale,HandScale,HandScale]) import("o_PinkyFingerPhalanx.stl", convexity=3);}

module RingFingerEnd() {scale([HandScale,HandScale,HandScale]) import("o_RingFingerEnd.stl", convexity=3);}

module RingFingerPhalanx() {scale([HandScale,HandScale,HandScale]) import("o_RingFingerPhalanx.stl", convexity=3);}

module ThumbEnd() {scale([HandScale,HandScale,HandScale]) import("o_ThumbEnd.stl", convexity=3);}

module ThumbPhalanx() {scale([HandScale,HandScale,HandScale]) import("o_ThumbPhalanx.stl", convexity=3);}

module WhippleTreePrimary() {scale([HandScale,HandScale,HandScale]) import("o_WhippleTreePrimary.stl", convexity=3);}

module WhippleTreeSecondary() {scale([HandScale,HandScale,HandScale]) import("o_WhippleTreeSecondary.stl", convexity=3);}

module Tensioner() { scale([ElbowPartsScale,ElbowPartsScale,ElbowPartsScale]) import("o_Tensioner.stl", convexity=3); }

//Mirror because I designed opening on bottom of arm not top, then changed my mind 
module UpperArm1() { mirror([0,1,0]) scale([ElbowPartsScale,ElbowPartsScale,ElbowPartsScale]) import("o_Arm1.stl", convexity=3); }

module UpperArm2() { mirror([0,1,0]) translate([0, -ElbowPartsScale*135  ,0]) scale([ElbowPartsScale,ElbowPartsScale,ElbowPartsScale]) import("o_Arm2.stl", convexity=3); }

module Ratchet() {mirror([0,1,0]) scale([ElbowPartsScale,ElbowPartsScale,ElbowPartsScale]) import("o_Ratchet.stl", convexity=3); }

module LatchCover() {mirror([0,1,0]) scale([ElbowPartsScale,ElbowPartsScale,ElbowPartsScale]) import("o_LatchCover.stl", convexity=3); }

module Latch() {mirror([0,1,0]) scale([ElbowPartsScale,ElbowPartsScale,ElbowPartsScale]) import("o_Latch.stl", convexity=3); }

module Cuff1() {mirror([0,1,0]) scale([ElbowPartsScale,ElbowPartsScale,ElbowPartsScale]) import("o_Cuff1.stl", convexity=3); }

module Cuff2(offset) {mirror([0,1,0]) translate([0, -ElbowPartsScale  * 135, offset ]) scale([ElbowPartsScale,ElbowPartsScale,ElbowPartsScale]) import("o_Cuff2.stl", convexity=3); }



