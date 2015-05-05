#!/bin/bash -l
#SBATCH --time=10
#SBATCH -N 1
#SBATCH -n 16
#SBATCH --exclusive
#SBATCH -p normal-mic

#For info on runscript contact Ben Matthews <matthews@ucar.edu>
#https://wiki.ucar.edu/display/hss/Xeon+Phi

#Debugging
/sbin/ifconfig
cat /etc/hosts
/sbin/ip addr
/sbin/ip link
/sbin/ip route
ibv_devinfo
env
cp -r /opt/tacc ./
ulimit -l unlimited
echo "memlock ulimit:" `ulimit -l`

#Try to avoid the worst of the TACC crazy
module purge
for i in `env | grep I_MPI| cut -f 1 -d '='`; do unset $i; done
for i in `env | grep DAPL | cut -f 1 -d '='`; do unset $i; done
for i in `env | grep TACC | cut -f 1 -d '='`; do unset $i; done

export SINK_LD_LIBRARY_PATH=/opt/apps/intel/15/composer_xe_2015.2.164/compiler/lib/mic/:/opt/apps/intel15/impi/5.0.2.044/mic/lib/:$SINK_LD_LIBRARY_PATH
export SINK_PATH=/opt/apps/intel15/impi/5.0.2.044/mic/bin:$SINK_PATH

#export LM_LICENSE_FILE="28518@128.117.177.41"
. /opt/apps/intel/15/composer_xe_2015.2.164/bin/compilervars.sh intel64
. /opt/apps/intel15/impi/5.0.2.044/bin64/mpivars.sh
#export I_MPI_PMI_LIBRARY=/usr/lib64/libpmi.so

hostnp=0
micnp=2
n_mics=1
app="/work/02422/cwsmith/mpiio/helloIoWorld"

tmpdir=`mktemp -d`

hosts=()
for i in $SLURM_NODELIST; do
	for j in `scontrol show hostname $i`; do
		hosts+=($j)
	done
done
echo "-genv I_MPI_DEBUG 5" > $tmpdir/mpi_conf
echo "-genv I_MPI_FABRICS 'shm:dapl'" >> $tmpdir/mpi_conf
echo "-genv I_MPI_FALLBACK 0" >> $tmpdir/mpi_conf
echo "-genv I_MPI_MIC 1" >> $tmpdir/mpi_conf
#echo "-genv I_MPI_MIC_PREFIX ./mic/" >> $tmpdir/mpi_conf
echo "-genv I_MPI_EXTRA_FILE_SYSTEM 1" >> $tmpdir/mpi_conf
echo "-genv I_MPI_EXTRA_FILE_SYSTEM_LLIST lustre" >> $tmpdir/mpi_conf
echo "-genv I_MPI_MIC_PROXY_PATH /opt/apps/intel15/impi/5.0.2.044/mi8/bin" >> $tmpdir/mpi_conf
MIC_ENVS="-genv PATH $SINK_PATH -genv LD_LIBRARY_PATH $SINK_LD_LIBRARY_PATH"
#MIC_ENVS=" -env I_MPI_ROOT /lustre/system/phi/intel/2015_update1/impi/5.0.2.044/mic"

for h in "${hosts[@]}"; do
	for i in `seq 0 $(( $n_mics-1 ))`; do
		printf -- "$MIC_ENVS -n %d -host %s %s\n" $micnp "$h-mic$i" "$app" >> $tmpdir/mpi_conf
	done
		printf -- "$HOST_ENVS -n %d -host %s %s\n" $hostnp "$h" "$app" >> $tmpdir/mpi_conf
done

cat $tmpdir/mpi_conf
which mpirun
export I_MPI_MIC=1
export I_MPI_MIC_PROXY_PATH=/opt/apps/intel15/impi/5.0.2.044/mic/bin
mpiexec.hydra -configfile $tmpdir/mpi_conf
rm -rf $tmpdir
