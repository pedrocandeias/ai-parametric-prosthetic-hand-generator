// RBE580 Low-Cost Cable-Driven Prosthetic Hand
// WPI Biomedical Robotics Fall 2016
// Original authors: Gondokaryono, Gonzalez, Lazaro, Miscione, Sujumnong, Wee
// Self-contained parametric assembly — all modules inlined, no external dependencies.

// ── Primary inputs ────────────────────────────────────────────────────────────
palm_width    = 85;   // knuckle-to-knuckle palm breadth (mm); range ~44–95
middle_length = 80;   // middle finger total length (mm); range ~50–160
thumb_length  = 65;   // thumb total length (mm); range ~40–120

// ── Part visibility ───────────────────────────────────────────────────────────
show_palm_back      = true;
show_palm_cover     = true;
show_palm_pulley    = true;
show_proximal       = true;
show_middle         = true;
show_distal         = true;
show_thumb_proximal = true;
show_thumb_tip      = true;

// ── View mode ────────────────────────────────────────────────────────────────
assembled = true;   // true = assembled hand view, false = flat print layout

// ── Derived geometry ──────────────────────────────────────────────────────────
fw       = palm_width * 15.8 / 90;   // finger cross-section width
tw       = palm_width * 16.3 / 90;   // thumb  cross-section width
gap      = palm_width * 7.5  / 90;   // inter-knuckle gap
palm_z   = palm_width * 6    / 90;   // palm plate thickness
// Joint pin center z in assembled hand; phalanx base sits so its joint aligns:
z_joint  = palm_z + fw * 2 / 5;
z_ph     = z_joint - fw * 3 / 5;    // z offset for phalanx base

