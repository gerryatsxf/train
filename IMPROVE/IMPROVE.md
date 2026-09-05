1.



![alt text](image-1.png)


in this component please add a button to the right without occupying more vertical space

the button should allow a box for writing notes, in a simiilar fashion as the notes for exercises, but this time for the training as a whole. follow a similar pattern, nothing shows if there are no notes and if a note is written a small space is used to display them

2.

![alt text](image-2.png)

in live activity there are many things:
* when timer stops i dont want the live activity component to dissappear, rather just stay there indicating that the rest timer is done
* i want the numbers color to be white
* when timer is done, i want a button in the lvie activity component that will do the same as the pruple button, to register the resting time without needing to unlblock the phone, so that i can more easily just register the rest time and go on the next series


3.

if a series already has a non zero rest time recorded, when checking, no rest timer should get started

4.

i would want an edit button what will allow to update certain displayed details of the exercise
there should be updates to those details depending on the kinds of weight being used:

* Bodyweight (100%)
* Bodyweight (75%)
* Bodyweight (50%)
* Bodyweight (25%)
* Dumbbells / Kettlebells (x1)
* Dumbbells / Kettlebells (x2)
* Bar
* Pulley (Fixed 1:1)
* Pulley (Dynamic 2:1)
* Pulley (Compound 4:1)


the ratios and num of weights should play a role in the way the information is displayed in the application, as it should allow the user to understand that the execise requires to be weighted either on a single side/push/pull or on both sides, but the intention is for the component where the user inputs the weight to be dedicated only to combined weight, so that if i have an exercsie that requires two 5kg dumbbells, in the field i would input 10kg so that day training volume calculations stay consistent, so i would want the details to display and details both the 2x5kg but also show something liek =10kg or something of the sort

and for example if bodyweight is selected, i should be allowed to set something like a percentage, because for example when doing a push up you're supposed to be lifting 0.7 of your bodyweight but if its an inclined push up then it should be something like 50%

something of the sort should happen as well with the kind of selected pulley

so the point here is, if bodyweight i will record my full bodyweight in the field, if pulley i will set the total weight set in the pulley machine, but a calculation must be made according to the reuqired proportion being handled and while the input field for the bodyweight or for the pulley execrise should remain the same or as similar as possible overall, somewhere we need to signal or display to the user the calculations being made for the hwole both execrise effective volumne as well as for effective volumne for the day training




5.

following same line of thought about that execrise edit button, i would like there to be an option to switch between lb and kg

6.

*i want a button somewhere for scrolling all the way to the stop so i dont have to scroll myself when im at the bottom of scroll
* by default all execrises should appear as collapsed except for the first execrise fo the day training or bi-series exercise, and then when that is completed with checks the next exercise or bi-series exercise should open automatically. 
* also i want a toggle containers expansion button for exercises. if at least one exercise is open the toggle button should close all containers when pushed and then the button functionally should toggle to open all ontainers since now all containers are closed. consequently, the button should open all containers if all containers are closed.