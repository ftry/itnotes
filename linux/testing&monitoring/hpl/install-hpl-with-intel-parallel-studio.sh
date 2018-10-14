#!/bin/sh
ver=2.2
hplpkg=hpl-${ver}.tar.gz

installpath=$HOME/hpl
makefile=Make.Linux_Intel64 

intelparallelstudio=/share/apps/intel-parallel-studio

# extract
tar xzvf $hplpkg

# copy Make configuration file
mv hpl-${ver} $installpath
cd $installpath/
cp setup/$makefile $installpath/

# edit Make configuration file
#TOPdir
#sed -i "1i HOME=$HOME" ./${makefile}

#intel parallel stuido path
sed -i "s/intelpath/$intelparallelstudio" ${makefile} 


#intel parallel stuido path
#sed -i "/#[\s]MPdir/i MPdir=$intelparallelstudio/impi/$(ls $impi) \n MPinc=-I$(MPdir)/include64 \n MPlib=$(MPdir)/intel64/lib/libmpi_mt.so" ${makefile}

#sed -i "/^LAdir/i MKLROOT=$intelparallelstudio/mkl"

# compile hpl
cd $installpath
make arch=Linux_Intel64

# add to PATH
export PATH=$PATH:$installpath/bin/intel64

echo "done"
echo "hpl -- ${installpath}"
