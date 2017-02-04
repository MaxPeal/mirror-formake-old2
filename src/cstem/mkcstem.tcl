#!/bin/sh
#
# Author: Oleksiy Chernyavskyy <ochern@rocketmail.com>
#
#\
exec tclsh "$0" ${1+"$@"}

set cc_config "cstem"
set cxx_config "cstem+"

set fid_src [open $argv0 r]
set fid_cc_config [open $cc_config w 0750]
set fid_cxx_config [open $cxx_config w 0750]

set script_start 0
set cc_block 1
set cx_block 1

while {[gets $fid_src line] >= 0} {
  if {$script_start != 2} {
    if {[string match "*CC_CONFIG_START*" $line] == 1} {
      incr script_start
    }
  } else {
    set cc_line 1
    set cx_line 1
    if {[string match "*CC_LINE*" $line] == 1} {
      set cx_line 0
      regsub -all {\s*#*CC_LINE} $line "" line
    } elseif {[string match "*CX_LINE*" $line] == 1} {
      set cc_line 0
      regsub -all {\s*#*CX_LINE} $line "" line
    }

    if {[string match "*CC_BLOCK_START*" $line] == 1} {
      set cc_block 1
      set cx_block 0
    } elseif {[string match "*CX_BLOCK_START*" $line] == 1} {
      set cc_block 0
      set cx_block 1
    } elseif {[string match "*BLOCK_END*" $line] == 1} {
      set cc_block 1
      set cx_block 1
    } else {
      set cxx_line $line
      if {$cc_block == 1 && $cc_line == 1} {
        regsub -all %C% $line C line
        puts $fid_cc_config $line
      }
      if {$cx_block == 1 && $cx_line == 1} {
        regsub -all %C% $cxx_line C++ cxx_line
        puts $fid_cxx_config $cxx_line
      }
    }
  }
}

close $fid_src
close $fid_cc_config
close $fid_cxx_config
exit 0


# CC_CONFIG_START
#!/bin/sh
#
# Author: Oleksiy Chernyavskyy <ochern@rocketmail.com>
#

abs_path() {
  _sub_orig_dir=`pwd`
  if test $# = 0; then
    abs_path_ret=
    return
  fi
  if test $# = 2; then
    _arg_orig_dir=$1
    _arg=$2
    if echo -n "$_arg" | grep "^/" > /dev/null; then
      :
    else
      _arg=`echo -n "$_arg_orig_dir/$_arg" | sed 's!//*!/!g'`
    fi
  else
    _arg=$1
  fi
  if test -e "$_arg"; then
    if test -d $_arg; then
      _file=
    else
      _file=`basename -- $_arg`
      _arg=`dirname -- $_arg`
    fi

    cd $_cd_param $_arg
    abs_path_ret=`pwd`
    if test x"$_file" != "x"; then
      abs_path_ret="$abs_path_ret/$_file"
    fi

    cd $_cd_param $_sub_orig_dir
  else
    if echo -n "$_arg" | grep "^/" > /dev/null; then
      abs_path_ret="$_arg"
    else
      abs_path_ret="$_sub_orig_dir/$_arg"
    fi
    abs_path_ret=`echo -n "$abs_path_ret" | sed 's#//*#/#g'`
    abs_path_ret=`echo -n "$abs_path_ret" | sed 's#/*$#/#'`
    string_prev=
    while test "x$abs_path_ret" != "x$string_prev" ; do
      string_prev=$abs_path_ret
      abs_path_ret=`echo -n "$abs_path_ret" | sed 's#/[^/][^/][^/][^/]*/\.\./#/#g' | sed 's#/[^/][^/.]/\.\./#/#g' | sed 's#/[^/.][^/]/\.\./#/#g' | sed 's#/[^/.]/\.\./#/#g'`
      abs_path_ret=`echo -n "$abs_path_ret" | sed 's#^/\.\./#/#' | sed 's#^/\.\.$#/#'`
      abs_path_ret=`echo -n "$abs_path_ret" | sed 's#/\./#/#g' | sed 's#/\.$#/#'`
    done
    abs_path_ret=`echo -n "$abs_path_ret" | sed 's#/$##' | sed 's#^$#/#'`
  fi
}

script_name=`basename $0`
orig_dir=`pwd`
abs_path $0
script_abs=$abs_path_ret
script_dir=`dirname $script_abs`
out_format=1
########## CC_BLOCK_START
config_file="$script_dir/cstem.conf"
########## CX_BLOCK_START
config_file="$script_dir/cstem+.conf"
########## BLOCK_END

################################################################################
# LOAD CONFIG
PATH=$FORMAKE:$PATH
########## CC_BLOCK_START
CSTEM=
########## CX_BLOCK_START
CSTEMX=
########## BLOCK_END
if test -f $script_dir/config.rc; then
  . $script_dir/config.rc
fi
########## CC_BLOCK_START
test -n "$FORMAKE_CSTEM" && CSTEM=$FORMAKE_CSTEM
if test -n "$CSTEM" && test -z "$CSTEM_REDIRECT"; then
  export CSTEM_REDIRECT=1
  $CSTEM "$@"
########## CX_BLOCK_START
test -n "$FORMAKE_CSTEMX" && CSTEMX=$FORMAKE_CSTEMX
if test -n "$CSTEMX" && test -z "$CSTEMX_REDIRECT"; then
  export CSTEMX_REDIRECT=1
  $CSTEMX "$@"
########## BLOCK_END
  ret=$?
  if test $ret -ne 64; then
    exit $ret
  fi
fi
################################################################################

syscap -h >/dev/null 2>&1
if test $? -ne 127; then
  SYSCAP=syscap
elif test -f $script_dir/syscap; then
  SYSCAP=$script_dir/syscap
fi

config_list="
cmd
cflags
id
version
std
os
os_version
kernel
arch
bitness
endianess
data_model
"

print_help() {
cat <<EOF
Configure and probe %C% compiler

$script_name [options]
$script_name config [-cc CMD] [-cflags=FLAGS]
$script_name probe [-cc CMD] [-cflags=FLAGS] [-f1|-f2|-f3]

By default $script_name prints information about configured compiler
 -id            get compiler id
 -ver           get compiler version
 -cmd           get compiler command
 -cflags        get compiler flags
 -std           get %C% language standard
 -os            get target OS
 -osver         get target OS version
 -kernel        get target kernel
 -arch          get target architecture
 -bits          get target bitness
 -endian        get target endianess
 -dm            get target data model


Config mode. Probe compiler and generate config file
 -cc CMD        specify compiler command with optional flags
 -cflags=FLAGS  specify compiler flags

Probe mode. Probe compiler and print information to a standard output
 -cc CMD        specify compiler command with optional flags
 -cflags=FLAGS  specify compiler flags
 -f1            print in format 1> VAR="VALUE"
 -f2            print in format 2> FIELD: VALUE
 -f3            print in format 3> VALUE
EOF
}

check_cc() {
  cc_is_ok=

  $cc_cmd >/dev/null 2>&1
  if test $? -eq 127; then
    return
  fi

  cc_cmd_base=`basename $cc_cmd`
  case $cc_cmd_base in
    gcc*|g++*)
      CPP_FLAG=-E
      ;;
    *)
      CPP_FLAG=-E
      ;;
  esac

  test_dir=/tmp/cc_config_data_$$
  rm -rf $test_dir
  mkdir $test_dir
  cd $test_dir

  test_h="cc_test.h"
  cat >$test_h <<EOF
#define MY_DEFINE 1
#ifdef MY_DEFINE
  #define CPP_OK
#endif
EOF
  $cc_cmd $probe_cc_flags $CPP_FLAG $test_h >/dev/null 2>&1
  ret_code=$?
  rm -f $test_h
  if test $ret_code -ne 0; then
    return
  fi

########## CC_BLOCK_START
  test_src="test.c"
  cat > $test_src <<EOF
int main(int argc, char** argv)
{
  return 0;
}
EOF
########## CX_BLOCK_START
  test_src="test.cpp"
  cat > $test_src <<EOF
class test_class
{
  public:
    int i;
};

int main(int argc, char** argv)
{
  test_class t;
  return 0;
}
EOF
########## BLOCK_END

  if $cc_cmd $probe_cc_flags -c $test_src >/dev/null 2>&1; then
    cc_is_ok=1
  fi

  rm -rf $test_dir
  cd $orig_dir
}

