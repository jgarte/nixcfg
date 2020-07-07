#!/usr/bin/env bash
set -euo pipefail
set -x

## NIXPKGS
cd ~/code/nixpkgs/master
git remote update
git reset --hard nixpkgs/master
git push origin HEAD -f

cd ~/code/nixpkgs/cmpkgs; git reset --hard nixpkgs/nixos-unstable-small
cd ~/code/nixpkgs/pipkgs; git reset --hard nixpkgs/nixos-unstable
cd ~/code/nixpkgs/pulls
for f in *; do
  cd $f; git rebase nixpkgs/master; cd .. #  && git push origin HEAD -f; cd ..
  cd ~/code/nixpkgs/cmpkgs && git merge --no-edit $f; cd -
done
cd ~/code/nixpkgs/cmpkgs; git push origin HEAD -f
cd ~/code/nixpkgs/pipkgs; git push origin HEAD -f

cd ~/code/nixpkgs/master; git reset --hard "nixpkgs/master" && git push origin HEAD -f; cd -
cd ~/code/nixpkgs/stable; git reset --hard "nixpkgs/nixos-20.03" && git push origin HEAD -f; cd -

## HOME_MANAGER
cd ~/code/home-manager/master
git remote update
git reset --hard rycee/master
git push origin HEAD -f

cd ~/code/home-manager/cmhm; git reset --hard rycee/master
cd ~/code/home-manager/pulls
for f in *; do
  cd $f; git rebase rycee/master; cd - # && git push origin HEAD -f; cd ..
  cd ~/code/home-manager/cmhm && git merge --no-edit $f; cd -
done
cd ~/code/home-manager/cmhm; git push origin HEAD -f; cd -

## NIXPKGS_WAYLAND
cd ~/code/overlays/nixpkgs-wayland
git remote update
git reset --hard origin/master
cd -
