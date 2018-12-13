DM "LOG;CLEAR;OUTPUT;CLEAR;";

libname Mydata  'D:\Mydata17';
ods html;
data X;
	set Mydata. DataBase2;
    rename _COL0=gvkey;
	rename _COL1=conm;
	rename _COL3=sic_tej;
	rename _COL4=sicb;
	rename _COL5=datadate;
	rename _COL6=cash;
	rename _COL7=AR;
	rename _COL8=inventory;
	rename _COL9=CA;
	rename _COL10=LI;
	rename _COL11=LA;
	rename _COL12=AT;
	rename _COL13=CL;
	rename _COL14=LL;
	rename _COL15=LT;
	rename _COL16=OE;
	rename _COL17=SALE;
	rename _COL18=COGS;
	rename _COL19=expense;
	rename _COL24=NI;
	rename _COL25=gross;
run;

data X2;
	set X;
	sic_tej=substr(sic_tej,2,2);
run;

data X2;
	set X2;
	if gvkey=. then delete;
	if sic_tej=. then delete;
	if cash=. then delete;
	if AR=. then delete;
	if inventory=. then delete;
	if CA=. then delete;
	if LI=. then delete;
	if LA=. then delete;
	if AT=. then delete;
	if CL=. then delete;
	if LL=. then delete;
	if LT=. then delete;
	if OE=. then delete;
	if sale=. then delete;
	if cogs=. then delete;
	if cogs = 0 then delete;
	if expense=. then delete;
	if NI=. then delete;
	if NI < 10000 then delete;
	if gross=. then delete;
run;

data X3;
	set X2;
	yyyy = year(datadate);
	mm=month(datadate);
	DebtR=LT/AT;
	ROA=NI/AT;
	ROE = NI/OE;
	logSize=log(AT);
	NPM = NI/SALE;
	AssetTurnover = SALE/AT;
	newCOGS=input (COGS,24.);
run;
proc sort  nodup; by gvkey yyyy ; run;

data X3;
	set X3;
	if mm ne 12 then delete;
	where yyyy >=2006 and yyyy <= 2016;
run;
proc sort  nodup; by gvkey yyyy ; run;


data X4;
	set X3;
	LagROA=lag(ROA);
	LagDebtR=lag(DebtR);
	LagCOGS=lag(newCOGS);
	LogCOGS=log(newCOGS);
	LogNPM = LOG(NPM);
	LagAssetTurnover = lag(AssetTurnover);
	LagROE = lag(ROE);
	if first. Conm then do;
		LagROA=.;
		LagDebtR=.;
		LagCOGS=.;
		LogNPM =.;
		LagAssetTurnover = .;
		LagROE =.;
	end;
run;
proc sort  nodup; by gvkey yyyy ; run;

data X5;
	set X4;
	LagNI=lag(NI);
	preROA = NPM*LagAssetTurnover;
	if preROA > 1 then delete;
	if first. conm then LagNI=.;
		growthNI = (NI-LagNI)/NI;
run;
proc sort  nodup; by gvkey yyyy ; run;

data Estimatel1;
	set X5;
	where yyyy between 2006 and 2014;
run;
proc sort  nodup; by gvkey yyyy ; run;


proc reg data= Estimatel1 outest=Coeff; 	
	model ROA= LagROA LagDebtR growthNI NPM LogNPM LagCOGS LogCOGS preROA LagROE  / rsquare;
	output out=output1 p=yhat r=residual;
quit;


data Coeff2;
	set Coeff;
	B0=Intercept;
	B1=LagROA;
	B2=LagDebtR;
	B3=LagCOGS;
	B3 = growthNI;
	B4 = preROA;
	B5 = LagROE;
	B6 = LogNPM;
	B7 = LogCOGS;
	keep B0-B7;
run;
**Step2:Step1︳璸玒计箇代2013ROA璝ぃ穝タStep1家家瞷ぃ岿Note: Y琌2013, X琌2012;
Data PredictA1;
	set X5;
	where yyyy=2015;
run;
proc sql;
	create table PredictA2 as
	select *
	from PredictA1, Coeff2;
quit;
data PredictA3;
	set PredictA2;
	Predict_ROA=B0+B1*LagROA+B2*LagDebtR+B3*growthNI+B4*preROA+B5*LagROE+B6*LogNPM+B7*LogCOGS;
	Error=ROA-Predict_ROA;
	Abs_Error=abs(Error);
	Error2=Error**2;
run;
proc means data=PredictA3 mean;
	var Abs_Error Error2;
	output out=Predict_PerformanceA mean=MAE RMSE;
run;
proc print data=Predict_PerformanceA; run;

***Step3:Step1家︳璸ぇ癹耴玒计箇代2014 ROA跑计lag 1戳Note: Y琌2014, X琌2013;
***Step4: 丁筁2014/12/31眔箇代罿ぃ;

Data PredictB1;
	set X5;
	where yyyy=2016;
run;
proc sql;
	create table PredictB2 as
	select *
	from PredictB1, Coeff2;
quit;
data PredictB3;
	set PredictB2;
	Predict_ROA=B0+B1*LagROA+B2*LagDebtR+B3*growthNI+B4*preROA+B5*LagROE+B6*LogNPM+B7*LogCOGS;
	Error=ROA-Predict_ROA;
	Abs_Error=abs(Error);
	Error2=Error**2;
run;
proc means data=PredictB3 mean;
	var Abs_Error Error2;
	output out=Predict_PerformanceB mean=MAE   RMSE;
run;
proc print data=Predict_PerformanceB; run;