read_cc_props() {
########## CC_BLOCK_START
  probe_h="/tmp/cc_config_$$.h"
########## CX_BLOCK_START
  probe_h="/tmp/cc_config_$$.H"
########## BLOCK_END
  cat $script_abs | grep -A 10000 "/\* *COMPILER DEFINES *\*/" | grep -v "^EOF" > $probe_h
  probe_h_out="/tmp/cc_config_$$_out"
  $cc_cmd $probe_cc_flags $CPP_FLAG $probe_h 2>/dev/null > $probe_h_out
  probe_sh="/tmp/cc_config_$$.sh"
  cat $probe_h_out | grep "^D[SV][EA][TL]" | sed 's/=\(.*\)$/="\1"/' > $probe_sh
  . $probe_sh
  rm -f $probe_sh
  rm -f $probe_h_out
  rm -f $probe_h

########## CC_BLOCK_START
  if test -n "$DSET__STDC__"; then
    config_std=c89
  fi

  if test -n "$DSET__STDC_VERSION__"; then
    std_version=`echo "$DVAL__STDC_VERSION__" | sed 's/[a-zA-Z_]//g'`
    if test "$std_version" -ge 201112; then
      config_std=c11
    elif test "$std_version" -ge 199901; then
      config_std=c99
    elif test "$std_version" -ge 199409; then
      config_std=c95
    else
      config_std=c89
    fi
  fi
########## CX_BLOCK_START
  if test -n "$DSET_cplusplus_cli"; then
    config_std=cxx_cli
  elif test -n "$DSET__embedded_cplusplus"; then
    config_std=embedded_cxx
  elif test -n "$DSET__cplusplus"; then
    std_version=`echo "$DVAL__cplusplus" | sed 's/[a-zA-Z_]//g'`
    if test "$std_version" -ge 201402; then
      config_std=cxx14
    elif test "$std_version" -ge 201103; then
      config_std=cxx11
    elif test "$std_version" -ge 199711; then
      config_std=cxx98
    fi
  fi
########## BLOCK_END

########## CC_BLOCK_START
  if test -n "$DSET__CMB__"; then
    config_id=altium_cmb

    if test -n "$DVAL__VERSION__"; then
      config_vmajor=`expr "0$DVAL__VERSION__" / 1000`
      config_vminor=`expr "0$DVAL__VERSION__" % 1000`
    fi
    if test -n "$DVAL__REVISION__"; then
      config_vrevision=`expr "0$DVAL__REVISION__" + 0`
    fi
  fi

  if test -n "$DSET__CHC__"; then
    config_id=altium_chc

    if test -n "$DVAL__VERSION__"; then
      config_vmajor=`expr "0$DVAL__VERSION__" / 1000`
      config_vminor=`expr "0$DVAL__VERSION__" % 1000`
    fi
    if test -n "$DVAL__REVISION__"; then
      config_vrevision=`expr "0$DVAL__REVISION__" + 0`
    fi
  fi

  if test -n "$DSET__ACK__"; then
    config_id=ack
  fi
########## BLOCK_END

  if test -n "$DSET__CC_ARM"; then
    config_id=armc

    if test -n "$DVAL__ARMCC_VERSION"; then
      config_vmajor=`expr "0$DVAL__ARMCC_VERSION" / 100000`
      tbuf=`expr "0$DVAL__ARMCC_VERSION" % 100000`
      config_vminor=`expr "0$tbuf" / 10000`
      tbuf=`expr "0$DVAL__ARMCC_VERSION" % 10000`
      config_vrevision=`expr "0$tbuf" / 1000`
    fi
  fi

  if test -n "$DSET__BORLANDC__" || test -n "$DSET__CODEGEARC__"; then
    config_id=borlandc
  fi

  if test -n "$DSET__clang__"; then
    config_id=clang

    config_vmajor=$DVAL__clang_major__
    config_vminor=$DVAL__clang_minor__
    config_vrevision=$DVAL__clang_patchlevel__
  fi

  if test -n "$DSET__COMO__"; then
    config_id=comeau

    if test -n "$DVAL__COMO_VERSION__"; then
      config_vmajor=`expr "0$DVAL__COMO_VERSION__" / 100`
      config_vminor=`expr "0$DVAL__COMO_VERSION__" % 100`
    fi
  fi

########## CC_BLOCK_START
  if test -n "$DSET__COMPCERT__"; then
    config_id=compcert
  fi
########## BLOCK_END

  if test -n "$DSET__DCC__"; then
    config_id=diabc

    if test -n "$DVAL__VERSION_NUMBER__"; then
      config_vmajor=`echo "$DVAL__VERSION_NUMBER__" | sed 's/^\(.\).*/\1/g'`
      config_vminor=`echo "$DVAL__VERSION_NUMBER__" | sed 's/^.\(.\).*/\1/g'`
      config_vrevision=`echo "$DVAL__VERSION_NUMBER__" | sed 's/^..\(..\).*/\1/g'`
    fi
  fi

  if test -n "$DSET__DMC__"; then
    config_id=dmc

    if test -n "$DVAL__DMC__"; then
      tbuf=`echo "$DVAL__DMC__" | sed 's/0[xX]\(.\).*/\1/g'`
      config_vmajor=`printf "%d" "0x$tbuf"`
      tbuf=`echo "$DVAL__DMC__" | sed 's/0[xX].\(.\).*/\1/g'`
      config_vminor=`printf "%d" "0x$tbuf"`
      tbuf=`echo "$DVAL__DMC__" | sed 's/0[xX]..\(.\).*/\1/g'`
      config_vrevision=`printf "%d" "0x$tbuf"`
    fi
  fi

  if test -n "$DSET__SYSC__"; then
    config_id=dignus

    if test -n "$DVAL__SYSC_VER__"; then
      config_vmajor=`expr "0$DVAL__SYSC_VER__" / 10000`
      buf=`expr "0$DVAL__SYSC_VER__" % 10000`
      config_vminor=`expr "0$buf" / 100`
      config_vrevision=`expr "0$DVAL__SYSC_VER__" % 100`
    fi
  fi

  if test -n "$DSET__EDG__"; then
    config_id=edg

    if test -n "$DVAL__EDG_VERSION__"; then
      config_vmajor=`expr "0$DVAL__EDG_VERSION__" / 100`
      config_vminor=`expr "0$DVAL__EDG_VERSION__" % 100`
    fi
  fi

  if test -n "$DSET__PATHCC__"; then
    config_id=ekopath

    config_vmajor=$DVAL__PATHCC__
    config_vminor=$DVAL__PATHCC_MINOR__
    config_vrevision=$DVAL__PATHCC_PATCHLEVEL__
  fi

  if test -n "$DSET__ghs__"; then
    config_id=ghs

    if test -n "$DVAL__GHS_VERSION_NUMBER__"; then
      config_vmajor=`expr "0$DVAL__GHS_VERSION_NUMBER__" / 100`
      tbuf=`expr "0$DVAL__GHS_VERSION_NUMBER__" % 100`
      config_vminor=`expr "0$tbuf" / 10`
      config_vrevision=`expr "0$DVAL__GHS_VERSION_NUMBER__" % 10`
    fi
  fi

########## CC_BLOCK_START
  if test -n "$DSET__HP_cc"; then
    config_id=hpansic
  fi
########## CX_BLOCK_START
  if test -n "$DSET__HP_aCC"; then
    config_id=hpacc

    if test -n "$DVAL__HP_aCC"; then
      if test "x$DVAL__HP_aCC" = "x1"; then
        config_vmajor=1
      else
        config_vmajor=`expr "0$DVAL__HP_aCC" / 10000`
        tbuf=`expr "0$DVAL__HP_aCC" % 10000`
        config_vminor=`expr "0$tbuf" / 100`
        config_vrevision=`expr "0$DVAL__HP_aCC" % 100`
      fi
    fi
  fi
########## BLOCK_END

  if test -n "$DSET__IAR_SYSTEMS_ICC__"; then
    config_id=iar

    if test -n "$DVAL__VER__"; then
      config_vmajor=`expr "0$DVAL__VER__" / 100`
      config_vminor=`expr "0$DVAL__VER__" % 100`
    fi
  fi

  if test -n "$DSET__IBMC__" || test -n "$DVAL__IBMCPP__"; then
    config_id=xlc

    if test -n "$DSET__COMPILER_VER__"; then
      tbuf=`echo "$DVAL__COMPILER_VER__" | sed 's/0[xX].\(.\).*/\1/g'`
      config_vmajor=`printf "%d" "0x$tbuf"`
      tbuf=`echo "$DVAL__COMPILER_VER__" | sed 's/0[xX]..\(..\).*/\1/g'`
      config_vminor=`printf "%d" "0x$tbuf"`
      tbuf=`echo "$DVAL__COMPILER_VER__" | sed 's/0[xX]....\(....\).*/\1/g'`
      config_vrevision=`printf "%d" "0x$tbuf"`
    elif test -n "$DVAL__xlc__"; then
      tbuf=`echo "0${DVAL__xlc__}" | sed 's/^\([0-9]*\).*/\1/g'`
      config_vmajor=`expr "0$tbuf" + 0`
      tbuf=`echo "0${DVAL__xlc__}." | sed 's/^[^\.]*\.\([0-9]*\).*/\1/g'`
      config_vminor=`expr "0$tbuf" + 0`
      tbuf=`echo "0${DVAL__xlc__}.." | sed 's/^[^\.]*\.[^\.]*\.\([0-9]*\).*/\1/g'`
      config_vrevision=`expr "0$tbuf" + 0`
    elif test -n "$DVAL__IBMC__"; then
      config_vmajor=`expr "0$DVAL__IBMC__" / 100`
      tbuf=`expr "0$DVAL__IBMC__" % 100`
      config_vminor=`expr "0$tbuf" / 10`
      config_vrevision=`expr "0$DVAL__IBMC__" % 10`
    elif test -n "$DVAL__xlC__"; then
      tbuf=`echo "$DVAL__xlC__" | sed 's/0[xX]\(..\).*/\1/g'`
      config_vmajor=`printf "%d" "0x$tbuf"`
      tbuf=`echo "$DVAL__xlC__" | sed 's/0[xX]..\(..\).*/\1/g'`
      config_vminor=`printf "%d" "0x$tbuf"`
    elif test -n "$DVAL__IBMCPP__"; then
      config_vmajor=`expr "0$DVAL__IBMCPP__" / 100`
      tbuf=`expr "0$DVAL__IBMCPP__" % 100`
      config_vminor=`expr "0$tbuf" / 10`
      config_vrevision=`expr "0$DVAL__IBMCPP__" % 10`
    fi
  fi

########## CC_BLOCK_START
  if test -n "$DSET__IMAGECRAFT__"; then
    config_id=imagecraft
  fi
########## BLOCK_END

  if test -n "$DSET__INTEL_COMPILER" || test -n "$DSET__ICC" || test -n "$DSET__ECC" || test -n "$DSET__ICL"; then
    config_id=intel

    if test -n "$DVAL__INTEL_COMPILER"; then
      config_vmajor=`expr "0$DVAL__INTEL_COMPILER" / 100`
      tbuf=`expr "0$DVAL__INTEL_COMPILER" % 100`
      config_vminor=`expr "0$tbuf" / 10`
      config_vrevision=`expr "0$DVAL__INTEL_COMPILER" % 10`
    fi
  fi

########## CC_BLOCK_START
  if test -n "$DSET__C166__"; then
    config_id=c166

    if test -n "$DVAL__C166__"; then
      config_vmajor=`expr "0$DVAL__C166__" / 100`
      config_vminor=`expr "0$DVAL__C166__" % 100`
    fi
  fi

  if test -n "$DSET__C51__" || test -n "$DSET__CX51__"; then
    config_id=c51

    if test -n "$DVAL__C51__"; then
      config_vmajor=`expr "0$DVAL__C51__" / 100`
      config_vminor=`expr "0$DVAL__C51__" % 100`
    elif test -n "$DVAL__CX51__"; then
      config_vmajor=`expr "0$DVAL__CX51__" / 100`
      config_vminor=`expr "0$DVAL__CX51__" % 100`
    fi
  fi

  if test -n "$DSET__LCC__"; then
    config_id=lcc
  fi
########## BLOCK_END

  if test -n "$DSET__HIGHC__"; then
    config_id=metaware
  fi

  if test -n "$DSET__MWERKS__" || test -n "$DSET__CWCC__"; then
    config_id=codewarrior

    if test -n "$DVAL__CWCC__"; then
      tbuf=`echo "$DVAL__CWCC__" | sed 's/0[xX]\(.\).*/\1/g'`
      config_vmajor=`printf "%d" "0x$tbuf"`
      tbuf=`echo "$DVAL__CWCC__" | sed 's/0[xX].\(.\).*/\1/g'`
      config_vminor=`printf "%d" "0x$tbuf"`
      tbuf=`echo "$DVAL__CWCC__" | sed 's/0[xX]..\(..\).*/\1/g'`
      config_vrevision=`printf "%d" "0x$tbuf"`
    elif test -n "$DVAL__MWERKS__"; then
      if test "x$DVAL__MWERKS__" != "x1"; then
        tbuf=`echo "$DVAL__MWERKS__" | sed 's/0[xX]\(.\).*/\1/g'`
        config_vmajor=`printf "%d" "0x$tbuf"`
        tbuf=`echo "$DVAL__MWERKS__" | sed 's/0[xX].\(.\).*/\1/g'`
        config_vminor=`printf "%d" "0x$tbuf"`
        tbuf=`echo "$DVAL__MWERKS__" | sed 's/0[xX]..\(..\).*/\1/g'`
        config_vrevision=`printf "%d" "0x$tbuf"`
      fi
    fi
  fi

  if test -n "$DSET_MSC_VER"; then
    config_id=msc

    if test -n "$DVAL_MSC_VER"; then
      config_vmajor=`expr "0$DVAL_MSC_VER" / 100`
      config_vminor=`expr "0$DVAL_MSC_VER" % 100`
    fi
  fi

  if test -n "$DSET_MRI"; then
    config_id=mri
  fi

  if test -n "$DSET__MINGW32__"; then
    if test -n "$DSET__MINGW64_VERSION_MAJOR"; then
      config_id=mingw64
      config_vmajor=$DVAL__MINGW64_VERSION_MAJOR
      config_vminor=$DVAL__MINGW64_VERSION_MINOR

      if test -n "$DSET__MINGW64__"; then
        config_bitness=64
      else
        config_bitness=32
      fi
    else
      config_id=mingw
      config_vmajor=$DVAL__MINGW32_MAJOR_VERSION
      config_vminor=$DVAL__MINGW32_MINOR_VERSION
    fi
  fi

  if test -n "$DSET__sgi" || test -n "$DSETsgi"; then
    config_id=mipspro

    version_string=${DVAL_SGI_COMPILER_VERSION:-"$DVAL_COMPILER_VERSION"}
    if test -n "$version_string"; then
      config_vmajor=`expr "0$version_string" / 100`
      tbuf=`expr "0$version_string" % 100`
      config_vminor=`expr "0$tbuf" / 10`
      config_vrevision=`expr "0$version_string" % 10`
    fi
  fi

  if test -n "$DSET__OPEN64__" || test -n "$DSET__OPENCC__"; then
    config_id=open64

    config_vmajor=`expr "0$DVAL__OPENCC__" + 0`
    config_vminor=`expr "0$DVAL__OPENCC_MINOR__" + 0`
    if test -n "$DVAL__OPENCC_PATCHLEVEL__"; then
      tbuf=`echo "${DVAL__OPENCC_PATCHLEVEL__}." | sed 's/^\([^.]*\)\..*/\1/g'`
      config_vrevision=`expr "0$tbuf" + 0`
    fi
  fi

  if test -n "$DSET__SUNPRO_C" || test -n "$DSET__SUNPRO_CC"; then
    config_id=sunpro

    version_string=${DVAL__SUNPRO_C:-"$DVAL__SUNPRO_CC"}

    if test -n "$version_string"; then
      tbuf=`echo "$version_string" | sed 's/0[xX]\(.\).*/\1/g'`
      config_vmajor=`expr "0$tbuf" + 0`
      nchars=`echo -n "$version_string" | wc -c`
      if test "$nchars" -gt 5; then
        tbuf=`echo "$version_string" | sed 's/0[xX].\(..\).*/\1/g'`
        config_vminor=`expr "0$tbuf" + 0`
        tbuf=`echo "$version_string" | sed 's/0[xX]...\(.\).*/\1/g'`
        config_vrevision=`expr "0$tbuf" + 0`
      else
        tbuf=`echo "$version_string" | sed 's/0[xX].\(.\).*/\1/g'`
        config_vminor=`expr "0$tbuf" + 0`
        tbuf=`echo "$version_string" | sed 's/0[xX]..\(.\).*/\1/g'`
        config_vrevision=`expr "0$tbuf" + 0`
      fi
    fi
  fi

########## CC_BLOCK_START
  if test -n "$DSET__POCC__"; then
    config_id=pelles

    if test -n "$DVAL__POCC__"; then
      config_vmajor=`expr "0$DVAL__POCC__" / 100`
      config_vminor=`expr "0$DVAL__POCC__" % 100`
    fi
  fi
########## BLOCK_END

  if test -n "$DSET__PGI"; then
    config_id=pgi

    config_vmajor=$DVAL__PGIC__
    config_vminor=$DVAL__PGIC_MINOR__
    config_vrevision=$DVAL__PGIC_PATCHLEVEL__
  fi

  if test -n "$DSET__RENESAS__" || test -n "$DSET__HITACHI__"; then
    config_id=renesas

    version_string=${DVAL__RENESAS_VERSION__:-"$DVAL__HITACHI_VERSION__"}

    if test -n "$version_string"; then
      tbuf=`echo "$version_string" | sed 's/0[xX]\(..\).*/\1/g'`
      config_vmajor=`printf "%d" "0x$tbuf"`
      tbuf=`echo "$version_string" | sed 's/0[xX]..\(..\).*/\1/g'`
      config_vminor=`printf "%d" "0x$tbuf"`
      nchars=`echo -n "$version_string" | wc -c`
      if test "$nchars" -gt 6; then
        tbuf=`echo "$version_string" | sed 's/0[xX]....\(..\).*/\1/g'`
        config_vrevision=`printf "%d" "0x$tbuf"`
      fi
    fi
  fi

########## CC_BLOCK_START
  if test -n "$DSETSDCC"; then
    config_id=sdcc

    if test -n "$DVALSDCC"; then
      config_vmajor=`expr "0$DVALSDCC" / 100`
      tbuf=`expr "0$DVALSDCC" % 100`
      config_vminor=`expr "0$tbuf" / 10`
      config_vrevision=`expr "0$DVALSDCC" % 10`
    fi
  fi
########## BLOCK_END

  if test -n "$DSET__SNC__"; then
    config_id=snc
  fi

########## CC_BLOCK_START
  if test -n "$DSET__VOSC__"; then
    config_id=vosc
  fi
########## BLOCK_END

  if test -n "$DSET__TenDRA__"; then
    config_id=tendra
  fi

  if test -n "$DSET__TI_COMPILER_VERSION__"; then
    config_id=ticc

    if test -n "$DVAL__TI_COMPILER_VERSION__"; then
      config_vmajor=`expr "0$DVAL__TI_COMPILER_VERSION__" / 1000000`
      tbuf=`expr "0$DVAL__TI_COMPILER_VERSION__" % 1000000`
      config_vminor=`expr "0$tbuf" / 1000`
      config_vrevision=`expr "0$DVAL__TI_COMPILER_VERSION__" % 1000`
    fi
  fi

########## CC_BLOCK_START
  if test -n "$DSET__TINYC__"; then
    config_id=tinyc
  fi

  if test -n "$DSET__VBCC__"; then
    config_id=vbcc
  fi
########## BLOCK_END

  if test -n "$DSET__WATCOMC__"; then
    config_id=watcom

    if test -n "$DVAL__WATCOMC__"; then
      config_vmajor=`expr "0$DVAL__WATCOMC__" / 100`
      config_vminor=`expr "0$DVAL__WATCOMC__" % 100`
    fi
  fi

  if test -n "$DSET__GNUC__" && test -z "$config_id"; then
    config_id=gcc

    if test -n "$DVAL__GNUC_VERSION__"; then
      config_vmajor=`expr "0$DVAL__GNUC_VERSION__" / 10000`
      tbuf=`expr "0$DVAL__GNUC_VERSION__" % 10000`
      config_vminor=`expr "0$tbuf" / 100`
      config_vrevision=`expr "0$DVAL__GNUC_VERSION__" % 100`
    else
      config_vmajor=$DVAL__GNUC__
      config_vminor=$DVAL__GNUC_MINOR__
      config_vrevision=$DVAL__GNUC_PATCHLEVEL__
    fi
  fi

  if test -n "$DSET_AIX" || test -n "$DSET__TOS_AIX__"; then
    config_os=aix

    if test -n "$DSET_AIX3"; then
      config_os_vmajor=3
    fi
    if test -n "$DSET_AIX31"; then
      config_os_vmajor=3
    fi
    if test -n "$DSET_AIX4"; then
      config_os_vmajor=4
    fi
    if test -n "$DSET_AIX41"; then
      config_os_vmajor=4
    fi
    if test -n "$DSET_AIX5"; then
      config_os_vmajor=5
    fi
    if test -n "$DSET_AIX51"; then
      config_os_vmajor=5
    fi
    if test -n "$DSET_AIX6"; then
      config_os_vmajor=6
    fi
    if test -n "$DSET_AIX61"; then
      config_os_vmajor=6
    fi
    if test -n "$DSET_AIX7"; then
      config_os_vmajor=7
    fi
    if test -n "$DSET_AIX71"; then
      config_os_vmajor=7
    fi
    if test -n "$DSET_AIX8"; then
      config_os_vmajor=8
    fi
    if test -n "$DSET_AIX81"; then
      config_os_vmajor=8
    fi
    if test -n "$DSET_AIX9"; then
      config_os_vmajor=9
    fi
    if test -n "$DSET_AIX91"; then
      config_os_vmajor=9
    fi
  fi

  if test -n "$DSET__ANDROID__"; then
    config_os=android
    config_os_vmajor=$DVAL__ANDROID_API__
  fi

  if test -n "$DSETAMIGA" || test -n "$DSET__amigaos__"; then
    config_os=amigaos
  fi

  if test -n "$DSET__FreeBSD__"; then
    config_os=freebsd
    config_os_vmajor=$DVAL__FreeBSD__
  fi

  if test -n "$DSET__FreeBSD_kernel__"; then
    config_kernel=freebsd
  fi

  if test -n "$DSET__NetBSD__"; then
    config_os=netbsd
  fi

  if test -n "$DSET__OpenBSD__"; then
    config_os=openbsd
  fi

  if test -n "$DSET__DragonFly__"; then
    config_os=dragonfly
  fi

  if test -n "$DSET__CYGWIN__"; then
    config_os=cygwin
  fi

  if test -n "$DSET__ECOS"; then
    config_os=ecos
  fi

  if test -n "$DSET__gnu_hurd__"; then
    config_os=gnuhurd
  fi

  if test -n "$DSET__gnu_linux__" || test -n "$DSET__gnu_linux"; then
    config_os=gnulinux
    config_kernel=linux
  fi

  if test -n "$DSET__linux__" || test -n "$DSETlinux" || test -n "$DSET__linux"; then
    config_kernel=linux
  fi

  if test -n "$DSET_hpux" || test -n "$DSEThpux" || test -n "$DSET__hpux"; then
    config_os=hpux
  fi

  if test -n "$DSET__INTEGRITY"; then
    config_os=integrity
  fi

  if test -n "$DSET__INTERIX"; then
    config_os=interix
  fi

  if test -n "$DSETsgi" || test -n "$DSET__sgi"; then
    config_os=irix
  fi

  if test -n "$DSET__Lynx__"; then
    config_os=lynxos
  fi

  if test -n "$DSET__APPLE__" && test -n "$DSET__MACH__"; then
    config_os=osx
  fi

  if test -n "$DSET__OS9000" || test -n "$DSET_OSK"; then
    config_os=os9
  fi

  if test -n "$DSET__minix"; then
    config_os=minix
  fi

  if test -n "$DSET__MORPHOS__"; then
    config_os=morphos
  fi

  if test -n "$DSET__TANDEM"; then
    config_os=nonstop
  fi

  if test -n "$DSET__nucleus__"; then
    config_os=nucleus
  fi

  if test -n "$DSET__QNX__" || test -n "$DSET__QNXNTO__"; then
    config_os=qnx
    if test -n "$DVAL_NTO_VERSION"; then
      config_os_vmajor=`expr "0$DVAL_NTO_VERSION" / 100`
    fi
  fi

  if test -n "$DSETsun" || test -n "$DSET__sun"; then
    if test -n "$DSET__SVR4" || test -n "$DSET__svr4__"; then
      config_os=solaris
    fi

    if test -n "$DSET__SunOS_5_8"; then
      config_os_vmajor=8
    elif test -n "$DSET__SunOS_5_9"; then
      config_os_vmajor=9
    elif test -n "$DSET__SunOS_5_9"; then
      config_os_vmajor=9
    elif test -n "$DSET__SunOS_5_10"; then
      config_os_vmajor=10
    elif test -n "$DSET__SunOS_5_11"; then
      config_os_vmajor=11
    fi
  fi

  if test -n "$DSET__VOS__"; then
    config_os=vos
  fi

  if test -n "$DSET__SYLLABLE__"; then
    config_os=syllable
  fi

  if test -n "$DSET__VXWORKS__" || test -n "$DSET__vxworks"; then
    config_os=vxworks
    if test -n "$DVAL_WRS_VXWORKS_MAJOR"; then
      config_os_vmajor=$DVAL_WRS_VXWORKS_MAJOR
    fi
  fi

  if test -n "$DSET_WIN32" || test -n "$DSET_WIN64" || test -n "$DSET__WIN32__" || test -n "$DSET__TOS_WIN__" || test -n "$DSET__WINDOWS__"; then
    config_os=windows
  fi

  if test -n "$DSET__MVS__" || test -n "$DSET__HOS_MVS__" || test -n "$DSET__TOS_MVS__"; then
    config_os=zos
  fi

  if test -n "$DSET__alpha__" || test -n "$DSET_M_ALPHA"; then
    config_arch=alpha
    config_bitness=64
  fi

  if test -n "$DSET__arm__" || test -n "$DSET__thumb__" || test -n "$DSET__TARGET_ARCH_ARM" || test -n "$DSET__TARGET_ARCH_THUMB" || test -n "$DSET_ARM" || test -n "$DSET_M_ARM" || test -n "$DSET_M_ARMT" || test -n "$DSET__arm"; then
    config_arch=arm
  fi

  if test -n "$DSET__aarch64__"; then
    config_arch=arm64
    config_bitness=64
  fi

  if test -n "$DSET__bfin" || test -n "$DSET__BFIN__"; then
    config_arch=blackfin
  fi

  if test -n "$DSET__epiphany__"; then
    config_arch=epiphany
  fi

  if test -n "$DSET__hppa__" || test -n "$DSET__HPPA__" || test -n "$DSET__hppa"; then
    config_arch=hppa
  fi

# X86 start
  if test -n "$DSETi386" || test -n "$DSET__i386" || test -n "$DSET__i386__" || test -n "$DSET__386"; then
    config_arch=x86
    config_bitness=32
  fi

  if test -n "$DSET__i486__" || test -n "$DSET__i586__" || test -n "$DSET__i686__"; then
    config_arch=x86
    config_bitness=32
  fi

  if test -n "$DSET__IA32__" || test -n "$DSET__X86__" || test -n "$DSET_X86_" || test -n "$DSET__THW_INTEL__" || test -n "$DSET__INTEL__"; then
    config_arch=x86
    config_bitness=32
  fi

  if test -n "$DSET_M_IX86" || test -n "$DSET__I86__"; then
    config_arch=x86
    config_bitness=32
  fi
# X86 end

  if test -n "$DSET__amd64__" || test -n "$DSET__amd64" || test -n "$DSET__x86_64__" || test -n "$DSET__x86_64" || test -n "$DSET_M_X64" || test -n "$DSET_M_AMD64"; then
    config_arch=x86_64
    config_bitness=64
  fi

  if test -n "$DSET__ia64__" || test -n "$DSET_IA64" || test -n "$DSET__IA64__" || test -n "$DSET__ia64" || test -n "$DSET_M_IA64" || test -n "$DSET__itanium__"; then
    config_arch=ia64
    config_bitness=64
  fi

  if test -n "$DSET__mips__" || test -n "$DSETmips" || test -n "$DSET__MIPS__" || test -n "$DSET__mips"; then
    config_arch=mips
  fi

  if test -n "$DSET__powerpc" || test -n "$DSET__powerpc__" || test -n "$DSET__powerpc64__" || test -n "$DSET__POWERPC__" || test -n "$DSET__ppc__" || test -n "$DSET__ppc64__" || test -n "$DSET__PPC__" || test -n "$DSET__PPC64__" || test -n "$DSET_ARCH_PPC" || test -n "$DSET_ARCH_PPC64" || test -n "$DSET_M_PPC" || test -n "$DSET__PPCGECKO__" || test -n "$DSET__PPCBROADWAY__" || test -n "$DSET_XENON" || test -n "$DSET__ppc" || test -n "$DSET__PowerPC__" || test -n "$DSET__PPC" || test -n "$DSET__ppc64"; then
    config_arch=powerpc
  fi

  if test -n "$DSET__sparc__" || test -n "$DSET__sparc" || test -n "$DSET__sparc64__"; then
    config_arch=sparc
  fi

  if test -n "$DSET__sh__"; then
    config_arch=superh
  fi

  if test -n "$DSET__s390x__" || test -n "$DSET__zarch__" || test -n "$DSET__SYSC_ZARCH__"; then
    config_arch=zarch
    config_bitness=64
  fi

  if test -n "$DSET__BIG_ENDIAN__" || test -n "$DSET__ARMEB__" || test -n "$DSET__THUMBEB__" || test -n "$DSET__AARCH64EB__" || test -n "$DSET_MIPSEB" || test -n "$DSET__MIPSEB" || test -n "$DSET__MIPSEB__"; then
    config_endianess=big
  fi

  if test x"$DVAL__BYTE_ORDER__" = "x__ORDER_BIG_ENDIAN__" || test x"$DVAL__FLOAT_WORD_ORDER__" = "x__ORDER_BIG_ENDIAN__"; then
    config_endianess=big
  fi

  if test -n "$DSET__LITTLE_ENDIAN__" || test -n "$DSET__ARMEL__" || test -n "$DSET__THUMBEL__" || test -n "$DSET__AARCH64EL__" || test -n "$DSET_MIPSEL" || test -n "$DSET__MIPSEL" || test -n "$DSET__MIPSEL__"; then
    config_endianess=little
  fi

  if test x"$DVAL__BYTE_ORDER__" = "x__ORDER_LITTLE_ENDIAN__" || test x"$DVAL__FLOAT_WORD_ORDER__" = "x__ORDER_LITTLE_ENDIAN__"; then
    config_endianess=little
  fi

  if test -n "$DSET_ILP32" || test -n "$DSET__ILP32__"; then
    config_data_model=ilp32
    config_bitness=32
  fi

  if test -n "$DSET_LP64" || test -n "$DSET__LP64__"; then
    config_data_model=lp64
    config_bitness=64
  fi

  config_version=$config_vmajor
  if test -n "$config_vminor"; then
    config_version="${config_version}.${config_vminor}"
    if test -n "$config_vrevision"; then
      config_version="${config_version}.${config_vrevision}"
    fi
  fi

  config_os_version=$config_os_vmajor
}

