/*** HELP START ***//*

Macro:       timer_start  

Purpose:     Starts step-level elapsed-time collection for relative  
               performance review of subsequent DATA and PROC steps.  

Notes:       Uses PROC SCAPROC to record processing metadata in a  
               temporary file under the WORK directory. FULLSTIMER is  
               enabled for supplemental information in the SAS log.  

Example Usage:  
%timer_start();  
data work.class_bmi;  
  set sashelp.class;  
  bmi = weight / (height ** 2) * 703;  
run;  

proc sort data=work.class_bmi out=work.class_bmi_sort;  
  by age sex;  
run;  

proc means data=work.class_bmi_sort n mean min max;  
  var age height weight bmi;  
run;  

%timer_end();  


See also:    %timer_end()

*//*** HELP END ***/

%macro timer_start();
options fullstimer;
%let workpath=%sysfunc(pathname(WORK));
%put &=workpath;
filename scaproc "&workpath/scaproc.txt";
proc scaproc;
  record scaproc;
run;
%mend;
