/*** HELP START ***//*

Macro:       timer_end  

Purpose:     Stops elapsed-time collection, creates a step-level  
               summary table, and optionally produces a bar chart.  
  
Parameter:   plot=  
                 Y : Creates a processing-time bar chart (default).  
                 N : Creates the summary table only.  
  
Output:      WORK.SCAPROC_ELAPSED  
               Contains step number, process type, elapsed time in  
               milliseconds, and elapsed time in seconds.  
  
Generation:  The output data set is created with GENMAX=100.  
               When %timer_start() and %timer_end() are run repeatedly  
               in the same SAS session, up to 100 previous results are  
               retained as generation data sets.
  
Notes:       Intended for relative performance checks and hotspot  
               identification. It is not a real-time monitoring or  
               precise benchmarking tool.  
  
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
  
Requires:    %timer_start() must be run before this macro.

*//*** HELP END ***/

%macro timer_end(plot=Y);
data a;
set sashelp.class;
run;
ods html;
proc scaproc;
  write;
run;
options nofullstimer;

data scaproc_elapsed(genmax=100);
  length line $32767 procname $32;
  retain elapsed_ms step_no 0;

  infile scaproc lrecl=32767 truncover;
  input;
  line = _infile_;

  if index(line, 'JOBSPLIT: ELAPSED') > 0 then do;
    elapsed_ms = input(scan(line, 4, ' '), best32.);
  end;

  else if index(line, 'JOBSPLIT: PROCNAME') > 0 then do;
    procname = scan(line, 4, ' ');

    if not missing(elapsed_ms) then do;
      step_no + 1;
      elapsed_sec = elapsed_ms / 1000;
      output;
    end;

    call missing(elapsed_ms);
  end;

  keep step_no procname elapsed_ms elapsed_sec;
  format elapsed_sec 12.3;
run;
proc print data=scaproc_elapsed noobs label;
label step_no     = 'Step Number'
      procname    = 'Process Type'
      elapsed_ms  = 'Elapsed Time (Milliseconds)'
      elapsed_sec = 'Elapsed Time (Seconds)';
run;
filename scaproc clear;
%if %upcase(&plot)=Y %then %do; 
proc sgplot data=work.scaproc_elapsed;
  vbarparm category=step_no response=elapsed_sec /
    datalabel=procname
    datalabelpos=bottom
    datalabelattrs=(size=6)
    fillattrs=(color=cx4E79A7);

  xaxis label='Step Number'
        integer
        grid;

  yaxis label='Elapsed Time (Seconds)'
        grid;

  title 'Processing Time by Step';
run;
title;
%end;
%mend;