perform_probe() {
  if test x$mode_config = x1; then
    rm -f $config_file
  fi

  if test -z "$probe_cc_cmd"; then
    if test -n "$SYSCAP"; then
      case `$SYSCAP -os` in
        aix)
          cc_list="cc xlc gcc c99"   ###CC_LINE
          cc_list="xlc++ xlC c++ CC g++"    ###CX_LINE
          ;;
        solaris)
          cc_list="cc gcc c99"   ###CC_LINE
          cc_list="CC g++ c++"    ###CX_LINE
          ;;
        irix)
          cc_list="cc c99 gcc c89"   ###CC_LINE
          cc_list="CC g++"    ###CX_LINE
          ;;
        gnulinux)
          cc_list="gcc cc c99"   ###CC_LINE
          cc_list="g++ c++ CC"    ###CX_LINE
          ;;
      esac
    else
      cc_list="gcc cc c99"    ###CC_LINE
      cc_list="g++ CC c++"    ###CX_LINE
    fi

    for cc_cmd in $cc_list; do
      check_cc
      if test x$cc_is_ok = x1; then
        break
      fi
    done
  else
    cc_cmd=$probe_cc_cmd
    check_cc
  fi

  if test x$cc_is_ok = x1; then
    if test x$mode_config = x1 && test -z "$silent_config"; then
      printf "%s\n" "found %C% compiler $cc_cmd" >&2
    fi
    read_cc_props
    config_cmd=$cc_cmd
    for config in $config_list; do
      config_var=`echo "CC_${config}" | tr [a-z] [A-Z]`
      eval config_val=\$config_$config
      if test x$mode_config = x1; then
        printf "%s\n" "$config_var=\"$config_val\"" >>$config_file
      else
        case $out_format in
          1)
            printf "%s\n" "$config_var=\"$config_val\""
            ;;
          2) 
            printf "%s\n" "$config_var: $config_val"
            ;;
          3) 
            printf "%s\n" "${config_val:--}"
            ;;
        esac
      fi
      eval $config_var=\$config_val
    done
  else
    if test x$mode_config = x1 && test -z "$silent_config"; then
      printf "%s\n" "${script_name}: %C% compiler not found" >&2
    fi
    exit 1
  fi
}


