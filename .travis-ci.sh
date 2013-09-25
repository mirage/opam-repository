echo pull req $TRAVIS_PULL_REQUEST

if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
  curl https://github.com/$TRAVIS_REPO_SLUG/pull/$TRAVIS_PULL_REQUEST.diff -o pullreq.diff
else
  git show > pullreq.diff
fi

# Install OCaml and OPAM PPAs
case "$OCAML_VERSION" in
4.00.1)
  echo "yes" | sudo add-apt-repository ppa:avsm/ppa
  echo TODO need to add OPAM to this repository as there is no i386 at present
  ;;
4.01.0)
  echo "yes" | sudo add-apt-repository ppa:avsm/ppa-testing
  ;;
*)
  ;;
esac

sudo apt-get update -qq
sudo apt-get install -qq ocaml ocaml-native-compilers camlp4-extra opam
export OPAMYES=1

cd $TRAVIS_BUILD_DIR

opam init .

if [ -e pullreq.diff ]; then
  cat pullreq.diff
  # CR: this will be replaced with the OCamlot analysis of affected packages
  cat pullreq.diff | sort -u | grep '^... b/packages' | sed -E 's,\+\+\+ b/packages/(.*)/.*,\1,' | awk -F. '{print $1}'| sort -u > tobuild.txt
  pkgsraw=`cat tobuild.txt`
  allpkgs=`opam list -s -a`
  # test for installability
  for pkg in $pkgsraw; do
    if [ `echo $allpkgs | grep $pkg` != "" ]; then
      pkgs="$pkgs $pkg"
    fi
  done   
  if [ "$pkgs" != "" ]; then
    depext=`opam install $pkgs -e ubuntu`
    if [ "$depext" != "" ]; then 
      sudo apt-get install $depext
    fi
    opam install $pkgs
  fi
fi