// ═════════════════════════════════════════════════════════════════════════════
// MODULE: Palm Back  (from Palm_Back.scad)
// ═════════════════════════════════════════════════════════════════════════════
module palm_1(thumb_length, middle_length, palm_width)
{
    finger_width = palm_width*15.8/90;
    thumb_width = palm_width*16.3/90;
    difference()
    {
        union()
        {
            difference()
            {
                union()
               {
                   cube([palm_width,palm_width+finger_width*4/5,palm_width*6/90],false);
                   for (i=[0:1:3]){
                       translate([(palm_width*7.5/90+finger_width)*i,palm_width,palm_width*6/90])
                       cube([2,finger_width*4/5,finger_width*2/5],false);
                       translate([(finger_width+palm_width*7.5/90)*i,palm_width+finger_width*2/5,palm_width*6/90+finger_width*2/5])
                       rotate([0,90,0])
                       cylinder(2,r=finger_width*2/5,false,$fn=50);
                       translate([2+finger_width+(palm_width*7.5/90+finger_width)*i,palm_width,palm_width*6/85])
                       cube([2,finger_width*4/5,finger_width*2/5],false);
                       translate([(2+finger_width)+(palm_width*7.5/90+finger_width)*i,palm_width+finger_width*2/5,palm_width*6/90+finger_width*2/5])
                       rotate([0,90,0])
                       cylinder(2,r=finger_width*2/5,false,$fn=50);
                   }
                }
                translate([-0.1,palm_width+finger_width*2/5,palm_width*12/85])
                rotate([0,90,0])
                cylinder(palm_width*1.1,r=3.175/2,false,$fn=50);
                translate([-0.1,palm_width*87.5/85,palm_width*10/85])
                rotate([0,90,0])
                cylinder(palm_width*1.1,r=1.1905,false,$fn=50);
                translate([-0.1,palm_width*87.5/85,palm_width*15/85])
                rotate([0,90,0])
                cylinder(palm_width*1.1,r=1.1905,false,$fn=50);
                for(i=[0:1:1]){
                    translate([palm_width*(5/85+50/85*i),palm_width*5/85,0])
                    cylinder(10,r=3.46/2,false,$fn=50);
                    translate([palm_width*(5/85+50/85*i),palm_width*20/85,0])
                    cylinder(10,r=3.46/2,false,$fn=50);
                }
                for(i=[0:1:1]){
                    translate([palm_width*(5/85+75/85*i),palm_width*55/85,0])
                    cylinder(10,r=3.46/2,false,$fn=50);
                    translate([palm_width*(5/85+75/85*i),palm_width*75/85,0])
                    cylinder(10,r=3.46/2,false,$fn=50);
                }
                for(i = [0:1:1]){
                translate([palm_width*(14.5/85+22/85*i),0,palm_width*2/85])
                cube([palm_width*14/85,palm_width*75/85,palm_width*1.7/85],false);
                translate([palm_width*(19.86/85+22/85*i),0,palm_width*2/85])
                cube([palm_width*3.28/85,palm_width*75/85,palm_width*8/85],false);
                }
                translate([palm_width*60/85,0,0])
                rotate([0,0,-45])
                cube([palm_width*25/85,palm_width*35/85,palm_width*6/85],false);
                translate([palm_width,palm_width*25/85,0])
                rotate([0,0,45])
                cube([(palm_width*25/85)/sin(45),palm_width*16/85,palm_width*6/85],false);
            }
            translate([palm_width*63.056/85,palm_width*28.056/85,0])
            cube([palm_width*17.678/85,palm_width*17.678/85,palm_width*6/90],false);
            translate([palm_width*67.723/85,palm_width*30.461/85,0])
            rotate([0,0,-45])
            cube([thumb_width+5,palm_width*15/85,palm_width*16/85]);
            translate([palm_width*(67.723/85+7.5/85*sin(45)),palm_width*(30.461/85+7.5/85*cos(45)),palm_width*16/85])
            rotate([0,90,-45])
            cylinder(thumb_width+5,r=palm_width*15/85/2,false,$fn=50);
            translate([palm_width*67.723/85,palm_width*30.461/85,0])
            rotate([0,0,-135])
            cube([palm_width*12/90,palm_width*2/90,palm_width*16/85]);
        }
        translate([palm_width*58.5/85,0,palm_width*2/85])
        cube([palm_width*14/85,palm_width*75/85,palm_width*1.7/85],false);
        translate([palm_width*63.86/85,0,palm_width*2.7/85])
        cube([palm_width*3.28/85,palm_width*75/85,palm_width*8/90],false);
        translate([palm_width*67.723/85+1.5*cos(45),palm_width*30.461/85-3*sin(45),palm_width*6/90])
        rotate([0,0,-45])
        cube([thumb_width,palm_width*15/85*1.1,palm_width*20/85]);
        translate([palm_width*(67.723/85+7.5/85*sin(45)),palm_width*(30.461/85+7.5/85*cos(45)),palm_width*16/85])
        rotate([0,90,-45])
        cylinder((thumb_width+4)*1.1,r=2.38,false,$fn=50);
        translate([palm_width*67.723/85,palm_width*30.461/85,palm_width*16/85])
        rotate([0,25,-135])
        cube([palm_width*15/90,palm_width*2/90,palm_width*16/85]);
    }
}

