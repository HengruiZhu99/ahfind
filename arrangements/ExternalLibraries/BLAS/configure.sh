#! /bin/bash

################################################################################
# Prepare
################################################################################

# Set up shell
if [ "$(echo ${VERBOSE} | tr '[:upper:]' '[:lower:]')" = 'yes' ]; then
    set -x                      # Output commands
fi
set -e                          # Abort on errors



################################################################################
# Search
################################################################################

if [ -z "${BLAS_DIR}" ]; then
    echo "BEGIN MESSAGE"
    echo "BLAS selected, but BLAS_DIR not set. Checking some places..."
    echo "END MESSAGE"
    
    FILES="libblas.a libblas.so"
    DIRS="/usr/lib64 /usr/lib /usr/local/lib64 /usr/local/lib /usr/lib64/atlas /usr/lib/atlas /usr/lib64/atlas-base/atlas /usr/lib/atlas-base/atlas ${HOME}"
    for file in $FILES; do
        for dir in $DIRS; do
            if test -r "$dir/$file"; then
                BLAS_DIR="$dir"
                break
            fi
        done
    done
    
    if [ -z "$BLAS_DIR" ]; then
        echo "BEGIN MESSAGE"
        echo "BLAS not found"
        echo "END MESSAGE"
    else
        echo "BEGIN MESSAGE"
        echo "Found BLAS in ${BLAS_DIR}"
        echo "END MESSAGE"
    fi
fi



################################################################################
# Build
################################################################################

if [ -z "${BLAS_DIR}"                                                   \
     -o "$(echo "${BLAS_DIR}" | tr '[a-z]' '[A-Z]')" = 'BUILD' ]
