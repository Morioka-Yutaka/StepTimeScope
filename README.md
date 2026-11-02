# StepTimeScope
StepTimeScope is a lightweight SAS package for reviewing relative processing time across DATA and PROC steps. It records elapsed-time information with PROC SCAPROC, produces a concise step-level table, and can create a chart to surface potential hotspots. It is designed for quick performance checks and comparisons.

<img width="359" height="389" alt="StepTimeScope" src="https://github.com/user-attachments/assets/e69955d4-2987-4d4c-9a7b-0533166e4f01" />

### Usage Example
~~~sas
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
~~~


<img width="379" height="108" alt="image" src="https://github.com/user-attachments/assets/091d467d-c8c6-4225-a331-141768e8af45" />

<img width="483" height="370" alt="image" src="https://github.com/user-attachments/assets/24eb09f6-dfda-48e6-af4e-380d4097283f" />