// ═════════════════════════════════════════════════════════════════════════════
// MODULE: Palm Cover  (from Palm_Cover.scad, parametric via scale)
// ═════════════════════════════════════════════════════════════════════════════
module palm_cover_part(palm_width)
{
    scale([palm_width/85, palm_width/85, 1]) {
        length=85; wrist=60; width=85; res=30;
        difference(){
            union(){
                cube([10,25,2]);
                translate([0,length-35,0]) cube([10,35,2]);
                translate([wrist+25-10,length-35,0]) cube([10,35,2]);
                translate([wrist-10,0,0]) cube([10,25,2]);
                translate([0,0,2]) cube([wrist+25,length,3]);
            }
            union(){
                translate([85,50,0]) rotate([0,0,225]) cube([35.36,50,6]);
                translate([wrist,0,0]) cube([length-wrist,25,6]);
                translate([5,5,0])          cylinder(10,r=3.26/2,true,$fn=res);
                translate([5,20,0])         cylinder(10,r=3.26/2,true,$fn=res);
                translate([wrist-5,5,0])    cylinder(10,r=3.26/2,true,$fn=res);
                translate([wrist-5,20,0])   cylinder(10,r=3.26/2,true,$fn=res);
                translate([5,length-10,0])      cylinder(10,r=3.26/2,true,$fn=res);
                translate([5,length-30,0])      cylinder(10,r=3.26/2,true,$fn=res);
                translate([wrist+25-5,length-10,0]) cylinder(10,r=3.26/2,true,$fn=res);
                translate([wrist+25-5,length-30,0]) cylinder(10,r=3.26/2,true,$fn=res);
                translate([22.69,37,2]) cylinder(1.24,r=2.38/2,true,$fn=res);
                translate([44.69,36,2]) cylinder(1.24,r=2.38/2,true,$fn=res);
                translate([64.31,37,2]) cylinder(1.24,r=2.38/2,true,$fn=res);
                translate([53.5,39,2])  cylinder(1.24,r=2.38/2,true,$fn=res);
                translate([33.5,39,2])  cylinder(1.24,r=2.38/2,true,$fn=res);
                translate([11.69,73,2]) cylinder(1.24,r=2.38/2,true,$fn=res);
                translate([31.31,73,2]) cylinder(1.24,r=2.38/2,true,$fn=res);
                translate([55.69,73,2]) cylinder(1.24,r=2.38/2,true,$fn=res);
                translate([75.31,73,2]) cylinder(1.24,r=2.38/2,true,$fn=res);
                translate([0,length-8,5]) rotate([360-15,0,0]) cube([width,50,5]);
            }
        }
    }
}

// ═════════════════════════════════════════════════════════════════════════════
// MODULE: Palm Pulley  (from Palm_Pulley.scad, parametric via scale)
// ═════════════════════════════════════════════════════════════════════════════
module palm_pulley_part(palm_width)
{
    scale([palm_width/85, palm_width/85, 1]) {
        length=85; wrist=60; width=85; res=15;
        difference(){
            union(){
                cube([10,25,1]);
                translate([0,length-35,0]) cube([10,35,1]);
                translate([wrist+25-10,length-35,0]) cube([10,35,1]);
                translate([wrist-10,0,0]) cube([10,25,1]);
                translate([0,0,1]) cube([wrist+25,length,2]);
            }
            union(){
                translate([85,50,0]) rotate([0,0,225]) cube([35.36,50,6]);
                translate([wrist,0,0]) cube([length-wrist,25,6]);
                translate([5,5,0])          cylinder(10,r=3.46/2,true,$fn=res);
                translate([5,20,0])         cylinder(10,r=3.46/2,true,$fn=res);
                translate([wrist-5,5,0])    cylinder(10,r=3.46/2,true,$fn=res);
                translate([wrist-5,20,0])   cylinder(10,r=3.46/2,true,$fn=res);
                translate([5,length-10,0])      cylinder(10,r=3.46/2,true,$fn=res);
                translate([5,length-30,0])      cylinder(10,r=3.46/2,true,$fn=res);
                translate([wrist+25-5,length-10,0]) cylinder(10,r=3.46/2,true,$fn=res);
                translate([wrist+25-5,length-30,0]) cylinder(10,r=3.46/2,true,$fn=res);
                translate([22.69,37,1]) cylinder(4,r=2.38/2,true,$fn=res);
                translate([44.69,36,1]) cylinder(4,r=2.38/2,true,$fn=res);
                translate([64.31,37,1]) cylinder(4,r=2.38/2,true,$fn=res);
                translate([53.5,39,1])  cylinder(4,r=2.38/2,true,$fn=res);
                translate([33.5,39,1])  cylinder(4,r=2.38/2,true,$fn=res);
                translate([11.69,73,1]) cylinder(4,r=2.38/2,true,$fn=res);
                translate([31.31,73,1]) cylinder(4,r=2.38/2,true,$fn=res);
                translate([55.69,73,1]) cylinder(4,r=2.38/2,true,$fn=res);
                translate([75.31,73,1]) cylinder(4,r=2.38/2,true,$fn=res);
                translate([0,length-8,3]) rotate([360-10,0,0]) cube([width,50,5]);
                union(){
                    translate([21.5,65,1]) cylinder(2,r=1.64,true,$fn=res);
                    translate([21.5,45,1]) cylinder(2,r=1.64,true,$fn=res);
                    translate([19.86,45,1]) cube([1.64*2,20,2]);
                }
                translate([44,0,0]) union(){
                    translate([21.5,65,1]) cylinder(2,r=1.64,true,$fn=res);
                    translate([21.5,45,1]) cylinder(2,r=1.64,true,$fn=res);
                    translate([19.86,45,1]) cube([1.64*2,20,2]);
                }
                translate([22,-35,0]) union(){
                    translate([21.5,65,1]) cylinder(2,r=1.64,true,$fn=res);
                    translate([21.5,45,1]) cylinder(2,r=1.64,true,$fn=res);
                    translate([19.86,45,1]) cube([1.64*2,20,2]);
                }
            }
        }
    }
}

