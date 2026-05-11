import tkinter as tk
from tkinter import StringVar, ttk
import os
import subprocess

class Application(tk.Frame):
    def __init__(self, master = None):
        tk.Frame.__init__(self, master)
        self.pack()
        self.createWidgets()

    def editText(self, fileName, valThumb, valMiddle, valPalm):
        if(not(valThumb.isnumeric()) or valThumb == '0'):
            valThumb = '1'
        if(not(valMiddle.isnumeric()) or valMiddle == '0'):
            valMiddle = '1'
        if(not(valPalm.isnumeric()) or valPalm == '0'):
            valPalm = '1'

        vals = (str(valThumb), str(valMiddle), str(valPalm))

        # Read file
        importedFile = open(fileName, "r")              # open the file in reading mode
        lineList = list(importedFile)                   # turn each line into an element of a list
        lineList[0] = 'thumb_length = %s; middle_length = %s; palm_width = %s;\n' % vals # change the first line (first element)in the list)
        importedFile.close()                            # close the file

        # Write file
        importedFile = open(fileName, "w")      # open the file in writing mode
        for line in lineList:                      # loop through each line (element in the list)
            importedFile.write(str(line))          # write the line (element of the list) to the file
        importedFile.close()                    # close the file

    def makeBoM(self, valThumb, valMiddle, valPalm, reqTorque):
        # create blank file and list of lines
        BoMFile = open('BoM.csv', "w")
        lineList = []

        # create all lines for BoM
        lineList.append('Label, Description, Quantity' + '\n')

        # motors
        # https://www.servocity.com/90-rpm-micro-gear-motor
        if reqTorque == 'High':
            lineList.append('Micro Gear Motor, 90 RPM 12V, 1' + '\n')
        elif reqTorque == 'Medium':
            lineList.append('Micro Gear Motor, 110 RPM 12V, 1' + '\n')
        elif reqTorque == 'Low':
            lineList.append('Micro Gear Motor, 130 RPM 12V, 1' + '\n')

        # motor enclosure
        # https://www.servocity.com/micro-gear-motor-enclosure
        lineList.append('Motor Enclosure, Micro, 1' + '\n')     # 0.99 servocity

        # Wire
        # http://www.berkley-fishing.com/berkley-terminal-tackle-leaders-berkley-steelon/berkley-steelon-nylon-coated-wire/1285569.html#start=1
        lineList.append('Nylon Coated Steel Wire (0.58mm), '+ str(float(valThumb) + 0.25*float(valPalm)) + 'mm, 1\n')    # thumb
        lineList.append('Nylon Coated Steel Wire (0.58mm), '+ str(0.9*float(valMiddle) + 0.45*float(valPalm)) + 'mm, 1\n')  # index
        lineList.append('Nylon Coated Steel Wire (0.58mm), '+ str(float(valMiddle) + 0.50*float(valPalm)) + 'mm, 1\n')    # middle
        lineList.append('Nylon Coated Steel Wire (0.58mm), '+ str(0.85*float(valMiddle) + 0.45*float(valPalm)) + 'mm, 1\n')  # ring
        lineList.append('Nylon Coated Steel Wire (0.58mm), '+ str(0.6*float(valMiddle) + 0.40*float(valPalm)) + 'mm, 1\n')    # pinky
        lineList.append('Nylon Coated Steel Wire (0.58mm), '+ str(0.50*float(valPalm)) + 'mm, 1\n')    # connector to motor

        # https://www.mcmaster.com/#9271k74/=1594nh2
        lineList.append('0.014" wire diam Spring, 0.075 in*lbs Torsion, 14' + '\n')

        # nuts and bolts
        lineList.append('Joint Screw, 4-40, 14' + '\n')
        lineList.append('Joint Nut, 4-40, 14' + '\n')

        # spool

        # Battery and connectors
        lineList.append('LIPO Battery, 1000mAh+ 3S 20C+, 1' + '\n') # $5.93 hobbyking
        lineList.append('LIPO Battery Sleeve, Silicone, 1' + '\n')  # $0.01 hobbyking
        lineList.append('XT60 Battery Connector, Male, 1' + '\n')  # $0.01 hobbyking
        lineList.append('XT60 Battery Connector, Female, 1' + '\n')  # $0.01 hobbyking

        # switches
        lineList.append('DPDT Switch, Center Off, 1' + '\n')    # $5.93 hobbyking

        # wire harness for other hand
        lineList.append('Stranded Electrical Wire, ' + str(25*float(valPalm)) + 'mm 16 AWG, 4\n') # 4 because motor mounted on battery mounted on hand
        lineList.append('Protective Wire Sleeve, ' + str(25*float(valPalm)) + 'mm length 3mm diameter, 1\n')
        lineList.append('Heat Shrink Tubing, 6mm x 50mm, 2' + '\n')

        # write all lines to files
        for line in lineList:
            BoMFile.write(str(line))
        BoMFile.close()

    def makePartFiles(self):
        filePath = os.path.dirname(os.path.abspath(__file__)) + "\SCADtoSTL.bat"
        #filePath = "c:\\Users\Jeff\PycharmProjects\Biomedical_Robotics\SCADtoSTL.bat"

        # Read edit field data =========================================================
        valThumb = self.efThumb.get()
        valMiddle = self.efMiddle.get()
        valPalm = self.efPalm.get()

        # Make SCAD files ===============================================================
        # do for each part
        self.editText('finger_tip.scad', valThumb, valMiddle, valPalm)
        self.editText('middle_phalanx.scad', valThumb, valMiddle, valPalm)
        self.editText('Palm_Back.scad', valThumb, valMiddle, valPalm)
        self.editText('Palm_Cover.scad', valThumb, valMiddle, valPalm)
        self.editText('Palm_Pulley.scad', valThumb, valMiddle, valPalm)
        self.editText('proximal_phalanx.scad', valThumb, valMiddle, valPalm)
        self.editText('proximal_thumb.scad', valThumb, valMiddle, valPalm)
        self.editText('thumb_tip.scad', valThumb, valMiddle, valPalm)


        # Make STL files ================================================================
        # display 'creating stl files dialogue'
        self.stSplash['text'] = 'Creating STL Files'
        self.update()

        # make the BoM
        self.makeBoM(valThumb, valMiddle, valPalm, self.torque_box.get())       # edit what the scale value is going to be

        # make the files
        p = subprocess.Popen(filePath)
        p.communicate()

        # remove 'creating stl files dialogue'
        self.stSplash['text'] = 'Prosthetic Hand STL Generator'
        self.update()

    def createWidgets(self):
        # thumb length, middle finger length, and palm width

        # Static Texts =======================================================================
        self.stSplash = tk.Label(self, text = "Prosthetic Hand STL Generator", font = ("Helvetica", 16))

        self.stThumb = tk.Label(self, text = "Thumb Length (mm)")
        self.stMiddle = tk.Label(self, text = "Middle Finger Length (mm)")
        self.stPalm = tk.Label(self, text = "Palm Width (mm)")
        self.stTorque = tk.Label(self, text = "Torque Required")

        self.stPrinter = tk.Label(self, text = "MAKE SURE TO SET 3D PRINTER TO MM UNITS")

        # Pushbuttons ========================================================================
        self.pbMakePartFiles = tk.Button(self, text = "Generate STL", command = self.makePartFiles)
        self.pbQuit = tk.Button(self, text = "QUIT", fg = "red", command = root.destroy)

        # Edit Fields ========================================================================
        self.efThumb = tk.Entry(self)
        self.efMiddle = tk.Entry(self)
        self.efPalm = tk.Entry(self)

        # Image
        self.handImage = tk.PhotoImage(file="handImage.gif")
        self.imageBin = tk.Label(self,image=self.handImage)

        # Option Menu ========================================================================
        self.torque_box = ttk.Combobox(self, textvariable = StringVar(), state ='readonly')
        self.torque_box['values'] = ('Low', 'Medium', 'High')

        # Arrange Items ======================================================================
        self.imageBin.grid(row = 0, column = 2, columnspan = 2, rowspan = 15)

        self.stSplash.grid(row = 0, column = 0, columnspan = 2, sticky ='E'+'W')

        self.pbMakePartFiles.grid(row = 1, column = 0, columnspan = 2, sticky ='E'+'W')

        self.stThumb.grid(row = 2, column = 0, sticky ='E'+'W')
        self.stMiddle.grid(row = 3, column = 0, sticky ='E'+'W')
        self.stPalm.grid(row = 4, column = 0, sticky ='E'+'W')
        self.stTorque.grid(row = 6, column = 0, sticky ='E'+'W')

        self.efThumb.grid(row = 2, column = 1, sticky ='E'+'W')
        self.efMiddle.grid(row = 3, column = 1, sticky ='E'+'W')
        self.efPalm.grid(row = 4, column = 1, sticky ='E'+'W')

        self.stPrinter.grid(row = 5, column = 0, columnspan = 2, sticky ='E'+'W')

        self.torque_box.grid(row = 6, column = 1, sticky ='E'+'W')

        self.pbQuit.grid(row = 7, column = 0, columnspan = 2, sticky ='E'+'W')


root = tk.Tk()
root.title("Hand STL Generator")
root.iconbitmap('BRicon.ico')
root.resizable(False, False)
app = Application(master = root)
app.mainloop()
