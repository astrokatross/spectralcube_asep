#! /bin/bash

usage()
{
echo "obs_spectral_img.sh [-d dep] [-p project] [-z] [-t] obsnum
  -d dep     : job number for dependency (afterok)
  -p project : project, (must be specified, no default)
  -z         : Debugging mode: image the CORRECTED_DATA column
                instead of imaging the DATA column
  -t         : test. Don't submit job, just make the batch file
               and then return the submission command
  obsnum     : the obsid to process, or a text file of obsids (newline separated). 
               A job-array task will be submitted to process the collection of obsids. " 1>&2;
exit 1;
}

source /software/projects/$PAWSEY_PROJECT/$USER/spectral_cube/spectralcube_asep/spectralcube.cfg

#initial variables
dep=
tst=
debug=
base=($(pwd))
# parse args and set options
while getopts ':tzd:p:' OPTION
do
    case "$OPTION" in
	d)
	    dep=${OPTARG}
	    ;;
    p)
        project=${OPTARG}
        ;;
    z)
        debug=1
        ;;
	t)
	    tst=1
	    ;;
	? | : | h)
	    usage
	    ;;
  esac
done
# set the obsid to be the first non option
shift  "$(($OPTIND -1))"
obsnum=$1
# if obsid is empty then just print help

if [[ -z ${obsnum} ]] || [[ -z $project ]] || [[ ! -d ${base} ]]
then
    echo $obsnum
    echo $project
    echo $base
    usage
fi

base="$SCRATCHDIR/$project/"

if [[ ! -z ${dep} ]]
then
    if [[ -f ${obsnum} ]]
    then
        depend="--dependency=aftercorr:${dep}"
    else
        depend="--dependency=afterok:${dep}"
    fi
fi


script="$SCRIPT_BASE/spectral_img_${obsnum}.sh"
cat "$SCRIPT_BASE/spectral_img.tmpl" | sed -e "s:OBSNUM:${obsnum}:g" \
                                 -e "s:BASEDIR:${base}:g" \
                                 -e "s:DEBUG:${debug}:g"  > "${script}"

chmod 755 "${script}"



output="spectral_img_${obsnum}.o%A"
error="spectral_img_${obsnum}.e%A"

sub="sbatch --begin=now+1minutes --account=$PAWSEY_PROJECT --export=ALL  --time=03:00:00 --cpus-per-task=64 --ntasks=1 --ntasks-per-node=1 -M setonix -p mwa --output=${output} --error=${error}"
sub="${sub} ${depend} ${script}"

if [[ ! -z ${tst} ]]
then
    echo "script is ${script}"
    echo "submit via:"
    echo "${sub}"
    exit 0
fi
    

# submit job
jobid=($(${sub}))
jobid=${jobid[3]}

echo "Submitted ${script} as ${jobid} . Follow progress here:"