// ═════════════════════════════════════════════════════════════════════════════
// MODULE: Proximal Phalanx — fingers  (from proximal_phalanx.scad)
// ═════════════════════════════════════════════════════════════════════════════
module proximal_phalanx(thumb_length, middle_length, palm_width)
{
    width = palm_width*15.8/90;
    difference()
    {
        union(){
            cube([middle_length/2,width,width],false);
            translate([0,0,width*3/5])
            rotate([-90,0,0])
            cylinder(width,r=width*2/5,false,$fn=100);
            translate([middle_length/2,0,width*3/5])
            rotate([-90,0,0])
            cylinder(width,r=width*2/5*0.9,false,$fn=100);
        }
        translate([0,width*1.1,width*3/5])
        rotate([90,0,0])
        cylinder(width*2,r=1.985,false,$fn=100);
        translate([middle_length/2,width*1.1,width*3/5])
        rotate([90,0,0])
        cylinder(width*2,r=1.985,false,$fn=100);
        translate([0,0,width*3/5])
        rotate([-90,0,0])
        cylinder(2.0,r=width*2.1/5,false,$fn=100);
        translate([0,0,width*3/5])
        cube([width*2/5,2,width*3/5]);
        translate([0,0,width*3/5])
        cube([width*2/5,2,width]);
        translate([0,width,width*3/5])
        rotate([90,0,0])
        cylinder(2.0,r=width*2.1/5,false,$fn=100);
        translate([0,width-2,width*3/5])
        cube([width*2/5,2,width*3/5]);
        translate([0,width-2,width*3/5])
        cube([width*2/5,2,width]);
        translate([0,0,width/5])
        rotate([0,170,0])
        cube([2*cos(45)*width/5,width,2*sin(45)*width/5],false);
        translate([middle_length/2/2,width/2,width*1/1.5])
        cube([middle_length/2+width*4.5,width*2/5,width*4/15],true);
        translate([-width*2/5,width/2,width/5])
        cube([width*1.2,width*2/5,width*4/5],true);
        translate([middle_length/2,width/2,width*3/5])
        rotate([90,0,0])
        cylinder(width/2-2,r=width*2/5,true,$fn=100);
        translate([middle_length/2,width/2,width*3/5])
        rotate([-90,0,0])
        cylinder(width/2-2,r=width*2/5,true,$fn=100);
        translate([middle_length/2-width*2/5,2,0])
        cube([2*width*2/5,width-4,width*3/5],false);
        translate([middle_length/2-width/5,2,0])
        cube([2/3*width*2/5,width-4,width],false);
        translate([middle_length/2,width/2,0])
        rotate([0,45,0])
        cube([2*cos(45)*width/5,width,2*sin(45)*width/5],true);
        translate([0,width/2,width*4/15])
        rotate([0,90,0])
        cylinder(middle_length/2,r=0.75,false,$fn=100);
        for (i = [0:1:1]){
            translate([0,width*(1/3+1/3*i),width*7/15])
            rotate([0,90,0])
            cylinder(middle_length/2,d=0.53,false,$fn=50);
        }
        translate([0,width*1.5/6,width*10.87/15])
        rotate([0,90,0])
        cylinder(middle_length/2,d=0.53,false,$fn=50);
    }
}

