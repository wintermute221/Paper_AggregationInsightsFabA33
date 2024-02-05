# A protocol for MD all-atom simulation set up

<img width="690" alt="image" src="https://github.com/wintermute221/Paper_AggregationInsightsFabA33/assets/57851709/54a65ae1-7958-4306-ab3b-5f5577215a47">


* Note
  
The command is mostly adapted from Justin Lemkul's [lysozyme tutorial](http://www.mdtutorials.com/gmx/lysozyme/index.html)



  Get the mdp files from Justin's tutorial:
- nvt.mdp (change temperature, gen_temp, ref_t))
- npt.mdp (change temperature, ref_t)
- md.mdp (change temperature, ref_t)
 
 
### md.mdp (modification)
nsteps        = 1000000000000    ;  just set it to be quite long, and it can be stopped if e.g. 100 ns is achieved

nstxout                = 50000        ; save coordinates every 100 ps

nstvout                = 0            ; NOT save velocities

compressed-x-grps   = Protein   ; replaces xtc-grps, only save the protein coordinates, as I am not interested in the water/ions coordinates, which could save disc space
 
 

### script.sh (Gromacs 2019 version)
```
#!/bin/bash -l
#$ -S /bin/bash
#$ -l h_rt=48:00:0
#$ -l mem=2G
#$ -N 3.5_277_0
#$ -pe mpi 160
#$ -cwd

module load compilers/intel/2018/update3
module load mpi/intel/2018/update3/intel
module load gromacs/2019.3/intel-2018

gmx pdb2gmx  -f Fab.pdb -o processed.gro -water spce -ignh -merge interactive # choose force fields and change protein protonation states
gmx editconf -f processed.gro -o newbox.gro -c -d 1.0 -bt cubic # create a simulation environment - a box
gmx solvate -cp newbox.gro -cs spc216.gro -o solv.gro -p topol.top # add water into the environment
gmx grompp -f ions.mdp -c solv.gro -p topol.top -o ions.tpr -maxwarn 1 # generate an ionic description of the system
gmx genion -s ions.tpr -o solv_ions.gro -p topol.top -pname NA -nname CL -neutral -conc 0.05 # adding ions # choose 13

gmx grompp -f minim.mdp -c solv_ions.gro -p topol.top -o em.tpr
gerun mdrun_mpi -deffnm em # energy minimization

gmx grompp -f nvt.mdp -c em.gro -r em.gro -p topol.top -o nvt.tpr
gerun mdrun_mpi -deffnm nvt # equilibration phase I, for volumn and temperature

gmx grompp -f npt.mdp -c nvt.gro -r nvt.gro -t nvt.cpt -p topol.top -o npt.tpr
gerun mdrun_mpi -deffnm npt # euqilibration phase II, for pressure and temperature
 
gmx grompp -f md.mdp -c npt.gro -t npt.cpt -p topol.top -o md_0_1.tpr -r npt.gro
 
gerun mdrun_mpi -deffnm md_0_1 -cpi -append
```


### job_analysis.sh
```
#!/bin/bash -l
#$ -S /bin/bash
#$ -l h_rt=2:00:0
#$ -l mem=2G
#$ -N job_MD10ns
#$ -pe mpi 160
#$ -cwd

module load compilers/intel/2018/update3
module load mpi/intel/2018/update3/intel
module load gromacs/2019.3/intel-2018

echo 1 1 | gmx trjconv -s md_0_1.tpr -f md_0_1.xtc -o md_0_1_fit-rot_trans.xtc -ur compact -fit rot+trans
echo 1 | gmx gyrate -s md_0_1.tpr -f md_0_1_fit-rot_trans.xtc -o gyrate.xvg
echo 1 1 | gmx rms -s md_0_1.tpr -f md_0_1_fit-rot_trans.xtc -o rmsd.xvg -tu ns
echo 1 | gmx rmsf -s md_0_1.tpr -f md_0_1_fit-rot_trans.xtc -o rmsf.xvg -oq bfac.pdb -res
```

### Loop_version.sh
```
#!/bin/bash -l
#$ -S /bin/bash
#$ -l h_rt=48:00:0
#$ -l mem=2G
#$ -N loop1_3.5_277_0_240c
#$ -pe mpi 240
#$ -cwd
#$ -m beas

 
  module load compilers/intel/2018/update3
  module load mpi/intel/2018/update3/intel
  module load gromacs/2019.3/intel-2018

for name in $(ls -d */)
do
    cd $name

      
        gmx editconf -f processed.gro -o newbox.gro -c -d 1.0 -bt cubic
        gmx solvate -cp newbox.gro -cs spc216.gro -o solv.gro -p topol.top
        gmx grompp -f ions.mdp -c solv.gro -p topol.top -o ions.tpr -maxwarn 1
        echo 13|gmx genion -s ions.tpr -o solv_ions.gro -p topol.top -pname NA -nname CL -neutral -conc 0
        gmx grompp -f minim.mdp -c solv_ions.gro -p topol.top -o em.tpr
        gerun mdrun_mpi -deffnm em

        gmx grompp -f nvt.mdp -c em.gro -r em.gro -p topol.top -o nvt.tpr
        gerun mdrun_mpi -deffnm nvt

        gmx grompp -f npt.mdp -c nvt.gro -r nvt.gro -t nvt.cpt -p topol.top -o npt.tpr
        gerun mdrun_mpi -deffnm npt

        gmx grompp -f md.mdp -c npt.gro -t npt.cpt -p topol.top -o md_0_1.tpr -r npt.gro

        gerun mdrun_mpi -deffnm md_0_1 -cpi -append

        echo 1 1 | gmx trjconv -s md_0_1.tpr -f md_0_1.xtc -o md_0_1_noPBC.xtc -pbc mol -center
        echo 5 | gmx trjconv -s md_0_1.tpr -f md_0_1_noPBC.xtc -o md_0_1_backbone.xtc # generate the backbone trajectory file
        echo 5 | gmx trjconv -s md_0_1.tpr -f md_0_1_noPBC.xtc -o backbone_beOption.pdb -b 0 -e 0 # generate the according pdb file
```
