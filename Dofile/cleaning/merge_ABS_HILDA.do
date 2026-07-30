**********************************************************************  
* Created by Heera Lee 

* Purpose of the program: 
* ======================                                                       *
* This program creates an unbalanced and a balanced longitudinal data file,    *
* using the the combined files. The new data files are in Stata's long format. *
* Please note that we use 'tempfile tempdata_w' to create a macro (local) that *
* allows us to access a temporary data file which will be automatically        *
* deleted when this do-file ends. 
* ====================== 
* Immigration in Australia 
* HILDA panel data clean do-file
**********************************************************************
clear all
	global main "/Users/ihuila/Research/AUS_immigration"
	global raw "${main}/Data raw"
	global data "${main}/Data cleaned"
	global interim "${main}/Data interim"
	global final "${main}/Data final"
**********************************************************************
