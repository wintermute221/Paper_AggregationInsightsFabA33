#!/bin/bash -l
#$ -S /bin/bash
#$ -l h_rt=48:00:0
#$ -l mem=2G
#$ -N loop1_240c
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

        gmx grompp -f minim.mdp -c solv_ions.gro -p topol.top -o em.tpr
        gerun mdrun_mpi -deffnm em

        gmx grompp -f nvt.mdp -c em.gro -r em.gro -p topol.top -o nvt.tpr
        gerun mdrun_mpi -deffnm nvt

        gmx grompp -f npt.mdp -c nvt.gro -r nvt.gro -t nvt.cpt -p topol.top -o npt.tpr
        gerun mdrun_mpi -deffnm npt

        gmx grompp -f md.mdp -c npt.gro -t npt.cpt -p topol.top -o md_0_1.tpr -r npt.gro

        gerun mdrun_mpi -deffnm md_0_1 -cpi -append

        echo 1 1 | gmx trjconv -s md_0_1.tpr -f md_0_1.xtc -o md_0_1_fit-rot_trans.xtc -ur compact -fit rot+trans

        echo 1 | gmx gyrate -s md_0_1.tpr -f md_0_1_fit-rot_trans.xtc -o gyrate.xvg
        echo 1 1 | gmx rms -s md_0_1.tpr -f md_0_1_fit-rot_trans.xtc -o rmsd.xvg -tu ns
        echo 1 | gmx rmsf -s md_0_1.tpr -f md_0_1_fit-rot_trans.xtc -o rmsf.xvg -oq bfac.pdb -res

        cd ..
done


