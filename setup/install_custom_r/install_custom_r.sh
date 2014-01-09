#!/bin/bash
#Install a custom version of R and R packages needed
export DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "Script dir is:" $DIR

#Check environment
[ -z "$GENOME_SW" ] && echo "GENOME_SW is not set " && exit 1;
echo "GENOME_SW is:" $GENOME_SW

#Set the R version to install
export R_VERSION="R-2.15.2"
echo "INSTALLING R VERSION" $R_VERSION

#Create the installation location
export R_BASE_DIR="$GENOME_SW/R"
[ ! -d $R_BASE_DIR ] && mkdir $R_BASE_DIR && echo echo "Creating base R dir"
export R_INSTALL_DIR="$R_BASE_DIR/$R_VERSION"

#Make sure this version of R is not already there
[ -d $R_INSTALL_DIR ] && echo "Already installed this version of R?:" $R_INSTALL_DIR && exit 1

#Install a specific version of R to custom location
cd $R_BASE_DIR
wget http://cran.r-project.org/src/base/R-2/$R_VERSION.tar.gz
tar -zxvf $R_VERSION.tar.gz
[ ! -d $R_INSTALL_DIR ] && echo "R_INSTALL_DIR missing:" $R_INSTALL_DIR && exit 1
cd $R_INSTALL_DIR
./configure --prefix=$R_INSTALL_DIR/ --enable-memory-profiling --with-tcltk --with-cairo --with-libpng --with-jpeglib --with-libtiff
make
make install

#Make this first version of R to use in PATH
export PATH=$GENOME_SW/R/$R_VERSION/bin:$PATH

#Make sure the R bin was successfully installed where expected
export R_BIN="$R_INSTALL_DIR/bin/R"
[ ! -e $R_BIN ] && echo "R_BIN missing:" $R_BIN && exit 1

#Install R libraries needed from within an R session
echo "INSTALLING R LIBRARIES FROM WITHIN AN R SESSION"
echo "Script dir is " $DIR
$R_BIN CMD BATCH $DIR/install_r_packages.R $R_INSTALL_DIR/install_r_packages.stdout

#Install R libraries that must be handled manually
echo "INSTALLING R LIBRARIES THAT MUST BE HANDLED MANUALLY"
mkdir $R_INSTALL_DIR/custom_packages
export CUSTOM_DIR="$GENOME_SW/R/$R_VERSION/custom_packages"
echo "Directory for custom packages is " $CUSTOM_DIR

#Install CopyCat R package manually -> 'copyCat'
echo $CUSTOM_DIR
cd $CUSTOM_DIR
git clone https://github.com/chrisamiller/copyCat.git
cd $CUSTOM_DIR/copyCat
export COPYCAT_VERSION=$(grep "Version" copyCat/DESCRIPTION | awk '{print $2}')
$R_BIN CMD build copyCat
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library copyCat_$COPYCAT_VERSION.tar.gz

#Install 'gplots' package manually -> 'gplots'
cd $CUSTOM_DIR
wget http://cran.r-project.org/src/contrib/Archive/gplots/gplots_2.8.0.tar.gz
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library gplots_2.8.0.tar.gz

#Install pbh5 package -> 'pbh5'
cd $CUSTOM_DIR
git clone https://github.com/PacificBiosciences/R-pbh5.git
tar -cf pbh5.tar R-pbh5/
gzip pbh5.tar
$R_BIN CMD INSTALL --library=$R_INSTALL_DIR/lib/R/library pbh5.tar.gz

#Test that all R packages can load
echo "TESTING THAT ALL R PACKAGES CAN LOAD"
$R_BIN CMD BATCH $DIR/test_r_packages.R $R_INSTALL_DIR/test_r_packages.stdout

#Make sure 'cairo' is used for bitmap creation instead of 'Xlib' by creating a setting in a .Rprofile file
bash -c 'echo options\(bitmapType = \"cairo\"\) > $R_INSTALL_DIR/etc/.Rprofile'

#Display the result of the final test
cat $R_INSTALL_DIR/test_r_packages.stdout | grep "\[1\]"