case x"$1" in
  x-h|x-help|x--help)
    print_help
    exit 0
    ;;
  xconfig)
    mode_config=1
    shift
    ;;
  xprobe)
    mode_probe=1
    shift
    ;;
  *)
    mode_info=1
    ;;
esac

if test x$mode_config$mode_probe = x1; then
########## CC_BLOCK_START
  test -n "$CC" && probe_cc_cmd=$CC
  test -n "$CFLAGS" && probe_cc_cmd=$CFLAGS
########## CX_BLOCK_START
  test -n "$CXX" && probe_cc_cmd=$CXX
  test -n "$CXXFLAGS" && probe_cc_cmd=$CXXFLAGS
########## BLOCK_END
  current_opt=
  while test $# -gt 0; do
    case "$1" in
      -cc)
        current_opt=cc
        ;;
      -cflags=*)
        probe_cc_flags=`echo -n "$1" | sed 's/^[^=]*=//'`
        current_opt=
        ;;
      -f1|-f2|-f3)
        if test x$mode_probe = x; then
          printf "%s\n" "$script_name: invalid parameter $1" >&2
          exit 1
        fi
        out_format=`echo -n "$1" | sed 's/^-f//'`
        current_opt=
        ;;
      *)
        case "$current_opt" in
          cc)
            probe_cc_cmd=$1
            current_opt=
            ;;
          *)
            printf "%s\n" "$script_name: invalid parameter $1" >&2
            exit 1
            ;;
        esac
        ;;
    esac
    shift
  done
  config_cflags=$probe_cc_flags
