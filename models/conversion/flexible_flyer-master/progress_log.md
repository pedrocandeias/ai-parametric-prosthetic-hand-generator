# The Paraglider Progress Log
## Summer 2022
Wow! Just Wow.  An Eagle Scout project was developed to  produce detailed documentation for this, in the form of a PDF user manual, and a brief video to show how to work with OpenSCAD on these files.  Thanks to Peter Ilyin and his crew!  See the [manual](Instruction\_manual\_rev2.pdf) and [video](images/Instructional\_Video\_Trim.mp4).

* *Peter Ilyin* - Project Lead, Eagle Scout Candidate
* *Jackson Rodgers* - General Volunteer, Volunteer Coordinator, Technical Support Volunteer, Technical Writer, and Illustrator.
* *Leonard Katowitz* - General Volunteer, Printer Assistance, Photographer, and Illustrator
* *Dean DeSeve* - General Volunteer, Technical Writer, Photographer, and Illustrator
* *Mark Dorazelski* - General Volunteer, Technical Writer,  and Technical Consultant
* *Jasper Mosely* - Technical Consultant, and Digital Design Consultant
* *Albert Z* - General Volunteer, Instructions Tester
* *Thomas H* - General Volunteer, Instructions Tester
* *Dalton S* - General Volunteer, Instructions Tester
* *Indigo S* - General Volunteer, Instructions Tester
* *Chris S* - General Volunteer, Instructions Tester
* *Rick Y* - General Volunteer, Instructions Tester
 
## Mid-December 2020
### Wrist joint
The work on a wrist joint using an m3 screw instead of a plastic pin
is complete.  The joint has a conical thrust/axial bearing printed
in, so the screw is not the actual bearing.  It can be assembled
without any bearing material, or can either have something like
polypropylene sheet inserted to lower friction, or it can use the
non-adhesive Igus A160T-5-100 plastic, described in the materials list.  If using the
Igus plastic, I have included an option to print a thermoforming jig
which allows the plastic to be heated, and then stamped and drilled
using the jig.

### Labeling text
To allow hands to be traced and recorded, I have added the ability
to print 3 lines of text on the inside of the hand. These might
include the maker name, a serial number, and a date.
Whatever you want...

### Here it is
![Hand with new bearings and text](images/december2020palm.png)
This shows the current wrist and text design.

## Early November, 2020

### Name change (sort of) to "paraglider"
It has been decided that this project will adopt the "paraglider" name, since "flexible flyer" makes it appear it might be a flexure-joint based project.  Some files and materials will keep the old name, though.

### New!  Unlimbited V3 palm 
It is now also possible to build the parametric palm against the [Unlimbited Phoenix V3](https://www.thingiverse.com/thing:1674320)  palm, which is somewhat different.  Everything works almost the same, but the passages (especially the thumb string) are quite different. Everything should be compatible, although I have not yet tested the thumb.  The positioning of the thumb socket is different on this palm, and it may require a slightly different parametric scaling of the thumb. Use paraglider_palm_unlimbited_v3.scad and its customizer script to use this.

### Reborn palm progress
Much cleanup has been carried out on the palm based on the Phoenix Reborn project.  

## Later October, 2020
The entire 'fingerator' module has been replaced. The original used a slice off of the Phoenix finger meshes to start with, and edited from there.  The new fingers are entirely OpenSCAD objects.  
![Rendered image of new fingers](images/fingerator.png) ![Rendered image of new fingers](images/fingerator_2.png)  They have the following improvements:

* A 'keel' on the overhang to make it _really_ easy to print.  Even without very good cooling,  the distal segment overhang comes out smooth. The keel is easy to break off, and sand the stub away.
* The entire path for the elastic is covered, resulting in better aesthetics. The elastic now passes through from the top of the finger to the bottom, where it gets tied.
* There is a channel to guide the elastic so that it can be inserted in most cases without any  sort of leader to push or pull it through.
* There are two bars under each finger to tie things to, one for the string and one for the elastic.

The goal of these efforts is to produce a hand which gives as stronger grip with less effort from the user, to assist people who do not have a lot of wrist strength.

Here is a picture of an assembled finger, showing the blue Igus self-lubricating tape, the off-white bearing tubing inside a joint, and the assembled joint with a 1/16" steel pin.
![picture](images/assembled_finger.jpg) 

## October, 2020 update
There is a new OpenSCAD file, paraglider\_palm\_new\_channels.scad.  This file has a better mechanism for filling in the old string channels to get rid if various voids, etc.  It then implements an entirely new system for the channels.  There are two channels for each digit (except the thumb): one for the string and one for the elastic return band.  This should make it easier to thread, using a piece of wire as a leader to puller the strings through. It should also eliminate drag between the two lines. 
![Rendered image of new channels](images/paraglider_palm_new_channels.png)

