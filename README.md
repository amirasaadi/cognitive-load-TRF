Modifed version of CNSP workshop encoding tutorial code
(Nathaniel Zuk, 2021)

by Amir Hosein Asaadi(asaadi.amir@gmail.com)

This is the code that I have written for the encoding tutorial. During the hands-on session, I won't be able to go through all of it, but I have provided everything I have written. Feel free to run everything and try out various parameters.

Here are the scripts. All of these scripts use the EbrahimpourMultimedia dataset, but it should work for other datasets using the CND format:

SingleSubjectEncoding_NStim_IDnames.m -- Runs model training and cross-validation 

MultiSubjectEncoding.m -- Computes a multi-subject (generic) model by iteratively leaving one subject's data out