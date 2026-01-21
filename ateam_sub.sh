#! /bin/bash -l

# A template script to generate a model of a-team sources that will be subtracted
# from the visibility dataset. The idea is to make small images around a-team sources
# which that than subtracted from the visibilities. We are using wsclean to first chgcenter
# and the clean a small region arount the source. This is then subtracted from the 
# column (DATA or CORRECTED_DATA). 

set -x

pipeuser=PIPEUSER
obsnum=OBSNUM
debug=DEBUG

source ${spectral_cube_path}/spectralcube.cfg 

# Checking container availability and setting up temp disk 
if [[ ! -z ${container} ]]
then 
    # adding shorthand for simplicity later
    container="singularity run $CONTAINER_PATH/spectral_asep.img"
    echo $container 
else 
    echo "No container defined, exiting"
    exit 1
fi

if [[ -n $TMPDIR_SHM && -d $TMPDIR_SHM ]];then
    ramDiskBase=$TMPDIR_SHM
else
    ramDiskBase=$(mktemp -d /dev/shm/${jobid}_${taskid}.XXX)
fi
tempdir="${ramDiskBase}/${jobid}_${taskid}"
mkdir -p "$tempdir"
[[ -d $tempdir ]] || die "RAM disk creation unsuccessful: $tempdir"
trap "rm -rf $tempdir" EXIT

cp -rf ${obsnum}.ms ${tempdir}/


# General house keeping to get obsid info 
if [[ -f "${obsnum}" ]]
then
    taskid="${SLURM_ARRAY_TASK_ID}"
    jobid="${SLURM_ARRAY_JOB_ID}"

    echo "obsfile ${obsnum}"
    obsnum=$(sed -n -e "${SLURM_ARRAY_TASK_ID}"p "${obsnum}")
    echo "image obsid ${obsnum}"
else
    taskid=1
    jobid="${SLURM_JOB_ID}"
fi

echo "jobid: ${jobid}"
echo "taskid: ${taskid}"

# Setting up for logging info (TODO: add extra here, including perhaps database tracking of job success etc as needed)
start_time=$(date +%s)

