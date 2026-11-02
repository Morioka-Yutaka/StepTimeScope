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


<img width="658" height="216" alt="image" src="https://github.com/user-attachments/assets/091d467d-c8c6-4225-a331-141768e8af45" />
  <br>
<img width="241" height="185" alt="image" src="https://github.com/user-attachments/assets/24eb09f6-dfda-48e6-af4e-380d4097283f" />

~~~sas
%timer_start();
 
/* Step 1: Create a large synthetic transaction data set */
data work.transactions;
  length region $3 product $5;
  format transaction_date yymmdd10. amount comma14.2;
 
  call streaminit(20261102);
 
  do transaction_id = 1 to 2000000;
    customer_id      = rand('integer', 1, 300000);
    region           = cats('R', put(rand('integer', 1, 20), z2.));
    product          = cats('P', put(rand('integer', 1, 500), z4.));
    transaction_date = '01JAN2023'd + rand('integer', 0, 1095);
    quantity         = rand('integer', 1, 20);
    amount           = round(quantity * rand('uniform') * 20000, .01);
    output;
  end;
run;
 
 
/* Step 2: Sort the large transaction data set */
proc sort data=work.transactions out=work.transactions_sorted;
  by region product transaction_date customer_id;
run;
 
 
/* Step 3: Summarize transactions by region and product */
proc summary data=work.transactions_sorted nway;
  class region product;
  var amount quantity;
  output out=work.product_summary(drop=_type_ _freq_)
    n(amount)=transaction_count
    sum(amount)=total_amount
    mean(amount)=mean_amount
    sum(quantity)=total_quantity;
run;
 
 
/* Step 4: Join summary values back to transaction-level data */
proc sql;
  create table work.transactions_enriched as
  select
    a.*,
    b.transaction_count,
    b.total_amount,
    b.mean_amount,
    b.total_quantity
  from work.transactions_sorted as a
  left join work.product_summary as b
    on  a.region  = b.region
    and a.product = b.product;
quit;
 
 
/* Step 5: Assign each transaction to an amount decile */
proc rank data=work.transactions_enriched
          out=work.transactions_ranked
          groups=10;
  var amount;
  ranks amount_decile;
run;
 
 
/* Step 6: Create a final summary by region and amount decile */
proc sql;
  create table work.performance_result as
  select
    region,
    amount_decile,
    count(*)    as record_count,
    sum(amount) as total_amount format=comma18.2,
    mean(amount) as mean_amount format=comma14.2,
    mean(quantity) as mean_quantity format=8.2
  from work.transactions_ranked
  group by region, amount_decile
  order by region, amount_decile;
quit;
 
%timer_end(plot=Y);
~~~
<img width="746" height="328" alt="image" src="https://github.com/user-attachments/assets/6677d3ec-eb38-45c7-8856-9df0265a1782" />
  <br>
<img width="484" height="368" alt="image" src="https://github.com/user-attachments/assets/fc3d4921-4d53-4691-a0b7-3b3ed6ffec2d" />

## `%timer_start()` macro <a name="timerstart-macro-2"></a> ######
### Purpose:     
Starts step-level elapsed-time collection for relative performance review of subsequent DATA and PROC steps.  

### Notes:       
Uses PROC SCAPROC to record processing metadata in a temporary file under the WORK directory. FULLSTIMER is enabled for supplemental information in the SAS log.  

### Example Usage:  
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

See also:    %timer_end()

## `%timer_end()` macro <a name="timerend-macro-1"></a> ######
### Purpose:     
Stops elapsed-time collection, creates a step-level summary table, and optionally produces a bar chart.  
  
### Parameter:   
~~~text
plot=  
Y : Creates a processing-time bar chart (default).  
N : Creates the summary table only.  
~~~

### Output: 
WORK.SCAPROC_ELAPSED Contains step number, process type, elapsed time in milliseconds, and elapsed time in seconds.  
  
### Generation:  
The output data set is created with GENMAX=100.  
When %timer_start() and %timer_end() are run repeatedly in the same SAS session, up to 100 previous results are retained as generation data sets.
  
### Notes:       
Intended for relative performance checks and hotspot  identification. It is not a real-time monitoring or precise benchmarking tool.  
  
### Example Usage:  
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
Requires:    %timer_start() must be run before this macro.
 
---
  
## Notes on versions history

- 0.1.0(02November2026): Initial version.

---

## What is SAS Packages?

The package is built on top of **SAS Packages Framework(SPF)** developed by Bartosz Jablonski.

For more information about the framework, see [SAS Packages Framework](https://github.com/yabwon/SAS_PACKAGES).

You can also find more SAS Packages (SASPacs) in the [SAS Packages Archive(SASPAC)](https://github.com/SASPAC).

## How to use SAS Packages? (quick start)

### 1. Set-up SAS Packages Framework

First, create a directory for your packages and assign a `packages` fileref to it.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~sas
filename packages "\path\to\your\packages";
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Secondly, enable the SAS Packages Framework.
(If you don't have SAS Packages Framework installed, follow the instruction in 
[SPF documentation](https://github.com/yabwon/SAS_PACKAGES/tree/main/SPF/Documentation) 
to install SAS Packages Framework.)

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~sas
%include packages(SPFinit.sas)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


### 2. Install SAS package

Install SAS package you want to use with the SPF's `%installPackage()` macro.

- For packages located in **SAS Packages Archive(SASPAC)** run:
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~sas
  %installPackage(packageName)
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- For packages located in **PharmaForest** run:
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~sas
  %installPackage(packageName, mirror=PharmaForest)
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- For packages located at some network location run:
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~sas
  %installPackage(packageName, sourcePath=https://some/internet/location/for/packages)
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  (e.g. `%installPackage(ABC, sourcePath=https://github.com/SomeRepo/ABC/raw/main/)`)


### 3. Load SAS package

Load SAS package you want to use with the SPF's `%loadPackage()` macro.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~sas
%loadPackage(packageName)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


### Enjoy!
