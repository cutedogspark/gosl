#!/bin/bash

set -e

echo "usage:"
echo "    $0 JOB"
echo "where JOB is:"
echo "    0 -- count lines [default]"
echo "    1 -- execute goimports"
echo "    2 -- generate depedency graphs"
echo "    3 -- fix links in README files"

JOB=0
if [[ $# != 0 ]]; then
    JOB=$1
    if [[ $JOB -lt 0 || $JOB -gt 3 ]]; then
        echo
        echo "Job number $1 is invalid"
        echo
        exit 1
    fi
fi

echo "current JOB = $JOB"

if [[ $JOB == 0 ]]; then
    totnfiles=0
    totnlines=0
    for f in `find . -iname "*.go"`; do
        totnfiles=$(($totnfiles+1))
        totnlines=$(($totnlines+`wc -l $f | awk '{print $1}'`))
    done
    echo
    echo "Total number of files = $totnfiles"
    echo "Total number of lines = $totnlines"
    exit 0
fi

ALL="
chk \
io \
utl \
plt \
mpi \
la  \
la/mkl \
la/oblas \
fdm \
num \
fun \
gm \
gm/msh \
gm/tri \
gm/rw \
graph \
ode \
opt \
rnd \
rnd/sfmt \
rnd/dsfmt \
tsr \
vtk \
img \
img/ocv \
"

EXTRA="
examples \
tools \
"

rungoimports() {
    pkg=$1
    for f in *.go; do
        echo $f
        goimports -w $f
    done
}

depgraph(){
    pkg=$1
    fna="/tmp/gosl/depgraph-${pkg/\//_}-A.png"
    fnb="/tmp/gosl/depgraph-${pkg/\//_}-B.svg"
    godepgraph -s github.com/cpmech/gosl/$pkg | dot -Tpng -o $fna
    graphpkg -stdout -match 'gosl' github.com/cpmech/gosl/$pkg > $fnb
    echo "file <$fna> generated"
    echo "file <$fnb> generated"
}

fixreadme() {
    pkg=$1
    old="http://rawgit.com/cpmech/gosl/master/doc/xx${pkg/\//-}.html"
    new="https://godoc.org/github.com/cpmech/gosl/${pkg}"
    sed -i 's,'"$old"','"$new"',' README.md
}

if [[ $JOB == 1 ]]; then
    ALL="$ALL $EXTRA"
fi

if [[ $JOB == 2 ]]; then
    mkdir -p /tmp/gosl
fi

idx=1
for pkg in $ALL; do
    HERE=`pwd`
    cd $pkg
    echo
    echo ">>> $idx $pkg <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
    if [[ $JOB == 1 ]]; then
        rungoimports $pkg
    fi
    if [[ $JOB == 2 ]]; then
        depgraph $pkg
    fi
    if [[ $JOB == 3 ]]; then
        fixreadme $pkg
    fi
    cd $HERE
    (( idx++ ))
done