elif test x$mode_info = x1; then
  while test $# -gt 0; do
    case "$1" in
      -id)
        print_string="$print_string \$CC_ID"
        ;;
      -ver)
        print_string="$print_string \$CC_VERSION"
        ;;
      -cmd)
        print_string="$print_string \$CC_CMD"
        ;;
      -cflags)
        print_string="$print_string \$CC_CFLAGS"
        ;;
      -std)
        print_string="$print_string \$CC_STD"
        ;;
      -os)
        print_string="$print_string \$CC_OS"
        ;;
      -osver)
        print_string="$print_string \$CC_OS_VERSION"
        ;;
      -kernel)
        print_string="$print_string \$CC_KERNEL"
        ;;
      -arch)
        print_string="$print_string \$CC_ARCH"
        ;;
      -bits)
        print_string="$print_string \$CC_BITNESS"
        ;;
      -endian)
        print_string="$print_string \$CC_ENDIANESS"
        ;;
      -dm)
        print_string="$print_string \$CC_DATA_MODEL"
        ;;
      *)
        printf "%s\n" "$script_name: invalid parameter $1" >&2
        exit 1
        ;;
    esac
    shift
  done
fi

if test x$mode_info = x1 && test ! -f $config_file; then
  mode_config=1
  silent_config=1
fi

if test x$mode_config$mode_probe = x1; then
  perform_probe
else
  . $config_file
fi

