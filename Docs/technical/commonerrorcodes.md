Common error codes in the FB system
---------------------------------------

* 0 : Succcess. The script/routine executed normally with no errors.

* 1 : Normal error code for some kind of natural failure, like file doesn't exist

* 2 : User error, wrong kinds/types of parameters for instance

* 5 : Programmer error, wrong usage/number of parameters for a function.

* 255 : Critical error that makes it impossible to run, and
	also will hinder a daemon to restart the job. It is
	usually, lack of some resource, like an environment
	variable, internet connection, or mounted folder. 

--------------------------------------
  Last updated:23-02-05 03:52
