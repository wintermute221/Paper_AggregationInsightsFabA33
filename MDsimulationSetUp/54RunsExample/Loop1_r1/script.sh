#!/bin/bash -l
#$ -S /bin/bash
#$ -l h_rt=48:00:0
#$ -l mem=2G
#$ -N r1loop1_240c
#$ -pe mpi 240
#$ -cwd
#$ -m be

  module unload compilers mpi
  module load compilers/intel/2018/update3
  module load mpi/intel/2018/update3/intel
  module load gromacs/2019.3/intel-2018

for name in $(ls -d */)
do
    cd $name

        
        gerun mdrun_mpi -deffnm md_0_1 -cpi -append

        echo 1 1 | gmx trjconv -s md_0_1.tpr -f md_0_1.xtc -o md_0_1_fit-rot_trans.xtc -ur compact -fit rot+trans

        echo 1 | gmx gyrate -s md_0_1.tpr -f md_0_1_fit-rot_trans.xtc -o gyrate.xvg
        echo 1 1 | gmx rms -s md_0_1.tpr -f md_0_1_fit-rot_trans.xtc -o rmsd.xvg -tu ns
        echo 1 | gmx rmsf -s md_0_1.tpr -f md_0_1_fit-rot_trans.xtc -o rmsf.xvg -oq bfac.pdb -res

        cd ..
done