if test x$mode_info = x1; then
  if test -n "$print_string"; then
    eval print_string=\"$print_string\"
    print_string=`echo "$print_string" | sed 's/^ *//' | sed 's/ *$//' | sed 's/  */ /g'`
    printf "%s\n" "$print_string"
  else

  cat <<EOF
id:                    ${CC_ID:-"-"}
version:               ${CC_VERSION:-"-"}
command:               ${CC_CMD:-"-"}
cflags:                ${CC_CFLAGS:-"-"}
language standard:     ${CC_STD:-"-"}
target os:             ${CC_OS:-"-"}
target os version:     ${CC_OS_VERSION:-"-"}
target kernel:         ${CC_KERNEL:-"-"}
target arch:           ${CC_ARCH:-"-"}
bitness:               ${CC_BITNESS:-"-"}
endianess:             ${CC_ENDIANESS:-"-"}
data model:            ${CC_DATA_MODEL:-"-"}
EOF
  fi
fi

exit 0


cat <<EOF
/* COMPILER DEFINES */

/* STANDARDS */

#ifdef __STDC__
DSET__STDC__=1
#endif

#ifdef __STDC_VERSION__
DSET__STDC_VERSION__=1
DVAL__STDC_VERSION__=__STDC_VERSION__
#endif

#ifdef __cplusplus
DSET__cplusplus=1
DVAL__cplusplus=__cplusplus
#endif

#ifdef __cplusplus_cli
DSET_cplusplus_cli=1
DVAL_cplusplus_cli=__cplusplus_cli
#endif

#ifdef __embedded_cplusplus
DSET__embedded_cplusplus=1
#endif


/* COMPILERS */

#ifdef __CMB__
DSET__CMB__=1
#endif

#ifdef __VERSION__
DSET__VERSION__=1
DVAL__VERSION__=__VERSION__
#endif

#ifdef __REVISION__
DSET__REVISION__=1
DVAL__REVISION__=__REVISION__
#endif

#ifdef __BUILD__
DSET__BUILD__=1
DVAL__BUILD__=__BUILD__
#endif

#ifdef __CHC__
DSET__CHC__=1
#endif

#ifdef __ACK__
DSET__ACK__=1
#endif

#ifdef __CC_ARM
DSET__CC_ARM=1
#endif

#ifdef __ARMCC_VERSION
DSET__ARMCC_VERSION=1
DVAL__ARMCC_VERSION=__ARMCC_VERSION
#endif

#ifdef __BORLANDC__
DSET__BORLANDC__=1
DVAL__BORLANDC__=__BORLANDC__
#endif

#ifdef __CODEGEARC__
DSET__CODEGEARC__=1
DVAL__CODEGEARC__=__CODEGEARC__
#endif

#ifdef __clang__
DSET__clang__=1
#endif

#ifdef __clang_major__
DSET__clang_major__=1
DVAL__clang_major__=__clang_major__
#endif

#ifdef __clang_minor__
DSET__clang_minor__=1
DVAL__clang_minor__=__clang_minor__
#endif

#ifdef __clang_patchlevel__
DSET__clang_patchlevel__=1
DVAL__clang_patchlevel__=__clang_patchlevel__
#endif

#ifdef __COMO__
DSET__COMO__=1
#endif

#ifdef __COMO_VERSION__
DSET__COMO_VERSION__=1
DVAL__COMO_VERSION__=__COMO_VERSION__
#endif

#ifdef __COMPCERT__
DSET__COMPCERT__=1
#endif

#ifdef __DCC__
DSET__DCC__=1
#endif

#ifdef __VERSION_NUMBER__
DSET__VERSION_NUMBER__=1
DVAL__VERSION_NUMBER__=__VERSION_NUMBER__
#endif

#ifdef __DMC__
DSET__DMC__=1
DVAL__DMC__=__DMC__
#endif

#ifdef __SYSC__
DSET__SYSC__=1
#endif

#ifdef __SYSC_VER__
DSET__SYSC_VER__=1
DVAL__SYSC_VER__=__SYSC_VER__
#endif

#ifdef __DJGPP__
DSET__DJGPP__=1
DVAL__DJGPP__=__DJGPP__
#endif

#ifdef __DJGPP_MINOR__
DSET__DJGPP_MINOR__=1
DVAL__DJGPP_MINOR__=__DJGPP_MINOR__
#endif

#ifdef __GO32__
DSET__GO32__=1
#endif

#ifdef __EDG__
DSET__EDG__=1
#endif

#ifdef __EDG_VERSION__
DSET__EDG_VERSION__=1
DVAL__EDG_VERSION__=__EDG_VERSION__
#endif

#ifdef __PATHCC__
DSET__PATHCC__=1
DVAL__PATHCC__=__PATHCC__
#endif

#ifdef __PATHCC_MINOR__
DSET__PATHCC_MINOR__=1
DVAL__PATHCC_MINOR__=__PATHCC_MINOR__
#endif

#ifdef __PATHCC_PATCHLEVEL__
DSET__PATHCC_PATCHLEVEL__=1
DVAL__PATHCC_PATCHLEVEL__=__PATHCC_PATCHLEVEL__
#endif

#ifdef __GNUC__
DSET__GNUC__=1
DVAL__GNUC__=__GNUC__
#endif

#ifdef __GNUC_MINOR__
DSET__GNUC_MINOR__=1
DVAL__GNUC_MINOR__=__GNUC_MINOR__
#endif

#ifdef __GNUC_PATCHLEVEL__
DSET__GNUC_PATCHLEVEL__=1
DVAL__GNUC_PATCHLEVEL__=__GNUC_PATCHLEVEL__
#endif

#ifdef __GNUC_VERSION__
DSET__GNUC_VERSION__=1
DVAL__GNUC_VERSION__=__GNUC_VERSION__
#endif

#ifdef __ghs__
DSET__ghs__=1
#endif

#ifdef __GHS_VERSION_NUMBER__
DSET__GHS_VERSION_NUMBER__=1
DVAL__GHS_VERSION_NUMBER__=__GHS_VERSION_NUMBER__
#endif

#ifdef __GHS_REVISION_DATE__
DSET__GHS_REVISION_DATE__=1
DVAL__GHS_REVISION_DATE__=__GHS_REVISION_DATE__
#endif

#ifdef __HP_cc
DSET__HP_cc=1
#endif

#ifdef __HP_aCC
DSET__HP_aCC=1
DVAL__HP_aCC=__HP_aCC
#endif

#ifdef __IAR_SYSTEMS_ICC__
DSET__IAR_SYSTEMS_ICC__=1
#endif

#ifdef __VER__
DSET__VER__=1
DVAL__VER__=__VER__
#endif

#ifdef __xlc__
DSET__xlc__=1
DVAL__xlc__=__xlc__
#endif

#ifdef __xlC__
DSET__xlC__=1
DVAL__xlC__=__xlC__
#endif

#ifdef __xlC_ver__
DSET__xlC_ver__=1
DVAL__xlC_ver__=__xlC_ver__
#endif

#ifdef __IBMC__
DSET__IBMC__=1
DVAL__IBMC__=__IBMC__
#endif

#ifdef __IBMCPP__
DSET__IBMCPP__=1
DVAL__IBMCPP__=__IBMCPP__
#endif

#ifdef __COMPILER_VER__
DSET__COMPILER_VER__=1
DVAL__COMPILER_VER__=__COMPILER_VER__
#endif

#ifdef __IMAGECRAFT__
DSET__IMAGECRAFT__=1
#endif

#ifdef __INTEL_COMPILER
DSET__INTEL_COMPILER=1
DVAL__INTEL_COMPILER=__INTEL_COMPILER
#endif

#ifdef __ICC
DSET__ICC=1
#endif

#ifdef __ECC
DSET__ECC=1
#endif

#ifdef __ICL
DSET__ICL=1
#endif

#ifdef __INTEL_COMPILER_BUILD_DATE
DSET__INTEL_COMPILER_BUILD_DATE=1
DVAL__INTEL_COMPILER_BUILD_DATE=__INTEL_COMPILER_BUILD_DATE
#endif

#ifdef __C166__
DSET__C166__=1
DVAL__C166__=__C166__
#endif

#ifdef __C51__
DSET__C51__=1
DVAL__C51__=__C51__
#endif

#ifdef __CX51__
DSET__CX51__=1
DVAL__CX51__=__CX51__
#endif

#ifdef __LCC__
DSET__LCC__=1
#endif

#ifdef __HIGHC__
DSET__HIGHC__=1
#endif

#ifdef __MWERKS__
DSET__MWERKS__=1
DVAL__MWERKS__=__MWERKS__
#endif

#ifdef __CWCC__
DSET__CWCC__=1
DVAL__CWCC__=__CWCC__
#endif

#ifdef _MSC_VER
DSET_MSC_VER=1
DVAL_MSC_VER=_MSC_VER
#endif

#ifdef _MSC_FULL_VER
DSET_MSC_FULL_VER=1
DVAL_MSC_FULL_VER=_MSC_FULL_VER
#endif

#ifdef _MSC_BUILD
DSET_MSC_BUILD=1
DVAL_MSC_BUILD=_MSC_BUILD
#endif

#ifdef _MRI
DSET_MRI=1
#endif

