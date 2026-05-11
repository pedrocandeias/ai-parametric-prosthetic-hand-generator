thumb_length = 60; middle_length = 80; palm_width = 90;

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
                   //palm
                   cube([palm_width,palm_width+finger_width*4/5,palm_width*6/90],false);
                   
                   //knuckes 
                   for (i=[0:1:3]){
                       translate([(palm_width*7.5/90+finger_width)*i,palm_width,palm_width*6/90])
                       cube([2,finger_width*4/5,finger_width*2/5],false);
                       translate([(finger_width+palm_width*7.5/90)*i,palm_width+finger_width*2/5,palm_width*6/90+finger_width*2/5])
                       rotate([0,90,0])
                       cylinder(2,r=finger_width*2/5,false,$fn=50);
//                       
                       translate([2+finger_width+(palm_width*7.5/90+finger_width)*i,palm_width,palm_width*6/85])
                       cube([2,finger_width*4/5,finger_width*2/5],false);
                       translate([(2+finger_width)+(palm_width*7.5/90+finger_width)*i,palm_width+finger_width*2/5,palm_width*6/90+finger_width*2/5])
                       rotate([0,90,0])
                       cylinder(2,r=finger_width*2/5,false,$fn=50);
                       
                   }
                }
                
                //knuckles pin holes
                translate([-0.1,palm_width+finger_width*2/5,palm_width*12/85])
                rotate([0,90,0])
                cylinder(palm_width*1.1,r=3.175/2,false,$fn=50);
                
                translate([-0.1,palm_width*87.5/85,palm_width*10/85])
                rotate([0,90,0])
                cylinder(palm_width*1.1,r=1.1905,false,$fn=50);
                
                translate([-0.1,palm_width*87.5/85,palm_width*15/85])
                rotate([0,90,0])
                cylinder(palm_width*1.1,r=1.1905,false,$fn=50);
                
                //screw extrusion
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
                
                //sliding part extrusion
                for(i = [0:1:1]){
                translate([palm_width*(14.5/85+22/85*i),0,palm_width*2/85])
                cube([palm_width*14/85,palm_width*75/85,palm_width*1.7/85],false);
                translate([palm_width*(19.86/85+22/85*i),0,palm_width*2/85])
                cube([palm_width*3.28/85,palm_width*75/85,palm_width*8/85],false);
                }
            
                //thumb slot
                translate([palm_width*60/85,0,0])
                rotate([0,0,-45])
                cube([palm_width*25/85,palm_width*35/85,palm_width*6/85],false);
                translate([palm_width,palm_width*25/85,0])
                rotate([0,0,45])
                cube([(palm_width*25/85)/sin(45),palm_width*16/85,palm_width*6/85],false);
                
                
            }
                //thumb section
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
        //3rd sliding slot extrusion
        translate([palm_width*58.5/85,0,palm_width*2/85])
        cube([palm_width*14/85,palm_width*75/85,palm_width*1.7/85],false);
        translate([palm_width*63.86/85,0,palm_width*2.7/85])
        cube([palm_width*3.28/85,palm_width*75/85,palm_width*8/90],false);
        //thumb section (extrusion)
        
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

palm_1(thumb_length, middle_length, palm_width);