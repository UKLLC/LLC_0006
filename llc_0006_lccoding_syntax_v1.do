*Project 0006 - Full analysis record:
*Date: 02/02/23
*1. Preparation of HES dataset - HESOP excluded as no records of long COVID
*2. Preparation of GDPPR 
*3. Preparation of Denominator using Demographics file
*4. Preparation of Cohort dataset
*5. Combination and final variable preparation
*6. Descriptives for presentation
* Written by Anika Knuppel and Dylan Williams (dylan.williams@ucl.ac.uk), at the MRC Unit for Lifelong Health and Ageing at UCL

**# Bookmark #1
*Coding based on ICD-10
clear
cd "S:\LLC_0006\data\views_20221104\"
	use "LLC_0006.nhsd_HESAPC_v0001.dta"
	merge m:m epikey using "LLC_0006.nhsd_HESAPC_OTR_v0001.dta"

		gen admidated = dofc(admidate)
		format admidated %td 
		drop admidate
		rename admidated admidate
	
	drop row_version

	quietly: describe
	bysort _all: gen apc_dup=cond(_N==1,0,_n)
	drop if apc_dup>1
	
	gen apc_DomainCovid_=0
	label var apc_DomainCovid "COVID-19"
	gen apc_DomainCovid_date=0
	label var apc_DomainCovid_date "date of COVID-19"
	format apc_DomainCovid_date %td
	foreach a in 01 02 03 04 05 06 07 08 09 10 11 12 {
						   replace apc_DomainCovid_=1 if substr(diag_4_`a',1,4)=="U071"
	*covid19 virus identified
						   replace apc_DomainCovid_date=admidate if substr(diag_4_`a',1,4)=="U071"
	}
	foreach a in 01 02 03 04 05 06 07 08 09 10 11 12 {
						   replace apc_DomainCovid_=1 if substr(diag_4_`a',1,4)=="U072"
	*covid19 virus not identified
						   replace apc_DomainCovid_date=admidate if substr(diag_4_`a',1,4)=="U072"
	}
	foreach a in 01 02 03 04 05 06 07 08 09 10 11 12 {
						   replace apc_DomainCovid_=1 if substr(diag_4_`a',1,4)=="U073"
	*Personal history of COVID-19
						   replace apc_DomainCovid_date=admidate if substr(diag_4_`a',1,4)=="U073"
	}
	foreach a in 01 02 03 04 05 06 07 08 09 10 11 12 {
						   replace apc_DomainCovid_=1 if substr(diag_4_`a',1,4)=="U075"
	*Multisystem inflammatory syndrome associated with COVID-19
						   replace apc_DomainCovid_date=admidate if substr(diag_4_`a',1,4)=="U075"
	}

	gen apc_DomainLCovid_=0
	label var apc_DomainLCovid "long COVID-19"
	gen apc_DomainLCovid_date=0
	label var apc_DomainLCovid_date "date of long COVID-19"
	format apc_DomainLCovid_date %td
	foreach a in 01 02 03 04 05 06 07 08 09 10 11 12 {
						   replace apc_DomainLCovid_=1 if substr(diag_4_`a',1,4)=="U074"
	* Post COVID-19 condition
						   replace apc_DomainLCovid_date=admidate if substr(diag_4_`a',1,4)=="U074"
	}

	gen apc_LC_defined_=0
	label var apc_LC_defined "LC_defined"
	gen apc_LC_defined_date=0
	label var apc_LC_defined_date "date of LC_defined"
	format apc_LC_defined_date %td
	foreach a in 01 02 03 04 05 06 07 08 09 10 11 12 {
						   replace apc_LC_defined_=1 if substr(diag_4_`a',1,4)=="U074"
	* Post COVID-19 condition
						   replace apc_LC_defined_date=admidate if substr(diag_4_`a',1,4)=="U074"
	}

	****************************************************
	bysort llc (admidate): gen instance = _n

	* Marking out earliest occurrence of codes:
	sort llc instance
	order llc instance
	by llc: egen apc_firstdate_DomainCovid_= min(apc_DomainCovid_date) if apc_DomainCovid_==1
	format apc_firstdate_DomainCovid %td
	by llc: egen apc_firstdate_DomainLCovid_= min(apc_DomainLCovid_date) if apc_DomainLCovid_==1
	format apc_firstdate_DomainLCovid %td
	by llc: egen apc_firstdate_LC_defined_= min(apc_LC_defined_date) if apc_LC_defined_==1
	format apc_firstdate_LC_defined %td
	
	*Combining all info:
	foreach domain in DomainCovid DomainLCovid LC_defined{
	egen  tapc_`domain'_=total(apc_`domain'_==1), by(llc_0006_stud_id)
	replace  tapc_`domain'_=1 if tapc_`domain'_!=0
	egen  tapc_firstdate_`domain'_=min(apc_firstdate_`domain'_), by(llc_0006_stud_id)
	format tapc_firstdate_`domain'_ %td
	}

	* Creating wide dataset including only a marker of domains and earliest date of these:
	*drop *_date
	drop if instance!=1 // creates wide dataset with fixed variables that were duplicated across instances
	drop instance
	
	keep tapc_firstdate_* tapc_* llc*
	
	rename llc_0006_stud_id LLC_0006_stud_id 
	
	save "S:\LLC_0006\data\derived\ForPaper\views_20221104\HESAPC_data.dta", replace
	****************************************************
**# 2. Preparation of GDPPR#
	*Coding based on GPDPR_Snomed
	cd "S:\LLC_0006\data\views_20221104\"
	use "LLC_0006.nhsd_GDPPR_v0001.dta"
	
	gen dated = dofc(date)
		format dated %td 
		drop date
		rename dated date
	
	drop row_version
	quietly: describe
	bysort _all: gen gdppr_dup=cond(_N==1,0,_n)
	drop if gdppr_dup>1

	gen gdppr_DomainLCovid_=0
	label var gdppr_DomainLCovid " long COVID-19"
	gen gdppr_DomainLCovid_date=0
	label var gdppr_DomainLCovid_date "date of  long COVID-19"
	
	destring code, replace
						   replace gdppr_DomainLCovid_=1 if code==1325071000000105
	*COVID-19 Yorkshire Rehabilitation Screening tool (assessment scale)
						   replace gdppr_DomainLCovid_date=date if code==1325071000000105
						   replace gdppr_DomainLCovid_=1 if code==1325831000000100
	*Post-COVID-19 syndrome service (qualifier value)
						   replace gdppr_DomainLCovid_date=date if code==1325831000000100
						   replace gdppr_DomainLCovid_=1 if code==1325051000000101
	*Newcastle post-COVID syndrome Follow-up Screening Questionnaire (assessment scale)
						   replace gdppr_DomainLCovid_date=date if code==1325051000000101
						   replace gdppr_DomainLCovid_=1 if code==1325041000000100
	*Referral to Your COVID Recovery rehabilitation platform
						   replace gdppr_DomainLCovid_date=date if code==1325041000000100
						   replace gdppr_DomainLCovid_=1 if code==1325181000000106
	*Ongoing symptomatic disease caused by severe acute respiratory syndrome coronavirus 2
						   replace gdppr_DomainLCovid_date=date if code==1325181000000106
						   replace gdppr_DomainLCovid_=1 if code==1325101000000101
	*Assessment using Post-COVID-19 Functional Status Scale patient self-report (procedure)
						   replace gdppr_DomainLCovid_date=date if code==1325101000000101
						   replace gdppr_DomainLCovid_=1 if code==1119304009
	*Chronic post-COVID-19 syndrome (disorder)
						   replace gdppr_DomainLCovid_date=date if code==1119304009
						   replace gdppr_DomainLCovid_=1 if code==1325091000000109
	*Post-COVID-19 Functional Status Scale patient self-report (assessment scale)
						   replace gdppr_DomainLCovid_date=date if code==1325091000000109
						   replace gdppr_DomainLCovid_=1 if code==1325161000000102
	*Post-COVID-19 syndrome
						   replace gdppr_DomainLCovid_date=date if code==1325161000000102
						   replace gdppr_DomainLCovid_=1 if code==1325081000000107
	*Assessment using COVID-19 Yorkshire Rehabilitation Screening tool (procedure)
						   replace gdppr_DomainLCovid_date=date if code==1325081000000107
						   replace gdppr_DomainLCovid_=1 if code==1325141000000103
	*Assessment using Post-COVID-19 Functional Status Scale structured interview (procedure)
						   replace gdppr_DomainLCovid_date=date if code==1325141000000103
						   replace gdppr_DomainLCovid_=1 if code==1325131000000107
	*Post-COVID-19 Functional Status Scale structured interview final scale grade (observable entity)
						   replace gdppr_DomainLCovid_date=date if code==1325131000000107
						   replace gdppr_DomainLCovid_=1 if code==1325121000000105
	*Post-COVID-19 Functional Status Scale patient self-report final scale grade (observable entity)
						   replace gdppr_DomainLCovid_date=date if code==1325121000000105
						   replace gdppr_DomainLCovid_=1 if code==1325021000000106
	*Signposting to Your COVID Recovery
						   replace gdppr_DomainLCovid_date=date if code==1325021000000106
						   replace gdppr_DomainLCovid_=1 if code==1325151000000100
	*Post-COVID-19 Functional Status Scale structured interview (assessment scale)
						   replace gdppr_DomainLCovid_date=date if code==1325151000000100
						   replace gdppr_DomainLCovid_=1 if code==1326351000000108
	*Post-COVID-19 syndrome resolved (finding)
						   replace gdppr_DomainLCovid_date=date if code==1326351000000108
						   replace gdppr_DomainLCovid_=1 if code==1325061000000103
	*Assessment using Newcastle post-COVID syndrome Follow-up Screening Questionnaire (procedure)
						   replace gdppr_DomainLCovid_date=date if code==1325061000000103
						   replace gdppr_DomainLCovid_=1 if code==1325031000000108
	*Referral to post-COVID assessment clinic
						   replace gdppr_DomainLCovid_date=date if code==1325031000000108
	gen gdppr_DomainCovid_=0
	label var gdppr_DomainCovid "COVID-19"
	gen gdppr_DomainCovid_date=0
	label var gdppr_DomainCovid_date "date of COVID-19"
						   replace gdppr_DomainCovid_=1 if code==62641000237109
	*Qualitative result of severe acute respiratory syndrome coronavirus 2 immunoglobulin A antibody in serum (observable entity)
						   replace gdppr_DomainCovid_date=date if code==62641000237109
						   replace gdppr_DomainCovid_=1 if code==1321181000000108
	*Coronavirus disease 19 caused by severe acute respiratory syndrome coronavirus 2 record extraction simple reference set (foundation metadata concept)
						   replace gdppr_DomainCovid_date=date if code==1321181000000108
						   replace gdppr_DomainCovid_=1 if code==1321191000000105
	*Coronavirus disease 19 caused by severe acute respiratory syndrome coronavirus 2 procedures simple reference set (foundation metadata concept)
						   replace gdppr_DomainCovid_date=date if code==1321191000000105
						   replace gdppr_DomainCovid_=1 if code==688232241000119100
	*Disease caused by Severe acute respiratory syndrome coronavirus 2 absent (situation)
						   replace gdppr_DomainCovid_date=date if code==688232241000119100
						   replace gdppr_DomainCovid_=1 if code==871552002
	*Detection of Severe acute respiratory syndrome coronavirus 2 antibody (observable entity)
						   replace gdppr_DomainCovid_date=date if code==871552002
						   replace gdppr_DomainCovid_=1 if code==1300671000000104
	*Coronavirus disease 19 severity scale (assessment scale)
						   replace gdppr_DomainCovid_date=date if code==1300671000000104
						   replace gdppr_DomainCovid_=1 if code==1321321000000105
	*Severe acute respiratory syndrome coronavirus 2 immunoglobulin G qualitative existence in specimen (observable entity)
						   replace gdppr_DomainCovid_date=date if code==1321321000000105
						   replace gdppr_DomainCovid_=1 if code==1322781000000102
	*Severe acute respiratory syndrome coronavirus 2 antigen detection result positive (finding)
						   replace gdppr_DomainCovid_date=date if code==1322781000000102
						   replace gdppr_DomainCovid_=1 if code==1153537004
	*Antigen of inactivated whole Severe acute respiratory syndrome coronavirus 2 (substance)
						   replace gdppr_DomainCovid_date=date if code==1153537004
						   replace gdppr_DomainCovid_=1 if code==1324601000000106
	* Severe acute respiratory syndrome coronavirus 2 ribonucleic acid detected (finding)
						   replace gdppr_DomainCovid_date=date if code==1324601000000106
						   replace gdppr_DomainCovid_=1 if code==1157045004
	*Antigen of Severe acute respiratory syndrome coronavirus 2 protein (substance)
						   replace gdppr_DomainCovid_date=date if code==1157045004
						   replace gdppr_DomainCovid_=1 if code==1240421000000101
	*Serotype severe acute respiratory syndrome coronavirus 2 (qualifier value)
						   replace gdppr_DomainCovid_date=date if code==1240421000000101
						   replace gdppr_DomainCovid_=1 if code==50321000237103
	*  Qualitative result of severe acute respiratory syndrome coronavirus 2 ribonucleic acid nucleic acid amplification (observable entity)
						   replace gdppr_DomainCovid_date=date if code==50321000237103
						   replace gdppr_DomainCovid_=1 if code==1321801000000108
	*Arbitrary concentration of severe acute respiratory syndrome coronavirus 2 immunoglobulin A in serum (observable entity)
						   replace gdppr_DomainCovid_date=date if code==1321801000000108
						   replace gdppr_DomainCovid_=1 if code==1324581000000102
	*Severe acute respiratory syndrome coronavirus 2 ribonucleic acid detected (finding)
						   replace gdppr_DomainCovid_date=date if code==1324581000000102
						   replace gdppr_DomainCovid_=1 if code==66641000237105
	*Qualitative result of severe acute respiratory syndrome coronavirus 2 antibody in serum (observable entity)
						   replace gdppr_DomainCovid_date=date if code==66641000237105
						   replace gdppr_DomainCovid_=1 if code==1300631000000101
	*Coronavirus disease 19 severity score (observable entity)
						   replace gdppr_DomainCovid_date=date if code==1300631000000101
						   replace gdppr_DomainCovid_=1 if code==1240561000000108
	*Encephalopathy due to disease caused by Severe acute respiratory syndrome coronavirus 2 (disorder)
						   replace gdppr_DomainCovid_date=date if code==1240561000000108
						   replace gdppr_DomainCovid_=1 if code==840536004
	*Antigen of Severe acute respiratory syndrome coronavirus 2 (substance)
						   replace gdppr_DomainCovid_date=date if code==840536004
						   replace gdppr_DomainCovid_=1 if code==870361009
	*Immunoglobulin G antibody to Severe acute respiratory syndrome coronavirus 2 (substance)
						   replace gdppr_DomainCovid_date=date if code==870361009
						   replace gdppr_DomainCovid_=1 if code==50581000237106
	*Qualitative result of severe acute respiratory syndrome coronavirus 2 immunoglobulin M antibody in serum (observable entity)
						   replace gdppr_DomainCovid_date=date if code==50581000237106
						   replace gdppr_DomainCovid_=1 if code==840535000
	* Antibody to Severe acute respiratory syndrome coronavirus 2 (substance)
						   replace gdppr_DomainCovid_date=date if code==840535000
						   replace gdppr_DomainCovid_=1 if code==1029481000000103
	*Coronavirus nucleic acid detection assay (observable entity)
						   replace gdppr_DomainCovid_date=date if code==1029481000000103
						   replace gdppr_DomainCovid_=1 if code==1240521000000100
	*Otitis media due to disease caused by Severe acute respiratory syndrome coronavirus 2 (disorder)
						   replace gdppr_DomainCovid_date=date if code==1240521000000100
						   replace gdppr_DomainCovid_=1 if code==1300721000000109
	*Coronavirus disease 19 caused by severe acute respiratory syndrome coronavirus 2 confirmed by laboratory test (situation)
						   replace gdppr_DomainCovid_date=date if code==1300721000000109
						   replace gdppr_DomainCovid_=1 if code==1321341000000103
	*Arbitrary concentration of severe acute respiratory syndrome coronavirus 2 immunoglobulin G in serum (observable entity)
						   replace gdppr_DomainCovid_date=date if code==1321341000000103
						   replace gdppr_DomainCovid_=1 if code==1155866009
	*Messenger ribonucleic acid of Severe acute respiratory syndrome coronavirus 2 encoding spike protein (substance)
						   replace gdppr_DomainCovid_date=date if code==1155866009
						   replace gdppr_DomainCovid_=1 if code==29301000087104
	* Antigen of Severe acute respiratory syndrome coronavirus 2 recombinant spike protein (substance)
						   replace gdppr_DomainCovid_date=date if code==29301000087104
						   replace gdppr_DomainCovid_=1 if code==1240461000000109
	*Measurement of Severe acute respiratory syndrome coronavirus 2 antibody (observable entity)
						   replace gdppr_DomainCovid_date=date if code==1240461000000109
						   replace gdppr_DomainCovid_=1 if code==840544004
	*Suspected disease caused by Severe acute respiratory coronavirus 2 (situation)
						   replace gdppr_DomainCovid_date=date if code==840544004
						   replace gdppr_DomainCovid_=1 if code==1240391000000107
	*Antigen of severe acute respiratory syndrome coronavirus 2 (substance)
						   replace gdppr_DomainCovid_date=date if code==1240391000000107
						   replace gdppr_DomainCovid_=1 if code==63001000237108
	*Qualitative result of severe acute respiratory syndrome coronavirus 2 immunoglobulin G antibody in serum (observable entity)
						   replace gdppr_DomainCovid_date=date if code==63001000237108
						   replace gdppr_DomainCovid_=1 if code==119731000146105
	*Cardiomyopathy caused by severe acute respiratory syndrome coronavirus 2 (disorder)
						   replace gdppr_DomainCovid_date=date if code==119731000146105
						   replace gdppr_DomainCovid_=1 if code==1008541000000105
	*Coronavirus ribonucleic acid detection assay (observable entity)
						   replace gdppr_DomainCovid_date=date if code==1008541000000105
						   replace gdppr_DomainCovid_=1 if code==840533007
	*Severe acute respiratory syndrome coronavirus 2 (organism)
						   replace gdppr_DomainCovid_date=date if code==840533007
						   replace gdppr_DomainCovid_=1 if code==1240741000000103
	*Severe acute respiratory syndrome coronavirus 2 serology (observable entity)
						   replace gdppr_DomainCovid_date=date if code==1240741000000103
						   replace gdppr_DomainCovid_=1 if code==1321201000000107
	*Coronavirus disease 19 caused by severe acute respiratory syndrome coronavirus 2 health issues simple reference set (foundation metadata concept)
						   replace gdppr_DomainCovid_date=date if code==1321201000000107
						   replace gdppr_DomainCovid_=1 if code==1240401000000105
	*Antibody to severe acute respiratory syndrome coronavirus 2 (substance)
						   replace gdppr_DomainCovid_date=date if code==1240401000000105
						   replace gdppr_DomainCovid_=1 if code==120814005
	*Coronavirus antibody (substance)
						   replace gdppr_DomainCovid_date=date if code==120814005
						   replace gdppr_DomainCovid_=1 if code==186747009
	*Coronavirus infection (disorder)
						   replace gdppr_DomainCovid_date=date if code==186747009
						   replace gdppr_DomainCovid_=1 if code==1240531000000103
	*Myocarditis due to disease caused by Severe acute respiratory syndrome coronavirus 2 (disorder)
						   replace gdppr_DomainCovid_date=date if code==1240531000000103
						   replace gdppr_DomainCovid_=1 if code==1240571000000101
	*Gastroenteritis caused by severe acute respiratory syndrome coronavirus 2 (disorder)
						   replace gdppr_DomainCovid_date=date if code==1240571000000101
						   replace gdppr_DomainCovid_=1 if code==1321551000000106
	*Severe acute respiratory syndrome coronavirus 2 immunoglobulin M detected (finding)
						   replace gdppr_DomainCovid_date=date if code==1321551000000106
						   replace gdppr_DomainCovid_=1 if code==1325171000000109
	*Acute disease caused by severe acute respiratory syndrome coronavirus 2 infection (disorder)
						   replace gdppr_DomainCovid_date=date if code==1325171000000109
						   replace gdppr_DomainCovid_=1 if code==1240381000000105
	*Severe acute respiratory syndrome coronavirus 2 (organism)
						   replace gdppr_DomainCovid_date=date if code==1240381000000105
						   replace gdppr_DomainCovid_=1 if code==871560001
	* Detection of ribonucleic acid of Severe acute respiratory syndrome coronavirus 2 using polymerase chain reaction (observable entity)
						   replace gdppr_DomainCovid_date=date if code==871560001
						   replace gdppr_DomainCovid_=1 if code==1240751000000100
	*Coronavirus disease 19 caused by severe acute respiratory syndrome coronavirus 2 (disorder)
						   replace gdppr_DomainCovid_date=date if code==1240751000000100
						   replace gdppr_DomainCovid_=1 if code==1323081000000108
	*Coronavirus disease 19 caused by severe acute respiratory syndrome coronavirus 2 test result communication to general practice concept simple map reference set (foundation metadata concept)
						   replace gdppr_DomainCovid_date=date if code==1323081000000108
						   replace gdppr_DomainCovid_=1 if code==1321111000000101
	*Coronavirus disease 19 caused by severe acute respiratory syndrome coronavirus 2 excluded by laboratory test (situation)
						   replace gdppr_DomainCovid_date=date if code==1321111000000101
						   replace gdppr_DomainCovid_=1 if code==1119302008
	*Acute disease caused by Severe acute respiratory syndrome coronavirus 2 (disorder)
						   replace gdppr_DomainCovid_date=date if code==1119302008
						   replace gdppr_DomainCovid_=1 if code==1240471000000102
	* Measurement of Severe acute respiratory syndrome coronavirus 2 antigen (observable entity)
						   replace gdppr_DomainCovid_date=date if code==1240471000000102
						   replace gdppr_DomainCovid_=1 if code==1321811000000105
	*Severe acute respiratory syndrome coronavirus 2 immunoglobulin A qualitative existence in specimen (observable entity)
						   replace gdppr_DomainCovid_date=date if code==1321811000000105
						   replace gdppr_DomainCovid_=1 if code==1119343008
	*Messenger ribonucleic acid of Severe acute respiratory syndrome coronavirus 2 (substance)
						   replace gdppr_DomainCovid_date=date if code==1119343008
						   replace gdppr_DomainCovid_=1 if code==415398003
	*Severe acute respiratory syndrome coronavirus 2 (organism)
						   replace gdppr_DomainCovid_date=date if code==415398003
						   replace gdppr_DomainCovid_=1 if code==1300681000000102
	*Assessment using coronavirus disease 19 severity scale (procedure)
						   replace gdppr_DomainCovid_date=date if code==1300681000000102
						   replace gdppr_DomainCovid_=1 if code==51631000237101
	*Qualitative result of severe acute respiratory syndrome coronavirus 2 antigen in serum (observable entity)
						   replace gdppr_DomainCovid_date=date if code==51631000237101
						   replace gdppr_DomainCovid_=1 if code==119981000146107
	*Dyspnea caused by Severe acute respiratory syndrome coronavirus 2
						   replace gdppr_DomainCovid_date=date if code==119981000146107
						   replace gdppr_DomainCovid_=1 if code==871553007
	*Detection of Severe acute respiratory syndrome coronavirus 2 antigen (observable entity)
						   replace gdppr_DomainCovid_date=date if code==871553007
						   replace gdppr_DomainCovid_=1 if code==1240541000000107
	*Infection of upper respiratory tract caused by Severe acute respiratory syndrome coronavirus 2 (disorder)
						   replace gdppr_DomainCovid_date=date if code==1240541000000107
						   replace gdppr_DomainCovid_=1 if code==1321121000000107
	*Coronavirus disease 19 caused by severe acute respiratory syndrome coronavirus 2 excluded using clinical diagnostic criteria (situation)
						   replace gdppr_DomainCovid_date=date if code==1321121000000107
						   replace gdppr_DomainCovid_=1 if code==1321541000000108
	*Severe acute respiratory syndrome coronavirus 2 immunoglobulin G detected (finding)
						   replace gdppr_DomainCovid_date=date if code==1321541000000108
						   replace gdppr_DomainCovid_=1 if code==1321301000000101
	*Severe acute respiratory syndrome coronavirus 2 ribonucleic acid qualitative existence in specimen (observable entity)
						   replace gdppr_DomainCovid_date=date if code==1321301000000101
						   replace gdppr_DomainCovid_=1 if code==1321311000000104
	*Severe acute respiratory syndrome coronavirus 2 immunoglobulin M qualitative existence in specimen (observable entity)
						   replace gdppr_DomainCovid_date=date if code==1321311000000104
						   replace gdppr_DomainCovid_=1 if code==1323091000000105
	*Coronavirus disease 19 caused by severe acute respiratory syndrome coronavirus 2 test result communication to general practice description simple map reference set (foundation metadata concept)
						   replace gdppr_DomainCovid_date=date if code==1323091000000105
						   replace gdppr_DomainCovid_=1 if code==1321331000000107
	*Arbitrary concentration of severe acute respiratory syndrome coronavirus 2 total immunoglobulin in serum (observable entity)
						   replace gdppr_DomainCovid_date=date if code==1321331000000107
						   replace gdppr_DomainCovid_=1 if code==897034005
	*Severe acute respiratory syndrome coronavirus 2 antibody detection result positive (finding)
						   replace gdppr_DomainCovid_date=date if code==897034005
						   replace gdppr_DomainCovid_=1 if code==1240411000000107
	*Ribonucleic acid of severe acute respiratory syndrome coronavirus 2 (substance)
						   replace gdppr_DomainCovid_date=date if code==1240411000000107
						   replace gdppr_DomainCovid_=1 if code==840539006
	*Disease caused by Severe acute respiratory syndrome coronavirus 2 (disorder)
						   replace gdppr_DomainCovid_date=date if code==840539006
						   replace gdppr_DomainCovid_=1 if code==1321761000000103
	*Severe acute respiratory syndrome coronavirus 2 immunoglobulin A detected (finding)
						   replace gdppr_DomainCovid_date=date if code==1321761000000103
						   replace gdppr_DomainCovid_=1 if code==1300731000000106
	*Coronavirus disease 19 caused by severe acute respiratory syndrome coronavirus 2 confirmed using clinical diagnostic criteria (situation)
						   replace gdppr_DomainCovid_date=date if code==1300731000000106
						   replace gdppr_DomainCovid_=1 if code==1321351000000100
	*Arbitrary concentration of severe acute respiratory syndrome coronavirus 2 immunoglobulin M in serum (observable entity)
						   replace gdppr_DomainCovid_date=date if code==1321351000000100
						   replace gdppr_DomainCovid_=1 if code==882784691000119100
	*Pneumonia caused by severe acute respiratory syndrome coronavirus 2 (disorder)
						   replace gdppr_DomainCovid_date=date if code==882784691000119100
						   replace gdppr_DomainCovid_=1 if code==870362002
	*Immunoglobulin M antibody to Severe acute respiratory syndrome coronavirus 2 (substance)
						   replace gdppr_DomainCovid_date=date if code==870362002

	gen gdppr_LC_defined_=0
	label var gdppr_LC_defined "LC_defined"
	gen gdppr_LC_defined_date=0
	label var gdppr_LC_defined_date "date of LC_defined"
						   replace gdppr_LC_defined_=1 if code==1326351000000108
	*Post-COVID-19 syndrome resolved (finding)
						   replace gdppr_LC_defined_date=date if code==1326351000000108
						   replace gdppr_LC_defined_=1 if code==1325031000000108
	*Referral to post-COVID assessment clinic
						   replace gdppr_LC_defined_date=date if code==1325031000000108
						   replace gdppr_LC_defined_=1 if code==1325161000000102
	*Post-COVID-19 syndrome
						   replace gdppr_LC_defined_date=date if code==1325161000000102
						   replace gdppr_LC_defined_=1 if code==1119304009
	*Chronic post-COVID-19 syndrome (disorder)
						   replace gdppr_LC_defined_date=date if code==1119304009
						   replace gdppr_LC_defined_=1 if code==1325041000000100
	*Referral to Your COVID Recovery rehabilitation platform
						   replace gdppr_LC_defined_date=date if code==1325041000000100
						   replace gdppr_LC_defined_=1 if code==1325181000000106
	*Ongoing symptomatic disease caused by severe acute respiratory syndrome coronavirus 2
						   replace gdppr_LC_defined_date=date if code==1325181000000106
						   replace gdppr_LC_defined_=1 if code==1325021000000106
	*Signposting to Your COVID Recovery
						   replace gdppr_LC_defined_date=date if code==1325021000000106

	****************************************************
	bysort llc (date): gen instance = _n

	* Marking out earliest occurrence of codes:
		sort llc instance
		order llc instance
		by llc: egen gdppr_firstdate_DomainCovid_= min(gdppr_DomainCovid_date) if gdppr_DomainCovid_==1
		format gdppr_firstdate_DomainCovid %td
		by llc: egen gdppr_firstdate_DomainLCovid_= min(gdppr_DomainLCovid_date) if gdppr_DomainLCovid_==1
		format gdppr_firstdate_DomainLCovid %td

		by llc: egen gdppr_firstdate_LC_defined_= min(gdppr_LC_defined_date) if gdppr_LC_defined_==1
		format gdppr_firstdate_LC_defined %td
		
    foreach domain in DomainCovid DomainLCovid LC_defined{
	egen  tgdppr_`domain'_=total(gdppr_`domain'_==1), by(llc_0006_stud_id)
	replace  tgdppr_`domain'_=1 if tgdppr_`domain'_!=0
	egen tgdppr_firstdate_`domain'_=min(gdppr_firstdate_`domain'_), by(llc_0006_stud_id)
	format tgdppr_firstdate_`domain'_ %td
	}
		
	* Creating wide dataset including only a marker of domains and earliest date of these:
	*drop *_date
	drop if instance!=1 // creates wide dataset with fixed variables that were duplicated across instances
	drop instance

	keep tgdppr_firstdate_* tgdppr_* llc*
	
	rename llc_0006_stud_id LLC_0006_stud_id

	save "S:\LLC_0006\data\derived\ForPaper\views_20221104\GDPPR_data.dta", replace
	
	****************************************************
**# 3. Preparation of Denominator using Demographics file#
 *Inclusion in NHS EHR data
	use "S:\LLC_0006\data\views_20221104\LLC_0006.nhsd_DEMOGRAPHICS_SUB_20220716.dta"
	*Generate dob (set at day 1) for age 
	tostring dob_year_month, gen(dob_ym)
	gen doby=real(substr(dob_ym,1,4))
	gen dobm=real(substr(dob_ym, 5,2))
	gen dob=mdy(dobm,1, doby)
	format dob %td
	duplicates report llc_0006_stud_id
	duplicates tag llc_0006_stud_id, gen(duplicate)
	br llc_0006_stud_id dob gender if duplicate==1
	duplicates drop llc_0006_stud_id, force
	count
	
	quietly: describe
	bysort _all: gen nhsd_dup=cond(_N==1,0,_n)
	drop if nhsd_dup>1
	
	merge 1:1 llc_0006_stud_id using   "S:\LLC_0006\data\views_20221104\LLC_0006.nhsd_MORTALITY_20220106.dta", gen(mergedmortality)
	drop if mergedmortality==2
	gen deceaseds=0
	replace deceaseds=1 if mergedmortality==3
	keep llc_0006_stud_id dob deceaseds
	
	merge 1:1 llc_0006_stud_id using "S:\LLC_0006\data\views_20221104\LLC_0006.CORE_nhsd_derived_indicator_v0004_20221101.dta", gen(indic)
	gen ethnic2_nhs=.
	replace ethnic2_nhs=1 if ethnic=="A" | ethnic=="B" | ethnic=="C"| ethnic=="0"
	replace ethnic2_nhs=2 if ethnic=="1" | ethnic=="2" | ethnic=="3" | ethnic=="4" | ethnic=="5" | ethnic=="6" | ethnic=="7" | ethnic=="8" | ethnic=="D" | ethnic=="E" | ethnic=="F" | ethnic=="G" | ethnic=="H" | ethnic=="J" | ethnic=="K" | ethnic=="L" | ethnic=="M" | ethnic=="N" | ethnic=="P" | ethnic=="R" | ethnic=="S" 
	replace ethnic2_nhs=9 if ethnic=="Z" | ethnic=="X" | ethnic=="99" | ethnic=="9" | ethnic=="X"
	replace ethnic2_nhs=10 if ethnic2_nhs==.
	label def ethnic2L 1"Any White" 2"All Non-white" 9"Not known or stated" 10"Missing"
	label val ethnic2_nhs ethnic2L
	tab ethnic2_nhs, miss
	/*based on ethnicity code 2001:
		A White British
		B White Irish
		C White Any other background
		D Mixed: White & Black Caribbean
		E Mixed: White & Black African
		F Mixed: White & Asian
		G Mixed: Any other mixed background
		H Asian/Asian British - Indian
		J Asian/ Asian British - Pakistani
		K Asian/Asian British - Bangladeshi
		L Asian / Asian British - Any other Asian Background
		M Black / Black British - Caribbean
		N Black / Black British - African
		P Black / Black British - Any other Black background
		R Other Ethnic Groups - Chinese
		S Other Ethnic Groups - Any other group
		Z not stated
		X Not known (before 2013)
		99 Not known (since 2013)
		
		*Numbers see Mathur R, Bhaskaran K, Chaturvedi N, Leon D A, vanStaa T, Grundy E, Smeeth L 2014 J Public Health 'Completeness and usability of ethnicity data in UK-based primary care and hospital databases' - see supplement
		Inpatient 1995-2000:
		0 White 
		1 Black Caribbean
		2 Black African
		3 Black Other
		4 Indian
		5 Pakistani
		6 Bangladeshi
		7 Chinese
		8 Any other ethnic grp
		9 Not given
		X Not known
			*/
	gen sex_nhs=sex
	
	keep llc_0006_stud_id dob deceaseds ethnic2_nhs sex_nhs deceased 
	
	rename llc_0006_stud_id LLC_0006_stud_id
	
	save "S:\LLC_0006\data\derived\ForPaper\views_20221104\EHR_inclusion.dta", replace
	****************************************************
**# 4. Preparation of Cohort dataset#
	*Cohortdata preparation
	*Project:
	local project "_0006"
	cd "S:\LLC`project'\data\views_20221104\"
	*************************************************************
			*BCS70
	*************************************************************
	*LC wave: Wave3
	use LLC_0006.BCS70_COVID_w3_v0001_20211101.dta, clear
	gen cw3_date=mdy(cw3_enddatem, cw3_enddated, 2021)
	format cw3_date %d
	label var cw3_date "Date of cw3"
	*LongCovid
	recode cw3_covfunc (1/5=0 "no") (6=1 "4-<12wks") (7=2 "12+ weeks"), gen(longcovid3) label(longcovid3l)
	replace longcovid3=1 if cw3_covbed==6 & longcovid3!=2
	replace longcovid3=2 if cw3_covbed==7
	label var longcovid3 "Long Covid (3cat)"
	tab longcovid3 
	gen longcovid3date=cw3_date
	format longcovid3date %d
	label var longcovid3date "Date of LongCovid quest"
	keep LLC`project'_stud_id longcovid3 longcovid3date 
	gen study=1
	save "S:\LLC`project'\data\derived\ForPaper\views_20221104\BCS70.dta", replace
	clear
	*************************************************************
			*MCS
	*************************************************************
	*LC wave: Wave3
	use LLC`project'.MCS_COVID_w3_v0001_20211101.dta
	gen cw3_date=mdy(cw3_enddatem, cw3_enddated, 2021)
	format cw3_date %d
	label var cw3_date "Date of cw3"
	*LC
	recode cw3_covfunc (1/5=0 "no") (6=1 "4-<12wks") (7=2 "12+ weeks"), gen(longcovid3) label(longcovid3l)
	replace longcovid3=1 if cw3_covbed==6 & longcovid3!=2
	replace longcovid3=2 if cw3_covbed==7
	label var longcovid3 "Long Covid(3cat)"
	tab longcovid3
	gen longcovid3date=cw3_date
	format longcovid3date %d
	label var longcovid3date "Date of LongCovid quest"
	keep LLC`project'_stud_id longcovid3 longcovid3date
	gen study=2
	save "S:\LLC`project'\data\derived\ForPaper\views_20221104\MCS.dta", replace
	clear
	*************************************************************
			*NCDS
	*************************************************************
	*LC wave: Wave3
	use LLC`project'.NCDS58_COVID_w3_v0001_20211101.dta
	gen cw3_date=mdy(cw3_enddatem, cw3_enddated, 2021)
	format cw3_date %d
	label var cw3_date "Date of cw3"
	recode cw3_covfunc (1/5=0 "no") (6=1 "4-<12wks") (7=2 "12+ weeks"), gen(longcovid3) label(longcovid3l)
	replace longcovid3=1 if cw3_covbed==6 & longcovid3!=2
	replace longcovid3=2 if cw3_covbed==7
	label var longcovid3 "Long Covid(3cat)"
	tab longcovid3
	gen longcovid3date=cw3_date
	format longcovid3date %d
	label var longcovid3date "Date of LongCovid quest"
	keep LLC`project'_stud_id longcovid3date longcovid3
	gen study=3
	save "S:\LLC`project'\data\derived\ForPaper\views_20221104\NCDS.dta", replace
	clear
	*************************************************************
			*NEXTSTEP
	*************************************************************
	*LC wave: Wave3
	use LLC`project'.NEXTSTEP_COVID_w3_v0001_20211101.dta
	gen cw3_date=mdy(cw3_enddatem, cw3_enddated, 2021)
	format cw3_date %d
	label var cw3_date "Date of cw3"
	recode cw3_covfunc (1/5=0 "no") (6=1 "4-<12wks") (7=2 "12+ weeks"), gen(longcovid3) label(longcovid3l)
	replace longcovid3=1 if cw3_covbed==6 & longcovid3!=2
	replace longcovid3=2 if cw3_covbed==7
	label var longcovid3 "Long Covid(3cat)"
	tab longcovid3 
	gen longcovid3date=cw3_date
	format longcovid3date %d
	label var longcovid3date "Date of LongCovid quest"
	keep LLC`project'_stud_id longcovid3date longcovid3 
	gen study=4
	save "S:\LLC`project'\data\derived\ForPaper\views_20221104\NEXTSTEP.dta", replace
	clear
	
	*************************************************************
				*NSHD
	*************************************************************
	*LC wave: Wave3
	use LLC`project'.NSHD46_COVIDW3WEB_v0001_20211101.dta
	gen cw3_date=mdy(cw3_enddatem, cw3_enddated, 2021)
	format cw3_date %d
	recode cw3_covfunc (1/5=0 "no") (6=1 "4-<12wks") (7=2 "12+ weeks"), gen(longcovid3) label(longcovid3l)
	replace longcovid3=1 if cw3_covbed==6 & longcovid3!=2
	replace longcovid3=2 if cw3_covbed==7
	label var longcovid3 "Long Covid(3cat)"
	tab longcovid3
	recode cw3_psex (1=1 "1:men") (2=2 "2:women"), gen(sex) label(sexL)
	label var sex "Sex"
	gen longcovid3date=cw3_date
	label var longcovid3date "Date of LongCovid quest"
	keep LLC`project'_stud_id longcovid3date longcovid3 
	gen study=5
	save "S:\LLC`project'\data\derived\ForPaper\views_20221104\NSHD.dta", replace
	clear

	*************************************************************
				**#UKHLS
	*************************************************************	
	*Several waves with long Covid questions
	use LLC_0006.UKHLS_cg_indresp_w_v0001_20211101.dta, replace
	local a "cg"
	recode `a'_longcovid (1=0 "recovered")(2=1 "not recovered") (-9/-1=.), gen(`a'_covidrecov) label(covidrecovL)
	tab `a'_covidrecov
	recode `a'_cvtime (-9/-1=.) (1/3=0 "nod") (4/11=1 "4-<12wks") (12/100=2 "12+ weeks"), gen(`a'_longcovid3) label(longcovid3l)
	replace `a'_longcovid3=0 if `a'_covidrecov==0
	tab `a'_longcovid3

	gen `a'_questdate = dofc(`a'_surveyend)
		format `a'_questdate %td 

	keep LLC_0006_stud_id `a'_questdate `a'_covidrecov `a'_longcovid3
	save "S:\LLC`project'\data\derived\ForPaper\views_20221104\UKHLS_`a'.dta", replace
	clear
	use LLC_0006.UKHLS_ch_indresp_w_v0001_20211101.dta
	local a "ch"
	recode `a'_longcovid (1=0 "recovered")(2=1 "not recovered") (-9/-1=.), gen(`a'_covidrecov) label(covidrecovL)
	tab `a'_covidrecov
	recode `a'_cvtime (-9/-1=.) (1/3=0 "nod") (4/11=1 "4-<12wks") (12/100=2 "12+ weeks"), gen(`a'_longcovid3) label(longcovid3l)
	replace `a'_longcovid3=0 if `a'_covidrecov==0
	tab `a'_longcovid3

	gen `a'_questdate = dofc(`a'_surveyend)
			format `a'_questdate %td 

	keep LLC`project'_stud_id `a'_questdate `a'_covidrecov `a'_longcovid3
	save "S:\LLC`project'\data\derived\ForPaper\views_20221104\UKHLS_`a'.dta", replace
	clear
	use LLC_0006.UKHLS_ci_indresp_w_v0002_20220118.dta
	local a "ci"
	recode `a'_longcovid (1=0 "recovered")(2=1 "not recovered") (-9/-1=.), gen(`a'_covidrecov) label(covidrecovL)
	tab `a'_covidrecov
	recode `a'_cvtime (-9/-1=.) (1/3=0 "nod") (4/11=1 "4-<12wks") (12/100=2 "12+ weeks"), gen(`a'_longcovid3) label(longcovid3l)
	replace `a'_longcovid3=0 if `a'_covidrecov==0
	tab `a'_longcovid3

	gen `a'_questdate = dofc(`a'_surveyend)
			format `a'_questdate %td 

	keep LLC`project'_stud_id `a'_questdate `a'_covidrecov `a'_longcovid3
	save "S:\LLC`project'\data\derived\ForPaper\views_20221104\UKHLS_`a'.dta", replace
	clear
	*combine waves
	use S:\LLC`project'\data\derived\ForPaper\views_20221104\UKHLS_cg.dta
	foreach a in h i{
	merge m:m LLC`project'_stud_id using "S:\LLC`project'\data\derived\ForPaper\views_20221104\UKHLS_c`a'.dta", gen(merge`a') 
	}
	gen longcovid3=0
	gen age=.
	replace longcovid3=. if cg_longcovid3==. & ch_longcovid3==. & ci_longcovid3==.
	foreach a in cg ch ci{
	replace longcovid3=2 if `a'_longcovid3==2 & longcovid3!=2
		}
	foreach a in cg ch ci{
	replace longcovid3=1 if `a'_longcovid3==1 & longcovid3!=2 & longcovid3!=1
	}
	*dates
	gen longcovid3date=.
	foreach a in cg ch ci{
	replace longcovid3date=`a'_questdate if `a'_longcovid3==2 & longcovid3date==.
	}
	foreach a in cg ch ci{
	replace longcovid3date=`a'_questdate if `a'_longcovid3==1 & longcovid3date==.
	}
	foreach a in ci ch cg{
	replace longcovid3date=`a'_questdate if longcovid3==0  & longcovid3date==.
	}
	format longcovid3date %td
	*Highest length of symptoms reported at first time
	
	gen study=6
	save "S:\LLC`project'\data\derived\ForPaper\views_20221104\UKHLS.dta", replace
	clear 
	
	*************************************************************
				**#TWINS UK
	*************************************************************
	*COPE 2
	use "LLC_0006.TWINSUK_COPE2_v0002_20220302.dta"
	tab responsedate // date of questionnaire
		gen c2questday=real(substr(responsedate,1,2))
		gen c2questmonth=real(substr(responsedate, 4,2)) 
		gen c2questyear=real(substr(responsedate,7,4)) 
		gen c2questdate=mdy(c2questmonth,c2questday,c2questyear)
		format c2questdate %td
	recode b15 (0=0 "no symptoms from Covid") (1=1 "1-7 days") (2=2 "1-2 weeks") (3=3 "2-4 weeks") (4=4 "4-6 weeks") (5=5 "6+weeks") (999900/999911=.), gen(c2symptomslength)
	recode b19_1 (0=0 "always functioning") (1=1 "1-3 days") (2=2 "4-6 days") (3=3 "7-13 days") (4=4 "2-4 wks")(5=5 "4-6 wks") (6=6 "4-12 wks") (7=7 "12+wks") (999900/999911=.), gen(c2functioning)
	recode b19_2 (0=0 "none") (1=1 "1-3 days") (2=2 "4-6 days") (3=3 "1-2 wks") (4=4 "2-4 wks") (5=5 "4-6 wks") (5=6 "6+ wks")(999900/999911=.), gen(c2bedridden) // no-one in 6+ group
	*take into account functioning
	recode c2functioning (0/4=0 "<4weeks") (5/6=1 "4-<12 weeks") (7=2 "12+wks"), gen(c2longcovid3)
	replace c2longcovid3=1 if (c2bedridden==5 |c2bedridden==6) & c2longcovid3!=2
	*take into account only time
	recode c2symptomslength (0/3=0 "<4weeks") (4/5=1 "4+ weeks (12+NA)"), gen(c2longcovid3t)
	gen c2longcovid3date=c2questdate
	label var c2longcovid3date "Date of LongCovid quest COPE2"
	rename responsedate cope2responsedate
	keep c2longcovid3date c2longcovid3t c2longcovid3 LLC`project'_stud_id
	save "S:\LLC`project'\data\derived\ForPaper\views_20221104\TWINSUK_COPE2.dta", replace
	clear
	*COPE 3
	use "LLC_0006.TWINSUK_COPE3_v0001_20220531.dta"
	*issues with variables with the same name - therefore merge on seperate dataset
		gen c3questday=real(substr(responsedate,1,2))
		gen c3questmonth=real(substr(responsedate, 4,2)) 
		gen c3questyear=real(substr(responsedate,7,4)) 
		gen c3questdate=mdy(c3questmonth,c3questday, c3questyear)
		format c3questdate %td
	recode a4 (0=0 "no symptoms from Covid") (1=1 "symptoms from Covid") (999900/999911=.), gen(c3anysym)	
	recode a8 (0=0 "no symtpoms") (1=1 "1day-2weeks") (2=2 "2-4 weeks") (3=3 "4-12 weeks") (4=4 "12+weeks") (999900/999911=.), gen(c3symptomlengthall)
	recode a9 (0=0 "no symtpoms") (1=1 "1day-2weeks") (2=2 "2-4 weeks") (3=3 "4-12 weeks") (4=4 "12+weeks") (999900/999911=.), gen(c3symptomlength1st)
	gen c3longcovid3t=0 if c3symptomlengthall!=. | c3symptomlength1st!=.
	replace c3longcovid3t=2 if c3symptomlengthall==4 | c3symptomlength1st==4
	replace c3longcovid3t=1 if (c3symptomlengthall==3 | c3symptomlength1st==3) & c3longcovid3!=2
	replace c3longcovid3t=0 if c3anysym==0
	tab c3longcovid3t
	recode a10 (0=0 "always functioning") (1=1 "1-3 days") (2=2 "4-6 days") (3=3 "1-2 weeks") (4=4 "2-4 wks")(5=5 "4-12 wks") (6=6 "12+wks") (999900/999911=.), gen(c3functioning)
	recode a11 (0=0 "none") (1=1 "1-3 days") (2=2 "4-6 days") (3=3 "1-2 wks") (4=4 "2+ wks") (999900/999911=.), gen(c3bedridden) // no-one in 6+ group
	*take into account functioning
	recode c3functioning (0/4=0 "<4weeks") (5=1 "4-<12 weeks") (6=2 "12+wks"), gen(c3longcovid3)
	*bedridden not within the values to added
	gen c3longcovid3date=c3questdate
	label var c3longcovid3date "Date of LongCovid quest COPE3"
	keep c3longcovid3date c3longcovid3t c3longcovid3 LLC`project'_stud_id
	save "S:\LLC`project'\data\derived\ForPaper\views_20221104\TWINSUK_COPE3.dta", replace
	clear
	use "S:\LLC`project'\data\derived\ForPaper\views_20221104\TWINSUK_COPE2.dta"
	merge m:m LLC`project'_stud_id using "S:\LLC`project'\data\derived\ForPaper\views_20221104\TWINSUK_COPE3.dta", gen(mergecope3)
	*combine
	gen longcovid3=c2longcovid3
	gen longcovid3date=c2longcovid3date
	replace longcovid3=c3longcovid3 if longcovid3==. // cope2 missing
	replace longcovid3date=c3longcovid3date if longcovid3==.  // cope2 missing
	replace longcovid3=2 if c3longcovid3==2  // cope3 12+
	replace longcovid3date=c3longcovid3date if c3longcovid3==2 & c2longcovid3!=2
	replace longcovid3=1 if c3longcovid3==1 & longcovid3!=2 // cope3 4+
	replace longcovid3date=c3longcovid3date if c3longcovid3==1 & c2longcovid3!=2
	replace longcovid3date=c3longcovid3date if longcovid3==0 & c2longcovid3date==.

	gen longcovid3t=c2longcovid3t
	replace longcovid3t=c3longcovid3t if longcovid3t==.
	replace longcovid3t=2 if c3longcovid3t==2
	replace longcovid3t=1 if c3longcovid3t==1 & longcovid3t!=2

	gen study=7
	save "S:\LLC`project'\data\derived\ForPaper\views_20221104\TWINSUK.dta", replace
	clear

	*************************************************************
				**#ALSPAC
	*************************************************************	
	*y is G1; *m is G0 mothers
	*LC Wave: Wave 4
	use "LLC_0006.ALSPAC_wave0y_v0001_20220531.dta"
	recode kz021 (1=1 "men") (2=2 "women"), gen(sex_sr)
	keep LLC`project'_stud_id sex
	merge m:m LLC`project'_stud_id using "LLC_0006.ALSPAC_wave4y_v0001_20220531.dta"
	*Dates
		gen questday=covid4yp_9620
		gen questmonth=covid4yp_9621
		gen questyr=covid4yp_9622
		gen g1w4questdate=mdy(questmonth, questday, questyr)
		format g1w4questdate %d	
	*Length of symptoms
		recode covid4yp_1540 (1=1 "1day-2weeks") (2=2 "2-4 weeks") (3=3 "4-12 weeks") (4=4 "12+weeks") (-11/-1=.), gen(symptomlengthall)
		recode covid4yp_1550 (1=1 "1day-2weeks") (2=2 "2-4 weeks") (3=3 "4-12 weeks") (4=4 "12+weeks") (-11/-1=.), gen(symptomlength1st)
		*no question on functioning
			recode covid4yp_1560 (0=0 "none") (1=1 "1-3 days") (2=2 "4-6 days") (3=3 "1-2 wks") (4=4 "2-4 wks") (5=5 "4-12 wks")  (6=6 "12+ wks"), gen(bedridden) 
		*take into account only time
		gen longcovid3t=0 if symptomlengthall!=. | symptomlength1st!=.
		replace longcovid3t=2 if symptomlengthall==4 | symptomlength1st==4
		replace longcovid3t=1 if (symptomlengthall==3 | symptomlength1st==3) & longcovid3t!=2
		gen longcovid3date= g1w4questdate
		label var longcovid3date "Date of LongCovid quest"	
		gen longcovid3=longcovid3t
		gen study=8
	keep longcovid3 longcovid3date longcovid3t study LLC`project'_stud_id sex_sr
	save "S:\LLC`project'\data\derived\ForPaper\views_20221104\ALSPACG1.dta", replace
	clear
	
	****************************************
	*LC Wave: Wave 4
	use "LLC_0006.ALSPAC_wave4m_v0001_20220531.dta"	
	*Dates
		gen questday=covid4m_9620
		gen questmonth=covid4m_9621
		gen questyr=covid4m_9622
		gen g0w4questdate=mdy(questmonth, questday, questyr)
		format g0w4questdate %d	
	*Length of symptoms
		recode covid4m_1540 (1=1 "1day-2weeks") (2=2 "2-4 weeks") (3=3 "4-12 weeks") (4=4 "12+weeks") (-11/-1=.), gen(symptomlengthall)
		recode covid4m_1550 (1=1 "1day-2weeks") (2=2 "2-4 weeks") (3=3 "4-12 weeks") (4=4 "12+weeks") (-11/-1=.), gen(symptomlength1st)
		*length of first bout - ignored as overall length more in line with other questionnaires 
		*no question on functioning
		recode covid4m_1560 (0=0 "none") (1=1 "1-3 days") (2=2 "4-6 days") (3=3 "1-2 wks") (4=4 "2-4 wks") (5=5 "4-12 wks") (6=6 "12+ wks") , gen(bedridden) // * 12+ weeks  NA
		*take into account only time
		gen longcovid3t=0 if symptomlengthall!=. | symptomlength1st!=.
		replace longcovid3t=2 if symptomlengthall==4 | symptomlength1st==4
		replace longcovid3t=1 if (symptomlengthall==3 | symptomlength1st==3) & longcovid3t!=2
		gen longcovid3date=g0w4questdate
		label var longcovid3date "Date of LongCovid quest"	
		gen longcovid3=longcovid3t
		gen study=9
	keep longcovid3 longcovid3date longcovid3t study LLC`project'_stud_id
	save "S:\LLC`project'\data\derived\ForPaper\views_20221104\ALSPACG0.dta", replace
	clear
	****************************************
	* Pulling studies together
	cd "S:\LLC`project'\data\derived\ForPaper\views_20221104"
	use  BCS70.dta
	merge m:m LLC`project'_stud_id using "MCS.dta", gen(mergemcs) 
	merge m:m LLC`project'_stud_id using "NCDS.dta", gen(mergencds) 
	merge m:m LLC`project'_stud_id using "NEXTSTEP.dta", gen(mergenextstep)
	merge m:m LLC`project'_stud_id using "NSHD.dta", gen(mergenshd) 
	merge m:m LLC`project'_stud_id using "UKHLS.dta", gen(mergeukhls) 
	merge m:m LLC`project'_stud_id using "TWINSUK.dta",gen(mergetwinsuk)
	merge m:m LLC`project'_stud_id using "ALSPACG1.dta", gen(mergealspacg1)
	merge m:m LLC`project'_stud_id using "ALSPACG0.dta", gen(mergealspacg0)
	label def studyL 1 "BCS70" 2 "MCS" 3 "NCDS" 4"NEXTSTEP" 5"NSHD" 6"UKHLS" 7"TWINSUK" 8"ALSPAC G1" 9"ALSPAC G0"
	label val study studyL
		recode longcovid3(0=0 "no") (1/2=1 "4+"), gen(longcovid2)
		label var longcovid3 "LongCovid (3cat) defined by time/function"	
		label var longcovid2 "LongCovid (bin) defined by time/function"	
		drop longcovid3t

		gen longcovid3t=longcovid3 if study==6 | study>=8
		label var longcovid3t "LongCovid (3cat) defined by time"	
		recode longcovid3t(0=0 "no") (1/2=1 "4+"), gen(longcovid2t)
		label var longcovid2t "LongCovid (bin) defined by time"	

		gen longcovid3f=longcovid3
		replace longcovid3f=. if study==6 | study>=8
		label var longcovid3f "LongCovid (3cat) defined by function"	
		recode longcovid3f(0=0 "no") (1/2=1 "4+"), gen(longcovid2f)
		label var longcovid2f "LongCovid (bin) defined by function"	
		tab study longcovid3
		tab study longcovid2
		tab study longcovid3t
		tab study longcovid2t
		tab study longcovid3f
		tab study longcovid2f
		save "S:\LLC`project'\data\derived\ForPaper\views_20221104\cohorts_dataset_England.dta", replace
	
	***************************************************
**# 5. Combination and final variable preparation#
	*Data combined
	
	clear
	cd "S:\LLC_0006\data\derived\ForPaper\views_20221104"
	 use cohorts_dataset_England.dta
	 drop if longcovid2==. // no data on long covid
	 count
	merge 1:1 LLC_0006_stud_id using HESapc_data, gen(mergeHESapc)
	drop if mergeHESapc==2
	merge 1:1 LLC_0006_stud_id using GDPPR_data, gen(mergeGDPPR)
	drop if mergeGDPPR==2
	merge 1:1 LLC_0006_stud_id using EHR_inclusion, gen(mergeEHR)
	tab mergeEHR 
	tab study mergeEHR, row
	keep if mergeEHR==3 // only those with linkage to demographics file
	count
	
	* Merge to add IMD from the NHS D Geo dataset, issued within the UK LLC on 21st October '22
	rename LLC llc_0006_stud_id
	destring(llc), replace
	merge 1:1 llc_0006_stud_id using "S:\LLC_0006\data\derived\IMDfrom_CORE_NHSD_Geo_Indicator_v0004_20221028.dta", keepusing(imd2019_q3)
	drop if _m==2
	tab _m // identifies individuals missing IMD data 
	
	
	
	*Age variable + data quality check
	gen ageatlcquest=round(((longcovid3date-dob)/365.25),.1)
	sum ageatlcquest, det
	tabstat ageatlcquest, by(study) s(mean median min max)
	*Splitting MCS participants and parents generation
	recode study (1=1) (2=2) (3=4)(4=5) (5=6) (6=7) (7=8) (8=9) (9=10) (10=11), gen(studydet)
	replace studydet=3 if study==2 & ageatlcquest>=37.0
	label def studydetL 1 "BCS70" 2 "MCS" 3 "MCS parents" 4 "NCDS" 5"NEXTSTEP" 6"NSHD" 7"UKHLS" 8"TWINSUK" 9"ALSPAC G1" 10"ALSPAC G0"
	label val studydet studydetL
	tab study studydet
	tab studydet
	tabstat ageatlcquest, by(studydet) s(mean sd median min max)
	tab longcovid3, miss
	tab longcovid3t, miss
	*Timing
	gen apc_f_timediff=tapc_firstdate_LC_defined_-longcovid3date if longcovid3date!=. & tapc_firstdate_LC_defined_!=. & tapc_LC_defined_==1
	gen gdppr_f_timediff=tgdppr_firstdate_LC_defined_-longcovid3date if longcovid3date!=. & tgdppr_firstdate_LC_defined_!=. & tgdppr_LC_defined_==1
	gen apc_f_timediff_mth=round(apc_f_timediff/30.437)
	gen gdppr_f_timediff_mth=round(gdppr_f_timediff/30.437)
	gen f_timediff_mth=gdppr_f_timediff_mth
	replace f_timediff_mth=apc_f_timediff_mth if gdppr_f_timediff_mth==. | gdppr_f_timediff_mth>=apc_f_timediff_mth
	gen fuptime=round(((mdy(06, 01, 2022)-longcovid3date)/30.437),.1)
	sum fuptime if longcovid2!=.
	sum fuptime if longcovid2!=., det
	tabstat fuptime if longcovid2!=., by(studydet) s(mean sd med min max)
	
	gen realfuptime=fuptime
	replace realfuptime=f_timediff_mth if f_timediff_mth!=.
	sum realfuptime, det
	sum fuptime, det
	
	sum realfuptime
	sum fuptime
	
	************************************
	*Combination of health care based long Covid:
	gen hclongCovid=0
	replace hclongCovid=1 if tapc_LC_defined_==1
	replace hclongCovid=1 if tgdppr_LC_defined_==1
	tab hclongCovid
	label var hclongCovid "Long Covid code in Health records"

	**********************************************
	*Where data linkage is likely confirmed: Available data for Domain Covid or long Covid - broad definition reflecting EHR data availability
	gen gdppravail=1 if tgdppr_DomainLCovid_==1 | tgdppr_DomainCovid_==1
	gen gdpprdate=tgdppr_firstdate_DomainLCovid_ 
	replace gdpprdate=tgdppr_firstdate_DomainCovid_ if gdpprdate==.
	format gdpprdate %td
	gen apcavail=1 if tapc_DomainLCovid_==1 | tapc_DomainCovid_==1
	gen apcdate=tapc_firstdate_DomainLCovid_ 
	replace apcdate=tapc_firstdate_DomainCovid_ if apcdate==.
	format apcdate %td
	*op none available
	
	*Combine GP & APC HES data
	gen gpapcavail=0
	replace gpapcavail=1 if gdppravail==1
	replace gpapcavail=1 if apcavail==1 
	tab gpapcavail

	*Covariates
	destring(sex_nhs), replace
	gen sex=sex_nhs
	replace sex=sex_sr if sex_nhs==9
	tab sex
	
	tab ethnic2_nhs
	gen ethnic2=ethnic2_nhs if ethnic2_nhs<9
	tab ethnic2
	
	lab define ethnicity 1 "white" 2 "other"
	label values ethnic2 ethnicity
	
	xtile agetertiles=ageatlcquest, nq(3)
	tabstat ageatlcquest,by(agetertiles) s(mean n min max)
	label def agetertilesL 1"Ter1,mean25y" 2"Ter2,mean46y" 3"Ter3,mean63y"
	label val agetertiles agetertilesL
	tab agetertiles
	
	tab imd2019_q3 

	
	*SAMPLE CHARACTERISTICS
	tabstat ageatlcquest, by(studydet) s(n mean median sd)
	tab studydet
	bysort studydet: tab sex
	bysort studydet: tab ethnic2
	
	tab studydet longcovid2, nofreq row
	tab studydet longcovid2f, nofreq row
	tab studydet longcovid2t, nofreq row
	tab longcovid2 ethnic2, col 
	tab longcovid2 sex, col
	tab longcovid2f ethnic2, col 
	tab longcovid2f sex, col
	tab longcovid2t ethnic2, col 
	tab longcovid2t sex, col
	tab longcovid2
	tab longcovid2f
	tab longcovid2t
	tabstat fuptime, by(studydet) s(mean median sd p25 p75 min max)
	*MAIN ANALYSIS
	tab longcovid2 hclongCovid 
	tab longcovid2 hclongCovid, nofreq row 
	prop hclongCovid , over(longcovid2) citype(agresti)
	tabstat f_timediff_mth, by(longcovid2) s(n mean median sd p25 p75 min max)
	*by function
	tab longcovid2f hclongCovid 
	tab longcovid2f hclongCovid, nofreq row
	prop hclongCovid , over(longcovid2f) citype(agresti)
	tabstat f_timediff_mth, by(longcovid2f) s(n mean median sd p25 p75 min max)
	*by time
	tab longcovid2t hclongCovid 
	tab longcovid2t hclongCovid, nofreq row 
	prop hclongCovid , over(longcovid2t) citype(agresti)
	tabstat f_timediff_mth, by(longcovid2t) s(n mean median sd p25 p75 min max)
	
		
		***** BY SEX *****
	tab hclongCovid sex if longcovid2==0, col
	tab hclongCovid sex if longcovid2==1, col
	prop hclongCovid , over(longcovid2 sex) citype(agresti) percent
	
	prtest hclongCovid if longcovid2==0, by(sex)

	prtest hclongCovid if longcovid2==1, by(sex) 
	

	
	* by function
	
	tab hclongCovid sex if longcovid2f==0, col
	tab hclongCovid sex if longcovid2f==1, col
	prop hclongCovid , over(longcovid2 sex) citype(agresti) percent
	
	prop hclongCovid , over(longcovid2f sex) citype(agresti) percent
	
	prtest hclongCovid if longcovid2f==1, by(sex)
	
	prtest hclongCovid if longcovid2f==0, by(sex)
	
	prtest hclongCovid if longcovid2f==1, by(sex)


		* by time
	
	tab hclongCovid sex if longcovid2t==1, col
	prop hclongCovid , over(longcovid2t sex) citype(agresti) percent
	
	prtest hclongCovid if longcovid2t==0, by(sex)
	
	prtest hclongCovid if longcovid2t==1, by(sex)

	
	
	***** BY AGE *****
	bysort agetertiles: tab longcovid2 hclongCovid
	bysort agetertiles:  tab longcovid2 hclongCovid, nofreq row 
	prop hclongCovid , over(longcovid2 agetertiles) citype(agresti) percent
	
		* Non-linear differences across age tertiles
	
		* testing difference between bottom tertile and middle tertile:
			prtest hclongCovid if longcovid2==1 & agetertiles!=3, by(agetertiles)
			
	* expressing this % difference with group 1 as reference:
			recode agetertiles (1 = 3) (3 = 1), gen(inv_age)
			prtest hclongCovid if longcovid2==1 & inv_age!=1, by(inv_age)
			
	
		* testing difference between bottom tertile and top tertile:
		prtest hclongCovid if longcovid2==1 & agetertiles!=2, by(agetertiles)
	
			* testing difference between top tertile and middle tertile:
	prtest hclongCovid if longcovid2==1 & agetertiles!=1, by(agetertiles) 

			recode imd2019_q3 (1 = 3) (3 = 1), gen(inv_imd)
			
		/* testing difference in HC coding between bottom and top age tertiles among those that DID NOT originally report LC in surveys:
	prtest hclongCovid if longcovid2==0 & agetertiles!=2, by(agetertiles)
		*/
		
	* Age x debilitating LC:
		bysort agetertiles: tab longcovid2f hclongCovid
	bysort agetertiles:  tab longcovid2f hclongCovid, nofreq row 
	prop hclongCovid , over(longcovid2f agetertiles) citype(agresti) percent 
	
			* Non-linear differences across age tertiles
	
		* testing difference between bottom tertile and middle tertile:
			prtest hclongCovid if longcovid2f==1 & agetertiles!=3, by(agetertiles) 
	
		* testing difference between bottom tertile and top tertile:
		prtest hclongCovid if longcovid2f==1 & agetertiles!=2, by(agetertiles)
	
			* testing difference between top tertile and middle tertile:
	prtest hclongCovid if longcovid2f==1 & agetertiles!=1, by(agetertiles) 
		
		
		* Age x non-debilitating LC only:
		bysort agetertiles: tab longcovid2t hclongCovid
	bysort agetertiles:  tab longcovid2t hclongCovid, nofreq row 
	prop hclongCovid , over(longcovid2t agetertiles) citype(agresti) percent 
	
			* Non-linear differences across age tertiles
	
		* testing difference between bottom tertile and middle tertile:
			prtest hclongCovid if longcovid2t==1 & agetertiles!=3, by(agetertiles) 
	
		* testing difference between bottom tertile and top tertile:
		prtest hclongCovid if longcovid2t==1 & agetertiles!=2, by(agetertiles)
	
			* testing difference between top tertile and middle tertile:
	prtest hclongCovid if longcovid2t==1 & agetertiles!=1, by(agetertiles) 
		
		***** BY ETHNICITY *****
	bysort ethnic2: tab longcovid2 hclongCovid
	bysort ethnic2:  tab longcovid2 hclongCovid, nofreq row 
	prop hclongCovid , over(longcovid2 ethnic2) citype(agresti) percent
	prtest hclongCovid if longcovid2==1, by(ethnic2) // two-sided P = 0. 
				
	bysort ethnic2: tab longcovid2f hclongCovid
	bysort ethnic2:  tab longcovid2f hclongCovid, nofreq row 
	prop hclongCovid , over(longcovid2f ethnic2) citype(agresti) percent
	prtest hclongCovid if longcovid2f==1, by(ethnic2) 
		
	prop hclongCovid , over(longcovid2t ethnic2) citype(agresti) percent
	prtest hclongCovid if longcovid2t==1, by(ethnic2) 
				
		***** BY IMD *****
	
	bysort imd: tab longcovid2 hclongCovid
	bysort imd:  tab longcovid2 hclongCovid, nofreq row 
	prop hclongCovid , over(longcovid2 imd) citype(agresti) percent
	logit hclongCovid imd2019_q3 if longcovid2==1
	
		*bottom vs middle 
	prtest hclongCovid if longcovid2==1 & imd!=3, by(imd) 
			*bottom vs top
	prtest hclongCovid if longcovid2==1 & imd!=2, by(imd) 
			*middle vs top
	prtest hclongCovid if longcovid2==1 & imd!=1, by(imd) 
	
	* by function
	prop hclongCovid , over(longcovid2f imd) citype(agresti) percent
	logit hclongCovid imd2019_q3 if longcovid2f==1

			*bottom vs middle 
	prtest hclongCovid if longcovid2f==1 & imd!=3, by(imd)
			*bottom vs top
	prtest hclongCovid if longcovid2f==1 & imd!=2, by(imd)
			*middle vs top
	prtest hclongCovid if longcovid2f==1 & imd!=1, by(imd)
	
	*by time:
	prop hclongCovid , over(longcovid2t imd) citype(agresti) percent
	logit hclongCovid imd2019_q3 if longcovid2t==1


			*bottom vs middle 
	prtest hclongCovid if longcovid2t==1 & imd!=3, by(imd)
			*bottom vs top
	prtest hclongCovid if longcovid2t==1 & imd!=2, by(imd)
			*middle vs top
	prtest hclongCovid if longcovid2t==1 & imd!=1, by(imd)
	
	
	*time since diagnosis frame within without long Covid

	*by additional linkage limitation
	tab longcovid2 hclongCovid if gpapcavail==1
	tab longcovid2 hclongCovid if gpapcavail==1, nofreq row
	prop hclongCovid if gpapcavail==1, over(longcovid2) citype(agresti)
	tabstat f_timediff_mth if gpapcavail==1, by(longcovid2) s(n mean median)

	tab longcovid2f hclongCovid if gpapcavail==1
	tab longcovid2f hclongCovid if gpapcavail==1, nofreq row
	prop hclongCovid if gpapcavail==1, over(longcovid2f) citype(agresti)
	tabstat f_timediff_mth if gpapcavail==1, by(longcovid2f) s(n mean median)
	
	tab longcovid2t hclongCovid if gpapcavail==1
	tab longcovid2t hclongCovid if gpapcavail==1, nofreq row
	prop hclongCovid if gpapcavail==1, over(longcovid2t) citype(agresti)
	tabstat f_timediff_mth if gpapcavail==1, by(longcovid2t) s(n mean median)