#ifdef __MINGW32__
DSET__MINGW32__=1

#include <stdlib.h>

#ifdef __MINGW32_MAJOR_VERSION
DSET__MINGW32_MAJOR_VERSION=1
DVAL__MINGW32_MAJOR_VERSION=__MINGW32_MAJOR_VERSION
#endif

#ifdef __MINGW32_MINOR_VERSION
DSET__MINGW32_MINOR_VERSION=1
DVAL__MINGW32_MINOR_VERSION=__MINGW32_MINOR_VERSION
#endif

#ifdef __MINGW64_VERSION_MAJOR
DSET__MINGW64_VERSION_MAJOR=1
DVAL__MINGW64_VERSION_MAJOR=__MINGW64_VERSION_MAJOR
#endif

#ifdef __MINGW64_VERSION_MINOR
DSET__MINGW64_VERSION_MINOR=1
DVAL__MINGW64_VERSION_MINOR=__MINGW64_VERSION_MINOR
#endif

#endif

#ifdef __MINGW64__
DSET__MINGW64__=1
#endif

#ifdef __sgi
DSET__sgi=1
#endif

#ifdef sgi
DSETsgi=1
#endif

#ifdef _COMPILER_VERSION
DSET_COMPILER_VERSION=1
DVAL_COMPILER_VERSION=_COMPILER_VERSION
#endif

#ifdef _SGI_COMPILER_VERSION
DSET_SGI_COMPILER_VERSION=1
DVAL_SGI_COMPILER_VERSION=_SGI_COMPILER_VERSION
#endif

#ifdef __OPEN64__
DSET__OPEN64__=1
#endif

#ifdef __OPENCC__
DSET__OPENCC__=1
DVAL__OPENCC__=__OPENCC__
#endif

#ifdef __OPENCC_MINOR__
DSET__OPENCC_MINOR__=1
DVAL__OPENCC_MINOR__=__OPENCC_MINOR__
#endif

#ifdef __OPENCC_PATCHLEVEL__
DSET__OPENCC_PATCHLEVEL__=1
DVAL__OPENCC_PATCHLEVEL__=__OPENCC_PATCHLEVEL__
#endif

#ifdef __SUNPRO_C
DSET__SUNPRO_C=1
DVAL__SUNPRO_C=__SUNPRO_C
#endif

#ifdef __SUNPRO_CC
DSET__SUNPRO_CC=1
DVAL__SUNPRO_CC=__SUNPRO_CC
#endif

#ifdef __POCC__
DSET__POCC__=1
DVAL__POCC__=__POCC__
#endif

#ifdef __PGI
DSET__PGI=1
#endif

#ifdef __PGIC__
DSET__PGIC__=1
DVAL__PGIC__=__PGIC__
#endif

#ifdef __PGIC_MINOR__
DSET__PGIC_MINOR__=1
DVAL__PGIC_MINOR__=__PGIC_MINOR__
#endif

#ifdef __PGIC_PATCHLEVEL__
DSET__PGIC_PATCHLEVEL__=1
DVAL__PGIC_PATCHLEVEL__=__PGIC_PATCHLEVEL__
#endif

#ifdef __RENESAS__
DSET__RENESAS__=1
#endif

#ifdef __HITACHI__
DSET__HITACHI__=1
#endif

#ifdef __RENESAS_VERSION__
DSET__RENESAS_VERSION__=1
DVAL__RENESAS_VERSION__=__RENESAS_VERSION__
#endif

#ifdef __HITACHI_VERSION__
DSET__HITACHI_VERSION__=1
DVAL__HITACHI_VERSION__=__HITACHI_VERSION__
#endif

#ifdef SDCC
DSETSDCC=1
DVALSDCC=SDCC
#endif

#ifdef __SNC__
DSET__SNC__=1
#endif

#ifdef __VOSC__
DSET__VOSC__=1
DVAL__VOSC__=__VOSC__
#endif

#ifdef __TenDRA__
DSET__TenDRA__=1
#endif

#ifdef __TI_COMPILER_VERSION__
DSET__TI_COMPILER_VERSION__=1
DVAL__TI_COMPILER_VERSION__=__TI_COMPILER_VERSION__
#endif

#ifdef __TINYC__
DSET__TINYC__=1
#endif

#ifdef __VBCC__
DSET__VBCC__=1
#endif

#ifdef __WATCOMC__
DSET__WATCOMC__=1
DVAL__WATCOMC__=__WATCOMC__
#endif


/* OPERATING SYSTEMS */

#ifdef _AIX
DSET_AIX=1
#endif

#ifdef __TOS_AIX__
DSET__TOS_AIX__=1
#endif

#ifdef _AIX3
DSET_AIX3=1
#endif

#ifdef _AIX31
DSET_AIX31=1
#endif

#ifdef _AIX4
DSET_AIX4=1
#endif

#ifdef _AIX41
DSET_AIX41=1
#endif

#ifdef _AIX5
DSET_AIX5=1
#endif

#ifdef _AIX51
DSET_AIX51=1
#endif

#ifdef _AIX6
DSET_AIX6=1
#endif

#ifdef _AIX61
DSET_AIX61=1
#endif

#ifdef _AIX7
DSET_AIX7=1
#endif

#ifdef _AIX71
DSET_AIX71=1
#endif

#ifdef _AIX8
DSET_AIX8=1
#endif

#ifdef _AIX81
DSET_AIX81=1
#endif

#ifdef _AIX9
DSET_AIX9=1
#endif

#ifdef _AIX91
DSET_AIX91=1
#endif

#ifdef __ANDROID__
DSET__ANDROID__=1

#include <android/api-level.h>
#ifdef __ANDROID_API__
DSET__ANDROID_API__=1
DVAL__ANDROID_API__=__ANDROID_API__
#endif

#endif

#ifdef AMIGA
DSETAMIGA=1
#endif

#ifdef __amigaos__
DSET__amigaos__=1
#endif

#ifdef __FreeBSD__
DSET__FreeBSD__=1
DVAL__FreeBSD__=__FreeBSD__
#endif

#ifdef __FreeBSD_kernel__
DSET__FreeBSD_kernel__=1
#endif

#ifdef __NetBSD__
DSET__NetBSD__=1
#endif

#ifdef __OpenBSD__
DSET__OpenBSD__=1
#endif

#ifdef __DragonFly__
DSET__DragonFly__=1
#endif

#ifdef __CYGWIN__
DSET__CYGWIN__=1
#endif

#ifdef __ECOS
DSET__ECOS=1
#endif

#ifdef __GNU__
DSET__GNU__=1
#endif

#ifdef __gnu_hurd__
DSET__gnu_hurd__=1
#endif

#ifdef __GLIBC__
DSET__GLIBC__=1
#endif

#ifdef __gnu_linux__
DSET__gnu_linux__=1
#endif

#ifdef linux
DSETlinux=1
#endif

#ifdef __linux
DSET__linux=1
#endif

#ifdef __linux__
DSET__linux__=1
#endif

#ifdef __gnu_linux
DSET__gnu_linux=1
#endif

#ifdef _hpux
DSET_hpux=1
#endif

#ifdef hpux
DSEThpux=1
#endif

#ifdef __hpux
DSET__hpux=1
#endif

#ifdef __INTEGRITY
DSET__INTEGRITY=1
#endif

#ifdef __INTERIX
DSET__INTERIX=1
#endif

#ifdef __Lynx__
DSET__Lynx__=1
#endif

#ifdef __APPLE__
DSET__APPLE__=1
#endif

#ifdef __MACH__
DSET__MACH__=1
#endif

#ifdef __OS9000
DSET__OS9000=1
#endif

#ifdef _OSK
DSET_OSK=1
#endif

#ifdef __minix
DSET__minix=1
#endif

#ifdef __MORPHOS__
DSET__MORPHOS__=1
#endif

#ifdef __TANDEM
DSET__TANDEM=1
#endif

#ifdef __nucleus__
DSET__nucleus__=1
#endif

#ifdef __palmos__
DSET__palmos__=1
#endif

#ifdef __QNX__
DSET__QNX__=1
#endif

#ifdef __QNXNTO__
DSET__QNXNTO__=1

#include <sys/neutrino.h>
#ifdef _NTO_VERSION
DSET_NTO_VERSION=1
DVAL_NTO_VERSION=_NTO_VERSION
#endif

#endif

#ifdef M_I386
DSETM_I386=1
#endif

#ifdef M_XENIX
DSETM_XENIX=1
#endif

#ifdef sun
DSETsun=1
#endif

#ifdef __sun
DSET__sun=1
#endif

#ifdef __sun__
DSET__sun__=1
#endif

#ifdef __SunOS
DSET__SunOS=1
#endif

#ifdef __SunOS_5_8
DSET__SunOS_5_8=1
#endif

#ifdef __SunOS_5_9
DSET__SunOS_5_9=1
#endif

#ifdef __SunOS_5_10
DSET__SunOS_5_10=1
#endif

#ifdef __SunOS_5_11
DSET__SunOS_5_11=1
#endif

#ifdef __VOS__
DSET__VOS__=1
#endif

#ifdef __SYLLABLE__
DSET__SYLLABLE__=1
#endif

