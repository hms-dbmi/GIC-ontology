The instructions below describe how to map and load phenotypic data for GIC using the GIC ACT ontology. 
There two options to load the phenotypic data: <br>
[Upload data using CSV](https://github.com/hms-dbmi/i2b2ACTtoHPDS/blob/master/Loading%20data%20using%20CSV.MD)<br> 
[Upload data using RDBMS](https://github.com/hms-dbmi/i2b2ACTtoHPDS/blob/master/Loading%20data%20using%20RDBMS.MD)

# Frequently Asked Questions

<b>Question: What is the difference between the mapping for GIC and the ACT ontology?</b> <br>
Answer: Below are the differences between the ACT ontology used in GIC:

* Age: Age is a numeric value in GIC, not a categorical value. This allows researchers to search more dynamically. 
* GIC uses only icd_10 and not icd_10 and icd10_icd9. This is to avoid misleading investigators as patients at some institutes can be mapped to both icd_10 and icd10_icd9. 
* ‘ACT’ is prefixed in the root node path in GIC ontology.
* In the Covid file, "&#x7C" has been replaced with a pipe in the GIC ontology. Example:  \ACT COVID-19\Course Of Illness\Illness Severity\Severe Illness\Severe Lab Tests\Carbon dioxide <b>&#x7C</b>  blood arterial\Carbon dioxide:PPres:Pt:BldA:Qn


<b>Question: What version of the ACT ontology is used in GIC?</b><br>
Answer: ACT ontology V201 is used in GIC. 

<b>Question: What is the process for updating the ACT ontology version?</b><br>
Answer: In order for researchers to search and query across the GIC Common Area, all of the institutions need to use the same ontology. The GIC Working Group will review the institute’s version updates and decide democratically when the ACT ontology version should be updated for GIC.

<b>Question: How should I map the data if two different lab codes map to one LOINC code? </b><br>
Answer:  Create an entry for each code that maps to the same LOINC code in the ontology mapping table, in HPDS_DATA_LATEST the two different local lab_code will be populated with one concept_path.

<b>Question: When a concept code has more than one concept path (example: when there are different parent/child hierarchies present for a concept code). Do I need to eliminate the one to many relationship and pick one of the concept paths when there are many paths? Or do I create multiple individual records (one per concept path) in HPDS? </b><br>
Answer:  Create multiple individual records per concept path with different c_name ( name_char).

 
<b>Question: In i2B2 encounter_num is part of the primary key (and so is instance_num), without this column included in the mapping file I would get records that may seem like duplicates. How do I resolve the duplicates issue?</b><br>
Answer: HPDS ETL format takes a timestamp parameter, you should populate this with the startTime from your encounter or observation fact.


<b>Question: What is the cadence of when each institute should refresh its data in GIC?</b><br>
Answer: Every 1-3 months or if there is a change in the ontology. 

<b>Question: Is there an order in which the phenotypic and genomic data should be loaded?</b><br>
Answer: The phenotypic data should be loaded first. The genomic data should be loaded after using the patient nums created from loading the phenotypic data. 

<b>Question: Can I load additional columns to HPDS for my institute to assist with mapping, etc?</b><br>
Answer: Yes, you can load additional columns into your institute’s instance of HPDS. 

<b>Question: What are the values for the biosamples mapping?</b><br>
Biosample | Path | Value
:--- | :--- | :--- 
WGS | \Variant Data Type\WGS\ | True
WES | \Variant Data Type\WES\ | True
Genotype array |  \Variant Data Type\Genotype array\ | True
Low coverage WGS |  \Variant Data Type\Low coverage WGS\ | True
Extracted DNA | \Bio Specimens\NucleicAcid\DNA\ | True
Wholeblood | \Bio Specimens\HumanFluid\Blood (Whole)\SPECIMENS:HF.BLD.000 Quantity\ | Quantity
Plasma | \Bio Specimens\HumanFluid\Plasma\SPECIMENS:HF.PLS.000 Quantity\ | Quantity
Tissue | \Bio Specimens\HumanTissue\ | True
CSF | \Bio Specimens\HumanFluid\Brain\Cerebro-Spinal Fluid (CSF)\SPECIMENS:HF.BRN.004\ |True
