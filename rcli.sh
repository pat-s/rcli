#!/opt/homebrew/bin/bash

function rcli() {

  ### EXAMPLES
  # shc -f rcli.sh && mv rcli.sh.x /opt/homebrew/bin/rcli && chmod +x /opt/homebrew/bin/rcli && rcli install 4.1.1 --arch x86_64

  source ./helpers/version-compare.sh
  source ./helpers/parseArguments.sh
  source ./helpers/help.sh

  # from https://stackoverflow.com/a/61055114/4185785
  parseArguments "${@}"

  R_VERSION=$2
  arch=$(uname -m)

  if [[ $1 == "--version" || $1 == "-v" ]]; then
    echo "0.1.0"
    exit 0

  elif [[ $1 == "--help" || $1 == "-h" ]]; then
    showHelp
    exit 0

    # version_compare $R_VERSION 4.0.6
    arm_avail=$(version_compare $R_VERSION 4.0.6)
    R3x="$(version_compare $R_VERSION 3.6.4)"

  elif [[ $1 == "install" ]]; then

    if [[ $ARG_ARCH == "x86_64" ]]; then
      echo "Downloading x86_64 installer because --arch x86_64 was set."
    fi

    if [[ $arm_avail != 1 && $ARG_ARCH != "x86_64" ]]; then
      echo "No arm installer available for this R version. Downloading x86_64 version instead."
    fi

    # this means the request R version was smaller than 3.6.3
    if [[ $R3x == -1 ]]; then

      echo -e "-> Downloading https://cran.r-project.org/bin/macosx/el-capitan/base/R-${R_VERSION}.pkg"
      curl -s https://cran.r-project.org/bin/macosx/el-capitan/base/R-${R_VERSION}.pkg -o /tmp/R-${R_VERSION}.pkg
      # this preserves the previous installation
      sudo pkgutil --forget org.r-project.R.el-capitan.fw.pkg
      sudo installer -pkg /tmp/R-${R_VERSION}.pkg -target /
      rm /tmp/R-${R_VERSION}.pkg

    elif [[ ($arch == "arm64" && $arm_avail == 1 && $ARG_ARCH != "x86_64") ]]; then
      echo -e "-> Downloading https://cran.r-project.org/bin/macosx/big-sur-arm64/base/R-${R_VERSION}-arm64.pkg"
      curl -s https://cran.r-project.org/bin/macosx/big-sur-arm64/base/R-${R_VERSION}-arm64.pkg -o /tmp/R-${R_VERSION}-arm64.pkg
      # this preserves the previous installation
      sudo pkgutil --forget org.R-project.arm64.R.fw.pkg
      sudo installer -pkg /tmp/R-${R_VERSION}-arm64.pkg -target /
      rm /tmp/R-${R_VERSION}-arm64.pkg
    else
      echo -e "-> Downloading https://cran.r-project.org/bin/macosx/base/R-${R_VERSION}.pkg"
      curl -s https://cran.r-project.org/bin/macosx/base/R-${R_VERSION}.pkg -o /tmp/R-${R_VERSION}.pkg
      # this preserves the previous installation
      sudo pkgutil --forget org.R-project.R.fw.pkg
      sudo installer -pkg /tmp/R-${R_VERSION}.pkg -target /
      rm /tmp/R-${R_VERSION}.pkg
    fi

  elif [[ $1 == "switch" ]]; then

    # only branch specific switching is possible - we need to strip and write a warning
    if [[ ${#R_VERSION} == 5 ]]; then
      R_CUT=$(echo $R_VERSION | cut -c 1-3)
      echo -e "Only minor-version switching is possible, e.g. between versions 4.0 and 4.1.\nStripping the patch version from the supplied version '$R_VERSION' to '$R_CUT'.\nTo suppress this warning, omit the patch version."
      ARG_1=$R_CUT
    fi

    if [[ $ARG_ARCH == "x86_64" ]]; then
      echo "-> Switching to x86_64 R installation because --arch x86_64 was set."
    fi
    if [[ ($arch == "arm64" && $arm_avail == 1 && $ARG_ARCH != "x86_64") ]]; then
      ln -sfn $ARG_1-arm64 /Library/Frameworks/R.framework/Versions/Current
    else
      ln -sfn $ARG_1 /Library/Frameworks/R.framework/Versions/Current
    fi

  fi

}

[ $# -gt 0 ] && rcli ${@}