#ifdef __VXWORKS__
DSET__VXWORKS__=1
#endif

#ifdef __vxworks
DSET__vxworks=1
#endif

#if defined(__VXWORKS__) || defined(__vxworks)
#include <version.h>

#ifdef _WRS_VXWORKS_MAJOR
DSET_WRS_VXWORKS_MAJOR=1
DVAL_WRS_VXWORKS_MAJOR=_WRS_VXWORKS_MAJOR
#endif

#ifdef _WRS_VXWORKS_MINOR
DSET_WRS_VXWORKS_MINOR=1
DVAL_WRS_VXWORKS_MINOR=_WRS_VXWORKS_MINOR
#endif

#ifdef _WRS_VXWORKS_MAINT
DSET_WRS_VXWORKS_MAINT=1
DVAL_WRS_VXWORKS_MAINT=_WRS_VXWORKS_MAINT
#endif

#endif /*__VXWORKS __vxworks */

#ifdef __RTP__
DSET__RTP__=1
#endif

#ifdef _WRS_KERNEL
DSET_WRS_KERNEL=1
#endif

#ifdef _WIN32
DSET_WIN32=1
#endif

#ifdef _WIN64
DSET_WIN64=1
#endif

#ifdef __WIN32__
DSET__WIN32__=1
#endif

#ifdef __TOS_WIN__
DSET__TOS_WIN__=1
#endif

#ifdef __WINDOWS__
DSET__WINDOWS__=1
#endif

#ifdef WIN32
DSETWIN32=1
#endif

#ifdef __WIN32
DSET__WIN32=1
#endif

#ifdef WIN64
DSETWIN64=1
#endif

#ifdef __WIN64
DSET__WIN64=1
#endif

#ifdef __WIN64__
DSET__WIN64__=1
#endif

#ifdef WINNT
DSETWINNT=1
#endif

#ifdef __WINNT
DSET__WINNT=1
#endif

#ifdef __WINNT__
DSET__WINNT__=1
#endif

#ifdef __MVS__
DSET__MVS__=1
#endif

#ifdef __HOS_MVS__
DSET__HOS_MVS__=1
#endif

#ifdef __TOS_MVS__
DSET__TOS_MVS__=1
#endif

#ifdef __MINGW32__
DSET__MINGW32__=1
#endif

#ifdef __MINGW64__
DSET__MINGW64__=1
#endif


/* ARCHITECTURES */

#ifdef __alpha__
DSET__alpha__=1
#endif

#ifdef _M_ALPHA
DSET_M_ALPHA=1
#endif

#ifdef __amd64__
DSET__amd64__=1
#endif

#ifdef __amd64
DSET__amd64=1
#endif

#ifdef __x86_64__
DSET__x86_64__=1
#endif

#ifdef __x86_64
DSET__x86_64=1
#endif

#ifdef _M_X64
DSET_M_X64=1
#endif

#ifdef _M_AMD64
DSET_M_AMD64=1
#endif

#ifdef __arm__
DSET__arm__=1
#endif

#ifdef __thumb__
DSET__thumb__=1
#endif

#ifdef __TARGET_ARCH_ARM
DSET__TARGET_ARCH_ARM=1
#endif

#ifdef __TARGET_ARCH_THUMB
DSET__TARGET_ARCH_THUMB=1
#endif

#ifdef _ARM
DSET_ARM=1
#endif

#ifdef _M_ARM
DSET_M_ARM=1
#endif

#ifdef _M_ARMT
DSET_M_ARMT=1
#endif

#ifdef __arm
DSET__arm=1
#endif

#ifdef __aarch64__
DSET__aarch64__=1
#endif

#ifdef __bfin
DSET__bfin=1
#endif

#ifdef __BFIN__
DSET__BFIN__=1
#endif

#ifdef __epiphany__
DSET__epiphany__=1
#endif

#ifdef __hppa__
DSET__hppa__=1
#endif

#ifdef __HPPA__
DSET__HPPA__=1
#endif

#ifdef __hppa
DSET__hppa=1
#endif

#ifdef i386
DSETi386=1
#endif

#ifdef __i386
DSET__i386=1
#endif

#ifdef __i386__
DSET__i386__=1
#endif

#ifdef __i486__
DSET__i486__=1
#endif

#ifdef __i586__
DSET__i586__=1
#endif

#ifdef __i686__
DSET__i686__=1
#endif

#ifdef __IA32__
DSET__IA32__=1
#endif

#ifdef _M_IX86
DSET_M_IX86=1
#endif

#ifdef __X86__
DSET__X86__=1
#endif

#ifdef _X86_
DSET_X86_=1
#endif

#ifdef __THW_INTEL__
DSET__THW_INTEL__=1
#endif

#ifdef __I86__
DSET__I86__=1
#endif

#ifdef __INTEL__
DSET__INTEL__=1
#endif

#ifdef __386
DSET__386=1
#endif

#ifdef __ia64__
DSET__ia64__=1
#endif

#ifdef _IA64
DSET_IA64=1
#endif

#ifdef __IA64__
DSET__IA64__=1
#endif

#ifdef __ia64
DSET__ia64=1
#endif

#ifdef _M_IA64
DSET_M_IA64=1
#endif

#ifdef __itanium__
DSET__itanium__=1
#endif

#ifdef ia64
DSETia64=1
#endif

#ifdef __mips__
DSET__mips__=1
#endif

#ifdef mips
DSETmips=1
#endif

#ifdef __mips
DSET__mips=1
#endif

#ifdef __MIPS__
DSET__MIPS__=1
#endif

#ifdef __powerpc
DSET__powerpc=1
#endif

#ifdef __powerpc__
DSET__powerpc__=1
#endif

#ifdef __powerpc64__
DSET__powerpc64__=1
#endif

#ifdef __POWERPC__
DSET__POWERPC__=1
#endif

#ifdef __ppc__
DSET__ppc__=1
#endif

#ifdef __ppc64__
DSET__ppc64__=1
#endif

#ifdef __PPC__
DSET__PPC__=1
#endif

#ifdef __PPC64__
DSET__PPC64__=1
#endif

#ifdef _ARCH_PPC
DSET_ARCH_PPC=1
#endif

#ifdef _ARCH_PPC64
DSET_ARCH_PPC64=1
#endif

#ifdef _M_PPC
DSET_M_PPC=1
#endif

#ifdef __PPCGECKO__
DSET__PPCGECKO__=1
#endif

#ifdef __PPCBROADWAY__
DSET__PPCBROADWAY__=1
#endif

#ifdef _XENON
DSET_XENON=1
#endif

#ifdef __ppc
DSET__ppc=1
#endif

#ifdef __PowerPC__
DSET__PowerPC__=1
#endif

#ifdef __PPC
DSET__PPC=1
#endif

#ifdef __ppc64
DSET__ppc64=1
#endif

#ifdef __sparc__
DSET__sparc__=1
#endif

#ifdef __sparc
DSET__sparc=1
#endif

#ifdef __sparc64__
DSET__sparc64__=1
#endif

#ifdef __sh__
DSET__sh__=1
#endif

#ifdef __s390x__
DSET__s390x__=1
#endif

#ifdef __zarch__
DSET__zarch__=1
#endif

#ifdef __SYSC_ZARCH__
DSET__SYSC_ZARCH__=1
#endif

/* ENDIANESS */

#ifdef __BIG_ENDIAN__
DSET__BIG_ENDIAN__=1
#endif

#ifdef __ARMEB__
DSET__ARMEB__=1
#endif

#ifdef __THUMBEB__
DSET__THUMBEB__=1
#endif

#ifdef __AARCH64EB__
DSET__AARCH64EB__=1
#endif

#ifdef _MIPSEB
DSET_MIPSEB=1
#endif

#ifdef __MIPSEB
DSET__MIPSEB=1
#endif

#ifdef __MIPSEB__
DSET__MIPSEB__=1
#endif

#ifdef __BYTE_ORDER__
DSET__BYTE_ORDER__=1
DVAL__BYTE_ORDER__=__BYTE_ORDER__
#endif

#ifdef __FLOAT_WORD_ORDER__
DSET__FLOAT_WORD_ORDER__=1
DVAL__FLOAT_WORD_ORDER__=__FLOAT_WORD_ORDER__
#endif

#ifdef __LITTLE_ENDIAN__
DSET__LITTLE_ENDIAN__=1
#endif

#ifdef __ARMEL__
DSET__ARMEL__=1
#endif

#ifdef __THUMBEL__
DSET__THUMBEL__=1
#endif

#ifdef __AARCH64EL__
DSET__AARCH64EL__=1
#endif

#ifdef _MIPSEL
DSET_MIPSEL=1
#endif

#ifdef __MIPSEL
DSET__MIPSEL=1
#endif

#ifdef __MIPSEL__
DSET__MIPSEL__=1
#endif


/* DATA MODELS */

#ifdef _ILP32
DSET_ILP32=1
#endif

#ifdef __ILP32__
DSET__ILP32__=1
#endif

#ifdef _LP64
DSET_LP64=1
#endif

#ifdef __LP64__
DSET__LP64__=1
#endif
EOF
