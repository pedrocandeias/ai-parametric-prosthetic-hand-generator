thumb_length = 65; middle_length = 80; palm_width = 85;

module distal_phalanx(thumb_length, middle_length, palm_width)
{
    width = palm_width*15.8/90;
    difference()
    {
        union(){
            //skeletal structure
            cube([middle_length/3,width,width],false);

            translate([0,0,width*3/5])
            rotate([-90,0,0])
            cylinder(width,r=width*2/5,false,$fn=100);
            translate([middle_length/3,0,width/2])
            rotate([-90,0,0])
            cylinder(width,r=width/2,false,$fn=100);
            
            }
            //pin holes
            translate([0,width*1.1,width*3/5])
            rotate([90,0,0])
            cylinder(width*2,r=1.985,false,$fn=100);
            
            //spacer at one end
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
          
            //cut hallow hole inside the phalanx
            translate([0,width/2,width*1/1.5])
            cube([middle_length/2,width*2/5,width*4/15],true);
            translate([-width*2/5,width/2,width/5])
            cube([width*1.2,width*2/5,width*4/5],true);
            
            
            //make a canal for cable routing
            
            translate([0,width/2,width*4/15])
            rotate([0,90,0])
            cylinder(middle_length/3/2,r=0.75,false,$fn=100);
            
            //torsion spring slot
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

distal_phalanx(thumb_length, middle_length, palm_width);