// ═════════════════════════════════════════════════════════════════════════════
// MODULE: Middle Phalanx  (from middle_phalanx.scad)
// ═════════════════════════════════════════════════════════════════════════════
module middle_phalanx(thumb_length, middle_length, palm_width)
{
    width = palm_width*15.8/90;
    difference()
    {
        union(){
            cube([middle_length/3,width,width],false);
            translate([0,0,width*3/5])
            rotate([-90,0,0])
            cylinder(width,r=width*2/5,false,$fn=100);
            translate([middle_length/3,0,width*3/5])
            rotate([-90,0,0])
            cylinder(width,r=width*2/5*0.9,false,$fn=100);
        }
        translate([0,width*1.1,width*3/5])
        rotate([90,0,0])
        cylinder(width*2,r=1.985,false,$fn=100);
        translate([middle_length/3,width*1.1,width*3/5])
        rotate([90,0,0])
        cylinder(width*2,r=1.985,false,$fn=100);
        translate([0,0,width*3/5])
        rotate([-90,0,0])
        cylinder(2.0,r=width*2/5,false,$fn=100);
        cube([width*2/5,2,width*3/5]);
        cube([2,2,width]);
        translate([0,width,width*3/5])
        rotate([90,0,0])
        cylinder(2.0,r=width*2/5,false,$fn=100);
        translate([0,width-2,0])
        cube([width*2/5,2,width*3/5]);
        translate([0,width-2,0])
        cube([2,2,width]);
        translate([0,width/2,0])
        rotate([0,45,0])
        cube([2*cos(45)*width/5,width,2*sin(45)*width/5],true);
        translate([middle_length/3/2,width/2,width*1/1.5])
        cube([middle_length/3+width*4.5,width*2/5,width*4/15],true);
        translate([-width*2/5,width/2,width/5])
        cube([width*1.2,width*2/5,width*4/5],true);
        translate([middle_length/3,width/2,width*3/5])
        rotate([90,0,0])
        cylinder(width/2-2,r=width*2/5,true,$fn=100);
        translate([middle_length/3,width/2,width*3/5])
        rotate([-90,0,0])
        cylinder(width/2-2,r=width*2/5,true,$fn=100);
        translate([middle_length/3-width*2/5,2,0])
        cube([2*width*2/5,width-4,width*3/5],false);
        translate([middle_length/3-width/5,2,0])
        cube([2/3*width*2/5,width-4,width],false);
        translate([middle_length/3,width/2,0])
        rotate([0,45,0])
        cube([2*cos(45)*width/5,width,2*sin(45)*width/5],true);
        translate([0,width/2,width*4/15])
        rotate([0,90,0])
        cylinder(middle_length/2,r=0.75,false,$fn=100);
        for (i = [0:1:1]){
            translate([0,width*(1/3+1/3*i),width*7/15])
            rotate([0,90,0])
            cylinder(middle_length/2,d=0.53,false,$fn=50);
        }
        translate([0,width*1.5/6,width*10.87/15])
        rotate([0,90,0])
        cylinder(middle_length/2,d=0.53,false,$fn=50);
    }
}

