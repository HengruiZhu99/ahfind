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

if [ -z "${LAPACK_DIR}" ]; then
    echo "BEGIN MESSAGE"
    echo "LAPACK selected, but LAPACK_DIR not set. Checking some places..."
    echo "END MESSAGE"
    
    FILES="liblapack.a liblapack.so"
    DIRS="/usr/lib64 /usr/lib /usr/local/lib64 /usr/local/lib /usr/lib64/atlas /usr/lib/atlas /usr/lib64/atlas-base/atlas /usr/lib/atlas-base/atlas ${HOME}"
    for file in $FILES; do
        for dir in $DIRS; do
            if test -r "$dir/$file"; then
                LAPACK_DIR="$dir"
                break
            fi
        done
    done
    
    if [ -z "$LAPACK_DIR" ]; then
        echo "BEGIN MESSAGE"
        echo "LAPACK not found"
        echo "END MESSAGE"
    else
        echo "BEGIN MESSAGE"
        echo "Found LAPACK in ${LAPACK_DIR}"
        echo "END MESSAGE"
    fi
fi



################################################################################
# Build
################################################################################

if [ -z "${LAPACK_DIR}"                                                 \
     -o "$(echo "${LAPACK_DIR}" | tr '[a-z]' '[A-Z]')" = 'BUILD' ]
then
    echo "BEGIN MESSAGE"
    echo "Using bundled LAPACK..."
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
    THORN=LAPACK
    NAME=lapack-3.9.0
    SRCDIR="$(dirname $0)"
    BUILD_DIR=${SCRATCH_BUILD}/build/${THORN}
    if [ -z "${LAPACK_INSTALL_DIR}" ]; then
        INSTALL_DIR=${SCRATCH_BUILD}/external/${THORN}
    else
        echo "BEGIN MESSAGE"
        echo "Installing LAPACK into ${LAPACK_INSTALL_DIR}"
        echo "END MESSAGE"
        INSTALL_DIR=${LAPACK_INSTALL_DIR}
    fi
    DONE_FILE=${SCRATCH_BUILD}/done/${THORN}
    LAPACK_DIR=${INSTALL_DIR}

    if [ "${F77}" = "none" ]; then
        echo 'BEGIN ERROR'
        echo "Building LAPACK requires a fortran compiler, but there is none configured: F77 = $F77. Aborting."
        echo 'END ERROR'
        exit 1
    fi
    
    if [ -e ${DONE_FILE} -a ${DONE_FILE} -nt ${SRCDIR}/dist/${NAME}.tgz \
                         -a ${DONE_FILE} -nt ${SRCDIR}/configure.sh ]
    then
        echo "BEGIN MESSAGE"
        echo "LAPACK has already been built; doing nothing"
        echo "END MESSAGE"
    else
        echo "BEGIN MESSAGE"
        echo "Building LAPACK"
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
        
        echo "LAPACK: Preparing directory structure..."
        mkdir build external done 2> /dev/null || true
        rm -rf ${BUILD_DIR} ${INSTALL_DIR}
        mkdir ${BUILD_DIR} ${INSTALL_DIR}
        
        echo "LAPACK: Unpacking archive..."
        pushd ${BUILD_DIR}
        ${TAR?} xzf ${SRCDIR}/dist/${NAME}.tgz
        
        echo "LAPACK: Configuring..."
        cd ${NAME}/SRC
        
        echo "LAPACK: Building..."
        #if echo ${F77} | grep -i xlf > /dev/null 2>&1; then
        #    FIXEDF77FLAGS=-qfixed
        #fi
        if ${F77} -qversion 2>/dev/null | grep -q 'IBM XL Fortran'; then
            FIXEDF77FLAGS=-qfixed
        fi
        #${F77} ${F77FLAGS} ${FIXEDF77FLAGS} -c *.f ../INSTALL/dlamch.f ../INSTALL/ilaver.f ../INSTALL/lsame.f ../INSTALL/slamch.f
        #${AR} ${ARFLAGS} liblapack.a *.o
	#if [ ${USE_RANLIB} = 'yes' ]; then
	#    ${RANLIB} ${RANLIBFLAGS} liblapack.a
        #fi
        cat > make.cactus <<EOF
SRCS = $(echo *.f) ../INSTALL/dlamch.f ../INSTALL/ilaver.f ../INSTALL/lsame.f ../INSTALL/slamch.f
liblapack.a: \$(SRCS:%.f=%.o)
	${AR} ${ARFLAGS} \$@ \$^
	${RANLIB} ${RANLIBFLAGS} \$@
%.o: %.f
	${F77} ${F77FLAGS} ${FIXEDF77FLAGS} -c \$*.f -o \$*.o
EOF
        ${MAKE} -f make.cactus
        
        echo "LAPACK: Installing..."
        cp liblapack.a ${LAPACK_DIR}
        popd
        
        echo "LAPACK: Cleaning up..."
        rm -rf ${BUILD_DIR}
        
        date > ${DONE_FILE}
        echo "LAPACK: Done."
        )
        
        if (( $? )); then
            echo 'BEGIN ERROR'
            echo 'Error while building LAPACK. Aborting.'
            echo 'END ERROR'
            exit 1
        fi
    fi
    
fi



################################################################################
# Configure Cactus
################################################################################

# Set options
if [ "${LAPACK_DIR}" != 'NO_BUILD' ]; then
    : ${LAPACK_INC_DIRS=}
    : ${LAPACK_LIB_DIRS="${LAPACK_DIR}"}
fi
: ${LAPACK_LIBS='lapack'}

LAPACK_INC_DIRS="$(${CCTK_HOME}/lib/sbin/strip-incdirs.sh ${LAPACK_INC_DIRS})"
LAPACK_LIB_DIRS="$(${CCTK_HOME}/lib/sbin/strip-libdirs.sh ${LAPACK_LIB_DIRS})"

# Pass options to Cactus
echo "BEGIN MAKE_DEFINITION"
echo "LAPACK_DIR      = ${LAPACK_DIR}"
echo "LAPACK_INC_DIRS = ${LAPACK_INC_DIRS}"
echo "LAPACK_LIB_DIRS = ${LAPACK_LIB_DIRS}"
echo "LAPACK_LIBS     = ${LAPACK_LIBS}"
echo "END MAKE_DEFINITION"

echo 'INCLUDE_DIRECTORY $(LAPACK_INC_DIRS)'
echo 'LIBRARY_DIRECTORY $(LAPACK_LIB_DIRS)'
echo 'LIBRARY           $(LAPACK_LIBS)'
