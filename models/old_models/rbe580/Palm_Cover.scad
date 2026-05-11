length=85;
wrist=60;
width=85;
res=30;
//length
difference(){
union(){
    //palm part
cube([10,25,2]); 
translate([0,length-35,0])cube([10,35,2]);
translate([wrist+25-10,length-35,0]) cube([10,35,2]);
translate([wrist-10,0,0]) cube([10,25,2]);   
translate([0,0,2])cube([wrist+25,length,3]);
}
union(){
    //thumb section
translate([85,50,0]) rotate([0,0,45+180]) cube([35.36,50,6]);
translate([wrist,0,0]) cube([length-wrist,25,6]);
    
    //screw holes
translate([5,5,0]) cylinder(10,r=3.26/2,true,$fn=30);
translate([5,20,0]) cylinder(10,r=3.26/2,true,$fn=30);   
translate([wrist-5,5,0]) cylinder(10,r=3.26/2,true,$fn=30);
translate([wrist-5,20,0]) cylinder(10,r=3.26/2,true,$fn=30);
    

translate([5,length-10,0]) cylinder(10,r=3.26/2,true,$fn=30);
translate([5,length-30,0]) cylinder(10,r=3.26/2,true,$fn=30);
translate([wrist+25-5,length-10,0]) cylinder(10,r=3.26/2,true,$fn=30);
translate([wrist+25-5,length-30,0]) cylinder(10,r=3.26/2,true,$fn=30);

    //internal screws
translate([22.69,37,2]) cylinder(1.24,r=2.38/2,true,$fn=res);
translate([44.69,36,2]) cylinder(1.24,r=2.38/2,true,$fn=res);
translate([64.31,37,2]) cylinder(1.24,r=2.38/2,true,$fn=res); 
translate([53.5,39,2]) cylinder(1.24,r=2.38/2,true,$fn=res);
translate([33.5,39,2]) cylinder(1.24,r=2.38/2,true,$fn=res);
    
translate([11.69,73,2]) cylinder(1.24,r=2.38/2,true,$fn=res);
translate([31.31,73,2]) cylinder(1.24,r=2.38/2,true,$fn=res);
translate([55.69,73,2]) cylinder(1.24,r=2.38/2,true,$fn=res);  
translate([75.31,73,2]) cylinder(1.24,r=2.38/2,true,$fn=res);     
    
    //chamfer
translate([0,length-8,5]) rotate([360-15,0,0]) cube([width,50,5]);

}
}