// ═════════════════════════════════════════════════════════════════════════════
// MODULE: Distal Phalanx / Finger Tip  (from finger_tip.scad)
// ═════════════════════════════════════════════════════════════════════════════
module distal_phalanx(thumb_length, middle_length, palm_width)
{
    width = palm_width*15.8/90;
    difference()
    {
        union(){
            cube([middle_length/3,width,width],false);
            translate([0,0,width*3/5])
            rotate([-90,0,0])
            cylinder(width,r=width*2/5,false,$fn=100);
            translate([middle_length/3,0,width/2])
            rotate([-90,0,0])
            cylinder(width,r=width/2,false,$fn=100);
        }
        translate([0,width*1.1,width*3/5])
        rotate([90,0,0])
        cylinder(width*2,r=1.985,false,$fn=100);
        translate([0,0,width*3/5])
        rotate([-90,0,0])
        cylinder(2.0,r=width*2/5,false,$fn=100);
        cube([width*2/5,2,width*3/5]);
        cube([2,2,width]);
        translate([0,width,width*3/5])
        rotate([90,0,0])
        cylinder(2.0,r=width*2/5,false,$fn=100);
        translate([0,width-2,0])
        cube([width*2/5,2,width*3/5]);
        translate([0,width-2,0])
        cube([2,2,width]);
        translate([0,width/2,0])
        rotate([0,45,0])
        cube([2*cos(45)*width/5,width,2*sin(45)*width/5],true);
        translate([0,width/2,width*1/1.5])
        cube([middle_length/2,width*2/5,width*4/15],true);
        translate([-width*2/5,width/2,width/5])
        cube([width*1.2,width*2/5,width*4/5],true);
        translate([0,width/2,width*4/15])
        rotate([0,90,0])
        cylinder(middle_length/3/2,r=0.75,false,$fn=100);
        for (i = [0:1:1]){
            translate([0,width*(1/3+1/3*i),width*7/15])
            rotate([0,90,0])
            cylinder(middle_length/3/2,d=0.53,false,$fn=50);
        }
        translate([0,width*1.5/6,width*10.87/15])
        rotate([0,90,0])
        cylinder(middle_length/3/2,d=0.53,false,$fn=50);
    }
}

// ═════════════════════════════════════════════════════════════════════════════
// MODULE: Thumb Proximal Phalanx  (from proximal_thumb.scad)
// ═════════════════════════════════════════════════════════════════════════════
module thumb_proximal(thumb_length, middle_length, palm_width)
{
    width = palm_width*16.3/90;
    difference()
    {
        union(){
            cube([thumb_length/2,width,width],false);
            translate([0,0,width*3/5])
            rotate([-90,0,0])
            cylinder(width,r=width*2/5,false,$fn=100);
            translate([thumb_length/2,0,width*3/5])
            rotate([-90,0,0])
            cylinder(width,r=width*2/5*0.9,false,$fn=100);
        }
        translate([0,width*1.1,width*3/5])
        rotate([90,0,0])
        cylinder(width*2,r=1.985,false,$fn=100);
        translate([thumb_length/2,width*1.1,width*3/5])
        rotate([90,0,0])
        cylinder(width*2,r=1.985,false,$fn=100);
        translate([0,0,width*3/5])
        rotate([-90,0,0])
        cylinder(2.0,r=width*2.1/5,false,$fn=100);
        translate([0,0,width*3/5])
        cube([width*2/5,2,width*3/5]);
        translate([0,0,width*3/5])
        cube([width*2/5,2,width]);
        translate([0,width,width*3/5])
        rotate([90,0,0])
        cylinder(2.0,r=width*2.1/5,false,$fn=100);
        translate([0,width-2,width*3/5])
        cube([width*2/5,2,width*3/5]);
        translate([0,width-2,width*3/5])
        cube([width*2/5,2,width]);
        translate([0,0,width/5])
        rotate([0,170,0])
        cube([2*cos(45)*width/5,width,2*sin(45)*width/5],false);
        translate([thumb_length/2/2,width/2,width*1/1.5])
        cube([thumb_length/2+width*4.5,width*2/5,width*4/15],true);
        translate([-width*2/5,width/2,width/5])
        cube([width*1.2,width*2/5,width*4/5],true);
        translate([thumb_length/2,width/2,width*3/5])
        rotate([90,0,0])
        cylinder(width/2-2,r=width*2/5,true,$fn=100);
        translate([thumb_length/2,width/2,width*3/5])
        rotate([-90,0,0])
        cylinder(width/2-2,r=width*2/5,true,$fn=100);
        translate([thumb_length/2-width*2/5,2,0])
        cube([2*width*2/5,width-4,width*3/5],false);
        translate([thumb_length/2-width/5,2,0])
        cube([2/3*width*2/5,width-4,width],false);
        translate([thumb_length/2,width/2,0])
        rotate([0,45,0])
        cube([2*cos(45)*width/5,width,2*sin(45)*width/5],true);
        translate([0,width/2,width*4/15])
        rotate([0,90,0])
        cylinder(thumb_length/2,r=0.75,false,$fn=100);
        for (i = [0:1:1]){
            translate([0,width*(1/3+1/3*i),width*7/15])
            rotate([0,90,0])
            cylinder(thumb_length/2,d=0.53,false,$fn=50);
        }
        translate([0,width*1.5/6,width*10.87/15])
        rotate([0,90,0])
        cylinder(thumb_length/2,d=0.53,false,$fn=50);
    }
}

