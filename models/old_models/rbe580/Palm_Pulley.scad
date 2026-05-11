length=85;
wrist=60;
width=85;
res=15;
//length
difference(){
union(){
cube([10,25,1]); 
translate([0,length-35,0])cube([10,35,1]);
translate([wrist+25-10,length-35,0]) cube([10,35,1]);
translate([wrist-10,0,0]) cube([10,25,1]);   
translate([0,0,1])cube([wrist+25,length,2]);
}
union(){
//palm cutout
translate([85,50,0]) rotate([0,0,45+180]) cube([35.36,50,6]);
translate([wrist,0,0]) cube([length-wrist,25,6]);
//holes   
translate([5,5,0]) cylinder(10,r=3.46/2,true,$fn=res);
translate([5,20,0]) cylinder(10,r=3.46/2,true,$fn=res);   
translate([wrist-5,5,0]) cylinder(10,r=3.46/2,true,$fn=res);
translate([wrist-5,20,0]) cylinder(10,r=3.46/2,true,$fn=res);
    
translate([5,length-10,0]) cylinder(10,r=3.46/2,true,$fn=res);
translate([5,length-30,0]) cylinder(10,r=3.46/2,true,$fn=res);
translate([wrist+25-5,length-10,0]) cylinder(10,r=3.46/2,true,$fn=res);
translate([wrist+25-5,length-30,0]) cylinder(10,r=3.46/2,true,$fn=res);

translate([22.69,37,1]) cylinder(4,r=2.38/2,true,$fn=res);
translate([44.69,36,1]) cylinder(4,r=2.38/2,true,$fn=res);
translate([64.31,37,1]) cylinder(4,r=2.38/2,true,$fn=res); 
translate([53.5,39,1]) cylinder(4,r=2.38/2,true,$fn=res);
translate([33.5,39,1]) cylinder(4,r=2.38/2,true,$fn=res);
    
translate([11.69,73,1]) cylinder(4,r=2.38/2,true,$fn=res);
translate([31.31,73,1]) cylinder(4,r=2.38/2,true,$fn=res);
translate([55.69,73,1]) cylinder(4,r=2.38/2,true,$fn=res);  
translate([75.31,73,1]) cylinder(4,r=2.38/2,true,$fn=res);     
//slant    
translate([0,length-8,3]) rotate([360-10,0,0]) cube([width,50,5]);
//slots
union(){
    translate([21.5,65,1]) cylinder(2,r=1.64,true,$fn=res);
    translate([21.5,45,1]) cylinder(2,r=1.64,true,$fn=res); 
    translate([19.86,45,1]) cube([1.64*2,20,2]);
}
translate([44,0,0])
union(){
    translate([21.5,65,1]) cylinder(2,r=1.64,true,$fn=res);
    translate([21.5,45,1]) cylinder(2,r=1.64,true,$fn=res); 
    translate([19.86,45,1]) cube([1.64*2,20,2]);
}
translate([22,-35,0])
union(){
    translate([21.5,65,1]) cylinder(2,r=1.64,true,$fn=res);
    translate([21.5,45,1]) cylinder(2,r=1.64,true,$fn=res); 
    translate([19.86,45,1]) cube([1.64*2,20,2]);
}
}
}