then
    echo "BEGIN MESSAGE"
    echo "Using bundled BLAS..."
    echo "END MESSAGE"
    
    # check for required tools. Do this here so that we don't require them when
    # using the system library
    if [ x$TAR = x ] ; then
      echo 'BEGIN ERROR'
      echo 'Could not find tar command. Please make sure that (gnu) tar is present'
      echo 'and that the TAR variable is set to its location.'
      echo 'END ERROR'
      exit 1
    fi
    #if [ x$PATCH = x ] ; then
    #  echo 'BEGIN ERROR'
    #  echo 'Could not find patch command. Please make sure that (gnu) tar is present'
    #  echo 'and that the PATCH variable is set to its location.'
    #  echo 'END ERROR'
    #  exit 1
    #fi

    # Set locations
    THORN=BLAS
    NAME=blas-3.4.2
    TARNAME=lapack-3.9.0
    SRCDIR="$(dirname $0)"
    BUILD_DIR=${SCRATCH_BUILD}/build/${THORN}
    if [ -z "${BLAS_INSTALL_DIR}" ]; then
        INSTALL_DIR=${SCRATCH_BUILD}/external/${THORN}
    else
        echo "BEGIN MESSAGE"
        echo "Installing BLAS into ${BLAS_INSTALL_DIR}"
        echo "END MESSAGE"
        INSTALL_DIR=${BLAS_INSTALL_DIR}
    fi
    DONE_FILE=${SCRATCH_BUILD}/done/${THORN}
    BLAS_DIR=${INSTALL_DIR}
    
    if [ "${F77}" = "none" ]; then
        echo 'BEGIN ERROR'
        echo "Building BLAS requires a Fortran compiler, but there is none configured: F77='${F77}'. Aborting."
        echo 'END ERROR'
        exit 1
    fi

    if [ -e ${DONE_FILE} -a ${DONE_FILE} -nt ${SRCDIR}/dist/${TARNAME}.tgz \
                         -a ${DONE_FILE} -nt ${SRCDIR}/configure.sh ]
    then
        echo "BEGIN MESSAGE"
        echo "BLAS has already been built; doing nothing"
        echo "END MESSAGE"
    else
        echo "BEGIN MESSAGE"
        echo "Building BLAS"
        echo "END MESSAGE"
        
        # Build in a subshell
        (
        exec >&2                # Redirect stdout to stderr
        if [ "$(echo ${VERBOSE} | tr '[:upper:]' '[:lower:]')" = 'yes' ]; then
            set -x              # Output commands
        fi
        set -e                  # Abort on errors
        cd ${SCRATCH_BUILD}
        
        # Set up environment
        unset LIBS
	if [ ${USE_RANLIB} != 'yes' ]; then
            RANLIB=': ranlib'
        fi
        
        echo "BLAS: Preparing directory structure..."
        mkdir build external done 2> /dev/null || true
        rm -rf ${BUILD_DIR} ${INSTALL_DIR}
        mkdir ${BUILD_DIR} ${INSTALL_DIR}
        
        echo "BLAS: Unpacking archive..."
        pushd ${BUILD_DIR}
        ${TAR?} xzf ${SRCDIR}/dist/${TARNAME}.tgz
        
        echo "BLAS: Configuring..."
        cd ${TARNAME}/BLAS/SRC
        
        echo "BLAS: Building..."
        #if echo ${F77} | grep -i xlf > /dev/null 2>&1; then
        #    FIXEDF77FLAGS=-qfixed
        #fi
        if ${F77} -qversion 2>/dev/null | grep -q 'IBM XL Fortran'; then
            FIXEDF77FLAGS=-qfixed
        fi
        #${F77} ${F77FLAGS} ${FIXEDF77FLAGS} -c *.f
        #${AR} ${ARFLAGS} libblas.a *.o
	#if [ ${USE_RANLIB} = 'yes' ]; then
	#    ${RANLIB} ${RANLIBFLAGS} libblas.a
        #fi
        cat > make.cactus <<EOF
SRCS = $(echo *.f)
libblas.a: \$(SRCS:%.f=%.o)
	${AR} ${ARFLAGS} \$@ \$^
	${RANLIB} ${RANLIBFLAGS} \$@
%.o: %.f
	${F77} ${F77FLAGS} ${FIXEDF77FLAGS} -c \$*.f -o \$*.o
EOF
        ${MAKE} -f make.cactus
        
        echo "BLAS: Installing..."
        cp libblas.a ${BLAS_DIR}
        popd
        
        echo "BLAS: Cleaning up..."
        rm -rf ${BUILD_DIR}
        
        date > ${DONE_FILE}
        echo "BLAS: Done."
        )
        if (( $? )); then
            echo 'BEGIN ERROR'
            echo 'Error while building BLAS. Aborting.'
            echo 'END ERROR'
            exit 1
        fi
    fi
    
fi



################################################################################
# Configure Cactus
################################################################################

# Set options
if [ "${BLAS_DIR}" != 'NO_BUILD' ]; then
    : ${BLAS_INC_DIRS=}
    : ${BLAS_LIB_DIRS="${BLAS_DIR}"}
fi
: ${BLAS_LIBS='blas'}

BLAS_INC_DIRS="$(${CCTK_HOME}/lib/sbin/strip-incdirs.sh ${BLAS_INC_DIRS})"
BLAS_LIB_DIRS="$(${CCTK_HOME}/lib/sbin/strip-libdirs.sh ${BLAS_LIB_DIRS})"

# Pass options to Cactus
echo "BEGIN MAKE_DEFINITION"
echo "BLAS_DIR      = ${BLAS_DIR}"
echo "BLAS_INC_DIRS = ${BLAS_INC_DIRS}"
echo "BLAS_LIB_DIRS = ${BLAS_LIB_DIRS}"
echo "BLAS_LIBS     = ${BLAS_LIBS}"
echo "END MAKE_DEFINITION"

echo 'INCLUDE_DIRECTORY $(BLAS_INC_DIRS)'
echo 'LIBRARY_DIRECTORY $(BLAS_LIB_DIRS)'
echo 'LIBRARY           $(BLAS_LIBS)'