// ═════════════════════════════════════════════════════════════════════════════
// MODULE: Thumb Tip  (from thumb_tip.scad)
// ═════════════════════════════════════════════════════════════════════════════
module thumb_tip(thumb_length, middle_length, palm_width)
{
    width = palm_width*16.3/90;
    difference()
    {
        union(){
            cube([thumb_length/2,width,width],false);
            translate([0,0,width*3/5])
            rotate([-90,0,0])
            cylinder(width,r=width*2/5,false,$fn=100);
            translate([thumb_length/2,0,width/2])
            rotate([-90,0,0])
            cylinder(width,r=width/2,false,$fn=100);
        }
        translate([0,width*1.1,width*3/5])
        rotate([90,0,0])
        cylinder(width*2,r=1.985,false,$fn=100);
        translate([0,0,width*3/5])
        rotate([-90,0,0])
        cylinder(2.0,r=width*2/5,false,$fn=100);
        cube([width*2/5,2,width*3/5]);
        cube([2,2,width]);
        translate([0,width,width*3/5])
        rotate([90,0,0])
        cylinder(2.0,r=width*2/5,false,$fn=100);
        translate([0,width-2,0])
        cube([width*2/5,2,width*3/5]);
        translate([0,width-2,0])
        cube([2,2,width]);
        translate([0,width/2,0])
        rotate([0,45,0])
        cube([2*cos(45)*width/5,width,2*sin(45)*width/5],true);
        translate([0,width/2,width*1/1.5])
        cube([thumb_length/2/2,width*2/5,width*4/15],true);
        translate([-width*2/5,width/2,width/5])
        cube([width*1.2,width*2/5,width*4/5],true);
        translate([0,width/2,width*4/15])
        rotate([0,90,0])
        cylinder(thumb_length/2/2,r=0.75,false,$fn=100);
        for (i = [0:1:1]){
            translate([0,width*(1/3+1/3*i),width*7/15])
            rotate([0,90,0])
            cylinder(thumb_length/2/2,d=0.53,false,$fn=50);
        }
        translate([0,width*1.5/6,width*10.87/15])
        rotate([0,90,0])
        cylinder(thumb_length/2/2,d=0.53,false,$fn=50);
    }
}

// ═════════════════════════════════════════════════════════════════════════════
// Helper: orient a finger phalanx to extend in the +Y direction.
//   Original phalanx runs along X=[0,L], Y=[0,fw], Z=[0,fw].
//   After rotate([0,0,90]) + translate([fw,0,0]) it runs along
//   X=[0,fw], Y=[0,L], Z=[0,fw] — i.e. the length axis points in +Y.
// ═════════════════════════════════════════════════════════════════════════════
module finger_orient() {
    translate([fw, 0, 0]) rotate([0, 0, 90]) children();
}
module thumb_orient() {
    translate([tw, 0, 0]) rotate([0, 0, 90]) children();
}

// Knuckle slot x-center for finger i (from Palm_Back geometry):
//   left wall at i*(gap+fw), right wall at i*(gap+fw)+2+fw
//   → center = i*(gap+fw) + 1 + fw/2
//   After finger_orient the phalanx spans X=[0,fw], so we translate
//   by center - fw/2 = i*(gap+fw)+1  then add fw from finger_orient.
//   Combined: translate_x = i*(gap+fw) + 1 + fw

