honishi uncrustify template
==

you should *not* use this uncrustify stuff as a git submodule.
cause `git-rev-parse` is used internally in the scripts to get repository root directory.

setup uncrustify binary
--
````
brew install uncrustify
````

locate this scripts
--
````
mkdir scripts
cp -r git-hooks uncrustify scripts
````

configure script
--
edit `FIXME` part in the following scripts.
````
vi scripts/uncrustify/uncrustify_all
vi scripts/uncrustify/uncrustify_pre_commit.hook
vi scripts/git-hooks/pre-commit
````

setup git repository
--
````
cd .git/hooks
ln -s ../../scripts/git-hooks/pre-commit
````
