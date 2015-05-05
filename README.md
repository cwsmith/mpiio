# mpiio
demonstrates mpi io library run time error on Stampede with intel 15 and impi 5

##build
    module swap intel intel/15.0.2
    module swap mvapich2 impi/5.0.2
    mpicc -mmic helloIoWorld.c -o helloIoWorld
   
##run
    module swap intel intel/15.0.2
    module swap mvapich2 impi/5.0.2
    #using standard method
    sbatch -A projectId -p development -t 1 -n 1 -N 1 ./runPhi.sh
    #using custom script
    sbatch -A projectId -p development -t 1 -n 1 -N 1 ./run-phi-1mic.sh 

##expected output from each process using runPhi.sh
   
    [0] ERROR - ADIO_Init(): Can't load libmpi_lustre.so library: libmpi_lustre.so: cannot open shared object file: No such file or directory