if (assembled) {
    // ── Palm plates ────────────────────────────────────────────────────────
    if (show_palm_back)
        palm_1(thumb_length, middle_length, palm_width);

    // Palm pulley layer sits on top of palm back
    if (show_palm_pulley)
        translate([0, 0, palm_z])
            palm_pulley_part(palm_width);

    // Palm cover sits on top of pulley
    if (show_palm_cover)
        translate([0, 0, palm_z + 3])
            palm_cover_part(palm_width);

    // ── 4 fingers ──────────────────────────────────────────────────────────
    for (i = [0:3]) {
        px = i*(gap+fw) + 1 + fw-15;   // x-start of phalanx after finger_orient

        if (show_proximal)
            translate([px, palm_width, z_ph])
            finger_orient()
            proximal_phalanx(thumb_length, middle_length, palm_width);

        if (show_middle)
            translate([px, palm_width + middle_length/2, z_ph])
            finger_orient()
            middle_phalanx(thumb_length, middle_length, palm_width);

        if (show_distal)
            translate([px, palm_width + middle_length*5/6, z_ph])
            finger_orient()
            distal_phalanx(thumb_length, middle_length, palm_width);
    }

    // ── Thumb ──────────────────────────────────────────────────────────────
    // Mount point mirrors the Palm_Back thumb socket at [0.797,0.359]*palm_width,
    // angled at -45° so the thumb extends upper-right from the palm corner.
    thumb_mx = palm_width * 0.80;
    thumb_my = palm_width * 0.28;
    // After rotate([0,0,-45]) thumb_orient(), the phalanx length extends
    // in the (cos45, sin45) = (1/√2, 1/√2) direction.
    thumb_step = (thumb_length / 2) * 0.707;

    if (show_thumb_proximal)
        translate([thumb_mx, thumb_my, z_ph])
        rotate([0, 0, -45])
        thumb_orient()
        thumb_proximal(thumb_length, middle_length, palm_width);

    if (show_thumb_tip)
        translate([thumb_mx + thumb_step, thumb_my + thumb_step, z_ph])
        rotate([0, 0, -45])
        thumb_orient()
        thumb_tip(thumb_length, middle_length, palm_width);

} else {
    // ── Flat print layout ──────────────────────────────────────────────────
    // Phalanges rotated so length runs along Y, spaced by middle_length/2+gap
    col_step = middle_length / 2 + 10;

    if (show_palm_back)   palm_1(thumb_length, middle_length, palm_width);
    if (show_palm_cover)  translate([palm_width + 15, 0, 0]) palm_cover_part(palm_width);
    if (show_palm_pulley) translate([palm_width*2 + 30, 0, 0]) palm_pulley_part(palm_width);

    row_y = palm_width + 20;
    for (i = [0:3]) {
        col_x = i * (fw + 4);
        if (show_proximal)
            translate([col_x + fw, row_y, 0]) rotate([0,0,90])
            proximal_phalanx(thumb_length, middle_length, palm_width);
        if (show_middle)
            translate([col_x + fw, row_y + middle_length/2 + 8, 0]) rotate([0,0,90])
            middle_phalanx(thumb_length, middle_length, palm_width);
        if (show_distal)
            translate([col_x + fw, row_y + middle_length/2 + middle_length/3 + 16, 0]) rotate([0,0,90])
            distal_phalanx(thumb_length, middle_length, palm_width);
    }
    thumb_col = 4*(fw+4);
    if (show_thumb_proximal)
        translate([thumb_col + tw, row_y, 0]) rotate([0,0,90])
        thumb_proximal(thumb_length, middle_length, palm_width);
    if (show_thumb_tip)
        translate([thumb_col + tw, row_y + thumb_length/2 + 8, 0]) rotate([0,0,90])
        thumb_tip(thumb_length, middle_length, palm_width);
}
